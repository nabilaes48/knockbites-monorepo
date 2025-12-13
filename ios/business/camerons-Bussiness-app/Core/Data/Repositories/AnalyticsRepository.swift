//
//  AnalyticsRepository.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 5 cleanup - consolidated analytics data access
//

import Foundation
import Supabase

/// Repository for all analytics-related data operations
class AnalyticsRepository {
    static let shared = AnalyticsRepository()

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Response Types

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

    // MARK: - Analytics Summary

    func fetchAnalyticsSummary(storeId: Int, startDate: Date, endDate: Date) async throws -> AnalyticsSummary {
        print("🔄 Fetching analytics summary from \(startDate) to \(endDate)...")

        struct OrderSummary: Codable {
            let id: Int
            let total: Double
            let createdAt: String
            let customerId: Int?

            enum CodingKeys: String, CodingKey {
                case id, total
                case createdAt = "created_at"
                case customerId = "customer_id"
            }
        }

        // Fetch orders for current period
        let currentOrders: [OrderSummary] = try await client
            .from(TableNames.orders)
            .select("id, total, created_at, customer_id")
            .eq("store_id", value: storeId)
            .gte("created_at", value: DateFormatting.toISO8601(startDate))
            .lte("created_at", value: DateFormatting.toISO8601(endDate))
            .neq("status", value: "cancelled")
            .execute()
            .value

        // Calculate previous period dates
        let duration = endDate.timeIntervalSince(startDate)
        let prevEndDate = startDate
        let prevStartDate = startDate.addingTimeInterval(-duration)

        // Fetch orders for previous period
        let previousOrders: [OrderSummary] = try await client
            .from(TableNames.orders)
            .select("id, total, created_at, customer_id")
            .eq("store_id", value: storeId)
            .gte("created_at", value: DateFormatting.toISO8601(prevStartDate))
            .lte("created_at", value: DateFormatting.toISO8601(prevEndDate))
            .neq("status", value: "cancelled")
            .execute()
            .value

        // Calculate metrics
        let revenue = currentOrders.reduce(0.0) { $0 + $1.total }
        let ordersCount = currentOrders.count
        let uniqueCustomers = Set(currentOrders.compactMap { $0.customerId }).count

        let previousRevenue = previousOrders.reduce(0.0) { $0 + $1.total }
        let previousOrdersCount = previousOrders.count
        let previousCustomersCount = Set(previousOrders.compactMap { $0.customerId }).count

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

    // MARK: - Daily Sales

    func fetchDailySales(storeId: Int, days: Int) async throws -> [DailySales] {
        print("🔄 Fetching daily sales for last \(days) days...")

        struct OrderSummary: Codable {
            let total: Double
            let createdAt: String

            enum CodingKeys: String, CodingKey {
                case total
                case createdAt = "created_at"
            }
        }

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date()).addingTimeInterval(86400)
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!

        let orders: [OrderSummary] = try await client
            .from(TableNames.orders)
            .select("total, created_at")
            .eq("store_id", value: storeId)
            .gte("created_at", value: DateFormatting.toISO8601(startDate))
            .lte("created_at", value: DateFormatting.toISO8601(endDate))
            .neq("status", value: "cancelled")
            .execute()
            .value

        // Group orders by day
        var salesByDay: [Date: (revenue: Double, count: Int)] = [:]

        for order in orders {
            if let orderDate = DateFormatting.parseISO8601(order.createdAt) {
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

    // MARK: - Top Selling Items

    func fetchTopSellingItems(storeId: Int, startDate: Date, endDate: Date, limit: Int = 10) async throws -> [TopSellingItem] {
        print("🔄 Fetching top selling items...")

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
            .from(TableNames.orders)
            .select("id, items")
            .eq("store_id", value: storeId)
            .gte("created_at", value: DateFormatting.toISO8601(startDate))
            .lte("created_at", value: DateFormatting.toISO8601(endDate))
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

    // MARK: - Order Type Distribution

    func fetchOrderTypeDistribution(storeId: Int, startDate: Date, endDate: Date) async throws -> [String: Int] {
        print("🔄 Fetching order type distribution...")

        struct OrderType: Codable {
            let type: String
        }

        let orders: [OrderType] = try await client
            .from(TableNames.orders)
            .select("type")
            .eq("store_id", value: storeId)
            .gte("created_at", value: DateFormatting.toISO8601(startDate))
            .lte("created_at", value: DateFormatting.toISO8601(endDate))
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
}
