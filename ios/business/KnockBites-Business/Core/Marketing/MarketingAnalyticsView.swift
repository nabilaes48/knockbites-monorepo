//
//  MarketingAnalyticsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct MarketingAnalyticsView: View {
    @StateObject private var viewModel = MarketingAnalyticsViewModel()
    @State private var selectedPeriod: AnalyticsPeriod = .week

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // MARK: - Period Selector
                    MarketingPeriodSelector(selectedPeriod: $selectedPeriod)
                        .onChange(of: selectedPeriod) { _ in
                            viewModel.loadAnalytics(period: selectedPeriod)
                        }

                    // MARK: - Marketing ROI Overview
                    MarketingROISection(
                        totalRevenue: viewModel.totalRevenue,
                        totalSpent: viewModel.totalSpent,
                        roi: viewModel.roi
                    )

                    // MARK: - Notification Performance
                    NotificationPerformanceSection(
                        totalSent: viewModel.notificationsSent,
                        deliveryRate: viewModel.notificationDeliveryRate,
                        openRate: viewModel.notificationOpenRate,
                        conversionRate: viewModel.notificationConversionRate
                    )

                    // MARK: - Coupon Performance
                    CouponPerformanceAnalyticsSection(
                        totalCoupons: viewModel.totalActiveCoupons,
                        redemptionRate: viewModel.couponRedemptionRate,
                        avgOrderValue: viewModel.avgOrderValueWithCoupon,
                        totalDiscount: viewModel.totalDiscountGiven
                    )

                    // MARK: - Loyalty Performance
                    LoyaltyPerformanceSection(
                        activeMembers: viewModel.activeLoyaltyMembers,
                        avgPoints: viewModel.avgPointsBalance,
                        tierDistribution: viewModel.tierDistribution
                    )

                    // MARK: - Top Performing Coupons
                    if !viewModel.topCoupons.isEmpty {
                        TopCouponsSection(coupons: viewModel.topCoupons)
                    }
                }
                .padding()
            }
            .navigationTitle("Marketing Analytics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadAnalytics(period: selectedPeriod)
            }
            .refreshable {
                viewModel.loadAnalytics(period: selectedPeriod)
            }
        }
    }
}

// MARK: - Period Selector

enum AnalyticsPeriod: String, CaseIterable {
    case week = "7 Days"
    case month = "30 Days"
    case all = "All Time"
}

struct MarketingPeriodSelector: View {
    @Binding var selectedPeriod: AnalyticsPeriod

    var body: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Marketing ROI Section

struct MarketingROISection: View {
    let totalRevenue: Double
    let totalSpent: Double
    let roi: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Marketing ROI")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            HStack(spacing: Spacing.md) {
                ROICard(
                    title: "Revenue Generated",
                    value: "$\(Int(totalRevenue))",
                    color: .success
                )

                ROICard(
                    title: "Marketing Spend",
                    value: "$\(Int(totalSpent))",
                    color: .error
                )

                ROICard(
                    title: "ROI",
                    value: "\(Int(roi))%",
                    color: roi > 0 ? .success : .error
                )
            }
        }
    }
}

struct ROICard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(AppFonts.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2)
    }
}

// MARK: - Notification Performance Section

struct NotificationPerformanceSection: View {
    let totalSent: Int
    let deliveryRate: Double
    let openRate: Double
    let conversionRate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Push Notifications")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            LazyVGrid(columns: [GridItem(), GridItem()], spacing: Spacing.md) {
                MetricCard(
                    icon: "paperplane.fill",
                    title: "Total Sent",
                    value: "\(totalSent)",
                    color: .brandPrimary
                )

                MetricCard(
                    icon: "checkmark.circle.fill",
                    title: "Delivery Rate",
                    value: "\(Int(deliveryRate))%",
                    color: .success
                )

                MetricCard(
                    icon: "eye.fill",
                    title: "Open Rate",
                    value: "\(Int(openRate))%",
                    color: .info
                )

                MetricCard(
                    icon: "cart.fill",
                    title: "Conversion",
                    value: "\(Int(conversionRate))%",
                    color: .warning
                )
            }
        }
    }
}

// MARK: - Coupon Performance Section

struct CouponPerformanceAnalyticsSection: View {
    let totalCoupons: Int
    let redemptionRate: Double
    let avgOrderValue: Double
    let totalDiscount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Coupons & Discounts")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            LazyVGrid(columns: [GridItem(), GridItem()], spacing: Spacing.md) {
                MetricCard(
                    icon: "ticket.fill",
                    title: "Active Coupons",
                    value: "\(totalCoupons)",
                    color: .brandPrimary
                )

                MetricCard(
                    icon: "percent",
                    title: "Redemption Rate",
                    value: "\(Int(redemptionRate))%",
                    color: .success
                )

                MetricCard(
                    icon: "dollarsign.circle.fill",
                    title: "Avg Order Value",
                    value: "$\(Int(avgOrderValue))",
                    color: .warning
                )

                MetricCard(
                    icon: "tag.fill",
                    title: "Total Discount",
                    value: "$\(Int(totalDiscount))",
                    color: .error
                )
            }
        }
    }
}

// MARK: - Loyalty Performance Section

struct LoyaltyPerformanceSection: View {
    let activeMembers: Int
    let avgPoints: Int
    let tierDistribution: [String: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Loyalty Program")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            HStack(spacing: Spacing.md) {
                MetricCard(
                    icon: "person.2.fill",
                    title: "Active Members",
                    value: "\(activeMembers)",
                    color: .brandPrimary
                )

                MetricCard(
                    icon: "star.fill",
                    title: "Avg Points",
                    value: "\(avgPoints)",
                    color: .warning
                )
            }

            // Tier Distribution
            if !tierDistribution.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Tier Distribution")
                        .font(AppFonts.subheadline)
                        .fontWeight(.semibold)

                    ForEach(Array(tierDistribution.keys.sorted()), id: \.self) { tier in
                        TierDistributionRow(
                            tierName: tier,
                            count: tierDistribution[tier] ?? 0,
                            total: activeMembers
                        )
                    }
                }
                .padding()
                .background(Color.surface)
                .cornerRadius(CornerRadius.md)
                .shadow(color: AppShadow.sm, radius: 2)
            }
        }
    }
}

struct TierDistributionRow: View {
    let tierName: String
    let count: Int
    let total: Int

    var percentage: Double {
        total > 0 ? (Double(count) / Double(total)) * 100 : 0
    }

    var body: some View {
        HStack {
            Text(tierName)
                .font(AppFonts.subheadline)

            Spacer()

            Text("\(count)")
                .font(AppFonts.subheadline)
                .fontWeight(.semibold)

            Text("(\(Int(percentage))%)")
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Top Coupons Section

struct TopCouponsSection: View {
    let coupons: [TopCoupon]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Top Performing Coupons")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            ForEach(coupons) { coupon in
                TopCouponCard(coupon: coupon)
            }
        }
    }
}

struct TopCouponCard: View {
    let coupon: TopCoupon

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(coupon.code)
                    .font(AppFonts.headline)
                    .fontWeight(.bold)

                Text(coupon.name)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text("\(coupon.uses) uses")
                    .font(AppFonts.subheadline)
                    .fontWeight(.semibold)

                Text("$\(Int(coupon.revenue)) revenue")
                    .font(AppFonts.caption)
                    .foregroundColor(.success)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2)
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)

            Text(value)
                .font(AppFonts.headline)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2)
    }
}

#Preview {
    MarketingAnalyticsView()
}
