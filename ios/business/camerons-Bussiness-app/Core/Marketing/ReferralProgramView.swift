//
//  ReferralProgramView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct ReferralProgramView: View {
    @StateObject private var viewModel = ReferralProgramViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // MARK: - Program Overview
                    if let program = viewModel.referralProgram {
                        ReferralProgramOverviewSection(program: program)
                    }

                    // MARK: - Referral Stats
                    ReferralStatsSection(
                        totalReferrals: viewModel.totalReferrals,
                        completedReferrals: viewModel.completedReferrals,
                        rewardsPaid: viewModel.rewardsPaid
                    )

                    // MARK: - Recent Referrals
                    RecentReferralsSection(
                        referrals: viewModel.referrals,
                        isLoading: viewModel.isLoading
                    )
                }
                .padding()
            }
            .navigationTitle("Referral Program")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadReferralProgram()
            }
            .refreshable {
                viewModel.loadReferralProgram()
            }
        }
    }
}

// MARK: - Program Overview Section

struct ReferralProgramOverviewSection: View {
    let program: ReferralProgram

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.brandPrimary)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Give $\(Int(program.refereeRewardValue)), Get $\(Int(program.referrerRewardValue))")
                        .font(AppFonts.title2)
                        .fontWeight(.bold)

                    Text(program.isActive ? "Active Program" : "Inactive")
                        .font(AppFonts.caption)
                        .foregroundColor(program.isActive ? .success : .textSecondary)
                }

                Spacer()
            }

            Divider()

            // Program Details
            VStack(alignment: .leading, spacing: Spacing.md) {
                ReferralRuleRow(
                    icon: "gift.fill",
                    title: "Referrer Reward",
                    value: formatReward(type: program.referrerRewardType, value: program.referrerRewardValue)
                )

                ReferralRuleRow(
                    icon: "star.fill",
                    title: "Referee Reward",
                    value: formatReward(type: program.refereeRewardType, value: program.refereeRewardValue)
                )

                if program.minOrderValue > 0 {
                    ReferralRuleRow(
                        icon: "cart.fill",
                        title: "Minimum Order",
                        value: "$\(Int(program.minOrderValue))"
                    )
                }

                if let maxReferrals = program.maxReferralsPerCustomer {
                    ReferralRuleRow(
                        icon: "number",
                        title: "Max Referrals",
                        value: "\(maxReferrals) per customer"
                    )
                } else {
                    ReferralRuleRow(
                        icon: "infinity",
                        title: "Max Referrals",
                        value: "Unlimited"
                    )
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: AppShadow.sm, radius: 4)
    }

    func formatReward(type: String, value: Double) -> String {
        switch type {
        case "credit":
            return "$\(Int(value)) credit"
        case "points":
            return "\(Int(value)) points"
        case "coupon":
            return "Special coupon"
        default:
            return "Reward"
        }
    }
}

struct ReferralRuleRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.brandPrimary)
                .frame(width: 24)

            Text(title)
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(AppFonts.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Referral Stats Section

struct ReferralStatsSection: View {
    let totalReferrals: Int
    let completedReferrals: Int
    let rewardsPaid: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Program Stats")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            HStack(spacing: Spacing.md) {
                ReferralStatCard(
                    icon: "person.2.fill",
                    title: "Total Referrals",
                    value: "\(totalReferrals)",
                    color: .brandPrimary
                )

                ReferralStatCard(
                    icon: "checkmark.circle.fill",
                    title: "Completed",
                    value: "\(completedReferrals)",
                    color: .success
                )

                ReferralStatCard(
                    icon: "dollarsign.circle.fill",
                    title: "Rewards Paid",
                    value: "$\(Int(rewardsPaid))",
                    color: .warning
                )
            }
        }
    }
}

struct ReferralStatCard: View {
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
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(AppFonts.headline)
                .fontWeight(.bold)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2)
    }
}

// MARK: - Recent Referrals Section

struct RecentReferralsSection: View {
    let referrals: [ReferralItem]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Recent Referrals")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if referrals.isEmpty {
                EmptyStateView(
                    icon: "person.2.slash",
                    title: "No Referrals Yet",
                    message: "Referrals will appear here when customers share their codes",
                    showBackground: false
                )
            } else {
                ForEach(referrals) { referral in
                    ReferralCard(referral: referral)
                }
            }
        }
    }
}

struct ReferralCard: View {
    let referral: ReferralItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(referral.referralCode)
                        .font(AppFonts.headline)
                        .fontWeight(.bold)

                    Text(statusText)
                        .font(AppFonts.caption)
                        .foregroundColor(statusColor)
                }

                Spacer()

                // Status Badge
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                }
            }

            Divider()

            // Participants
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Referrer")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)

                    Text(referral.referrerName)
                        .font(AppFonts.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundColor(.textSecondary)

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("Referee")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)

                    Text(referral.refereeName ?? "Pending")
                        .font(AppFonts.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(referral.refereeName != nil ? .textPrimary : .textSecondary)
                }
            }

            // Rewards Status
            if referral.status == "completed" || referral.status == "rewarded" {
                HStack {
                    Label(
                        referral.referrerRewarded ? "Referrer rewarded" : "Pending reward",
                        systemImage: referral.referrerRewarded ? "checkmark.circle.fill" : "clock.fill"
                    )
                    .font(AppFonts.caption)
                    .foregroundColor(referral.referrerRewarded ? .success : .warning)

                    Spacer()

                    Label(
                        referral.refereeRewarded ? "Referee rewarded" : "Pending reward",
                        systemImage: referral.refereeRewarded ? "checkmark.circle.fill" : "clock.fill"
                    )
                    .font(AppFonts.caption)
                    .foregroundColor(referral.refereeRewarded ? .success : .warning)
                }
                .padding(.top, Spacing.xs)
            }

            // Date
            Text("Created \(referral.createdAt, style: .relative)")
                .font(AppFonts.caption2)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2)
    }

    var statusText: String {
        switch referral.status {
        case "pending":
            return "Pending"
        case "completed":
            return "Completed"
        case "rewarded":
            return "Rewarded"
        case "expired":
            return "Expired"
        default:
            return "Unknown"
        }
    }

    var statusColor: Color {
        switch referral.status {
        case "pending":
            return .warning
        case "completed", "rewarded":
            return .success
        case "expired":
            return .error
        default:
            return .textSecondary
        }
    }

    var statusIcon: String {
        switch referral.status {
        case "pending":
            return "clock.fill"
        case "completed", "rewarded":
            return "checkmark.circle.fill"
        case "expired":
            return "xmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}

#Preview {
    ReferralProgramView()
}
