//
//  IngredientManagementViewModel.swift
//  KnockBites-Business
//
//  Created by Claude Code on 12/31/25.
//  Ingredient Pricing Management ViewModel
//

import SwiftUI

@MainActor
class IngredientManagementViewModel: ObservableObject {
    @Published var ingredients: [IngredientTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var selectedCategory: IngredientCategory?

    // Editing state
    @Published var editingIngredient: IngredientTemplate?
    @Published var showEditSheet = false
    @Published var showAddSheet = false

    // Form data for editing
    @Published var editName = ""
    @Published var editCategory: IngredientCategory = .extras
    @Published var editLightPrice: Double = 0
    @Published var editRegularPrice: Double = 0
    @Published var editExtraPrice: Double = 0
    @Published var editIsActive = true

    // Filtered ingredients
    var filteredIngredients: [IngredientTemplate] {
        var filtered = ingredients

        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // Filter by search
        if !searchQuery.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        return filtered
    }

    // Group by category
    var groupedIngredients: [(category: IngredientCategory, items: [IngredientTemplate])] {
        let grouped = Dictionary(grouping: filteredIngredients) { $0.category }
        return IngredientCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    // Stats
    var totalCount: Int { ingredients.count }
    var activeCount: Int { ingredients.filter { $0.isActive }.count }
    var premiumCount: Int { ingredients.filter { $0.isPremium }.count }

    func loadIngredients() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let templates = try await SupabaseManager.shared.fetchAllIngredientTemplates()
                // Deduplicate by name + category
                var seen = Set<String>()
                ingredients = templates.filter { template in
                    let key = "\(template.name)-\(template.category.rawValue)"
                    if seen.contains(key) { return false }
                    seen.insert(key)
                    return true
                }
            } catch {
                errorMessage = error.localizedDescription
                print("❌ Failed to load ingredients: \(error)")
            }

            isLoading = false
        }
    }

    func startEditing(_ ingredient: IngredientTemplate) {
        editingIngredient = ingredient
        editName = ingredient.name
        editCategory = ingredient.category
        editLightPrice = ingredient.portionPricing.light
        editRegularPrice = ingredient.portionPricing.regular
        editExtraPrice = ingredient.portionPricing.extra
        editIsActive = ingredient.isActive
        showEditSheet = true
    }

    func startAdding() {
        editingIngredient = nil
        editName = ""
        editCategory = .extras
        editLightPrice = 0
        editRegularPrice = 0
        editExtraPrice = 0
        editIsActive = true
        showAddSheet = true
    }

    func saveIngredient() {
        guard !editName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Ingredient name is required"
            return
        }

        Task {
            do {
                let pricing = PortionPricing(
                    none: 0,
                    light: editLightPrice,
                    regular: editRegularPrice,
                    extra: editExtraPrice
                )

                if let existing = editingIngredient {
                    // Update existing
                    try await SupabaseManager.shared.updateIngredientTemplate(
                        id: existing.id,
                        name: editName,
                        category: editCategory.rawValue,
                        portionPricing: pricing,
                        isActive: editIsActive
                    )
                } else {
                    // Create new
                    let maxOrder = ingredients.filter { $0.category == editCategory }.map { $0.displayOrder }.max() ?? 0
                    try await SupabaseManager.shared.createIngredientTemplate(
                        name: editName,
                        category: editCategory.rawValue,
                        portionPricing: pricing,
                        displayOrder: maxOrder + 1
                    )
                }

                showEditSheet = false
                showAddSheet = false
                loadIngredients()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleActive(_ ingredient: IngredientTemplate) {
        Task {
            do {
                try await SupabaseManager.shared.toggleIngredientActive(
                    id: ingredient.id,
                    isActive: !ingredient.isActive
                )
                loadIngredients()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteIngredient(_ ingredient: IngredientTemplate) {
        Task {
            do {
                try await SupabaseManager.shared.deleteIngredientTemplate(id: ingredient.id)
                loadIngredients()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
