//
//  MarketingDashboardView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

// MARK: - Marketing Dashboard Sheet State

enum MarketingSheet: Identifiable {
    case createNotification
    case createCoupon
    case createReward

    var id: String {
        switch self {
        case .createNotification: return "notification"
        case .createCoupon: return "coupon"
        case .createReward: return "reward"
        }
    }
}

// MARK: - Marketing Dashboard View

struct MarketingDashboardView: View {
    @StateObject private var viewModel = MarketingViewModel()
    @State private var activeSheet: MarketingSheet?
    @State private var appError: AppError?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // MARK: - Quick Actions
                    QuickActionsSection(
                        onNotificationTap: { activeSheet = .createNotification },
                        onCouponTap: { activeSheet = .createCoupon },
                        onRewardTap: { activeSheet = .createReward }
                    )

                    // MARK: - Analytics Quick Links
                    VStack(spacing: Spacing.md) {
                        MarketingAnalyticsQuickLink()
                        AdvancedAnalyticsQuickLink()
                    }

                    // MARK: - Campaign Stats
                    CampaignStatsSection(stats: viewModel.campaignStats)

                    // MARK: - Loyalty Program Quick Link
                    LoyaltyProgramQuickLink()

                    // MARK: - Referral Program Quick Link
                    ReferralProgramQuickLink()

                    // MARK: - Automated Campaigns Quick Link
                    AutomatedCampaignsQuickLink()

                    // MARK: - Customer Segments Quick Link
                    CustomerSegmentsQuickLink()

                    // MARK: - Active Campaigns
                    ActiveCampaignsSection(campaigns: viewModel.activeCampaigns)

                    // MARK: - Recent Notifications
                    if !viewModel.recentNotifications.isEmpty {
                        RecentNotificationsSection(
                            notifications: viewModel.recentNotifications,
                            onDelete: { notification in
                                viewModel.deleteNotification(notification)
                            }
                        )
                    }

                    // MARK: - Coupon Performance
                    CouponPerformanceSection(
                        coupons: viewModel.activeCoupons,
                        isLoading: viewModel.isLoading,
                        onToggleActive: { coupon in
                            viewModel.toggleCouponActive(coupon: coupon)
                        },
                        onDelete: { coupon in
                            viewModel.deleteCoupon(coupon)
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("Marketing")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadCoupons()
                viewModel.loadNotifications()
            }
            .refreshable {
                viewModel.loadCoupons()
                viewModel.loadNotifications()
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .createNotification:
                    CreateNotificationView(onNotificationSent: {
                        viewModel.loadNotifications()
                    })
                case .createCoupon:
                    CreateCouponView(onCouponCreated: {
                        viewModel.loadCoupons()
                    })
                case .createReward:
                    CreateRewardView()
                }
            }
            .appErrorAlert(error: $appError) {
                viewModel.loadCoupons()
                viewModel.loadNotifications()
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if let message = newValue {
                    appError = AppError.from(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
                    viewModel.errorMessage = nil
                }
            }
        }
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    let onNotificationTap: () -> Void
    let onCouponTap: () -> Void
    let onRewardTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Quick Actions")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            HStack(spacing: Spacing.lg) {
                QuickActionCard(
                    icon: "bell.badge.fill",
                    title: "Send\nNotification",
                    color: .warning,
                    action: onNotificationTap
                )

                QuickActionCard(
                    icon: "ticket.fill",
                    title: "Create\nCoupon",
                    color: .brandPrimary,
                    action: onCouponTap
                )

                QuickActionCard(
                    icon: "star.fill",
                    title: "Add\nReward",
                    color: .success,
                    action: onRewardTap
                )
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)

                Text(title)
                    .font(AppFonts.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: AppShadow.sm, radius: 4)
        }
    }
}

// MARK: - Campaign Stats Section

struct CampaignStatsSection: View {
    let stats: CampaignStats

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Campaign Performance")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            LazyVGrid(columns: [GridItem(), GridItem()], spacing: Spacing.lg) {
                MarketingStatCard(
                    icon: "paperplane.fill",
                    title: "Sent Today",
                    value: "\(stats.sentToday)",
                    color: .warning
                )

                MarketingStatCard(
                    icon: "eye.fill",
                    title: "Opened",
                    value: "\(stats.opened)%",
                    color: .brandPrimary
                )

                MarketingStatCard(
                    icon: "hand.tap.fill",
                    title: "Clicked",
                    value: "\(stats.clicked)%",
                    color: .success
                )

                MarketingStatCard(
                    icon: "cart.fill",
                    title: "Converted",
                    value: "\(stats.converted)%",
                    color: .info
                )
            }
        }
    }
}

struct MarketingStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(AppFonts.title2)

            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)

            Text(value)
                .font(AppFonts.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 4)
    }
}

// MARK: - Active Campaigns Section

struct ActiveCampaignsSection: View {
    let campaigns: [Campaign]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Active Campaigns")
                    .font(AppFonts.title3)
                    .fontWeight(.bold)

                Spacer()

                Text("\(campaigns.count) active")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            if campaigns.isEmpty {
                EmptyStateView(
                    icon: "megaphone",
                    title: "No Active Campaigns",
                    message: "Create your first marketing campaign"
                )
            } else {
                ForEach(campaigns) { campaign in
                    CampaignCard(campaign: campaign)
                }
            }
        }
    }
}

struct CampaignCard: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: campaign.type.icon)
                        .foregroundColor(campaign.type.color)

                    Text(campaign.title)
                        .font(AppFonts.headline)
                }

                Spacer()

                MarketingStatusBadge(status: campaign.status)
            }

            Text(campaign.message)
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)
                .lineLimit(2)

            HStack {
                Label("\(campaign.sentCount) sent", systemImage: "paperplane.fill")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)

                Spacer()

                Label("\(campaign.openRate)% opened", systemImage: "eye.fill")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            if let expiresAt = campaign.expiresAt {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.warning)
                    Text("Expires \(expiresAt, style: .relative)")
                        .font(AppFonts.caption)
                        .foregroundColor(.warning)
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 4)
    }
}

// MARK: - Coupon Performance Section

struct CouponPerformanceSection: View {
    let coupons: [Coupon]
    let isLoading: Bool
    let onToggleActive: (Coupon) -> Void
    let onDelete: (Coupon) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Active Coupons")
                    .font(AppFonts.title3)
                    .fontWeight(.bold)

                Spacer()

                if isLoading {
                    ProgressView()
                } else {
                    Text("\(coupons.count) active")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if coupons.isEmpty {
                EmptyStateView(
                    icon: "ticket",
                    title: "No Coupons Yet",
                    message: "Create your first coupon to start driving sales"
                )
            } else {
                ForEach(coupons) { coupon in
                    CouponPerformanceCard(
                        coupon: coupon,
                        onToggleActive: { onToggleActive(coupon) },
                        onDelete: { onDelete(coupon) }
                    )
                }
            }
        }
    }
}

struct CouponPerformanceCard: View {
    let coupon: Coupon
    let onToggleActive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(coupon.code)
                        .font(AppFonts.headline)
                        .fontWeight(.bold)

                    if !coupon.isActive {
                        Text("INACTIVE")
                            .font(AppFonts.caption)
                            .foregroundColor(.error)
                    }
                }

                Spacer()

                Text(coupon.discount)
                    .font(AppFonts.title3)
                    .fontWeight(.bold)
                    .foregroundColor(coupon.isActive ? .success : .textSecondary)
            }

            Text(coupon.title)
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)

            HStack {
                if let totalUses = coupon.totalUses {
                    ProgressView(value: Double(coupon.usedCount), total: Double(totalUses))
                        .tint(.success)

                    Text("\(coupon.usedCount)/\(totalUses) used")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                } else {
                    Text("\(coupon.usedCount) used")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.warning)
                Text("Expires \(coupon.expiresAt, style: .date)")
                    .font(AppFonts.caption)
                    .foregroundColor(.warning)

                Spacer()

                // Action buttons
                HStack(spacing: Spacing.sm) {
                    Button(action: onToggleActive) {
                        Image(systemName: coupon.isActive ? "pause.circle.fill" : "play.circle.fill")
                            .foregroundColor(coupon.isActive ? .warning : .success)
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.error)
                    }
                }
                .font(.title2)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 4)
        .opacity(coupon.isActive ? 1.0 : 0.6)
    }
}

// MARK: - Recent Notifications Section

struct RecentNotificationsSection: View {
    let notifications: [NotificationItem]
    let onDelete: (NotificationItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Recent Notifications")
                    .font(AppFonts.title3)
                    .fontWeight(.bold)

                Spacer()

                Text("\(notifications.count)")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            ForEach(notifications) { notification in
                NotificationCard(
                    notification: notification,
                    onDelete: { onDelete(notification) }
                )
            }
        }
    }
}

struct NotificationCard: View {
    let notification: NotificationItem
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(notification.title)
                        .font(AppFonts.headline)
                        .fontWeight(.bold)

                    Text(notification.status.uppercased())
                        .font(AppFonts.caption)
                        .foregroundColor(statusColor)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.error)
                        .font(.title2)
                }
            }

            Text(notification.message)
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)
                .lineLimit(2)

            HStack {
                Label(
                    "\(notification.sentCount) sent",
                    systemImage: "paperplane.fill"
                )
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)

                Spacer()

                if notification.sentCount > 0 {
                    Label(
                        "\(notification.openRate)% opened",
                        systemImage: "eye.fill"
                    )
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
                }
            }

            Text("Sent \(notification.sentAt, style: .relative)")
                .font(AppFonts.caption2)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 4)
    }

    var statusColor: Color {
        switch notification.status {
        case "sent":
            return .success
        case "scheduled":
            return .brandPrimary
        case "sending":
            return .warning
        case "failed":
            return .error
        default:
            return .textSecondary
        }
    }
}

// MARK: - Loyalty Program Quick Link

struct LoyaltyProgramQuickLink: View {
    var body: some View {
        NavigationLink(destination: LoyaltyProgramView()) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.warning)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Loyalty Program")
                        .font(AppFonts.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("View tiers and manage customer rewards")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: AppShadow.sm, radius: 4)
        }
    }
}

// MARK: - Marketing Analytics Quick Link

struct MarketingAnalyticsQuickLink: View {
    var body: some View {
        NavigationLink(destination: MarketingAnalyticsView()) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.success)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Marketing Analytics")
                        .font(AppFonts.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("View ROI, performance metrics, and insights")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: AppShadow.sm, radius: 4)
        }
    }
}

struct AdvancedAnalyticsQuickLink: View {
    var body: some View {
        NavigationLink(destination: AdvancedAnalyticsDashboardView()) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundColor(.info)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Advanced Analytics")
                        .font(AppFonts.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("Visual charts and trends")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: AppShadow.sm, radius: 4)
        }
    }
}

// MARK: - Referral Program Quick Link

struct ReferralProgramQuickLink: View {
    var body: some View {
        NavigationLink(destination: ReferralProgramView()) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.brandPrimary)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Referral Program")
                        .font(AppFonts.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("Track referrals and rewards")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: AppShadow.sm, radius: 4)
        }
    }
}

// MARK: - Automated Campaigns Quick Link

struct AutomatedCampaignsQuickLink: View {
    var body: some View {
        NavigationLink(destination: AutomatedCampaignsView()) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.brandPrimary)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Automated Campaigns")
                        .font(AppFonts.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("Manage automated marketing workflows")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: AppShadow.sm, radius: 4)
        }
    }
}

// MARK: - Customer Segments Quick Link

struct CustomerSegmentsQuickLink: View {
    var body: some View {
        NavigationLink(destination: CustomerSegmentsView()) {
            HStack {
                Image(systemName: "person.2.crop.square.stack.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.brandPrimary)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Customer Segments")
                        .font(AppFonts.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("Target specific customer groups")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: AppShadow.sm, radius: 4)
        }
    }
}

#Preview {
    MarketingDashboardView()
}
