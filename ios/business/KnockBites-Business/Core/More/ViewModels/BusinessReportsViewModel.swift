//
//  BusinessReportsViewModel.swift
//  knockbites-Bussiness-app
//
//  Extracted from BusinessReportsView.swift during Phase 3 cleanup
//

import SwiftUI
import Combine

@MainActor
class BusinessReportsViewModel: ObservableObject {
    @Published var selectedPeriod: ReportPeriod = .week
    @Published var isLoading = false

    // Key Metrics
    @Published var totalRevenue: Double = 0
    @Published var revenueChange: Double = 0
    @Published var totalOrders: Int = 0
    @Published var ordersChange: Double = 0
    @Published var averageOrderValue: Double = 0
    @Published var aovChange: Double = 0
    @Published var topCategory: String = ""
    @Published var topCategoryRevenue: Double = 0

    // Chart Data
    @Published var revenueByDay: [RevenueDataPoint] = []
    @Published var categoryPerformance: [CategoryPerformance] = []
    @Published var peakHoursData: [PeakHourData] = []
    @Published var orderFrequency: [OrderFrequencyData] = []
    @Published var menuItemTrends: [MenuItemTrend] = []
    @Published var paymentMethods: [PaymentMethodData] = []

    private let analyticsService = AnalyticsService.shared

    init() {
        loadData()
    }

    func loadData() {
        Task {
            isLoading = true

            do {
                let storeId = SecureSupabaseConfig.storeId
                let dateRange = selectedPeriod.apiValue

                // Fetch metrics
                let metrics = try await analyticsService.getStoreMetrics(storeId: storeId, dateRange: dateRange)
                totalRevenue = Double(metrics.totalRevenue.description) ?? 0
                totalOrders = metrics.totalOrders
                averageOrderValue = Double(metrics.avgOrderValue.description) ?? 0
                revenueChange = Double(metrics.revenueChange?.description ?? "0") ?? 0
                ordersChange = Double(metrics.ordersChange ?? 0)
                aovChange = revenueChange - ordersChange // Approximation

                // Fetch revenue chart data
                let revenuePoints = try await analyticsService.getRevenueChartData(storeId: storeId, dateRange: dateRange)
                let formatter = ISO8601DateFormatter()
                revenueByDay = revenuePoints.compactMap { point in
                    RevenueDataPoint(
                        date: formatter.date(from: point.timeLabel) ?? Date(),
                        revenue: Double(point.revenue.description) ?? 0,
                        orders: point.orders,
                        averageOrderValue: point.orders > 0 ? (Double(point.revenue.description) ?? 0) / Double(point.orders) : 0
                    )
                }

                // Fetch category distribution
                let categories = try await analyticsService.getCategoryDistribution(limit: 10)
                let categoryColors: [Color] = [.blue, .green, .orange, .pink, .purple, .yellow, .red, .cyan, .indigo, .mint]
                categoryPerformance = categories.enumerated().map { index, item in
                    CategoryPerformance(
                        category: item.category,
                        revenue: Double(item.totalRevenue.description) ?? 0,
                        orders: item.orderCount,
                        color: categoryColors[index % categoryColors.count]
                    )
                }.sorted { $0.revenue > $1.revenue }

                topCategory = categoryPerformance.first?.category ?? ""
                topCategoryRevenue = categoryPerformance.first?.revenue ?? 0

                // Fetch hourly data for peak hours
                let hourlyData = try await analyticsService.getHourlyData(storeId: storeId)
                peakHoursData = hourlyData.map { data in
                    PeakHourData(
                        hour: data.hour,
                        orders: data.orders,
                        revenue: Double(data.revenue.description) ?? 0
                    )
                }

                // Fetch popular items
                let popularItems = try await analyticsService.getPopularItems(storeId: storeId, limit: 10)
                menuItemTrends = popularItems.enumerated().map { index, item in
                    MenuItemTrend(
                        name: item.itemName,
                        orders: item.timesOrdered,
                        revenue: Double(item.totalRevenue.description) ?? 0,
                        trend: 0, // TODO: Calculate from historical data
                        rank: index + 1
                    )
                }.sorted { $0.orders > $1.orders }

                // Fetch payment methods
                let payments = try await analyticsService.getPaymentMethods(storeId: storeId)
                let paymentColors: [String: Color] = [
                    "credit_card": .blue,
                    "cash": .green,
                    "apple_pay": .black,
                    "google_pay": .orange
                ]
                paymentMethods = payments.map { item in
                    PaymentMethodData(
                        method: item.method.capitalized,
                        count: item.count,
                        percentage: item.percentage,
                        color: paymentColors[item.method.lowercased()] ?? .gray
                    )
                }

                // Calculate order frequency from daily stats
                let dailyStats = try await analyticsService.getDailyStats(storeId: storeId, days: 90)
                let totalCustomers = dailyStats.reduce(0) { $0 + $1.uniqueCustomers }

                // Simple frequency distribution based on customer data
                orderFrequency = [
                    OrderFrequencyData(frequency: "Active Customers", count: totalCustomers, percentage: 1.0)
                ]

                print("✅ Business reports loaded successfully")
            } catch {
                print("❌ Error loading business reports: \(error)")
                // Leave data empty on error - no mock data
            }

            isLoading = false
        }
    }

    func changePeriod(_ period: ReportPeriod) {
        selectedPeriod = period
        loadData()
    }
}
