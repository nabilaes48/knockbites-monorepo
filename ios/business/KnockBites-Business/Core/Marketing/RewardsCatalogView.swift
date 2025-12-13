//
//  RewardsCatalogView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct RewardsCatalogView: View {
    let programId: Int
    @StateObject private var viewModel = LoyaltyRewardsViewModel()
    @State private var showCreateReward = false
    @State private var rewardToEdit: LoyaltyReward?
    @State private var rewardToDelete: LoyaltyReward?
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // MARK: - Header Stats
                RewardCatalogHeader(
                    totalRewards: viewModel.rewards.count,
                    activeRewards: viewModel.activeRewards.count,
                    totalRedemptions: viewModel.totalRedemptions
                )

                // MARK: - Active Rewards
                if !viewModel.activeRewards.isEmpty {
                    RewardsSection(
                        title: "Active Rewards",
                        rewards: viewModel.activeRewards,
                        onEdit: { reward in
                            rewardToEdit = reward
                        },
                        onDelete: { reward in
                            rewardToDelete = reward
                            showDeleteAlert = true
                        }
                    )
                }

                // MARK: - Inactive Rewards
                if !viewModel.inactiveRewards.isEmpty {
                    RewardsSection(
                        title: "Inactive Rewards",
                        rewards: viewModel.inactiveRewards,
                        onEdit: { reward in
                            rewardToEdit = reward
                        },
                        onDelete: { reward in
                            rewardToDelete = reward
                            showDeleteAlert = true
                        }
                    )
                }

                // MARK: - Empty State
                if viewModel.rewards.isEmpty && !viewModel.isLoading {
                    EmptyRewardsState()
                }
            }
            .padding()
        }
        .navigationTitle("Rewards Catalog")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateReward = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.brandPrimary)
                }
            }
        }
        .sheet(isPresented: $showCreateReward) {
            EditRewardView(programId: programId, reward: nil) {
                viewModel.loadRewards(programId: programId)
            }
        }
        .sheet(item: $rewardToEdit) { reward in
            EditRewardView(programId: programId, reward: reward) {
                viewModel.loadRewards(programId: programId)
            }
        }
        .alert("Delete Reward", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let reward = rewardToDelete {
                    viewModel.deleteReward(reward: reward, programId: programId)
                }
            }
        } message: {
            Text("Are you sure you want to delete this reward? This action cannot be undone.")
        }
        .onAppear {
            viewModel.loadRewards(programId: programId)
        }
        .refreshable {
            viewModel.loadRewards(programId: programId)
        }
    }
}

// MARK: - Reward Catalog Header

struct RewardCatalogHeader: View {
    let totalRewards: Int
    let activeRewards: Int
    let totalRedemptions: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Overview")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            HStack(spacing: Spacing.md) {
                RewardStatCard(
                    icon: "gift.fill",
                    title: "Total Rewards",
                    value: "\(totalRewards)",
                    color: .brandPrimary
                )

                RewardStatCard(
                    icon: "checkmark.circle.fill",
                    title: "Active",
                    value: "\(activeRewards)",
                    color: .success
                )

                RewardStatCard(
                    icon: "arrow.down.circle.fill",
                    title: "Redeemed",
                    value: "\(totalRedemptions)",
                    color: .warning
                )
            }
        }
    }
}

struct RewardStatCard: View {
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

// MARK: - Rewards Section

struct RewardsSection: View {
    let title: String
    let rewards: [LoyaltyReward]
    let onEdit: (LoyaltyReward) -> Void
    let onDelete: (LoyaltyReward) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text(title)
                    .font(AppFonts.title3)
                    .fontWeight(.bold)

                Spacer()

                Text("\(rewards.count)")
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }

            ForEach(rewards) { reward in
                RewardCard(
                    reward: reward,
                    onEdit: { onEdit(reward) },
                    onDelete: { onDelete(reward) }
                )
            }
        }
    }
}

// MARK: - Reward Card

struct RewardCard: View {
    let reward: LoyaltyReward
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                // Type Icon
                ZStack {
                    Circle()
                        .fill(reward.rewardType.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: reward.rewardType.icon)
                        .font(.title3)
                        .foregroundColor(reward.rewardType.color)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(reward.name)
                        .font(AppFonts.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text(reward.rewardType.displayName)
                        .font(AppFonts.caption)
                        .foregroundColor(reward.rewardType.color)
                }

                Spacer()

                // Points Cost Badge
                VStack(spacing: Spacing.xs) {
                    Text("\(reward.pointsCost)")
                        .font(AppFonts.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.warning)

                    Text("points")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            if let description = reward.description {
                Text(description)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            Divider()

            // Details
            HStack(spacing: Spacing.lg) {
                // Reward Value
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Value")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)

                    Text(reward.rewardValue)
                        .font(AppFonts.subheadline)
                        .fontWeight(.semibold)
                }

                // Redemptions
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Redeemed")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)

                    Text("\(reward.redemptionCount)x")
                        .font(AppFonts.subheadline)
                        .fontWeight(.semibold)
                }

                // Stock (if applicable)
                if let stock = reward.stockQuantity {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Stock")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)

                        Text("\(stock)")
                            .font(AppFonts.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(stock < 10 ? .error : .textPrimary)
                    }
                }

                Spacer()

                // Active Badge
                if reward.isActive {
                    Text("Active")
                        .font(AppFonts.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.success)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.success.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                }
            }

            // Action Buttons
            HStack(spacing: Spacing.md) {
                Button(action: onEdit) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(AppFonts.subheadline)
                    .foregroundColor(.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.brandPrimary.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
                }

                Button(action: onDelete) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(AppFonts.subheadline)
                    .foregroundColor(.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.error.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2)
    }
}

// MARK: - Empty State

struct EmptyRewardsState: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "gift")
                .font(.system(size: 60))
                .foregroundColor(.textSecondary)

            Text("No Rewards Yet")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            Text("Create rewards that customers can redeem with their loyalty points.")
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, Spacing.xxl)
    }
}

#Preview {
    NavigationView {
        RewardsCatalogView(programId: 1)
    }
}
