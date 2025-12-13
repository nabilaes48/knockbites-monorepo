import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: SupabaseConfig.url) else {
            fatalError("Invalid Supabase URL")
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }

    func testConnection() async {
        do {
            struct DBStore: Codable {
                let id: Int
                let name: String
            }

            let stores: [DBStore] = try await client
                .from("stores")
                .select()
                .limit(5)
                .execute()
                .value

            print("✅ Supabase Business connection successful!")
            print("📍 Found \(stores.count) stores")
        } catch {
            print("❌ Supabase connection failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Order Management

    /// Fetch orders filtered by user's accessible stores (RBAC-compliant)
    /// - Parameter storeIds: Optional array of store IDs. If nil, uses AuthManager's accessible stores
    /// - Returns: Array of orders the user has access to
    func fetchOrders(storeIds: [Int]? = nil) async throws -> [Order] {
        print("🔄 Fetching orders from Supabase...")

        // Get accessible stores from AuthManager or use provided storeIds
        let targetStoreIds: [Int]
        if let providedIds = storeIds {
            targetStoreIds = providedIds
        } else {
            // Import AuthManager to access user's assigned stores
            targetStoreIds = await AuthManager.shared.getAccessibleStores()

            // If user has no assigned stores and is not super admin, return empty
            let isSuperAdmin = await AuthManager.shared.isSuperAdmin()
            if targetStoreIds.isEmpty && !isSuperAdmin {
                print("⚠️ User has no accessible stores")
                return []
            }
        }

        print("📍 Fetching orders for stores: \(targetStoreIds)")

        let query: PostgrestTransformBuilder

        // Super admins with empty assignedStores can see all stores
        let isSuperAdmin = await AuthManager.shared.isSuperAdmin()
        if targetStoreIds.isEmpty && isSuperAdmin {
            print("🔓 Super admin: fetching ALL orders")
            query = client
                .from("orders")
                .select("""
                    *,
                    order_items(*)
                """)
                .order("created_at", ascending: false)
        } else {
            // Filter by accessible stores using .in()
            query = client
                .from("orders")
                .select("""
                    *,
                    order_items(*)
                """)
                .in("store_id", values: targetStoreIds)
                .order("created_at", ascending: false)
        }

        // Fetch raw response
        struct OrderResponse: Codable {
            let id: String
            let order_number: String
            let user_id: String
            let customer_name: String?
            let customer_email: String?  // May exist in orders table
            let customer_phone: String?  // May exist in orders table
            let store_id: Int  // Database stores as Int
            let subtotal: Double
            let tax: Double
            let total: Double
            let status: String
            let order_type: String
            let created_at: String
            let estimated_ready_time: String?
            let completed_at: String?
            let order_items: [OrderItemResponse]

            // Get display name
            var displayName: String {
                // Check if customer_name looks like a real name (not UUID, not username-like)
                if let name = customer_name, !name.isEmpty {
                    // If it contains spaces or capital letters in the middle, it's likely a real name
                    let hasSpace = name.contains(" ")
                    let hasCapitalInMiddle = name.dropFirst().contains(where: { $0.isUppercase })

                    if hasSpace || hasCapitalInMiddle {
                        // Looks like a real name (e.g., "John Smith" or "JohnSmith")
                        return name
                    }

                    // If it doesn't contain hyphens and is reasonably long, might be a name
                    if !name.contains("-") && !name.contains("@") && name.count > 2 {
                        // Could be a single name or username - use it anyway
                        return name.capitalized
                    }
                }

                // Try email if available
                if let email = customer_email, !email.isEmpty {
                    let username = email.components(separatedBy: "@").first ?? email
                    return username.capitalized
                }

                // Try phone if available
                if let phone = customer_phone, !phone.isEmpty {
                    return phone
                }

                // Fallback: showing "Customer #" + first 8 chars of user_id
                let shortId = String(user_id.prefix(8))
                return "Customer #\(shortId)"
            }
        }

        struct OrderItemResponse: Codable {
            let id: Int
            let order_id: String?
            let quantity: Int

            // Denormalized fields (item data stored directly)
            let item_name: String?
            let item_price: Double?
            let subtotal: Double?

            // Customizations can be either String or Array depending on database
            enum CustomizationsType: Codable {
                case string(String)
                case array([String])

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    if let stringValue = try? container.decode(String.self) {
                        self = .string(stringValue)
                    } else if let arrayValue = try? container.decode([String].self) {
                        self = .array(arrayValue)
                    } else {
                        self = .array([])
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    switch self {
                    case .string(let value):
                        try container.encode(value)
                    case .array(let value):
                        try container.encode(value)
                    }
                }
            }

            let customizations: CustomizationsType?

            // Legacy fields (if referencing menu_items table)
            let menu_item_id: Int?

            // selected_options can be either an array or a dictionary in the database
            enum SelectedOptionsType: Codable {
                case dictionary([String: [String]])
                case array([String])

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()

                    // Try dictionary first
                    if let dict = try? container.decode([String: [String]].self) {
                        self = .dictionary(dict)
                    }
                    // Try array second
                    else if let arr = try? container.decode([String].self) {
                        self = .array(arr)
                    }
                    // Fallback to empty dictionary
                    else {
                        self = .dictionary([:])
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    switch self {
                    case .dictionary(let value):
                        try container.encode(value)
                    case .array(let value):
                        try container.encode(value)
                    }
                }

                var asDictionary: [String: [String]] {
                    switch self {
                    case .dictionary(let dict):
                        return dict
                    case .array(let arr):
                        // Convert array to dictionary format
                        // e.g., ["Extra Cheese", "No Onions"] -> ["Options": ["Extra Cheese", "No Onions"]]
                        if arr.isEmpty {
                            return [:]
                        }
                        return ["Options": arr]
                    }
                }
            }

            let selected_options: SelectedOptionsType?
            let special_instructions: String?
        }

        let response: [OrderResponse] = try await query.execute().value

        // Convert to Order model
        let orders = try response.map { orderResp -> Order in
            print("📦 Order \(orderResp.order_number) has \(orderResp.order_items.count) items")
            let items = orderResp.order_items.compactMap { item -> CartItem? in
                // Check if we have denormalized data (item_name, item_price directly)
                if let itemName = item.item_name, let itemPrice = item.item_price {
                    print("   📄 Item: \(itemName) x\(item.quantity) @ $\(itemPrice)")

                    let menuItem = MenuItem(
                        id: String(item.id),
                        name: itemName,
                        description: "",
                        price: itemPrice,
                        categoryId: "0",
                        imageURL: "",
                        isAvailable: true,
                        dietaryInfo: [],
                        customizationGroups: [],
                        calories: nil,
                        prepTime: 15
                    )

                    // Parse customizations from various formats
                    var customizations: [String: [String]] = [:]
                    var customizationText = ""

                    // First, try the customizations field
                    if let customizationsData = item.customizations {
                        switch customizationsData {
                        case .string(let str):
                            // Parse JSON string
                            if let data = str.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String]] {
                                customizations = json
                            } else {
                                customizationText = str
                            }
                        case .array(let arr):
                            // Convert array to displayable text
                            customizationText = arr.joined(separator: ", ")
                        }
                    }
                    // Also check selected_options field
                    else if let selectedOptionsData = item.selected_options {
                        switch selectedOptionsData {
                        case .dictionary(let dict):
                            customizations = dict
                        case .array(let arr):
                            // Convert array to text
                            customizationText = arr.joined(separator: ", ")
                        }
                    }

                    // Combine special instructions with customization text
                    var finalInstructions = item.special_instructions ?? ""
                    if !customizationText.isEmpty {
                        if !finalInstructions.isEmpty {
                            finalInstructions += "\n\(customizationText)"
                        } else {
                            finalInstructions = customizationText
                        }
                    }

                    return CartItem(
                        id: String(item.id),
                        menuItem: menuItem,
                        quantity: item.quantity,
                        selectedOptions: customizations,
                        specialInstructions: finalInstructions
                    )
                }

                // If no denormalized data, this item is invalid
                print("   ⚠️ Order item \(item.id) missing item_name/item_price")
                return nil
            }

            let dateFormatter = ISO8601DateFormatter()
            let createdAt = dateFormatter.date(from: orderResp.created_at) ?? Date()
            let estimatedReadyTime = orderResp.estimated_ready_time.flatMap { dateFormatter.date(from: $0) }
            let completedAt = orderResp.completed_at.flatMap { dateFormatter.date(from: $0) }

            let order = Order(
                id: orderResp.id,
                orderNumber: orderResp.order_number,
                userId: orderResp.user_id,
                customerName: orderResp.displayName,  // Use displayName instead of customer_name
                storeId: String(orderResp.store_id),  // Convert Int to String
                items: items,
                subtotal: orderResp.subtotal,
                tax: orderResp.tax,
                total: orderResp.total,
                status: OrderStatus(rawValue: orderResp.status) ?? .received,
                orderType: OrderType(rawValue: orderResp.order_type) ?? .pickup,
                createdAt: createdAt,
                estimatedReadyTime: estimatedReadyTime,
                completedAt: completedAt
            )

            print("   → Created order with \(order.items.count) items")
            if order.items.isEmpty {
                print("   ⚠️ WARNING: Order \(order.orderNumber) has no items!")
            }

            return order
        }

        print("✅ Fetched \(orders.count) orders")

        // Enrich orders with actual customer names from staff table
        let enrichedOrders = await enrichOrdersWithUserNames(orders)
        return enrichedOrders
    }

    /// Enrich orders with actual user names from the staff_profiles table
    private func enrichOrdersWithUserNames(_ orders: [Order]) async -> [Order] {
        // Get unique user IDs
        let userIds = Array(Set(orders.map { $0.userId }))

        guard !userIds.isEmpty else { return orders }

        do {
            // Fetch user profiles from staff_profiles table
            struct UserProfileResponse: Codable {
                let id: String
                let full_name: String
            }

            let profiles: [UserProfileResponse] = try await client
                .from("staff_profiles")
                .select("id, full_name")
                .in("id", values: userIds)
                .execute()
                .value

            // Create lookup dictionary
            let userNameLookup = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0.full_name) })

            print("✅ Enriched \(userNameLookup.count) user profiles with names")

            // Enrich orders with actual names
            return orders.map { order in
                if let fullName = userNameLookup[order.userId], !fullName.isEmpty {
                    // Create new order with updated customer name
                    return Order(
                        id: order.id,
                        orderNumber: order.orderNumber,
                        userId: order.userId,
                        customerName: fullName,  // Replace with actual full name
                        storeId: order.storeId,
                        items: order.items,
                        subtotal: order.subtotal,
                        tax: order.tax,
                        total: order.total,
                        status: order.status,
                        orderType: order.orderType,
                        createdAt: order.createdAt,
                        estimatedReadyTime: order.estimatedReadyTime,
                        completedAt: order.completedAt
                    )
                }
                return order
            }
        } catch {
            print("⚠️ Failed to enrich orders with user names: \(error)")
            return orders  // Return original orders if enrichment fails
        }
    }

    /// Backward-compatible overload for single store ID
    /// - Parameter storeId: Single store ID to fetch orders from
    /// - Returns: Array of orders from the specified store
    func fetchOrders(storeId: Int) async throws -> [Order] {
        return try await fetchOrders(storeIds: [storeId])
    }

    func updateOrderStatus(orderId: String, status: String) async throws {
        print("🔄 Updating order \(orderId) to status: \(status)")

        try await client
            .from("orders")
            .update(["status": status])
            .eq("id", value: orderId)
            .execute()

        print("✅ Order status updated successfully")
    }

    // MARK: - Real-Time Subscriptions

    func subscribeToOrders(storeId: Int? = nil, onInsert: @escaping () -> Void) -> Task<Void, Never> {
        Task {
            // Use provided storeId or default to Jay's Deli (store_id = 1)
            let targetStoreId = storeId ?? SupabaseConfig.storeId
            let channelName = "orders_store_\(targetStoreId)"

            let channel = client.channel(channelName)

            // Subscribe to INSERT events (new orders) filtered by store_id
            let insertChanges = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "orders",
                filter: "store_id=eq.\(targetStoreId)"
            )

            // Subscribe to UPDATE events (status changes) filtered by store_id
            let updateChanges = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "orders",
                filter: "store_id=eq.\(targetStoreId)"
            )

            do {
                try await channel.subscribe()
                print("✅ Subscribed to real-time order updates for store \(targetStoreId)")
            } catch {
                print("❌ Real-time subscription error: \(error)")
            }

            // Listen for changes
            Task {
                for await _ in insertChanges {
                    print("🔔 New order received via real-time for store \(targetStoreId)!")
                    onInsert()
                }
            }

            Task {
                for await _ in updateChanges {
                    print("🔔 Order updated via real-time for store \(targetStoreId)!")
                    onInsert()
                }
            }
        }
    }

    // MARK: - Menu Management

    func fetchMenuItems() async throws -> [MenuItem] {
        print("🔄 Fetching menu items from Supabase...")

        struct DBMenuItem: Codable {
            let id: Int
            let name: String
            let description: String
            let price: Double
            let category_id: Int
            let image_url: String?
            let is_available: Bool
            let calories: Int?
            let prep_time: Int?
        }

        let items: [DBMenuItem] = try await client
            .from("menu_items")
            .select()
            .execute()
            .value

        let menuItems = items.map { item in
            MenuItem(
                id: String(item.id),
                name: item.name,
                description: item.description,
                price: item.price,
                categoryId: String(item.category_id),
                imageURL: item.image_url ?? "",
                isAvailable: item.is_available,
                dietaryInfo: [],
                customizationGroups: [],
                calories: item.calories,
                prepTime: item.prep_time ?? 15
            )
        }

        print("✅ Fetched \(menuItems.count) menu items")
        return menuItems
    }

    func fetchCategories() async throws -> [Category] {
        print("🔄 Fetching categories from Supabase...")

        struct DBCategory: Codable {
            let id: Int
            let name: String
            let icon: String?
        }

        let categories: [DBCategory] = try await client
            .from("menu_categories")
            .select()
            .order("id", ascending: true)
            .execute()
            .value

        let result = categories.map { category in
            Category(
                id: String(category.id),
                name: category.name,
                icon: category.icon ?? "🍽️",
                sortOrder: category.id
            )
        }

        print("✅ Fetched \(result.count) categories")
        return result
    }

    func updateMenuItemAvailability(itemId: String, isAvailable: Bool) async throws {
        print("🔄 Updating menu item \(itemId) availability to: \(isAvailable)")

        guard let id = Int(itemId) else {
            throw NSError(domain: "SupabaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid item ID"])
        }

        try await client
            .from("menu_items")
            .update(["is_available": isAvailable])
            .eq("id", value: id)
            .execute()

        print("✅ Menu item availability updated successfully")
    }

    func updateMenuItemPrice(itemId: String, price: Double) async throws {
        print("🔄 Updating menu item \(itemId) price to: $\(String(format: "%.2f", price))")

        guard let id = Int(itemId) else {
            throw NSError(domain: "SupabaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid item ID"])
        }

        try await client
            .from("menu_items")
            .update(["price": price])
            .eq("id", value: id)
            .execute()

        print("✅ Menu item price updated successfully")
    }

    // MARK: - Analytics

    struct AnalyticsSummary {
        let revenue: Double
        let ordersCount: Int
        let customersCount: Int
        let avgPrepTime: Int
        let previousRevenue: Double
        let previousOrdersCount: Int
        let previousCustomersCount: Int
    }

    struct DailySales {
        let date: Date
        let revenue: Double
        let orderCount: Int
    }

    struct TopSellingItem {
        let menuItemId: String
        let menuItemName: String
        let totalQuantity: Int
        let revenue: Double
        let orderCount: Int
    }

    func fetchAnalyticsSummary(storeId: Int, startDate: Date, endDate: Date) async throws -> AnalyticsSummary {
        print("🔄 Fetching analytics summary from \(startDate) to \(endDate)...")

        struct OrderSummary: Codable {
            let id: Int
            let total: Double
            let created_at: String
            let customer_id: Int?
        }

        let dateFormatter = ISO8601DateFormatter()

        // Fetch orders for current period
        let currentOrders: [OrderSummary] = try await client
            .from("orders")
            .select("id, total, created_at, customer_id")
            .eq("store_id", value: storeId)
            .gte("created_at", value: dateFormatter.string(from: startDate))
            .lte("created_at", value: dateFormatter.string(from: endDate))
            .neq("status", value: "cancelled")
            .execute()
            .value

        // Calculate previous period dates
        let duration = endDate.timeIntervalSince(startDate)
        let prevEndDate = startDate
        let prevStartDate = startDate.addingTimeInterval(-duration)

        // Fetch orders for previous period
        let previousOrders: [OrderSummary] = try await client
            .from("orders")
            .select("id, total, created_at, customer_id")
            .eq("store_id", value: storeId)
            .gte("created_at", value: dateFormatter.string(from: prevStartDate))
            .lte("created_at", value: dateFormatter.string(from: prevEndDate))
            .neq("status", value: "cancelled")
            .execute()
            .value

        // Calculate metrics
        let revenue = currentOrders.reduce(0.0) { $0 + $1.total }
        let ordersCount = currentOrders.count
        let uniqueCustomers = Set(currentOrders.compactMap { $0.customer_id }).count

        let previousRevenue = previousOrders.reduce(0.0) { $0 + $1.total }
        let previousOrdersCount = previousOrders.count
        let previousCustomersCount = Set(previousOrders.compactMap { $0.customer_id }).count

        // Average prep time (simplified - using default for now)
        let avgPrepTime = 18

        print("✅ Analytics: Revenue: $\(revenue), Orders: \(ordersCount), Customers: \(uniqueCustomers)")

        return AnalyticsSummary(
            revenue: revenue,
            ordersCount: ordersCount,
            customersCount: uniqueCustomers,
            avgPrepTime: avgPrepTime,
            previousRevenue: previousRevenue,
            previousOrdersCount: previousOrdersCount,
            previousCustomersCount: previousCustomersCount
        )
    }

    func fetchDailySales(storeId: Int, days: Int) async throws -> [DailySales] {
        print("🔄 Fetching daily sales for last \(days) days...")

        struct OrderSummary: Codable {
            let total: Double
            let created_at: String
        }

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date()).addingTimeInterval(86400) // End of today
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!

        let dateFormatter = ISO8601DateFormatter()

        let orders: [OrderSummary] = try await client
            .from("orders")
            .select("total, created_at")
            .eq("store_id", value: storeId)
            .gte("created_at", value: dateFormatter.string(from: startDate))
            .lte("created_at", value: dateFormatter.string(from: endDate))
            .neq("status", value: "cancelled")
            .execute()
            .value

        // Group orders by day
        var salesByDay: [Date: (revenue: Double, count: Int)] = [:]

        for order in orders {
            if let orderDate = dateFormatter.date(from: order.created_at) {
                let dayStart = calendar.startOfDay(for: orderDate)
                let current = salesByDay[dayStart] ?? (revenue: 0.0, count: 0)
                salesByDay[dayStart] = (revenue: current.revenue + order.total, count: current.count + 1)
            }
        }

        // Create daily sales array for all days (including zeros)
        var dailySales: [DailySales] = []
        for dayOffset in 0..<days {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate.addingTimeInterval(-1))!
            let dayStart = calendar.startOfDay(for: date)
            let sales = salesByDay[dayStart] ?? (revenue: 0.0, count: 0)
            dailySales.append(DailySales(date: dayStart, revenue: sales.revenue, orderCount: sales.count))
        }

        dailySales.sort { $0.date < $1.date }

        print("✅ Fetched sales for \(dailySales.count) days")
        return dailySales
    }

    func fetchTopSellingItems(storeId: Int, startDate: Date, endDate: Date, limit: Int = 10) async throws -> [TopSellingItem] {
        print("🔄 Fetching top selling items...")

        struct OrderItemSummary: Codable {
            let id: String
            let name: String
            let price: Double
            let quantity: Int
        }

        let dateFormatter = ISO8601DateFormatter()

        // Query to get order items with menu item details
        let query = """
            id,
            items
        """

        struct OrderData: Codable {
            let id: Int
            let items: [ItemData]
        }

        struct ItemData: Codable {
            let id: String
            let name: String
            let price: Double
            let quantity: Int
        }

        let orders: [OrderData] = try await client
            .from("orders")
            .select(query)
            .eq("store_id", value: storeId)
            .gte("created_at", value: dateFormatter.string(from: startDate))
            .lte("created_at", value: dateFormatter.string(from: endDate))
            .neq("status", value: "cancelled")
            .execute()
            .value

        // Aggregate items
        var itemStats: [String: (name: String, price: Double, totalQuantity: Int, orderCount: Int)] = [:]

        for order in orders {
            for item in order.items {
                if var stats = itemStats[item.id] {
                    stats.totalQuantity += item.quantity
                    stats.orderCount += 1
                    itemStats[item.id] = stats
                } else {
                    itemStats[item.id] = (name: item.name, price: item.price, totalQuantity: item.quantity, orderCount: 1)
                }
            }
        }

        // Convert to TopSellingItem and sort by quantity
        let topItems = itemStats.map { menuItemId, stats in
            TopSellingItem(
                menuItemId: menuItemId,
                menuItemName: stats.name,
                totalQuantity: stats.totalQuantity,
                revenue: Double(stats.totalQuantity) * stats.price,
                orderCount: stats.orderCount
            )
        }
        .sorted { $0.totalQuantity > $1.totalQuantity }
        .prefix(limit)

        print("✅ Fetched \(topItems.count) top selling items")
        return Array(topItems)
    }

    func fetchOrderTypeDistribution(storeId: Int, startDate: Date, endDate: Date) async throws -> [String: Int] {
        print("🔄 Fetching order type distribution...")

        struct OrderType: Codable {
            let type: String
        }

        let dateFormatter = ISO8601DateFormatter()

        let orders: [OrderType] = try await client
            .from("orders")
            .select("type")
            .eq("store_id", value: storeId)
            .gte("created_at", value: dateFormatter.string(from: startDate))
            .lte("created_at", value: dateFormatter.string(from: endDate))
            .neq("status", value: "cancelled")
            .execute()
            .value

        // Count by type
        var distribution: [String: Int] = [:]
        for order in orders {
            distribution[order.type, default: 0] += 1
        }

        print("✅ Order type distribution: \(distribution)")
        return distribution
    }

    // MARK: - Marketing - Coupons

    struct CouponResponse: Codable {
        let id: Int
        let store_id: Int
        let code: String
        let name: String
        let description: String?
        let discount_type: String
        let discount_value: Double
        let min_order_value: Double?
        let max_discount_amount: Double?
        let applicable_order_types: [String]?
        let applicable_menu_categories: [Int]?
        let first_order_only: Bool
        let max_uses_total: Int?
        let max_uses_per_customer: Int
        let current_uses: Int
        let start_date: String
        let end_date: String?
        let active_days_of_week: [Int]?
        let active_hours_start: String?
        let active_hours_end: String?
        let target_segment: String?
        let minimum_tier_id: Int?
        let is_active: Bool
        let is_featured: Bool
        let created_at: String
        let updated_at: String
    }

    func fetchCoupons(storeId: Int) async throws -> [CouponResponse] {
        print("🔄 Fetching coupons for store \(storeId)...")

        let coupons: [CouponResponse] = try await client
            .from("coupons")
            .select()
            .eq("store_id", value: storeId)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ Fetched \(coupons.count) coupons")
        return coupons
    }

    struct CreateCouponRequest: Encodable {
        let store_id: Int
        let code: String
        let name: String
        let description: String?
        let discount_type: String
        let discount_value: Double
        let min_order_value: Double?
        let max_uses_total: Int?
        let max_uses_per_customer: Int
        let first_order_only: Bool
        let start_date: String
        let end_date: String?
        let is_active: Bool
        let is_featured: Bool
    }

    func createCoupon(coupon: CreateCouponRequest) async throws -> CouponResponse {
        print("🔄 Creating coupon: \(coupon.code)...")

        let response: CouponResponse = try await client
            .from("coupons")
            .insert(coupon)
            .select()
            .single()
            .execute()
            .value

        print("✅ Coupon created: \(response.code)")
        return response
    }

    func updateCoupon(id: Int, isActive: Bool) async throws {
        print("🔄 Updating coupon \(id) active status to: \(isActive)...")

        try await client
            .from("coupons")
            .update(["is_active": isActive])
            .eq("id", value: id)
            .execute()

        print("✅ Coupon updated successfully")
    }

    func deleteCoupon(id: Int) async throws {
        print("🔄 Deleting coupon \(id)...")

        try await client
            .from("coupons")
            .delete()
            .eq("id", value: id)
            .execute()

        print("✅ Coupon deleted successfully")
    }

    // MARK: - Marketing - Push Notifications

    struct PushNotificationResponse: Codable {
        let id: Int
        let store_id: Int
        let title: String
        let body: String
        let image_url: String?
        let action_url: String?
        let target_segment: String?
        let target_customer_ids: [Int]?
        let target_tier_ids: [Int]?
        let scheduled_for: String?
        let send_immediately: Bool
        let status: String
        let sent_at: String?
        let recipients_count: Int
        let delivered_count: Int
        let opened_count: Int
        let clicked_count: Int
        let created_at: String
        let updated_at: String
    }

    func fetchNotifications(storeId: Int) async throws -> [PushNotificationResponse] {
        print("🔄 Fetching push notifications for store \(storeId)...")

        let notifications: [PushNotificationResponse] = try await client
            .from("push_notifications")
            .select()
            .eq("store_id", value: storeId)
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
            .value

        print("✅ Fetched \(notifications.count) notifications")
        return notifications
    }

    struct CreateNotificationRequest: Encodable {
        let store_id: Int
        let title: String
        let body: String
        let image_url: String?
        let action_url: String?
        let target_segment: String
        let send_immediately: Bool
        let scheduled_for: String?
        let status: String
    }

    func createNotification(notification: CreateNotificationRequest) async throws -> PushNotificationResponse {
        print("🔄 Creating notification: \(notification.title)...")

        let response: PushNotificationResponse = try await client
            .from("push_notifications")
            .insert(notification)
            .select()
            .single()
            .execute()
            .value

        print("✅ Notification created: \(response.title)")
        return response
    }

    func deleteNotification(id: Int) async throws {
        print("🔄 Deleting notification \(id)...")

        try await client
            .from("push_notifications")
            .delete()
            .eq("id", value: id)
            .execute()

        print("✅ Notification deleted successfully")
    }

    // MARK: - Marketing - Loyalty Program

    struct LoyaltyProgramResponse: Codable {
        let id: Int
        let store_id: Int
        let name: String
        let points_per_dollar: Double
        let welcome_bonus_points: Int
        let referral_bonus_points: Int
        let is_active: Bool
        let created_at: String
        let updated_at: String
    }

    struct LoyaltyTierResponse: Codable {
        let id: Int
        let program_id: Int
        let name: String
        let min_points: Int
        let discount_percentage: Double
        let free_delivery: Bool
        let priority_support: Bool
        let early_access_promos: Bool
        let birthday_reward_points: Int
        let tier_color: String?
        let sort_order: Int
        let created_at: String
    }

    struct CustomerLoyaltyResponse: Codable {
        let id: Int
        let customer_id: Int
        let program_id: Int
        let current_tier_id: Int?
        let total_points: Int
        let lifetime_points: Int
        let total_orders: Int
        let total_spent: Double
        let joined_at: String
        let last_order_at: String?
        let updated_at: String
    }

    struct LoyaltyTransactionResponse: Codable {
        let id: Int
        let customer_loyalty_id: Int
        let order_id: String?
        let transaction_type: String
        let points: Int
        let reason: String?
        let balance_after: Int
        let created_at: String
    }

    func fetchLoyaltyProgram(storeId: Int) async throws -> LoyaltyProgramResponse {
        print("🔄 Fetching loyalty program for store \(storeId)...")

        let programs: [LoyaltyProgramResponse] = try await client
            .from("loyalty_programs")
            .select()
            .eq("store_id", value: storeId)
            .limit(1)
            .execute()
            .value

        guard let program = programs.first else {
            throw NSError(domain: "SupabaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No loyalty program found"])
        }

        print("✅ Fetched loyalty program: \(program.name)")
        return program
    }

    struct UpdateLoyaltyProgramRequest: Encodable {
        let name: String?
        let points_per_dollar: Double?
        let welcome_bonus_points: Int?
        let referral_bonus_points: Int?
        let is_active: Bool?
    }

    func updateLoyaltyProgram(
        programId: Int,
        name: String? = nil,
        pointsPerDollar: Double? = nil,
        welcomeBonusPoints: Int? = nil,
        referralBonusPoints: Int? = nil,
        isActive: Bool? = nil
    ) async throws -> LoyaltyProgramResponse {
        print("🔄 Updating loyalty program \(programId)...")

        let request = UpdateLoyaltyProgramRequest(
            name: name,
            points_per_dollar: pointsPerDollar,
            welcome_bonus_points: welcomeBonusPoints,
            referral_bonus_points: referralBonusPoints,
            is_active: isActive
        )

        let updated: LoyaltyProgramResponse = try await client
            .from("loyalty_programs")
            .update(request)
            .eq("id", value: programId)
            .single()
            .execute()
            .value

        print("✅ Updated loyalty program: \(updated.name)")
        return updated
    }

    func fetchLoyaltyTiers(programId: Int) async throws -> [LoyaltyTierResponse] {
        print("🔄 Fetching loyalty tiers for program \(programId)...")

        let tiers: [LoyaltyTierResponse] = try await client
            .from("loyalty_tiers")
            .select()
            .eq("program_id", value: programId)
            .order("sort_order", ascending: true)
            .execute()
            .value

        print("✅ Fetched \(tiers.count) loyalty tiers")
        return tiers
    }

    struct CreateLoyaltyTierRequest: Encodable {
        let program_id: Int
        let name: String
        let min_points: Int
        let discount_percentage: Double
        let free_delivery: Bool
        let priority_support: Bool
        let early_access_promos: Bool
        let birthday_reward_points: Int
        let tier_color: String?
        let sort_order: Int
    }

    func createLoyaltyTier(
        programId: Int,
        name: String,
        minPoints: Int,
        discountPercentage: Double,
        freeDelivery: Bool,
        prioritySupport: Bool,
        earlyAccessPromos: Bool,
        birthdayRewardPoints: Int,
        tierColor: String?,
        sortOrder: Int
    ) async throws -> LoyaltyTierResponse {
        print("🔄 Creating loyalty tier: \(name)...")

        let request = CreateLoyaltyTierRequest(
            program_id: programId,
            name: name,
            min_points: minPoints,
            discount_percentage: discountPercentage,
            free_delivery: freeDelivery,
            priority_support: prioritySupport,
            early_access_promos: earlyAccessPromos,
            birthday_reward_points: birthdayRewardPoints,
            tier_color: tierColor,
            sort_order: sortOrder
        )

        let created: LoyaltyTierResponse = try await client
            .from("loyalty_tiers")
            .insert(request)
            .single()
            .execute()
            .value

        print("✅ Created loyalty tier: \(created.name)")
        return created
    }

    struct UpdateLoyaltyTierRequest: Encodable {
        let name: String?
        let min_points: Int?
        let discount_percentage: Double?
        let free_delivery: Bool?
        let priority_support: Bool?
        let early_access_promos: Bool?
        let birthday_reward_points: Int?
        let tier_color: String?
        let sort_order: Int?
    }

    func updateLoyaltyTier(
        tierId: Int,
        name: String? = nil,
        minPoints: Int? = nil,
        discountPercentage: Double? = nil,
        freeDelivery: Bool? = nil,
        prioritySupport: Bool? = nil,
        earlyAccessPromos: Bool? = nil,
        birthdayRewardPoints: Int? = nil,
        tierColor: String? = nil,
        sortOrder: Int? = nil
    ) async throws -> LoyaltyTierResponse {
        print("🔄 Updating loyalty tier \(tierId)...")

        let request = UpdateLoyaltyTierRequest(
            name: name,
            min_points: minPoints,
            discount_percentage: discountPercentage,
            free_delivery: freeDelivery,
            priority_support: prioritySupport,
            early_access_promos: earlyAccessPromos,
            birthday_reward_points: birthdayRewardPoints,
            tier_color: tierColor,
            sort_order: sortOrder
        )

        let updated: LoyaltyTierResponse = try await client
            .from("loyalty_tiers")
            .update(request)
            .eq("id", value: tierId)
            .single()
            .execute()
            .value

        print("✅ Updated loyalty tier: \(updated.name)")
        return updated
    }

    func deleteLoyaltyTier(tierId: Int) async throws {
        print("🔄 Deleting loyalty tier \(tierId)...")

        try await client
            .from("loyalty_tiers")
            .delete()
            .eq("id", value: tierId)
            .execute()

        print("✅ Deleted loyalty tier")
    }

    // MARK: - Loyalty Rewards

    struct LoyaltyRewardResponse: Codable {
        let id: Int
        let program_id: Int
        let name: String
        let description: String?
        let points_cost: Int
        let reward_type: String
        let reward_value: String
        let image_url: String?
        let is_active: Bool
        let stock_quantity: Int?
        let redemption_count: Int
        let sort_order: Int
        let created_at: String
        let updated_at: String
    }

    func fetchLoyaltyRewards(programId: Int) async throws -> [LoyaltyRewardResponse] {
        print("🔄 Fetching loyalty rewards for program \(programId)...")

        let rewards: [LoyaltyRewardResponse] = try await client
            .from("loyalty_rewards")
            .select()
            .eq("program_id", value: programId)
            .order("sort_order", ascending: true)
            .execute()
            .value

        print("✅ Fetched \(rewards.count) loyalty rewards")
        return rewards
    }

    struct CreateLoyaltyRewardRequest: Encodable {
        let program_id: Int
        let name: String
        let description: String?
        let points_cost: Int
        let reward_type: String
        let reward_value: String
        let image_url: String?
        let is_active: Bool
        let stock_quantity: Int?
        let sort_order: Int
    }

    func createLoyaltyReward(
        programId: Int,
        name: String,
        description: String?,
        pointsCost: Int,
        rewardType: String,
        rewardValue: String,
        imageUrl: String?,
        isActive: Bool,
        stockQuantity: Int?,
        sortOrder: Int
    ) async throws -> LoyaltyRewardResponse {
        print("🔄 Creating loyalty reward: \(name)...")

        let request = CreateLoyaltyRewardRequest(
            program_id: programId,
            name: name,
            description: description,
            points_cost: pointsCost,
            reward_type: rewardType,
            reward_value: rewardValue,
            image_url: imageUrl,
            is_active: isActive,
            stock_quantity: stockQuantity,
            sort_order: sortOrder
        )

        let created: LoyaltyRewardResponse = try await client
            .from("loyalty_rewards")
            .insert(request)
            .single()
            .execute()
            .value

        print("✅ Created loyalty reward: \(created.name)")
        return created
    }

    struct UpdateLoyaltyRewardRequest: Encodable {
        let name: String?
        let description: String?
        let points_cost: Int?
        let reward_type: String?
        let reward_value: String?
        let image_url: String?
        let is_active: Bool?
        let stock_quantity: Int?
        let sort_order: Int?
    }

    func updateLoyaltyReward(
        rewardId: Int,
        name: String? = nil,
        description: String? = nil,
        pointsCost: Int? = nil,
        rewardType: String? = nil,
        rewardValue: String? = nil,
        imageUrl: String? = nil,
        isActive: Bool? = nil,
        stockQuantity: Int? = nil,
        sortOrder: Int? = nil
    ) async throws -> LoyaltyRewardResponse {
        print("🔄 Updating loyalty reward \(rewardId)...")

        let request = UpdateLoyaltyRewardRequest(
            name: name,
            description: description,
            points_cost: pointsCost,
            reward_type: rewardType,
            reward_value: rewardValue,
            image_url: imageUrl,
            is_active: isActive,
            stock_quantity: stockQuantity,
            sort_order: sortOrder
        )

        let updated: LoyaltyRewardResponse = try await client
            .from("loyalty_rewards")
            .update(request)
            .eq("id", value: rewardId)
            .single()
            .execute()
            .value

        print("✅ Updated loyalty reward: \(updated.name)")
        return updated
    }

    func deleteLoyaltyReward(rewardId: Int) async throws {
        print("🔄 Deleting loyalty reward \(rewardId)...")

        try await client
            .from("loyalty_rewards")
            .delete()
            .eq("id", value: rewardId)
            .execute()

        print("✅ Deleted loyalty reward")
    }

    // MARK: - Bulk Points Award

    func bulkAwardLoyaltyPoints(customerIds: [Int], points: Int, reason: String) async throws {
        print("🔄 Bulk awarding \(points) points to \(customerIds.count) customers...")

        // Process each customer sequentially to ensure data integrity
        var successCount = 0
        var errors: [Error] = []

        for customerId in customerIds {
            do {
                // Get customer's loyalty record
                let loyalty: [CustomerLoyaltyResponse] = try await client
                    .from("customer_loyalty")
                    .select()
                    .eq("customer_id", value: customerId)
                    .limit(1)
                    .execute()
                    .value

                guard let customerLoyalty = loyalty.first else {
                    print("⚠️ No loyalty record found for customer \(customerId)")
                    continue
                }

                // Calculate new balance
                let newBalance = customerLoyalty.total_points + points
                let newLifetimePoints = customerLoyalty.lifetime_points + points

                // Update customer loyalty balance
                struct UpdateLoyaltyBalanceRequest: Encodable {
                    let total_points: Int
                    let lifetime_points: Int
                }

                try await client
                    .from("customer_loyalty")
                    .update(UpdateLoyaltyBalanceRequest(
                        total_points: newBalance,
                        lifetime_points: newLifetimePoints
                    ))
                    .eq("id", value: customerLoyalty.id)
                    .execute()

                // Create transaction record
                struct BulkPointsTransactionRequest: Encodable {
                    let customer_loyalty_id: Int
                    let transaction_type: String
                    let points: Int
                    let reason: String
                    let balance_after: Int
                }

                try await client
                    .from("loyalty_transactions")
                    .insert(BulkPointsTransactionRequest(
                        customer_loyalty_id: customerLoyalty.id,
                        transaction_type: "manual_award",
                        points: points,
                        reason: reason,
                        balance_after: newBalance
                    ))
                    .execute()

                successCount += 1
                print("  ✓ Awarded \(points) points to customer \(customerId)")

            } catch {
                print("  ✗ Failed to award points to customer \(customerId): \(error)")
                errors.append(error)
            }
        }

        print("✅ Bulk award completed: \(successCount)/\(customerIds.count) successful")

        if !errors.isEmpty && successCount == 0 {
            throw NSError(domain: "SupabaseManager", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to award points to any customers"
            ])
        }
    }

    func fetchCustomerLoyalty(customerId: Int) async throws -> CustomerLoyaltyResponse {
        print("🔄 Fetching customer loyalty for customer \(customerId)...")

        let loyalty: [CustomerLoyaltyResponse] = try await client
            .from("customer_loyalty")
            .select()
            .eq("customer_id", value: customerId)
            .limit(1)
            .execute()
            .value

        guard let customerLoyalty = loyalty.first else {
            throw NSError(domain: "SupabaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No loyalty data found"])
        }

        print("✅ Fetched customer loyalty: \(customerLoyalty.total_points) points")
        return customerLoyalty
    }

    func fetchLoyaltyTransactions(customerLoyaltyId: Int, limit: Int = 20) async throws -> [LoyaltyTransactionResponse] {
        print("🔄 Fetching loyalty transactions...")

        let transactions: [LoyaltyTransactionResponse] = try await client
            .from("loyalty_transactions")
            .select()
            .eq("customer_loyalty_id", value: customerLoyaltyId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        print("✅ Fetched \(transactions.count) transactions")
        return transactions
    }

    struct AddLoyaltyPointsRequest: Encodable {
        let customer_loyalty_id: Int
        let transaction_type: String
        let points: Int
        let reason: String
        let balance_after: Int
    }

    func addLoyaltyPoints(customerLoyaltyId: Int, points: Int, reason: String) async throws {
        print("🔄 Adding \(points) loyalty points...")

        // First, get current balance
        let currentLoyalty = try await client
            .from("customer_loyalty")
            .select("total_points")
            .eq("id", value: customerLoyaltyId)
            .single()
            .execute()
            .value as! [String: Any]

        let currentPoints = currentLoyalty["total_points"] as! Int
        let newBalance = currentPoints + points

        // Create transaction record
        let transaction = AddLoyaltyPointsRequest(
            customer_loyalty_id: customerLoyaltyId,
            transaction_type: points > 0 ? "bonus" : "adjustment",
            points: points,
            reason: reason,
            balance_after: newBalance
        )

        try await client
            .from("loyalty_transactions")
            .insert(transaction)
            .execute()

        // Update customer loyalty balance
        try await client
            .from("customer_loyalty")
            .update([
                "total_points": newBalance,
                "lifetime_points": currentPoints + (points > 0 ? points : 0)
            ])
            .eq("id", value: customerLoyaltyId)
            .execute()

        print("✅ Added \(points) points successfully")
    }

    // MARK: - Marketing - Referral Program

    struct ReferralProgramResponse: Codable {
        let id: Int
        let store_id: Int
        let referrer_reward_type: String
        let referrer_reward_value: Double
        let referee_reward_type: String
        let referee_reward_value: Double
        let min_order_value: Double
        let max_referrals_per_customer: Int?
        let is_active: Bool
        let created_at: String
        let updated_at: String
    }

    struct ReferralResponse: Codable {
        let id: Int
        let program_id: Int
        let referral_code: String
        let referrer_customer_id: Int
        let referee_customer_id: Int?
        let status: String
        let referrer_rewarded: Bool
        let referee_rewarded: Bool
        let created_at: String
        let completed_at: String?
        let rewarded_at: String?
    }

    func fetchReferralProgram(storeId: Int) async throws -> ReferralProgramResponse {
        print("🔄 Fetching referral program for store \(storeId)...")

        let programs: [ReferralProgramResponse] = try await client
            .from("referral_program")
            .select()
            .eq("store_id", value: storeId)
            .limit(1)
            .execute()
            .value

        guard let program = programs.first else {
            throw NSError(domain: "SupabaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No referral program found"])
        }

        print("✅ Fetched referral program")
        return program
    }

    func fetchReferrals(programId: Int, limit: Int = 20) async throws -> [ReferralResponse] {
        print("🔄 Fetching referrals for program \(programId)...")

        let referrals: [ReferralResponse] = try await client
            .from("referrals")
            .select()
            .eq("program_id", value: programId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        print("✅ Fetched \(referrals.count) referrals")
        return referrals
    }

    // MARK: - Marketing - Automated Campaigns

    struct AutomatedCampaignResponse: Codable {
        let id: Int
        let store_id: Int
        let campaign_type: String
        let name: String
        let description: String?
        let trigger_condition: String
        let trigger_value: Int?
        let notification_title: String
        let notification_message: String
        let cta_type: String?
        let cta_value: String?
        let target_audience: String
        let is_active: Bool
        let times_triggered: Int
        let conversion_count: Int
        let revenue_generated: Double
        let created_at: String
        let updated_at: String
    }

    func fetchAutomatedCampaigns(storeId: Int) async throws -> [AutomatedCampaignResponse] {
        print("🔄 Fetching automated campaigns for store \(storeId)...")

        let campaigns: [AutomatedCampaignResponse] = try await client
            .from("automated_campaigns")
            .select()
            .eq("store_id", value: storeId)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ Fetched \(campaigns.count) automated campaigns")
        return campaigns
    }

    struct UpdateCampaignStatusRequest: Encodable {
        let is_active: Bool
    }

    func toggleCampaignStatus(campaignId: Int, isActive: Bool) async throws {
        print("🔄 Toggling campaign \(campaignId) to \(isActive ? "active" : "inactive")...")

        let request = UpdateCampaignStatusRequest(is_active: isActive)

        try await client
            .from("automated_campaigns")
            .update(request)
            .eq("id", value: campaignId)
            .execute()

        print("✅ Campaign status updated successfully")
    }

    struct CreateAutomatedCampaignRequest: Encodable {
        let store_id: Int
        let campaign_type: String
        let name: String
        let description: String?
        let trigger_condition: String
        let trigger_value: Int?
        let notification_title: String
        let notification_message: String
        let cta_type: String?
        let cta_value: String?
        let target_audience: String
        let is_active: Bool
    }

    func createAutomatedCampaign(
        storeId: Int,
        campaignType: String,
        name: String,
        description: String?,
        triggerCondition: String,
        triggerValue: Int?,
        notificationTitle: String,
        notificationMessage: String,
        ctaType: String?,
        ctaValue: String?,
        targetAudience: String,
        isActive: Bool
    ) async throws -> AutomatedCampaignResponse {
        print("🔄 Creating automated campaign: \(name)...")

        let request = CreateAutomatedCampaignRequest(
            store_id: storeId,
            campaign_type: campaignType,
            name: name,
            description: description,
            trigger_condition: triggerCondition,
            trigger_value: triggerValue,
            notification_title: notificationTitle,
            notification_message: notificationMessage,
            cta_type: ctaType,
            cta_value: ctaValue,
            target_audience: targetAudience,
            is_active: isActive
        )

        let response: AutomatedCampaignResponse = try await client
            .from("automated_campaigns")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        print("✅ Automated campaign created: \(response.name)")
        return response
    }

    func deleteAutomatedCampaign(id: Int) async throws {
        print("🔄 Deleting automated campaign \(id)...")

        try await client
            .from("automated_campaigns")
            .delete()
            .eq("id", value: id)
            .execute()

        print("✅ Automated campaign deleted successfully")
    }

    // MARK: - Ingredient Templates & Customizations

    /// Fetch all active ingredient templates
    func fetchIngredientTemplates() async throws -> [IngredientTemplate] {
        print("🔄 Fetching ingredient templates...")

        let response: [IngredientTemplate] = try await client
            .from("ingredient_templates")
            .select()
            .eq("is_active", value: true)
            .order("category")
            .order("display_order")
            .execute()
            .value

        print("✅ Fetched \(response.count) ingredient templates")
        return response
    }

    /// Fetch ingredient templates by category
    func fetchIngredientTemplates(category: IngredientCategory) async throws -> [IngredientTemplate] {
        print("🔄 Fetching \(category.rawValue) ingredients...")

        let response: [IngredientTemplate] = try await client
            .from("ingredient_templates")
            .select()
            .eq("is_active", value: true)
            .eq("category", value: category.rawValue)
            .order("display_order")
            .execute()
            .value

        print("✅ Fetched \(response.count) \(category.rawValue) ingredients")
        return response
    }

    /// Fetch customizations for a specific menu item
    func fetchMenuItemCustomizations(menuItemId: Int) async throws -> [MenuItemCustomization] {
        print("🔄 Fetching customizations for menu item \(menuItemId)...")

        let response: [MenuItemCustomization] = try await client
            .from("menu_item_customizations")
            .select()
            .eq("menu_item_id", value: menuItemId)
            .order("category")
            .order("display_order")
            .execute()
            .value

        print("✅ Fetched \(response.count) customizations for menu item \(menuItemId)")
        return response
    }

    /// Fetch only portion-based customizations for a menu item
    func fetchPortionCustomizations(menuItemId: Int) async throws -> [MenuItemCustomization] {
        print("🔄 Fetching portion customizations for menu item \(menuItemId)...")

        let response: [MenuItemCustomization] = try await client
            .from("menu_item_customizations")
            .select()
            .eq("menu_item_id", value: menuItemId)
            .eq("supports_portions", value: true)
            .order("category")
            .order("display_order")
            .execute()
            .value

        print("✅ Fetched \(response.count) portion customizations")
        return response
    }
}
