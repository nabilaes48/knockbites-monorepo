//
//  NotificationsAnalyticsViewModel.swift
//  knockbites-Bussiness-app
//
//  Extracted from NotificationsAnalyticsView.swift during Phase 3 cleanup
//

import SwiftUI
import Combine

@MainActor
class NotificationsAnalyticsViewModel: ObservableObject {
    @Published var totalSent = 0
    @Published var delivered = 0
    @Published var opened = 0
    @Published var clicked = 0

    @Published var sentChange = "+0%"
    @Published var deliveryChange = "+0%"
    @Published var openChange = "+0%"
    @Published var clickChange = "+0%"

    @Published var deliveryRate = 0
    @Published var openRate = 0
    @Published var clickRate = 0

    @Published var deliveryData: [DeliverySuccessData] = []
    @Published var hourlyPerformance: [HourlyPerformanceData] = []
    @Published var platformData: [PlatformData] = []
    @Published var recentNotifications: [NotificationPerformance] = []

    func loadAnalytics(period: NotificationPeriod) {
        Task {
            await loadRealData(for: period)
        }
    }

    func refreshAsync(period: NotificationPeriod) async {
        await loadRealData(for: period)
    }

    private func loadRealData(for period: NotificationPeriod) async {
        let storeId = SupabaseConfig.storeId
        let service = NotificationsService.shared

        do {
            // Get aggregate metrics
            let sent = try await service.getTotalSent(storeId: storeId, period: period)
            let delRate = try await service.getDeliveryRate(storeId: storeId, period: period)
            let opRate = try await service.getOpenRate(storeId: storeId, period: period)
            let clRate = try await service.getClickRate(storeId: storeId, period: period)

            // Get funnel data for absolute numbers
            let funnel = try await service.getEngagementFunnel(storeId: storeId, period: period)

            // Get period changes
            let changes = try await service.getPeriodChanges(storeId: storeId, period: period)

            // Get time series data
            let deliverySuccess = try await service.getDeliverySuccessOverTime(storeId: storeId, period: period)
            let hourlyPerf = try await service.getHourlySendPerformance(storeId: storeId, period: period)
            let platforms = try await service.getPlatformDistribution(storeId: storeId, period: period)
            let recent = try await service.getRecentNotifications(storeId: storeId, limit: 10)

            // Update published properties on main thread
            await MainActor.run {
                self.totalSent = sent
                self.delivered = funnel.delivered
                self.opened = funnel.opened
                self.clicked = funnel.clicked

                self.deliveryRate = delRate
                self.openRate = opRate
                self.clickRate = clRate

                // Format percentage changes
                self.sentChange = formatChange(changes.sentChange)
                self.deliveryChange = formatChange(changes.deliveryChange)
                self.openChange = formatChange(changes.openChange)
                self.clickChange = formatChange(changes.clickChange)

                // Map delivery success data
                self.deliveryData = deliverySuccess.map { point in
                    DeliverySuccessData(
                        date: Date(), // Will be parsed from string
                        successRate: point.successRate,
                        failureRate: 100 - point.successRate
                    )
                }

                // Map hourly performance data
                self.hourlyPerformance = hourlyPerf.map { hour in
                    HourlyPerformanceData(
                        hour: hour.hour,
                        openRate: hour.engagementRate,
                        clickRate: hour.engagementRate * 0.2 // Estimate click rate
                    )
                }

                // Map platform data
                self.platformData = platforms.map { platform in
                    PlatformData(
                        name: platform.platform,
                        count: platform.count,
                        percentage: platform.percentage / 100
                    )
                }

                // Map recent notifications
                let dateFormatter = ISO8601DateFormatter()
                self.recentNotifications = recent.compactMap { notification in
                    guard let sentDate = dateFormatter.date(from: notification.sentAt) else {
                        return nil
                    }
                    return NotificationPerformance(
                        title: notification.title,
                        sentDate: sentDate,
                        sent: notification.recipientCount,
                        delivered: Int(Double(notification.recipientCount) * (notification.deliveryRate / 100)),
                        opened: Int(Double(notification.recipientCount) * (notification.deliveryRate / 100) * (notification.openRate / 100)),
                        clicked: 0, // Calculate from open rate
                        icon: determineIcon(for: notification.title),
                        color: determineColor(for: notification.title)
                    )
                }

                print("✅ Loaded notification analytics: \(sent) sent, \(delRate)% delivery rate")
            }
        } catch {
            print("⚠️ Failed to load notification analytics: \(error)")
            // Keep zeros on error - graceful degradation
            await MainActor.run {
                self.totalSent = 0
                self.deliveryRate = 0
                self.openRate = 0
                self.clickRate = 0
            }
        }
    }

    private func formatChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(Int(change))%"
    }

    private func determineIcon(for title: String) -> String {
        if title.contains("🎉") || title.contains("Special") { return "gift.fill" }
        if title.contains("⏰") || title.contains("ready") { return "checkmark.circle.fill" }
        if title.contains("🍔") || title.contains("Menu") { return "star.fill" }
        if title.contains("💳") || title.contains("Points") { return "star.circle.fill" }
        return "bell.fill"
    }

    private func determineColor(for title: String) -> Color {
        if title.contains("Special") { return .orange }
        if title.contains("ready") { return .green }
        if title.contains("Menu") { return .blue }
        if title.contains("Points") { return .purple }
        return .brandPrimary
    }
}
