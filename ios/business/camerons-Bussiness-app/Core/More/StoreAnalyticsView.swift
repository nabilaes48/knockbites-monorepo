//
//  StoreAnalyticsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/19/25.
//

import SwiftUI
import Charts
import Combine

// MARK: - Store Analytics View Model (extracted to Core/More/ViewModels/StoreAnalyticsViewModel.swift)

// MARK: - Data Models

enum StorePeriod: String, CaseIterable {
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

struct DailyPerformanceData: Identifiable {
    let id = UUID()
    let date: Date
    let orders: Int
    let revenue: Double
    let rating: Double
    let fulfillmentTime: Double
}

struct FulfillmentTimeData: Identifiable {
    let id = UUID()
    let range: String
    let count: Int
    let percentage: Double
}

struct StaffEfficiencyData: Identifiable {
    let id = UUID()
    let name: String
    let ordersProcessed: Int
    let avgProcessingTime: Double
    let rating: Double
    let efficiency: Double
}

struct CapacityData: Identifiable {
    let id = UUID()
    let hour: Int
    let utilization: Double
    let maxCapacity: Int
    let currentOrders: Int

    var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}

struct SatisfactionData: Identifiable {
    let id = UUID()
    let date: Date
    let rating: Double
    let reviews: Int
    let positivePercentage: Double
}

struct StoreComparisonData: Identifiable {
    let id = UUID()
    let storeName: String
    let orders: Int
    let revenue: Double
    let rating: Double
    let avgFulfillment: Double
    let color: Color
}

struct OperatingHourData: Identifiable {
    let id = UUID()
    let day: String
    let avgOrders: Int
    let avgRevenue: Double
    let peakHour: Int
    let efficiency: Double
}

// MARK: - Store Analytics View

struct StoreAnalyticsView: View {
    @StateObject private var viewModel = StoreAnalyticsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Period Picker
                    periodPicker

                    // Key Store Metrics
                    keyMetricsSection

                    // Daily Performance Trend
                    dailyPerformanceSection

                    // Order Fulfillment Times
                    fulfillmentTimesSection

                    // Staff Efficiency
                    staffEfficiencySection

                    // Capacity Utilization
                    capacityUtilizationSection

                    // Customer Satisfaction Trend
                    customerSatisfactionSection

                    // Multi-Store Comparison
                    storeComparisonSection

                    // Operating Hours Performance
                    operatingHoursSection
                }
                .padding(.vertical)
            }
            .background(Color.surface)
            .navigationTitle("Store Analytics")
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
                        // TODO: Export analytics
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
            ForEach(StorePeriod.allCases, id: \.self) { period in
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
                AnalyticsMetricCard(
                    title: "Store Rating",
                    value: String(format: "%.1f", viewModel.storeRating),
                    change: viewModel.ratingChange,
                    icon: "star.fill",
                    color: .yellow,
                    suffix: "⭐"
                )

                AnalyticsMetricCard(
                    title: "Avg Fulfillment",
                    value: String(format: "%.0f", viewModel.orderFulfillmentTime),
                    change: -viewModel.fulfillmentChange, // Negative is good for time
                    icon: "clock.fill",
                    color: .blue,
                    suffix: "min"
                )
            }

            HStack(spacing: Spacing.md) {
                AnalyticsMetricCard(
                    title: "Active Staff",
                    value: "\(viewModel.activeStaff)",
                    icon: "person.3.fill",
                    color: .purple,
                    suffix: ""
                )

                AnalyticsMetricCard(
                    title: "Capacity",
                    value: String(format: "%.0f%%", viewModel.capacityUtilization * 100),
                    icon: "chart.bar.fill",
                    color: viewModel.capacityUtilization > 0.8 ? .red : .green,
                    suffix: ""
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Daily Performance Section

    private var dailyPerformanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Daily Performance")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Chart(viewModel.dailyPerformance) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Orders", data.orders)
                    )
                    .foregroundStyle(.blue.gradient)
                    .interpolationMethod(.catmullRom)
                    .symbol {
                        Circle()
                            .fill(.blue)
                            .frame(width: 6, height: 6)
                    }

                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Orders", data.orders)
                    )
                    .foregroundStyle(.blue.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 220)
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
                    AxisMarks(position: .leading)
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Fulfillment Times Section

    private var fulfillmentTimesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Order Fulfillment Times")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Chart(viewModel.fulfillmentTimes) { data in
                    BarMark(
                        x: .value("Count", data.count),
                        y: .value("Range", data.range)
                    )
                    .foregroundStyle(
                        data.range.contains("0-10") ? Color.green.gradient :
                        data.range.contains("10-15") ? Color.blue.gradient :
                        data.range.contains("15-20") ? Color.orange.gradient :
                        Color.red.gradient
                    )
                    .cornerRadius(CornerRadius.sm)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(data.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textSecondary)
                            .padding(.leading, 4)
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }

                // Performance indicator
                HStack(spacing: Spacing.md) {
                    LegendItem(color: .green, label: "Excellent (0-10m)")
                    LegendItem(color: .blue, label: "Good (10-15m)")
                    LegendItem(color: .orange, label: "Fair (15-20m)")
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

    // MARK: - Staff Efficiency Section

    private var staffEfficiencySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Staff Performance")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.staffEfficiency) { staff in
                    StaffEfficiencyRow(staff: staff)
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Capacity Utilization Section

    private var capacityUtilizationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Capacity Utilization")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Chart(viewModel.peakCapacity) { data in
                    BarMark(
                        x: .value("Hour", data.hourString),
                        y: .value("Utilization", data.utilization * 100)
                    )
                    .foregroundStyle(
                        data.utilization > 0.85 ? Color.red.gradient :
                        data.utilization > 0.70 ? Color.orange.gradient :
                        Color.green.gradient
                    )
                    .cornerRadius(CornerRadius.sm)
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let percent = value.as(Double.self) {
                                Text("\(Int(percent))%")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 3)) { value in
                        AxisValueLabel {
                            if let index = value.as(Int.self), index < viewModel.peakCapacity.count {
                                Text(viewModel.peakCapacity[index].hourString)
                                    .font(.caption2)
                            }
                        }
                    }
                }

                // Capacity legend
                HStack(spacing: Spacing.lg) {
                    LegendItem(color: .green, label: "Normal (<70%)")
                    LegendItem(color: .orange, label: "Busy (70-85%)")
                    LegendItem(color: .red, label: "At Capacity (>85%)")
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

    // MARK: - Customer Satisfaction Section

    private var customerSatisfactionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Customer Satisfaction")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Chart(viewModel.customerSatisfaction) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Rating", data.rating)
                    )
                    .foregroundStyle(.yellow.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 8, height: 8)
                    }

                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Rating", data.rating)
                    )
                    .foregroundStyle(.yellow.opacity(0.15).gradient)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartYScale(domain: 3.5...5.0)
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
                            if let rating = value.as(Double.self) {
                                Text(String(format: "%.1f", rating))
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

    // MARK: - Store Comparison Section

    private var storeComparisonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Multi-Store Comparison")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.storeComparison) { store in
                    StoreComparisonRow(store: store)
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }

    // MARK: - Operating Hours Section

    private var operatingHoursSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Day of Week Performance")
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Chart(viewModel.operatingHoursPerformance) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Revenue", data.avgRevenue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(CornerRadius.sm)
                }
                .frame(height: 220)
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
}

// MARK: - Supporting Views

struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    var change: Double? = nil
    let icon: String
    let color: Color
    let suffix: String

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

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }

            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)
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

struct StaffEfficiencyRow: View {
    let staff: StaffEfficiencyData

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(efficiencyColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text(String(staff.name.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(efficiencyColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(staff.name)
                    .font(AppFonts.body.weight(.semibold))
                    .foregroundColor(.textPrimary)

                HStack(spacing: Spacing.sm) {
                    Label("\(staff.ordersProcessed)", systemImage: "cart.fill")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    Label(String(format: "%.1fm", staff.avgProcessingTime), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", staff.rating))
                        .font(.body.weight(.semibold))
                        .foregroundColor(.textPrimary)
                }

                Text(String(format: "%.0f%% efficient", staff.efficiency * 100))
                    .font(.caption)
                    .foregroundColor(efficiencyColor)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var efficiencyColor: Color {
        staff.efficiency > 0.90 ? .green :
        staff.efficiency > 0.80 ? .blue : .orange
    }
}

struct StoreComparisonRow: View {
    let store: StoreComparisonData

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Circle()
                    .fill(store.color)
                    .frame(width: 12, height: 12)

                Text(store.storeName)
                    .font(AppFonts.body.weight(.semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", store.rating))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.textPrimary)
                }
            }

            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Orders")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text("\(store.orders)")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Revenue")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(String(format: "$%.0f", store.revenue))
                        .font(.body.weight(.semibold))
                        .foregroundColor(.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg Time")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(String(format: "%.0fm", store.avgFulfillment))
                        .font(.body.weight(.semibold))
                        .foregroundColor(.textPrimary)
                }

                Spacer()
            }
        }
        .padding()
        .background(store.color.opacity(0.05))
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    StoreAnalyticsView()
}
