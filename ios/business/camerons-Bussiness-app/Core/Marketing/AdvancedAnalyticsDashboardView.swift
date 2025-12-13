//
//  AdvancedAnalyticsDashboardView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI
import Charts

struct AdvancedAnalyticsDashboardView: View {
    @StateObject private var viewModel = AdvancedAnalyticsViewModel()
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @State private var showExportOptions = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // MARK: - Period Selector
                MarketingPeriodSelector(selectedPeriod: $selectedPeriod)
                    .padding(.horizontal)
                    .onChange(of: selectedPeriod) { _ in
                        viewModel.loadAnalytics(period: selectedPeriod)
                    }

                // MARK: - Key Metrics Summary
                keyMetricsSummary

                // MARK: - Revenue Trend Chart
                revenueTrendSection

                // MARK: - Loyalty Points Activity
                pointsActivitySection

                // MARK: - Tier Distribution Chart
                tierDistributionSection

                // MARK: - Top Rewards Performance
                topRewardsSection

                // MARK: - Campaign Performance Comparison
                campaignPerformanceSection

                // MARK: - Customer Engagement Trend
                engagementTrendSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Advanced Analytics")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showExportOptions = true }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                }
            }
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(
                exportType: .advancedAnalytics,
                onExport: { format, options in
                    try await exportReport(format: format, options: options)
                }
            )
        }
        .onAppear {
            viewModel.loadAnalytics(period: selectedPeriod)
        }
        .refreshable {
            viewModel.loadAnalytics(period: selectedPeriod)
        }
    }

    // MARK: - Export Function

    private func exportReport(format: ExportFormat, options: ExportOptions) async throws -> URL {
        switch format {
        case .pdf:
            let exporter = ReportExporter()
            return try await exporter.exportAdvancedAnalyticsToPDF(
                period: selectedPeriod,
                viewModel: viewModel
            )

        case .csv:
            let exporter = ExcelExporter()
            let metrics = MarketingMetrics(
                notificationsSent: 0,
                notificationsChange: 0,
                couponsRedeemed: 0,
                couponsChange: 0,
                loyaltyMembers: viewModel.activeMembers,
                loyaltyMembersChange: viewModel.memberChange,
                pointsAwarded: viewModel.pointsAwarded,
                campaignROI: 0,
                averageLTV: 0,
                acquisitionCost: 0
            )
            return try await exporter.exportMarketingAnalyticsToCSV(
                period: selectedPeriod,
                metrics: metrics
            )
        }
    }

    // MARK: - Key Metrics Summary

    private var keyMetricsSummary: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Overview")
                .font(AppFonts.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    SummaryMetricCard(
                        title: "Total Revenue",
                        value: String(format: "$%.0f", viewModel.totalRevenue),
                        change: viewModel.revenueChange,
                        icon: "dollarsign.circle.fill",
                        color: .success
                    )

                    SummaryMetricCard(
                        title: "Active Members",
                        value: "\(viewModel.activeMembers)",
                        change: viewModel.memberChange,
                        icon: "person.2.fill",
                        color: .brandPrimary
                    )

                    SummaryMetricCard(
                        title: "Points Awarded",
                        value: "\(viewModel.pointsAwarded)",
                        change: viewModel.pointsChange,
                        icon: "star.fill",
                        color: .warning
                    )

                    SummaryMetricCard(
                        title: "Redemptions",
                        value: "\(viewModel.totalRedemptions)",
                        change: viewModel.redemptionsChange,
                        icon: "gift.fill",
                        color: .info
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Revenue Trend Section

    private var revenueTrendSection: some View {
        ChartSection(title: "Revenue Trend", icon: "chart.line.uptrend.xyaxis") {
            Chart(viewModel.revenueTrend) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Revenue", data.value)
                )
                .foregroundStyle(.green.gradient)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", data.date),
                    y: .value("Revenue", data.value)
                )
                .foregroundStyle(.green.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: viewModel.dateStride)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let revenue = value.as(Double.self) {
                            Text("$\(Int(revenue))")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Points Activity Section

    private var pointsActivitySection: some View {
        ChartSection(title: "Loyalty Points Activity", icon: "star.circle.fill") {
            Chart {
                ForEach(viewModel.pointsActivity) { data in
                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Points", data.awarded)
                    )
                    .foregroundStyle(.orange)
                    .position(by: .value("Type", "Awarded"))

                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Points", -data.redeemed)
                    )
                    .foregroundStyle(.purple)
                    .position(by: .value("Type", "Redeemed"))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: viewModel.dateStride))
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let points = value.as(Int.self) {
                            Text("\(abs(points))")
                        }
                    }
                }
            }
            .chartForegroundStyleScale([
                "Awarded": Color.orange,
                "Redeemed": Color.purple
            ])
        }
    }

    // MARK: - Tier Distribution Section

    private var tierDistributionSection: some View {
        ChartSection(title: "Member Tier Distribution", icon: "crown.fill") {
            VStack(spacing: Spacing.md) {
                // Pie Chart
                Chart(viewModel.tierDistribution) { tier in
                    SectorMark(
                        angle: .value("Count", tier.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Tier", tier.name))
                    .annotation(position: .overlay) {
                        if tier.percentage > 10 {
                            Text("\(Int(tier.percentage))%")
                                .font(AppFonts.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 250)
                .chartForegroundStyleScale([
                    "Bronze": Color(hex: "#CD7F32") ?? .orange,
                    "Silver": Color(hex: "#C0C0C0") ?? .gray,
                    "Gold": Color(hex: "#FFD700") ?? .yellow,
                    "Platinum": Color(hex: "#E5E4E2") ?? .purple
                ])
                .chartLegend(position: .bottom, alignment: .center)

                // Bar Chart
                Chart(viewModel.tierDistribution) { tier in
                    BarMark(
                        x: .value("Tier", tier.name),
                        y: .value("Members", tier.count)
                    )
                    .foregroundStyle(by: .value("Tier", tier.name))
                    .annotation(position: .top) {
                        Text("\(tier.count)")
                            .font(AppFonts.caption)
                            .fontWeight(.semibold)
                    }
                }
                .frame(height: 150)
                .chartForegroundStyleScale([
                    "Bronze": Color(hex: "#CD7F32") ?? .orange,
                    "Silver": Color(hex: "#C0C0C0") ?? .gray,
                    "Gold": Color(hex: "#FFD700") ?? .yellow,
                    "Platinum": Color(hex: "#E5E4E2") ?? .purple
                ])
                .chartLegend(.hidden)
            }
        }
    }

    // MARK: - Top Rewards Section

    private var topRewardsSection: some View {
        ChartSection(title: "Top Performing Rewards", icon: "gift.fill") {
            Chart(viewModel.topRewards) { reward in
                BarMark(
                    x: .value("Redemptions", reward.redemptions),
                    y: .value("Reward", reward.name)
                )
                .foregroundStyle(.blue.gradient)
                .annotation(position: .trailing) {
                    Text("\(reward.redemptions)")
                        .font(AppFonts.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(height: CGFloat(viewModel.topRewards.count) * 50)
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
        }
    }

    // MARK: - Campaign Performance Section

    private var campaignPerformanceSection: some View {
        ChartSection(title: "Campaign Performance", icon: "megaphone.fill") {
            Chart(viewModel.campaignPerformance) { campaign in
                BarMark(
                    x: .value("Campaign", campaign.name),
                    y: .value("Conversions", campaign.conversions)
                )
                .foregroundStyle(by: .value("Type", campaign.type))
                .annotation(position: .top) {
                    VStack(spacing: 2) {
                        Text("\(campaign.conversions)")
                            .font(AppFonts.caption2)
                            .fontWeight(.bold)
                        Text("\(Int(campaign.roi))% ROI")
                            .font(AppFonts.caption2)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
            .chartForegroundStyleScale([
                "Notification": Color.brandPrimary,
                "Coupon": Color.success,
                "Reward": Color.warning
            ])
            .chartLegend(position: .bottom, alignment: .center)
        }
    }

    // MARK: - Engagement Trend Section

    private var engagementTrendSection: some View {
        ChartSection(title: "Customer Engagement", icon: "chart.bar.fill") {
            Chart(viewModel.engagementTrend) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Active Users", data.activeUsers)
                )
                .foregroundStyle(.blue)
                .symbol(Circle())

                PointMark(
                    x: .value("Date", data.date),
                    y: .value("Active Users", data.activeUsers)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: viewModel.dateStride))
            }
            .chartYAxis {
                AxisMarks()
            }
        }
    }
}

// MARK: - Summary Metric Card

struct SummaryMetricCard: View {
    let title: String
    let value: String
    let change: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(String(format: "%.1f%%", abs(change)))
                }
                .font(AppFonts.caption)
                .fontWeight(.semibold)
                .foregroundColor(change >= 0 ? .success : .error)
            }

            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)

            Text(value)
                .font(AppFonts.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(width: 160)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: AppShadow.sm, radius: 4)
    }
}

// MARK: - Chart Section

struct ChartSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.brandPrimary)
                Text(title)
                    .font(AppFonts.title3)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)

            content
                .padding()
                .background(Color.surface)
                .cornerRadius(CornerRadius.lg)
                .shadow(color: AppShadow.sm, radius: 4)
                .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationView {
        AdvancedAnalyticsDashboardView()
    }
}
