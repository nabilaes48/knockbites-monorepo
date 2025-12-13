//
//  HomeView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var menuViewModel: MenuViewModel
    @Environment(\.selectedTab) private var selectedTab
    @State private var selectedItem: MenuItem?
    @State private var showItemDetail = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Welcome Header
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Welcome back!")
                                    .font(AppFonts.body)
                                    .foregroundColor(.textSecondary)

                                Text("KnockBites")
                                    .font(AppFonts.largeTitle)
                                    .foregroundColor(.textPrimary)
                            }

                            Spacer()

                            // Points Badge
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.warning)
                                Text("0")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.textPrimary)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.warning.opacity(0.15))
                            .cornerRadius(CornerRadius.xl)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Store Selector
                        VStack(spacing: Spacing.sm) {
                            StoreSelectorButton(selectedStore: $cartViewModel.selectedStore)
                                .padding(.horizontal)
                        }

                        // Quick Action Cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.md) {
                                QuickActionCard(
                                    icon: "fork.knife",
                                    title: "Browse Menu",
                                    color: .brandPrimary
                                ) {
                                    // Navigation handled by tab
                                }

                                QuickActionCard(
                                    icon: "bag.fill",
                                    title: "My Orders",
                                    color: .brandSecondary
                                ) {
                                    // Navigation handled by tab
                                }

                                QuickActionCard(
                                    icon: "star.fill",
                                    title: "Rewards",
                                    color: .warning
                                ) {
                                    // Navigation handled by tab
                                }

                                QuickActionCard(
                                    icon: "mappin.circle.fill",
                                    title: "Locations",
                                    color: .error
                                ) {
                                    // Show store selector
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Featured Items
                        if !menuViewModel.featuredItems.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Featured Items")
                                    .font(AppFonts.title3)
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Spacing.md) {
                                        ForEach(menuViewModel.featuredItems) { item in
                                            Button(action: {
                                                selectedItem = item
                                                showItemDetail = true
                                            }) {
                                                FeaturedItemCard(item: item)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Categories Grid
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Categories")
                                .font(AppFonts.title3)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: Spacing.md
                            ) {
                                ForEach(menuViewModel.categories.prefix(6)) { category in
                                    Button(action: {
                                        // Navigate to Menu tab and select category
                                        menuViewModel.selectCategory(category)
                                        selectedTab.wrappedValue = 1 // Menu tab
                                    }) {
                                        CategoryCard(category: category)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationBarHidden(true)
            .task {
                await menuViewModel.loadMenu()
            }
            .sheet(isPresented: $showItemDetail) {
                if let item = selectedItem {
                    ItemDetailView(item: item)
                }
            }
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.15))
                    .cornerRadius(CornerRadius.md)

                Text(title)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 100)
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

// MARK: - Featured Item Card
struct FeaturedItemCard: View {
    let item: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            AsyncImage(url: URL(string: item.imageURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    // Gradient placeholder
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: gradientColorsFor(item)),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        VStack(spacing: 8) {
                            Text(String(item.name.prefix(1)).uppercased())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)

                            Image(systemName: "fork.knife")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 200, height: 140)
            .clipped()

            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.name)
                    .font(AppFonts.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Text(item.description)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)

                HStack {
                    Text(item.formattedPrice)
                        .font(AppFonts.headline)
                        .foregroundColor(.brandPrimary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("\(item.prepTime) min")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                }
            }
            .padding(Spacing.sm)
        }
        .frame(width: 200)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
    }

    private func gradientColorsFor(_ item: MenuItem) -> [Color] {
        // Generate colors based on category ID for consistency
        let categoryHash = item.categoryId.hashValue
        let colorSets: [[Color]] = [
            [Color(red: 0.95, green: 0.35, blue: 0.24), Color(red: 0.96, green: 0.56, blue: 0.24)], // Red-Orange
            [Color(red: 0.35, green: 0.67, blue: 0.95), Color(red: 0.45, green: 0.82, blue: 0.95)], // Blue
            [Color(red: 0.67, green: 0.35, blue: 0.95), Color(red: 0.82, green: 0.45, blue: 0.95)], // Purple
            [Color(red: 0.35, green: 0.95, blue: 0.67), Color(red: 0.45, green: 0.95, blue: 0.82)], // Green
            [Color(red: 0.95, green: 0.67, blue: 0.35), Color(red: 0.95, green: 0.82, blue: 0.45)], // Orange-Yellow
            [Color(red: 0.95, green: 0.35, blue: 0.67), Color(red: 0.95, green: 0.45, blue: 0.82)]  // Pink
        ]

        return colorSets[abs(categoryHash) % colorSets.count]
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: Category

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text(category.icon)
                .font(.system(size: 40))

            Text(category.name)
                .font(AppFonts.subheadline)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
    HomeView()
        .environmentObject(CartViewModel())
        .environmentObject(MenuViewModel())
}
