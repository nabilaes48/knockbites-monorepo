//
//  Analytics.swift
//  KnockBites Connect — Shared Models
//
//  Canonical analytics models shared across Business iOS, Customer iOS, and Website.
//  These models map to PostgreSQL views created by migration 024.
//

import Foundation

// MARK: - Shared Analytics Summary

/// Analytics summary response from `get_store_metrics` RPC.
public struct SharedAnalyticsSummary: Codable {
    public let totalRevenue: Double
    public let totalOrders: Int
    public let avgOrderValue: Double
    public let uniqueCustomers: Int
    public let revenueChange: Double?
    public let ordersChange: Int?

    enum CodingKeys: String, CodingKey {
        case totalRevenue = "total_revenue"
        case totalOrders = "total_orders"
        case avgOrderValue = "avg_order_value"
        case uniqueCustomers = "unique_customers"
        case revenueChange = "revenue_change"
        case ordersChange = "orders_change"
    }

    public init(
        totalRevenue: Double,
        totalOrders: Int,
        avgOrderValue: Double,
        uniqueCustomers: Int,
        revenueChange: Double?,
        ordersChange: Int?
    ) {
        self.totalRevenue = totalRevenue
        self.totalOrders = totalOrders
        self.avgOrderValue = avgOrderValue
        self.uniqueCustomers = uniqueCustomers
        self.revenueChange = revenueChange
        self.ordersChange = ordersChange
    }
}

// MARK: - Shared Daily Stats

/// Daily stats from `analytics_daily_stats` view.
public struct SharedDailyStats: Codable, Identifiable {
    public var id: String { "\(storeId)-\(dateString)" }

    public let storeId: Int
    public let dateString: String
    public let totalOrders: Int
    public let totalRevenue: Double
    public let totalTax: Double?
    public let avgOrderValue: Double
    public let uniqueCustomers: Int

    public var date: Date? {
        SharedDateFormatting.parseISO8601(dateString)
    }

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case dateString = "date"
        case totalOrders = "total_orders"
        case totalRevenue = "total_revenue"
        case totalTax = "total_tax"
        case avgOrderValue = "avg_order_value"
        case uniqueCustomers = "unique_customers"
    }

    public init(
        storeId: Int,
        dateString: String,
        totalOrders: Int,
        totalRevenue: Double,
        totalTax: Double?,
        avgOrderValue: Double,
        uniqueCustomers: Int
    ) {
        self.storeId = storeId
        self.dateString = dateString
        self.totalOrders = totalOrders
        self.totalRevenue = totalRevenue
        self.totalTax = totalTax
        self.avgOrderValue = avgOrderValue
        self.uniqueCustomers = uniqueCustomers
    }
}

// MARK: - Shared Hourly Stats

/// Hourly stats from `analytics_hourly_today` view.
public struct SharedHourlyStats: Codable, Identifiable {
    public var id: String { "\(storeId)-\(hour)" }

    public let storeId: Int
    public let hour: Int
    public let orders: Int
    public let revenue: Double

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case hour
        case orders
        case revenue
    }

    public init(storeId: Int, hour: Int, orders: Int, revenue: Double) {
        self.storeId = storeId
        self.hour = hour
        self.orders = orders
        self.revenue = revenue
    }

    /// Formatted hour label (e.g., "9 AM", "2 PM")
    public var hourLabel: String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
        }
    }
}

// MARK: - Shared Popular Item

/// Popular item from `analytics_popular_items` view.
public struct SharedPopularItem: Codable, Identifiable {
    public var id: Int { menuItemId }

    public let storeId: Int
    public let menuItemId: Int
    public let itemName: String
    public let timesOrdered: Int
    public let totalQuantity: Int
    public let totalRevenue: Double
    public let avgPrice: Double

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case menuItemId = "menu_item_id"
        case itemName = "item_name"
        case timesOrdered = "times_ordered"
        case totalQuantity = "total_quantity"
        case totalRevenue = "total_revenue"
        case avgPrice = "avg_price"
    }

    public init(
        storeId: Int,
        menuItemId: Int,
        itemName: String,
        timesOrdered: Int,
        totalQuantity: Int,
        totalRevenue: Double,
        avgPrice: Double
    ) {
        self.storeId = storeId
        self.menuItemId = menuItemId
        self.itemName = itemName
        self.timesOrdered = timesOrdered
        self.totalQuantity = totalQuantity
        self.totalRevenue = totalRevenue
        self.avgPrice = avgPrice
    }
}

// MARK: - Revenue Chart Data

/// Revenue chart data point from `get_revenue_chart_data` RPC.
public struct SharedRevenueChartData: Codable, Identifiable {
    public var id: String { timeLabel }

    public let timeLabel: String
    public let revenue: Double
    public let orders: Int

    enum CodingKeys: String, CodingKey {
        case timeLabel = "time_label"
        case revenue
        case orders
    }

    public init(timeLabel: String, revenue: Double, orders: Int) {
        self.timeLabel = timeLabel
        self.revenue = revenue
        self.orders = orders
    }
}

// MARK: - Date Range

/// Canonical date range values for analytics queries.
public enum SharedDateRange: String, Codable, CaseIterable {
    case today = "today"
    case week = "week"
    case month = "month"
    case year = "year"

    public var displayName: String {
        switch self {
        case .today: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        }
    }
}

// MARK: - Order Type Distribution

/// Order type distribution for analytics.
public struct SharedOrderTypeDistribution: Codable, Identifiable {
    public var id: String { orderType }

    public let orderType: String
    public let count: Int
    public let percentage: Double

    public init(orderType: String, count: Int, percentage: Double) {
        self.orderType = orderType
        self.count = count
        self.percentage = percentage
    }
}
