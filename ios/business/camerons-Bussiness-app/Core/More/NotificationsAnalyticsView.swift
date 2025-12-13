//
//  NotificationsAnalyticsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code - Comprehensive Notifications Analytics
//

import SwiftUI
import Charts
import Combine

struct NotificationsAnalyticsView: View {
    @StateObject private var viewModel = NotificationsAnalyticsViewModel()
    @State private var selectedPeriod: NotificationPeriod = .month

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Period Selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(NotificationPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedPeriod) { _ in
                    viewModel.loadAnalytics(period: selectedPeriod)
                }

                // Key Metrics
                notificationMetricsSection

                // Delivery Success Rate Chart
                deliverySuccessChart

                // Engagement Funnel
                engagementFunnelSection

                // Send Time Analysis
                sendTimeAnalysisChart

                // Device Platform Distribution
                platformDistributionChart

                // Recent Notifications Performance
                recentNotificationsSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Push Notifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.loadAnalytics(period: selectedPeriod) }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.brandPrimary)
                }
            }
        }
        .onAppear {
            viewModel.loadAnalytics(period: selectedPeriod)
        }
        .refreshable {
            await viewModel.refreshAsync(period: selectedPeriod)
        }
    }

    // MARK: - Notification Metrics Section

    private var notificationMetricsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Overview")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    NotificationMetricCard(
                        title: "Total Sent",
                        value: "\(viewModel.totalSent)",
                        change: viewModel.sentChange,
                        icon: "paperplane.fill",
                        color: .blue
                    )

                    NotificationMetricCard(
                        title: "Delivered",
                        value: "\(viewModel.deliveryRate)%",
                        change: viewModel.deliveryChange,
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    NotificationMetricCard(
                        title: "Opened",
                        value: "\(viewModel.openRate)%",
                        change: viewModel.openChange,
                        icon: "envelope.open.fill",
                        color: .orange
                    )

                    NotificationMetricCard(
                        title: "Clicked",
                        value: "\(viewModel.clickRate)%",
                        change: viewModel.clickChange,
                        icon: "hand.tap.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Delivery Success Chart

    private var deliverySuccessChart: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Delivery Success Rate")
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(.horizontal)

            Chart(viewModel.deliveryData) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Rate", data.successRate)
                )
                .foregroundStyle(.green.gradient)
                .interpolationMethod(.catmullRom)
                .symbol(Circle().strokeBorder(lineWidth: 2))

                AreaMark(
                    x: .value("Date", data.date),
                    y: .value("Rate", data.successRate)
                )
                .foregroundStyle(.green.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let rate = value.as(Double.self) {
                            Text("\(Int(rate))%")
                        }
                    }
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.green.opacity(0.1), radius: 8, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Engagement Funnel

    private var engagementFunnelSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.brandPrimary)
                Text("Engagement Funnel")
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(.horizontal)

            VStack(spacing: Spacing.sm) {
                FunnelStage(
                    title: "Sent",
                    count: viewModel.totalSent,
                    percentage: 100,
                    color: .blue,
                    width: 1.0
                )

                FunnelStage(
                    title: "Delivered",
                    count: viewModel.delivered,
                    percentage: viewModel.deliveryRate,
                    color: .green,
                    width: Double(viewModel.deliveryRate) / 100.0
                )

                FunnelStage(
                    title: "Opened",
                    count: viewModel.opened,
                    percentage: viewModel.openRate,
                    color: .orange,
                    width: Double(viewModel.openRate) / 100.0
                )

                FunnelStage(
                    title: "Clicked",
                    count: viewModel.clicked,
                    percentage: viewModel.clickRate,
                    color: .purple,
                    width: Double(viewModel.clickRate) / 100.0
                )
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: AppShadow.sm, radius: 8, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Send Time Analysis

    private var sendTimeAnalysisChart: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("Best Time to Send")
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(.horizontal)

            Chart(viewModel.hourlyPerformance) { data in
                BarMark(
                    x: .value("Hour", data.hour),
                    y: .value("Open Rate", data.openRate)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: 3)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour):00")
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let rate = value.as(Double.self) {
                            Text("\(Int(rate))%")
                        }
                    }
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.orange.opacity(0.1), radius: 8, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Platform Distribution

    private var platformDistributionChart: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "apps.iphone")
                    .foregroundColor(.blue)
                Text("Device Platforms")
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(.horizontal)

            Chart(viewModel.platformData) { platform in
                SectorMark(
                    angle: .value("Count", platform.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Platform", platform.name))
                .cornerRadius(4)
            }
            .frame(height: 250)
            .chartForegroundStyleScale([
                "iOS": .blue,
                "Android": .green,
                "Web": .orange
            ])
            .chartLegend(position: .bottom, spacing: Spacing.md)
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: AppShadow.sm, radius: 8, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Recent Notifications

    private var recentNotificationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent Notifications")
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal)

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.recentNotifications) { notification in
                    NotificationPerformanceRow(notification: notification)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views

struct NotificationMetricCard: View {
    let title: String
    let value: String
    let change: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Spacer()

                Text(change)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(changeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(changeColor.opacity(0.15))
                    .cornerRadius(CornerRadius.sm)
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .padding()
        .frame(width: 160)
        .background(
            LinearGradient(
                colors: [color.opacity(0.08), color.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.15), radius: 8, y: 4)
    }

    private var changeColor: Color {
        if change.hasPrefix("+") { return .green }
        if change.hasPrefix("-") { return .red }
        return .gray
    }
}

struct FunnelStage: View {
    let title: String
    let count: Int
    let percentage: Int
    let color: Color
    let width: Double

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(color)

                Text("(\(percentage)%)")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * width)
                        .cornerRadius(6)

                    Spacer()
                }
            }
            .frame(height: 32)
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct NotificationPerformanceRow: View {
    let notification: NotificationPerformance

    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(notification.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: notification.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Text(notification.sentDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 10))
                    Text("\(notification.openRate)%")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.orange)

                Text("\(notification.sent) sent")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 4, y: 2)
    }
}

// MARK: - Data Models

enum NotificationPeriod: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
}

struct DeliverySuccessData: Identifiable {
    let id = UUID()
    let date: Date
    let successRate: Double
    let failureRate: Double
}

struct HourlyPerformanceData: Identifiable {
    let id = UUID()
    let hour: Int
    let openRate: Double
    let clickRate: Double
}

struct PlatformData: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let percentage: Double
}

struct NotificationPerformance: Identifiable {
    let id = UUID()
    let title: String
    let sentDate: Date
    let sent: Int
    let delivered: Int
    let opened: Int
    let clicked: Int
    let icon: String
    let color: Color

    var deliveryRate: Int {
        sent > 0 ? (delivered * 100) / sent : 0
    }

    var openRate: Int {
        delivered > 0 ? (opened * 100) / delivered : 0
    }

    var clickRate: Int {
        opened > 0 ? (clicked * 100) / opened : 0
    }
}

// MARK: - View Model (extracted to Core/More/ViewModels/NotificationsAnalyticsViewModel.swift)

#Preview {
    NavigationView {
        NotificationsAnalyticsView()
    }
}
