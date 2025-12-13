//
//  FavoritesViewModel.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import Combine

@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favoriteItems: [MenuItem] = []
    @Published var favoriteItemIds: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let favoritesKey = "userFavorites"

    init() {
        loadFavoritesFromCache()
    }

    // MARK: - Fetch Favorites from Supabase
    func fetchFavorites() async {
        isLoading = true
        errorMessage = nil

        print("📥 Fetching favorites from Supabase...")

        do {
            let items = try await SupabaseManager.shared.getUserFavorites()
            favoriteItems = items
            favoriteItemIds = Set(items.map { $0.id })

            // Cache favorites for offline access
            saveFavoritesToCache()

            print("✅ Loaded \(items.count) favorite items from Supabase")
        } catch {
            print("❌ Failed to fetch favorites: \(error.localizedDescription)")
            errorMessage = "Failed to load favorites"

            // Fallback to cached favorites
            loadFavoritesFromCache()
        }

        isLoading = false
    }

    // MARK: - Check if Item is Favorite
    func isFavorite(_ itemId: String) -> Bool {
        favoriteItemIds.contains(itemId)
    }

    // MARK: - Check if Item is Favorite (Async - checks database)
    func checkIsFavorite(_ itemId: String) async -> Bool {
        do {
            return try await SupabaseManager.shared.isFavorited(menuItemId: itemId)
        } catch {
            print("❌ Failed to check favorite status: \(error.localizedDescription)")
            // Fallback to local state
            return favoriteItemIds.contains(itemId)
        }
    }

    // MARK: - Toggle Favorite (Async - syncs with Supabase)
    func toggleFavorite(_ item: MenuItem) async {
        print("🔄 Toggling favorite for: \(item.name)")

        // Optimistic update
        let wasOptimisticallyAdded = !favoriteItemIds.contains(item.id)
        if wasOptimisticallyAdded {
            favoriteItemIds.insert(item.id)
            favoriteItems.append(item)
        } else {
            favoriteItemIds.remove(item.id)
            favoriteItems.removeAll { $0.id == item.id }
        }

        do {
            let isFavorited = try await SupabaseManager.shared.toggleFavorite(menuItemId: item.id)

            print("✅ Favorite toggled successfully: \(isFavorited ? "Added" : "Removed")")

            // Refresh favorites to ensure sync
            await fetchFavorites()

            // Show toast feedback
            ToastManager.shared.show(
                isFavorited ? "Added to favorites" : "Removed from favorites",
                icon: isFavorited ? "heart.fill" : "heart",
                type: isFavorited ? .success : .info
            )
        } catch {
            print("❌ Failed to toggle favorite: \(error.localizedDescription)")

            // Revert optimistic update on failure
            if wasOptimisticallyAdded {
                favoriteItemIds.remove(item.id)
                favoriteItems.removeAll { $0.id == item.id }
            } else {
                favoriteItemIds.insert(item.id)
                favoriteItems.append(item)
            }

            ToastManager.shared.show(
                "Failed to update favorite",
                icon: "exclamationmark.triangle",
                type: .error
            )
        }
    }

    // MARK: - Synchronous Toggle (wraps async version for SwiftUI Button actions)
    func toggleFavorite(_ item: MenuItem) {
        Task {
            await toggleFavorite(item)
        }
    }

    // MARK: - Cache Management
    private func saveFavoritesToCache() {
        // Save favorite IDs
        let favoriteArray = Array(favoriteItemIds)
        UserDefaults.standard.set(favoriteArray, forKey: favoritesKey)

        // Save full items for offline access
        if let encoded = try? JSONEncoder().encode(favoriteItems) {
            UserDefaults.standard.set(encoded, forKey: "\(favoritesKey)_items")
        }
    }

    private func loadFavoritesFromCache() {
        // Load favorite IDs
        if let savedFavorites = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            favoriteItemIds = Set(savedFavorites)
        }

        // Load full items
        if let data = UserDefaults.standard.data(forKey: "\(favoritesKey)_items"),
           let items = try? JSONDecoder().decode([MenuItem].self, from: data) {
            favoriteItems = items
            print("📦 Loaded \(items.count) favorites from cache")
        }
    }

    // MARK: - Clear All Favorites
    func clearAllFavorites() async {
        isLoading = true

        // Clear all favorites by removing each one
        let itemsToRemove = favoriteItems
        for item in itemsToRemove {
            do {
                _ = try await SupabaseManager.shared.toggleFavorite(menuItemId: item.id)
            } catch {
                print("❌ Failed to remove favorite: \(item.name)")
            }
        }

        // Clear local state
        favoriteItemIds.removeAll()
        favoriteItems.removeAll()
        saveFavoritesToCache()

        isLoading = false

        ToastManager.shared.show(
            "All favorites cleared",
            icon: "trash",
            type: .info
        )
    }
}
