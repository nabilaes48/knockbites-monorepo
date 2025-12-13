//
//  MenuRepository.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 5 cleanup - consolidated menu data access
//  Updated Phase 9 - Added caching layer
//

import Foundation
import Supabase

/// Repository for all menu-related data operations
class MenuRepository {
    static let shared = MenuRepository()

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    // MARK: - Caching
    private let menuItemsCache = DataCache<[MenuItem]>(defaultTTL: CacheTTL.medium)
    private let categoriesCache = DataCache<[Category]>(defaultTTL: CacheTTL.long)
    private let ingredientTemplatesCache = DataCache<[IngredientTemplate]>(defaultTTL: CacheTTL.long)

    private init() {}

    // MARK: - Menu Items

    func fetchMenuItems(forceRefresh: Bool = false) async throws -> [MenuItem] {
        // Check cache first
        if !forceRefresh, let cached = await menuItemsCache.get(CacheKeys.menuItems) {
            print("📦 Returning cached menu items (\(cached.count) items)")
            return cached
        }

        print("🔄 Fetching menu items from Supabase...")

        struct DBMenuItem: Codable {
            let id: Int
            let name: String
            let description: String
            let price: Double
            let categoryId: Int
            let imageUrl: String?
            let isAvailable: Bool
            let calories: Int?
            let prepTime: Int?

            enum CodingKeys: String, CodingKey {
                case id, name, description, price
                case categoryId = "category_id"
                case imageUrl = "image_url"
                case isAvailable = "is_available"
                case calories
                case prepTime = "prep_time"
            }
        }

        let items: [DBMenuItem] = try await client
            .from(TableNames.menuItems)
            .select()
            .execute()
            .value

        let menuItems = items.map { item in
            MenuItem(
                id: String(item.id),
                name: item.name,
                description: item.description,
                price: item.price,
                categoryId: String(item.categoryId),
                imageURL: item.imageUrl ?? "",
                isAvailable: item.isAvailable,
                dietaryInfo: [],
                customizationGroups: [],
                calories: item.calories,
                prepTime: item.prepTime ?? 15
            )
        }

        print("✅ Fetched \(menuItems.count) menu items")

        // Cache the result
        await menuItemsCache.set(CacheKeys.menuItems, value: menuItems)

        return menuItems
    }

    /// Invalidate menu items cache (call after updates)
    func invalidateMenuItemsCache() async {
        await menuItemsCache.invalidate(CacheKeys.menuItems)
    }

    // MARK: - Categories

    func fetchCategories(forceRefresh: Bool = false) async throws -> [Category] {
        // Check cache first
        if !forceRefresh, let cached = await categoriesCache.get(CacheKeys.categories) {
            print("📦 Returning cached categories (\(cached.count) items)")
            return cached
        }

        print("🔄 Fetching categories from Supabase...")

        struct DBCategory: Codable {
            let id: Int
            let name: String
            let icon: String?
        }

        let categories: [DBCategory] = try await client
            .from(TableNames.menuCategories)
            .select()
            .order("id", ascending: true)
            .execute()
            .value

        let result = categories.map { category in
            Category(
                id: String(category.id),
                name: category.name,
                icon: category.icon ?? "🍽️",
                sortOrder: category.id
            )
        }

        print("✅ Fetched \(result.count) categories")

        // Cache the result
        await categoriesCache.set(CacheKeys.categories, value: result)

        return result
    }

    // MARK: - Update Menu Items

    func updateMenuItemAvailability(itemId: String, isAvailable: Bool) async throws {
        print("🔄 Updating menu item \(itemId) availability to: \(isAvailable)")

        guard let id = Int(itemId) else {
            throw NSError(domain: "MenuRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid item ID"])
        }

        try await client
            .from(TableNames.menuItems)
            .update(["is_available": isAvailable])
            .eq("id", value: id)
            .execute()

        // Invalidate cache after update
        await invalidateMenuItemsCache()

        print("✅ Menu item availability updated successfully")
    }

    func updateMenuItemPrice(itemId: String, price: Double) async throws {
        print("🔄 Updating menu item \(itemId) price to: $\(String(format: "%.2f", price))")

        guard let id = Int(itemId) else {
            throw NSError(domain: "MenuRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid item ID"])
        }

        try await client
            .from(TableNames.menuItems)
            .update(["price": price])
            .eq("id", value: id)
            .execute()

        // Invalidate cache after update
        await invalidateMenuItemsCache()

        print("✅ Menu item price updated successfully")
    }

    // MARK: - Ingredient Templates & Customizations

    func fetchIngredientTemplates() async throws -> [IngredientTemplate] {
        print("🔄 Fetching ingredient templates...")

        let response: [IngredientTemplate] = try await client
            .from(TableNames.ingredientTemplates)
            .select()
            .eq("is_active", value: true)
            .order("category")
            .order("display_order")
            .execute()
            .value

        print("✅ Fetched \(response.count) ingredient templates")
        return response
    }

    func fetchIngredientTemplates(category: IngredientCategory) async throws -> [IngredientTemplate] {
        print("🔄 Fetching \(category.rawValue) ingredients...")

        let response: [IngredientTemplate] = try await client
            .from(TableNames.ingredientTemplates)
            .select()
            .eq("is_active", value: true)
            .eq("category", value: category.rawValue)
            .order("display_order")
            .execute()
            .value

        print("✅ Fetched \(response.count) \(category.rawValue) ingredients")
        return response
    }

    func fetchMenuItemCustomizations(menuItemId: Int) async throws -> [MenuItemCustomization] {
        print("🔄 Fetching customizations for menu item \(menuItemId)...")

        let response: [MenuItemCustomization] = try await client
            .from(TableNames.menuItemCustomizations)
            .select()
            .eq("menu_item_id", value: menuItemId)
            .order("category")
            .order("display_order")
            .execute()
            .value

        print("✅ Fetched \(response.count) customizations for menu item \(menuItemId)")
        return response
    }

    func fetchPortionCustomizations(menuItemId: Int) async throws -> [MenuItemCustomization] {
        print("🔄 Fetching portion customizations for menu item \(menuItemId)...")

        let response: [MenuItemCustomization] = try await client
            .from(TableNames.menuItemCustomizations)
            .select()
            .eq("menu_item_id", value: menuItemId)
            .eq("supports_portions", value: true)
            .order("category")
            .order("display_order")
            .execute()
            .value

        print("✅ Fetched \(response.count) portion customizations")
        return response
    }
}
