//
//  LoyaltyProgramView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//  Updated Phase 9 - Enum-based sheet state
//

import SwiftUI

// MARK: - Sheet State

private enum LoyaltySheet: Identifiable {
    case editSettings
    case createTier
    case editTier(LoyaltyTier)

    var id: String {
        switch self {
        case .editSettings: return "editSettings"
        case .createTier: return "createTier"
        case .editTier(let tier): return "editTier_\(tier.id)"
        }
    }
}

struct LoyaltyProgramView: View {
    @StateObject private var viewModel = LoyaltyProgramViewModel()
    @State private var activeSheet: LoyaltySheet?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // MARK: - Program Overview
                    if let program = viewModel.loyaltyProgram {
                        ProgramOverviewSection(program: program)
                    }

                    // MARK: - Tier Distribution
                    if !viewModel.tierDistribution.isEmpty {
                        TierDistributionSection(
                            distribution: viewModel.tierDistribution,
                            totalMembers: viewModel.totalMembers
                        )
                    }

                    // MARK: - Rewards Catalog
                    if let program = viewModel.loyaltyProgram {
                        RewardsCatalogSection(programId: program.id)
                    }

                    // MARK: - Loyalty Tiers
                    LoyaltyTiersSection(
                        tiers: viewModel.loyaltyTiers,
                        isLoading: viewModel.isLoading,
                        onAddTier: { activeSheet = .createTier },
                        onEditTier: { tier in activeSheet = .editTier(tier) }
                    )

                    // MARK: - Program Stats
                    if !viewModel.loyaltyTiers.isEmpty {
                        ProgramStatsSection(
                            totalMembers: viewModel.totalMembers,
                            activeMembersPercent: viewModel.activeMembersPercent
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Loyalty Program")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeSheet = .editSettings }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.brandPrimary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CustomerLoyaltyView()) {
                        Label("Manage Customers", systemImage: "person.2.fill")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .editSettings:
                    if let program = viewModel.loyaltyProgram {
                        EditProgramSettingsView(program: program) {
                            viewModel.loadLoyaltyProgram()
                        }
                    }
                case .createTier:
                    if let program = viewModel.loyaltyProgram {
                        EditTierView(programId: program.id) {
                            viewModel.loadLoyaltyProgram()
                        }
                    }
                case .editTier(let tier):
                    EditTierView(programId: tier.programId, tier: tier) {
                        viewModel.loadLoyaltyProgram()
                    }
                }
            }
            .onAppear {
                viewModel.loadLoyaltyProgram()
            }
            .refreshable {
                viewModel.loadLoyaltyProgram()
            }
        }
    }
}

// MARK: - Program Overview Section

struct ProgramOverviewSection: View {
    let program: LoyaltyProgram

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.warning)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(program.name)
                        .font(AppFonts.title2)
                        .fontWeight(.bold)

                    Text(program.isActive ? "Active" : "Inactive")
                        .font(AppFonts.caption)
                        .foregroundColor(program.isActive ? .success : .textSecondary)
                }

                Spacer()
            }

            Divider()

            // Program Rules
            VStack(alignment: .leading, spacing: Spacing.md) {
                ProgramRuleRow(
                    icon: "dollarsign.circle.fill",
                    title: "Points Per Dollar",
                    value: "\(Int(program.pointsPerDollar)) point"
                )

                ProgramRuleRow(
                    icon: "gift.fill",
                    title: "Welcome Bonus",
                    value: "\(program.welcomeBonusPoints) points"
                )

                ProgramRuleRow(
                    icon: "person.2.fill",
                    title: "Referral Bonus",
                    value: "\(program.referralBonusPoints) points"
                )
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: AppShadow.sm, radius: 4)
    }
}

struct ProgramRuleRow: View {
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

// MARK: - Rewards Catalog Section

struct RewardsCatalogSection: View {
    let programId: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundColor(.warning)

                Text("Rewards Catalog")
                    .font(AppFonts.title3)
                    .fontWeight(.bold)

                Spacer()

                NavigationLink(destination: RewardsCatalogView(programId: programId)) {
                    HStack(spacing: Spacing.xs) {
                        Text("Manage")
                            .font(AppFonts.subheadline)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(AppFonts.caption)
                    }
                    .foregroundColor(.brandPrimary)
                }
            }

            Text("Create and manage rewards that customers can redeem with their loyalty points")
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 4)
    }
}

// MARK: - Loyalty Tiers Section

struct LoyaltyTiersSection: View {
    let tiers: [LoyaltyTier]
    let isLoading: Bool
    let onAddTier: () -> Void
    let onEditTier: (LoyaltyTier) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Membership Tiers")
                    .font(AppFonts.title3)
                    .fontWeight(.bold)

                Spacer()

                Button(action: onAddTier) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Tier")
                            .font(AppFonts.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.brandPrimary)
                }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if tiers.isEmpty {
                EmptyStateView(
                    icon: "star",
                    title: "No Tiers Configured",
                    message: "Create your first tier to get started"
                )
            } else {
                ForEach(tiers) { tier in
                    Button(action: { onEditTier(tier) }) {
                        LoyaltyTierCard(tier: tier)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct LoyaltyTierCard: View {
    let tier: LoyaltyTier

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Tier Header
            HStack {
                // Tier Badge
                ZStack {
                    Circle()
                        .fill(tierColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: tierIcon)
                        .font(.title2)
                        .foregroundColor(tierColor)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(tier.name)
                        .font(AppFonts.title3)
                        .fontWeight(.bold)

                    Text("\(tier.minPoints)+ points")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()
            }

            Divider()

            // Benefits
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if tier.discountPercentage > 0 {
                    BenefitRow(
                        icon: "percent",
                        text: "\(Int(tier.discountPercentage))% off all orders",
                        isEnabled: true
                    )
                }

                BenefitRow(
                    icon: "shippingbox.fill",
                    text: "Free delivery",
                    isEnabled: tier.freeDelivery
                )

                BenefitRow(
                    icon: "headphones",
                    text: "Priority support",
                    isEnabled: tier.prioritySupport
                )

                BenefitRow(
                    icon: "star.fill",
                    text: "Early access to promos",
                    isEnabled: tier.earlyAccessPromos
                )

                if tier.birthdayRewardPoints > 0 {
                    BenefitRow(
                        icon: "gift.fill",
                        text: "\(tier.birthdayRewardPoints) birthday bonus points",
                        isEnabled: true
                    )
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(tierColor.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: AppShadow.sm, radius: 4)
    }

    var tierColor: Color {
        if let colorHex = tier.tierColor {
            return Color(hex: colorHex) ?? .brandPrimary
        }
        return .brandPrimary
    }

    var tierIcon: String {
        switch tier.name.lowercased() {
        case "bronze":
            return "3.circle.fill"
        case "silver":
            return "2.circle.fill"
        case "gold":
            return "1.circle.fill"
        case "platinum":
            return "crown.fill"
        default:
            return "star.fill"
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .success : .textSecondary)
                .frame(width: 20)

            Text(text)
                .font(AppFonts.subheadline)
                .foregroundColor(isEnabled ? .textPrimary : .textSecondary)
                .strikethrough(!isEnabled)

            Spacer()

            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.success)
            }
        }
    }
}

// MARK: - Program Stats Section

struct ProgramStatsSection: View {
    let totalMembers: Int
    let activeMembersPercent: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Program Stats")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            HStack(spacing: Spacing.lg) {
                LoyaltyStatCard(
                    icon: "person.2.fill",
                    title: "Total Members",
                    value: "\(totalMembers)",
                    color: .brandPrimary
                )

                LoyaltyStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Active Rate",
                    value: "\(activeMembersPercent)%",
                    color: .success
                )
            }
        }
    }
}

struct LoyaltyStatCard: View {
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

// MARK: - Tier Distribution Section

struct TierDistributionSection: View {
    let distribution: [TierDistribution]
    let totalMembers: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Member Distribution")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            VStack(spacing: Spacing.md) {
                // Visual bar chart
                ForEach(distribution) { tier in
                    TierDistributionBar(tier: tier, totalMembers: totalMembers)
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: AppShadow.sm, radius: 4)
        }
    }
}

struct TierDistributionBar: View {
    let tier: TierDistribution
    let totalMembers: Int

    var tierColor: Color {
        if let colorHex = tier.tierColor {
            return Color(hex: colorHex) ?? .brandPrimary
        }
        return .brandPrimary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(tier.tierName)
                    .font(AppFonts.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(tier.memberCount) members")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)

                Text("(\(String(format: "%.0f", tier.percentage))%)")
                    .font(AppFonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(tierColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(tierColor)
                        .frame(
                            width: geometry.size.width * CGFloat(tier.percentage / 100),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    LoyaltyProgramView()
}
