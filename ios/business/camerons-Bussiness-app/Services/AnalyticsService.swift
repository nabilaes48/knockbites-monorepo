//
//  AnalyticsService.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/19/25.
//

import Foundation
import Supabase

class AnalyticsService {
    static let shared = AnalyticsService()
    private let supabase = SupabaseManager.shared.client

    // MARK: - Postgres Functions

    /// Get store metrics with period comparison
    func getStoreMetrics(storeId: Int, dateRange: String = "today") async throws -> StoreMetrics {
        do {
            let queryString = "p_store_id=\(storeId)&p_date_range=\(dateRange)"
            let response = try await supabase.rpc("get_store_metrics", params: queryString).execute()

            let metrics = try JSONDecoder().decode([StoreMetrics].self, from: response.data)
            return metrics.first ?? StoreMetrics.empty
        } catch {
            print("⚠️ get_store_metrics failed (migration 024 may not be run): \(error)")
            return StoreMetrics.empty
        }
    }

    /// Get revenue chart data for different time periods
    func getRevenueChartData(storeId: Int, dateRange: String = "today") async throws -> [RevenueChartPoint] {
        do {
            let queryString = "p_store_id=\(storeId)&p_date_range=\(dateRange)"
            let response = try await supabase.rpc("get_revenue_chart_data", params: queryString).execute()

            return try JSONDecoder().decode([RevenueChartPoint].self, from: response.data)
        } catch {
            print("⚠️ get_revenue_chart_data failed (migration 024 may not be run): \(error)")
            return []
        }
    }

    // MARK: - Analytics Views

    /// Get daily stats for a store
    func getDailyStats(storeId: Int, days: Int = 30) async throws -> [DailyStat] {
        let response = try await supabase
            .from("analytics_daily_stats")
            .select()
            .eq("store_id", value: storeId)
            .order("date", ascending: false)
            .limit(days)
            .execute()

        return try JSONDecoder().decode([DailyStat].self, from: response.data)
    }

    /// Get hourly data for today
    func getHourlyData(storeId: Int) async throws -> [HourlyData] {
        let response = try await supabase
            .from("analytics_hourly_today")
            .select()
            .eq("store_id", value: storeId)
            .order("hour")
            .execute()

        return try JSONDecoder().decode([HourlyData].self, from: response.data)
    }

    /// Get time distribution (Breakfast, Lunch, Dinner, Late Night)
    func getTimeDistribution(storeId: Int) async throws -> [TimeDistribution] {
        let response = try await supabase
            .from("analytics_time_distribution")
            .select()
            .eq("store_id", value: storeId)
            .execute()

        return try JSONDecoder().decode([TimeDistribution].self, from: response.data)
    }

    /// Get category distribution
    func getCategoryDistribution(limit: Int = 10) async throws -> [CategoryDistItem] {
        let response = try await supabase
            .from("analytics_category_distribution")
            .select()
            .limit(limit)
            .execute()

        return try JSONDecoder().decode([CategoryDistItem].self, from: response.data)
    }

    /// Get popular items for a store
    func getPopularItems(storeId: Int, limit: Int = 10) async throws -> [PopularItemResponse] {
        let response = try await supabase
            .from("analytics_popular_items")
            .select()
            .eq("store_id", value: storeId)
            .limit(limit)
            .execute()

        return try JSONDecoder().decode([PopularItemResponse].self, from: response.data)
    }

    // MARK: - Additional Queries

    /// Get order frequency distribution (customer retention)
    func getOrderFrequency(storeId: Int) async throws -> [OrderFrequencyItem] {
        // This function doesn't exist in migration 024 - would need separate implementation
        // For now, calculate frequency from orders directly
        let response = try await supabase
            .from("orders")
            .select("user_id")
            .eq("store_id", value: storeId)
            .execute()

        let orders = try JSONDecoder().decode([UserOrder].self, from: response.data)

        // Count orders per user
        var userCounts: [String: Int] = [:]
        for order in orders {
            userCounts[order.userId ?? "guest", default: 0] += 1
        }

        // Categorize by frequency
        var frequencies: [String: Int] = [
            "First Time": 0,
            "2-5 Orders": 0,
            "6-10 Orders": 0,
            "11+ Orders": 0
        ]

        for count in userCounts.values {
            if count == 1 {
                frequencies["First Time"]! += 1
            } else if count >= 2 && count <= 5 {
                frequencies["2-5 Orders"]! += 1
            } else if count >= 6 && count <= 10 {
                frequencies["6-10 Orders"]! += 1
            } else {
                frequencies["11+ Orders"]! += 1
            }
        }

        return frequencies.map { range, count in
            OrderFrequencyItem(frequencyRange: range, customerCount: count)
        }.sorted { $0.customerCount > $1.customerCount }
    }

    /// Get payment method distribution
    func getPaymentMethods(storeId: Int) async throws -> [PaymentMethodItem] {
        let response = try await supabase
            .from("orders")
            .select("payment_method")
            .eq("store_id", value: storeId)
            .execute()

        let orders = try JSONDecoder().decode([OrderPayment].self, from: response.data)

        // Aggregate payment methods
        var methodCounts: [String: Int] = [:]
        for order in orders {
            methodCounts[order.paymentMethod ?? "Unknown", default: 0] += 1
        }

        let total = orders.count
        return methodCounts.map { method, count in
            PaymentMethodItem(
                method: method,
                count: count,
                percentage: total > 0 ? Double(count) / Double(total) : 0
            )
        }.sorted { $0.count > $1.count }
    }

    /// Get average fulfillment time
    func getAverageFulfillmentTime(storeId: Int) async throws -> Double {
        let response = try await supabase
            .from("orders")
            .select("created_at, completed_at")
            .eq("store_id", value: storeId)
            .not("completed_at", operator: .is, value: "null")
            .execute()

        let orders = try JSONDecoder().decode([OrderTiming].self, from: response.data)

        let formatter = ISO8601DateFormatter()
        var totalMinutes = 0.0
        var count = 0

        for order in orders {
            if let created = formatter.date(from: order.createdAt),
               let completed = formatter.date(from: order.completedAt) {
                let minutes = completed.timeIntervalSince(created) / 60
                totalMinutes += minutes
                count += 1
            }
        }

        return count > 0 ? totalMinutes / Double(count) : 0
    }

    /// Get multi-store comparison
    func getMultiStoreMetrics(dateRange: String = "today") async throws -> [StoreComparison] {
        var stores: [StoreComparison] = []

        // Get metrics for each store (1-29 based on your setup)
        for storeId in 1...3 { // Start with first 3 stores
            do {
                let metrics = try await getStoreMetrics(storeId: storeId, dateRange: dateRange)
                let fulfillmentTime = try await getAverageFulfillmentTime(storeId: storeId)

                // Get store name
                let storeResponse = try await supabase
                    .from("stores")
                    .select("name")
                    .eq("id", value: storeId)
                    .single()
                    .execute()

                let storeData = try JSONDecoder().decode(StoreNameResponse.self, from: storeResponse.data)

                stores.append(StoreComparison(
                    storeName: storeData.name,
                    orders: metrics.totalOrders,
                    revenue: Double(metrics.totalRevenue.description) ?? 0,
                    rating: 0, // Not available yet
                    avgFulfillment: fulfillmentTime
                ))
            } catch {
                print("⚠️ Could not fetch metrics for store \(storeId): \(error)")
            }
        }

        return stores.sorted { $0.revenue > $1.revenue }
    }
}

// MARK: - Response Models

struct StoreMetrics: Codable {
    let totalRevenue: Decimal
    let totalOrders: Int
    let avgOrderValue: Decimal
    let uniqueCustomers: Int
    let revenueChange: Decimal?
    let ordersChange: Int?

    enum CodingKeys: String, CodingKey {
        case totalRevenue = "total_revenue"
        case totalOrders = "total_orders"
        case avgOrderValue = "avg_order_value"
        case uniqueCustomers = "unique_customers"
        case revenueChange = "revenue_change"
        case ordersChange = "orders_change"
    }

    static let empty = StoreMetrics(
        totalRevenue: 0,
        totalOrders: 0,
        avgOrderValue: 0,
        uniqueCustomers: 0,
        revenueChange: 0,
        ordersChange: 0
    )
}

struct RevenueChartPoint: Codable {
    let timeLabel: String
    let revenue: Decimal
    let orders: Int

    enum CodingKeys: String, CodingKey {
        case timeLabel = "time_label"
        case revenue
        case orders
    }
}

struct DailyStat: Codable {
    let date: String
    let totalOrders: Int
    let totalRevenue: Decimal
    let totalTax: Decimal
    let avgOrderValue: Decimal
    let uniqueCustomers: Int

    enum CodingKeys: String, CodingKey {
        case date
        case totalOrders = "total_orders"
        case totalRevenue = "total_revenue"
        case totalTax = "total_tax"
        case avgOrderValue = "avg_order_value"
        case uniqueCustomers = "unique_customers"
    }
}

struct HourlyData: Codable {
    let hour: Int
    let orders: Int
    let revenue: Decimal
}

struct TimeDistribution: Codable {
    let timePeriod: String
    let orderCount: Int
    let revenue: Decimal

    enum CodingKeys: String, CodingKey {
        case timePeriod = "time_period"
        case orderCount = "order_count"
        case revenue
    }
}

struct CategoryDistItem: Codable {
    let category: String
    let subcategory: String?
    let orderCount: Int
    let itemsSold: Int
    let totalRevenue: Decimal

    enum CodingKeys: String, CodingKey {
        case category
        case subcategory
        case orderCount = "order_count"
        case itemsSold = "items_sold"
        case totalRevenue = "total_revenue"
    }
}

struct PopularItemResponse: Codable {
    let menuItemId: Int
    let itemName: String
    let timesOrdered: Int
    let totalQuantity: Int
    let totalRevenue: Decimal
    let avgPrice: Decimal

    enum CodingKeys: String, CodingKey {
        case menuItemId = "menu_item_id"
        case itemName = "item_name"
        case timesOrdered = "times_ordered"
        case totalQuantity = "total_quantity"
        case totalRevenue = "total_revenue"
        case avgPrice = "avg_price"
    }
}

struct OrderFrequencyItem: Codable {
    let frequencyRange: String
    let customerCount: Int

    enum CodingKeys: String, CodingKey {
        case frequencyRange = "frequency_range"
        case customerCount = "customer_count"
    }
}

struct PaymentMethodItem: Codable {
    let method: String
    let count: Int
    let percentage: Double
}

struct OrderPayment: Codable {
    let paymentMethod: String?

    enum CodingKeys: String, CodingKey {
        case paymentMethod = "payment_method"
    }
}

struct UserOrder: Codable {
    let userId: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

struct OrderTiming: Codable {
    let createdAt: String
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }
}

struct StoreComparison: Codable {
    let storeName: String
    let orders: Int
    let revenue: Double
    let rating: Double
    let avgFulfillment: Double
}

struct StoreNameResponse: Codable {
    let name: String
}
