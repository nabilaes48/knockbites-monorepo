//
//  AnalyticsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//
//  Enhanced with SwiftUI Charts
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var appError: AppError?

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    LoadingStateView(message: "Loading analytics...")
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Period Selector
                            PeriodSelector(selection: $viewModel.currentPeriod)
                                .padding(.horizontal)

                            // Quick Stats
                            QuickStatsSection(stats: viewModel.quickStats)
                                .padding(.horizontal)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.currentPeriod)

                            // Revenue Chart
                            if !viewModel.revenueData.isEmpty {
                                RevenueChartSection(data: viewModel.revenueData, period: viewModel.currentPeriod)
                                    .padding(.horizontal)
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentPeriod)
                            }

                            // Top Items
                            if !viewModel.topItems.isEmpty {
                                TopItemsSection(items: viewModel.topItems)
                                    .padding(.horizontal)
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentPeriod)
                            }

                            // Order Types Distribution
                            if !viewModel.orderTypes.isEmpty {
                                OrderTypesSection(data: viewModel.orderTypes)
                                    .padding(.horizontal)
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentPeriod)
                            }

                            // Kitchen Quality Metrics
                            KitchenQualitySection(metrics: viewModel.qualityMetrics)
                                .padding(.horizontal)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.currentPeriod)
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        viewModel.loadAnalytics(for: viewModel.currentPeriod)
                    }
                }
            }
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.loadAnalytics(for: viewModel.currentPeriod) }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .appErrorAlert(error: $appError) {
                viewModel.loadAnalytics(for: viewModel.currentPeriod)
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if let message = newValue {
                    appError = AppError.from(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
                    viewModel.errorMessage = nil
                }
            }
        }
        .onAppear {
            viewModel.loadAnalytics(for: viewModel.currentPeriod)
        }
    }
}

// MARK: - Period Selector
enum TimePeriod: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
}

struct PeriodSelector: View {
    @Binding var selection: TimePeriod

    var body: some View {
        Picker("Period", selection: $selection) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Quick Stats
struct QuickStatsSection: View {
    let stats: QuickStats

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Overview")
                .font(AppFonts.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                AnalyticsStatCard(
                    icon: "dollarsign.circle.fill",
                    title: "Revenue",
                    value: "$\(String(format: "%.0f", stats.revenue))",
                    change: stats.revenueChange,
                    color: .success
                )

                AnalyticsStatCard(
                    icon: "bag.fill",
                    title: "Orders",
                    value: "\(stats.ordersCount)",
                    change: "+\(stats.ordersChange)",
                    color: .brandPrimary
                )

                AnalyticsStatCard(
                    icon: "person.fill",
                    title: "Customers",
                    value: "\(stats.customersCount)",
                    change: "+\(stats.customersChange)",
                    color: .warning
                )

                AnalyticsStatCard(
                    icon: "clock.fill",
                    title: "Avg Time",
                    value: "\(stats.avgPrepTime) min",
                    change: "\(stats.timeChange) min",
                    color: .info
                )
            }
        }
    }
}

struct AnalyticsStatCard: View {
    let icon: String
    let title: String
    let value: String
    let change: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text(change)
                    .font(AppFonts.caption)
                    .foregroundColor(.success)
            }

            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)

            Text(value)
                .font(AppFonts.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 4)
    }
}

struct QuickStats {
    let revenue: Double
    let revenueChange: String
    let ordersCount: Int
    let ordersChange: Int
    let customersCount: Int
    let customersChange: Int
    let avgPrepTime: Int
    let timeChange: Int
}

// MARK: - Revenue Chart Section
struct RevenueChartSection: View {
    let data: [ChartDataPoint]
    let period: TimePeriod

    private var chartTitle: String {
        switch period {
        case .today:
            return "Today's Hourly Revenue"
        case .week:
            return "Weekly Revenue Trend"
        case .month:
            return "Monthly Revenue by Week"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(chartTitle)
                .font(AppFonts.headline)

            VStack(spacing: Spacing.sm) {
                ForEach(data) { point in
                    HStack {
                        Text(point.label)
                            .font(AppFonts.caption)
                            .frame(width: 60, alignment: .leading)

                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(LinearGradient(
                                        colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(width: geometry.size.width * CGFloat(point.percentage))
                                    .cornerRadius(4)

                                Spacer()
                            }
                        }
                        .frame(height: 24)

                        Text(point.formattedValue)
                            .font(AppFonts.caption)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: AppShadow.sm, radius: 4)
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let percentage: Double

    var formattedValue: String {
        "$\(String(format: "%.0f", value))"
    }
}

// MARK: - Top Items Section
struct TopItemsSection: View {
    let items: [PopularItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Top Sellers")
                .font(AppFonts.headline)

            VStack(spacing: Spacing.sm) {
                ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, item in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.brandPrimary.opacity(0.1))
                                .frame(width: 32, height: 32)

                            Text("#\(index + 1)")
                                .font(AppFonts.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.brandPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.menuItem.name)
                                .font(AppFonts.body)
                                .foregroundColor(.textPrimary)

                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "bag.fill")
                                    .font(.system(size: 10))
                                Text("\(item.orderCount) orders")

                                Text("•")

                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 10))
                                Text(item.formattedRevenue)
                            }
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "star.fill")
                            .foregroundColor(.warning)
                            .font(.system(size: 20))
                    }
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.md)
                    .shadow(color: AppShadow.sm, radius: 2, y: 1)
                }
            }
        }
    }
}

// MARK: - Order Types Section
struct OrderTypesSection: View {
    let data: [OrderTypeData]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Order Distribution")
                .font(AppFonts.headline)

            VStack(spacing: Spacing.md) {
                ForEach(data) { orderType in
                    VStack(spacing: Spacing.sm) {
                        HStack {
                            Image(systemName: orderType.icon)
                                .foregroundColor(orderType.color)
                                .frame(width: 24)

                            Text(orderType.type)
                                .font(AppFonts.body)

                            Spacer()

                            Text("\(orderType.count) orders")
                                .font(AppFonts.subheadline)
                                .foregroundColor(.textSecondary)

                            Text("\(Int(orderType.percentage * 100))%")
                                .font(AppFonts.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(orderType.color)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.surfaceSecondary)
                                    .frame(height: 8)
                                    .cornerRadius(4)

                                Rectangle()
                                    .fill(orderType.color)
                                    .frame(width: geometry.size.width * orderType.percentage, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.md)
                    .shadow(color: AppShadow.sm, radius: 2, y: 1)
                }
            }
        }
    }
}

struct OrderTypeData: Identifiable {
    let id = UUID()
    let type: String
    let icon: String
    let count: Int
    let percentage: Double
    let color: Color
}

// MARK: - Kitchen Quality Section
struct KitchenQualitySection: View {
    let metrics: KitchenQualityMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.brandPrimary)
                Text("Kitchen Performance")
                    .font(AppFonts.headline)
            }

            // Quality Score Card
            VStack(spacing: Spacing.md) {
                // Overall Quality Score
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Quality Score")
                            .font(AppFonts.subheadline)
                            .foregroundColor(.textSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(metrics.qualityScore)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(qualityColor(for: metrics.qualityScore))

                            Text("/ 100")
                                .font(AppFonts.title3)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    // Quality Badge
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: qualityBadgeIcon(for: metrics.qualityScore))
                            .font(.system(size: 40))
                            .foregroundColor(qualityColor(for: metrics.qualityScore))

                        Text(qualityLabel(for: metrics.qualityScore))
                            .font(AppFonts.caption)
                            .fontWeight(.bold)
                            .foregroundColor(qualityColor(for: metrics.qualityScore))
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 4)
                            .background(qualityColor(for: metrics.qualityScore).opacity(0.15))
                            .cornerRadius(CornerRadius.sm)
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [qualityColor(for: metrics.qualityScore).opacity(0.1), Color.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .strokeBorder(qualityColor(for: metrics.qualityScore).opacity(0.3), lineWidth: 2)
                )

                // Metrics Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                    QualityMetricCard(
                        icon: "checkmark.circle.fill",
                        title: "On-Time",
                        value: "\(metrics.onTimePercentage)%",
                        subtitle: "\(metrics.onTimeCount)/\(metrics.totalOrders) orders",
                        color: .success
                    )

                    QualityMetricCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "Late Orders",
                        value: "\(metrics.lateOrdersCount)",
                        subtitle: "\(metrics.latePercentage)% of total",
                        color: .error
                    )

                    QualityMetricCard(
                        icon: "clock.badge.checkmark.fill",
                        title: "Avg vs Est",
                        value: metrics.avgVariance >= 0 ? "+\(metrics.avgVariance)m" : "\(metrics.avgVariance)m",
                        subtitle: metrics.avgVariance >= 0 ? "Over estimate" : "Under estimate",
                        color: metrics.avgVariance > 5 ? .warning : .info
                    )

                    QualityMetricCard(
                        icon: "timer",
                        title: "Avg Actual",
                        value: "\(metrics.avgActualTime)m",
                        subtitle: "vs \(metrics.avgEstimatedTime)m est",
                        color: .brandPrimary
                    )
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: AppShadow.sm, radius: 4)
        }
    }

    private func qualityColor(for score: Int) -> Color {
        if score >= 90 { return .success }
        if score >= 75 { return .info }
        if score >= 60 { return .warning }
        return .error
    }

    private func qualityLabel(for score: Int) -> String {
        if score >= 90 { return "Excellent" }
        if score >= 75 { return "Good" }
        if score >= 60 { return "Fair" }
        return "Needs Work"
    }

    private func qualityBadgeIcon(for score: Int) -> String {
        if score >= 90 { return "star.circle.fill" }
        if score >= 75 { return "checkmark.seal.fill" }
        if score >= 60 { return "exclamationmark.circle.fill" }
        return "xmark.circle.fill"
    }
}

struct QualityMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }

            Text(value)
                .font(AppFonts.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)

            Text(subtitle)
                .font(AppFonts.caption2)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.surfaceSecondary)
        .cornerRadius(CornerRadius.sm)
    }
}

struct KitchenQualityMetrics {
    let qualityScore: Int
    let onTimePercentage: Int
    let onTimeCount: Int
    let totalOrders: Int
    let lateOrdersCount: Int
    let latePercentage: Int
    let avgActualTime: Int
    let avgEstimatedTime: Int
    let avgVariance: Int
}

// MARK: - View Model (extracted to Core/Analytics/ViewModels/AnalyticsViewModel.swift)

#Preview {
    AnalyticsView()
}
