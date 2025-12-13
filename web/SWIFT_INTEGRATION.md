# Swift Apps - Supabase Integration Guide

This guide shows how to connect your Swift business and customer apps to the same Supabase backend.

## Prerequisites

1. Complete the web app Supabase setup first (`SUPABASE_SETUP.md`)
2. Have your Supabase credentials ready:
   - Project URL
   - Anon Key

## Step 1: Install Supabase Swift SDK

### Using Swift Package Manager (Recommended)

1. **In Xcode:**
   - File → Add Packages...
   - Enter: `https://github.com/supabase-community/supabase-swift`
   - Version: `2.0.0` or later
   - Click "Add Package"

2. **Or in Package.swift:**
   ```swift
   dependencies: [
       .package(url: "https://github.com/supabase-community/supabase-swift", from: "2.0.0")
   ]
   ```

## Step 2: Configure Supabase Client

### Create SupabaseManager.swift

```swift
import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // Get credentials from Info.plist or Config
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
              let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
              let supabaseURL = URL(string: url) else {
            fatalError("Missing Supabase configuration in Info.plist")
        }

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(schema: "public"),
                auth: SupabaseClientOptions.AuthOptions(
                    storage: UserDefaultsStorage(key: "supabase.session"),
                    flowType: .pkce
                ),
                global: SupabaseClientOptions.GlobalOptions(
                    headers: ["x-app-name": "camerons-connect-ios"]
                )
            )
        )
    }
}
```

### Add to Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Your existing keys -->

    <!-- Add these: -->
    <key>SupabaseURL</key>
    <string>https://your-project-ref.supabase.co</string>

    <key>SupabaseAnonKey</key>
    <string>your-anon-key-here</string>

    <!-- For deep linking (auth callbacks) -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>cameronsconnect</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

## Step 3: Create Data Models

### Store.swift
```swift
import Foundation

struct Store: Codable, Identifiable {
    let id: Int
    let name: String
    let address: String
    let city: String
    let state: String
    let zip: String
    let phone: String?
    let hours: String
    let isOpen: Bool
    let latitude: Double
    let longitude: Double
    let storeType: String

    enum CodingKeys: String, CodingKey {
        case id, name, address, city, state, zip, phone, hours
        case isOpen = "is_open"
        case latitude, longitude
        case storeType = "store_type"
    }
}
```

### UserProfile.swift
```swift
import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let role: Role
    let fullName: String
    let phone: String?
    let storeId: Int?
    let permissions: [String]
    let isActive: Bool
    let avatarUrl: String?
    let createdAt: Date
    let updatedAt: Date

    enum Role: String, Codable {
        case superAdmin = "super_admin"
        case admin
        case manager
        case staff
        case customer
    }

    enum CodingKeys: String, CodingKey {
        case id, role, phone, permissions
        case fullName = "full_name"
        case storeId = "store_id"
        case isActive = "is_active"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

### Order.swift
```swift
import Foundation

struct Order: Codable, Identifiable {
    let id: UUID
    let orderNumber: String
    let customerId: UUID?
    let storeId: Int
    let customerName: String
    let customerPhone: String
    let customerEmail: String?
    let status: OrderStatus
    let priority: OrderPriority
    let subtotal: Double
    let tax: Double
    let tip: Double
    let total: Double
    let orderType: OrderType
    let estimatedReadyAt: Date?
    let completedAt: Date?
    let specialInstructions: String?
    let createdAt: Date
    let updatedAt: Date
    let orderItems: [OrderItem]?

    enum OrderStatus: String, Codable {
        case pending, confirmed, preparing, ready, completed, cancelled
    }

    enum OrderPriority: String, Codable {
        case normal, express, vip
    }

    enum OrderType: String, Codable {
        case pickup, delivery
    }

    enum CodingKeys: String, CodingKey {
        case id
        case orderNumber = "order_number"
        case customerId = "customer_id"
        case storeId = "store_id"
        case customerName = "customer_name"
        case customerPhone = "customer_phone"
        case customerEmail = "customer_email"
        case status, priority, subtotal, tax, tip, total
        case orderType = "order_type"
        case estimatedReadyAt = "estimated_ready_at"
        case completedAt = "completed_at"
        case specialInstructions = "special_instructions"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case orderItems = "order_items"
    }
}

struct OrderItem: Codable, Identifiable {
    let id: Int
    let orderId: UUID
    let menuItemId: Int?
    let itemName: String
    let itemPrice: Double
    let quantity: Int
    let customizations: [Customization]
    let subtotal: Double
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case menuItemId = "menu_item_id"
        case itemName = "item_name"
        case itemPrice = "item_price"
        case quantity, customizations, subtotal, notes
    }
}

struct Customization: Codable {
    let name: String
    let value: String
    let price: Double
}
```

## Step 4: Authentication Manager

### AuthManager.swift
```swift
import Foundation
import Supabase
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var profile: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = true

    private let supabase = SupabaseManager.shared.client
    private var cancellables = Set<AnyCancellable>()

    init() {
        Task {
            await checkSession()
        }
    }

    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            self.user = session.user
            self.isAuthenticated = true
            await fetchProfile()
        } catch {
            print("No active session:", error)
            self.isAuthenticated = false
            self.isLoading = false
        }
    }

    func signIn(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        self.user = session.user
        self.isAuthenticated = true
        await fetchProfile()
    }

    func signUp(email: String, password: String, fullName: String, phone: String) async throws {
        let session = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: [
                "full_name": .string(fullName),
                "phone": .string(phone)
            ]
        )
        self.user = session.user
        self.isAuthenticated = true
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        self.user = nil
        self.profile = nil
        self.isAuthenticated = false
    }

    private func fetchProfile() async {
        guard let userId = user?.id else {
            isLoading = false
            return
        }

        do {
            let response: UserProfile = try await supabase
                .from("user_profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            self.profile = response
        } catch {
            print("Error fetching profile:", error)
        }

        isLoading = false
    }

    func hasPermission(_ permission: String) -> Bool {
        guard let profile = profile else { return false }
        if profile.role == .superAdmin || profile.role == .admin {
            return true
        }
        return profile.permissions.contains(permission)
    }
}
```

## Step 5: Order Manager (for Business App)

### OrderManager.swift
```swift
import Foundation
import Supabase
import Combine

@MainActor
class OrderManager: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var error: String?

    private let supabase = SupabaseManager.shared.client
    private var channel: RealtimeChannelV2?

    func fetchOrders(storeId: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: [Order] = try await supabase
                .from("orders")
                .select("""
                    *,
                    order_items (*)
                """)
                .eq("store_id", value: storeId)
                .neq("status", value: "completed")
                .order("created_at", ascending: false)
                .execute()
                .value

            self.orders = response
        } catch {
            print("Error fetching orders:", error)
            self.error = error.localizedDescription
        }
    }

    func subscribeToOrders(storeId: Int) async {
        // Fetch initial orders
        await fetchOrders(storeId: storeId)

        // Subscribe to real-time updates
        let channel = await supabase.channel("orders-\(storeId)")

        await channel
            .on(.postgresChanges(
                event: .insert,
                schema: "public",
                table: "orders",
                filter: "store_id=eq.\(storeId)"
            )) { [weak self] (payload: PostgresChangePayload<Order>) in
                Task { @MainActor in
                    if let order = payload.new {
                        await self?.fetchOrderDetails(orderId: order.id)
                    }
                }
            }
            .on(.postgresChanges(
                event: .update,
                schema: "public",
                table: "orders",
                filter: "store_id=eq.\(storeId)"
            )) { [weak self] (payload: PostgresChangePayload<Order>) in
                Task { @MainActor in
                    if let order = payload.new {
                        await self?.fetchOrderDetails(orderId: order.id)
                    }
                }
            }
            .subscribe()

        self.channel = channel
    }

    private func fetchOrderDetails(orderId: UUID) async {
        do {
            let order: Order = try await supabase
                .from("orders")
                .select("""
                    *,
                    order_items (*)
                """)
                .eq("id", value: orderId)
                .single()
                .execute()
                .value

            if let index = orders.firstIndex(where: { $0.id == orderId }) {
                orders[index] = order
            } else {
                orders.insert(order, at: 0)
            }
        } catch {
            print("Error fetching order details:", error)
        }
    }

    func updateOrderStatus(orderId: UUID, newStatus: Order.OrderStatus) async throws {
        var updateData: [String: Any] = ["status": newStatus.rawValue]

        if newStatus == .completed {
            updateData["completed_at"] = ISO8601DateFormatter().string(from: Date())
        }

        try await supabase
            .from("orders")
            .update(updateData)
            .eq("id", value: orderId)
            .execute()
    }

    deinit {
        Task {
            await channel?.unsubscribe()
        }
    }
}
```

## Step 6: Sample SwiftUI Views

### LoginView.swift (Business App)
```swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Cameron's Connect")
                .font(.largeTitle)
                .bold()

            Text("Business Dashboard")
                .font(.headline)
                .foregroundColor(.gray)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: login) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text("Sign In")
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(isLoading)
        }
        .padding()
    }

    func login() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
```

### OrderListView.swift (Business App)
```swift
import SwiftUI

struct OrderListView: View {
    @StateObject private var orderManager = OrderManager()
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationView {
            Group {
                if orderManager.isLoading {
                    ProgressView("Loading orders...")
                } else if let error = orderManager.error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text("Error: \(error)")
                    }
                } else if orderManager.orders.isEmpty {
                    VStack {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                        Text("No active orders")
                    }
                } else {
                    List(orderManager.orders) { order in
                        OrderRowView(order: order, orderManager: orderManager)
                    }
                }
            }
            .navigationTitle("Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        Task {
                            try? await authManager.signOut()
                        }
                    }
                }
            }
        }
        .task {
            if let storeId = authManager.profile?.storeId {
                await orderManager.subscribeToOrders(storeId: storeId)
            }
        }
    }
}

struct OrderRowView: View {
    let order: Order
    @ObservedObject var orderManager: OrderManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(order.orderNumber)
                    .font(.headline)
                Spacer()
                Text("$\(order.total, specifier: "%.2f")")
                    .bold()
            }

            Text(order.customerName)
                .font(.subheadline)

            Text(order.status.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(order.status))
                .foregroundColor(.white)
                .cornerRadius(4)

            // Status buttons
            HStack {
                if order.status == .pending {
                    Button("Confirm") {
                        Task {
                            try? await orderManager.updateOrderStatus(
                                orderId: order.id,
                                newStatus: .confirmed
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if order.status == .confirmed {
                    Button("Start Preparing") {
                        Task {
                            try? await orderManager.updateOrderStatus(
                                orderId: order.id,
                                newStatus: .preparing
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if order.status == .preparing {
                    Button("Mark Ready") {
                        Task {
                            try? await orderManager.updateOrderStatus(
                                orderId: order.id,
                                newStatus: .ready
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if order.status == .ready {
                    Button("Complete") {
                        Task {
                            try? await orderManager.updateOrderStatus(
                                orderId: order.id,
                                newStatus: .completed
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.vertical, 4)
    }

    func statusColor(_ status: Order.OrderStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .confirmed: return .blue
        case .preparing: return .purple
        case .ready: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}
```

## Step 7: App Entry Point

### CameronsConnectBusinessApp.swift
```swift
import SwiftUI

@main
struct CameronsConnectBusinessApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    ProgressView()
                } else if authManager.isAuthenticated {
                    OrderListView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(authManager)
        }
    }
}
```

## Testing

1. **Build and run** the app
2. **Login** with test credentials: `admin@cameronsconnect.com` / `admin123`
3. **View orders** - should show active orders from your store
4. **Test real-time** - create an order from web app, should appear in iOS app instantly
5. **Update status** - tap buttons to move order through workflow

## Customer App Differences

For the customer app, you'll need:
- Menu browsing views
- Cart management
- Order placement
- Order tracking

The authentication and Supabase client setup is identical. Just different UI and queries.

## Next Steps

1. Implement menu browsing in customer app
2. Add cart functionality
3. Implement checkout flow
4. Add push notifications for order updates
5. Test across all 3 platforms (web + 2 iOS apps)

## Security Notes

- ✅ Never hardcode credentials - use Info.plist
- ✅ Same RLS policies protect iOS apps as web app
- ✅ Use environment-based configuration for dev vs prod
- ✅ Test all user roles and permissions

Your Swift apps now share the same Supabase backend as your web app! 🎉
