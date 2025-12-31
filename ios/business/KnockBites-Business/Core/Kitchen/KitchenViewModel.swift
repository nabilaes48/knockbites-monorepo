//
//  KitchenViewModel.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/13/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Kitchen Order Status

enum KitchenOrderStatus: String, CaseIterable {
    case received = "received"
    case acknowledged = "acknowledged"
    case preparing = "preparing"
    case ready = "ready"
    case pickedUp = "picked_up"
    case completed = "completed"

    var displayName: String {
        switch self {
        case .received: return "Received"
        case .acknowledged: return "Acknowledged"
        case .preparing: return "Preparing"
        case .ready: return "Ready"
        case .pickedUp: return "Picked Up"
        case .completed: return "Completed"
        }
    }

    var tabTitle: String {
        switch self {
        case .received: return "New Orders"
        case .acknowledged: return "Queued"
        case .preparing: return "Preparing"
        case .ready: return "Ready"
        case .pickedUp: return "Out"
        case .completed: return "Done"
        }
    }

    var icon: String {
        switch self {
        case .received: return "bell.badge.fill"
        case .acknowledged: return "checkmark.circle"
        case .preparing: return "flame.fill"
        case .ready: return "checkmark.seal.fill"
        case .pickedUp: return "shippingbox.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }

    var nextStatus: KitchenOrderStatus? {
        switch self {
        case .received: return .acknowledged
        case .acknowledged: return .preparing
        case .preparing: return .ready
        case .ready: return .pickedUp
        case .pickedUp: return .completed
        case .completed: return nil
        }
    }

    func actionButtonTitle(for orderType: OrderType) -> String {
        switch self {
        case .received: return "Acknowledge"
        case .acknowledged: return "Start Prep"
        case .preparing: return "Mark as Ready"
        case .ready:
            switch orderType {
            case .delivery: return "Out for Delivery"
            case .pickup: return "Picked Up"
            case .dineIn: return "Served"
            }
        case .pickedUp: return "Complete"
        case .completed: return ""
        }
    }

    var buttonColor: Color {
        switch self {
        case .received: return .warning
        case .acknowledged: return Color.yellow
        case .preparing: return .info
        case .ready: return .success
        case .pickedUp: return Color.purple
        case .completed: return .textSecondary
        }
    }

    var badgeColor: Color {
        switch self {
        case .received: return .warning
        case .acknowledged: return Color.yellow
        case .preparing: return .info
        case .ready: return .success
        case .pickedUp: return Color.purple
        case .completed: return .textSecondary
        }
    }
}

// MARK: - Kitchen Order

struct KitchenOrder: Identifiable {
    let id: String
    let orderNumber: String
    let customerName: String
    let type: OrderType
    let items: [OrderItem]
    var status: KitchenOrderStatus
    let placedAt: Date
    let specialInstructions: String?
    let estimatedPrepTime: Int // minutes

    var minutesWaiting: Int {
        Int(Date().timeIntervalSince(placedAt) / 60)
    }

    var estimatedReadyTime: Date? {
        Calendar.current.date(byAdding: .minute, value: estimatedPrepTime, to: placedAt)
    }

    struct OrderItem {
        let name: String
        let quantity: Int
        let customizations: [String]
        let notes: String? // Per-item special instructions

        init(name: String, quantity: Int, customizations: [String], notes: String? = nil) {
            self.name = name
            self.quantity = quantity
            self.customizations = customizations
            self.notes = notes
        }
    }
}

// MARK: - Kitchen View Model

@MainActor
class KitchenViewModel: ObservableObject {
    @Published var orders: [KitchenOrder] = []
    @Published var draggedOrder: KitchenOrder?
    @Published var filterType: OrderType?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private var realtimeTask: Task<Void, Never>?
    private var refreshTimer: Timer?

    // Track order count for new order detection
    private var previousOrderCount: Int = 0
    private var knownOrderIds: Set<String> = []

    // Auto-refresh interval (30 seconds)
    private let autoRefreshInterval: TimeInterval = 30

    init() {
        loadOrders()
        startAutoRefresh()
    }

    nonisolated deinit {
        Task { @MainActor in
            stopAutoRefresh()
            stopRealtimeUpdates()
        }
    }

    func loadOrders(storeId: Int? = nil) {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                // Use Jay's Deli store ID by default
                let targetStoreId = storeId ?? SecureSupabaseConfig.storeId

                // Fetch orders from Supabase
                let supabaseOrders = try await SupabaseManager.shared.fetchOrders(storeId: targetStoreId)

                // Convert to KitchenOrder format
                let newOrders = supabaseOrders.map { order in
                    convertToKitchenOrder(order)
                }

                // Detect new orders (orders we haven't seen before)
                let newOrderIds = Set(newOrders.map { $0.id })
                let trulyNewOrders = newOrders.filter { !knownOrderIds.contains($0.id) }

                // Play sound for new orders (skip on initial load)
                if !knownOrderIds.isEmpty && !trulyNewOrders.isEmpty {
                    // Found new orders!
                    let newReceivedOrders = trulyNewOrders.filter { $0.status == .received }
                    if !newReceivedOrders.isEmpty {
                        print("🔔 New order(s) detected: \(newReceivedOrders.map { $0.orderNumber })")
                        SoundManager.shared.notifyNewOrder(orderNumber: newReceivedOrders.first?.orderNumber ?? "")
                    }
                }

                // Update known order IDs
                knownOrderIds = newOrderIds
                orders = newOrders

                print("✅ Kitchen loaded \(orders.count) orders from Supabase for store \(targetStoreId)")
            } catch {
                print("❌ Failed to load kitchen orders: \(error)")
                errorMessage = "Failed to load orders: \(error.localizedDescription)"

                // Fallback to mock data for testing
                print("⚠️ Using mock data as fallback")
                orders = MockKitchenData.generateOrders()
            }

            isLoading = false
        }
    }

    func refreshOrders(storeId: Int? = nil) {
        loadOrders(storeId: storeId)
    }

    func startRealtimeUpdates(storeId: Int? = nil) {
        // Cancel existing subscription if any
        realtimeTask?.cancel()

        // Use Jay's Deli store ID by default
        let targetStoreId = storeId ?? SecureSupabaseConfig.storeId

        // Subscribe to real-time order updates
        realtimeTask = SupabaseManager.shared.subscribeToOrders(storeId: targetStoreId) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("🔔 Kitchen real-time update triggered - refreshing orders")

                // Reload orders when new order comes in
                do {
                    let supabaseOrders = try await SupabaseManager.shared.fetchOrders(storeId: targetStoreId)
                    let newOrders = supabaseOrders.map { self.convertToKitchenOrder($0) }

                    // Detect truly new orders
                    let newOrderIds = Set(newOrders.map { $0.id })
                    let trulyNewOrders = newOrders.filter { !self.knownOrderIds.contains($0.id) }

                    // Play sound for new received orders
                    if !self.knownOrderIds.isEmpty && !trulyNewOrders.isEmpty {
                        let newReceivedOrders = trulyNewOrders.filter { $0.status == .received }
                        if !newReceivedOrders.isEmpty {
                            print("🔔 Real-time: New order(s) detected: \(newReceivedOrders.map { $0.orderNumber })")
                            SoundManager.shared.notifyNewOrder(orderNumber: newReceivedOrders.first?.orderNumber ?? "")
                        }
                    }

                    // Update state
                    self.knownOrderIds = newOrderIds
                    self.orders = newOrders
                } catch {
                    print("❌ Failed to refresh kitchen orders: \(error)")
                }
            }
        }

        print("✅ Kitchen real-time subscription started for store \(targetStoreId)")
    }

    func stopRealtimeUpdates() {
        realtimeTask?.cancel()
        realtimeTask = nil
        print("⏹️ Kitchen real-time subscription stopped")
    }

    // MARK: - Auto-Refresh

    func startAutoRefresh() {
        // Stop existing timer if any
        stopAutoRefresh()

        // Create new timer that fires every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("🔄 Auto-refreshing kitchen orders...")
                self.refreshOrders()
            }
        }

        print("✅ Auto-refresh started (every \(Int(autoRefreshInterval)) seconds)")
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("⏹️ Auto-refresh stopped")
    }

    func filteredOrders(for status: KitchenOrderStatus) -> [KitchenOrder] {
        var filtered = orders.filter { $0.status == status }

        if let filterType = filterType {
            filtered = filtered.filter { $0.type == filterType }
        }

        return filtered.sorted { $0.placedAt < $1.placedAt }
    }

    func updateOrderStatus(_ order: KitchenOrder, to newStatus: KitchenOrderStatus) {
        Task {
            do {
                // Map kitchen status back to order status
                let orderStatus = mapKitchenStatusToOrderStatus(newStatus)

                // Update status in Supabase
                try await SupabaseManager.shared.updateOrderStatus(
                    orderId: order.id,
                    status: orderStatus.rawValue
                )

                // Update local state
                if let index = orders.firstIndex(where: { $0.id == order.id }) {
                    withAnimation(.spring(response: 0.3)) {
                        orders[index].status = newStatus
                    }
                }

                // Play sound when order is ready
                if newStatus == .ready {
                    SoundManager.shared.playOrderReadySound()
                }

                print("✅ Updated order \(order.orderNumber) to \(newStatus.displayName)")
            } catch {
                print("❌ Failed to update order status: \(error)")
                errorMessage = "Failed to update order: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Helpers

    private func convertToKitchenOrder(_ order: Order) -> KitchenOrder {
        let items = order.items.map { cartItem in
            KitchenOrder.OrderItem(
                name: cartItem.menuItem.name,
                quantity: cartItem.quantity,
                customizations: cartItem.customizationSummary.components(separatedBy: "\n").filter { !$0.isEmpty },
                notes: cartItem.specialInstructions.isEmpty ? nil : cartItem.specialInstructions
            )
        }

        // Collect all item notes for order-level special instructions
        let allNotes = order.items
            .filter { !$0.specialInstructions.isEmpty }
            .map { "\($0.menuItem.name): \($0.specialInstructions)" }
            .joined(separator: " | ")
        let specialInstructions = allNotes.isEmpty ? nil : allNotes

        // Map OrderStatus to KitchenOrderStatus
        let kitchenStatus = mapOrderStatusToKitchenStatus(order.status)

        return KitchenOrder(
            id: order.id,
            orderNumber: order.orderNumber,
            customerName: order.customerName,
            type: order.orderType,
            items: items,
            status: kitchenStatus,
            placedAt: order.createdAt,
            specialInstructions: specialInstructions,
            estimatedPrepTime: 15 // Default, could be calculated from items
        )
    }

    private func mapOrderStatusToKitchenStatus(_ status: OrderStatus) -> KitchenOrderStatus {
        switch status {
        case .received: return .received
        case .preparing: return .preparing
        case .ready: return .ready
        case .completed: return .completed
        case .cancelled: return .completed
        }
    }

    private func mapKitchenStatusToOrderStatus(_ status: KitchenOrderStatus) -> OrderStatus {
        switch status {
        case .received, .acknowledged: return .received
        case .preparing: return .preparing
        case .ready, .pickedUp: return .ready
        case .completed: return .completed
        }
    }
}

// MARK: - Mock Kitchen Data

struct MockKitchenData {
    static func generateOrders() -> [KitchenOrder] {
        let now = Date()

        return [
            // Received Orders (New - just came in)
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-001",
                customerName: "John Smith",
                type: .dineIn,
                items: [
                    KitchenOrder.OrderItem(name: "Classic Cheeseburger", quantity: 2, customizations: ["No onions", "Extra cheese"]),
                    KitchenOrder.OrderItem(name: "French Fries", quantity: 2, customizations: ["Extra crispy"]),
                    KitchenOrder.OrderItem(name: "Coke", quantity: 2, customizations: [])
                ],
                status: .received,
                placedAt: now.addingTimeInterval(-5 * 60),
                specialInstructions: "Customer has nut allergy",
                estimatedPrepTime: 15
            ),
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-002",
                customerName: "Sarah Johnson",
                type: .pickup,
                items: [
                    KitchenOrder.OrderItem(name: "Crispy Calamari", quantity: 1, customizations: []),
                    KitchenOrder.OrderItem(name: "Caesar Salad", quantity: 1, customizations: ["Dressing on side"])
                ],
                status: .received,
                placedAt: now.addingTimeInterval(-3 * 60),
                specialInstructions: nil,
                estimatedPrepTime: 12
            ),
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-003",
                customerName: "Mike Davis",
                type: .delivery,
                items: [
                    KitchenOrder.OrderItem(name: "Pepperoni Pizza", quantity: 2, customizations: ["Extra cheese"]),
                    KitchenOrder.OrderItem(name: "Buffalo Wings", quantity: 1, customizations: ["Mild sauce"]),
                    KitchenOrder.OrderItem(name: "Garlic Bread", quantity: 1, customizations: [])
                ],
                status: .received,
                placedAt: now.addingTimeInterval(-25 * 60), // Urgent!
                specialInstructions: "Call on arrival: 555-0123",
                estimatedPrepTime: 20
            ),

            // Acknowledged Orders (Seen by kitchen, queued)
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-004",
                customerName: "Jennifer White",
                type: .pickup,
                items: [
                    KitchenOrder.OrderItem(name: "Veggie Burger", quantity: 1, customizations: ["Gluten-free bun"]),
                    KitchenOrder.OrderItem(name: "Side Salad", quantity: 1, customizations: [])
                ],
                status: .acknowledged,
                placedAt: now.addingTimeInterval(-7 * 60),
                specialInstructions: nil,
                estimatedPrepTime: 12
            ),

            // Preparing Orders (Being cooked)
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-005",
                customerName: "Emily Brown",
                type: .dineIn,
                items: [
                    KitchenOrder.OrderItem(name: "Grilled Chicken Sandwich", quantity: 1, customizations: []),
                    KitchenOrder.OrderItem(name: "Sweet Potato Fries", quantity: 1, customizations: [])
                ],
                status: .preparing,
                placedAt: now.addingTimeInterval(-10 * 60),
                specialInstructions: nil,
                estimatedPrepTime: 15
            ),
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-006",
                customerName: "David Wilson",
                type: .pickup,
                items: [
                    KitchenOrder.OrderItem(name: "Beef Tacos", quantity: 3, customizations: ["No cilantro"]),
                    KitchenOrder.OrderItem(name: "Nachos", quantity: 1, customizations: ["Extra jalapeños"])
                ],
                status: .preparing,
                placedAt: now.addingTimeInterval(-8 * 60),
                specialInstructions: nil,
                estimatedPrepTime: 12
            ),

            // Ready Orders (Cooked, waiting for pickup)
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-007",
                customerName: "Lisa Anderson",
                type: .dineIn,
                items: [
                    KitchenOrder.OrderItem(name: "Fish & Chips", quantity: 1, customizations: []),
                    KitchenOrder.OrderItem(name: "Coleslaw", quantity: 1, customizations: [])
                ],
                status: .ready,
                placedAt: now.addingTimeInterval(-20 * 60),
                specialInstructions: "Table 12",
                estimatedPrepTime: 18
            ),
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-008",
                customerName: "Tom Martinez",
                type: .delivery,
                items: [
                    KitchenOrder.OrderItem(name: "BBQ Ribs", quantity: 1, customizations: []),
                    KitchenOrder.OrderItem(name: "Mac & Cheese", quantity: 2, customizations: []),
                    KitchenOrder.OrderItem(name: "Cornbread", quantity: 2, customizations: [])
                ],
                status: .ready,
                placedAt: now.addingTimeInterval(-18 * 60),
                specialInstructions: "Leave at door",
                estimatedPrepTime: 25
            ),

            // Picked Up / Out for Delivery
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-009",
                customerName: "Amanda Taylor",
                type: .pickup,
                items: [
                    KitchenOrder.OrderItem(name: "Chicken Wrap", quantity: 2, customizations: []),
                    KitchenOrder.OrderItem(name: "Smoothie", quantity: 2, customizations: ["Strawberry"])
                ],
                status: .pickedUp,
                placedAt: now.addingTimeInterval(-25 * 60),
                specialInstructions: nil,
                estimatedPrepTime: 10
            ),
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-010",
                customerName: "Robert Garcia",
                type: .delivery,
                items: [
                    KitchenOrder.OrderItem(name: "Margherita Pizza", quantity: 1, customizations: []),
                    KitchenOrder.OrderItem(name: "Tiramisu", quantity: 1, customizations: [])
                ],
                status: .pickedUp,
                placedAt: now.addingTimeInterval(-22 * 60),
                specialInstructions: "Gate code: 1234",
                estimatedPrepTime: 18
            ),

            // Completed Orders
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-011",
                customerName: "Chris Lee",
                type: .dineIn,
                items: [
                    KitchenOrder.OrderItem(name: "Steak", quantity: 1, customizations: ["Medium rare"]),
                    KitchenOrder.OrderItem(name: "Mashed Potatoes", quantity: 1, customizations: []),
                    KitchenOrder.OrderItem(name: "Grilled Vegetables", quantity: 1, customizations: [])
                ],
                status: .completed,
                placedAt: now.addingTimeInterval(-35 * 60),
                specialInstructions: "VIP customer",
                estimatedPrepTime: 22
            ),
            KitchenOrder(
                id: UUID().uuidString,
                orderNumber: "ORD-012",
                customerName: "Patricia Moore",
                type: .delivery,
                items: [
                    KitchenOrder.OrderItem(name: "Sushi Platter", quantity: 1, customizations: []),
                    KitchenOrder.OrderItem(name: "Miso Soup", quantity: 2, customizations: [])
                ],
                status: .completed,
                placedAt: now.addingTimeInterval(-40 * 60),
                specialInstructions: nil,
                estimatedPrepTime: 20
            )
        ]
    }
}
