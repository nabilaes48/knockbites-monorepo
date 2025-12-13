//
//  IngredientRow.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/21/25.
//

import SwiftUI

struct IngredientRow: View {
    let customization: MenuItemCustomization
    @Binding var selectedPortion: PortionLevel

    var body: some View {
        HStack(spacing: 12) {
            // Ingredient Name
            VStack(alignment: .leading, spacing: 2) {
                Text(customization.name)
                    .font(AppFonts.body)
                    .foregroundColor(.textPrimary)

                if let pricing = customization.portionPricing,
                   pricing[selectedPortion] > 0 {
                    Text("+$\(pricing[selectedPortion], specifier: "%.2f")")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            // Compact Portion Selector
            HStack(spacing: 4) {
                ForEach(PortionLevel.allCases, id: \.self) { portion in
                    Button(action: { selectedPortion = portion }) {
                        VStack(spacing: 2) {
                            Text(portion.emoji)
                                .font(.system(size: 16))

                            Text(portionShortName(portion))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(selectedPortion == portion ? .white : .textPrimary)
                        }
                        .frame(width: 50, height: 44)
                        .background(selectedPortion == portion ? Color.brandPrimary : Color.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedPortion == portion ? Color.clear : Color.border, lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func portionShortName(_ portion: PortionLevel) -> String {
        switch portion {
        case .none: return "None"
        case .light: return "Light"
        case .regular: return "Reg"
        case .extra: return "Extra"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Free vegetable
        IngredientRow(
            customization: MenuItemCustomization(
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
            selectedPortion: .constant(.regular)
        )

        // Premium extra
        IngredientRow(
            customization: MenuItemCustomization(
                id: 2,
                menuItemId: 84,
                name: "Extra Cheese",
                type: "single",
                category: "extras",
                supportsPortions: true,
                portionPricing: PortionPricing(none: 0, light: 0.75, regular: 1.00, extra: 1.50),
                defaultPortion: .none,
                isRequired: false,
                displayOrder: 20,
                options: nil
            ),
            selectedPortion: .constant(.regular)
        )
    }
    .padding()
}
