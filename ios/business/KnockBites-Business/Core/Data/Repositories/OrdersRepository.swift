//
//  OrdersRepository.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 5 cleanup - consolidated orders data access
//

import Foundation
import Supabase

/// Repository for all order-related data operations
class OrdersRepository {
    static let shared = OrdersRepository()

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Fetch Orders

    func fetchOrders(storeIds: [Int]? = nil) async throws -> [Order] {
        print("🔄 Fetching orders from Supabase...")

        // Get accessible stores from AuthManager or use provided storeIds
        let targetStoreIds: [Int]
        if let providedIds = storeIds {
            targetStoreIds = providedIds
        } else {
            targetStoreIds = await AuthManager.shared.getAccessibleStores()

            let isSuperAdmin = await AuthManager.shared.isSuperAdmin()
            if targetStoreIds.isEmpty && !isSuperAdmin {
                print("⚠️ User has no accessible stores")
                return []
            }
        }

        print("📍 Fetching orders for stores: \(targetStoreIds)")

        let query: PostgrestTransformBuilder

        let isSuperAdmin = await AuthManager.shared.isSuperAdmin()
        if targetStoreIds.isEmpty && isSuperAdmin {
            print("🔓 Super admin: fetching ALL orders")
            query = client
                .from(TableNames.orders)
                .select("""
                    *,
                    order_items(*)
                """)
                .order("created_at", ascending: false)
        } else {
            query = client
                .from(TableNames.orders)
                .select("""
                    *,
                    order_items(*)
                """)
                .in("store_id", values: targetStoreIds)
                .order("created_at", ascending: false)
        }

        let response: [OrderResponse] = try await query.execute().value

        let orders = try response.map { orderResp -> Order in
            print("📦 Order \(orderResp.orderNumber) has \(orderResp.orderItems.count) items")
            let items = orderResp.orderItems.compactMap { item -> CartItem? in
                if let itemName = item.itemName, let itemPrice = item.itemPrice {
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

                    var customizations: [String: [String]] = [:]
                    var customizationText = ""

                    if let customizationsData = item.customizations {
                        switch customizationsData {
                        case .string(let str):
                            if let data = str.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String]] {
                                customizations = json
                            } else {
                                customizationText = str
                            }
                        case .array(let arr):
                            customizationText = arr.joined(separator: ", ")
                        }
                    } else if let selectedOptionsData = item.selectedOptions {
                        switch selectedOptionsData {
                        case .dictionary(let dict):
                            customizations = dict
                        case .array(let arr):
                            customizationText = arr.joined(separator: ", ")
                        }
                    }

                    var finalInstructions = item.specialInstructions ?? ""
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

                print("   ⚠️ Order item \(item.id) missing item_name/item_price")
                return nil
            }

            let createdAt = DateFormatting.parseISO8601(orderResp.createdAt) ?? Date()
            let estimatedReadyTime = orderResp.estimatedReadyTime.flatMap { DateFormatting.parseISO8601($0) }
            let completedAt = orderResp.completedAt.flatMap { DateFormatting.parseISO8601($0) }

            let order = Order(
                id: orderResp.id,
                orderNumber: orderResp.orderNumber,
                userId: orderResp.userId,
                customerName: orderResp.displayName,
                storeId: String(orderResp.storeId),
                items: items,
                subtotal: orderResp.subtotal,
                tax: orderResp.tax,
                total: orderResp.total,
                status: OrderStatus(rawValue: orderResp.status) ?? .received,
                orderType: OrderType(rawValue: orderResp.orderType) ?? .pickup,
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

        let enrichedOrders = await enrichOrdersWithUserNames(orders)
        return enrichedOrders
    }

    func fetchOrders(storeId: Int) async throws -> [Order] {
        return try await fetchOrders(storeIds: [storeId])
    }

    // MARK: - Update Order Status

    func updateOrderStatus(orderId: String, status: String) async throws {
        print("🔄 Updating order \(orderId) to status: \(status)")

        try await client
            .from(TableNames.orders)
            .update(["status": status])
            .eq("id", value: orderId)
            .execute()

        print("✅ Order status updated successfully")
    }

    // MARK: - Real-Time Subscriptions

    func subscribeToOrders(storeId: Int? = nil, onInsert: @escaping () -> Void) -> Task<Void, Never> {
        Task {
            let targetStoreId = storeId ?? SecureSupabaseConfig.storeId
            let channelName = "orders_store_\(targetStoreId)"

            let channel = client.channel(channelName)

            let insertChanges = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: TableNames.orders,
                filter: "store_id=eq.\(targetStoreId)"
            )

            let updateChanges = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: TableNames.orders,
                filter: "store_id=eq.\(targetStoreId)"
            )

            do {
                try await channel.subscribe()
                print("✅ Subscribed to real-time order updates for store \(targetStoreId)")
            } catch {
                print("❌ Real-time subscription error: \(error)")
            }

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

    // MARK: - Private Helpers

    private func enrichOrdersWithUserNames(_ orders: [Order]) async -> [Order] {
        let userIds = Array(Set(orders.map { $0.userId }))

        guard !userIds.isEmpty else { return orders }

        do {
            struct UserProfileResponse: Codable {
                let id: String
                let fullName: String

                enum CodingKeys: String, CodingKey {
                    case id
                    case fullName = "full_name"
                }
            }

            let profiles: [UserProfileResponse] = try await client
                .from(TableNames.userProfiles)
                .select("id, full_name")
                .in("id", values: userIds)
                .execute()
                .value

            let userNameLookup = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0.fullName) })

            print("✅ Enriched \(userNameLookup.count) user profiles with names")

            return orders.map { order in
                if let fullName = userNameLookup[order.userId], !fullName.isEmpty {
                    return Order(
                        id: order.id,
                        orderNumber: order.orderNumber,
                        userId: order.userId,
                        customerName: fullName,
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
            return orders
        }
    }

    // MARK: - Response Types

    private struct OrderResponse: Codable {
        let id: String
        let orderNumber: String
        let userId: String
        let customerName: String?
        let customerEmail: String?
        let customerPhone: String?
        let storeId: Int
        let subtotal: Double
        let tax: Double
        let total: Double
        let status: String
        let orderType: String
        let createdAt: String
        let estimatedReadyTime: String?
        let completedAt: String?
        let orderItems: [OrderItemResponse]

        var displayName: String {
            if let name = customerName, !name.isEmpty {
                let hasSpace = name.contains(" ")
                let hasCapitalInMiddle = name.dropFirst().contains(where: { $0.isUppercase })

                if hasSpace || hasCapitalInMiddle {
                    return name
                }

                if !name.contains("-") && !name.contains("@") && name.count > 2 {
                    return name.capitalized
                }
            }

            if let email = customerEmail, !email.isEmpty {
                let username = email.components(separatedBy: "@").first ?? email
                return username.capitalized
            }

            if let phone = customerPhone, !phone.isEmpty {
                return phone
            }

            let shortId = String(userId.prefix(8))
            return "Customer #\(shortId)"
        }

        enum CodingKeys: String, CodingKey {
            case id
            case orderNumber = "order_number"
            case userId = "user_id"
            case customerName = "customer_name"
            case customerEmail = "customer_email"
            case customerPhone = "customer_phone"
            case storeId = "store_id"
            case subtotal, tax, total, status
            case orderType = "order_type"
            case createdAt = "created_at"
            case estimatedReadyTime = "estimated_ready_at"  // Fixed: DB column is estimated_ready_at
            case completedAt = "completed_at"
            case orderItems = "order_items"
        }
    }

    private struct OrderItemResponse: Codable {
        let id: Int
        let orderId: String?
        let quantity: Int
        let itemName: String?
        let itemPrice: Double?
        let subtotal: Double?
        let customizations: CustomizationsType?
        let menuItemId: Int?
        let selectedOptions: SelectedOptionsType?
        let specialInstructions: String?

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

        enum SelectedOptionsType: Codable {
            case dictionary([String: [String]])
            case array([String])

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()

                if let dict = try? container.decode([String: [String]].self) {
                    self = .dictionary(dict)
                } else if let arr = try? container.decode([String].self) {
                    self = .array(arr)
                } else {
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
        }

        enum CodingKeys: String, CodingKey {
            case id
            case orderId = "order_id"
            case quantity
            case itemName = "item_name"
            case itemPrice = "item_price"
            case subtotal
            case customizations
            case menuItemId = "menu_item_id"
            case selectedOptions = "selected_options"
            case specialInstructions = "special_instructions"
        }
    }
}
