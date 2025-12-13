//
//  OrderViewModel.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import Combine

@MainActor
class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var currentTrackingOrder: Order?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let realtimeManager = RealtimeManager.shared

    init() {
        // Listen for real-time order status changes using central notification name
        NotificationCenter.default.publisher(for: .orderStatusChanged)
            .sink { [weak self] notification in
                self?.handleRealtimeOrderUpdate(notification)
            }
            .store(in: &cancellables)

        print("✅ OrderViewModel initialized with realtime listener")
    }

    // MARK: - Submit New Order
    func submitOrder(
        items: [CartItem],
        storeId: String,
        orderType: OrderType,
        subtotal: Double,
        tax: Double,
        total: Double,
        customerName: String? = nil,
        customerPhone: String? = nil
    ) async throws -> (orderId: String, orderNumber: String) {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await SupabaseManager.shared.submitOrder(
                items: items,
                storeId: storeId,
                orderType: orderType,
                subtotal: subtotal,
                tax: tax,
                total: total,
                customerName: customerName,
                customerPhone: customerPhone
            )

            isLoading = false
            return result
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Load Orders (Primary method)
    func loadOrders() async {
        do {
            let fetched = try await SupabaseManager.shared.fetchUserOrders()
            DispatchQueue.main.async {
                self.orders = fetched
            }
        } catch {
            print("ORDER LOAD ERROR:", error)
        }
    }

    // MARK: - Fetch Order History (calls loadOrders)
    func fetchOrderHistory() async {
        isLoading = true
        errorMessage = nil

        do {
            print("📥 Fetching order history from Supabase...")

            // Fetch orders from Supabase database
            let fetchedOrders = try await SupabaseManager.shared.fetchUserOrders()

            // TODO: Assign order.store = storeViewModel.store(for: order.storeId)
            // This requires injecting StoreViewModel into OrderViewModel

            // Update orders array (already sorted by created_at DESC from database)
            orders = fetchedOrders

            print("✅ Loaded \(orders.count) orders from database")

            // Also cache in UserDefaults as backup
            if let encoded = try? JSONEncoder().encode(orders) {
                UserDefaults.standard.set(encoded, forKey: "orderHistory")
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription

            print("⚠️ Failed to fetch orders from Supabase: \(error.localizedDescription)")
            print("   Falling back to cached orders from UserDefaults")

            // Fallback: Load from UserDefaults cache if network fails
            if let data = UserDefaults.standard.data(forKey: "orderHistory"),
               let cachedOrders = try? JSONDecoder().decode([Order].self, from: data) {
                orders = cachedOrders.sorted { $0.createdAt > $1.createdAt }
                print("   ✅ Loaded \(orders.count) cached orders")
            } else {
                // Show error toast only if cache is also empty
                ToastManager.shared.show(
                    "Failed to load orders",
                    icon: "wifi.slash",
                    type: .error
                )
            }
        }
    }

    // MARK: - Save Order to History
    func saveOrder(_ order: Order) {
        // Add to beginning of array
        orders.insert(order, at: 0)

        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(orders) {
            UserDefaults.standard.set(encoded, forKey: "orderHistory")
        }
    }

    // MARK: - Get Order by ID
    func getOrder(byId id: String) -> Order? {
        orders.first { $0.id == id }
    }

    // MARK: - Start Tracking Order
    func startTracking(order: Order) {
        currentTrackingOrder = order

        print("📍 Starting to track order #\(order.orderNumber) (ID: \(order.id))")

        // Subscribe to real-time updates for this order
        realtimeManager.subscribeToOrder(orderId: order.id)

        ToastManager.shared.show(
            "Tracking order #\(order.orderNumber)",
            icon: "wifi",
            type: .success
        )
    }

    // MARK: - Stop Tracking
    func stopTracking() {
        guard let order = currentTrackingOrder else { return }

        print("🛑 Stopping tracking for order #\(order.orderNumber)")

        // Unsubscribe from real-time updates
        realtimeManager.unsubscribeFromOrder(orderId: order.id)

        currentTrackingOrder = nil
    }

    // MARK: - Reorder
    func reorder(_ order: Order) -> [CartItem] {
        // Return the cart items from the order so they can be added to cart
        return order.items
    }

    // MARK: - Cancel Order
    func canCancelOrder(_ order: Order) -> Bool {
        // Can only cancel orders that are not completed or already cancelled
        guard order.status != .completed && order.status != .cancelled else {
            return false
        }

        // Check if order is within 5-minute cancellation window
        let timeSinceOrder = Date().timeIntervalSince(order.createdAt)
        let cancellationWindow: TimeInterval = 5 * 60 // 5 minutes

        return timeSinceOrder <= cancellationWindow
    }

    func remainingCancellationTime(_ order: Order) -> TimeInterval? {
        guard canCancelOrder(order) else { return nil }

        let timeSinceOrder = Date().timeIntervalSince(order.createdAt)
        let cancellationWindow: TimeInterval = 5 * 60
        return max(0, cancellationWindow - timeSinceOrder)
    }

    func cancelOrder(_ order: Order) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        // Simulate potential network error (5% chance)
        if Bool.random() && Bool.random() && Bool.random() && Bool.random() {
            throw NSError(
                domain: "NetworkError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to cancel order. Please try again."]
            )
        }

        // Update order status to cancelled
        var cancelledOrder = order.withStatus(.cancelled)

        // Update in order list
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index] = cancelledOrder
            saveOrderHistory()
        }

        // Stop tracking if this was the current tracking order
        if currentTrackingOrder?.id == order.id {
            currentTrackingOrder = nil
            stopTracking()
        }

        ToastManager.shared.show(
            "Order cancelled successfully",
            icon: "checkmark.circle.fill",
            type: .success
        )
    }

    // MARK: - Update Order Status
    func updateStatus(orderId: String, status: String) {
        guard let index = orders.firstIndex(where: { $0.id == orderId }) else { return }
        orders[index].status = OrderStatus(rawValue: status)
    }

    // MARK: - Real-Time Update Handler
    private func handleRealtimeOrderUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let orderId = userInfo["orderId"] as? String else {
            print("⚠️ Invalid realtime update payload - missing orderId")
            return
        }

        // Extract optional fields from notification
        let statusString = userInfo["status"] as? String
        let estimatedReadyAtString = userInfo["estimatedReadyAt"] as? String
        let updatedAtString = userInfo["updatedAt"] as? String

        print("📨 Processing realtime update for order #\(orderId)")
        if let status = statusString { print("   Status: \(status)") }
        if let time = estimatedReadyAtString { print("   EstimatedReadyAt: \(time)") }

        // Apply the realtime update
        applyRealtimeUpdate(
            orderId: orderId,
            status: statusString,
            estimatedReadyAt: estimatedReadyAtString,
            updatedAt: updatedAtString
        )
    }

    // MARK: - Apply Realtime Update
    /// Central method for applying realtime updates to orders
    private func applyRealtimeUpdate(
        orderId: String,
        status: String?,
        estimatedReadyAt: String?,
        updatedAt: String?
    ) {
        // Parse status if provided
        let newStatus: OrderStatus? = status.map { OrderStatus(rawValue: $0) }

        // Parse estimatedReadyAt date if provided
        let newEstimatedReadyTime: Date? = estimatedReadyAt.flatMap { dateString in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        }

        // Update in orders list
        if let index = orders.firstIndex(where: { $0.id == orderId }) {
            if let status = newStatus {
                orders[index].status = status
            }
            if let time = newEstimatedReadyTime {
                orders[index].estimatedReadyTime = time
            }
            print("   ✅ Updated order in history list")
        }

        // Update current tracking order if this is it
        if var currentOrder = currentTrackingOrder, currentOrder.id == orderId {
            if let status = newStatus {
                currentOrder.status = status
                print("   ✅ Updated currentTrackingOrder status to \(status.rawValue)")

                // Show toast notification for status change
                ToastManager.shared.show(
                    "Order \(status.rawValue.lowercased())",
                    icon: status.icon,
                    type: .success
                )

                // Auto-stop tracking if order is completed or cancelled
                if status == .completed || status == .cancelled {
                    print("   🏁 Order finished, will stop tracking")
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000) // Wait 3 seconds
                        await MainActor.run {
                            self.stopTracking()
                        }
                    }
                }
            }
            if let time = newEstimatedReadyTime {
                currentOrder.estimatedReadyTime = time
                print("   ✅ Updated estimatedReadyTime")
            }
            currentTrackingOrder = currentOrder
        }

        saveOrderHistory()
    }

    private func saveOrderHistory() {
        if let encoded = try? JSONEncoder().encode(orders) {
            UserDefaults.standard.set(encoded, forKey: "orderHistory")
        }
    }

    // MARK: - Clear History (for testing)
    func clearHistory() {
        orders.removeAll()
        UserDefaults.standard.removeObject(forKey: "orderHistory")
    }
}

// MARK: - Order Extension for Mutable Updates
extension Order {
    func withStatus(_ newStatus: OrderStatus) -> Order {
        var order = Order(
            id: id,
            userId: userId,
            storeId: storeId,
            items: items,
            subtotal: subtotal,
            tax: tax,
            total: total,
            status: newStatus,
            orderType: orderType,
            createdAt: createdAt,
            estimatedReadyTime: estimatedReadyTime,
            orderNumber: orderNumber,
            scheduledFor: scheduledFor
        )
        order.store = store
        return order
    }

    func withStore(_ store: Store?) -> Order {
        var order = self
        order.store = store
        return order
    }
}
