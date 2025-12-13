//
//  MenuView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject var viewModel: MenuViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var selectedItem: MenuItem?
    @State private var showItemDetail = false
    @State private var showFilterSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $viewModel.searchText)
                        .padding(.horizontal)
                        .padding(.top, Spacing.sm)

                    // Active Filters
                    if viewModel.hasActiveFilters {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(Array(viewModel.selectedDietaryTags).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { tag in
                                    FilterChip(text: tag.rawValue) {
                                        viewModel.selectedDietaryTags.remove(tag)
                                    }
                                }

                                if viewModel.priceRange != 0...50 {
                                    FilterChip(text: "$\(Int(viewModel.priceRange.lowerBound))-$\(Int(viewModel.priceRange.upperBound))") {
                                        viewModel.priceRange = 0...50
                                    }
                                }

                                if viewModel.sortOption != .none {
                                    FilterChip(text: viewModel.sortOption.rawValue) {
                                        viewModel.sortOption = .none
                                    }
                                }

                                Button(action: {
                                    withAnimation {
                                        viewModel.clearFilters()
                                    }
                                }) {
                                    Text("Clear All")
                                        .font(AppFonts.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.brandPrimary)
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, Spacing.xs)
                                        .background(Color.brandPrimary.opacity(0.1))
                                        .cornerRadius(CornerRadius.md)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, Spacing.xs)
                        }
                    }

                    // Category Tabs
                    if viewModel.searchText.isEmpty {
                        CategoryTabBar(
                            categories: viewModel.categories,
                            selectedCategory: $viewModel.selectedCategory
                        )
                        .padding(.vertical, Spacing.sm)
                    }

                    // Menu Items Grid
                    if let errorMessage = viewModel.errorMessage {
                        Spacer()
                        ErrorView(
                            title: "Unable to Load Menu",
                            message: errorMessage,
                            icon: "wifi.slash",
                            retryAction: {
                                Task {
                                    await viewModel.loadMenu()
                                }
                            }
                        )
                        Spacer()
                    } else if viewModel.isLoading {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ],
                                alignment: .center,
                                spacing: 16
                            ) {
                                ForEach(0..<6, id: \.self) { _ in
                                    MenuItemSkeleton()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 100)
                        }
                    } else if viewModel.filteredMenuItems.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "fork.knife",
                            title: "No Items Found",
                            message: viewModel.searchText.isEmpty
                                ? "Check back soon for new items!"
                                : "Try a different search term"
                        )
                        Spacer()
                    } else {
                        // Clean, consistent 2-column grid for menu items
                        // Grid uses .flexible() columns to adapt to screen width
                        // Horizontal spacing: 12px between columns
                        // Vertical spacing: 16px between rows
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ],
                                alignment: .center,
                                spacing: 16
                            ) {
                                ForEach(viewModel.filteredMenuItems) { item in
                                    Button(action: {
                                        selectedItem = item
                                        showItemDetail = true
                                    }) {
                                        MenuItemCard(item: item) {
                                            quickAddToCart(item)
                                        }
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 100)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.selectedCategory?.id)
                        }
                    }
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilterSheet = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.brandPrimary)

                            if viewModel.hasActiveFilters {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
            }
            .task {
                await viewModel.loadMenu()
            }
            .sheet(isPresented: $showItemDetail) {
                if let item = selectedItem {
                    ItemDetailView(item: item)
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheet(viewModel: viewModel)
            }
        }
    }

    private func quickAddToCart(_ item: MenuItem) {
        // If item has required customizations, show detail view
        if item.customizationGroups.contains(where: { $0.isRequired }) {
            selectedItem = item
            showItemDetail = true
        } else {
            // Quick add with defaults
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                cartViewModel.addItem(menuItem: item, quantity: 1)
            }
            // Show success toast
            ToastManager.shared.show(
                "Added to cart!",
                icon: "checkmark.circle.fill",
                type: .success
            )
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)

            TextField("Search menu...", text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Category Tab Bar
struct CategoryTabBar: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // "All" button
                CategoryChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation {
                        selectedCategory = nil
                    }
                }

                // Category buttons
                ForEach(categories) { category in
                    CategoryChip(
                        title: category.name,
                        icon: nil,
                        emoji: category.icon,
                        isSelected: selectedCategory?.id == category.id
                    ) {
                        withAnimation {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let icon: String?
    var emoji: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String?,
        emoji: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.emoji = emoji
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                if let emoji = emoji {
                    Text(emoji)
                }
                Text(title)
                    .font(AppFonts.subheadline)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.brandPrimary : Color.surface)
            .foregroundColor(isSelected ? .white : .textPrimary)
            .cornerRadius(CornerRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .stroke(isSelected ? Color.clear : Color.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Text(text)
                    .font(AppFonts.caption)
                    .fontWeight(.medium)

                Image(systemName: "xmark")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.brandPrimary)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    MenuView()
        .environmentObject(MenuViewModel())
        .environmentObject(CartViewModel())
}
