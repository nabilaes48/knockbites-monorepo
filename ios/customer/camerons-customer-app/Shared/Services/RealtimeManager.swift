//
//  RealtimeManager.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/19/25.
//

import Foundation
import Combine
import Supabase

/// Manages real-time subscriptions for live data updates from Supabase (Realtime V2)
@MainActor
class RealtimeManager: ObservableObject {
    static let shared = RealtimeManager()

    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: String?

    private let supabase = SupabaseManager.shared.client
    private var activeChannels: [String: RealtimeChannelV2] = [:]
    private var subscriptionTasks: [String: Task<Void, Never>] = [:]
    private var activeOrderSubscriptions: [String: Any] = [:]  // key: orderId

    // MARK: - Type-safe Realtime Payload
    private struct RealtimeOrderUpdate {
        let id: String
        let status: String?
        let estimatedReadyAt: String?
        let updatedAt: String?
    }

    enum ConnectionState {
        case connected
        case connecting
        case disconnected
        case error(String)

        var displayText: String {
            switch self {
            case .connected: return "Connected"
            case .connecting: return "Connecting..."
            case .disconnected: return "Disconnected"
            case .error(let message): return "Error: \(message)"
            }
        }

        var isConnected: Bool {
            if case .connected = self { return true }
            return false
        }
    }

    private init() {
        print("🔌 RealtimeManager initialized (Realtime V2)")
    }

    // MARK: - Order Subscriptions

    /// Subscribe to real-time updates for a specific order
    /// - Parameter orderId: The order ID to track
    func subscribeToOrder(orderId: String) {
        print("📡 Subscribing to order #\(orderId) updates...")

        // Don't create duplicate subscriptions
        if activeChannels[orderId] != nil {
            print("⚠️ Already subscribed to order #\(orderId)")
            return
        }

        connectionState = .connecting

        // Create subscription task
        let task = Task {
            // Create channel with unique name
            let channelName = "order-\(orderId)"
            let channel = await supabase.realtimeV2.channel(channelName)

            // Store channel
            await MainActor.run {
                activeChannels[orderId] = channel
            }

            // Set up the change listener BEFORE subscribing
            let updates = channel.postgresChange(UpdateAction.self, table: "orders")

            // Subscribe to the channel
            do {
                try await channel.subscribeWithError()
                print("✅ Channel subscribed for order #\(orderId)")

                await MainActor.run {
                    connectionState = .connected
                }
            } catch {
                await MainActor.run {
                    connectionState = .error(error.localizedDescription)
                    lastError = error.localizedDescription
                    print("❌ Subscription failed: \(error.localizedDescription)")
                }
                return
            }

            // Listen for UPDATE events on the orders table
            for await update in updates {
                // Check if this update is for our specific order
                if let id = update.record["id"]?.stringValue, id == orderId {
                    await handleOrderUpdate(update: update, orderId: orderId)
                }
            }
        }

        subscriptionTasks[orderId] = task
    }

    /// Unsubscribe from order updates
    /// - Parameter orderId: The order ID to stop tracking
    func unsubscribeFromOrder(orderId: String) {
        guard let channel = activeChannels[orderId] else {
            print("⚠️ No active subscription for order #\(orderId)")
            return
        }

        print("🔌 Unsubscribing from order #\(orderId)")

        // Cancel the subscription task
        subscriptionTasks[orderId]?.cancel()
        subscriptionTasks.removeValue(forKey: orderId)

        Task {
            await channel.unsubscribe()
            await supabase.realtimeV2.removeChannel(channel)

            await MainActor.run {
                activeChannels.removeValue(forKey: orderId)

                // Update connection state if no more active channels
                if activeChannels.isEmpty {
                    connectionState = .disconnected
                }

                print("✅ Unsubscribed from order #\(orderId)")
            }
        }
    }

    /// Unsubscribe from all active channels
    func unsubscribeAll() {
        print("🔌 Unsubscribing from all channels (\(activeChannels.count) active)")

        let orderIds = Array(activeChannels.keys)
        for orderId in orderIds {
            unsubscribeFromOrder(orderId: orderId)
        }
    }

    // MARK: - Handle Updates

    private func handleOrderUpdate(update: UpdateAction, orderId: String) async {
        await MainActor.run {
            print("📨 Received update for order #\(orderId)")

            // Extract raw data from update
            let record = update.record
            print("   New data keys: \(record.keys)")

            // Build type-safe update payload
            let realtimeUpdate = RealtimeOrderUpdate(
                id: orderId,
                status: record["status"]?.stringValue,
                estimatedReadyAt: record["estimated_ready_at"]?.stringValue,
                updatedAt: record["updated_at"]?.stringValue
            )

            if let status = realtimeUpdate.status {
                print("   ✨ Status changed to: \(status)")
            }

            // Post notification using central name for OrderViewModel to handle
            NotificationCenter.default.post(
                name: .orderStatusChanged,
                object: nil,
                userInfo: [
                    "orderId": realtimeUpdate.id,
                    "status": realtimeUpdate.status as Any,
                    "estimatedReadyAt": realtimeUpdate.estimatedReadyAt as Any,
                    "updatedAt": realtimeUpdate.updatedAt as Any
                ]
            )
        }
    }

    // MARK: - Multiple Order Subscriptions

    /// Subscribe to multiple orders at once (for order history view)
    /// - Parameter orderIds: Array of order IDs to track
    func subscribeToOrders(_ orderIds: [String]) {
        print("📡 Subscribing to \(orderIds.count) orders")

        for orderId in orderIds {
            _ = subscribeToOrder(orderId: orderId)
        }
    }

    // MARK: - Connection Health

    /// Check if we have any active subscriptions
    var hasActiveSubscriptions: Bool {
        return !activeChannels.isEmpty
    }

    /// Get count of active subscriptions
    var activeSubscriptionCount: Int {
        return activeChannels.count
    }

    /// Get list of subscribed order IDs
    var subscribedOrderIds: [String] {
        return Array(activeChannels.keys)
    }
}
