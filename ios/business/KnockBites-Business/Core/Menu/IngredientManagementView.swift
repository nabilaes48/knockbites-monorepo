//
//  IngredientManagementView.swift
//  KnockBites-Business
//
//  Created by Claude Code on 12/31/25.
//  Full Ingredient Pricing Management View
//

import SwiftUI

struct IngredientManagementView: View {
    @StateObject private var viewModel = IngredientManagementViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats Header
                if !viewModel.isLoading {
                    statsHeader
                        .padding()
                        .background(Color(.systemBackground))
                }

                // Category Filter
                if !viewModel.isLoading {
                    categoryFilterTabs
                        .padding(.horizontal)
                        .padding(.bottom, Spacing.sm)
                }

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search ingredients...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                }
                .padding(Spacing.md)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadius.md)
                .padding(.horizontal)
                .padding(.bottom, Spacing.sm)

                // Main Content
                if viewModel.isLoading {
                    LoadingStateView(message: "Loading ingredients...")
                } else if viewModel.groupedIngredients.isEmpty {
                    EmptyStateView(
                        icon: "leaf.fill",
                        title: "No Ingredients",
                        message: "Add your first ingredient to get started",
                        showBackground: false
                    )
                } else {
                    ingredientsList
                }
            }
            .navigationTitle("Ingredient Pricing")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.startAdding() }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showEditSheet) {
                ingredientEditSheet
            }
            .sheet(isPresented: $viewModel.showAddSheet) {
                ingredientEditSheet
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear {
            viewModel.loadIngredients()
        }
    }

    // MARK: - Stats Header
    private var statsHeader: some View {
        HStack(spacing: Spacing.lg) {
            StatCard(
                title: "Total",
                value: "\(viewModel.totalCount)",
                color: .brandPrimary,
                icon: "leaf.fill"
            )
            StatCard(
                title: "Active",
                value: "\(viewModel.activeCount)",
                color: .green,
                icon: "checkmark.circle.fill"
            )
            StatCard(
                title: "Premium",
                value: "\(viewModel.premiumCount)",
                color: .purple,
                icon: "dollarsign.circle.fill"
            )
        }
    }

    // MARK: - Category Filter Tabs
    private var categoryFilterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // All tab
                CategoryFilterChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: viewModel.selectedCategory == nil,
                    color: .brandPrimary
                ) {
                    viewModel.selectedCategory = nil
                }

                // Category tabs
                ForEach(IngredientCategory.allCases, id: \.self) { category in
                    CategoryFilterChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category,
                        color: category.color
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
    }

    // MARK: - Ingredients List
    private var ingredientsList: some View {
        List {
            ForEach(viewModel.groupedIngredients, id: \.category) { group in
                Section {
                    ForEach(group.items) { ingredient in
                        IngredientRow(
                            ingredient: ingredient,
                            onEdit: { viewModel.startEditing(ingredient) },
                            onToggle: { viewModel.toggleActive(ingredient) },
                            onDelete: { viewModel.deleteIngredient(ingredient) }
                        )
                    }
                } header: {
                    HStack {
                        Image(systemName: group.category.icon)
                            .foregroundColor(group.category.color)
                        Text(group.category.displayName)
                            .font(AppFonts.headline)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.loadIngredients()
        }
    }

    // MARK: - Edit Sheet
    private var ingredientEditSheet: some View {
        NavigationView {
            Form {
                // Name Section
                Section("Ingredient Details") {
                    TextField("Name", text: $viewModel.editName)

                    Picker("Category", selection: $viewModel.editCategory) {
                        ForEach(IngredientCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }

                    Toggle("Active", isOn: $viewModel.editIsActive)
                }

                // Pricing Section
                Section {
                    PricingRow(label: "Light", price: $viewModel.editLightPrice)
                    PricingRow(label: "Regular", price: $viewModel.editRegularPrice)
                    PricingRow(label: "Extra", price: $viewModel.editExtraPrice)
                } header: {
                    Text("Portion Pricing")
                } footer: {
                    Text("Set to $0.00 for free ingredients. Premium extras like cheese and bacon typically charge $1.50-$2.50.")
                }
            }
            .navigationTitle(viewModel.editingIngredient == nil ? "Add Ingredient" : "Edit Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showEditSheet = false
                        viewModel.showAddSheet = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveIngredient()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(AppFonts.title2)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}

private struct CategoryFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(AppFonts.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .foregroundColor(isSelected ? .white : color)
            .background(isSelected ? color : color.opacity(0.15))
            .cornerRadius(CornerRadius.full)
        }
        .buttonStyle(.plain)
    }
}

private struct IngredientRow: View {
    let ingredient: IngredientTemplate
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteAlert = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Ingredient Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(ingredient.name)
                        .font(AppFonts.body)
                        .foregroundColor(ingredient.isActive ? .primary : .secondary)

                    if ingredient.isPremium {
                        Text("$")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .cornerRadius(4)
                    }

                    if !ingredient.isActive {
                        Text("Inactive")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.gray)
                            .cornerRadius(4)
                    }
                }

                // Pricing info
                HStack(spacing: Spacing.md) {
                    PriceLabel(label: "L", price: ingredient.portionPricing.light)
                    PriceLabel(label: "R", price: ingredient.portionPricing.regular)
                    PriceLabel(label: "X", price: ingredient.portionPricing.extra)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: Spacing.sm) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.brandPrimary)
                }
                .buttonStyle(.plain)

                Toggle("", isOn: Binding(
                    get: { ingredient.isActive },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Ingredient?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Are you sure you want to delete '\(ingredient.name)'? This cannot be undone.")
        }
    }
}

private struct PriceLabel: View {
    let label: String
    let price: Double

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            Text(price > 0 ? String(format: "$%.2f", price) : "Free")
                .font(.caption)
                .foregroundColor(price > 0 ? .green : .secondary)
        }
    }
}

private struct PricingRow: View {
    let label: String
    @Binding var price: Double

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HStack {
                Text("$")
                    .foregroundColor(.secondary)
                TextField("0.00", value: $price, format: .number.precision(.fractionLength(2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
    }
}

#Preview {
    IngredientManagementView()
}
