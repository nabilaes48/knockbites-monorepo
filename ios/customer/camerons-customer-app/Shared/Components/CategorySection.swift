//
//  CategorySection.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/21/25.
//

import SwiftUI

struct CategorySection: View {
    let category: IngredientCategory
    let customizations: [MenuItemCustomization]
    @Binding var selections: [Int: PortionLevel]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category Header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(categoryColor)

                Text(category.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Ingredients List
            VStack(spacing: 0) {
                ForEach(customizations) { customization in
                    IngredientRow(
                        customization: customization,
                        selectedPortion: Binding(
                            get: { selections[customization.id] ?? customization.defaultPortion ?? .regular },
                            set: { selections[customization.id] = $0 }
                        )
                    )
                    .padding(.horizontal, 16)

                    if customization.id != customizations.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }

    private var categoryColor: Color {
        switch category {
        case .vegetables: return .green
        case .sauces: return .orange
        case .extras: return .purple
        }
    }
}

#Preview {
    CategorySection(
        category: .vegetables,
        customizations: [
            MenuItemCustomization(
                id: 1,
                menuItemId: 84,
                name: "Lettuce",
                type: "single",
                category: "vegetables",
                supportsPortions: true,
                portionPricing: PortionPricing(none: 0, light: 0, regular: 0, extra: 0),
                defaultPortion: .regular,
                isRequired: false,
                displayOrder: 1,
                options: nil
            ),
            MenuItemCustomization(
                id: 2,
                menuItemId: 84,
                name: "Tomato",
                type: "single",
                category: "vegetables",
                supportsPortions: true,
                portionPricing: PortionPricing(none: 0, light: 0, regular: 0, extra: 0),
                defaultPortion: .regular,
                isRequired: false,
                displayOrder: 2,
                options: nil
            )
        ],
        selections: .constant([1: .regular, 2: .light])
    )
    .padding()
}
