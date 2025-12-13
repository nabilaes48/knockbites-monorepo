//
//  StoreAnalyticsViewModel.swift
//  knockbites-Bussiness-app
//
//  Extracted from StoreAnalyticsView.swift during Phase 3 cleanup
//

import SwiftUI
import Combine

@MainActor
class StoreAnalyticsViewModel: ObservableObject {
    @Published var selectedPeriod: StorePeriod = .week
    @Published var isLoading = false

    // Store Performance Metrics
    @Published var storeRating: Double = 0
    @Published var ratingChange: Double = 0
    @Published var orderFulfillmentTime: Double = 0 // minutes
    @Published var fulfillmentChange: Double = 0
    @Published var activeStaff: Int = 0
    @Published var capacityUtilization: Double = 0

    // Chart Data
    @Published var dailyPerformance: [DailyPerformanceData] = []
    @Published var fulfillmentTimes: [FulfillmentTimeData] = []
    @Published var staffEfficiency: [StaffEfficiencyData] = []
    @Published var peakCapacity: [CapacityData] = []
    @Published var customerSatisfaction: [SatisfactionData] = []
    @Published var storeComparison: [StoreComparisonData] = []
    @Published var operatingHoursPerformance: [OperatingHourData] = []

    private let analyticsService = AnalyticsService.shared

    init() {
        loadData()
    }

    func loadData() {
        Task {
            isLoading = true

            do {
                let storeId = SupabaseConfig.storeId
                let dateRange = selectedPeriod.apiValue

                // Fetch store metrics
                _ = try await analyticsService.getStoreMetrics(storeId: storeId, dateRange: dateRange)

                // Calculate fulfillment time
                orderFulfillmentTime = try await analyticsService.getAverageFulfillmentTime(storeId: storeId)
                fulfillmentChange = 0 // TODO: Calculate from historical data

                // Store rating not available yet
                storeRating = 0
                ratingChange = 0

                // Active staff and capacity not available yet
                activeStaff = 0
                capacityUtilization = 0

                // Fetch daily performance
                let dailyStats = try await analyticsService.getDailyStats(storeId: storeId, days: 30)
                let formatter = ISO8601DateFormatter()
                dailyPerformance = dailyStats.compactMap { stat in
                    guard let date = formatter.date(from: stat.date) else { return nil }
                    return DailyPerformanceData(
                        date: date,
                        orders: stat.totalOrders,
                        revenue: Double(stat.totalRevenue.description) ?? 0,
                        rating: 0, // Not available
                        fulfillmentTime: 0 // Not tracked per day
                    )
                }.sorted { $0.date < $1.date }

                // Fetch hourly capacity data
                let hourlyData = try await analyticsService.getHourlyData(storeId: storeId)
                let maxOrders = hourlyData.map { $0.orders }.max() ?? 1
                peakCapacity = hourlyData.map { data in
                    CapacityData(
                        hour: data.hour,
                        utilization: Double(data.orders) / Double(maxOrders),
                        maxCapacity: maxOrders,
                        currentOrders: data.orders
                    )
                }

                // Fetch multi-store comparison
                storeComparison = try await analyticsService.getMultiStoreMetrics(dateRange: dateRange).map { comparison in
                    StoreComparisonData(
                        storeName: comparison.storeName,
                        orders: comparison.orders,
                        revenue: comparison.revenue,
                        rating: comparison.rating,
                        avgFulfillment: comparison.avgFulfillment,
                        color: .blue
                    )
                }

                // Calculate operating hours performance from daily stats
                let calendar = Calendar.current
                var dayPerformance: [String: (orders: Int, revenue: Double, count: Int)] = [:]

                for stat in dailyStats {
                    if let date = formatter.date(from: stat.date) {
                        let weekday = calendar.component(.weekday, from: date)
                        let dayName = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][weekday - 1]
                        let current = dayPerformance[dayName] ?? (orders: 0, revenue: 0, count: 0)
                        dayPerformance[dayName] = (
                            orders: current.orders + stat.totalOrders,
                            revenue: current.revenue + (Double(stat.totalRevenue.description) ?? 0),
                            count: current.count + 1
                        )
                    }
                }

                operatingHoursPerformance = dayPerformance.map { day, data in
                    OperatingHourData(
                        day: day,
                        avgOrders: data.count > 0 ? data.orders / data.count : 0,
                        avgRevenue: data.count > 0 ? data.revenue / Double(data.count) : 0,
                        peakHour: 12, // Not available
                        efficiency: 0  // Not available
                    )
                }.sorted { days.firstIndex(of: $0.day) ?? 0 < days.firstIndex(of: $1.day) ?? 0 }

                // Empty arrays for features not available in Supabase
                fulfillmentTimes = []
                staffEfficiency = []
                customerSatisfaction = []

                print("✅ Store analytics loaded successfully")
            } catch {
                print("❌ Error loading store analytics: \(error)")
                // Leave data empty on error
            }

            isLoading = false
        }
    }

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    func changePeriod(_ period: StorePeriod) {
        selectedPeriod = period
        loadData()
    }
}
