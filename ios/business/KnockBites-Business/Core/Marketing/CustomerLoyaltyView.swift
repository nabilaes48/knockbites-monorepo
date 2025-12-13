//
//  CustomerLoyaltyView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct CustomerLoyaltyView: View {
    @StateObject private var viewModel = CustomerLoyaltyViewModel()
    @State private var searchText = ""
    @State private var showBulkAward = false
    @State private var showExportOptions = false

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textSecondary)

                TextField("Search by email or phone", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding()
            .background(Color.surface)

            Divider()

            // Content
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                ErrorStateView(message: errorMessage, style: .fullScreen)
            } else if viewModel.customers.isEmpty {
                EmptyStateView(
                    icon: "person.2.slash",
                    title: "No Customers Found",
                    message: "Customers will appear here once they join the loyalty program",
                    showBackground: false
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(viewModel.filteredCustomers(searchText: searchText)) { customer in
                            NavigationLink(destination: CustomerLoyaltyDetailView(customerId: customer.id)) {
                                CustomerLoyaltyCard(customer: customer)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Customer Loyalty")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Spacing.md) {
                    Button(action: { showExportOptions = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.brandPrimary)
                    }

                    Button(action: { showBulkAward = true }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "gift.fill")
                            Text("Bulk Award")
                                .font(AppFonts.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.brandPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showBulkAward) {
            BulkPointsAwardView()
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(
                exportType: .loyalty,
                onExport: { format, options in
                    try await exportLoyaltyData(format: format, options: options)
                }
            )
        }
        .onAppear {
            viewModel.loadCustomers()
        }
        .refreshable {
            viewModel.loadCustomers()
        }
    }

    // MARK: - Export Function

    private func exportLoyaltyData(format: ExportFormat, options: ExportOptions) async throws -> URL {
        switch format {
        case .pdf:
            let exporter = ReportExporter()
            let summary = LoyaltySummary(
                totalMembers: viewModel.customers.count,
                totalPoints: viewModel.customers.reduce(0) { $0 + $1.points },
                totalRedemptions: 0, // Not available in current model
                averagePointsPerMember: viewModel.customers.isEmpty ? 0 : Double(viewModel.customers.reduce(0) { $0 + $1.points }) / Double(viewModel.customers.count),
                tierDistribution: Dictionary(grouping: viewModel.customers, by: { $0.tierName })
                    .mapValues { $0.count }
            )
            return try await exporter.exportLoyaltyReportToPDF(
                customers: viewModel.customers,
                summary: summary,
                dateRange: options.dateRange
            )

        case .csv:
            let exporter = ExcelExporter()
            return try await exporter.exportLoyaltyDataToCSV(
                customers: viewModel.customers,
                dateRange: options.dateRange
            )
        }
    }
}

// MARK: - Customer Loyalty Card

struct CustomerLoyaltyCard: View {
    let customer: CustomerLoyaltyListItem

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Customer Avatar
            ZStack {
                Circle()
                    .fill(tierColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Text(customer.initials)
                    .font(AppFonts.headline)
                    .fontWeight(.bold)
                    .foregroundColor(tierColor)
            }

            // Customer Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(customer.name)
                    .font(AppFonts.headline)
                    .foregroundColor(.textPrimary)

                Text(customer.email ?? customer.phone ?? "No contact")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)

                HStack {
                    Label("\(customer.points) pts", systemImage: "star.fill")
                        .font(AppFonts.caption)
                        .foregroundColor(.warning)

                    Text("•")
                        .foregroundColor(.textSecondary)

                    Text(customer.tierName)
                        .font(AppFonts.caption)
                        .foregroundColor(tierColor)
                        .fontWeight(.semibold)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2)
    }

    var tierColor: Color {
        switch customer.tierName.lowercased() {
        case "bronze":
            return Color(hex: "#CD7F32") ?? .brown
        case "silver":
            return Color(hex: "#C0C0C0") ?? .gray
        case "gold":
            return Color(hex: "#FFD700") ?? .yellow
        case "platinum":
            return Color(hex: "#E5E4E2") ?? .gray
        default:
            return .brandPrimary
        }
    }
}

// MARK: - Customer Loyalty Detail View

struct CustomerLoyaltyDetailView: View {
    let customerId: Int
    @StateObject private var viewModel = CustomerLoyaltyDetailViewModel()
    @State private var showAddPoints = false
    @State private var pointsToAdd = ""
    @State private var reason = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                if let loyalty = viewModel.customerLoyalty {
                    // Customer Header
                    CustomerHeaderSection(loyalty: loyalty, tier: viewModel.currentTier)

                    // Points Summary
                    PointsSummarySection(loyalty: loyalty)

                    // Transaction History
                    TransactionHistorySection(
                        transactions: viewModel.transactions,
                        isLoading: viewModel.isLoadingTransactions
                    )
                } else if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Text("Customer loyalty data not found")
                        .foregroundColor(.textSecondary)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Loyalty Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddPoints = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.brandPrimary)
                }
            }
        }
        .sheet(isPresented: $showAddPoints) {
            AddPointsView(
                customerLoyaltyId: viewModel.customerLoyalty?.id ?? 0,
                onPointsAdded: {
                    viewModel.loadCustomerLoyalty(customerId: customerId)
                }
            )
        }
        .onAppear {
            viewModel.loadCustomerLoyalty(customerId: customerId)
        }
    }
}

// MARK: - Customer Header Section

struct CustomerHeaderSection: View {
    let loyalty: CustomerLoyalty
    let tier: LoyaltyTier?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Tier Badge
            if let tier = tier {
                ZStack {
                    Circle()
                        .fill(tierColor.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: tierIcon)
                        .font(.system(size: 40))
                        .foregroundColor(tierColor)
                }

                Text(tier.name)
                    .font(AppFonts.title2)
                    .fontWeight(.bold)
                    .foregroundColor(tierColor)
            }

            // Points Display
            VStack(spacing: Spacing.xs) {
                Text("\(loyalty.totalPoints)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.warning)

                Text("Total Points")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: AppShadow.sm, radius: 4)
    }

    var tierColor: Color {
        guard let tier = tier else { return .brandPrimary }
        if let colorHex = tier.tierColor {
            return Color(hex: colorHex) ?? .brandPrimary
        }
        return .brandPrimary
    }

    var tierIcon: String {
        guard let tier = tier else { return "star.fill" }
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

// MARK: - Points Summary Section

struct PointsSummarySection: View {
    let loyalty: CustomerLoyalty

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Summary")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            LazyVGrid(columns: [GridItem(), GridItem()], spacing: Spacing.md) {
                SummaryCard(
                    icon: "star.fill",
                    title: "Lifetime Points",
                    value: "\(loyalty.lifetimePoints)",
                    color: .warning
                )

                SummaryCard(
                    icon: "cart.fill",
                    title: "Total Orders",
                    value: "\(loyalty.totalOrders)",
                    color: .brandPrimary
                )

                SummaryCard(
                    icon: "dollarsign.circle.fill",
                    title: "Total Spent",
                    value: "$\(Int(loyalty.totalSpent))",
                    color: .success
                )

                SummaryCard(
                    icon: "clock.fill",
                    title: "Member Since",
                    value: loyalty.joinedAt.formatted(.dateTime.month().year()),
                    color: .info
                )
            }
        }
    }
}

struct SummaryCard: View {
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

// MARK: - Transaction History Section

struct TransactionHistorySection: View {
    let transactions: [LoyaltyTransaction]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Transaction History")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if transactions.isEmpty {
                Text("No transactions yet")
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: LoyaltyTransaction

    var body: some View {
        HStack {
            Image(systemName: transactionIcon)
                .foregroundColor(transactionColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(transaction.reason ?? transaction.transactionType.capitalized)
                    .font(AppFonts.subheadline)

                Text(transaction.createdAt.formatted(.dateTime.month().day().hour().minute()))
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text("\(transaction.points > 0 ? "+" : "")\(transaction.points)")
                .font(AppFonts.headline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.points > 0 ? .success : .error)
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.sm)
    }

    var transactionIcon: String {
        switch transaction.transactionType {
        case "earn":
            return "arrow.up.circle.fill"
        case "redeem":
            return "arrow.down.circle.fill"
        case "bonus":
            return "gift.fill"
        case "expire":
            return "clock.badge.xmark"
        default:
            return "arrow.left.arrow.right.circle.fill"
        }
    }

    var transactionColor: Color {
        switch transaction.transactionType {
        case "earn", "bonus":
            return .success
        case "redeem", "expire":
            return .error
        default:
            return .brandPrimary
        }
    }
}

// MARK: - Add Points View

struct AddPointsView: View {
    @Environment(\.dismiss) var dismiss
    let customerLoyaltyId: Int
    let onPointsAdded: () -> Void

    @State private var pointsToAdd = ""
    @State private var reason = ""
    @State private var isProcessing = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Points")) {
                    TextField("Points to add", text: $pointsToAdd)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Reason")) {
                    TextField("e.g., Birthday bonus", text: $reason)
                }

                Section {
                    Text("You can add or remove points by entering a positive or negative number.")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .navigationTitle("Add Points")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addPoints()
                    }
                    .fontWeight(.bold)
                    .disabled(pointsToAdd.isEmpty || reason.isEmpty || isProcessing)
                }
            }
        }
    }

    func addPoints() {
        guard let points = Int(pointsToAdd) else { return }

        isProcessing = true

        Task {
            do {
                try await SupabaseManager.shared.addLoyaltyPoints(
                    customerLoyaltyId: customerLoyaltyId,
                    points: points,
                    reason: reason
                )

                await MainActor.run {
                    isProcessing = false
                    onPointsAdded()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    print("❌ Error adding points: \(error)")
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CustomerLoyaltyView()
    }
}
