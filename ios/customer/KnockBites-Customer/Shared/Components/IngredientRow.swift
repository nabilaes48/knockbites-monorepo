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
        VStack(alignment: .leading, spacing: 8) {
            // Ingredient Name on its own line
            HStack {
                Text(customization.name)
                    .font(AppFonts.body)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                Spacer()

                // Price indicator if applicable
                if let pricing = customization.portionPricing,
                   pricing[selectedPortion] > 0 {
                    Text("+$\(pricing[selectedPortion], specifier: "%.2f")")
                        .font(AppFonts.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brandPrimary.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Portion Selector on next line
            HStack(spacing: 6) {
                ForEach(PortionLevel.allCases, id: \.self) { portion in
                    Button(action: { selectedPortion = portion }) {
                        VStack(spacing: 2) {
                            Text(portion.emoji)
                                .font(.system(size: 18))

                            Text(portionShortName(portion))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(selectedPortion == portion ? .white : .textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(selectedPortion == portion ? Color.brandPrimary : Color.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedPortion == portion ? Color.clear : Color.border, lineWidth: 1)
                        )
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
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
