//
//  IngredientModels.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//  Portion-Based Customization System - Data Models
//

import Foundation
import SwiftUI

// MARK: - Portion Level Enum

/// Represents the portion size level for an ingredient
enum PortionLevel: String, Codable, CaseIterable {
    case none, light, regular, extra

    /// Visual emoji representation
    var emoji: String {
        switch self {
        case .none: return "○"
        case .light: return "◔"
        case .regular: return "◑"
        case .extra: return "●"
        }
    }

    /// Display name for UI
    var displayName: String {
        rawValue.capitalized
    }

    /// Detailed description for accessibility
    var description: String {
        switch self {
        case .none: return "No portion"
        case .light: return "Small amount (25%)"
        case .regular: return "Standard serving (50%)"
        case .extra: return "Generous portion (100%)"
        }
    }
}

// MARK: - Ingredient Category

/// Categories for organizing ingredients
enum IngredientCategory: String, Codable, CaseIterable {
    case vegetables
    case sauces
    case extras

    /// Display name for UI sections
    var displayName: String {
        switch self {
        case .vegetables: return "Fresh Vegetables"
        case .sauces: return "Signature Sauces"
        case .extras: return "Premium Extras"
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .vegetables: return "leaf.fill"
        case .sauces: return "drop.fill"
        case .extras: return "sparkles"
        }
    }

    /// Emoji representation
    var emoji: String {
        switch self {
        case .vegetables: return "🥗"
        case .sauces: return "🥫"
        case .extras: return "✨"
        }
    }

    /// Category color for UI
    var color: Color {
        switch self {
        case .vegetables: return .green
        case .sauces: return .orange
        case .extras: return .purple
        }
    }
}

// MARK: - Portion Pricing

/// Pricing structure for different portion levels
struct PortionPricing: Codable, Hashable {
    let none: Double
    let light: Double
    let regular: Double
    let extra: Double

    /// Get price for a specific portion level
    subscript(level: PortionLevel) -> Double {
        switch level {
        case .none: return none
        case .light: return light
        case .regular: return regular
        case .extra: return extra
        }
    }

    /// Check if this ingredient has any charges
    var hasCharge: Bool {
        light > 0 || regular > 0 || extra > 0
    }

    /// Get formatted price for a portion level
    func formattedPrice(for level: PortionLevel) -> String? {
        let price = self[level]
        guard price > 0 else { return nil }
        return String(format: "+$%.2f", price)
    }
}

// MARK: - Ingredient Template

/// Template for a reusable ingredient (e.g., Lettuce, Mayo, Bacon)
struct IngredientTemplate: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let category: IngredientCategory
    let supportsPortions: Bool
    let portionPricing: PortionPricing
    let defaultPortion: PortionLevel
    let displayOrder: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, category
        case supportsPortions = "supports_portions"
        case portionPricing = "portion_pricing"
        case defaultPortion = "default_portion"
        case displayOrder = "display_order"
        case isActive = "is_active"
    }

    /// Check if this is a premium (paid) ingredient
    var isPremium: Bool {
        portionPricing.hasCharge
    }
}

// MARK: - Menu Item Customization

/// Customization option for a specific menu item
struct MenuItemCustomization: Codable, Identifiable, Hashable {
    let id: Int
    let menuItemId: Int
    let templateId: Int?
    let name: String
    let type: String
    let category: String?
    let supportsPortions: Bool
    let portionPricing: PortionPricing?
    let defaultPortion: PortionLevel?
    let isRequired: Bool
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case menuItemId = "menu_item_id"
        case templateId = "template_id"
        case name, type, category
        case supportsPortions = "supports_portions"
        case portionPricing = "portion_pricing"
        case defaultPortion = "default_portion"
        case isRequired = "is_required"
        case displayOrder = "display_order"
    }

    /// Get the ingredient category enum
    var ingredientCategory: IngredientCategory? {
        guard let category = category else { return nil }
        return IngredientCategory(rawValue: category)
    }

    /// Check if this is a premium (paid) customization
    var isPremium: Bool {
        portionPricing?.hasCharge ?? false
    }

    /// Get formatted price for current portion selection
    func formattedPrice(for portion: PortionLevel) -> String? {
        portionPricing?.formattedPrice(for: portion)
    }
}

// MARK: - Portion Selection State

/// Manages portion selections for a menu item
struct PortionSelection {
    var selections: [Int: PortionLevel] = [:]

    /// Set the portion selection for a customization
    mutating func setSelection(_ portion: PortionLevel, for customizationId: Int) {
        selections[customizationId] = portion
    }

    /// Get the current selection for a customization
    func getSelection(for customizationId: Int) -> PortionLevel? {
        selections[customizationId]
    }

    /// Calculate the total additional cost from all selections
    func calculateAdditionalCost(customizations: [MenuItemCustomization]) -> Double {
        var total: Double = 0

        for customization in customizations where customization.supportsPortions {
            if let pricing = customization.portionPricing,
               let selectedPortion = selections[customization.id] {
                total += pricing[selectedPortion]
            }
        }

        return total
    }

    /// Convert selections to human-readable strings for order submission
    func toCustomizationStrings(customizations: [MenuItemCustomization]) -> [String] {
        var result: [String] = []

        for customization in customizations {
            if let portion = selections[customization.id], portion != .none {
                result.append("\(portion.displayName) \(customization.name)")
            }
        }

        return result
    }

    /// Check if any premium items are selected
    func hasPremiumSelections(customizations: [MenuItemCustomization]) -> Bool {
        for customization in customizations {
            if customization.isPremium,
               let portion = selections[customization.id],
               portion != .none,
               let pricing = customization.portionPricing,
               pricing[portion] > 0 {
                return true
            }
        }
        return false
    }

    /// Get count of selected ingredients (non-none portions)
    func selectedCount() -> Int {
        selections.values.filter { $0 != .none }.count
    }
}
