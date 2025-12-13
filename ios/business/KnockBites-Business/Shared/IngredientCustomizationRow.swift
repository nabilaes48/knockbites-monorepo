//
//  IngredientCustomizationRow.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//  Individual ingredient row with portion selector
//

import SwiftUI

struct IngredientCustomizationRow: View {
    let customization: MenuItemCustomization
    @Binding var selectedPortion: PortionLevel

    /// Get price text for currently selected portion
    var priceText: String? {
        guard let pricing = customization.portionPricing,
              pricing[selectedPortion] > 0 else {
            return nil
        }
        return String(format: "+$%.2f", pricing[selectedPortion])
    }

    /// Check if ingredient is free
    var isFree: Bool {
        customization.portionPricing?.hasCharge == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack {
                Text(customization.name)
                    .font(.body)
                    .fontWeight(.semibold)

                Spacer()

                if let price = priceText {
                    Text(price)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.brandPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.brandPrimary.opacity(0.1))
                        )
                } else if isFree && selectedPortion != .none {
                    Text("Free")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.1))
                        )
                }
            }

            // Portion Selector
            PortionSelectorRow(selectedPortion: $selectedPortion)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Previews

#Preview("Free Ingredient") {
    IngredientCustomizationRow(
        customization: MenuItemCustomization(
            id: 1,
            menuItemId: 84,
            templateId: 1,
            name: "Lettuce",
            type: "single",
            category: "vegetables",
            supportsPortions: true,
            portionPricing: PortionPricing(none: 0, light: 0, regular: 0, extra: 0),
            defaultPortion: .regular,
            isRequired: false,
            displayOrder: 1
        ),
        selectedPortion: .constant(.regular)
    )
    .padding()
}

#Preview("Premium Ingredient") {
    IngredientCustomizationRow(
        customization: MenuItemCustomization(
            id: 2,
            menuItemId: 84,
            templateId: 10,
            name: "Extra Cheese",
            type: "single",
            category: "extras",
            supportsPortions: true,
            portionPricing: PortionPricing(none: 0, light: 0.75, regular: 1.00, extra: 1.50),
            defaultPortion: .none,
            isRequired: false,
            displayOrder: 20
        ),
        selectedPortion: .constant(.regular)
    )
    .padding()
}

#Preview("Multiple Ingredients") {
    ScrollView {
        VStack(spacing: 16) {
            // Vegetables
            IngredientCustomizationRow(
                customization: MenuItemCustomization(
                    id: 1,
                    menuItemId: 84,
                    templateId: 1,
                    name: "Lettuce",
                    type: "single",
                    category: "vegetables",
                    supportsPortions: true,
                    portionPricing: PortionPricing(none: 0, light: 0, regular: 0, extra: 0),
                    defaultPortion: .regular,
                    isRequired: false,
                    displayOrder: 1
                ),
                selectedPortion: .constant(.regular)
            )

            IngredientCustomizationRow(
                customization: MenuItemCustomization(
                    id: 2,
                    menuItemId: 84,
                    templateId: 2,
                    name: "Tomato",
                    type: "single",
                    category: "vegetables",
                    supportsPortions: true,
                    portionPricing: PortionPricing(none: 0, light: 0, regular: 0, extra: 0),
                    defaultPortion: .regular,
                    isRequired: false,
                    displayOrder: 2
                ),
                selectedPortion: .constant(.light)
            )

            // Premium Extra
            IngredientCustomizationRow(
                customization: MenuItemCustomization(
                    id: 10,
                    menuItemId: 84,
                    templateId: 10,
                    name: "Extra Cheese",
                    type: "single",
                    category: "extras",
                    supportsPortions: true,
                    portionPricing: PortionPricing(none: 0, light: 0.75, regular: 1.00, extra: 1.50),
                    defaultPortion: .none,
                    isRequired: false,
                    displayOrder: 20
                ),
                selectedPortion: .constant(.extra)
            )
        }
        .padding()
    }
}
