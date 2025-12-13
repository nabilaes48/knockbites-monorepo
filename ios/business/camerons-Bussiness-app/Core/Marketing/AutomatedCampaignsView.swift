//
//  AutomatedCampaignsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct AutomatedCampaignsView: View {
    @StateObject private var viewModel = AutomatedCampaignsViewModel()
    @State private var showingDeleteAlert = false
    @State private var campaignToDelete: AutomatedCampaign?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // MARK: - Performance Overview
                    CampaignPerformanceOverview(
                        totalTriggered: viewModel.totalTriggered,
                        totalConversions: viewModel.totalConversions,
                        conversionRate: viewModel.conversionRate,
                        totalRevenue: viewModel.totalRevenue
                    )

                    // MARK: - Active Campaigns
                    if !viewModel.activeCampaigns.isEmpty {
                        CampaignsSection(
                            title: "Active Campaigns",
                            campaigns: viewModel.activeCampaigns,
                            onToggle: { campaign in
                                viewModel.toggleCampaign(campaign: campaign)
                            },
                            onDelete: { campaign in
                                campaignToDelete = campaign
                                showingDeleteAlert = true
                            }
                        )
                    }

                    // MARK: - Inactive Campaigns
                    if !viewModel.inactiveCampaigns.isEmpty {
                        CampaignsSection(
                            title: "Inactive Campaigns",
                            campaigns: viewModel.inactiveCampaigns,
                            onToggle: { campaign in
                                viewModel.toggleCampaign(campaign: campaign)
                            },
                            onDelete: { campaign in
                                campaignToDelete = campaign
                                showingDeleteAlert = true
                            }
                        )
                    }

                    // MARK: - Empty State
                    if viewModel.campaigns.isEmpty && !viewModel.isLoading {
                        EmptyCampaignsState()
                    }

                    // MARK: - Error Message
                    if let errorMessage = viewModel.errorMessage {
                        ErrorStateView(message: errorMessage, style: .banner)
                    }
                }
                .padding()
            }
            .navigationTitle("Automated Campaigns")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadCampaigns()
            }
            .refreshable {
                viewModel.loadCampaigns()
            }
            .alert("Delete Campaign", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let campaign = campaignToDelete {
                        viewModel.deleteCampaign(campaign: campaign)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this campaign? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Performance Overview

struct CampaignPerformanceOverview: View {
    let totalTriggered: Int
    let totalConversions: Int
    let conversionRate: Double
    let totalRevenue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Overall Performance")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            LazyVGrid(columns: [GridItem(), GridItem()], spacing: Spacing.md) {
                MetricCard(
                    icon: "bell.badge.fill",
                    title: "Times Triggered",
                    value: "\(totalTriggered)",
                    color: .brandPrimary
                )

                MetricCard(
                    icon: "checkmark.circle.fill",
                    title: "Conversions",
                    value: "\(totalConversions)",
                    color: .success
                )

                MetricCard(
                    icon: "percent",
                    title: "Conversion Rate",
                    value: "\(Int(conversionRate))%",
                    color: .info
                )

                MetricCard(
                    icon: "dollarsign.circle.fill",
                    title: "Revenue",
                    value: "$\(Int(totalRevenue))",
                    color: .warning
                )
            }
        }
    }
}

// MARK: - Campaigns Section

struct CampaignsSection: View {
    let title: String
    let campaigns: [AutomatedCampaign]
    let onToggle: (AutomatedCampaign) -> Void
    let onDelete: (AutomatedCampaign) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text(title)
                    .font(AppFonts.title3)
                    .fontWeight(.bold)

                Spacer()

                Text("\(campaigns.count)")
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }

            ForEach(campaigns) { campaign in
                AutomatedCampaignCard(
                    campaign: campaign,
                    onToggle: { onToggle(campaign) },
                    onDelete: { onDelete(campaign) }
                )
            }
        }
    }
}

// MARK: - Automated Campaign Card

struct AutomatedCampaignCard: View {
    let campaign: AutomatedCampaign
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(campaign.campaignType.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: campaign.campaignType.icon)
                        .foregroundColor(campaign.campaignType.color)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(campaign.name)
                        .font(AppFonts.headline)
                        .fontWeight(.bold)

                    Text(campaign.campaignType.displayName)
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Status Toggle
                Toggle("", isOn: Binding(
                    get: { campaign.isActive },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }

            Divider()

            // Campaign Details
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let description = campaign.description {
                    Text(description)
                        .font(AppFonts.subheadline)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }

                HStack {
                    Label(campaign.targetAudience.replacingOccurrences(of: "_", with: " ").capitalized, systemImage: "person.2.fill")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)

                    Spacer()

                    Text(campaign.triggerCondition.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Divider()

            // Performance Metrics
            HStack(spacing: Spacing.lg) {
                CampaignMetricItem(
                    label: "Triggered",
                    value: "\(campaign.timesTriggered)",
                    color: .brandPrimary
                )

                CampaignMetricItem(
                    label: "Conversions",
                    value: "\(campaign.conversionCount)",
                    color: .success
                )

                CampaignMetricItem(
                    label: "Revenue",
                    value: "$\(Int(campaign.revenueGenerated))",
                    color: .warning
                )
            }

            // Delete Button
            Button(action: onDelete) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Campaign")
                }
                .font(AppFonts.subheadline)
                .foregroundColor(.error)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2)
    }
}

// MARK: - Campaign Metric Item

struct CampaignMetricItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)

            Text(value)
                .font(AppFonts.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Empty State

struct EmptyCampaignsState: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(.textSecondary)

            Text("No Automated Campaigns")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            Text("Automated campaigns help you engage customers at the right time with personalized messages.")
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, Spacing.xxl)
    }
}

#Preview {
    AutomatedCampaignsView()
}
