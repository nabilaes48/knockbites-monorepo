//
//  PortionSelectorButton.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/21/25.
//

import SwiftUI

struct PortionSelectorButton: View {
    let portion: PortionLevel
    let isSelected: Bool
    let price: Double?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(portion.emoji)
                    .font(.title2)

                Text(portion.displayName)
                    .font(.caption)
                    .fontWeight(.medium)

                if let price = price, price > 0 {
                    Text(String(format: "+$%.2f", price))
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.brandPrimary : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : .textPrimary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 16) {
        // Free ingredient (no pricing)
        Text("Free Ingredient (Lettuce)")
            .font(.headline)
        HStack(spacing: 8) {
            PortionSelectorButton(portion: .none, isSelected: false, price: nil) {}
            PortionSelectorButton(portion: .light, isSelected: false, price: nil) {}
            PortionSelectorButton(portion: .regular, isSelected: true, price: nil) {}
            PortionSelectorButton(portion: .extra, isSelected: false, price: nil) {}
        }

        Divider()

        // Premium ingredient (with pricing)
        Text("Premium Extra (Cheese)")
            .font(.headline)
        HStack(spacing: 8) {
            PortionSelectorButton(portion: .none, isSelected: false, price: 0) {}
            PortionSelectorButton(portion: .light, isSelected: false, price: 0.75) {}
            PortionSelectorButton(portion: .regular, isSelected: true, price: 1.00) {}
            PortionSelectorButton(portion: .extra, isSelected: false, price: 1.50) {}
        }
    }
    .padding()
}
