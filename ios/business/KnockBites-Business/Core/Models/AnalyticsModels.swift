//
//  AnalyticsModels.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 4 cleanup - shared analytics DTOs
//

import Foundation

// MARK: - Analytics Summary

struct AnalyticsSummaryDTO {
    let revenue: Double
    let ordersCount: Int
    let customersCount: Int
    let avgPrepTime: Int
    let previousRevenue: Double
    let previousOrdersCount: Int
    let previousCustomersCount: Int
}

// MARK: - Daily Sales

struct DailySalesDTO {
    let date: Date
    let revenue: Double
    let orderCount: Int
}

// MARK: - Top Selling Items

struct TopSellingItemDTO {
    let menuItemId: String
    let menuItemName: String
    let totalQuantity: Int
    let revenue: Double
    let orderCount: Int
}

// MARK: - Order Summary (for aggregation)

struct OrderSummaryDTO: Codable {
    let id: Int
    let total: Double
    let createdAt: String
    let customerId: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case total
        case createdAt = "created_at"
        case customerId = "customer_id"
    }
}

// MARK: - Order Type Distribution

struct OrderTypeDistributionDTO: Codable {
    let type: String
}
