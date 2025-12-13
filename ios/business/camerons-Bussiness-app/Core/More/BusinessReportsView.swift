//
//  BusinessReportsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/19/25.
//

import SwiftUI
import Charts
import Combine

// MARK: - Business Reports View Model (extracted to Core/More/ViewModels/BusinessReportsViewModel.swift)

// MARK: - Data Models

struct RevenueDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let revenue: Double
    let orders: Int
    let averageOrderValue: Double
}

struct CategoryPerformance: Identifiable {
    let id = UUID()
    let category: String
    let revenue: Double
    let orders: Int
    let color: Color
}

struct PeakHourData: Identifiable {
    let id = UUID()
    let hour: Int
    let orders: Int
    let revenue: Double

    var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    var intensity: Double {
        return Double(orders) / 45.0 // Normalize to 0-1 range (max expected orders per hour)
    }
}

struct OrderFrequencyData: Identifiable {
    let id = UUID()
    let frequency: String
    let count: Int
    let percentage: Double
}

struct MenuItemTrend: Identifiable {
    let id = UUID()
    let name: String
    let orders: Int
    let revenue: Double
    let trend: Double // Percentage change
    let rank: Int
}

struct PaymentMethodData: Identifiable {
    let id = UUID()
    let method: String
    let count: Int
    let percentage: Double
    let color: Color
}

enum ReportPeriod: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"

    var apiValue: String {
        switch self {
        case .today: return "today"
        case .week: return "week"
        case .month: return "month"
        }
    }
}

// MARK: - Business Reports View

struct BusinessReportsView: View {
    @StateObject private var viewModel = BusinessReportsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Period Picker
                    periodPicker

                    // Key Metrics Cards
                    keyMetricsSection

                    // Revenue Trend Chart
                    revenueTrendSection

                    // Category Performance
                    categoryPerformanceSection

                    // Peak Hours Analysis
                    peakHoursSection

                    // Order Frequency Distribution
                    orderFrequencySection

                    // Top Menu Items
                    topMenuItemsSection

                    // Payment Methods
                    paymentMethodsSection
                }
                .padding(.vertical)
            }
            .background(Color.surface)
            .navigationTitle("Business Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.textSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Export report as PDF
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.semibold))
                    }
                }
            }
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(ReportPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: viewModel.selectedPeriod) { newPeriod in
            viewModel.changePeriod(newPeriod)
        }
    }

    // MARK: - Key Metrics Section

    private var keyMetricsSection: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                ReportsMetricCard(
                    title: "Total Revenue",
                    value: String(format: "$%.0f", viewModel.totalRevenue),
                    change: viewModel.revenueChange,
                    icon: "dollarsign.circle.fill",
                    color: .green
                )

                ReportsMetricCard(
                    title: "Total Orders",
                    value: "\(viewModel.totalOrders)",
                    change: viewModel.ordersChange,
                    icon: "cart.fill",
                    color: .blue
                )
            }

            HStack(spacing: Spacing.md) {
                ReportsMetricCard(
                    title: "Avg Order Value",
                    value: String(format: "$%.2f", viewModel.averageOrderValue),
                    change: viewModel.aovChange,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )

                ReportsMetricCard(
                    title: "Top Category",
                    value: viewModel.topCategory,
                    subtitle: String(format: "$%.0f", viewModel.topCategoryRevenue),
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Revenue Trend Section

    private var revenueTrendSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Revenue Trend")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Chart(viewModel.revenueByDay) { dataPoint in
                    BarMark(
                        x: .value("Date", dataPoint.date, unit: .day),
                        y: .value("Revenue", dataPoint.revenue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(CornerRadius.sm)
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                VStack(alignment: .leading) {
                                    Text(date, format: .dateTime.day())
                                        .font(.caption2)
                                    Text(date, format: .dateTime.month(.abbreviated))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let revenue = value.as(Double.self) {
                                Text("$\(Int(revenue))")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Category Performance Section

    private var categoryPerformanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Category Performance")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Chart(viewModel.categoryPerformance) { category in
                    BarMark(
                        x: .value("Revenue", category.revenue),
                        y: .value("Category", category.category)
                    )
                    .foregroundStyle(category.color.gradient)
                    .cornerRadius(CornerRadius.sm)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(String(format: "$%.0f", category.revenue))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textSecondary)
                            .padding(.leading, 4)
                    }
                }
                .frame(height: 300)
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisValueLabel {
                            if let revenue = value.as(Double.self) {
                                Text("$\(Int(revenue))")
                                    .font(.caption)
                            }
                        }
                    }
                }

                // Category details
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.categoryPerformance.prefix(3)) { category in
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 12, height: 12)

                            Text(category.category)
                                .font(AppFonts.body)
                                .foregroundColor(.textPrimary)

                            Spacer()

                            Text("\(category.orders) orders")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)

                            Text(String(format: "$%.0f", category.revenue))
                                .font(AppFonts.body.weight(.semibold))
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
                .padding(.top, Spacing.sm)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Peak Hours Section

    private var peakHoursSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Peak Hours Analysis")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Chart(viewModel.peakHoursData) { data in
                    BarMark(
                        x: .value("Hour", data.hourString),
                        y: .value("Orders", data.orders)
                    )
                    .foregroundStyle(
                        data.orders > 30 ? Color.red.gradient :
                        data.orders > 20 ? Color.orange.gradient :
                        Color.blue.gradient
                    )
                    .cornerRadius(CornerRadius.sm)
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let orders = value.as(Int.self) {
                                Text("\(orders)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 3)) { value in
                        AxisValueLabel {
                            if let index = value.as(Int.self), index < viewModel.peakHoursData.count {
                                Text(viewModel.peakHoursData[index].hourString)
                                    .font(.caption2)
                            }
                        }
                    }
                }

                // Peak hours legend
                HStack(spacing: Spacing.lg) {
                    LegendItem(color: .red, label: "High (30+)")
                    LegendItem(color: .orange, label: "Medium (20-30)")
                    LegendItem(color: .blue, label: "Low (<20)")
                }
                .padding(.top, Spacing.sm)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Order Frequency Section

    private var orderFrequencySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Customer Order Frequency")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Chart(viewModel.orderFrequency) { data in
                    SectorMark(
                        angle: .value("Count", data.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Frequency", data.frequency))
                    .cornerRadius(CornerRadius.sm)
                }
                .frame(height: 250)
                .chartLegend(position: .bottom, alignment: .center)

                // Frequency details
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.orderFrequency) { freq in
                        HStack {
                            Text(freq.frequency)
                                .font(AppFonts.body)
                                .foregroundColor(.textPrimary)

                            Spacer()

                            Text("\(freq.count) customers")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)

                            Text(String(format: "%.0f%%", freq.percentage * 100))
                                .font(AppFonts.body.weight(.semibold))
                                .foregroundColor(.textPrimary)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, Spacing.sm)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Top Menu Items Section

    private var topMenuItemsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Top Menu Items")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(spacing: Spacing.xs) {
                ForEach(viewModel.menuItemTrends.prefix(10)) { item in
                    TopMenuItemRow(item: item)
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Payment Methods Section

    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Payment Methods")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.lg) {
                    // Donut chart
                    Chart(viewModel.paymentMethods) { payment in
                        SectorMark(
                            angle: .value("Count", payment.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(payment.color.gradient)
                        .cornerRadius(CornerRadius.sm)
                    }
                    .frame(width: 140, height: 140)

                    // Payment method details
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(viewModel.paymentMethods) { payment in
                            HStack(spacing: Spacing.sm) {
                                Circle()
                                    .fill(payment.color)
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(payment.method)
                                        .font(AppFonts.body)
                                        .foregroundColor(.textPrimary)

                                    Text("\(payment.count) transactions")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.textSecondary)
                                }

                                Spacer()

                                Text(String(format: "%.0f%%", payment.percentage * 100))
                                    .font(AppFonts.body.weight(.semibold))
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views

struct ReportsMetricCard: View {
    let title: String
    let value: String
    var change: Double? = nil
    var subtitle: String? = nil
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Spacer()

                if let change = change {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.bold))
                        Text(String(format: "%.1f%%", abs(change)))
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(change >= 0 ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        (change >= 0 ? Color.green : Color.red).opacity(0.1)
                    )
                    .cornerRadius(4)
                }
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            } else {
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [color.opacity(0.08), color.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(CornerRadius.lg)
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

struct TopMenuItemRow: View {
    let item: MenuItemTrend

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("#\(item.rank)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(rankColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(AppFonts.body)
                    .foregroundColor(.textPrimary)

                HStack(spacing: Spacing.sm) {
                    Text("\(item.orders) orders")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)

                    Text("•")
                        .foregroundColor(.textSecondary)

                    Text(String(format: "$%.0f", item.revenue))
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            // Trend indicator
            HStack(spacing: 2) {
                Image(systemName: item.trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption.weight(.bold))
                Text(String(format: "%.0f%%", abs(item.trend)))
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(item.trend >= 0 ? .green : .red)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                (item.trend >= 0 ? Color.green : Color.red).opacity(0.1)
            )
            .cornerRadius(4)
        }
        .padding(.vertical, Spacing.xs)
    }

    private var rankColor: Color {
        switch item.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

#Preview {
    BusinessReportsView()
}
