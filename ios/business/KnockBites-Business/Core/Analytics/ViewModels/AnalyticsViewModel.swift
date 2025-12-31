//
//  AnalyticsViewModel.swift
//  knockbites-Bussiness-app
//
//  Extracted from AnalyticsView.swift during Phase 3 cleanup
//

import SwiftUI
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var currentPeriod: TimePeriod = .week
    @Published var quickStats = QuickStats(
        revenue: 0,
        revenueChange: "+0%",
        ordersCount: 0,
        ordersChange: 0,
        customersCount: 0,
        customersChange: 0,
        avgPrepTime: 0,
        timeChange: 0
    )
    @Published var revenueData: [ChartDataPoint] = []
    @Published var topItems: [PopularItem] = []
    @Published var orderTypes: [OrderTypeData] = []
    @Published var qualityMetrics = KitchenQualityMetrics(
        qualityScore: 0,
        onTimePercentage: 0,
        onTimeCount: 0,
        totalOrders: 0,
        lateOrdersCount: 0,
        latePercentage: 0,
        avgActualTime: 0,
        avgEstimatedTime: 0,
        avgVariance: 0
    )
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe period changes and reload data automatically
        $currentPeriod
            .dropFirst() // Skip initial value to avoid double loading
            .sink { [weak self] period in
                self?.loadAnalytics(for: period)
            }
            .store(in: &cancellables)
    }

    func loadAnalytics(for period: TimePeriod = .week) {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                switch period {
                case .today:
                    try await loadTodayAnalytics()
                case .week:
                    try await loadWeekAnalytics()
                case .month:
                    try await loadMonthAnalytics()
                }
            } catch {
                print("❌ Failed to load analytics: \(error)")
                errorMessage = "Failed to load analytics"
                // Fall back to mock data
                loadMockData(for: period)
            }

            isLoading = false
        }
    }

    // MARK: - Week Analytics (Real Data from Supabase)
    private func loadWeekAnalytics() async throws {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!

        // Fetch analytics summary
        let summary = try await SupabaseManager.shared.fetchAnalyticsSummary(
            storeId: SecureSupabaseConfig.storeId,
            startDate: startDate,
            endDate: endDate
        )

        // Calculate changes from previous period
        let revenueChange = summary.previousRevenue > 0
            ? Int((summary.revenue - summary.previousRevenue) / summary.previousRevenue * 100)
            : 0
        let ordersChange = summary.ordersCount - summary.previousOrdersCount
        let customersChange = summary.customersCount - summary.previousCustomersCount

        quickStats = QuickStats(
            revenue: summary.revenue,
            revenueChange: revenueChange >= 0 ? "+\(revenueChange)%" : "\(revenueChange)%",
            ordersCount: summary.ordersCount,
            ordersChange: ordersChange,
            customersCount: summary.customersCount,
            customersChange: customersChange,
            avgPrepTime: summary.avgPrepTime,
            timeChange: 0
        )

        // Fetch daily sales for chart
        let dailySales = try await SupabaseManager.shared.fetchDailySales(
            storeId: SecureSupabaseConfig.storeId,
            days: 7
        )

        let maxRevenue = dailySales.map { $0.revenue }.max() ?? 1
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        revenueData = dailySales.map { sale in
            ChartDataPoint(
                label: formatter.string(from: sale.date),
                value: sale.revenue,
                percentage: maxRevenue > 0 ? sale.revenue / maxRevenue : 0
            )
        }

        // Fetch top selling items
        let topSellingItems = try await SupabaseManager.shared.fetchTopSellingItems(
            storeId: SecureSupabaseConfig.storeId,
            startDate: startDate,
            endDate: endDate,
            limit: 5
        )

        // Convert to PopularItem (use mock menu items for now since we need full MenuItem data)
        let menuItems = try await SupabaseManager.shared.fetchMenuItems()
        topItems = topSellingItems.compactMap { item in
            guard let menuItem = menuItems.first(where: { $0.id == item.menuItemId }) else {
                return nil
            }
            return PopularItem(
                id: item.menuItemId,
                menuItem: menuItem,
                orderCount: item.orderCount,
                revenue: item.revenue
            )
        }

        // Fetch order type distribution
        let distribution = try await SupabaseManager.shared.fetchOrderTypeDistribution(
            storeId: SecureSupabaseConfig.storeId,
            startDate: startDate,
            endDate: endDate
        )

        let pickupCount = distribution["takeout"] ?? 0
        let deliveryCount = distribution["delivery"] ?? 0
        let dineInCount = distribution["dine-in"] ?? 0
        let totalOrders = pickupCount + deliveryCount + dineInCount

        orderTypes = totalOrders > 0 ? [
            OrderTypeData(
                type: "Pickup",
                icon: "bag.fill",
                count: pickupCount,
                percentage: Double(pickupCount) / Double(totalOrders),
                color: .brandPrimary
            ),
            OrderTypeData(
                type: "Delivery",
                icon: "bicycle",
                count: deliveryCount,
                percentage: Double(deliveryCount) / Double(totalOrders),
                color: .success
            ),
            OrderTypeData(
                type: "Dine-In",
                icon: "fork.knife",
                count: dineInCount,
                percentage: Double(dineInCount) / Double(totalOrders),
                color: .warning
            )
        ] : []

        // Generate quality metrics
        generateQualityMetrics(for: summary.ordersCount)
    }

    // MARK: - Today Analytics (Hourly)
    private func loadTodayAnalytics() async throws {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endDate = Date()

        // Fetch today's analytics
        let summary = try await SupabaseManager.shared.fetchAnalyticsSummary(
            storeId: SecureSupabaseConfig.storeId,
            startDate: startOfToday,
            endDate: endDate
        )

        let revenueChange = summary.previousRevenue > 0
            ? Int((summary.revenue - summary.previousRevenue) / summary.previousRevenue * 100)
            : 0

        quickStats = QuickStats(
            revenue: summary.revenue,
            revenueChange: revenueChange >= 0 ? "+\(revenueChange)%" : "\(revenueChange)%",
            ordersCount: summary.ordersCount,
            ordersChange: summary.ordersCount - summary.previousOrdersCount,
            customersCount: summary.customersCount,
            customersChange: summary.customersCount - summary.previousCustomersCount,
            avgPrepTime: summary.avgPrepTime,
            timeChange: 0
        )

        // For today, show hourly revenue (simplified - just show distribution)
        // In a real app, you'd query hourly data
        revenueData = []  // Could implement hourly breakdown later

        // Fetch top selling items for today
        let topSellingItems = try await SupabaseManager.shared.fetchTopSellingItems(
            storeId: SecureSupabaseConfig.storeId,
            startDate: startOfToday,
            endDate: endDate,
            limit: 5
        )

        let menuItems = try await SupabaseManager.shared.fetchMenuItems()
        topItems = topSellingItems.compactMap { item in
            guard let menuItem = menuItems.first(where: { $0.id == item.menuItemId }) else {
                return nil
            }
            return PopularItem(
                id: item.menuItemId,
                menuItem: menuItem,
                orderCount: item.orderCount,
                revenue: item.revenue
            )
        }

        // Fetch order type distribution
        let distribution = try await SupabaseManager.shared.fetchOrderTypeDistribution(
            storeId: SecureSupabaseConfig.storeId,
            startDate: startOfToday,
            endDate: endDate
        )

        let pickupCount = distribution["takeout"] ?? 0
        let deliveryCount = distribution["delivery"] ?? 0
        let dineInCount = distribution["dine-in"] ?? 0
        let totalOrders = pickupCount + deliveryCount + dineInCount

        orderTypes = totalOrders > 0 ? [
            OrderTypeData(type: "Pickup", icon: "bag.fill", count: pickupCount, percentage: Double(pickupCount) / Double(totalOrders), color: .brandPrimary),
            OrderTypeData(type: "Delivery", icon: "bicycle", count: deliveryCount, percentage: Double(deliveryCount) / Double(totalOrders), color: .success),
            OrderTypeData(type: "Dine-In", icon: "fork.knife", count: dineInCount, percentage: Double(dineInCount) / Double(totalOrders), color: .warning)
        ] : []

        generateQualityMetrics(for: summary.ordersCount)
    }

    // MARK: - Month Analytics (Weekly)
    private func loadMonthAnalytics() async throws {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!

        // Fetch monthly summary
        let summary = try await SupabaseManager.shared.fetchAnalyticsSummary(
            storeId: SecureSupabaseConfig.storeId,
            startDate: startDate,
            endDate: endDate
        )

        let revenueChange = summary.previousRevenue > 0
            ? Int((summary.revenue - summary.previousRevenue) / summary.previousRevenue * 100)
            : 0

        quickStats = QuickStats(
            revenue: summary.revenue,
            revenueChange: revenueChange >= 0 ? "+\(revenueChange)%" : "\(revenueChange)%",
            ordersCount: summary.ordersCount,
            ordersChange: summary.ordersCount - summary.previousOrdersCount,
            customersCount: summary.customersCount,
            customersChange: summary.customersCount - summary.previousCustomersCount,
            avgPrepTime: summary.avgPrepTime,
            timeChange: 0
        )

        // Fetch monthly sales (30 days)
        let dailySales = try await SupabaseManager.shared.fetchDailySales(
            storeId: SecureSupabaseConfig.storeId,
            days: 30
        )

        // Group into weeks
        let weeklySales = groupByWeeks(dailySales)
        let maxRevenue = weeklySales.map { $0.revenue }.max() ?? 1

        revenueData = weeklySales.enumerated().map { index, sale in
            ChartDataPoint(
                label: "Week \(index + 1)",
                value: sale.revenue,
                percentage: maxRevenue > 0 ? sale.revenue / maxRevenue : 0
            )
        }

        // Fetch top selling items
        let topSellingItems = try await SupabaseManager.shared.fetchTopSellingItems(
            storeId: SecureSupabaseConfig.storeId,
            startDate: startDate,
            endDate: endDate,
            limit: 5
        )

        let menuItems = try await SupabaseManager.shared.fetchMenuItems()
        topItems = topSellingItems.compactMap { item in
            guard let menuItem = menuItems.first(where: { $0.id == item.menuItemId }) else {
                return nil
            }
            return PopularItem(
                id: item.menuItemId,
                menuItem: menuItem,
                orderCount: item.orderCount,
                revenue: item.revenue
            )
        }

        // Fetch order type distribution
        let distribution = try await SupabaseManager.shared.fetchOrderTypeDistribution(
            storeId: SecureSupabaseConfig.storeId,
            startDate: startDate,
            endDate: endDate
        )

        let pickupCount = distribution["takeout"] ?? 0
        let deliveryCount = distribution["delivery"] ?? 0
        let dineInCount = distribution["dine-in"] ?? 0
        let totalOrders = pickupCount + deliveryCount + dineInCount

        orderTypes = totalOrders > 0 ? [
            OrderTypeData(type: "Pickup", icon: "bag.fill", count: pickupCount, percentage: Double(pickupCount) / Double(totalOrders), color: .brandPrimary),
            OrderTypeData(type: "Delivery", icon: "bicycle", count: deliveryCount, percentage: Double(deliveryCount) / Double(totalOrders), color: .success),
            OrderTypeData(type: "Dine-In", icon: "fork.knife", count: dineInCount, percentage: Double(dineInCount) / Double(totalOrders), color: .warning)
        ] : []

        generateQualityMetrics(for: summary.ordersCount)
    }

    private func groupByWeeks(_ dailySales: [SupabaseManager.DailySales]) -> [(revenue: Double, orderCount: Int)] {
        var weeks: [(revenue: Double, orderCount: Int)] = []
        var currentWeek = (revenue: 0.0, orderCount: 0)
        var dayCount = 0

        for sale in dailySales {
            currentWeek.revenue += sale.revenue
            currentWeek.orderCount += sale.orderCount
            dayCount += 1

            if dayCount == 7 {
                weeks.append(currentWeek)
                currentWeek = (revenue: 0.0, orderCount: 0)
                dayCount = 0
            }
        }

        // Add remaining days as last week
        if dayCount > 0 {
            weeks.append(currentWeek)
        }

        return weeks
    }

    // MARK: - Fallback Mock Data
    private func loadMockData(for period: TimePeriod) {
        print("⚠️ Using mock analytics data")
        // Use original mock data generation as fallback
        switch period {
        case .today:
            quickStats = QuickStats(revenue: 850, revenueChange: "+12%", ordersCount: 24, ordersChange: 3, customersCount: 18, customersChange: 2, avgPrepTime: 18, timeChange: -2)
        case .week:
            quickStats = QuickStats(revenue: 3500, revenueChange: "+15%", ordersCount: 48, ordersChange: 8, customersCount: 35, customersChange: 5, avgPrepTime: 19, timeChange: 1)
        case .month:
            quickStats = QuickStats(revenue: 15000, revenueChange: "+22%", ordersCount: 250, ordersChange: 35, customersCount: 180, customersChange: 25, avgPrepTime: 18, timeChange: 0)
        }

        topItems = MockDataService.shared.generatePopularItems()
        orderTypes = []
        revenueData = []
    }

    // MARK: - Helper Methods
    private func generateQualityMetrics(for orderCount: Int) {
        // Generate realistic quality metrics
        let onTimeCount = Int(Double(orderCount) * Double.random(in: 0.70...0.95))
        let lateCount = orderCount - onTimeCount
        let onTimePercentage = Int((Double(onTimeCount) / Double(orderCount)) * 100)
        let latePercentage = 100 - onTimePercentage

        // Average times (in minutes)
        let avgEstimated = Int.random(in: 18...25)
        let avgActual = Int.random(in: 16...30)
        let variance = avgActual - avgEstimated

        // Calculate quality score (0-100)
        // Factors: on-time percentage (60%), time accuracy (30%), late orders (10%)
        let onTimeScore = onTimePercentage * 60 / 100
        let timeAccuracy = max(0, 100 - abs(variance) * 3) // Penalize variance
        let timeAccuracyScore = timeAccuracy * 30 / 100
        let lateOrderScore = max(0, (100 - latePercentage * 2)) * 10 / 100
        let qualityScore = min(100, onTimeScore + timeAccuracyScore + lateOrderScore)

        qualityMetrics = KitchenQualityMetrics(
            qualityScore: qualityScore,
            onTimePercentage: onTimePercentage,
            onTimeCount: onTimeCount,
            totalOrders: orderCount,
            lateOrdersCount: lateCount,
            latePercentage: latePercentage,
            avgActualTime: avgActual,
            avgEstimatedTime: avgEstimated,
            avgVariance: variance
        )
    }
}
