//
//  MenuViewModel.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import Combine

@MainActor
class MenuViewModel: ObservableObject {
    @Published var allMenuItems: [MenuItem] = []
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var searchText: String = ""
    @Published var selectedStore: Store?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Advanced Filters
    @Published var priceRange: ClosedRange<Double> = 0...50
    @Published var selectedDietaryTags: Set<DietaryTag> = []
    @Published var sortOption: SortOption = .none

    // Search History
    @Published var searchHistory: [String] = []
    @Published var showSearchHistory = false

    // Recently Viewed
    @Published var recentlyViewedIds: [String] = []

    private let mockDataService = MockDataService.shared
    private let maxHistoryItems = 20
    private let maxRecentlyViewed = 50

    init() {
        loadSearchHistory()
        loadRecentlyViewed()
    }

    var recentlyViewedItems: [MenuItem] {
        recentlyViewedIds.compactMap { id in
            allMenuItems.first { $0.id == id }
        }
    }

    var hasActiveFilters: Bool {
        !selectedDietaryTags.isEmpty || priceRange != 0...50 || sortOption != .none
    }

    var filteredMenuItems: [MenuItem] {
        var items = allMenuItems

        // Filter by category
        if let category = selectedCategory {
            items = items.filter { $0.categoryId == category.id }
        }

        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by price range
        items = items.filter { item in
            item.price >= priceRange.lowerBound && item.price <= priceRange.upperBound
        }

        // Filter by dietary tags
        if !selectedDietaryTags.isEmpty {
            items = items.filter { item in
                !Set(item.dietaryInfo).isDisjoint(with: selectedDietaryTags)
            }
        }

        // Only show available items
        items = items.filter { $0.isAvailable }

        // Sort items
        switch sortOption {
        case .none:
            break
        case .priceLowToHigh:
            items.sort { $0.price < $1.price }
        case .priceHighToLow:
            items.sort { $0.price > $1.price }
        case .nameAZ:
            items.sort { $0.name < $1.name }
        case .prepTimeShort:
            items.sort { $0.prepTime < $1.prepTime }
        }

        return items
    }

    var featuredItems: [MenuItem] {
        // Return first 4 available items as "featured"
        Array(allMenuItems.filter { $0.isAvailable }.prefix(4))
    }

    // MARK: - Load Data
    func loadMenu() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch categories and menu items from Supabase
            async let categoriesTask = SupabaseManager.shared.fetchCategories()
            async let menuItemsTask = SupabaseManager.shared.fetchMenuItems()

            categories = try await categoriesTask
            allMenuItems = try await menuItemsTask

            print("✅ Loaded \(categories.count) categories and \(allMenuItems.count) menu items from Supabase")

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ Failed to load menu: \(error)")
            ToastManager.shared.show(
                "Failed to load menu",
                icon: "wifi.slash",
                type: .error
            )
        }
    }

    // MARK: - Category Selection
    func selectCategory(_ category: Category?) {
        withAnimation {
            selectedCategory = category
        }
    }

    // MARK: - Search
    func clearSearch() {
        searchText = ""
    }

    func performSearch(_ query: String) {
        searchText = query
        saveSearch(query)
        showSearchHistory = false
    }

    // MARK: - Search History
    private func saveSearch(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else { return }
        guard trimmedQuery.count >= 2 else { return } // Only save searches 2+ characters

        // Remove if already exists (to move to front)
        searchHistory.removeAll { $0.lowercased() == trimmedQuery.lowercased() }

        // Add to front
        searchHistory.insert(trimmedQuery, at: 0)

        // Keep only last N items
        if searchHistory.count > maxHistoryItems {
            searchHistory = Array(searchHistory.prefix(maxHistoryItems))
        }

        // Save to UserDefaults
        UserDefaults.standard.set(searchHistory, forKey: "searchHistory")
    }

    private func loadSearchHistory() {
        if let saved = UserDefaults.standard.stringArray(forKey: "searchHistory") {
            searchHistory = saved
        }
    }

    func clearSearchHistory() {
        searchHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: "searchHistory")
    }

    func deleteSearchHistoryItem(_ query: String) {
        searchHistory.removeAll { $0 == query }
        UserDefaults.standard.set(searchHistory, forKey: "searchHistory")
    }

    // MARK: - Recently Viewed
    func trackItemView(_ item: MenuItem) {
        // Remove if already exists (to move to front)
        recentlyViewedIds.removeAll { $0 == item.id }

        // Add to front
        recentlyViewedIds.insert(item.id, at: 0)

        // Keep only last N items
        if recentlyViewedIds.count > maxRecentlyViewed {
            recentlyViewedIds = Array(recentlyViewedIds.prefix(maxRecentlyViewed))
        }

        // Save to UserDefaults
        UserDefaults.standard.set(recentlyViewedIds, forKey: "recentlyViewedItems")
    }

    private func loadRecentlyViewed() {
        if let saved = UserDefaults.standard.stringArray(forKey: "recentlyViewedItems") {
            recentlyViewedIds = saved
        }
    }

    func clearRecentlyViewed() {
        recentlyViewedIds.removeAll()
        UserDefaults.standard.removeObject(forKey: "recentlyViewedItems")
    }

    // MARK: - Clear Filters
    func clearFilters() {
        withAnimation {
            priceRange = 0...50
            selectedDietaryTags.removeAll()
            sortOption = .none
        }
    }
}

// MARK: - Sort Option
enum SortOption: String, CaseIterable {
    case none = "Default"
    case priceLowToHigh = "Price: Low to High"
    case priceHighToLow = "Price: High to Low"
    case nameAZ = "Name: A-Z"
    case prepTimeShort = "Prep Time: Shortest"
}
