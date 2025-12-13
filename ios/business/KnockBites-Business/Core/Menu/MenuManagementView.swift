//
//  MenuManagementView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct MenuManagementView: View {
    @StateObject private var viewModel = MenuManagementViewModel()
    @State private var selectedCategory: String? = nil // nil = "All Items"
    @State private var showAddItem = false
    @State private var itemToEdit: MenuItem?
    @State private var appError: AppError?

    // Filtered menu items based on selected category
    var filteredItems: [MenuItem] {
        if let categoryId = selectedCategory {
            return viewModel.menuItems.filter { $0.categoryId == categoryId }
        }
        return viewModel.menuItems
    }

    // Group filtered items by category
    var groupedItems: [(category: Category, items: [MenuItem])] {
        viewModel.categories.compactMap { category in
            let items = filteredItems.filter { $0.categoryId == category.id }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter Tabs
                if !viewModel.isLoading {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            // "All Items" tab
                            CategoryTab(
                                title: "All Items",
                                icon: "square.grid.2x2",
                                count: viewModel.menuItems.count,
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )

                            // Category tabs
                            ForEach(viewModel.categories) { category in
                                let itemCount = viewModel.menuItems.filter { $0.categoryId == category.id }.count
                                CategoryTab(
                                    title: category.name,
                                    icon: category.icon,
                                    count: itemCount,
                                    isSelected: selectedCategory == category.id,
                                    action: { selectedCategory = category.id }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, Spacing.sm)
                    }
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
                }

                // Menu Items List
                ZStack {
                    if viewModel.isLoading {
                        LoadingStateView(message: "Loading menu...")
                    } else if viewModel.menuItems.isEmpty {
                        EmptyStateView(
                            icon: "menucard",
                            title: "No Menu Items",
                            message: "Add your first menu item to get started",
                            showBackground: false
                        )
                    } else {
                        List {
                            ForEach(groupedItems, id: \.category.id) { group in
                                Section(header: HStack {
                                    Text("\(group.category.icon) \(group.category.name)")
                                        .font(AppFonts.headline)
                                }) {
                                    ForEach(group.items) { item in
                                        MenuItemRow(item: item, viewModel: viewModel) {
                                            itemToEdit = item
                                        }
                                    }
                                }
                            }
                        }
                        .refreshable {
                            viewModel.loadMenu()
                        }
                    }
                }
            }
            .navigationTitle("Menu Management")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddItem = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddMenuItemView(onSave: { updatedItem in
                    viewModel.addMenuItem(updatedItem)
                })
            }
            .sheet(item: $itemToEdit) { item in
                AddMenuItemView(itemToEdit: item, onSave: { updatedItem in
                    viewModel.updateMenuItem(updatedItem)
                })
            }
            .appErrorAlert(error: $appError) {
                viewModel.loadMenu()
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if let message = newValue {
                    appError = AppError.from(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
                    viewModel.errorMessage = nil
                }
            }
        }
        .onAppear {
            viewModel.loadMenu()
        }
    }
}

// MARK: - Menu Item Row
struct MenuItemRow: View {
    let item: MenuItem
    @ObservedObject var viewModel: MenuManagementViewModel
    let onTap: () -> Void

    @State private var isEditingPrice = false
    @State private var editedPrice = ""
    @FocusState private var isPriceFocused: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.name)
                    .font(AppFonts.body)
                    .foregroundColor(.textPrimary)

                HStack(spacing: 8) {
                    // Price editing
                    if isEditingPrice {
                        HStack(spacing: 4) {
                            Text("$")
                                .font(AppFonts.subheadline)
                                .foregroundColor(.brandPrimary)
                            TextField("0.00", text: $editedPrice)
                                .font(AppFonts.subheadline)
                                .foregroundColor(.brandPrimary)
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                                .textFieldStyle(.plain)
                                .focused($isPriceFocused)

                            // Green checkmark to save
                            Button(action: savePrice) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.plain)

                            // Cancel button
                            Button(action: cancelEditing) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        // Tap to edit price
                        Button(action: startEditing) {
                            Text(item.formattedPrice)
                                .font(AppFonts.subheadline)
                                .foregroundColor(.brandPrimary)
                                .underline(true, color: .brandPrimary.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                    }

                    if let calories = item.calories {
                        Text("• \(calories) cal")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Text("• \(item.prepTime) min")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            if !isEditingPrice {
                // Edit button (pencil icon)
                Button(action: onTap) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.brandPrimary)
                        .font(.system(size: 24))
                }
                .buttonStyle(.plain)

                // Availability toggle
                Toggle("", isOn: Binding(
                    get: { item.isAvailable },
                    set: { newValue in
                        viewModel.toggleAvailability(for: item.id, available: newValue)
                    }
                ))
                .labelsHidden()
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private func startEditing() {
        editedPrice = String(format: "%.2f", item.price)
        isEditingPrice = true
        isPriceFocused = true
    }

    private func cancelEditing() {
        isEditingPrice = false
        editedPrice = ""
    }

    private func savePrice() {
        guard let newPrice = Double(editedPrice), newPrice > 0 else {
            cancelEditing()
            return
        }

        viewModel.updateItemPrice(for: item.id, newPrice: newPrice)
        isEditingPrice = false
        editedPrice = ""
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                    Text(title)
                        .font(AppFonts.subheadline)
                        .fontWeight(.semibold)
                    Text("(\(count))")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
                .foregroundColor(isSelected ? .white : .textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.brandPrimary : Color(.systemGray6))
                )
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MenuManagementView()
}
