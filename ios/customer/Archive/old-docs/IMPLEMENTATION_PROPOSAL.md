# Implementation Proposal - Cameron's Customer App Feature Roadmap

**Document Version:** 1.0
**Date:** November 13, 2025
**Status:** Proposed
**Author:** Cameron's Development Team

---

## Executive Summary

This document outlines a comprehensive implementation plan to bring Cameron's Customer App to feature parity with major competitors (DoorDash, Uber Eats, Grubhub) and enable full market launch.

**Current State:** 35-40% feature parity, 10,000+ lines of code, MVVM architecture
**Target State:** 90%+ feature parity, production-ready, scalable platform
**Timeline:** 52 weeks (4 phases)
**Estimated Cost:** $250,000 - $400,000 (with team)

---

## Table of Contents

1. [Phase 1: Launch Readiness (Weeks 1-16)](#phase-1-launch-readiness)
2. [Phase 2: Competitive Parity (Weeks 17-30)](#phase-2-competitive-parity)
3. [Phase 3: Engagement & Retention (Weeks 31-42)](#phase-3-engagement--retention)
4. [Phase 4: Platform & Scale (Weeks 43-52)](#phase-4-platform--scale)
5. [Resource Requirements](#resource-requirements)
6. [Risk Assessment](#risk-assessment)
7. [Success Metrics](#success-metrics)
8. [Budget Breakdown](#budget-breakdown)

---

## Phase 1: Launch Readiness (Weeks 1-16)

**Goal:** Enable real order processing and basic customer operations
**Budget:** $60,000 - $90,000
**Team:** 2 iOS developers, 1 backend developer, 1 QA

---

### Feature 1.1: Payment Processing Integration

#### Business Value
- **Critical** - Cannot process orders without this
- Enables revenue generation
- Industry standard requirement

#### Technical Specification

**iOS Implementation:**
```swift
// New files to create:
- Shared/Services/StripeService.swift
- Core/Payment/ViewModels/PaymentViewModel.swift
- Core/Payment/Views/PaymentMethodsView.swift
- Core/Payment/Views/AddPaymentView.swift
- Core/Payment/Models/PaymentMethod.swift
- Core/Checkout/Views/PaymentSelectionView.swift
```

**Dependencies:**
- Stripe iOS SDK (via SPM)
- Backend: Stripe API integration
- PCI compliance requirements

**Implementation Details:**

1. **Stripe SDK Integration** (Week 1)
   - Add Stripe iOS SDK via Swift Package Manager
   - Configure publishable key
   - Set up payment sheet UI
   - Implement SCA (Strong Customer Authentication)

2. **Payment Methods Management** (Week 1-2)
   ```swift
   class PaymentViewModel: ObservableObject {
       @Published var savedMethods: [PaymentMethod] = []
       @Published var defaultMethod: PaymentMethod?

       func addPaymentMethod() async throws
       func removePaymentMethod(_ id: String) async throws
       func setDefaultPaymentMethod(_ id: String) async throws
   }
   ```

3. **Apple Pay Integration** (Week 2)
   - Add Apple Pay capability to project
   - Configure merchant ID
   - Implement PKPaymentAuthorizationViewController
   - Test in Sandbox

4. **Google Pay Integration** (Week 2)
   - Add Google Pay SDK
   - Configure merchant account
   - Implement payment flow
   - Test in Sandbox

5. **Checkout Flow Enhancement** (Week 3)
   ```swift
   // Update CheckoutView.swift
   - Add payment method selection
   - Display saved cards
   - "Add new card" option
   - Default payment indicator
   - Payment security badges
   ```

6. **Backend Integration** (Week 3-4)
   - Create payment intent endpoint
   - Confirm payment endpoint
   - Refund endpoint
   - Webhook handlers for payment events
   - Store payment method tokens securely

7. **Security & Compliance** (Week 4)
   - Implement tokenization
   - No PCI data storage on device
   - Secure API communication (HTTPS)
   - Payment method encryption
   - Fraud detection hooks

**Testing Requirements:**
- Unit tests for PaymentViewModel
- Integration tests with Stripe test mode
- UI tests for payment flows
- Security penetration testing
- PCI compliance audit

**Acceptance Criteria:**
- ✅ User can add credit/debit cards
- ✅ User can add Apple Pay
- ✅ User can add Google Pay
- ✅ User can save multiple payment methods
- ✅ User can set default payment method
- ✅ User can remove payment methods
- ✅ Payment is processed securely
- ✅ Order is confirmed after successful payment
- ✅ Refunds can be processed
- ✅ PCI compliant

**Estimated Effort:** 4 weeks (1 developer)
**Dependencies:** Stripe account, backend API
**Risk Level:** Medium (external dependency, compliance)

---

### Feature 1.2: Address Management System

#### Business Value
- **Critical** - Required for delivery orders
- Improves user experience
- Reduces checkout friction

#### Technical Specification

**iOS Implementation:**
```swift
// New files to create:
- Core/Profile/Models/Address.swift
- Core/Profile/ViewModels/AddressViewModel.swift
- Core/Profile/Views/AddressListView.swift
- Core/Profile/Views/AddAddressView.swift
- Core/Profile/Views/EditAddressView.swift
- Shared/Services/LocationService.swift
```

**Dependencies:**
- Google Places API (or Apple MapKit)
- Core Location framework
- Backend: Address storage API

**Implementation Details:**

1. **Address Data Model** (Week 5, Day 1)
   ```swift
   struct Address: Identifiable, Codable {
       let id: String
       var nickname: String // "Home", "Work", etc.
       var street: String
       var apartment: String?
       var city: String
       var state: String
       var zipCode: String
       var country: String
       var latitude: Double
       var longitude: Double
       var deliveryInstructions: String?
       var isDefault: Bool
       var createdAt: Date
   }
   ```

2. **Google Places Autocomplete** (Week 5)
   - Integrate Google Places SDK
   - Implement address search
   - Parse place details to Address model
   - Display autocomplete suggestions
   - Handle selection and validation

3. **Location Services** (Week 5)
   ```swift
   class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
       func getCurrentLocation() async throws -> CLLocation
       func reverseGeocode(_ location: CLLocation) async throws -> Address
       func requestPermission()
   }
   ```

4. **Address Management UI** (Week 6)
   - Address list view with saved addresses
   - Add new address flow
   - Edit existing address
   - Delete address (swipe action)
   - Set default address (star icon)
   - "Use current location" button
   - Address validation

5. **Checkout Integration** (Week 6)
   ```swift
   // Update CheckoutView.swift
   - Display selected address
   - "Change address" button
   - Show default address by default
   - Validate address for delivery zone
   - Show delivery instructions
   ```

6. **Address Validation** (Week 6)
   - Format validation
   - Delivery zone check
   - Address verification via API
   - Distance from restaurant calculation
   - Delivery fee calculation based on distance

7. **Backend Integration** (Week 6)
   - Save address endpoint
   - Update address endpoint
   - Delete address endpoint
   - Get addresses endpoint
   - Validate delivery zone endpoint

**Testing Requirements:**
- Location permission flow testing
- Autocomplete accuracy testing
- Address parsing validation
- UI tests for address management
- Delivery zone validation testing

**Acceptance Criteria:**
- ✅ User can add addresses via autocomplete
- ✅ User can use current location
- ✅ User can save multiple addresses
- ✅ User can set default address
- ✅ User can nickname addresses
- ✅ User can add delivery instructions
- ✅ User can edit/delete addresses
- ✅ Addresses are validated for delivery zone
- ✅ Addresses sync with backend
- ✅ Works offline with cached addresses

**Estimated Effort:** 2 weeks (1 developer)
**Dependencies:** Google Places API key, backend API
**Risk Level:** Low

---

### Feature 1.3: Push Notifications

#### Business Value
- **Critical** - Keep users informed of order status
- Improve user engagement
- Reduce support inquiries

#### Technical Specification

**iOS Implementation:**
```swift
// New files to create:
- Shared/Services/NotificationService.swift
- Shared/Models/NotificationPayload.swift
- Core/Profile/Views/NotificationSettingsView.swift
```

**Dependencies:**
- APNs (Apple Push Notification service)
- Backend: Push notification server
- Firebase Cloud Messaging (optional)

**Implementation Details:**

1. **APNs Setup** (Week 7, Day 1-2)
   - Enable Push Notifications capability
   - Create APNs certificate/key
   - Configure in Apple Developer portal
   - Test with sandbox environment

2. **Notification Service** (Week 7)
   ```swift
   @MainActor
   class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
       @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

       func requestPermission() async throws -> Bool
       func registerForRemoteNotifications()
       func handleNotification(_ notification: UNNotification)
       func saveDeviceToken(_ token: Data) async throws
   }
   ```

3. **Notification Types** (Week 7)
   ```swift
   enum NotificationType: String, Codable {
       case orderConfirmed = "order_confirmed"
       case orderPreparing = "order_preparing"
       case orderReady = "order_ready"
       case driverAssigned = "driver_assigned"
       case outForDelivery = "out_for_delivery"
       case delivered = "delivered"
       case cancelled = "cancelled"
       case promotion = "promotion"
       case reminder = "reminder"
   }
   ```

4. **Notification Handling** (Week 7)
   - Foreground notifications (banner)
   - Background notifications
   - Deep linking to order details
   - Action buttons (Track Order, Contact Support)
   - Notification center integration
   - Badge count management

5. **Notification Settings** (Week 8)
   ```swift
   // NotificationSettingsView.swift
   - Order updates toggle
   - Promotional notifications toggle
   - Special offers toggle
   - Push notifications master toggle
   - Quiet hours setting
   ```

6. **Backend Integration** (Week 8)
   - Register device token endpoint
   - Update notification preferences endpoint
   - Trigger notifications on order events
   - Silent push for data updates
   - Rich notification support (images, actions)

7. **Rich Notifications** (Week 8)
   - Order status with image
   - Driver photo and name
   - Estimated time
   - Quick actions (View Order, Contact)
   - Custom sound per notification type

**Testing Requirements:**
- Permission flow testing
- Notification delivery testing
- Deep link navigation testing
- Action button testing
- Background/foreground handling

**Acceptance Criteria:**
- ✅ User can grant/deny notification permission
- ✅ Notifications sent for all order events
- ✅ Notifications show rich content
- ✅ Deep links work correctly
- ✅ User can customize notification preferences
- ✅ Badge count updates correctly
- ✅ Silent push updates app state
- ✅ Works in foreground and background
- ✅ Notification history accessible

**Estimated Effort:** 2 weeks (1 developer)
**Dependencies:** APNs certificate, backend integration
**Risk Level:** Low-Medium

---

### Feature 1.4: Promo Codes & Discounts

#### Business Value
- **Critical** - Enable marketing campaigns
- Drive user acquisition
- Increase order frequency
- Competitive requirement

#### Technical Specification

**iOS Implementation:**
```swift
// New files to create:
- Shared/Models/PromoCode.swift
- Core/Cart/ViewModels/PromoCodeViewModel.swift
- Core/Cart/Views/PromoCodeEntryView.swift
- Core/Profile/Views/AvailablePromosView.swift
```

**Implementation Details:**

1. **Promo Code Model** (Week 9, Day 1)
   ```swift
   struct PromoCode: Identifiable, Codable {
       let id: String
       let code: String
       let type: DiscountType
       let value: Double // percentage or fixed amount
       let minOrderAmount: Double?
       let maxDiscount: Double?
       let expirationDate: Date?
       let usageLimit: Int?
       let userUsageLimit: Int?
       let description: String
       let terms: String?

       enum DiscountType: String, Codable {
           case percentage
           case fixedAmount
           case freeDelivery
           case bogo // Buy One Get One
       }
   }
   ```

2. **Promo Code Entry UI** (Week 9)
   ```swift
   // In CartView.swift or CheckoutView.swift
   - "Have a promo code?" section
   - Text field for code entry
   - "Apply" button
   - Display applied discount
   - Remove promo option
   - Error messages for invalid codes
   ```

3. **Promo Validation Logic** (Week 9)
   ```swift
   class PromoCodeViewModel: ObservableObject {
       @Published var appliedPromo: PromoCode?
       @Published var error: String?

       func validatePromo(_ code: String, orderTotal: Double) async throws -> PromoCode
       func applyPromo(_ promo: PromoCode)
       func removePromo()
       func calculateDiscount(_ promo: PromoCode, subtotal: Double) -> Double
   }
   ```

4. **Discount Calculation** (Week 9)
   ```swift
   // Update CartViewModel.swift
   var promoDiscount: Double {
       guard let promo = appliedPromo else { return 0 }

       switch promo.type {
       case .percentage:
           let discount = subtotal * (promo.value / 100)
           return min(discount, promo.maxDiscount ?? .infinity)
       case .fixedAmount:
           return min(promo.value, subtotal)
       case .freeDelivery:
           return deliveryFee
       case .bogo:
           return calculateBogoDiscount()
       }
   }

   var total: Double {
       max(subtotal + tax + deliveryFee - promoDiscount, 0)
   }
   ```

5. **Available Promos View** (Week 10)
   - List of available promotions
   - Promo card design (code, description, value)
   - "Copy code" button
   - Expiration date display
   - Terms and conditions
   - One-tap apply from list

6. **Backend Integration** (Week 10)
   - Validate promo code endpoint
   - Get available promos endpoint
   - Track promo usage endpoint
   - Apply promo to order endpoint

7. **Auto-Apply Best Promo** (Week 10)
   - Automatically check for applicable promos
   - Suggest best available promo
   - "Apply best offer" button
   - Compare multiple promos

**Testing Requirements:**
- Promo validation testing (valid/invalid codes)
- Discount calculation accuracy
- Edge cases (expired, usage limits, minimum order)
- UI tests for entry and removal
- Backend integration testing

**Acceptance Criteria:**
- ✅ User can enter promo code
- ✅ Code is validated in real-time
- ✅ Discount applies correctly
- ✅ All discount types work (%, fixed, free delivery)
- ✅ Minimum order amount enforced
- ✅ Maximum discount cap enforced
- ✅ Expiration dates respected
- ✅ Usage limits tracked
- ✅ User can view available promos
- ✅ User can remove applied promo
- ✅ Error messages are clear
- ✅ Receipt shows promo discount

**Estimated Effort:** 2 weeks (1 developer)
**Dependencies:** Backend promo management system
**Risk Level:** Low

---

### Feature 1.5: Help & Support System

#### Business Value
- **Critical** - Handle customer issues
- Reduce support costs
- Improve customer satisfaction
- Required for operations

#### Technical Specification

**iOS Implementation:**
```swift
// New files to create:
- Core/Support/Views/HelpCenterView.swift
- Core/Support/Views/FAQView.swift
- Core/Support/Views/ContactSupportView.swift
- Core/Support/Views/ReportIssueView.swift
- Core/Support/Models/SupportTicket.swift
- Core/Support/ViewModels/SupportViewModel.swift
```

**Implementation Details:**

1. **Help Center Structure** (Week 11)
   ```swift
   struct HelpTopic: Identifiable {
       let id: String
       let title: String
       let icon: String
       let articles: [HelpArticle]
   }

   struct HelpArticle: Identifiable {
       let id: String
       let title: String
       let content: String
       let helpful: Int
   }
   ```

2. **FAQ Section** (Week 11)
   - Categorized questions
   - Expandable answers
   - Search functionality
   - "Was this helpful?" feedback
   - Most popular questions
   - Recently viewed

3. **Contact Support Options** (Week 11)
   ```swift
   enum SupportChannel {
       case email
       case phone
       case chat // future

       var displayText: String
       var icon: String
       var availability: String
   }
   ```

4. **Report Issue Flow** (Week 12)
   ```swift
   struct SupportTicket: Codable {
       let id: String
       let userId: String
       let orderId: String?
       let issueType: IssueType
       let subject: String
       let description: String
       let attachments: [URL]?
       let status: TicketStatus
       let createdAt: Date

       enum IssueType: String, Codable, CaseIterable {
           case wrongItem = "Wrong Item"
           case missingItem = "Missing Item"
           case lateDelivery = "Late Delivery"
           case foodQuality = "Food Quality"
           case payment = "Payment Issue"
           case refund = "Refund Request"
           case other = "Other"
       }

       enum TicketStatus: String, Codable {
           case open, inProgress, resolved, closed
       }
   }
   ```

5. **Issue Reporting UI** (Week 12)
   - Select order (if applicable)
   - Issue type selection
   - Description text area
   - Photo upload (optional)
   - Submit button
   - Ticket confirmation

6. **Support Ticket Tracking** (Week 12)
   - View submitted tickets
   - Ticket status updates
   - Support responses
   - Ticket history
   - Push notifications for updates

7. **Quick Actions** (Week 13)
   - Report from order detail
   - "Help with this order" button
   - Pre-filled information
   - One-tap issue reporting
   - Common issues quick select

8. **Backend Integration** (Week 13)
   - Submit ticket endpoint
   - Get tickets endpoint
   - Update ticket status endpoint
   - Upload attachment endpoint
   - Get FAQ content endpoint

**Testing Requirements:**
- FAQ search accuracy
- Ticket submission flow
- Image upload testing
- Support ticket retrieval
- UI tests for all flows

**Acceptance Criteria:**
- ✅ User can browse FAQ
- ✅ User can search help articles
- ✅ User can contact support via email
- ✅ User can call support (phone link)
- ✅ User can report order issues
- ✅ User can attach photos
- ✅ User can track support tickets
- ✅ User receives ticket updates
- ✅ Quick actions work from order detail
- ✅ All issue types supported

**Estimated Effort:** 3 weeks (1 developer)
**Dependencies:** Backend support system, help content
**Risk Level:** Low

---

### Feature 1.6: Driver Tipping

#### Business Value
- **Critical** - Driver compensation
- Industry standard
- Improves driver experience
- Increases driver retention

#### Technical Specification

**iOS Implementation:**
```swift
// Files to modify:
- Core/Cart/Views/CheckoutView.swift
- Core/Cart/ViewModels/CartViewModel.swift
- Core/Orders/Views/OrderDetailView.swift
- Shared/Models/Order.swift
```

**Implementation Details:**

1. **Tip Model** (Week 14, Day 1)
   ```swift
   struct Tip: Codable {
       let amount: Double
       let type: TipType
       let percentage: Double?

       enum TipType: String, Codable {
           case percentage
           case custom
           case none
       }
   }

   // Add to Order model
   var tip: Tip?
   var tipAmount: Double { tip?.amount ?? 0 }
   ```

2. **Tip Selection UI** (Week 14)
   ```swift
   // In CheckoutView.swift
   Section("Tip Your Driver") {
       // Preset percentage buttons
       HStack {
           TipButton(percentage: 15, isSelected: selectedTip == 15)
           TipButton(percentage: 18, isSelected: selectedTip == 18)
           TipButton(percentage: 20, isSelected: selectedTip == 20)
           TipButton(title: "Custom", isSelected: isCustomTip)
       }

       // Custom tip entry
       if isCustomTip {
           TextField("Enter amount", value: $customTipAmount)
       }

       // Calculated tip amount display
       Text("Tip amount: \(tipAmount.formatted(.currency))")
   }
   ```

3. **Tip Calculation** (Week 14)
   ```swift
   // In CartViewModel.swift
   @Published var tipPercentage: Double = 18
   @Published var customTipAmount: Double?

   var tipAmount: Double {
       if let custom = customTipAmount {
           return custom
       }
       return subtotal * (tipPercentage / 100)
   }

   var total: Double {
       subtotal + tax + deliveryFee + tipAmount - promoDiscount
   }
   ```

4. **Post-Order Tipping** (Week 14)
   ```swift
   // In OrderDetailView.swift
   // For completed orders without tip
   if order.status == .completed && order.tip == nil {
       Section("Tip Your Driver") {
           Text("Add a tip to thank your driver")
           // Same tip selection UI
           Button("Add Tip") {
               await addTipToOrder()
           }
       }
   }
   ```

5. **Tip Preferences** (Week 14)
   ```swift
   // In AppSettings.swift
   @Published var defaultTipPercentage: Double = 18
   @Published var alwaysAskForTip: Bool = true

   // Save user's preferred tip percentage
   // Auto-select on checkout
   ```

6. **Tip Distribution** (Week 14)
   - 100% of tip goes to driver
   - Clear messaging: "100% to driver"
   - Tip breakdown in receipt
   - Tip included in payment processing

7. **Backend Integration** (Week 14)
   - Include tip in order total
   - Track tip separately for driver payout
   - Add tip to completed order endpoint
   - Driver earnings calculation

**Testing Requirements:**
- Tip calculation accuracy
- Percentage and custom tips
- Post-order tip addition
- Payment processing with tip
- UI tests for tip selection

**Acceptance Criteria:**
- ✅ User can select preset tip percentages
- ✅ User can enter custom tip amount
- ✅ User can tip $0 (no tip)
- ✅ Tip calculates correctly from subtotal
- ✅ Tip included in total before payment
- ✅ User can add tip after order
- ✅ User can change tip before confirming
- ✅ Clear "100% to driver" messaging
- ✅ Tip shown in receipt
- ✅ Default tip preference saved

**Estimated Effort:** 1 week (1 developer)
**Dependencies:** Payment integration
**Risk Level:** Low

---

## Phase 1 Summary

**Total Duration:** 14 weeks (with some parallelization → 16 weeks calendar time)
**Total Effort:** 56 developer-weeks
**Team Size:** 2-3 developers
**Budget:** $60,000 - $90,000

**Deliverables:**
- ✅ Full payment processing (Stripe, Apple Pay, Google Pay)
- ✅ Address management with autocomplete
- ✅ Push notifications system
- ✅ Promo code engine
- ✅ Help & support center
- ✅ Driver tipping

**Success Criteria:**
- Can process real orders end-to-end
- Can handle customer support
- Can run marketing campaigns
- Ready for beta launch

---

## Phase 2: Competitive Parity (Weeks 17-30)

**Goal:** Match basic features of major competitors
**Budget:** $70,000 - $110,000
**Team:** 3 iOS developers, 2 backend developers, 1 QA

---

### Feature 2.1: Real-Time Delivery Tracking

#### Technical Specification

**iOS Implementation:**
```swift
// New files:
- Core/Tracking/Views/LiveTrackingView.swift
- Core/Tracking/ViewModels/TrackingViewModel.swift
- Core/Tracking/Services/LocationTrackingService.swift
- Shared/Models/DeliveryTracking.swift
```

**Implementation Details:**

1. **Map Integration** (Week 17-18)
   - MapKit or Google Maps integration
   - Driver location markers
   - Restaurant location marker
   - Delivery address marker
   - Route polyline
   - Real-time position updates

2. **WebSocket Connection** (Week 18)
   ```swift
   class LocationTrackingService: ObservableObject {
       private var webSocket: URLSessionWebSocketTask?
       @Published var driverLocation: CLLocationCoordinate2D?
       @Published var estimatedArrival: Date?

       func connect(orderId: String)
       func disconnect()
       func handleLocationUpdate(_ data: Data)
   }
   ```

3. **Live ETA Calculation** (Week 18-19)
   - Distance calculation
   - Traffic-aware routing
   - Dynamic ETA updates
   - "X minutes away" display
   - Progress percentage

4. **Driver Information Display** (Week 19)
   ```swift
   struct DriverInfo: Codable {
       let name: String
       let photo: URL?
       let rating: Double
       let phone: String
       let vehicleType: String
       let licensePlate: String?
   }
   ```

5. **Contact Driver** (Week 19)
   - Call driver button (tel: link)
   - Message driver (future: in-app chat)
   - Masked phone numbers for privacy
   - Call/message history

6. **Delivery Notifications** (Week 20)
   - "Driver assigned" push
   - "Driver is nearby" push
   - Geofence-based "arriving soon"
   - Delivery photo notification

**Estimated Effort:** 4 weeks (2 developers)
**Dependencies:** Backend real-time system, driver app
**Risk Level:** High (requires driver app, complex backend)

---

### Feature 2.2: Ratings & Reviews System

#### Technical Specification

**iOS Implementation:**
```swift
// New files:
- Core/Reviews/Views/RateOrderView.swift
- Core/Reviews/Views/WriteReviewView.swift
- Core/Reviews/Views/ReviewsListView.swift
- Core/Reviews/ViewModels/ReviewViewModel.swift
- Shared/Models/Review.swift
```

**Implementation Details:**

1. **Rating Model** (Week 21)
   ```swift
   struct Review: Identifiable, Codable {
       let id: String
       let userId: String
       let orderId: String
       let menuItemId: String?
       let rating: Int // 1-5 stars
       let comment: String?
       let photos: [URL]?
       let createdAt: Date
       let helpful: Int
       let response: RestaurantResponse?

       struct RestaurantResponse: Codable {
           let message: String
           let respondedAt: Date
       }
   }
   ```

2. **Rate Order Prompt** (Week 21)
   - Auto-prompt after order completion
   - Star rating (1-5)
   - Optional text review
   - Photo upload
   - Rate food, delivery, and driver separately

3. **Review Submission UI** (Week 21-22)
   ```swift
   // RateOrderView.swift
   - Overall rating
   - Food quality rating
   - Delivery rating
   - Driver rating (if delivery)
   - Text comment
   - Photo picker
   - Tags (delicious, fresh, hot, etc.)
   - Submit button
   ```

4. **Reviews Display** (Week 22)
   - Reviews list on menu items
   - Star rating average
   - Review count
   - Filter by rating
   - Sort by recent/helpful
   - Review photos gallery
   - Report inappropriate reviews

5. **Review Moderation** (Week 22)
   - Flag inappropriate content
   - Admin review system
   - Auto-filter profanity
   - User blocking

6. **Helpful Votes** (Week 23)
   - Thumbs up/down on reviews
   - "Was this helpful?" prompt
   - Sort by most helpful
   - Reputation system

**Estimated Effort:** 3 weeks (1 developer)
**Dependencies:** Backend review system, moderation tools
**Risk Level:** Medium

---

### Feature 2.3: Scheduled Orders

#### Technical Specification

**Implementation Details:**

1. **Date/Time Picker** (Week 23)
   ```swift
   // In CheckoutView.swift
   enum OrderTime {
       case asap
       case scheduled(Date)
   }

   @State var orderTime: OrderTime = .asap

   // UI
   Picker("When", selection: $orderTime) {
       Text("ASAP").tag(OrderTime.asap)
       Text("Schedule for later").tag(OrderTime.scheduled(Date()))
   }

   if case .scheduled = orderTime {
       DatePicker("Date & Time", selection: $scheduledDate)
   }
   ```

2. **Store Hours Validation** (Week 23)
   - Only allow times during open hours
   - Minimum lead time (30 mins)
   - Maximum advance (7 days)
   - Unavailable time slots

3. **Order Scheduling Backend** (Week 24)
   - Store scheduled orders
   - Queue for future processing
   - Send to kitchen at right time
   - Reminder notifications

**Estimated Effort:** 2 weeks (1 developer)
**Risk Level:** Low

---

### Feature 2.4: Order Modification & Cancellation

#### Technical Specification

**Implementation Details:**

1. **Cancel Order** (Week 24)
   ```swift
   // In OrderDetailView.swift
   if order.canBeCancelled {
       Button("Cancel Order", role: .destructive) {
           await cancelOrder()
       }
   }

   // Business rules
   var canBeCancelled: Bool {
       status == .received &&
       Date().timeIntervalSince(createdAt) < 300 // 5 minutes
   }
   ```

2. **Modify Order** (Week 25)
   - Add items before preparing
   - Remove items before preparing
   - Change delivery address
   - Update delivery instructions
   - Adjust tip

3. **Cancellation Policies** (Week 25)
   - Free cancellation window
   - Refund processing
   - Partial refunds for late cancellation
   - Clear policy communication

**Estimated Effort:** 2 weeks (1 developer)
**Risk Level:** Low

---

### Feature 2.5: Enhanced Search & Discovery

#### Technical Specification

**Implementation Details:**

1. **Search Enhancements** (Week 25-26)
   ```swift
   class MenuViewModel: ObservableObject {
       @Published var searchHistory: [String] = []
       @Published var recentlyViewed: [MenuItem] = []
       @Published var recommendations: [MenuItem] = []

       func saveSearch(_ query: String)
       func trackView(_ item: MenuItem)
   }
   ```

2. **Autocomplete** (Week 26)
   - Real-time search suggestions
   - Popular searches
   - Recent searches
   - Category suggestions

3. **Advanced Filters** (Week 26)
   - Price range slider
   - Prep time filter
   - Calorie range
   - Rating filter
   - Sort options (price, popularity, rating)

4. **Personalized Recommendations** (Week 27)
   - Based on order history
   - Based on favorites
   - "Customers also ordered"
   - "Popular in your area"
   - Time-based (breakfast, lunch, dinner)

**Estimated Effort:** 3 weeks (1 developer)
**Risk Level:** Low

---

### Feature 2.6: Enhanced Nutritional Information

#### Technical Specification

**Implementation Details:**

1. **Detailed Nutrition Model** (Week 27-28)
   ```swift
   struct NutritionInfo: Codable {
       let calories: Int
       let totalFat: Double
       let saturatedFat: Double
       let transFat: Double
       let cholesterol: Double
       let sodium: Double
       let totalCarbohydrates: Double
       let dietaryFiber: Double
       let sugars: Double
       let protein: Double
       let vitamins: [String: Double]

       var formattedLabel: String // FDA-style label
   }
   ```

2. **Allergen Information** (Week 28)
   ```swift
   struct AllergenInfo: Codable {
       let contains: [Allergen]
       let mayContain: [Allergen]
       let preparedWith: [Allergen]

       enum Allergen: String, CaseIterable {
           case milk, eggs, fish, shellfish, treeNuts
           case peanuts, wheat, soybeans, sesame
       }
   }
   ```

3. **Nutrition Display** (Week 28)
   - Expandable nutrition facts
   - FDA-style label
   - Allergen warnings (highlighted)
   - Ingredient list
   - "View full details" modal

4. **Allergen Filtering** (Week 29)
   - User allergen profile
   - Auto-filter incompatible items
   - Warning badges on items
   - Safe alternatives suggestion

**Estimated Effort:** 3 weeks (1 developer)
**Dependencies:** Detailed menu data from restaurants
**Risk Level:** Medium (data collection)

---

### Feature 2.7: Receipt & Expense Management

#### Technical Specification

**Implementation Details:**

1. **Receipt Generation** (Week 29)
   ```swift
   struct Receipt: Codable {
       let orderId: String
       let orderNumber: String
       let date: Date
       let items: [OrderItem]
       let subtotal: Double
       let tax: Double
       let tip: Double
       let deliveryFee: Double
       let discount: Double
       let total: Double
       let paymentMethod: String
       let restaurant: Store
       let deliveryAddress: Address?
   }
   ```

2. **Email Receipt** (Week 29)
   - Auto-send after order
   - HTML formatted email
   - PDF attachment
   - Itemized breakdown
   - Tax details

3. **Download PDF** (Week 30)
   - Generate PDF on device
   - Save to Files app
   - Share via activity sheet
   - Print option

4. **Expense Reporting** (Week 30)
   - Monthly spending summary
   - CSV export
   - Category breakdown
   - Tax year summary
   - Business expense tagging

**Estimated Effort:** 2 weeks (1 developer)
**Risk Level:** Low

---

## Phase 2 Summary

**Total Duration:** 14 weeks
**Total Effort:** 84 developer-weeks
**Team Size:** 3 developers
**Budget:** $70,000 - $110,000

**Deliverables:**
- ✅ Real-time delivery tracking
- ✅ Ratings & reviews
- ✅ Scheduled orders
- ✅ Order cancellation
- ✅ Enhanced search
- ✅ Detailed nutrition
- ✅ Receipt management

**Success Criteria:**
- 70-80% feature parity with competitors
- Strong user engagement features
- Professional user experience

---

## Phase 3: Engagement & Retention (Weeks 31-42)

**Goal:** Increase user retention and lifetime value
**Budget:** $50,000 - $80,000
**Team:** 2 iOS developers, 1 backend developer, 1 QA

---

### Feature 3.1: Full Rewards Program Implementation

#### Technical Specification

**Implementation Details:**

1. **Points System** (Week 31-32)
   ```swift
   struct RewardsAccount: Codable {
       let userId: String
       var points: Int
       var tier: RewardsTier
       var lifetimePoints: Int
       var transactions: [PointsTransaction]

       enum RewardsTier: String {
           case bronze, silver, gold, platinum

           var multiplier: Double {
               switch self {
               case .bronze: return 1.0
               case .silver: return 1.25
               case .gold: return 1.5
               case .platinum: return 2.0
               }
           }

           var benefits: [String]
       }
   }

   struct PointsTransaction: Codable {
       let amount: Int
       let type: TransactionType
       let description: String
       let date: Date

       enum TransactionType {
           case earned, redeemed, expired, bonus
       }
   }
   ```

2. **Earning Rules** (Week 32)
   - $1 spent = 10 points (base)
   - Tier multipliers
   - Bonus events (double points days)
   - First order bonus
   - Referral bonus
   - Birthday bonus
   - Streak bonuses

3. **Redemption System** (Week 33)
   ```swift
   struct Reward: Identifiable, Codable {
       let id: String
       let name: String
       let description: String
       let pointsCost: Int
       let type: RewardType
       let value: Double
       let imageURL: URL?
       let expiresAfter: TimeInterval?

       enum RewardType {
           case discount(percentage: Double)
           case fixedDiscount(amount: Double)
           case freeItem(menuItemId: String)
           case freeDelivery
       }
   }
   ```

4. **Rewards Catalog** (Week 33)
   - Browse available rewards
   - Filter by points cost
   - Redeem rewards
   - Active rewards display
   - Expiration tracking

5. **Gamification** (Week 34)
   - Progress bars to next tier
   - Achievement badges
   - Challenges (order 5x this week)
   - Leaderboards (optional)
   - Milestone celebrations

**Estimated Effort:** 4 weeks (1 developer)
**Risk Level:** Medium

---

### Feature 3.2: Gift Cards

#### Implementation Details (Week 35-36)
- Purchase gift cards
- Send to friends
- Redeem codes
- Balance checking
- Physical + digital cards

**Estimated Effort:** 2 weeks
**Dependencies:** Payment processing

---

### Feature 3.3: Social Features

#### Implementation Details (Week 37-38)
- Share orders
- Referral program
- Social login (Apple, Google, Facebook)
- Friend invites
- Group ordering

**Estimated Effort:** 2 weeks

---

### Feature 3.4: Contact-Free & Safety Features

#### Implementation Details (Week 39)
- Leave at door option
- No-contact delivery
- Photo proof of delivery
- Safety badges
- Tamper-evident seals

**Estimated Effort:** 1 week

---

### Feature 3.5: Advanced Customization UI

#### Implementation Details (Week 40-42)
- Visual ingredient builder
- Drag-and-drop interface
- Live nutrition updates
- Save custom combos
- Share recipes

**Estimated Effort:** 3 weeks
**Risk Level:** Medium

---

## Phase 3 Summary

**Total Duration:** 12 weeks
**Total Effort:** 48 developer-weeks
**Budget:** $50,000 - $80,000

---

## Phase 4: Platform & Scale (Weeks 43-52)

**Goal:** Build operational infrastructure for scale
**Budget:** $120,000 - $200,000
**Team:** 4 developers, 1 designer, 2 QA, 1 DevOps

---

### Feature 4.1: Restaurant Dashboard (Web App)

**Scope:**
- Order management
- Menu management
- Analytics
- Inventory tracking
- Settings

**Estimated Effort:** 8 weeks (2 developers)
**Technology:** React/Next.js + Supabase
**Budget:** $40,000 - $60,000

---

### Feature 4.2: Driver Mobile App

**Scope:**
- Accept deliveries
- Navigation
- Order management
- Earnings tracking
- Ratings

**Estimated Effort:** 8 weeks (2 developers)
**Technology:** React Native or Swift
**Budget:** $40,000 - $60,000

---

### Feature 4.3: Admin Panel (Web App)

**Scope:**
- User management
- Restaurant management
- Driver management
- Analytics dashboard
- Support tools
- Promo management
- System config

**Estimated Effort:** 10 weeks (2 developers)
**Technology:** React/Next.js + Supabase
**Budget:** $50,000 - $80,000

---

### Feature 4.4: Business Accounts & Corporate Features

**Implementation Details:**
- Corporate account setup
- Team management
- Budget controls
- Reporting
- Bulk ordering

**Estimated Effort:** 4 weeks

---

## Phase 4 Summary

**Total Duration:** 10 weeks (parallel work)
**Total Effort:** 120 developer-weeks
**Budget:** $120,000 - $200,000

---

## Resource Requirements

### Team Structure

#### Phase 1 (Weeks 1-16)
- **2x Senior iOS Developers** - $120/hr
- **1x Backend Developer** - $100/hr
- **1x QA Engineer** - $70/hr
- **0.5x UI/UX Designer** - $90/hr
- **0.25x DevOps Engineer** - $110/hr
- **0.25x Project Manager** - $100/hr

#### Phase 2-3 (Weeks 17-42)
- **3x Senior iOS Developers**
- **2x Backend Developers**
- **1x QA Engineer**
- **0.5x UI/UX Designer**
- **0.25x DevOps Engineer**
- **0.5x Project Manager**

#### Phase 4 (Weeks 43-52)
- **4x Full-Stack Developers**
- **1x UI/UX Designer**
- **2x QA Engineers**
- **1x DevOps Engineer**
- **1x Project Manager**

### External Services & Tools

**Required Subscriptions:**
- Stripe: $0 + 2.9% + $0.30 per transaction
- Google Maps API: ~$200-500/month
- Apple Developer: $99/year
- Firebase: ~$50-200/month
- Supabase: ~$25-100/month
- GitHub: $21/month (team)
- Figma: $45/month
- Sentry (error tracking): $26/month
- Mixpanel (analytics): $25/month

**One-Time Costs:**
- APNs Certificate: Free
- SSL Certificates: $0 (Let's Encrypt)
- Design assets: $2,000-5,000

---

## Risk Assessment

### High Risk Items

1. **Real-Time Delivery Tracking**
   - **Risk:** Complex backend, requires driver app
   - **Mitigation:** Phase after driver app, use 3rd party initially
   - **Alternative:** Partner with existing delivery service

2. **Payment Processing**
   - **Risk:** PCI compliance, security
   - **Mitigation:** Use Stripe (PCI compliant), thorough testing
   - **Contingency:** 2 week buffer

3. **Driver & Restaurant Apps**
   - **Risk:** Large scope, separate platforms
   - **Mitigation:** Use web apps initially, hire specialists
   - **Alternative:** White-label solutions

### Medium Risk Items

4. **Backend Scaling**
   - **Risk:** Performance under load
   - **Mitigation:** Supabase handles scaling, load testing
   - **Contingency:** Additional database optimization

5. **Data Migration**
   - **Risk:** Moving from mock data to production
   - **Mitigation:** Careful migration scripts, testing
   - **Timeline:** 1 week buffer

### Low Risk Items

6. **UI Features**
   - **Risk:** Minimal - well understood
   - **Mitigation:** Standard SwiftUI patterns

---

## Success Metrics

### Phase 1 Success Criteria
- ✅ 100% of test orders process successfully
- ✅ Payment success rate > 98%
- ✅ Push notification delivery > 95%
- ✅ Support ticket response < 24 hours
- ✅ Zero critical bugs

### Phase 2 Success Criteria
- ✅ User can complete all competitor features
- ✅ Search finds relevant items > 90%
- ✅ Review submission success rate > 95%
- ✅ Average order rating > 4.0
- ✅ App store rating > 4.5

### Phase 3 Success Criteria
- ✅ 30-day retention > 40%
- ✅ Rewards redemption rate > 15%
- ✅ Referral rate > 5%
- ✅ Average orders/user/month > 3
- ✅ User satisfaction > 85%

### Phase 4 Success Criteria
- ✅ Restaurant onboarding < 2 hours
- ✅ Driver app rating > 4.0
- ✅ Admin efficiency improvement > 50%
- ✅ System uptime > 99.5%
- ✅ Can handle 1000+ concurrent users

---

## Budget Breakdown

### Development Costs

| Phase | Duration | Team Cost | External Services | Total |
|-------|----------|-----------|-------------------|-------|
| Phase 1 | 16 weeks | $55,000 | $5,000 | $60,000 |
| Phase 2 | 14 weeks | $65,000 | $5,000 | $70,000 |
| Phase 3 | 12 weeks | $45,000 | $5,000 | $50,000 |
| Phase 4 | 10 weeks | $115,000 | $5,000 | $120,000 |
| **Total** | **52 weeks** | **$280,000** | **$20,000** | **$300,000** |

### Additional Costs (Year 1)

- **Infrastructure:** $15,000
- **Design & Assets:** $5,000
- **Testing & QA:** $10,000
- **Legal & Compliance:** $10,000
- **Marketing & Launch:** $20,000
- **Contingency (20%):** $60,000

**Total Year 1 Budget:** $420,000

---

## Timeline Overview

```
Month 1-4  : Phase 1 - Launch Readiness
Month 5-7  : Phase 2 - Competitive Parity
Month 8-10 : Phase 3 - Engagement
Month 11-12: Phase 4 - Platform & Scale

Beta Launch: Month 4
Public Launch: Month 7
Full Platform: Month 12
```

---

## Prioritization Matrix

### Must Have (P0) - Cannot launch without
- Payment processing ✅
- Address management ✅
- Push notifications ✅
- Help & support ✅

### Should Have (P1) - Launch with limited functionality
- Promo codes ✅
- Scheduled orders ✅
- Order cancellation ✅
- Driver tipping ✅

### Nice to Have (P2) - Post-launch
- Real-time tracking
- Reviews & ratings
- Enhanced search
- Rewards program

### Future (P3) - Long-term
- Social features
- AI recommendations
- Subscription service
- Multi-restaurant orders

---

## Dependencies & Prerequisites

### Before Phase 1
- [ ] Supabase account and project setup
- [ ] Stripe merchant account
- [ ] Google Places API key
- [ ] APNs certificates
- [ ] Backend API specification
- [ ] Design system finalized

### Before Phase 2
- [ ] Phase 1 features 100% complete
- [ ] Beta testing feedback incorporated
- [ ] Analytics implementation
- [ ] Error tracking setup
- [ ] Load testing completed

### Before Phase 3
- [ ] Payment processing stable
- [ ] Customer support process established
- [ ] Marketing campaigns ready
- [ ] Legal compliance verified

### Before Phase 4
- [ ] Restaurant partnerships signed
- [ ] Driver recruitment started
- [ ] Operations team hired
- [ ] Scalability testing completed

---

## Recommendations

### Immediate Actions (Week 1)
1. ✅ Set up development environment
2. ✅ Create Stripe account
3. ✅ Get Google Maps API key
4. ✅ Set up APNs
5. ✅ Finalize backend API contracts
6. ✅ Begin Phase 1 Sprint 1

### Quick Wins (Weeks 1-4)
1. Payment integration (highest ROI)
2. Push notifications (user engagement)
3. Address management (UX improvement)
4. Promo codes (marketing readiness)

### Strategic Decisions Needed
1. **Build vs Buy:** Driver app (build custom vs 3rd party delivery)
2. **Technology:** Backend (Supabase vs custom)
3. **Launch Strategy:** Soft launch vs big launch
4. **Market:** Single city vs multi-city
5. **Business Model:** Commission % vs subscription

---

## Conclusion

This implementation plan provides a clear path from current state (40% parity) to full market readiness (90%+ parity) in 52 weeks with an estimated budget of $300,000-420,000.

**Key Success Factors:**
- ✅ Experienced team execution
- ✅ Proper prioritization (P0 → P1 → P2 → P3)
- ✅ Agile methodology with 2-week sprints
- ✅ Continuous user feedback
- ✅ Quality over speed
- ✅ Strategic partnerships (payments, maps, delivery)

**Next Steps:**
1. Review and approve this proposal
2. Secure budget and resources
3. Finalize team hiring
4. Begin Phase 1, Week 1
5. Set up project management tools
6. Schedule weekly stakeholder reviews

---

**Document Status:** Ready for Review
**Prepared By:** Cameron's Development Team
**Review Date:** November 13, 2025
**Approval Required:** Executive Team

---

*This is a living document and will be updated as implementation progresses.*
