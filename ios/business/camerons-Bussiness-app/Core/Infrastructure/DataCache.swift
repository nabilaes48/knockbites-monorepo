//
//  DataCache.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 9 - Lightweight in-memory caching for repositories
//

import Foundation

/// A lightweight, thread-safe in-memory cache with TTL support.
/// Used by repositories to reduce redundant Supabase calls.
actor DataCache<T> {
    private struct CacheEntry {
        let value: T
        let expiresAt: Date
    }

    private var storage: [String: CacheEntry] = [:]
    private let defaultTTL: TimeInterval

    init(defaultTTL: TimeInterval = 30) {
        self.defaultTTL = defaultTTL
    }

    /// Get cached value if not expired
    func get(_ key: String) -> T? {
        guard let entry = storage[key] else { return nil }

        if Date() < entry.expiresAt {
            return entry.value
        } else {
            // Expired - remove entry
            storage.removeValue(forKey: key)
            return nil
        }
    }

    /// Set value with optional custom TTL
    func set(_ key: String, value: T, ttl: TimeInterval? = nil) {
        let expiresAt = Date().addingTimeInterval(ttl ?? defaultTTL)
        storage[key] = CacheEntry(value: value, expiresAt: expiresAt)
    }

    /// Invalidate a specific key
    func invalidate(_ key: String) {
        storage.removeValue(forKey: key)
    }

    /// Invalidate all keys matching a prefix
    func invalidatePrefix(_ prefix: String) {
        storage = storage.filter { !$0.key.hasPrefix(prefix) }
    }

    /// Clear all cached data
    func clear() {
        storage.removeAll()
    }

    /// Check if key exists and is not expired
    func has(_ key: String) -> Bool {
        guard let entry = storage[key] else { return false }
        return Date() < entry.expiresAt
    }
}

/// Cache key builders for consistent key naming
enum CacheKeys {
    // Menu
    static let menuItems = "menu_items"
    static let categories = "menu_categories"
    static func ingredientTemplates(category: String? = nil) -> String {
        if let category = category {
            return "ingredient_templates_\(category)"
        }
        return "ingredient_templates_all"
    }

    // Marketing
    static func coupons(storeId: Int) -> String { "coupons_\(storeId)" }
    static func loyaltyProgram(storeId: Int) -> String { "loyalty_program_\(storeId)" }
    static func loyaltyTiers(programId: Int) -> String { "loyalty_tiers_\(programId)" }
    static func rewards(programId: Int) -> String { "rewards_\(programId)" }
    static func customers(storeId: Int) -> String { "customers_\(storeId)" }

    // Analytics
    static func analyticsSummary(storeId: Int, period: String) -> String {
        "analytics_summary_\(storeId)_\(period)"
    }
    static func dailySales(storeId: Int, days: Int) -> String {
        "daily_sales_\(storeId)_\(days)"
    }
    static func topItems(storeId: Int, days: Int) -> String {
        "top_items_\(storeId)_\(days)"
    }

    // Orders (short TTL due to real-time nature)
    static func orders(storeId: Int) -> String { "orders_\(storeId)" }
}

/// TTL presets for different data types
enum CacheTTL {
    /// For real-time critical data like orders (5 seconds)
    static let realtime: TimeInterval = 5

    /// For frequently changing data like coupons (15 seconds)
    static let short: TimeInterval = 15

    /// For relatively stable data like menu items (30 seconds)
    static let medium: TimeInterval = 30

    /// For rarely changing data like categories (60 seconds)
    static let long: TimeInterval = 60

    /// For configuration-like data (5 minutes)
    static let extended: TimeInterval = 300
}
