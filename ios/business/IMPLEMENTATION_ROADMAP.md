# Cameron's Business App - Implementation Roadmap
## Complete Feature Implementation Plan

**Document Version:** 1.0
**Last Updated:** November 13, 2025
**Estimated Total Timeline:** 16-20 weeks

---

## Table of Contents
1. [Phase 1: MVP Completion - Critical Features](#phase-1-mvp-completion)
2. [Phase 2: Customer Experience Enhancement](#phase-2-customer-experience)
3. [Phase 3: Operational Excellence](#phase-3-operational-excellence)
4. [Phase 4: Scale & Growth](#phase-4-scale--growth)
5. [Technical Architecture](#technical-architecture)
6. [Database Schema](#database-schema)
7. [API Specifications](#api-specifications)
8. [Third-Party Integrations](#third-party-integrations)
9. [Testing Strategy](#testing-strategy)
10. [Deployment Plan](#deployment-plan)

---

# Phase 1: MVP Completion (Critical Features)
**Timeline:** 6-8 weeks
**Goal:** Make the app production-ready for taking real orders

## 1.1 Backend Infrastructure Setup (Week 1-2)

### Technology Stack Selection

**Recommended Backend Stack:**
```
Option A (Node.js - Recommended for speed):
├── Runtime: Node.js 18+
├── Framework: Express.js or Fastify
├── Database: PostgreSQL 15+ (primary)
├── Cache: Redis 7+
├── Real-time: Socket.io
├── File Storage: AWS S3 or Cloudinary
├── Authentication: JWT + Refresh Tokens
└── API Docs: OpenAPI/Swagger

Option B (Python - Recommended for AI features later):
├── Runtime: Python 3.11+
├── Framework: FastAPI
├── Database: PostgreSQL 15+
├── Cache: Redis 7+
├── Real-time: WebSockets
├── File Storage: AWS S3
├── Authentication: JWT + OAuth2
└── API Docs: Auto-generated from FastAPI

Option C (Swift - Native iOS Backend):
├── Framework: Vapor 4
├── Database: PostgreSQL with Fluent ORM
├── Cache: Redis
├── Real-time: WebSockets
└── Fully Swift stack (same language as frontend)
```

**Recommended Choice:** **Node.js with Express** for rapid development and ecosystem maturity.

### Infrastructure Setup Tasks

**Task 1.1.1: Initialize Backend Repository**
```bash
# Create backend repository
mkdir camerons-backend
cd camerons-backend

# Initialize Node.js project
npm init -y

# Install dependencies
npm install express cors helmet compression
npm install jsonwebtoken bcryptjs
npm install pg pg-hstore sequelize
npm install redis socket.io
npm install dotenv express-validator
npm install winston morgan
npm install --save-dev nodemon jest supertest
```

**Task 1.1.2: Project Structure**
```
camerons-backend/
├── src/
│   ├── config/
│   │   ├── database.js
│   │   ├── redis.js
│   │   └── config.js
│   ├── models/
│   │   ├── User.js
│   │   ├── Store.js
│   │   ├── Order.js
│   │   ├── MenuItem.js
│   │   ├── Customer.js
│   │   └── index.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── orders.routes.js
│   │   ├── menu.routes.js
│   │   ├── customers.routes.js
│   │   ├── analytics.routes.js
│   │   └── payments.routes.js
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── orders.controller.js
│   │   ├── menu.controller.js
│   │   └── payments.controller.js
│   ├── middleware/
│   │   ├── auth.middleware.js
│   │   ├── validation.middleware.js
│   │   ├── error.middleware.js
│   │   └── rateLimit.middleware.js
│   ├── services/
│   │   ├── payment.service.js
│   │   ├── notification.service.js
│   │   ├── email.service.js
│   │   └── sms.service.js
│   ├── utils/
│   │   ├── logger.js
│   │   ├── helpers.js
│   │   └── constants.js
│   ├── sockets/
│   │   └── order.socket.js
│   └── app.js
├── tests/
│   ├── unit/
│   └── integration/
├── .env.example
├── .gitignore
├── package.json
└── README.md
```

**Task 1.1.3: Database Setup**

**PostgreSQL Schema Creation:**
```sql
-- Create database
CREATE DATABASE camerons_prod;
CREATE DATABASE camerons_test;

-- Connect to camerons_prod
\c camerons_prod;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";  -- For geolocation features

-- Create enum types
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'staff', 'driver');
CREATE TYPE order_status AS ENUM ('received', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'completed', 'cancelled');
CREATE TYPE order_type AS ENUM ('pickup', 'delivery', 'dine_in');
CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'refunded');
CREATE TYPE payment_method AS ENUM ('card', 'cash', 'apple_pay', 'google_pay', 'gift_card');
```

---

## 1.2 Payment Processing Integration (Week 2-3)

### Recommended Payment Provider: **Stripe Connect**

**Why Stripe?**
- ✅ Excellent documentation
- ✅ Strong fraud protection
- ✅ Supports Apple Pay, Google Pay
- ✅ Easy refunds and disputes
- ✅ PCI compliant (Stripe handles it)
- ✅ Great iOS SDK
- ✅ Subscription support (for future features)

### Implementation Steps

**Step 1: Stripe Account Setup**
```bash
# Sign up at stripe.com
# Get API keys (Test & Live)
# Enable Apple Pay
# Enable Google Pay
# Set up webhooks
```

**Step 2: Install Stripe iOS SDK**
```swift
// In camerons-Bussiness-app.xcodeproj, add via SPM:
// https://github.com/stripe/stripe-ios
```

**Step 3: Create Payment Models**

**File:** `camerons-Bussiness-app/Shared/PaymentModels.swift`
```swift
import Foundation

// MARK: - Payment Intent
struct PaymentIntent: Codable, Identifiable {
    let id: String
    let amount: Int // in cents
    let currency: String
    let status: PaymentStatus
    let clientSecret: String?
    let orderId: String
    let customerId: String
    let paymentMethodId: String?
    let createdAt: Date
    let updatedAt: Date
}

enum PaymentStatus: String, Codable {
    case pending
    case processing
    case succeeded
    case failed
    case canceled
    case refunded

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .succeeded: return "Completed"
        case .failed: return "Failed"
        case .canceled: return "Canceled"
        case .refunded: return "Refunded"
        }
    }

    var color: Color {
        switch self {
        case .pending, .processing: return .warning
        case .succeeded: return .success
        case .failed, .canceled: return .error
        case .refunded: return .info
        }
    }
}

// MARK: - Payment Method
struct PaymentMethod: Codable, Identifiable {
    let id: String
    let type: PaymentMethodType
    let last4: String?
    let brand: String? // Visa, Mastercard, etc.
    let expiryMonth: Int?
    let expiryYear: Int?
    let isDefault: Bool
    let customerId: String
}

enum PaymentMethodType: String, Codable {
    case card
    case applePay
    case googlePay
    case cash
    case giftCard

    var displayName: String {
        switch self {
        case .card: return "Credit/Debit Card"
        case .applePay: return "Apple Pay"
        case .googlePay: return "Google Pay"
        case .cash: return "Cash"
        case .giftCard: return "Gift Card"
        }
    }

    var icon: String {
        switch self {
        case .card: return "creditcard.fill"
        case .applePay: return "apple.logo"
        case .googlePay: return "g.circle.fill"
        case .cash: return "dollarsign.circle.fill"
        case .giftCard: return "giftcard.fill"
        }
    }
}

// MARK: - Transaction
struct Transaction: Codable, Identifiable {
    let id: String
    let orderId: String
    let amount: Double
    let tax: Double
    let tip: Double?
    let total: Double
    let paymentMethod: PaymentMethodType
    let status: PaymentStatus
    let receiptUrl: String?
    let refundAmount: Double?
    let refundReason: String?
    let createdAt: Date
    let completedAt: Date?

    var formattedTotal: String {
        return String(format: "$%.2f", total)
    }
}

// MARK: - Refund Request
struct RefundRequest: Codable {
    let transactionId: String
    let amount: Double? // nil = full refund
    let reason: RefundReason
    let notes: String?
}

enum RefundReason: String, Codable, CaseIterable {
    case customerRequest = "customer_request"
    case qualityIssue = "quality_issue"
    case wrongOrder = "wrong_order"
    case deliveryIssue = "delivery_issue"
    case duplicate = "duplicate"
    case fraudulent = "fraudulent"

    var displayName: String {
        switch self {
        case .customerRequest: return "Customer Request"
        case .qualityIssue: return "Quality Issue"
        case .wrongOrder: return "Wrong Order"
        case .deliveryIssue: return "Delivery Issue"
        case .duplicate: return "Duplicate Charge"
        case .fraudulent: return "Fraudulent"
        }
    }
}
```

**Step 4: Create Payment Service**

**File:** `camerons-Bussiness-app/Services/PaymentService.swift`
```swift
import Foundation
import Stripe

@MainActor
class PaymentService: ObservableObject {
    static let shared = PaymentService()

    @Published var isProcessing = false
    @Published var paymentError: String?

    private let baseURL = "https://api.camerons.com/v1" // Your backend

    private init() {
        // Configure Stripe with publishable key
        StripeAPI.defaultPublishableKey = Configuration.stripePublishableKey
    }

    // MARK: - Create Payment Intent
    func createPaymentIntent(for order: Order) async throws -> PaymentIntent {
        isProcessing = true
        defer { isProcessing = false }

        let endpoint = "\(baseURL)/payments/intent"

        let requestBody: [String: Any] = [
            "orderId": order.id,
            "amount": Int(order.total * 100), // Convert to cents
            "currency": "usd",
            "customerId": order.customerId ?? "",
            "metadata": [
                "orderNumber": order.orderNumber,
                "storeId": order.storeId
            ]
        ]

        let (data, _) = try await APIClient.shared.post(endpoint, body: requestBody)
        let paymentIntent = try JSONDecoder().decode(PaymentIntent.self, from: data)

        return paymentIntent
    }

    // MARK: - Process Payment with Stripe
    func processPayment(
        paymentIntent: PaymentIntent,
        paymentMethod: STPPaymentMethod
    ) async throws -> PaymentIntent {
        isProcessing = true
        defer { isProcessing = false }

        guard let clientSecret = paymentIntent.clientSecret else {
            throw PaymentError.missingClientSecret
        }

        // Confirm payment with Stripe SDK
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodId = paymentMethod.stripeId

        let paymentHandler = STPPaymentHandler.shared()

        return try await withCheckedThrowingContinuation { continuation in
            paymentHandler.confirmPayment(paymentIntentParams, with: self) { status, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if status == .succeeded {
                    // Fetch updated payment intent from backend
                    Task {
                        do {
                            let updated = try await self.getPaymentIntent(id: paymentIntent.id)
                            continuation.resume(returning: updated)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                } else {
                    continuation.resume(throwing: PaymentError.paymentFailed)
                }
            }
        }
    }

    // MARK: - Process Apple Pay
    func processApplePay(for order: Order) async throws -> PaymentIntent {
        isProcessing = true
        defer { isProcessing = false }

        // Create payment request
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: Configuration.appleMerchantId,
            country: "US",
            currency: "USD"
        )

        // Add line items
        var items: [PKPaymentSummaryItem] = []
        for item in order.items {
            let summaryItem = PKPaymentSummaryItem(
                label: "\(item.quantity)x \(item.menuItem.name)",
                amount: NSDecimalNumber(value: item.menuItem.price * Double(item.quantity))
            )
            items.append(summaryItem)
        }

        // Add tax
        items.append(PKPaymentSummaryItem(
            label: "Tax",
            amount: NSDecimalNumber(value: order.tax)
        ))

        // Total
        items.append(PKPaymentSummaryItem(
            label: "Cameron's Restaurant",
            amount: NSDecimalNumber(value: order.total)
        ))

        paymentRequest.paymentSummaryItems = items

        // Present Apple Pay sheet and process
        // (Implementation continues with PKPaymentAuthorizationController)
        // ...

        throw PaymentError.notImplemented
    }

    // MARK: - Refund Payment
    func refundPayment(request: RefundRequest) async throws -> Transaction {
        let endpoint = "\(baseURL)/payments/refund"

        let (data, _) = try await APIClient.shared.post(endpoint, body: request)
        let transaction = try JSONDecoder().decode(Transaction.self, from: data)

        return transaction
    }

    // MARK: - Get Payment History
    func getPaymentHistory(orderId: String) async throws -> [Transaction] {
        let endpoint = "\(baseURL)/payments/history/\(orderId)"
        let (data, _) = try await APIClient.shared.get(endpoint)
        let transactions = try JSONDecoder().decode([Transaction].self, from: data)

        return transactions
    }

    // MARK: - Helper Methods
    private func getPaymentIntent(id: String) async throws -> PaymentIntent {
        let endpoint = "\(baseURL)/payments/intent/\(id)"
        let (data, _) = try await APIClient.shared.get(endpoint)
        let paymentIntent = try JSONDecoder().decode(PaymentIntent.self, from: data)

        return paymentIntent
    }
}

// MARK: - Payment Errors
enum PaymentError: LocalizedError {
    case missingClientSecret
    case paymentFailed
    case refundFailed
    case notImplemented
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .missingClientSecret:
            return "Payment initialization failed. Please try again."
        case .paymentFailed:
            return "Payment could not be processed. Please check your payment method."
        case .refundFailed:
            return "Refund could not be processed. Please contact support."
        case .notImplemented:
            return "This payment method is not yet available."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - STPAuthenticationContext (for 3D Secure)
extension PaymentService: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        // Return root view controller
        return UIApplication.shared.windows.first?.rootViewController ?? UIViewController()
    }
}
```

**Step 5: Create Payment Views**

**File:** `camerons-Bussiness-app/Core/Payments/PaymentMethodsView.swift`
```swift
import SwiftUI
import Stripe

struct PaymentMethodsView: View {
    @StateObject private var viewModel = PaymentMethodsViewModel()
    @State private var showAddCard = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Payment Methods List
                    ForEach(viewModel.paymentMethods) { method in
                        PaymentMethodCard(
                            method: method,
                            isDefault: method.isDefault,
                            onSetDefault: {
                                viewModel.setDefaultPaymentMethod(method.id)
                            },
                            onDelete: {
                                viewModel.deletePaymentMethod(method.id)
                            }
                        )
                    }

                    // Add Payment Method Button
                    Button(action: { showAddCard = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Payment Method")
                        }
                        .font(AppFonts.body)
                        .foregroundColor(.brandPrimary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.surface)
                        .cornerRadius(CornerRadius.md)
                    }
                }
                .padding()
            }
            .navigationTitle("Payment Methods")
            .sheet(isPresented: $showAddCard) {
                AddPaymentMethodView { newMethod in
                    viewModel.addPaymentMethod(newMethod)
                }
            }
        }
        .onAppear {
            viewModel.loadPaymentMethods()
        }
    }
}

struct PaymentMethodCard: View {
    let method: PaymentMethod
    let isDefault: Bool
    let onSetDefault: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            // Card Icon/Brand
            Image(systemName: method.type.icon)
                .font(.system(size: 32))
                .foregroundColor(.brandPrimary)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(method.brand ?? method.type.displayName)
                        .font(AppFonts.headline)

                    if isDefault {
                        Text("Default")
                            .font(AppFonts.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.success.opacity(0.2))
                            .foregroundColor(.success)
                            .cornerRadius(4)
                    }
                }

                if let last4 = method.last4 {
                    Text("•••• \(last4)")
                        .font(AppFonts.subheadline)
                        .foregroundColor(.textSecondary)
                }

                if let month = method.expiryMonth, let year = method.expiryYear {
                    Text("Expires \(String(format: "%02d/%02d", month, year % 100))")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            // Actions Menu
            Menu {
                if !isDefault {
                    Button(action: onSetDefault) {
                        Label("Set as Default", systemImage: "checkmark.circle")
                    }
                }

                Button(role: .destructive, action: onDelete) {
                    Label("Remove", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2, y: 1)
    }
}

// MARK: - Add Payment Method View
struct AddPaymentMethodView: View {
    @Environment(\.dismiss) var dismiss
    let onAdd: (PaymentMethod) -> Void

    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var zipCode = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Information")) {
                    TextField("Card Number", text: $cardNumber)
                        .keyboardType(.numberPad)
                        .textContentType(.creditCardNumber)

                    HStack {
                        TextField("MM/YY", text: $expiryDate)
                            .keyboardType(.numberPad)

                        TextField("CVV", text: $cvv)
                            .keyboardType(.numberPad)
                            .textContentType(.creditCardSecurityCode)
                    }

                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
                        .textContentType(.postalCode)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.error)
                            .font(AppFonts.caption)
                    }
                }

                Section {
                    Button(action: addCard) {
                        if isProcessing {
                            ProgressView()
                        } else {
                            Text("Add Card")
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(!isValid || isProcessing)
                }
            }
            .navigationTitle("Add Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var isValid: Bool {
        // Basic validation
        return cardNumber.count >= 15 &&
               expiryDate.count == 5 &&
               cvv.count >= 3 &&
               zipCode.count == 5
    }

    private func addCard() {
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                // Use Stripe SDK to tokenize card
                let cardParams = STPCardParams()
                cardParams.number = cardNumber

                let expiryComponents = expiryDate.split(separator: "/")
                if expiryComponents.count == 2 {
                    cardParams.expMonth = UInt(expiryComponents[0]) ?? 0
                    cardParams.expYear = UInt("20\(expiryComponents[1])") ?? 0
                }

                cardParams.cvc = cvv

                let token = try await STPAPIClient.shared.createToken(withCard: cardParams)

                // Send token to backend to save
                let method = try await savePaymentMethod(token: token.tokenId)

                onAdd(method)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }

            isProcessing = false
        }
    }

    private func savePaymentMethod(token: String) async throws -> PaymentMethod {
        // API call to backend
        // Backend will use token to create PaymentMethod with Stripe
        throw PaymentError.notImplemented
    }
}
```

**Backend Implementation:**

**File:** `camerons-backend/src/controllers/payments.controller.js`
```javascript
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { Order, Transaction, PaymentMethod } = require('../models');

// Create Payment Intent
exports.createPaymentIntent = async (req, res, next) => {
    try {
        const { orderId, amount, currency, customerId, metadata } = req.body;

        // Validate order exists
        const order = await Order.findByPk(orderId);
        if (!order) {
            return res.status(404).json({ error: 'Order not found' });
        }

        // Create Stripe Payment Intent
        const paymentIntent = await stripe.paymentIntents.create({
            amount: amount, // in cents
            currency: currency || 'usd',
            customer: customerId,
            metadata: {
                ...metadata,
                orderId,
                storeId: order.storeId
            },
            automatic_payment_methods: {
                enabled: true,
            },
        });

        // Save to database
        const transaction = await Transaction.create({
            id: paymentIntent.id,
            orderId,
            amount: amount / 100,
            currency,
            status: 'pending',
            stripePaymentIntentId: paymentIntent.id,
            clientSecret: paymentIntent.client_secret
        });

        res.json({
            id: paymentIntent.id,
            clientSecret: paymentIntent.client_secret,
            amount,
            currency,
            status: paymentIntent.status,
            orderId,
            customerId,
            createdAt: new Date(),
            updatedAt: new Date()
        });
    } catch (error) {
        next(error);
    }
};

// Stripe Webhook Handler
exports.handleWebhook = async (req, res) => {
    const sig = req.headers['stripe-signature'];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event;

    try {
        event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } catch (err) {
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // Handle different event types
    switch (event.type) {
        case 'payment_intent.succeeded':
            await handlePaymentSuccess(event.data.object);
            break;
        case 'payment_intent.payment_failed':
            await handlePaymentFailure(event.data.object);
            break;
        case 'refund.created':
            await handleRefundCreated(event.data.object);
            break;
        default:
            console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
};

async function handlePaymentSuccess(paymentIntent) {
    const orderId = paymentIntent.metadata.orderId;

    // Update transaction status
    await Transaction.update(
        {
            status: 'succeeded',
            completedAt: new Date()
        },
        { where: { stripePaymentIntentId: paymentIntent.id } }
    );

    // Update order status to confirmed
    await Order.update(
        {
            status: 'confirmed',
            paymentStatus: 'paid'
        },
        { where: { id: orderId } }
    );

    // Send confirmation email/SMS
    // ... notification logic
}

// Refund Payment
exports.refundPayment = async (req, res, next) => {
    try {
        const { transactionId, amount, reason, notes } = req.body;

        const transaction = await Transaction.findByPk(transactionId);
        if (!transaction) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        // Create refund with Stripe
        const refund = await stripe.refunds.create({
            payment_intent: transaction.stripePaymentIntentId,
            amount: amount ? amount * 100 : undefined, // undefined = full refund
            reason: reason,
            metadata: {
                notes: notes,
                processedBy: req.user.id
            }
        });

        // Update transaction
        await transaction.update({
            refundAmount: refund.amount / 100,
            refundReason: reason,
            status: 'refunded'
        });

        res.json({
            success: true,
            refund: {
                id: refund.id,
                amount: refund.amount / 100,
                status: refund.status
            }
        });
    } catch (error) {
        next(error);
    }
};
```

---

## 1.3 Real-Time Order System (Week 3-4)

### Architecture: WebSockets + Redis Pub/Sub

**Why This Architecture?**
- Real-time bidirectional communication
- Scalable across multiple server instances
- Persistent connections for instant updates
- Redis Pub/Sub allows broadcasting to all connected business dashboards

### Implementation

**Step 1: Backend WebSocket Server**

**File:** `camerons-backend/src/sockets/order.socket.js`
```javascript
const socketIo = require('socket.io');
const redis = require('redis');
const { verifyToken } = require('../middleware/auth.middleware');

class OrderSocketServer {
    constructor(server) {
        // Initialize Socket.IO
        this.io = socketIo(server, {
            cors: {
                origin: process.env.ALLOWED_ORIGINS.split(','),
                methods: ['GET', 'POST']
            }
        });

        // Initialize Redis clients
        this.redisPublisher = redis.createClient({
            url: process.env.REDIS_URL
        });
        this.redisSubscriber = redis.createClient({
            url: process.env.REDIS_URL
        });

        this.setupRedis();
        this.setupSocketHandlers();
    }

    async setupRedis() {
        await this.redisPublisher.connect();
        await this.redisSubscriber.connect();

        // Subscribe to order channels
        await this.redisSubscriber.subscribe('order:new', (message) => {
            this.broadcastNewOrder(JSON.parse(message));
        });

        await this.redisSubscriber.subscribe('order:update', (message) => {
            this.broadcastOrderUpdate(JSON.parse(message));
        });
    }

    setupSocketHandlers() {
        // Middleware: Authenticate socket connections
        this.io.use(async (socket, next) => {
            try {
                const token = socket.handshake.auth.token;
                const user = await verifyToken(token);
                socket.user = user;
                next();
            } catch (err) {
                next(new Error('Authentication failed'));
            }
        });

        this.io.on('connection', (socket) => {
            console.log(`User connected: ${socket.user.id} (${socket.user.role})`);

            // Join store-specific room
            const storeId = socket.user.storeId;
            socket.join(`store:${storeId}`);

            // Handle order status updates from business app
            socket.on('order:updateStatus', async (data) => {
                await this.handleOrderStatusUpdate(socket, data);
            });

            // Handle order acceptance
            socket.on('order:accept', async (data) => {
                await this.handleOrderAccept(socket, data);
            });

            // Handle order rejection
            socket.on('order:reject', async (data) => {
                await this.handleOrderReject(socket, data);
            });

            // Send current pending orders on connection
            socket.on('orders:subscribe', async () => {
                await this.sendPendingOrders(socket, storeId);
            });

            socket.on('disconnect', () => {
                console.log(`User disconnected: ${socket.user.id}`);
            });
        });
    }

    // Broadcast new order to all devices in store
    broadcastNewOrder(order) {
        const storeId = order.storeId;

        this.io.to(`store:${storeId}`).emit('order:new', {
            order,
            timestamp: new Date(),
            requiresAction: true
        });

        // Play sound alert
        this.io.to(`store:${storeId}`).emit('alert:sound', {
            type: 'newOrder',
            priority: 'high'
        });
    }

    // Broadcast order update to all devices in store
    broadcastOrderUpdate(update) {
        const storeId = update.storeId;

        this.io.to(`store:${storeId}`).emit('order:updated', {
            orderId: update.orderId,
            status: update.status,
            updatedBy: update.updatedBy,
            timestamp: new Date()
        });
    }

    // Handle status update from business app
    async handleOrderStatusUpdate(socket, data) {
        const { orderId, newStatus } = data;

        try {
            // Update order in database
            const order = await Order.findByPk(orderId);
            await order.update({ status: newStatus });

            // Publish to Redis for other server instances
            await this.redisPublisher.publish('order:update', JSON.stringify({
                orderId,
                status: newStatus,
                storeId: order.storeId,
                updatedBy: socket.user.id
            }));

            // Notify customer app (separate channel)
            await this.redisPublisher.publish('customer:orderUpdate', JSON.stringify({
                customerId: order.customerId,
                orderId,
                status: newStatus
            }));

            socket.emit('order:updateSuccess', { orderId, newStatus });
        } catch (error) {
            socket.emit('order:updateError', { error: error.message });
        }
    }

    // Send all pending orders to newly connected socket
    async sendPendingOrders(socket, storeId) {
        try {
            const pendingOrders = await Order.findAll({
                where: {
                    storeId,
                    status: ['received', 'preparing', 'ready']
                },
                order: [['createdAt', 'ASC']]
            });

            socket.emit('orders:initial', pendingOrders);
        } catch (error) {
            socket.emit('orders:error', { error: error.message });
        }
    }
}

module.exports = OrderSocketServer;
```

**Step 2: iOS WebSocket Client**

**File:** `camerons-Bussiness-app/Services/WebSocketService.swift`
```swift
import Foundation
import Combine

class WebSocketService: ObservableObject {
    static let shared = WebSocketService()

    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var receivedOrders: [Order] = []

    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "wss://api.camerons.com"

    enum ConnectionStatus {
        case connected
        case connecting
        case disconnected
        case error(String)
    }

    private init() {}

    // MARK: - Connection Management
    func connect() {
        guard connectionStatus != .connected && connectionStatus != .connecting else {
            return
        }

        connectionStatus = .connecting

        // Get auth token
        guard let token = AuthViewModel.shared.currentUser?.accessToken else {
            connectionStatus = .error("No authentication token")
            return
        }

        // Create WebSocket connection
        var request = URLRequest(url: URL(string: "\(baseURL)/socket")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        // Start listening for messages
        receiveMessage()

        // Subscribe to orders channel
        subscribeToOrders()

        connectionStatus = .connected

        // Send ping every 30 seconds to keep connection alive
        startHeartbeat()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionStatus = .disconnected
    }

    // MARK: - Receive Messages
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                // Continue listening
                self?.receiveMessage()

            case .failure(let error):
                self?.connectionStatus = .error(error.localizedDescription)
                // Attempt reconnection after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self?.connect()
                }
            }
        }
    }

    // MARK: - Handle Incoming Messages
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8) else { return }
            handleData(data)

        case .data(let data):
            handleData(data)

        @unknown default:
            break
        }
    }

    private func handleData(_ data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let eventType = json?["event"] as? String else { return }

            switch eventType {
            case "order:new":
                handleNewOrder(data)
            case "order:updated":
                handleOrderUpdate(data)
            case "alert:sound":
                playAlertSound()
            case "orders:initial":
                handleInitialOrders(data)
            default:
                print("Unknown event type: \(eventType)")
            }
        } catch {
            print("Failed to parse message: \(error)")
        }
    }

    private func handleNewOrder(_ data: Data) {
        do {
            struct NewOrderEvent: Codable {
                let order: Order
                let timestamp: Date
                let requiresAction: Bool
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let event = try decoder.decode(NewOrderEvent.self, from: data)

            DispatchQueue.main.async {
                // Add to orders list
                self.receivedOrders.insert(event.order, at: 0)

                // Show notification
                self.showOrderNotification(event.order)

                // Post notification for dashboard to refresh
                NotificationCenter.default.post(
                    name: .newOrderReceived,
                    object: event.order
                )
            }
        } catch {
            print("Failed to decode new order: \(error)")
        }
    }

    private func handleOrderUpdate(_ data: Data) {
        do {
            struct OrderUpdateEvent: Codable {
                let orderId: String
                let status: OrderStatus
                let updatedBy: String
                let timestamp: Date
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let event = try decoder.decode(OrderUpdateEvent.self, from: data)

            DispatchQueue.main.async {
                // Update order in list
                if let index = self.receivedOrders.firstIndex(where: { $0.id == event.orderId }) {
                    self.receivedOrders[index].status = event.status

                    // Post notification
                    NotificationCenter.default.post(
                        name: .orderStatusUpdated,
                        object: event
                    )
                }
            }
        } catch {
            print("Failed to decode order update: \(error)")
        }
    }

    private func handleInitialOrders(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let orders = try decoder.decode([Order].self, from: data)

            DispatchQueue.main.async {
                self.receivedOrders = orders
            }
        } catch {
            print("Failed to decode initial orders: \(error)")
        }
    }

    // MARK: - Send Messages
    private func send(event: String, data: [String: Any]) {
        var payload = data
        payload["event"] = event

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }

    func subscribeToOrders() {
        send(event: "orders:subscribe", data: [:])
    }

    func updateOrderStatus(orderId: String, newStatus: OrderStatus) {
        send(event: "order:updateStatus", data: [
            "orderId": orderId,
            "newStatus": newStatus.rawValue
        ])
    }

    func acceptOrder(orderId: String) {
        send(event: "order:accept", data: ["orderId": orderId])
    }

    func rejectOrder(orderId: String, reason: String) {
        send(event: "order:reject", data: [
            "orderId": orderId,
            "reason": reason
        ])
    }

    // MARK: - Heartbeat
    private func startHeartbeat() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.sendPing()
            }
            .store(in: &cancellables)
    }

    private func sendPing() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("Ping failed: \(error)")
            }
        }
    }

    // MARK: - Notifications
    private func showOrderNotification(_ order: Order) {
        let content = UNMutableNotificationContent()
        content.title = "New Order #\(order.orderNumber)"
        content.body = "\(order.customerName) - \(order.formattedTotal)"
        content.sound = .defaultCritical
        content.userInfo = ["orderId": order.id]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func playAlertSound() {
        // Play system sound or custom sound
        AudioServicesPlaySystemSound(1315) // Alert sound
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let newOrderReceived = Notification.Name("newOrderReceived")
    static let orderStatusUpdated = Notification.Name("orderStatusUpdated")
}
```

**Step 3: Update Dashboard to Use WebSocket**

**File:** `camerons-Bussiness-app/Core/Dashboard/DashboardView.swift` (Updates)
```swift
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var webSocket = WebSocketService.shared
    // ... existing code ...

    var body: some View {
        NavigationView {
            VStack {
                // Connection Status Indicator
                ConnectionStatusBar(status: webSocket.connectionStatus)

                // ... rest of existing UI ...
            }
            .onAppear {
                webSocket.connect()
                viewModel.loadOrders()
            }
            .onDisappear {
                webSocket.disconnect()
            }
            .onReceive(NotificationCenter.default.publisher(for: .newOrderReceived)) { notification in
                if let order = notification.object as? Order {
                    viewModel.handleNewOrder(order)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .orderStatusUpdated)) { notification in
                viewModel.refreshOrders()
            }
        }
    }
}

// Connection Status Bar
struct ConnectionStatusBar: View {
    let status: WebSocketService.ConnectionStatus

    var body: some View {
        Group {
            switch status {
            case .connected:
                HStack {
                    Circle()
                        .fill(Color.success)
                        .frame(width: 8, height: 8)
                    Text("Connected")
                        .font(AppFonts.caption)
                        .foregroundColor(.success)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.success.opacity(0.1))
                .cornerRadius(4)

            case .connecting:
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Connecting...")
                        .font(AppFonts.caption)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.warning.opacity(0.1))
                .cornerRadius(4)

            case .disconnected:
                HStack {
                    Circle()
                        .fill(Color.error)
                        .frame(width: 8, height: 8)
                    Text("Disconnected")
                        .font(AppFonts.caption)
                        .foregroundColor(.error)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.error.opacity(0.1))
                .cornerRadius(4)

            case .error(let message):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(message)
                        .font(AppFonts.caption)
                }
                .foregroundColor(.error)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.error.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
}
```

---

## 1.4 Kitchen Display System (Week 4-5)

### Design: Dedicated KDS Mode with Drag-and-Drop Workflow

**File:** `camerons-Bussiness-app/Core/KitchenDisplay/KitchenDisplayView.swift`
```swift
import SwiftUI

struct KitchenDisplayView: View {
    @StateObject private var viewModel = KitchenDisplayViewModel()
    @State private var selectedStation: KitchenStation = .all
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with Station Filter
            KDSHeader(
                selectedStation: $selectedStation,
                orderCount: viewModel.filteredOrders.count,
                onSettingsTap: { showSettings = true }
            )

            // Orders Grid (Kanban Style)
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md)
                    ],
                    spacing: Spacing.md
                ) {
                    ForEach(viewModel.filteredOrders) { order in
                        KDSOrderCard(
                            order: order,
                            onBump: {
                                viewModel.bumpOrder(order.id)
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color.black) // Dark background for kitchen display
        .onChange(of: selectedStation) { newStation in
            viewModel.filterByStation(newStation)
        }
        .sheet(isPresented: $showSettings) {
            KDSSettingsView()
        }
        .onAppear {
            viewModel.startKDSMode()
        }
        .onDisappear {
            viewModel.stopKDSMode()
        }
    }
}

// MARK: - KDS Header
struct KDSHeader: View {
    @Binding var selectedStation: KitchenStation
    let orderCount: Int
    let onSettingsTap: () -> Void

    var body: some View {
        HStack {
            // Station Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(KitchenStation.allCases, id: \.self) { station in
                        StationButton(
                            station: station,
                            isSelected: selectedStation == station,
                            action: { selectedStation = station }
                        )
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            // Order Count Badge
            HStack(spacing: Spacing.xs) {
                Image(systemName: "bell.fill")
                Text("\(orderCount)")
                    .fontWeight(.bold)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.warning)
            .foregroundColor(.white)
            .cornerRadius(20)

            // Settings Button
            Button(action: onSettingsTap) {
                Image(systemName: "gear")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, Spacing.md)
        .background(Color.gray.opacity(0.2))
    }
}

struct StationButton: View {
    let station: KitchenStation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: station.icon)
                Text(station.displayName)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.brandPrimary : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(20)
        }
    }
}

// MARK: - KDS Order Card
struct KDSOrderCard: View {
    let order: Order
    let onBump: () -> Void

    @State private var timeElapsed: String = ""

    var urgencyColor: Color {
        let elapsed = Date().timeIntervalSince(order.createdAt)
        if elapsed > 1800 { return .error } // > 30 min
        if elapsed > 900 { return .warning } // > 15 min
        return .success
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("#\(order.orderNumber)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text(order.customerName)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Time Indicator
                VStack(alignment: .trailing) {
                    Text(timeElapsed)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(urgencyColor)

                    Text(order.orderType.rawValue.uppercased())
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Divider()
                .background(Color.white.opacity(0.3))

            // Items
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(order.items) { item in
                    HStack(alignment: .top) {
                        Text("\(item.quantity)x")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(urgencyColor)
                            .frame(width: 50, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.menuItem.name)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)

                            // Customizations
                            ForEach(item.selectedOptions.keys.sorted(), id: \.self) { group in
                                if let options = item.selectedOptions[group] {
                                    ForEach(options, id: \.self) { option in
                                        Text("• \(option)")
                                            .font(.system(size: 16))
                                            .foregroundColor(.warning)
                                    }
                                }
                            }

                            // Special Instructions
                            if !item.specialInstructions.isEmpty {
                                Text("⚠️ \(item.specialInstructions)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.error)
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Bump Button
            Button(action: onBump) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("BUMP")
                        .fontWeight(.bold)
                }
                .font(.system(size: 20))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.success)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.md)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(urgencyColor, lineWidth: 4)
        )
        .frame(height: 450)
        .onAppear {
            startTimer()
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let elapsed = Int(Date().timeIntervalSince(order.createdAt))
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            timeElapsed = String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Kitchen Station Enum
enum KitchenStation: String, CaseIterable {
    case all = "all"
    case grill = "grill"
    case fry = "fry"
    case salad = "salad"
    case sandwich = "sandwich"
    case drinks = "drinks"
    case dessert = "dessert"

    var displayName: String {
        switch self {
        case .all: return "All Orders"
        case .grill: return "Grill"
        case .fry: return "Fry"
        case .salad: return "Salad"
        case .sandwich: return "Sandwich"
        case .drinks: return "Drinks"
        case .dessert: return "Dessert"
        }
    }

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .grill: return "flame.fill"
        case .fry: return "circle.hexagongrid.fill"
        case .salad: return "leaf.fill"
        case .sandwich: return "rectangle.stack.fill"
        case .drinks: return "cup.and.saucer.fill"
        case .dessert: return "birthday.cake.fill"
        }
    }
}

// MARK: - KDS ViewModel
class KitchenDisplayViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var filteredOrders: [Order] = []

    private var currentStation: KitchenStation = .all

    func startKDSMode() {
        // Connect to WebSocket
        WebSocketService.shared.connect()

        // Subscribe to order updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewOrder),
            name: .newOrderReceived,
            object: nil
        )

        loadActiveOrders()
    }

    func stopKDSMode() {
        NotificationCenter.default.removeObserver(self)
    }

    func loadActiveOrders() {
        // Load orders with status: confirmed, preparing
        // API call here
        orders = MockDataService.shared.getMockOrders()
            .filter { $0.status == .preparing || $0.status == .received }

        filterByStation(currentStation)
    }

    func filterByStation(_ station: KitchenStation) {
        currentStation = station

        if station == .all {
            filteredOrders = orders
        } else {
            filteredOrders = orders.filter { order in
                // Filter based on menu items in order
                order.items.contains { item in
                    item.menuItem.station == station
                }
            }
        }
    }

    func bumpOrder(_ orderId: String) {
        // Move order to next status
        if let index = orders.firstIndex(where: { $0.id == orderId }) {
            let order = orders[index]

            var newStatus: OrderStatus
            switch order.status {
            case .received:
                newStatus = .preparing
            case .preparing:
                newStatus = .ready
            case .ready:
                newStatus = .completed
                // Remove from KDS
                orders.remove(at: index)
            default:
                return
            }

            // Update via WebSocket
            WebSocketService.shared.updateOrderStatus(orderId: orderId, newStatus: newStatus)

            // Play confirmation sound
            AudioServicesPlaySystemSound(1104)
        }

        filterByStation(currentStation)
    }

    @objc private func handleNewOrder(_ notification: Notification) {
        if let order = notification.object as? Order {
            orders.insert(order, at: 0)
            filterByStation(currentStation)
        }
    }
}
```

**Add Station to MenuItem Model:**
```swift
// In Shared/Models.swift, add to MenuItem:
extension MenuItem {
    var station: KitchenStation {
        // Map category to station
        switch categoryId {
        case "cat_2": return .grill // Burgers
        case "cat_3": return .sandwich // Sandwiches
        case "cat_4": return .salad // Salads
        case "cat_6": return .dessert // Desserts
        case "cat_7": return .drinks // Beverages
        default: return .all
        }
    }
}
```

---

## 1.5 Customer Database & Profiles (Week 5-6)

### Database Schema

**SQL:**
```sql
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_order_at TIMESTAMP,
    total_orders INT DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0,
    loyalty_points INT DEFAULT 0,
    loyalty_tier VARCHAR(20) DEFAULT 'bronze', -- bronze, silver, gold, platinum
    is_vip BOOLEAN DEFAULT FALSE,
    notes TEXT,
    tags TEXT[], -- ['regular', 'vip', 'influencer']

    -- Preferences
    favorite_items JSONB, -- Array of menu item IDs
    dietary_preferences JSONB, -- ['vegetarian', 'gluten-free']
    allergies TEXT[],
    default_delivery_address JSONB,

    -- Marketing
    marketing_opt_in BOOLEAN DEFAULT TRUE,
    sms_opt_in BOOLEAN DEFAULT TRUE,
    email_opt_in BOOLEAN DEFAULT TRUE,

    -- Metadata
    birthday DATE,
    acquisition_source VARCHAR(50), -- 'organic', 'referral', 'marketing'
    referred_by UUID REFERENCES customers(id),

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_loyalty_tier ON customers(loyalty_tier);
CREATE INDEX idx_customers_last_order ON customers(last_order_at);

-- Trigger to update updated_at
CREATE TRIGGER update_customers_updated_at
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

### iOS Implementation

**File:** `camerons-Bussiness-app/Shared/CustomerModels.swift`
```swift
import Foundation

// MARK: - Customer
struct Customer: Codable, Identifiable {
    let id: String
    var phone: String
    var email: String?
    var firstName: String?
    var lastName: String?
    let createdAt: Date
    var lastOrderAt: Date?
    var totalOrders: Int
    var totalSpent: Double
    var loyaltyPoints: Int
    var loyaltyTier: LoyaltyTier
    var isVIP: Bool
    var notes: String?
    var tags: [String]

    // Preferences
    var favoriteItems: [String] // Menu item IDs
    var dietaryPreferences: [DietaryTag]
    var allergies: [String]
    var defaultDeliveryAddress: Address?

    // Marketing
    var marketingOptIn: Bool
    var smsOptIn: Bool
    var emailOptIn: Bool

    // Metadata
    var birthday: Date?
    var acquisitionSource: String?
    var referredBy: String?

    let updatedAt: Date

    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Guest" : name
    }

    var formattedTotalSpent: String {
        return String(format: "$%.2f", totalSpent)
    }

    var daysSinceLastOrder: Int? {
        guard let lastOrder = lastOrderAt else { return nil }
        return Calendar.current.dateComponents([.day], from: lastOrder, to: Date()).day
    }

    var customerStatus: CustomerStatus {
        guard let days = daysSinceLastOrder else { return .new }

        if days > 90 { return .atRisk }
        if days > 30 { return .inactive }
        if totalOrders >= 10 { return .regular }
        return .active
    }
}

enum LoyaltyTier: String, Codable, CaseIterable {
    case bronze
    case silver
    case gold
    case platinum

    var displayName: String {
        return rawValue.capitalized
    }

    var pointsRequired: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 100
        case .gold: return 500
        case .platinum: return 1000
        }
    }

    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.9, blue: 0.95)
        }
    }

    var icon: String {
        switch self {
        case .bronze: return "medal.fill"
        case .silver: return "medal.fill"
        case .gold: return "medal.fill"
        case .platinum: return "crown.fill"
        }
    }

    var discount: Double {
        switch self {
        case .bronze: return 0.0
        case .silver: return 0.05 // 5%
        case .gold: return 0.10 // 10%
        case .platinum: return 0.15 // 15%
        }
    }
}

enum CustomerStatus: String {
    case new
    case active
    case regular
    case inactive
    case atRisk

    var displayName: String {
        switch self {
        case .new: return "New"
        case .active: return "Active"
        case .regular: return "Regular"
        case .inactive: return "Inactive"
        case .atRisk: return "At Risk"
        }
    }

    var color: Color {
        switch self {
        case .new: return .info
        case .active: return .success
        case .regular: return .brandPrimary
        case .inactive: return .warning
        case .atRisk: return .error
        }
    }

    var icon: String {
        switch self {
        case .new: return "star.fill"
        case .active: return "checkmark.circle.fill"
        case .regular: return "heart.fill"
        case .inactive: return "clock.fill"
        case .atRisk: return "exclamationmark.triangle.fill"
        }
    }
}

struct Address: Codable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var apartment: String?
    var deliveryInstructions: String?

    var formattedAddress: String {
        var components = [street]
        if let apt = apartment {
            components.append("Apt \(apt)")
        }
        components.append("\(city), \(state) \(zipCode)")
        return components.joined(separator: ", ")
    }
}

// MARK: - Customer Analytics
struct CustomerAnalytics: Codable {
    let customerId: String
    let averageOrderValue: Double
    let favoriteCategory: String?
    let preferredOrderType: OrderType?
    let averageOrderFrequency: Int // days
    let lastThreeOrders: [Order]
    let totalRewards: Int
    let lifetimeValue: Double

    var formattedAOV: String {
        return String(format: "$%.2f", averageOrderValue)
    }

    var formattedLTV: String {
        return String(format: "$%.2f", lifetimeValue)
    }
}
```

**File:** `camerons-Bussiness-app/Core/Customers/CustomersView.swift`
```swift
import SwiftUI

struct CustomersView: View {
    @StateObject private var viewModel = CustomersViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: CustomerFilter = .all
    @State private var selectedCustomer: Customer?
    @State private var showAddCustomer = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText, placeholder: "Search customers...")
                    .padding()

                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(CustomerFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                title: filter.displayName,
                                count: viewModel.getCount(for: filter),
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Customer List
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if filteredCustomers.isEmpty {
                    EmptyStateView(
                        icon: "person.3",
                        title: "No Customers",
                        message: "Start building your customer base"
                    )
                } else {
                    List(filteredCustomers) { customer in
                        CustomerRow(customer: customer)
                            .onTapGesture {
                                selectedCustomer = customer
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Customers")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddCustomer = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $selectedCustomer) { customer in
                CustomerDetailView(customer: customer)
            }
            .sheet(isPresented: $showAddCustomer) {
                AddCustomerView { newCustomer in
                    viewModel.addCustomer(newCustomer)
                }
            }
        }
        .onAppear {
            viewModel.loadCustomers()
        }
    }

    private var filteredCustomers: [Customer] {
        var customers = viewModel.customers

        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .new:
            customers = customers.filter { $0.customerStatus == .new }
        case .active:
            customers = customers.filter { $0.customerStatus == .active || $0.customerStatus == .regular }
        case .vip:
            customers = customers.filter { $0.isVIP }
        case .atRisk:
            customers = customers.filter { $0.customerStatus == .atRisk }
        }

        // Apply search
        if !searchText.isEmpty {
            customers = customers.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.phone.contains(searchText) ||
                ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return customers
    }
}

// MARK: - Customer Row
struct CustomerRow: View {
    let customer: Customer

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Avatar or initials
            Circle()
                .fill(customer.loyaltyTier.color.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(customer.fullName.prefix(2).uppercased())
                        .font(AppFonts.headline)
                        .foregroundColor(customer.loyaltyTier.color)
                )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(customer.fullName)
                        .font(AppFonts.body)
                        .fontWeight(.medium)

                    if customer.isVIP {
                        Image(systemName: "star.fill")
                            .foregroundColor(.warning)
                            .font(.system(size: 12))
                    }

                    // Loyalty Tier Badge
                    Image(systemName: customer.loyaltyTier.icon)
                        .foregroundColor(customer.loyaltyTier.color)
                        .font(.system(size: 12))
                }

                Text(customer.phone)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)

                HStack {
                    // Status
                    Text(customer.customerStatus.displayName)
                        .font(AppFonts.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(customer.customerStatus.color.opacity(0.2))
                        .foregroundColor(customer.customerStatus.color)
                        .cornerRadius(4)

                    // Orders
                    Text("\(customer.totalOrders) orders")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)

                    // Total Spent
                    Text(customer.formattedTotalSpent)
                        .font(AppFonts.caption)
                        .foregroundColor(.success)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.textSecondary)
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Customer Filter
enum CustomerFilter: String, CaseIterable {
    case all
    case new
    case active
    case vip
    case atRisk

    var displayName: String {
        switch self {
        case .all: return "All"
        case .new: return "New"
        case .active: return "Active"
        case .vip: return "VIP"
        case .atRisk: return "At Risk"
        }
    }
}

struct FilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Text("(\(count))")
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .textSecondary)
            }
            .font(AppFonts.subheadline)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.brandPrimary : Color.surface)
            .foregroundColor(isSelected ? .white : .textPrimary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Customer Detail View
struct CustomerDetailView: View {
    let customer: Customer
    @StateObject private var viewModel = CustomerDetailViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Customer Header
                    CustomerHeaderSection(customer: customer)

                    // Quick Stats
                    CustomerStatsSection(customer: customer, analytics: viewModel.analytics)

                    // Order History
                    CustomerOrderHistorySection(orders: viewModel.recentOrders)

                    // Favorite Items
                    if !customer.favoriteItems.isEmpty {
                        FavoriteItemsSection(itemIds: customer.favoriteItems)
                    }

                    // Notes Section
                    CustomerNotesSection(notes: customer.notes ?? "")
                }
                .padding()
            }
            .navigationTitle("Customer Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            viewModel.loadCustomerDetails(customerId: customer.id)
        }
    }
}

// Supporting view components would continue here...
```

---

# Phase 2: Customer Experience Enhancement
**Timeline:** 4-5 weeks
**Goal:** Improve customer engagement and retention

## 2.1 Loyalty & Rewards Program (Week 7-8)

### Points System Implementation

**Database Schema:**
```sql
CREATE TABLE loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id),
    order_id UUID REFERENCES orders(id),
    points_earned INT DEFAULT 0,
    points_redeemed INT DEFAULT 0,
    points_balance INT NOT NULL,
    transaction_type VARCHAR(50), -- 'earned', 'redeemed', 'expired', 'bonus', 'adjustment'
    description TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    points_required INT NOT NULL,
    reward_type VARCHAR(50), -- 'free_item', 'discount', 'points_bonus'
    reward_value JSONB, -- {itemId: "123"} or {discount: 0.20}
    is_active BOOLEAN DEFAULT TRUE,
    total_available INT,
    times_redeemed INT DEFAULT 0,
    valid_from TIMESTAMP,
    valid_until TIMESTAMP,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reward_redemptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id),
    reward_id UUID NOT NULL REFERENCES rewards(id),
    order_id UUID REFERENCES orders(id),
    points_used INT NOT NULL,
    redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' -- 'pending', 'applied', 'cancelled'
);

CREATE INDEX idx_loyalty_customer ON loyalty_transactions(customer_id);
CREATE INDEX idx_loyalty_order ON loyalty_transactions(order_id);
CREATE INDEX idx_rewards_active ON rewards(is_active, valid_until);
```

**iOS Implementation:**

**File:** `camerons-Bussiness-app/Core/Loyalty/LoyaltyDashboardView.swift`
```swift
import SwiftUI

struct LoyaltyDashboardView: View {
    @StateObject private var viewModel = LoyaltyViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Points Balance Header
                LoyaltyBalanceCard(
                    points: viewModel.currentPoints,
                    tier: viewModel.currentTier,
                    nextTierPoints: viewModel.pointsToNextTier
                )
                .padding()

                // Tabs: Available Rewards | History
                Picker("", selection: $selectedTab) {
                    Text("Available Rewards").tag(0)
                    Text("History").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Content
                TabView(selection: $selectedTab) {
                    AvailableRewardsTab(rewards: viewModel.availableRewards) { reward in
                        viewModel.redeemReward(reward)
                    }
                    .tag(0)

                    LoyaltyHistoryTab(transactions: viewModel.transactions)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Loyalty & Rewards")
        }
        .onAppear {
            viewModel.loadLoyaltyData()
        }
    }
}

struct LoyaltyBalanceCard: View {
    let points: Int
    let tier: LoyaltyTier
    let nextTierPoints: Int?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Current Points
            VStack(spacing: Spacing.xs) {
                Text("\(points)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(tier.color)

                Text("Available Points")
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }

            // Tier Badge
            HStack {
                Image(systemName: tier.icon)
                    .foregroundColor(tier.color)
                Text(tier.displayName)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(tier.color.opacity(0.2))
            .cornerRadius(20)

            // Progress to Next Tier
            if let nextPoints = nextTierPoints, nextPoints > 0 {
                VStack(spacing: Spacing.sm) {
                    ProgressView(value: Double(points % tier.pointsRequired),
                               total: Double(nextPoints))
                        .tint(tier.color)

                    Text("\(nextPoints) points to next tier")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [tier.color.opacity(0.1), tier.color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.lg)
        .shadow(color: AppShadow.md, radius: 8)
    }
}

struct AvailableRewardsTab: View {
    let rewards: [Reward]
    let onRedeem: (Reward) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(rewards) { reward in
                    RewardCard(reward: reward, onRedeem: { onRedeem(reward) })
                }
            }
            .padding()
        }
    }
}

struct RewardCard: View {
    let reward: Reward
    let onRedeem: () -> Void
    @State private var showRedeemConfirm = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Reward Image
            if let imageUrl = reward.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.surfaceSecondary
                }
                .frame(width: 80, height: 80)
                .cornerRadius(CornerRadius.md)
            } else {
                Image(systemName: reward.type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.brandPrimary)
                    .frame(width: 80, height: 80)
                    .background(Color.surfaceSecondary)
                    .cornerRadius(CornerRadius.md)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(reward.name)
                    .font(AppFonts.headline)

                Text(reward.description)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.warning)
                        .font(.system(size: 12))

                    Text("\(reward.pointsRequired) points")
                        .font(AppFonts.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.warning)
                }
            }

            Spacer()

            Button(action: { showRedeemConfirm = true }) {
                Text("Redeem")
                    .font(AppFonts.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.success)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2, y: 1)
        .confirmationDialog(
            "Redeem \(reward.name)?",
            isPresented: $showRedeemConfirm,
            titleVisibility: .visible
        ) {
            Button("Redeem for \(reward.pointsRequired) points") {
                onRedeem()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will deduct \(reward.pointsRequired) points from your balance.")
        }
    }
}

struct LoyaltyHistoryTab: View {
    let transactions: [LoyaltyTransaction]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(transactions) { transaction in
                    LoyaltyTransactionRow(transaction: transaction)
                }
            }
            .padding()
        }
    }
}

struct LoyaltyTransactionRow: View {
    let transaction: LoyaltyTransaction

    var isPositive: Bool {
        transaction.pointsEarned > 0
    }

    var body: some View {
        HStack {
            Image(systemName: transaction.type.icon)
                .foregroundColor(isPositive ? .success : .error)
                .font(.system(size: 20))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(AppFonts.body)

                Text(transaction.createdAt.formatted(.dateTime.month().day().hour().minute()))
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text("\(isPositive ? "+" : "-")\(isPositive ? transaction.pointsEarned : transaction.pointsRedeemed)")
                .font(AppFonts.headline)
                .foregroundColor(isPositive ? .success : .error)
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Models
struct Reward: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let pointsRequired: Int
    let type: RewardType
    let value: RewardValue
    let isActive: Bool
    let totalAvailable: Int?
    let timesRedeemed: Int
    let validFrom: Date?
    let validUntil: Date?
    let imageUrl: String?
}

enum RewardType: String, Codable {
    case freeItem = "free_item"
    case discount = "discount"
    case pointsBonus = "points_bonus"

    var icon: String {
        switch self {
        case .freeItem: return "gift.fill"
        case .discount: return "percent"
        case .pointsBonus: return "star.fill"
        }
    }
}

struct RewardValue: Codable {
    let itemId: String?
    let discount: Double?
    let bonusPoints: Int?
}

struct LoyaltyTransaction: Codable, Identifiable {
    let id: String
    let customerId: String
    let orderId: String?
    let pointsEarned: Int
    let pointsRedeemed: Int
    let pointsBalance: Int
    let type: TransactionType
    let description: String
    let expiresAt: Date?
    let createdAt: Date
}

enum TransactionType: String, Codable {
    case earned
    case redeemed
    case expired
    case bonus
    case adjustment

    var icon: String {
        switch self {
        case .earned: return "plus.circle.fill"
        case .redeemed: return "minus.circle.fill"
        case .expired: return "clock.badge.xmark"
        case .bonus: return "gift.fill"
        case .adjustment: return "gearshape.fill"
        }
    }
}
```

**Backend Points Logic:**

**File:** `camerons-backend/src/services/loyalty.service.js`
```javascript
const { Customer, LoyaltyTransaction, Order } = require('../models');

class LoyaltyService {
    // Calculate points for an order
    static calculatePoints(orderTotal) {
        // 1 point per dollar spent
        const basePoints = Math.floor(orderTotal);

        // Bonus points for orders over certain amounts
        let bonusPoints = 0;
        if (orderTotal >= 50) bonusPoints = 10;
        if (orderTotal >= 100) bonusPoints = 25;

        return basePoints + bonusPoints;
    }

    // Award points for an order
    static async awardPoints(customerId, orderId, orderTotal) {
        const points = this.calculatePoints(orderTotal);

        // Get customer's current points
        const customer = await Customer.findByPk(customerId);
        const newBalance = customer.loyaltyPoints + points;

        // Create transaction
        await LoyaltyTransaction.create({
            customerId,
            orderId,
            pointsEarned: points,
            pointsRedeemed: 0,
            pointsBalance: newBalance,
            transactionType: 'earned',
            description: `Earned ${points} points from order`,
            expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // 1 year
        });

        // Update customer points and check tier
        await customer.update({
            loyaltyPoints: newBalance,
            totalOrders: customer.totalOrders + 1,
            lastOrderAt: new Date()
        });

        // Check if tier upgrade needed
        await this.checkAndUpgradeTier(customer);

        return { points, newBalance };
    }

    // Redeem reward
    static async redeemReward(customerId, rewardId) {
        const customer = await Customer.findByPk(customerId);
        const reward = await Reward.findByPk(rewardId);

        if (!reward || !reward.isActive) {
            throw new Error('Reward not available');
        }

        if (customer.loyaltyPoints < reward.pointsRequired) {
            throw new Error('Insufficient points');
        }

        if (reward.totalAvailable !== null && reward.timesRedeemed >= reward.totalAvailable) {
            throw new Error('Reward sold out');
        }

        // Deduct points
        const newBalance = customer.loyaltyPoints - reward.pointsRequired;

        // Create redemption record
        const redemption = await RewardRedemption.create({
            customerId,
            rewardId,
            pointsUsed: reward.pointsRequired,
            status: 'pending'
        });

        // Create transaction
        await LoyaltyTransaction.create({
            customerId,
            pointsEarned: 0,
            pointsRedeemed: reward.pointsRequired,
            pointsBalance: newBalance,
            transactionType: 'redeemed',
            description: `Redeemed: ${reward.name}`
        });

        // Update customer
        await customer.update({ loyaltyPoints: newBalance });

        // Update reward redemption count
        await reward.increment('timesRedeemed');

        return redemption;
    }

    // Check and upgrade tier
    static async checkAndUpgradeTier(customer) {
        const points = customer.loyaltyPoints;
        let newTier = 'bronze';

        if (points >= 1000) newTier = 'platinum';
        else if (points >= 500) newTier = 'gold';
        else if (points >= 100) newTier = 'silver';

        if (newTier !== customer.loyaltyTier) {
            await customer.update({ loyaltyTier: newTier });

            // Award bonus points for tier upgrade
            const bonusPoints = {
                silver: 10,
                gold: 25,
                platinum: 50
            }[newTier] || 0;

            if (bonusPoints > 0) {
                await this.awardBonusPoints(
                    customer.id,
                    bonusPoints,
                    `Tier upgrade bonus: ${newTier.toUpperCase()}`
                );
            }

            // Send notification
            await NotificationService.sendTierUpgrade(customer, newTier);
        }
    }

    // Award bonus points
    static async awardBonusPoints(customerId, points, description) {
        const customer = await Customer.findByPk(customerId);
        const newBalance = customer.loyaltyPoints + points;

        await LoyaltyTransaction.create({
            customerId,
            pointsEarned: points,
            pointsRedeemed: 0,
            pointsBalance: newBalance,
            transactionType: 'bonus',
            description
        });

        await customer.update({ loyaltyPoints: newBalance });
    }

    // Expire old points
    static async expirePoints() {
        const expiredTransactions = await LoyaltyTransaction.findAll({
            where: {
                expiresAt: { [Op.lt]: new Date() },
                pointsEarned: { [Op.gt]: 0 },
                transactionType: 'earned'
            }
        });

        for (const transaction of expiredTransactions) {
            const customer = await Customer.findByPk(transaction.customerId);
            const pointsToExpire = transaction.pointsEarned;
            const newBalance = Math.max(0, customer.loyaltyPoints - pointsToExpire);

            await LoyaltyTransaction.create({
                customerId: customer.id,
                pointsEarned: 0,
                pointsRedeemed: pointsToExpire,
                pointsBalance: newBalance,
                transactionType: 'expired',
                description: `${pointsToExpire} points expired`
            });

            await customer.update({ loyaltyPoints: newBalance });

            // Send notification
            await NotificationService.sendPointsExpiry(customer, pointsToExpire);
        }
    }
}

module.exports = LoyaltyService;
```

---

## 2.2 SMS & Push Notifications (Week 8-9)

### Twilio SMS Integration

**Setup:**
```bash
npm install twilio
```

**File:** `camerons-backend/src/services/sms.service.js`
```javascript
const twilio = require('twilio');

class SMSService {
    constructor() {
        this.client = twilio(
            process.env.TWILIO_ACCOUNT_SID,
            process.env.TWILIO_AUTH_TOKEN
        );
        this.fromNumber = process.env.TWILIO_PHONE_NUMBER;
    }

    // Order status notifications
    async sendOrderConfirmation(order, customer) {
        const message = `Hi ${customer.firstName}! Your order #${order.orderNumber} has been confirmed. Estimated ready time: ${order.estimatedReadyTime.toLocaleTimeString()}. Cameron's Restaurant`;

        return await this.send(customer.phone, message);
    }

    async sendOrderReady(order, customer) {
        const message = `${customer.firstName}, your order #${order.orderNumber} is ready for pickup! Cameron's Restaurant`;

        return await this.send(customer.phone, message);
    }

    async sendOrderOutForDelivery(order, customer, driverName) {
        const message = `${customer.firstName}, ${driverName} is on the way with your order #${order.orderNumber}! Track: ${process.env.APP_URL}/track/${order.id}`;

        return await this.send(customer.phone, message);
    }

    async sendOrderDelivered(order, customer) {
        const message = `Your order #${order.orderNumber} has been delivered! Enjoy your meal from Cameron's Restaurant. Rate your experience: ${process.env.APP_URL}/rate/${order.id}`;

        return await this.send(customer.phone, message);
    }

    // Marketing messages
    async sendPromotionalMessage(customer, message, couponCode = null) {
        let text = `Hi ${customer.firstName}! ${message}`;

        if (couponCode) {
            text += ` Use code: ${couponCode}`;
        }

        text += ` Reply STOP to opt out.`;

        return await this.send(customer.phone, text);
    }

    // Core send function
    async send(to, message) {
        try {
            const result = await this.client.messages.create({
                body: message,
                from: this.fromNumber,
                to: to
            });

            console.log(`SMS sent to ${to}: ${result.sid}`);
            return { success: true, sid: result.sid };
        } catch (error) {
            console.error('SMS send error:', error);
            return { success: false, error: error.message };
        }
    }

    // Handle opt-out
    async handleIncomingMessage(from, body) {
        const normalizedBody = body.trim().toUpperCase();

        if (normalizedBody === 'STOP' || normalizedBody === 'UNSUBSCRIBE') {
            await Customer.update(
                { smsOptIn: false },
                { where: { phone: from } }
            );

            return {
                response: "You've been unsubscribed from Cameron's Restaurant SMS. Text START to resubscribe.",
                action: 'unsubscribed'
            };
        }

        if (normalizedBody === 'START' || normalizedBody === 'SUBSCRIBE') {
            await Customer.update(
                { smsOptIn: true },
                { where: { phone: from } }
            );

            return {
                response: "Welcome back! You're now subscribed to Cameron's Restaurant SMS.",
                action: 'subscribed'
            };
        }

        return {
            response: "Thanks for contacting Cameron's Restaurant! Call us at (555) 123-4567 or visit our app to order.",
            action: 'auto_reply'
        };
    }
}

module.exports = new SMSService();
```

### iOS Push Notifications Setup

**File:** `camerons-Bussiness-app/Services/PushNotificationService.swift`
```swift
import UserNotifications
import UIKit

class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?

    private override init() {
        super.init()
        checkAuthorizationStatus()
    }

    // MARK: - Authorization
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self.checkAuthorizationStatus()
            }
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - Device Token
    func setDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString

        // Send to backend
        registerDeviceToken(tokenString)
    }

    private func registerDeviceToken(_ token: String) {
        guard let userId = AuthViewModel.shared.currentUser?.id else { return }

        Task {
            let endpoint = "\(Configuration.apiURL)/notifications/register"
            let body = [
                "userId": userId,
                "deviceToken": token,
                "platform": "ios"
            ]

            do {
                let _ = try await APIClient.shared.post(endpoint, body: body)
                print("Device token registered successfully")
            } catch {
                print("Failed to register device token: \(error)")
            }
        }
    }

    // MARK: - Handle Notifications
    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "new_order":
            handleNewOrderNotification(userInfo)
        case "order_update":
            handleOrderUpdateNotification(userInfo)
        case "low_stock":
            handleLowStockNotification(userInfo)
        case "marketing":
            handleMarketingNotification(userInfo)
        default:
            print("Unknown notification type: \(type)")
        }
    }

    private func handleNewOrderNotification(_ userInfo: [AnyHashable: Any]) {
        guard let orderId = userInfo["orderId"] as? String else { return }

        // Post notification for dashboard to refresh
        NotificationCenter.default.post(
            name: .newOrderReceived,
            object: orderId
        )

        // Play sound
        AudioServicesPlaySystemSound(1315)

        // Show local notification if app is in background
        scheduleLocalNotification(
            title: "New Order!",
            body: "Order #\(userInfo["orderNumber"] ?? "") received",
            userInfo: userInfo
        )
    }

    private func handleOrderUpdateNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle order status updates
        NotificationCenter.default.post(
            name: .orderStatusUpdated,
            object: userInfo
        )
    }

    private func handleLowStockNotification(_ userInfo: [AnyHashable: Any]) {
        scheduleLocalNotification(
            title: "Low Stock Alert",
            body: userInfo["message"] as? String ?? "Check inventory",
            userInfo: userInfo
        )
    }

    private func handleMarketingNotification(_ userInfo: [AnyHashable: Any]) {
        // Track marketing notification analytics
    }

    // MARK: - Local Notifications
    func scheduleLocalNotification(
        title: String,
        body: String,
        userInfo: [AnyHashable: Any] = [:],
        delay: TimeInterval = 0
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .defaultCritical
        content.userInfo = userInfo

        let trigger = delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        handleNotification(response.notification.request.content.userInfo)
        completionHandler()
    }
}
```

---

## 2.3 Order Modifications (Week 9)

**Database Schema:**
```sql
CREATE TABLE order_modifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id),
    modified_by UUID REFERENCES business_users(id),
    modification_type VARCHAR(50), -- 'add_item', 'remove_item', 'change_item', 'update_instructions', 'extend_time'
    previous_value JSONB,
    new_value JSONB,
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**iOS Implementation:**

**File:** `camerons-Bussiness-app/Core/Orders/OrderModificationView.swift`
```swift
import SwiftUI

struct OrderModificationView: View {
    let order: Order
    @StateObject private var viewModel: OrderModificationViewModel
    @Environment(\.dismiss) var dismiss

    init(order: Order) {
        self.order = order
        _viewModel = StateObject(wrappedValue: OrderModificationViewModel(order: order))
    }

    var body: some View {
        NavigationView {
            List {
                Section("Current Items") {
                    ForEach(viewModel.items) { item in
                        OrderItemModificationRow(
                            item: item,
                            onRemove: { viewModel.removeItem(item.id) },
                            onUpdateQuantity: { newQty in
                                viewModel.updateQuantity(item.id, quantity: newQty)
                            }
                        )
                    }
                }

                Section {
                    Button(action: { viewModel.showAddItem = true }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                            .foregroundColor(.brandPrimary)
                    }
                }

                Section("Special Instructions") {
                    TextEditor(text: $viewModel.specialInstructions)
                        .frame(height: 80)
                }

                Section("Extend Prep Time") {
                    Stepper("Add \(viewModel.extraPrepTime) minutes",
                           value: $viewModel.extraPrepTime,
                           in: 0...60,
                           step: 5)
                }

                Section("Modification Reason") {
                    TextEditor(text: $viewModel.modificationReason)
                        .frame(height: 60)
                }

                if viewModel.totalChanged {
                    Section {
                        HStack {
                            Text("Original Total:")
                            Spacer()
                            Text(order.formattedTotal)
                                .strikethrough()
                        }

                        HStack {
                            Text("New Total:")
                            Spacer()
                            Text(viewModel.newTotal)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.totalDifference > 0 ? .success : .error)
                        }
                    }
                }
            }
            .navigationTitle("Modify Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveModifications()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.hasChanges || viewModel.isLoading)
                }
            }
            .sheet(isPresented: $viewModel.showAddItem) {
                AddItemToOrderView(existingItems: viewModel.items) { newItem in
                    viewModel.addItem(newItem)
                }
            }
        }
    }
}

struct OrderItemModificationRow: View {
    let item: CartItem
    let onRemove: () -> Void
    let onUpdateQuantity: (Int) -> Void

    @State private var quantity: Int

    init(item: CartItem, onRemove: @escaping () -> Void, onUpdateQuantity: @escaping (Int) -> Void) {
        self.item = item
        self.onRemove = onRemove
        self.onUpdateQuantity = onUpdateQuantity
        _quantity = State(initialValue: item.quantity)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.menuItem.name)
                    .font(AppFonts.body)

                Text(item.menuItem.formattedPrice)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Stepper("\(quantity)", value: $quantity, in: 0...99)
                .onChange(of: quantity) { newValue in
                    if newValue == 0 {
                        onRemove()
                    } else {
                        onUpdateQuantity(newValue)
                    }
                }
        }
    }
}

@MainActor
class OrderModificationViewModel: ObservableObject {
    @Published var items: [CartItem]
    @Published var specialInstructions: String
    @Published var extraPrepTime: Int = 0
    @Published var modificationReason: String = ""
    @Published var showAddItem = false
    @Published var isLoading = false

    let originalOrder: Order
    private let originalItems: [CartItem]
    private let originalTotal: Double

    init(order: Order) {
        self.originalOrder = order
        self.items = order.items
        self.originalItems = order.items
        self.originalTotal = order.total
        self.specialInstructions = "" // Could load global order instructions
    }

    var hasChanges: Bool {
        items != originalItems ||
        extraPrepTime > 0 ||
        !specialInstructions.isEmpty ||
        !modificationReason.isEmpty
    }

    var totalChanged: Bool {
        newTotalValue != originalTotal
    }

    var newTotalValue: Double {
        items.reduce(0) { $0 + (Double($1.quantity) * $1.menuItem.price) }
    }

    var newTotal: String {
        String(format: "$%.2f", newTotalValue)
    }

    var totalDifference: Double {
        newTotalValue - originalTotal
    }

    func removeItem(_ itemId: String) {
        items.removeAll { $0.id == itemId }
    }

    func updateQuantity(_ itemId: String, quantity: Int) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].quantity = quantity
        }
    }

    func addItem(_ item: CartItem) {
        items.append(item)
    }

    func saveModifications() async {
        isLoading = true

        let modifications: [[String: Any]] = [
            [
                "type": "update_items",
                "previousValue": originalItems.map { ["id": $0.id, "quantity": $0.quantity] },
                "newValue": items.map { ["id": $0.id, "quantity": $0.quantity] },
                "reason": modificationReason
            ],
            [
                "type": "extend_time",
                "previousValue": ["minutes": 0],
                "newValue": ["minutes": extraPrepTime],
                "reason": "Extended prep time"
            ]
        ]

        do {
            let endpoint = "\(Configuration.apiURL)/orders/\(originalOrder.id)/modify"
            let body: [String: Any] = [
                "modifications": modifications,
                "newTotal": newTotalValue,
                "reason": modificationReason
            ]

            let _ = try await APIClient.shared.post(endpoint, body: body)

            // Show success
            // Notify dashboard to refresh
            NotificationCenter.default.post(name: .orderModified, object: originalOrder.id)
        } catch {
            print("Failed to save modifications: \(error)")
        }

        isLoading = false
    }
}
```

---

## 2.4 Feedback & Reviews (Week 10)

**Database Schema:**
```sql
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id),
    customer_id UUID NOT NULL REFERENCES customers(id),
    overall_rating INT CHECK (overall_rating BETWEEN 1 AND 5),
    food_rating INT CHECK (food_rating BETWEEN 1 AND 5),
    service_rating INT CHECK (service_rating BETWEEN 1 AND 5),
    delivery_rating INT CHECK (delivery_rating BETWEEN 1 AND 5),
    comment TEXT,
    photos TEXT[], -- Array of image URLs
    response TEXT, -- Business response
    responded_by UUID REFERENCES business_users(id),
    responded_at TIMESTAMP,
    is_published BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE review_issues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES reviews(id),
    issue_type VARCHAR(50), -- 'cold_food', 'wrong_order', 'missing_items', 'late_delivery', 'poor_quality'
    resolution_offered VARCHAR(100), -- 'refund', 'discount', 'free_item', 'apology'
    is_resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reviews_customer ON reviews(customer_id);
CREATE INDEX idx_reviews_order ON reviews(order_id);
CREATE INDEX idx_reviews_rating ON reviews(overall_rating);
```

**iOS Implementation:**

**File:** `camerons-Bussiness-app/Core/Reviews/ReviewsView.swift`
```swift
import SwiftUI

struct ReviewsView: View {
    @StateObject private var viewModel = ReviewsViewModel()
    @State private var selectedFilter: ReviewFilter = .all

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Average Rating Header
                ReviewStatsHeader(
                    averageRating: viewModel.averageRating,
                    totalReviews: viewModel.totalReviews,
                    ratingDistribution: viewModel.ratingDistribution
                )
                .padding()

                // Filter Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(ReviewFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.displayName,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Reviews List
                List {
                    ForEach(filteredReviews) { review in
                        ReviewCard(review: review) {
                            viewModel.selectedReview = review
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Reviews")
            .sheet(item: $viewModel.selectedReview) { review in
                ReviewDetailView(review: review) { response in
                    viewModel.respondToReview(review.id, response: response)
                }
            }
        }
        .onAppear {
            viewModel.loadReviews()
        }
    }

    var filteredReviews: [Review] {
        switch selectedFilter {
        case .all:
            return viewModel.reviews
        case .fiveStar:
            return viewModel.reviews.filter { $0.overallRating == 5 }
        case .fourStar:
            return viewModel.reviews.filter { $0.overallRating == 4 }
        case .threeStar:
            return viewModel.reviews.filter { $0.overallRating == 3 }
        case .needsResponse:
            return viewModel.reviews.filter { $0.response == nil }
        case .withIssues:
            return viewModel.reviews.filter { !$0.issues.isEmpty }
        }
    }
}

struct ReviewStatsHeader: View {
    let averageRating: Double
    let totalReviews: Int
    let ratingDistribution: [Int: Int]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Average Rating
            HStack(spacing: Spacing.xl) {
                VStack {
                    Text(String(format: "%.1f", averageRating))
                        .font(.system(size: 48, weight: .bold))

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(averageRating.rounded()) ? "star.fill" : "star")
                                .foregroundColor(.warning)
                        }
                    }

                    Text("\(totalReviews) reviews")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Divider()
                    .frame(height: 100)

                // Distribution
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach((1...5).reversed(), id: \.self) { rating in
                        RatingBar(
                            rating: rating,
                            count: ratingDistribution[rating] ?? 0,
                            total: totalReviews
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: AppShadow.sm, radius: 4)
    }
}

struct RatingBar: View {
    let rating: Int
    let count: Int
    let total: Int

    var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text("\(rating)")
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)
                .frame(width: 12)

            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(.warning)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))

                    Rectangle()
                        .fill(Color.warning)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)

            Text("\(count)")
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct ReviewCard: View {
    let review: Review
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(review.customerName)
                            .font(AppFonts.headline)

                        Text(review.createdAt.formatted(.dateTime.month().day().year()))
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= review.overallRating ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundColor(.warning)
                        }
                    }
                }

                if let comment = review.comment, !comment.isEmpty {
                    Text(comment)
                        .font(AppFonts.body)
                        .lineLimit(3)
                }

                // Issue Badges
                if !review.issues.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(review.issues, id: \.type) { issue in
                                Text(issue.type.displayName)
                                    .font(AppFonts.caption)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, 2)
                                    .background(Color.error.opacity(0.2))
                                    .foregroundColor(.error)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }

                // Response Status
                if review.response != nil {
                    Label("Responded", systemImage: "checkmark.circle.fill")
                        .font(AppFonts.caption)
                        .foregroundColor(.success)
                } else {
                    Label("Needs Response", systemImage: "exclamationmark.circle")
                        .font(AppFonts.caption)
                        .foregroundColor(.warning)
                }
            }
            .padding()
        }
        .buttonStyle(.plain)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2, y: 1)
    }
}

enum ReviewFilter: String, CaseIterable {
    case all
    case fiveStar = "5_star"
    case fourStar = "4_star"
    case threeStar = "3_star"
    case needsResponse = "needs_response"
    case withIssues = "with_issues"

    var displayName: String {
        switch self {
        case .all: return "All"
        case .fiveStar: return "5 ⭐"
        case .fourStar: return "4 ⭐"
        case .threeStar: return "≤3 ⭐"
        case .needsResponse: return "Needs Response"
        case .withIssues: return "With Issues"
        }
    }
}

// MARK: - Models
struct Review: Codable, Identifiable {
    let id: String
    let orderId: String
    let customerId: String
    let customerName: String
    let overallRating: Int
    let foodRating: Int?
    let serviceRating: Int?
    let deliveryRating: Int?
    let comment: String?
    let photos: [String]
    var response: String?
    let respondedBy: String?
    let respondedAt: Date?
    let isPublished: Bool
    let createdAt: Date
    var issues: [ReviewIssue]
}

struct ReviewIssue: Codable {
    let id: String
    let type: IssueType
    let resolutionOffered: String?
    let isResolved: Bool
}

enum IssueType: String, Codable {
    case coldFood = "cold_food"
    case wrongOrder = "wrong_order"
    case missingItems = "missing_items"
    case lateDelivery = "late_delivery"
    case poorQuality = "poor_quality"

    var displayName: String {
        switch self {
        case .coldFood: return "Cold Food"
        case .wrongOrder: return "Wrong Order"
        case .missingItems: return "Missing Items"
        case .lateDelivery: return "Late Delivery"
        case .poorQuality: return "Poor Quality"
        }
    }
}
```

---

# Phase 3: Operational Excellence
**Timeline:** 4-5 weeks
**Goal:** Streamline operations and improve efficiency

## 3.1 Inventory Management (Week 11-12)

### Database Schema

```sql
CREATE TABLE ingredients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    unit VARCHAR(50), -- 'lb', 'oz', 'kg', 'units', 'gal'
    current_stock DECIMAL(10,2) DEFAULT 0,
    par_level DECIMAL(10,2), -- Minimum stock level
    reorder_point DECIMAL(10,2), -- When to reorder
    cost_per_unit DECIMAL(10,2),
    supplier_id UUID REFERENCES suppliers(id),
    category VARCHAR(100), -- 'protein', 'produce', 'dairy', 'dry_goods'
    storage_location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE recipe_ingredients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID NOT NULL REFERENCES menu_items(id),
    ingredient_id UUID NOT NULL REFERENCES ingredients(id),
    quantity_needed DECIMAL(10,2) NOT NULL,
    unit VARCHAR(50)
);

CREATE TABLE inventory_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ingredient_id UUID NOT NULL REFERENCES ingredients(id),
    transaction_type VARCHAR(50), -- 'receive', 'use', 'waste', 'adjustment', 'transfer'
    quantity DECIMAL(10,2) NOT NULL,
    unit VARCHAR(50),
    reason TEXT,
    order_id UUID REFERENCES orders(id),
    performed_by UUID REFERENCES business_users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE purchase_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplier_id UUID REFERENCES suppliers(id),
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'sent', 'received', 'cancelled'
    order_number VARCHAR(100),
    total_cost DECIMAL(10,2),
    expected_delivery DATE,
    received_at TIMESTAMP,
    created_by UUID REFERENCES business_users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    payment_terms TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### iOS Implementation

**File:** `camerons-Bussiness-app/Core/Inventory/InventoryView.swift`
```swift
import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @State private var showAddIngredient = false
    @State private var showFilters = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Quick Stats
                InventoryStatsBar(
                    lowStockCount: viewModel.lowStockItems.count,
                    outOfStockCount: viewModel.outOfStockItems.count,
                    totalValue: viewModel.totalInventoryValue
                )
                .padding()

                // Tabs
                Picker("", selection: $selectedTab) {
                    Text("Ingredients").tag(0)
                    Text("Low Stock").tag(1)
                    Text("Orders").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                TabView(selection: $selectedTab) {
                    IngredientsListTab(
                        ingredients: viewModel.ingredients,
                        onTap: { ingredient in
                            viewModel.selectedIngredient = ingredient
                        }
                    )
                    .tag(0)

                    LowStockTab(
                        items: viewModel.lowStockItems,
                        onReorder: { ingredient in
                            viewModel.createPurchaseOrder(for: ingredient)
                        }
                    )
                    .tag(1)

                    PurchaseOrdersTab(orders: viewModel.purchaseOrders)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showAddIngredient = true }) {
                            Label("Add Ingredient", systemImage: "plus")
                        }

                        Button(action: { showFilters = true }) {
                            Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                        }

                        Button(action: { viewModel.exportInventory() }) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $viewModel.selectedIngredient) { ingredient in
                IngredientDetailView(ingredient: ingredient)
            }
            .sheet(isPresented: $showAddIngredient) {
                AddIngredientView { newIngredient in
                    viewModel.addIngredient(newIngredient)
                }
            }
        }
        .onAppear {
            viewModel.loadInventory()
        }
    }
}

struct InventoryStatsBar: View {
    let lowStockCount: Int
    let outOfStockCount: Int
    let totalValue: Double

    var body: some View {
        HStack(spacing: Spacing.lg) {
            StatCard(
                icon: "exclamationmark.triangle.fill",
                value: "\(lowStockCount)",
                label: "Low Stock",
                color: .warning
            )

            StatCard(
                icon: "xmark.circle.fill",
                value: "\(outOfStockCount)",
                label: "Out of Stock",
                color: .error
            )

            StatCard(
                icon: "dollarsign.circle.fill",
                value: String(format: "$%.0f", totalValue),
                label: "Total Value",
                color: .success
            )
        }
    }
}

struct IngredientsListTab: View {
    let ingredients: [Ingredient]
    let onTap: (Ingredient) -> Void

    var body: some View {
        List(ingredients) { ingredient in
            IngredientRow(ingredient: ingredient)
                .onTapGesture {
                    onTap(ingredient)
                }
        }
        .listStyle(.plain)
    }
}

struct IngredientRow: View {
    let ingredient: Ingredient

    var stockStatus: StockStatus {
        if ingredient.currentStock == 0 {
            return .outOfStock
        } else if ingredient.currentStock <= ingredient.reorderPoint {
            return .lowStock
        } else if ingredient.currentStock <= ingredient.parLevel {
            return .belowPar
        } else {
            return .good
        }
    }

    var body: some View {
        HStack {
            // Status Indicator
            Circle()
                .fill(stockStatus.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(AppFonts.body)

                Text("\(ingredient.currentStock, specifier: "%.1f") \(ingredient.unit)")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(ingredient.formattedCost)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)

                Text(stockStatus.displayName)
                    .font(AppFonts.caption)
                    .foregroundColor(stockStatus.color)
            }
        }
        .padding(.vertical, 4)
    }
}

enum StockStatus {
    case good
    case belowPar
    case lowStock
    case outOfStock

    var color: Color {
        switch self {
        case .good: return .success
        case .belowPar: return .info
        case .lowStock: return .warning
        case .outOfStock: return .error
        }
    }

    var displayName: String {
        switch self {
        case .good: return "Good"
        case .belowPar: return "Below Par"
        case .lowStock: return "Low"
        case .outOfStock: return "Out"
        }
    }
}

// MARK: - Models
struct Ingredient: Codable, Identifiable {
    let id: String
    let name: String
    let unit: String
    var currentStock: Double
    let parLevel: Double
    let reorderPoint: Double
    let costPerUnit: Double
    let supplierId: String?
    let category: String
    let storageLocation: String?

    var formattedCost: String {
        return String(format: "$%.2f/%@", costPerUnit, unit)
    }

    var totalValue: Double {
        return currentStock * costPerUnit
    }
}

struct PurchaseOrder: Codable, Identifiable {
    let id: String
    let supplierId: String
    let supplierName: String
    var status: POStatus
    let orderNumber: String
    let totalCost: Double
    let expectedDelivery: Date
    let receivedAt: Date?
    let items: [POItem]
    let createdAt: Date
}

enum POStatus: String, Codable {
    case pending
    case sent
    case received
    case cancelled

    var color: Color {
        switch self {
        case .pending: return .warning
        case .sent: return .info
        case .received: return .success
        case .cancelled: return .error
        }
    }
}

struct POItem: Codable, Identifiable {
    let id: String
    let ingredientId: String
    let ingredientName: String
    let quantity: Double
    let unit: String
    let costPerUnit: Double

    var subtotal: Double {
        return quantity * costPerUnit
    }
}
```

**Automatic Stock Deduction:**

**Backend Logic:**
```javascript
// After order is completed, deduct ingredients
async function deductIngredients(orderId) {
    const order = await Order.findByPk(orderId, {
        include: [{ model: OrderItem, include: [MenuItem] }]
    });

    for (const item of order.items) {
        const recipeIngredients = await RecipeIngredient.findAll({
            where: { menuItemId: item.menuItemId }
        });

        for (const recipeIng of recipeIngredients) {
            const quantityToDeduct = recipeIng.quantityNeeded * item.quantity;

            // Deduct from stock
            await Ingredient.decrement('currentStock', {
                by: quantityToDeduct,
                where: { id: recipeIng.ingredientId }
            });

            // Log transaction
            await InventoryTransaction.create({
                ingredientId: recipeIng.ingredientId,
                transactionType: 'use',
                quantity: quantityToDeduct,
                unit: recipeIng.unit,
                orderId: orderId,
                reason: `Used for order #${order.orderNumber}`
            });

            // Check if below reorder point
            const ingredient = await Ingredient.findByPk(recipeIng.ingredientId);
            if (ingredient.currentStock <= ingredient.reorderPoint) {
                await sendLowStockAlert(ingredient);

                // Auto-create purchase order if enabled
                if (process.env.AUTO_REORDER_ENABLED === 'true') {
                    await createAutoPurchaseOrder(ingredient);
                }
            }
        }
    }
}
```

---

## 3.2 Delivery Management (Week 13-14)

### Database Schema

```sql
CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES business_users(id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    phone VARCHAR(20),
    vehicle_type VARCHAR(50),
    license_plate VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    current_location GEOGRAPHY(POINT, 4326),
    status VARCHAR(50) DEFAULT 'offline', -- 'offline', 'available', 'busy', 'break'
    total_deliveries INT DEFAULT 0,
    average_rating DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE delivery_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    store_id UUID REFERENCES stores(id),
    zone_polygon GEOGRAPHY(POLYGON, 4326),
    delivery_fee DECIMAL(10,2),
    min_order_amount DECIMAL(10,2),
    estimated_time INT, -- minutes
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id),
    driver_id UUID REFERENCES drivers(id),
    pickup_address TEXT,
    delivery_address TEXT NOT NULL,
    pickup_location GEOGRAPHY(POINT, 4326),
    delivery_location GEOGRAPHY(POINT, 4326),
    distance_miles DECIMAL(5,2),
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'failed'
    assigned_at TIMESTAMP,
    picked_up_at TIMESTAMP,
    delivered_at TIMESTAMP,
    delivery_photo_url TEXT,
    customer_signature TEXT,
    delivery_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_drivers_location ON drivers USING GIST(current_location);
CREATE INDEX idx_drivers_status ON drivers(status, is_active);
CREATE INDEX idx_deliveries_status ON deliveries(status);
```

### iOS Implementation

**File:** `camerons-Bussiness-app/Core/Delivery/DeliveryDashboardView.swift`
```swift
import SwiftUI
import MapKit

struct DeliveryDashboardView: View {
    @StateObject private var viewModel = DeliveryViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Active Deliveries Stats
                DeliveryStatsBar(
                    activeDeliveries: viewModel.activeDeliveries.count,
                    availableDrivers: viewModel.availableDrivers.count,
                    avgDeliveryTime: viewModel.avgDeliveryTime
                )
                .padding()

                // Tabs
                Picker("", selection: $selectedTab) {
                    Text("Active").tag(0)
                    Text("Drivers").tag(1)
                    Text("Map").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                TabView(selection: $selectedTab) {
                    ActiveDeliveriesTab(deliveries: viewModel.activeDeliveries)
                        .tag(0)

                    DriversTab(
                        drivers: viewModel.drivers,
                        onAssignDelivery: { driver, delivery in
                            viewModel.assignDelivery(delivery, to: driver)
                        }
                    )
                    .tag(1)

                    DeliveryMapTab(
                        deliveries: viewModel.activeDeliveries,
                        drivers: viewModel.drivers
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Delivery Management")
        }
        .onAppear {
            viewModel.startLiveTracking()
        }
    }
}

struct DeliveryStatsBar: View {
    let activeDeliveries: Int
    let availableDrivers: Int
    let avgDeliveryTime: Int

    var body: some View {
        HStack(spacing: Spacing.lg) {
            StatCard(
                icon: "shippingbox.fill",
                value: "\(activeDeliveries)",
                label: "Active",
                color: .brandPrimary
            )

            StatCard(
                icon: "figure.walk",
                value: "\(availableDrivers)",
                label: "Available",
                color: .success
            )

            StatCard(
                icon: "clock.fill",
                value: "\(avgDeliveryTime)m",
                label: "Avg Time",
                color: .info
            )
        }
    }
}

struct ActiveDeliveriesTab: View {
    let deliveries: [Delivery]

    var body: some View {
        List(deliveries) { delivery in
            DeliveryCard(delivery: delivery)
        }
        .listStyle(.plain)
    }
}

struct DeliveryCard: View {
    let delivery: Delivery

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Order #\(delivery.orderNumber)")
                        .font(AppFonts.headline)

                    Text(delivery.customerName)
                        .font(AppFonts.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                DeliveryStatusBadge(status: delivery.status)
            }

            // Driver Info
            if let driver = delivery.driver {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.brandPrimary)

                    Text(driver.fullName)
                        .font(AppFonts.body)

                    Spacer()

                    Button(action: { /* Call driver */ }) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.success)
                    }
                }
            } else {
                Button(action: { /* Assign driver */ }) {
                    Label("Assign Driver", systemImage: "person.badge.plus")
                        .font(AppFonts.subheadline)
                        .foregroundColor(.brandPrimary)
                }
            }

            // Address
            HStack(alignment: .top) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.error)

                Text(delivery.deliveryAddress)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            // ETA
            if delivery.status == .inTransit || delivery.status == .pickedUp {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.info)

                    Text("ETA: \(delivery.estimatedArrival.formatted(.dateTime.hour().minute()))")
                        .font(AppFonts.caption)
                        .foregroundColor(.info)
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2, y: 1)
    }
}

struct DeliveryMapTab: View {
    let deliveries: [Delivery]
    let drivers: [Driver]

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: deliveryAnnotations + driverAnnotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                if annotation.type == .delivery {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.error)
                        .font(.system(size: 30))
                } else {
                    Image(systemName: "car.fill")
                        .foregroundColor(.brandPrimary)
                        .font(.system(size: 24))
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }

    var deliveryAnnotations: [MapAnnotationItem] {
        deliveries.compactMap { delivery in
            guard let location = delivery.deliveryLocation else { return nil }
            return MapAnnotationItem(
                id: delivery.id,
                coordinate: location,
                type: .delivery
            )
        }
    }

    var driverAnnotations: [MapAnnotationItem] {
        drivers.compactMap { driver in
            guard let location = driver.currentLocation else { return nil }
            return MapAnnotationItem(
                id: driver.id,
                coordinate: location,
                type: .driver
            )
        }
    }
}

struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType

    enum AnnotationType {
        case delivery
        case driver
    }
}

// MARK: - Models
struct Delivery: Codable, Identifiable {
    let id: String
    let orderId: String
    let orderNumber: String
    let customerName: String
    var driverId: String?
    var driver: Driver?
    let pickupAddress: String
    let deliveryAddress: String
    let pickupLocation: CLLocationCoordinate2D?
    let deliveryLocation: CLLocationCoordinate2D?
    let distanceMiles: Double
    var status: DeliveryStatus
    let assignedAt: Date?
    let pickedUpAt: Date?
    let deliveredAt: Date?
    var estimatedArrival: Date

    enum CodingKeys: String, CodingKey {
        case id, orderId, orderNumber, customerName, driverId, driver
        case pickupAddress, deliveryAddress, distanceMiles, status
        case assignedAt, pickedUpAt, deliveredAt, estimatedArrival
    }
}

enum DeliveryStatus: String, Codable {
    case pending
    case assigned
    case pickedUp = "picked_up"
    case inTransit = "in_transit"
    case delivered
    case failed

    var color: Color {
        switch self {
        case .pending: return .warning
        case .assigned: return .info
        case .pickedUp: return .brandPrimary
        case .inTransit: return .success
        case .delivered: return .gray
        case .failed: return .error
        }
    }

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .assigned: return "Assigned"
        case .pickedUp: return "Picked Up"
        case .inTransit: return "In Transit"
        case .delivered: return "Delivered"
        case .failed: return "Failed"
        }
    }
}

struct Driver: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let phone: String
    let vehicleType: String?
    let licensePlate: String?
    var isActive: Bool
    var currentLocation: CLLocationCoordinate2D?
    var status: DriverStatus
    let totalDeliveries: Int
    let averageRating: Double?

    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

enum DriverStatus: String, Codable {
    case offline
    case available
    case busy
    case onBreak = "break"

    var color: Color {
        switch self {
        case .offline: return .gray
        case .available: return .success
        case .busy: return .warning
        case .onBreak: return .info
        }
    }
}
```

---

# Phase 4: Scale & Growth
**Timeline:** 2-3 weeks
**Goal:** Enable business scaling and advanced features

## 4.1 Multi-Location Support (Week 15)

Enables management of multiple restaurant locations from single app.

**Key Features:**
- Store selector for admins
- Per-store inventory
- Cross-location reporting
- Store-specific settings

## 4.2 Advanced Analytics (Week 16)

**New Metrics:**
- Profit margin analysis
- Customer lifetime value
- Menu engineering matrix (Stars/Plowhorses/Puzzles/Dogs)
- Labor cost percentage
- Food cost percentage

**Export Formats:** CSV, PDF, Excel

## 4.3 Third-Party Integrations (Week 17)

- DoorDash API integration
- Uber Eats webhook handling
- Unified order dashboard
- Platform-specific menu pricing

---

# Technical Architecture

## System Overview
```
iOS App (SwiftUI) → API Gateway → Backend Services → PostgreSQL + Redis
                              ↓
                    Third-Party APIs (Stripe, Twilio, etc.)
```

## Technology Stack
- **Frontend**: SwiftUI, Combine, MapKit
- **Backend**: Node.js, Express, Socket.io
- **Database**: PostgreSQL 15+, Redis 7+
- **Payments**: Stripe
- **SMS**: Twilio
- **Hosting**: AWS (ECS/RDS/ElastiCache)

---

# API Specifications

## Base URL
```
Production: https://api.camerons.com/v1
Development: http://localhost:3000/v1
```

## Core Endpoints
```
Auth:       POST /auth/login, /auth/refresh
Orders:     GET/POST /orders, PUT /orders/:id/status
Menu:       GET/POST/PUT/DELETE /menu
Customers:  GET/POST/PUT /customers
Payments:   POST /payments/intent, /payments/refund
Analytics:  GET /analytics/dashboard, /analytics/export
```

## Authentication
All requests require JWT:
```
Authorization: Bearer <token>
```

---

# Testing Strategy

## Coverage Goals
- Unit Tests: 70%+ coverage
- Integration Tests: Critical paths
- E2E Tests: Main user flows

## Test Frameworks
- **iOS**: XCTest + XCUITest
- **Backend**: Jest + Supertest
- **Load Testing**: Apache JMeter

---

# Deployment Plan

## Environments
1. **Development**: Local (Docker Compose)
2. **Staging**: AWS ECS + RDS (mirrored prod)
3. **Production**: AWS Multi-AZ deployment

## CI/CD Pipeline
```
GitHub → GitHub Actions → Build & Test → Docker → ECS Deploy → Monitor
```

## Monitoring
- CloudWatch metrics & logs
- Error tracking (Sentry)
- Uptime monitoring (UptimeRobot)
- Performance (New Relic)

---

# Implementation Checklist

## Phase 1 ✅ (Weeks 1-6)
- [ ] Backend setup (Node.js/Express/PostgreSQL/Redis)
- [ ] Stripe payment integration
- [ ] WebSocket real-time orders
- [ ] Kitchen Display System
- [ ] Customer database & profiles

## Phase 2 ✅ (Weeks 7-10)
- [ ] Loyalty points system
- [ ] SMS notifications (Twilio)
- [ ] Push notifications
- [ ] Order modifications
- [ ] Review & feedback system

## Phase 3 ✅ (Weeks 11-14)
- [ ] Inventory management
- [ ] Auto stock deduction
- [ ] Purchase orders
- [ ] Delivery management
- [ ] Driver tracking

## Phase 4 ✅ (Weeks 15-17)
- [ ] Multi-location support
- [ ] Advanced analytics
- [ ] Export reports
- [ ] Third-party integrations

## Testing & Deployment ✅
- [ ] Unit tests (70%+ coverage)
- [ ] Integration tests
- [ ] E2E tests
- [ ] Staging environment
- [ ] Production deployment
- [ ] Monitoring & alerts

---

# Cost Estimates

## Development Phase (16-20 weeks)
- Backend Development: $50-80k
- iOS Development: $30-50k
- Total: **$80-130k**

## Monthly Operating Costs
- AWS Infrastructure: $500-2000
- Stripe: 2.9% + $0.30/transaction
- Twilio SMS: $0.0075/message
- Monitoring: $50-200
- **Total: $600-2500/month + transaction fees**

---

# Success Metrics

Track these KPIs post-launch:
- Order processing time < 2 minutes
- Payment success rate > 98%
- System uptime > 99.9%
- Customer satisfaction > 4.5/5 stars
- Average order value increase with loyalty

---

# Conclusion

This roadmap provides a **complete path from MVP to production-ready restaurant management system** with feature parity to industry leaders.

## Next Steps

### Week 1 (Immediate)
1. Set up development environment
2. Create Stripe test account
3. Initialize backend repository
4. Configure PostgreSQL database

### Week 2-3 (Quick Wins)
- Get real-time orders working
- Implement basic payment flow
- Build Kitchen Display System

### Month 2-3 (Long-term)
- Complete inventory management
- Add delivery features
- Implement advanced analytics

## Final Recommendations
1. ✅ **Start with Phase 1** - Focus on core features first
2. ✅ **Iterate based on feedback** - Real users guide priorities
3. ✅ **Monitor metrics** - Data-driven decisions
4. ✅ **Plan for scale** - Design for 10x growth
5. ✅ **Security first** - PCI compliance, encryption, auth

---

**Document Complete** | **Total: 6,000+ Lines** | **Timeline: 16-20 Weeks**

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
