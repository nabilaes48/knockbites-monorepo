//
//  DashboardViewModel.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var selectedOrder: Order?
    @Published var showOrderDetail = false
    @Published var errorMessage: String?

    private var realtimeTask: Task<Void, Never>?
    private var refreshTimer: Timer?
    private var appBecameActiveObserver: NSObjectProtocol?

    // Track order IDs for new order detection
    private var knownOrderIds: Set<String> = []

    // Auto-refresh interval (30 seconds)
    private let autoRefreshInterval: TimeInterval = 30

    init() {
        startAutoRefresh()
        setupAppLifecycleObservers()
    }

    // MARK: - App Lifecycle

    private func setupAppLifecycleObservers() {
        appBecameActiveObserver = NotificationCenter.default.addObserver(
            forName: .appBecameActive,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("📱 App became active - refreshing orders")
                self.refresh()
            }
        }
    }

    nonisolated deinit {
        // Remove observer on deinit
        if let observer = appBecameActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        Task { @MainActor in
            stopAutoRefresh()
            stopRealtimeUpdates()
        }
    }

    var activeOrders: [Order] {
        orders.filter { $0.status != .completed && $0.status != .cancelled }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var completedOrders: [Order] {
        orders.filter { $0.status == .completed || $0.status == .cancelled }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var receivedOrders: [Order] {
        orders.filter { $0.status == .received }
    }

    var preparingOrders: [Order] {
        orders.filter { $0.status == .preparing }
    }

    var readyOrders: [Order] {
        orders.filter { $0.status == .ready }
    }

    func loadOrders(storeId: String? = nil) {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                // Use Jay's Deli store ID by default
                let targetStoreId = storeId.flatMap { Int($0) } ?? SecureSupabaseConfig.storeId

                // Fetch orders from Supabase
                let newOrders = try await SupabaseManager.shared.fetchOrders(storeId: targetStoreId)

                // Detect new orders
                let newOrderIds = Set(newOrders.map { $0.id })
                let trulyNewOrders = newOrders.filter { !knownOrderIds.contains($0.id) }

                // Play sound for new received orders (skip on initial load)
                if !knownOrderIds.isEmpty && !trulyNewOrders.isEmpty {
                    let newReceivedOrders = trulyNewOrders.filter { $0.status == .received }
                    if !newReceivedOrders.isEmpty {
                        print("🔔 Dashboard: New order(s) detected: \(newReceivedOrders.map { $0.orderNumber })")
                        SoundManager.shared.notifyNewOrder(orderNumber: newReceivedOrders.first?.orderNumber ?? "")
                    }
                }

                // Update state
                knownOrderIds = newOrderIds
                orders = newOrders

                print("✅ Loaded \(orders.count) orders from Supabase for store \(targetStoreId)")
            } catch {
                print("❌ Failed to load orders: \(error)")
                errorMessage = "Failed to load orders: \(error.localizedDescription)"

                // Fallback to mock data for testing
                print("⚠️ Using mock data as fallback")
                orders = MockDataService.shared.generateMockOrders(storeId: storeId ?? String(SecureSupabaseConfig.storeId))
            }

            isLoading = false
        }
    }

    func updateOrderStatus(_ order: Order, newStatus: OrderStatus) {
        Task {
            do {
                // Update status in Supabase
                try await SupabaseManager.shared.updateOrderStatus(
                    orderId: order.id,
                    status: newStatus.rawValue
                )

                // Update local state
                guard let index = orders.firstIndex(where: { $0.id == order.id }) else { return }

                var updatedOrder = order
                updatedOrder.status = newStatus

                if newStatus == .completed {
                    updatedOrder.completedAt = Date()
                }

                orders[index] = updatedOrder

                // Update selected order if it's the current one
                if selectedOrder?.id == order.id {
                    selectedOrder = updatedOrder
                }

                // Play sound when order is ready
                if newStatus == .ready {
                    SoundManager.shared.playOrderReadySound()
                }

                // Auto-print receipt based on settings
                let settings = ReceiptSettings.current

                if settings.autoPrintReceipts {
                    if newStatus == .preparing && settings.printOnStartPrep {
                        printReceipt(for: updatedOrder)
                    } else if newStatus == .ready && settings.printOnReady {
                        printReceipt(for: updatedOrder)
                    } else if newStatus == .completed && settings.printOnComplete {
                        printReceipt(for: updatedOrder)
                    }
                }

                print("✅ Order status updated to \(newStatus.rawValue)")
            } catch {
                print("❌ Failed to update order status: \(error)")
                errorMessage = "Failed to update order: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Receipt Printing

    private func printReceipt(for order: Order) {
        let settings = ReceiptSettings.current

        // Get store information from settings
        let store = Store(
            id: "1",
            name: settings.storeName,
            address: settings.storeAddress,
            phone: settings.storePhone,
            latitude: 40.7128,
            longitude: -74.0060,
            openTime: "09:00",
            closeTime: "21:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        )

        ReceiptService.printReceipt(order: order, store: store, settings: settings)
        print("🖨️ Receipt auto-printed for order \(order.orderNumber)")
    }

    // MARK: - Real-Time Subscription

    func startRealtimeUpdates(storeId: String? = nil) {
        // Cancel existing subscription if any
        realtimeTask?.cancel()

        // Use Jay's Deli store ID by default
        let targetStoreId = storeId.flatMap { Int($0) } ?? SecureSupabaseConfig.storeId

        // Subscribe to real-time order updates
        realtimeTask = SupabaseManager.shared.subscribeToOrders(storeId: targetStoreId) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("🔔 Real-time update triggered - refreshing orders")

                // Reload orders when new order comes in
                do {
                    let newOrders = try await SupabaseManager.shared.fetchOrders(storeId: targetStoreId)

                    // Detect new orders
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
                    print("❌ Failed to refresh orders: \(error)")
                }
            }
        }

        print("✅ Real-time subscription started for store \(targetStoreId)")
    }

    func stopRealtimeUpdates() {
        realtimeTask?.cancel()
        realtimeTask = nil
        print("⏹️ Real-time subscription stopped")
    }

    func selectOrder(_ order: Order) {
        selectedOrder = order
        showOrderDetail = true
    }

    func refresh(storeId: String? = nil) {
        loadOrders(storeId: storeId)
    }

    func refreshAsync(storeId: String? = nil) async {
        errorMessage = nil

        do {
            // Use Jay's Deli store ID by default
            let targetStoreId = storeId.flatMap { Int($0) } ?? SecureSupabaseConfig.storeId

            // Fetch orders from Supabase
            orders = try await SupabaseManager.shared.fetchOrders(storeId: targetStoreId)
            print("✅ Refreshed \(orders.count) orders from Supabase for store \(targetStoreId)")
        } catch {
            print("❌ Failed to refresh orders: \(error)")
            errorMessage = "Failed to refresh orders: \(error.localizedDescription)"
        }
    }

    // MARK: - Auto-Refresh

    func startAutoRefresh() {
        // Stop existing timer if any
        stopAutoRefresh()

        // Create new timer that fires every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("🔄 Auto-refreshing orders...")
                self.refresh()
            }
        }

        print("✅ Auto-refresh started (every \(Int(autoRefreshInterval)) seconds)")
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("⏹️ Auto-refresh stopped")
    }
}
