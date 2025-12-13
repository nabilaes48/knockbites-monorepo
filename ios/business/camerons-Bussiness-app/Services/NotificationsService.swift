//
//  NotificationsService.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/19/25.
//  Phase 1.1: Notifications Analytics Service
//

import Foundation
import Supabase

class NotificationsService {
    static let shared = NotificationsService()
    private let supabase = SupabaseManager.shared.client

    // MARK: - Aggregate Metrics

    /// Get total notifications sent for a store in a given period
    func getTotalSent(storeId: Int, period: NotificationPeriod) async throws -> Int {
        do {
            let dateRange = getDateRange(for: period)

            let response = try await supabase
                .from("push_notifications")
                .select("recipients_count", head: false, count: .exact)
                .eq("store_id", value: storeId)
                .eq("status", value: "sent")
                .gte("sent_at", value: dateRange.start)
                .lte("sent_at", value: dateRange.end)
                .execute()

            let notifications = try JSONDecoder().decode([NotificationCountResponse].self, from: response.data)
            return notifications.reduce(0) { $0 + $1.recipientsCount }
        } catch {
            print("⚠️ getTotalSent failed: \(error)")
            return 0
        }
    }

    /// Get delivery rate percentage for a store in a given period
    func getDeliveryRate(storeId: Int, period: NotificationPeriod) async throws -> Int {
        do {
            let dateRange = getDateRange(for: period)

            let response = try await supabase
                .from("push_notifications")
                .select("recipients_count,delivered_count")
                .eq("store_id", value: storeId)
                .eq("status", value: "sent")
                .gte("sent_at", value: dateRange.start)
                .lte("sent_at", value: dateRange.end)
                .execute()

            let notifications = try JSONDecoder().decode([NotificationStatsResponse].self, from: response.data)

            let totalSent = notifications.reduce(0) { $0 + $1.recipientsCount }
            let totalDelivered = notifications.reduce(0) { $0 + $1.deliveredCount }

            guard totalSent > 0 else { return 0 }
            return Int((Double(totalDelivered) / Double(totalSent)) * 100)
        } catch {
            print("⚠️ getDeliveryRate failed: \(error)")
            return 0
        }
    }

    /// Get open rate percentage for a store in a given period
    func getOpenRate(storeId: Int, period: NotificationPeriod) async throws -> Int {
        do {
            let dateRange = getDateRange(for: period)

            let response = try await supabase
                .from("push_notifications")
                .select("delivered_count,opened_count")
                .eq("store_id", value: storeId)
                .eq("status", value: "sent")
                .gte("sent_at", value: dateRange.start)
                .lte("sent_at", value: dateRange.end)
                .execute()

            let notifications = try JSONDecoder().decode([NotificationStatsResponse].self, from: response.data)

            let totalDelivered = notifications.reduce(0) { $0 + $1.deliveredCount }
            let totalOpened = notifications.reduce(0) { $0 + $1.openedCount }

            guard totalDelivered > 0 else { return 0 }
            return Int((Double(totalOpened) / Double(totalDelivered)) * 100)
        } catch {
            print("⚠️ getOpenRate failed: \(error)")
            return 0
        }
    }

    /// Get click rate percentage for a store in a given period
    func getClickRate(storeId: Int, period: NotificationPeriod) async throws -> Int {
        do {
            let dateRange = getDateRange(for: period)

            let response = try await supabase
                .from("push_notifications")
                .select("opened_count,clicked_count")
                .eq("store_id", value: storeId)
                .eq("status", value: "sent")
                .gte("sent_at", value: dateRange.start)
                .lte("sent_at", value: dateRange.end)
                .execute()

            let notifications = try JSONDecoder().decode([NotificationStatsResponse].self, from: response.data)

            let totalOpened = notifications.reduce(0) { $0 + $1.openedCount }
            let totalClicked = notifications.reduce(0) { $0 + $1.clickedCount }

            guard totalOpened > 0 else { return 0 }
            return Int((Double(totalClicked) / Double(totalOpened)) * 100)
        } catch {
            print("⚠️ getClickRate failed: \(error)")
            return 0
        }
    }

    /// Get percentage changes compared to previous period
    func getPeriodChanges(storeId: Int, period: NotificationPeriod) async throws -> NotificationChanges {
        let currentPeriod = getDateRange(for: period)
        let previousPeriod = getPreviousDateRange(for: period)

        // Current period metrics
        let currentSent = try await getTotalSentInRange(storeId: storeId, start: currentPeriod.start, end: currentPeriod.end)
        let currentDelivered = try await getTotalDeliveredInRange(storeId: storeId, start: currentPeriod.start, end: currentPeriod.end)
        let currentOpened = try await getTotalOpenedInRange(storeId: storeId, start: currentPeriod.start, end: currentPeriod.end)

        // Previous period metrics
        let previousSent = try await getTotalSentInRange(storeId: storeId, start: previousPeriod.start, end: previousPeriod.end)
        let previousDelivered = try await getTotalDeliveredInRange(storeId: storeId, start: previousPeriod.start, end: previousPeriod.end)
        let previousOpened = try await getTotalOpenedInRange(storeId: storeId, start: previousPeriod.start, end: previousPeriod.end)

        // Calculate percentage changes
        let sentChange = calculatePercentageChange(current: currentSent, previous: previousSent)
        let deliveryChange = calculatePercentageChange(current: currentDelivered, previous: previousDelivered)
        let openChange = calculatePercentageChange(current: currentOpened, previous: previousOpened)

        return NotificationChanges(
            sentChange: sentChange,
            deliveryChange: deliveryChange,
            openChange: openChange,
            clickChange: 0 // Will be same calculation, simplified for now
        )
    }

    // MARK: - Time Series Data

    /// Get delivery success rate over time
    func getDeliverySuccessOverTime(storeId: Int, period: NotificationPeriod) async throws -> [DeliverySuccessDataPoint] {
        do {
            let dateRange = getDateRange(for: period)

            let response = try await supabase
                .from("push_notifications")
                .select("sent_at,recipients_count,delivered_count")
                .eq("store_id", value: storeId)
                .eq("status", value: "sent")
                .gte("sent_at", value: dateRange.start)
                .lte("sent_at", value: dateRange.end)
                .order("sent_at")
                .execute()

            let notifications = try JSONDecoder().decode([NotificationTimeSeriesResponse].self, from: response.data)

            // Group by day and calculate success rate
            var dailyData: [String: (sent: Int, delivered: Int)] = [:]

            let dateFormatter = ISO8601DateFormatter()
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = period == .week ? "EEE" : "MMM dd"

            for notification in notifications {
                if let date = dateFormatter.date(from: notification.sentAt) {
                    let dayKey = displayFormatter.string(from: date)
                    let current = dailyData[dayKey] ?? (sent: 0, delivered: 0)
                    dailyData[dayKey] = (
                        sent: current.sent + notification.recipientsCount,
                        delivered: current.delivered + notification.deliveredCount
                    )
                }
            }

            return dailyData.map { day, stats in
                let rate = stats.sent > 0 ? (Double(stats.delivered) / Double(stats.sent)) * 100 : 0
                return DeliverySuccessDataPoint(date: day, successRate: rate)
            }.sorted { $0.date < $1.date }
        } catch {
            print("⚠️ getDeliverySuccessOverTime failed: \(error)")
            return []
        }
    }

    /// Get hourly send performance
    func getHourlySendPerformance(storeId: Int, period: NotificationPeriod) async throws -> [HourlySendData] {
        do {
            let dateRange = getDateRange(for: period)

            let response = try await supabase
                .from("push_notifications")
                .select("sent_at,recipients_count,opened_count")
                .eq("store_id", value: storeId)
                .eq("status", value: "sent")
                .gte("sent_at", value: dateRange.start)
                .lte("sent_at", value: dateRange.end)
                .execute()

            let notifications = try JSONDecoder().decode([NotificationTimeSeriesResponse].self, from: response.data)

            // Group by hour (0-23)
            var hourlyData: [Int: (sent: Int, opened: Int)] = [:]

            let dateFormatter = ISO8601DateFormatter()
            let calendar = Calendar.current

            for notification in notifications {
                if let date = dateFormatter.date(from: notification.sentAt) {
                    let hour = calendar.component(.hour, from: date)
                    let current = hourlyData[hour] ?? (sent: 0, opened: 0)
                    hourlyData[hour] = (
                        sent: current.sent + notification.recipientsCount,
                        opened: current.opened + notification.openedCount
                    )
                }
            }

            return (0...23).map { hour in
                let stats = hourlyData[hour] ?? (sent: 0, opened: 0)
                let engagementRate = stats.sent > 0 ? (Double(stats.opened) / Double(stats.sent)) * 100 : 0
                return HourlySendData(hour: hour, notificationsSent: stats.sent, engagementRate: engagementRate)
            }
        } catch {
            print("⚠️ getHourlySendPerformance failed: \(error)")
            return []
        }
    }

    // MARK: - Distribution Data

    /// Get platform distribution (iOS, Android, Web)
    /// Note: Requires platform tracking in notification_deliveries table
    func getPlatformDistribution(storeId: Int, period: NotificationPeriod) async throws -> [PlatformDistributionItem] {
        // For now, return mock distribution since platform isn't tracked in current schema
        // When device_tokens table is created in Phase 2.4, this will query real data
        print("⚠️ getPlatformDistribution: Platform tracking not yet implemented")
        return [
            PlatformDistributionItem(platform: "iOS", count: 0, percentage: 0),
            PlatformDistributionItem(platform: "Android", count: 0, percentage: 0),
            PlatformDistributionItem(platform: "Web", count: 0, percentage: 0)
        ]
    }

    /// Get engagement funnel data
    func getEngagementFunnel(storeId: Int, period: NotificationPeriod) async throws -> EngagementFunnelData {
        do {
            let dateRange = getDateRange(for: period)

            let response = try await supabase
                .from("push_notifications")
                .select("recipients_count,delivered_count,opened_count,clicked_count")
                .eq("store_id", value: storeId)
                .eq("status", value: "sent")
                .gte("sent_at", value: dateRange.start)
                .lte("sent_at", value: dateRange.end)
                .execute()

            let notifications = try JSONDecoder().decode([NotificationStatsResponse].self, from: response.data)

            let sent = notifications.reduce(0) { $0 + $1.recipientsCount }
            let delivered = notifications.reduce(0) { $0 + $1.deliveredCount }
            let opened = notifications.reduce(0) { $0 + $1.openedCount }
            let clicked = notifications.reduce(0) { $0 + $1.clickedCount }

            return EngagementFunnelData(
                sent: sent,
                delivered: delivered,
                opened: opened,
                clicked: clicked
            )
        } catch {
            print("⚠️ getEngagementFunnel failed: \(error)")
            return EngagementFunnelData(sent: 0, delivered: 0, opened: 0, clicked: 0)
        }
    }

    // MARK: - Recent Notifications

    /// Get recent notifications with performance stats
    func getRecentNotifications(storeId: Int, limit: Int = 10) async throws -> [RecentNotificationItem] {
        do {
            let response = try await supabase
                .from("push_notifications")
                .select("id,title,sent_at,recipients_count,delivered_count,opened_count,clicked_count")
                .eq("store_id", value: storeId)
                .eq("status", value: "sent")
                .order("sent_at", ascending: false)
                .limit(limit)
                .execute()

            let notifications = try JSONDecoder().decode([RecentNotificationResponse].self, from: response.data)

            return notifications.map { notification in
                let deliveryRate = notification.recipientsCount > 0 ?
                    (Double(notification.deliveredCount) / Double(notification.recipientsCount)) * 100 : 0
                let openRate = notification.deliveredCount > 0 ?
                    (Double(notification.openedCount) / Double(notification.deliveredCount)) * 100 : 0

                return RecentNotificationItem(
                    id: notification.id,
                    title: notification.title,
                    sentAt: notification.sentAt,
                    recipientCount: notification.recipientsCount,
                    deliveryRate: deliveryRate,
                    openRate: openRate
                )
            }
        } catch {
            print("⚠️ getRecentNotifications failed: \(error)")
            return []
        }
    }

    // MARK: - Helper Functions

    private func getTotalSentInRange(storeId: Int, start: String, end: String) async throws -> Int {
        let response = try await supabase
            .from("push_notifications")
            .select("recipients_count")
            .eq("store_id", value: storeId)
            .eq("status", value: "sent")
            .gte("sent_at", value: start)
            .lte("sent_at", value: end)
            .execute()

        let notifications = try JSONDecoder().decode([NotificationCountResponse].self, from: response.data)
        return notifications.reduce(0) { $0 + $1.recipientsCount }
    }

    private func getTotalDeliveredInRange(storeId: Int, start: String, end: String) async throws -> Int {
        let response = try await supabase
            .from("push_notifications")
            .select("delivered_count")
            .eq("store_id", value: storeId)
            .eq("status", value: "sent")
            .gte("sent_at", value: start)
            .lte("sent_at", value: end)
            .execute()

        let notifications = try JSONDecoder().decode([NotificationCountResponse].self, from: response.data)
        return notifications.reduce(0) { $0 + ($1.deliveredCount ?? 0) }
    }

    private func getTotalOpenedInRange(storeId: Int, start: String, end: String) async throws -> Int {
        let response = try await supabase
            .from("push_notifications")
            .select("opened_count")
            .eq("store_id", value: storeId)
            .eq("status", value: "sent")
            .gte("sent_at", value: start)
            .lte("sent_at", value: end)
            .execute()

        let notifications = try JSONDecoder().decode([NotificationCountResponse].self, from: response.data)
        return notifications.reduce(0) { $0 + ($1.openedCount ?? 0) }
    }

    private func getDateRange(for period: NotificationPeriod) -> (start: String, end: String) {
        let now = Date()
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()

        let endDate = now
        let startDate: Date

        switch period {
        case .today:
            startDate = calendar.startOfDay(for: now)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        }

        return (start: formatter.string(from: startDate), end: formatter.string(from: endDate))
    }

    private func getPreviousDateRange(for period: NotificationPeriod) -> (start: String, end: String) {
        let current = getDateRange(for: period)
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()

        guard let currentStart = formatter.date(from: current.start),
              let currentEnd = formatter.date(from: current.end) else {
            return current
        }

        let duration = currentEnd.timeIntervalSince(currentStart)
        let previousEnd = currentStart
        let previousStart = previousEnd.addingTimeInterval(-duration)

        return (start: formatter.string(from: previousStart), end: formatter.string(from: previousEnd))
    }

    private func calculatePercentageChange(current: Int, previous: Int) -> Double {
        guard previous > 0 else { return current > 0 ? 100 : 0 }
        return ((Double(current) - Double(previous)) / Double(previous)) * 100
    }
}

// MARK: - Response Models

struct NotificationCountResponse: Codable {
    let recipientsCount: Int
    let deliveredCount: Int?
    let openedCount: Int?

    enum CodingKeys: String, CodingKey {
        case recipientsCount = "recipients_count"
        case deliveredCount = "delivered_count"
        case openedCount = "opened_count"
    }
}

struct NotificationStatsResponse: Codable {
    let recipientsCount: Int
    let deliveredCount: Int
    let openedCount: Int
    let clickedCount: Int

    enum CodingKeys: String, CodingKey {
        case recipientsCount = "recipients_count"
        case deliveredCount = "delivered_count"
        case openedCount = "opened_count"
        case clickedCount = "clicked_count"
    }
}

struct NotificationTimeSeriesResponse: Codable {
    let sentAt: String
    let recipientsCount: Int
    let deliveredCount: Int
    let openedCount: Int

    enum CodingKeys: String, CodingKey {
        case sentAt = "sent_at"
        case recipientsCount = "recipients_count"
        case deliveredCount = "delivered_count"
        case openedCount = "opened_count"
    }
}

struct RecentNotificationResponse: Codable {
    let id: Int
    let title: String
    let sentAt: String
    let recipientsCount: Int
    let deliveredCount: Int
    let openedCount: Int
    let clickedCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case sentAt = "sent_at"
        case recipientsCount = "recipients_count"
        case deliveredCount = "delivered_count"
        case openedCount = "opened_count"
        case clickedCount = "clicked_count"
    }
}

// MARK: - Data Models

struct NotificationChanges {
    let sentChange: Double
    let deliveryChange: Double
    let openChange: Double
    let clickChange: Double
}

struct DeliverySuccessDataPoint: Codable {
    let date: String
    let successRate: Double
}

struct HourlySendData: Codable {
    let hour: Int
    let notificationsSent: Int
    let engagementRate: Double
}

struct PlatformDistributionItem: Codable {
    let platform: String
    let count: Int
    let percentage: Double
}

struct EngagementFunnelData: Codable {
    let sent: Int
    let delivered: Int
    let opened: Int
    let clicked: Int
}

struct RecentNotificationItem: Codable {
    let id: Int
    let title: String
    let sentAt: String
    let recipientCount: Int
    let deliveryRate: Double
    let openRate: Double
}

// MARK: - Period Enum
// NotificationPeriod is defined in NotificationsAnalyticsView.swift
