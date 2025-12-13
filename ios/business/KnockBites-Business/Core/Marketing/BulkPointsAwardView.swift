//
//  BulkPointsAwardView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct BulkPointsAwardView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = BulkPointsAwardViewModel()

    @State private var searchText = ""
    @State private var pointsAmount = ""
    @State private var reason = ""
    @State private var showConfirmation = false
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var isValid: Bool {
        !viewModel.selectedCustomers.isEmpty &&
        Int(pointsAmount) != nil &&
        !reason.isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                awardConfigurationSection

                Divider()

                customerSelectionSection
            }
            .navigationTitle("Bulk Points Award")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Award Points") {
                        showConfirmation = true
                    }
                    .fontWeight(.bold)
                    .disabled(!isValid || isProcessing)
                }
            }
            .onAppear {
                viewModel.loadCustomers()
            }
            .alert("Confirm Award", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Award") {
                    awardPoints()
                }
            } message: {
                if let points = Int(pointsAmount) {
                    Text("Award \(points) points to \(viewModel.selectedCustomers.count) customer(s) for: \(reason)")
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Points awarded successfully to \(viewModel.selectedCustomers.count) customer(s)!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    func awardPoints() {
        guard let points = Int(pointsAmount) else { return }

        isProcessing = true

        Task {
            do {
                try await viewModel.awardPoints(
                    customerIds: Array(viewModel.selectedCustomers),
                    points: points,
                    reason: reason
                )

                await MainActor.run {
                    isProcessing = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    // MARK: - Award Configuration Section

    private var awardConfigurationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Award Configuration")
                .font(AppFonts.title3)
                .fontWeight(.bold)

            // Points Amount
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Points to Award")
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)

                TextField("e.g., 100", text: $pointsAmount)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.md)
            }

            // Reason
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Reason")
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)

                TextField("e.g., Grand Opening Bonus", text: $reason)
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.md)
            }

            // Selection Summary
            selectionSummary
        }
        .padding()
        .background(Color.surface)
    }

    private var selectionSummary: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .foregroundColor(.brandPrimary)

            Text("\(viewModel.selectedCustomers.count) customers selected")
                .font(AppFonts.subheadline)
                .fontWeight(.semibold)

            Spacer()

            if !viewModel.selectedCustomers.isEmpty {
                Button("Clear All") {
                    viewModel.selectedCustomers.removeAll()
                }
                .font(AppFonts.caption)
                .foregroundColor(.error)
            }
        }
        .padding()
        .background(Color.brandPrimary.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Customer Selection Section

    private var customerSelectionSection: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            filterChips
            Divider()
            customerList
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)

            TextField("Search customers", text: $searchText)
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
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                FilterChip(
                    title: "All (\(viewModel.customers.count))",
                    isSelected: viewModel.selectedFilter == .all,
                    action: { viewModel.selectedFilter = .all }
                )

                FilterChip(
                    title: "Bronze",
                    isSelected: viewModel.selectedFilter == .bronze,
                    action: { viewModel.selectedFilter = .bronze }
                )

                FilterChip(
                    title: "Silver",
                    isSelected: viewModel.selectedFilter == .silver,
                    action: { viewModel.selectedFilter = .silver }
                )

                FilterChip(
                    title: "Gold",
                    isSelected: viewModel.selectedFilter == .gold,
                    action: { viewModel.selectedFilter = .gold }
                )

                FilterChip(
                    title: "Platinum",
                    isSelected: viewModel.selectedFilter == .platinum,
                    action: { viewModel.selectedFilter = .platinum }
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, Spacing.sm)
        .background(Color.surface)
    }

    private var customerList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.customers.isEmpty {
                EmptyStateView(
                    icon: "person.2.slash",
                    title: "No Customers Found",
                    message: "Customers will appear here once they join the loyalty program",
                    showBackground: false
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(viewModel.filteredCustomers(searchText: searchText)) { customer in
                            SelectableCustomerRow(
                                customer: customer,
                                isSelected: viewModel.selectedCustomers.contains(customer.id),
                                onToggle: {
                                    viewModel.toggleCustomerSelection(customerId: customer.id)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Selectable Customer Row

struct SelectableCustomerRow: View {
    let customer: CustomerLoyaltyListItem
    let isSelected: Bool
    let onToggle: () -> Void

    var tierColor: Color {
        switch customer.tierName.lowercased() {
        case "bronze": return Color(hex: "#CD7F32") ?? .orange
        case "silver": return Color(hex: "#C0C0C0") ?? .gray
        case "gold": return Color(hex: "#FFD700") ?? .yellow
        case "platinum": return Color(hex: "#E5E4E2") ?? .purple
        default: return .brandPrimary
        }
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.md) {
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .brandPrimary : .textSecondary)
                    .font(.title3)

                // Customer Avatar
                ZStack {
                    Circle()
                        .fill(tierColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text(customer.initials)
                        .font(AppFonts.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(tierColor)
                }

                // Customer Info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(customer.name)
                        .font(AppFonts.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        Text(customer.tierName)
                            .font(AppFonts.caption)
                            .foregroundColor(tierColor)

                        Text("•")
                            .foregroundColor(.textSecondary)

                        Text("\(customer.points) pts")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.brandPrimary.opacity(0.05) : Color.surface)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.brandPrimary : Color.surface)
                .cornerRadius(999)
        }
    }
}

#Preview {
    BulkPointsAwardView()
}
