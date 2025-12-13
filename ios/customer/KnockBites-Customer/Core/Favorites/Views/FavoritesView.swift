//
//  FavoritesView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var selectedItem: MenuItem?
    @State private var showItemDetail = false

    var favoriteItems: [MenuItem] {
        favoritesViewModel.favoriteItems
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                if favoritesViewModel.isLoading && favoriteItems.isEmpty {
                    // Loading State (first load)
                    LoadingView(message: "Loading favorites...")
                } else if favoriteItems.isEmpty {
                    // Empty State
                    VStack(spacing: Spacing.xl) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.3))

                        VStack(spacing: Spacing.md) {
                            Text("No Favorites Yet")
                                .font(AppFonts.title2)
                                .foregroundColor(.textPrimary)

                            Text("Tap the heart icon on any menu item to save it here")
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.xl)
                        }
                    }
                } else {
                    // Favorites Grid
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: Spacing.md),
                                GridItem(.flexible(), spacing: Spacing.md)
                            ],
                            spacing: Spacing.md
                        ) {
                            ForEach(favoriteItems) { item in
                                Button(action: {
                                    selectedItem = item
                                    showItemDetail = true
                                }) {
                                    MenuItemCard(
                                        item: item,
                                        onQuickAdd: {
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                                cartViewModel.addItem(menuItem: item, quantity: 1)
                                            }
                                            ToastManager.shared.show(
                                                "Added to cart!",
                                                icon: "checkmark.circle.fill",
                                                type: .success
                                            )
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await favoritesViewModel.fetchFavorites()
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !favoriteItems.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: {
                                Task {
                                    await favoritesViewModel.clearAllFavorites()
                                }
                            }) {
                                Label("Clear All Favorites", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showItemDetail) {
                if let item = selectedItem {
                    ItemDetailView(item: item)
                }
            }
            .task {
                // Fetch favorites when view appears
                await favoritesViewModel.fetchFavorites()
            }
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(FavoritesViewModel())
        .environmentObject(CartViewModel())
}
