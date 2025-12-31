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

    // Check if this ingredient has any pricing
    private var hasPricing: Bool {
        guard let pricing = customization.portionPricing else { return false }
        return pricing.light > 0 || pricing.regular > 0 || pricing.extra > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Ingredient Name with premium indicator
            HStack {
                Text(customization.name)
                    .font(AppFonts.body)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                if hasPricing {
                    Text("$")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.15))
                        .cornerRadius(4)
                }

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

                            // Show price under each portion button if this ingredient has pricing
                            if let pricing = customization.portionPricing, portion != .none {
                                let price = pricing[portion]
                                if price > 0 {
                                    Text("+$\(price, specifier: "%.2f")")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(selectedPortion == portion ? .white.opacity(0.9) : .green)
                                } else if hasPricing {
                                    Text("Free")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(selectedPortion == portion ? .white.opacity(0.9) : .secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: hasPricing ? 62 : 50)
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
