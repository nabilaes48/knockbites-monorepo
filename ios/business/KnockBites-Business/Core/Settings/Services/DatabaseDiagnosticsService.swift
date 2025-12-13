//
//  DatabaseDiagnosticsService.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 4 cleanup - encapsulates database diagnostic operations
//

import Foundation
import Supabase

/// Service for database diagnostic operations
/// Replaces direct Supabase client usage in DatabaseDiagnosticsViewModel
class DatabaseDiagnosticsService {
    static let shared = DatabaseDiagnosticsService()

    private let supabase = SupabaseManager.shared

    private init() {}

    // MARK: - Connection Testing

    struct ConnectionTestResult {
        let isConnected: Bool
        let storeCount: Int
        let errorMessage: String?
    }

    /// Test connection to Supabase by querying stores table
    func testConnection() async -> ConnectionTestResult {
        do {
            struct DBStore: Codable {
                let id: Int
                let name: String
            }

            let stores: [DBStore] = try await supabase.client
                .from(TableNames.stores)
                .select()
                .limit(5)
                .execute()
                .value

            return ConnectionTestResult(
                isConnected: true,
                storeCount: stores.count,
                errorMessage: nil
            )
        } catch {
            return ConnectionTestResult(
                isConnected: false,
                storeCount: 0,
                errorMessage: "Connection failed: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Order Diagnostics

    struct OrderDiagnostics {
        let totalOrders: Int
        let pendingOrders: Int
        let completedOrders: Int
        let recentOrders: [Order]
        let errorMessage: String?
    }

    /// Fetch order diagnostics for a specific store
    func fetchOrderDiagnostics(storeId: Int) async -> OrderDiagnostics {
        do {
            let orders = try await supabase.fetchOrders(storeId: storeId)

            let recentOrders = Array(orders.prefix(10))
            let totalOrders = orders.count
            let pendingOrders = orders.filter { $0.status != .completed && $0.status != .cancelled }.count
            let completedOrders = orders.filter { $0.status == .completed }.count

            var errorMessage: String? = nil
            if orders.isEmpty {
                errorMessage = "No orders found for store_id = \(storeId). Try 'Check ALL Store Orders' to see if orders exist with different store IDs."
            }

            return OrderDiagnostics(
                totalOrders: totalOrders,
                pendingOrders: pendingOrders,
                completedOrders: completedOrders,
                recentOrders: recentOrders,
                errorMessage: errorMessage
            )
        } catch {
            return OrderDiagnostics(
                totalOrders: 0,
                pendingOrders: 0,
                completedOrders: 0,
                recentOrders: [],
                errorMessage: "Failed to fetch orders: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - All Store Orders

    struct AllStoreOrdersResult {
        let totalOrders: Int
        let storeBreakdown: [(storeId: Int, orderCount: Int)]
        let message: String
    }

    /// Fetch orders across all stores for diagnostic purposes
    func fetchAllStoreOrders(currentStoreId: Int) async -> AllStoreOrdersResult {
        do {
            struct OrderResponse: Codable {
                let id: String
                let orderNumber: String
                let userId: String
                let customerName: String
                let storeId: Int
                let total: Double
                let status: String
                let createdAt: String

                enum CodingKeys: String, CodingKey {
                    case id
                    case orderNumber = "order_number"
                    case userId = "user_id"
                    case customerName = "customer_name"
                    case storeId = "store_id"
                    case total
                    case status
                    case createdAt = "created_at"
                }
            }

            let response: [OrderResponse] = try await supabase.client
                .from(TableNames.orders)
                .select("id, order_number, user_id, customer_name, store_id, total, status, created_at")
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value

            // Group by store_id
            let storeGroups = Dictionary(grouping: response, by: { $0.storeId })

            var breakdown: [(storeId: Int, orderCount: Int)] = storeGroups.map { (storeId: $0.key, orderCount: $0.value.count) }
            breakdown.sort { $0.storeId < $1.storeId }

            var message = "Found \(response.count) total orders:\n"
            for item in breakdown {
                message += "  Store ID \(item.storeId): \(item.orderCount) orders\n"
            }

            message += "\nYour app is configured for Store ID: \(currentStoreId)"

            if let storeOrders = storeGroups[currentStoreId] {
                message += "\n\nFound \(storeOrders.count) orders for your store!"
            } else {
                message += "\n\n⚠️ NO ORDERS found for Store ID \(currentStoreId)"
                message += "\nOrders exist for other store IDs. Check your customer app's store configuration."
            }

            return AllStoreOrdersResult(
                totalOrders: response.count,
                storeBreakdown: breakdown,
                message: message
            )
        } catch {
            return AllStoreOrdersResult(
                totalOrders: 0,
                storeBreakdown: [],
                message: "Failed to fetch all orders: \(error.localizedDescription)"
            )
        }
    }
}
