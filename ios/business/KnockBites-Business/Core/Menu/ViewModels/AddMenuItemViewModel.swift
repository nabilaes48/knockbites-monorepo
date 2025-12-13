//
//  AddMenuItemViewModel.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//  Extracted from AddMenuItemView.swift
//

import SwiftUI
import Combine

class AddMenuItemViewModel: ObservableObject {
    @Published var itemName = ""
    @Published var description = ""
    @Published var price = ""
    @Published var selectedCategory = "Burgers"
    @Published var prepTime = ""
    @Published var calories = ""
    @Published var isAvailable = true
    @Published var isFeatured = false
    @Published var dietaryTags: Set<String> = []
    @Published var selectedImage: UIImage?

    let categories = ["Appetizers", "Burgers", "Sandwiches", "Salads", "Entrees", "Desserts", "Beverages"]
    private var itemId: String?

    init(item: MenuItem? = nil) {
        if let item = item {
            // Pre-fill form with existing item data
            self.itemId = item.id
            self.itemName = item.name
            self.description = item.description
            self.price = String(format: "%.2f", item.price)
            self.selectedCategory = getCategoryName(from: item.categoryId)
            self.prepTime = "\(item.prepTime)"
            self.calories = item.calories != nil ? "\(item.calories!)" : ""
            self.isAvailable = item.isAvailable
            self.isFeatured = false // You can add this to MenuItem model if needed
            // Note: dietaryTags and image would need to be added to MenuItem model
        }
    }

    var isValid: Bool {
        !itemName.isEmpty &&
        !description.isEmpty &&
        !price.isEmpty
    }

    func createMenuItem() -> MenuItem? {
        guard isValid,
              let priceValue = Double(price),
              let prepTimeValue = Int(prepTime) else {
            return nil
        }

        let caloriesValue = Int(calories)
        let categoryId = getCategoryId(from: selectedCategory)

        return MenuItem(
            id: itemId ?? UUID().uuidString,
            name: itemName,
            description: description,
            price: priceValue,
            categoryId: categoryId,
            imageURL: "", // TODO: Upload image and get URL
            isAvailable: isAvailable,
            dietaryInfo: [], // TODO: Map from dietaryTags
            customizationGroups: [], // TODO: Implement customizations
            calories: caloriesValue,
            prepTime: prepTimeValue
        )
    }

    private func getCategoryName(from categoryId: String) -> String {
        // Map category ID to category name
        switch categoryId {
        case "cat_1": return "Appetizers"
        case "cat_2": return "Burgers"
        case "cat_3": return "Sandwiches"
        case "cat_4": return "Salads"
        case "cat_5": return "Entrees"
        case "cat_6": return "Desserts"
        case "cat_7": return "Beverages"
        default: return "Burgers"
        }
    }

    private func getCategoryId(from categoryName: String) -> String {
        // Map category name to category ID
        switch categoryName {
        case "Appetizers": return "cat_1"
        case "Burgers": return "cat_2"
        case "Sandwiches": return "cat_3"
        case "Salads": return "cat_4"
        case "Entrees": return "cat_5"
        case "Desserts": return "cat_6"
        case "Beverages": return "cat_7"
        default: return "cat_2"
        }
    }
}
