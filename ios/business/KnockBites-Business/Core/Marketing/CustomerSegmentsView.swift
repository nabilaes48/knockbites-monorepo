//
//  CustomerSegmentsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct CustomerSegmentsView: View {
    @StateObject private var viewModel = CustomerSegmentsViewModel()
    @State private var showCreateSegment = false
    @State private var segmentToDelete: CustomerSegment?
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // MARK: - Overview Stats
                    SegmentOverviewSection(
                        totalSegments: viewModel.allSegments.count,
                        customSegments: viewModel.customSegments.count
                    )

                    // MARK: - Predefined Segments
                    if !viewModel.predefinedSegments.isEmpty {
                        SegmentsSection(
                            title: "Predefined Segments",
                            segments: viewModel.predefinedSegments,
                            isPredefined: true,
                            onDelete: nil
                        )
                    }

                    // MARK: - Custom Segments
                    if !viewModel.customSegments.isEmpty {
                        SegmentsSection(
                            title: "Custom Segments",
                            segments: viewModel.customSegments,
                            isPredefined: false,
                            onDelete: { segment in
                                segmentToDelete = segment
                                showDeleteAlert = true
                            }
                        )
                    }

                    // MARK: - Empty State
                    if viewModel.customSegments.isEmpty {
                        EmptyCustomSegmentsState()
                    }
                }
                .padding()
            }
            .navigationTitle("Customer Segments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateSegment = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
            .sheet(isPresented: $showCreateSegment) {
                SegmentBuilderView(viewModel: viewModel)
            }
            .alert("Delete Segment", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let segment = segmentToDelete {
                        viewModel.deleteCustomSegment(segment)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this custom segment? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Segment Overview Section

struct SegmentOverviewSection: View {
    let totalSegments: Int
    let customSegments: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Overview")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            HStack(spacing: Spacing.md) {
                SegmentOverviewCard(
                    icon: "person.2.fill",
                    title: "Total Segments",
                    value: "\(totalSegments)",
                    color: .brandPrimary
                )

                SegmentOverviewCard(
                    icon: "slider.horizontal.3",
                    title: "Custom Segments",
                    value: "\(customSegments)",
                    color: .success
                )
            }
        }
    }
}

struct SegmentOverviewCard: View {
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

// MARK: - Segments Section

struct SegmentsSection: View {
    let title: String
    let segments: [CustomerSegment]
    let isPredefined: Bool
    let onDelete: ((CustomerSegment) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text(title)
                    .font(AppFonts.title3)
                    .fontWeight(.bold)

                Spacer()

                Text("\(segments.count)")
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }

            ForEach(segments) { segment in
                NavigationLink(destination: SegmentDetailView(segment: segment)) {
                    SegmentCard(
                        segment: segment,
                        isPredefined: isPredefined,
                        onDelete: onDelete
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Segment Card

struct SegmentCard: View {
    let segment: CustomerSegment
    let isPredefined: Bool
    let onDelete: ((CustomerSegment) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(segment.name)
                            .font(AppFonts.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        if isPredefined {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.warning)
                        }
                    }

                    if let description = segment.description {
                        Text(description)
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }

            Divider()

            // Analytics
            HStack(spacing: Spacing.lg) {
                SegmentMetric(
                    label: "Customers",
                    value: "\(segment.customerCount ?? 0)",
                    color: .brandPrimary
                )

                SegmentMetric(
                    label: "Avg Order",
                    value: "$\(Int(segment.avgOrderValue ?? 0))",
                    color: .success
                )

                SegmentMetric(
                    label: "LTV",
                    value: "$\(Int(segment.lifetimeValue ?? 0))",
                    color: .warning
                )
            }

            // Delete button for custom segments
            if !isPredefined, let onDelete = onDelete {
                Button(action: { onDelete(segment) }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete Segment")
                    }
                    .font(AppFonts.subheadline)
                    .foregroundColor(.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2)
    }
}

struct SegmentMetric: View {
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

struct EmptyCustomSegmentsState: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 60))
                .foregroundColor(.textSecondary)

            Text("No Custom Segments")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            Text("Create custom segments to target specific groups of customers based on their behavior and attributes.")
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Segment Detail View

struct SegmentDetailView: View {
    let segment: CustomerSegment

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Analytics Cards
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Segment Analytics")
                        .font(AppFonts.title3)
                        .fontWeight(.bold)

                    LazyVGrid(columns: [GridItem(), GridItem()], spacing: Spacing.md) {
                        AnalyticsCard(
                            icon: "person.2.fill",
                            title: "Total Customers",
                            value: "\(segment.customerCount ?? 0)",
                            color: .brandPrimary
                        )

                        AnalyticsCard(
                            icon: "dollarsign.circle.fill",
                            title: "Avg Order Value",
                            value: "$\(Int(segment.avgOrderValue ?? 0))",
                            color: .success
                        )

                        AnalyticsCard(
                            icon: "repeat.circle.fill",
                            title: "Avg Frequency",
                            value: String(format: "%.1f", segment.avgOrderFrequency ?? 0),
                            color: .info
                        )

                        AnalyticsCard(
                            icon: "chart.bar.fill",
                            title: "Lifetime Value",
                            value: "$\(Int(segment.lifetimeValue ?? 0))",
                            color: .warning
                        )
                    }
                }

                // Filters
                if !segment.filters.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("Segment Filters")
                            .font(AppFonts.title3)
                            .fontWeight(.bold)

                        ForEach(segment.filters) { filter in
                            FilterDetailCard(filter: filter)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(segment.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnalyticsCard: View {
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

struct FilterDetailCard: View {
    let filter: SegmentFilter

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: filter.filterType.icon)
                    .foregroundColor(.brandPrimary)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(filter.filterType.displayName)
                    .font(AppFonts.body)
                    .fontWeight(.semibold)

                Text("\(filter.condition.displayName): \(filter.value)")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2)
    }
}

#Preview {
    CustomerSegmentsView()
}
