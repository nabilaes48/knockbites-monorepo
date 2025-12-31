//
//  ItemDetailView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct ItemDetailView: View {
    let item: MenuItem
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @State private var quantity = 1
    @State private var selectedOptions: [String: [String]] = [:]
    @State private var portionSelections: [Int: PortionLevel] = [:]
    @State private var specialInstructions = ""
    @State private var showingAddedConfirmation = false

    private var warnings: [String] {
        profileViewModel.getWarnings(for: item)
    }

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Image
                    AsyncImage(url: URL(string: item.imageURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            // Gradient placeholder
                            ZStack {
                                LinearGradient(
                                    gradient: Gradient(colors: gradientColors(for: item)),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )

                                VStack(spacing: 12) {
                                    Text(String(item.name.prefix(1)).uppercased())
                                        .font(.system(size: 72, weight: .bold))
                                        .foregroundColor(.white)

                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 280)
                    .clipped()

                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(item.name)
                                        .font(AppFonts.title2)
                                        .foregroundColor(.textPrimary)

                                    HStack(spacing: Spacing.sm) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                            Text("\(item.prepTime) min")
                                        }
                                        .font(AppFonts.caption)
                                        .foregroundColor(.textSecondary)

                                        if let calories = item.calories {
                                            HStack(spacing: 4) {
                                                Image(systemName: "flame")
                                                Text("\(calories) cal")
                                            }
                                            .font(AppFonts.caption)
                                            .foregroundColor(.textSecondary)
                                        }
                                    }
                                }

                                Spacer()

                                Text(item.formattedPrice)
                                    .font(AppFonts.title3)
                                    .foregroundColor(.brandPrimary)
                            }

                            Text(item.description)
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)
                        }

                        // Dietary Info
                        if !item.dietaryInfo.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(item.dietaryInfo, id: \.self) { tag in
                                        DietaryBadge(tag: tag)
                                    }
                                }
                            }
                        }

                        // Allergen Warnings
                        if !warnings.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                ForEach(warnings, id: \.self) { warning in
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundColor(.error)

                                        Text(warning)
                                            .font(AppFonts.caption)
                                            .foregroundColor(.error)
                                    }
                                    .padding(Spacing.sm)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.error.opacity(0.1))
                                    .cornerRadius(CornerRadius.sm)
                                }
                            }
                        }

                        Divider()

                        // Quantity Selector
                        HStack {
                            Text("Quantity")
                                .font(AppFonts.headline)
                                .foregroundColor(.textPrimary)

                            Spacer()

                            HStack(spacing: Spacing.md) {
                                Button(action: { if quantity > 1 { quantity -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(quantity > 1 ? .brandPrimary : .gray)
                                }
                                .disabled(quantity <= 1)

                                Text("\(quantity)")
                                    .font(AppFonts.title3)
                                    .foregroundColor(.textPrimary)
                                    .frame(minWidth: 30)

                                Button(action: { quantity += 1 }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.brandPrimary)
                                }
                            }
                        }

                        // Portion-Based Customizations
                        if item.hasPortionCustomizations,
                           let customizations = item.portionCustomizations {
                            Divider()

                            let grouped = Dictionary(grouping: customizations.filter { $0.supportsPortions }) {
                                $0.ingredientCategory ?? .extras
                            }

                            ForEach(IngredientCategory.allCases.sorted(by: { $0.displayOrder < $1.displayOrder }), id: \.self) { category in
                                if let items = grouped[category], !items.isEmpty {
                                    CategorySection(
                                        category: category,
                                        customizations: items.sorted(by: { $0.displayOrder < $1.displayOrder }),
                                        selections: $portionSelections
                                    )

                                    Divider()
                                }
                            }
                        }

                        // Legacy Customization Groups (fallback)
                        else if !item.customizationGroups.isEmpty {
                            Divider()

                            ForEach(item.customizationGroups) { group in
                                CustomizationGroupView(
                                    group: group,
                                    selectedOptions: binding(for: group.id)
                                )

                                if group.id != item.customizationGroups.last?.id {
                                    Divider()
                                }
                            }
                        }

                        Divider()

                        // Special Instructions
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Special Instructions")
                                .font(AppFonts.headline)
                                .foregroundColor(.textPrimary)

                            TextEditor(text: $specialInstructions)
                                .frame(height: 100)
                                .padding(Spacing.sm)
                                .background(Color.surface)
                                .cornerRadius(CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(Color.border, lineWidth: 1)
                                )
                                .scrollContentBackground(.hidden)
                        }
                    }
                    .padding()
                    .padding(.bottom, 100) // Space for sticky button
                }
            }

            // Add to Cart Button (Sticky)
            VStack {
                Spacer()

                CustomButton(
                    title: "Add to Cart",
                    action: addToCart,
                    style: .primary,
                    isDisabled: !isFormValid
                )
                .padding()
                .background(Color.surface.shadow(color: Color.black.opacity(0.1), radius: 8, y: -4))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .alert("Added to Cart", isPresented: $showingAddedConfirmation) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("\(quantity) × \(item.name) added to your cart")
        }
        .onAppear {
            menuViewModel.trackItemView(item)

            // Set default portions for portion-based customizations
            if let customizations = item.portionCustomizations {
                for customization in customizations where customization.supportsPortions {
                    if let defaultPortion = customization.defaultPortion {
                        portionSelections[customization.id] = defaultPortion
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        // Check all required groups have selections
        for group in item.customizationGroups where group.isRequired {
            if selectedOptions[group.id]?.isEmpty ?? true {
                return false
            }
        }
        return true
    }

    private var totalPrice: Double {
        var price = item.price * Double(quantity)

        // Add legacy customization costs
        for (groupId, optionIds) in selectedOptions {
            if let group = item.customizationGroups.first(where: { $0.id == groupId }) {
                for optionId in optionIds {
                    if let option = group.options.first(where: { $0.id == optionId }) {
                        price += option.priceModifier * Double(quantity)
                    }
                }
            }
        }

        // Add portion-based customization costs
        if let customizations = item.portionCustomizations {
            for (customizationId, portion) in portionSelections {
                if let customization = customizations.first(where: { $0.id == customizationId }),
                   let pricing = customization.portionPricing {
                    price += pricing[portion] * Double(quantity)
                }
            }
        }

        return price
    }

    private func binding(for groupId: String) -> Binding<[String]> {
        Binding(
            get: { selectedOptions[groupId] ?? [] },
            set: { selectedOptions[groupId] = $0 }
        )
    }

    private func addToCart() {
        cartViewModel.addItem(
            menuItem: item,
            quantity: quantity,
            selectedOptions: selectedOptions,
            portionSelections: item.hasPortionCustomizations ? portionSelections : nil,
            specialInstructions: specialInstructions.isEmpty ? nil : specialInstructions
        )
        showingAddedConfirmation = true
    }

    private func gradientColors(for item: MenuItem) -> [Color] {
        // Generate colors based on category ID for consistency
        let categoryHash = item.categoryId.hashValue
        let colorSets: [[Color]] = [
            [Color(red: 0.95, green: 0.35, blue: 0.24), Color(red: 0.96, green: 0.56, blue: 0.24)], // Red-Orange
            [Color(red: 0.35, green: 0.67, blue: 0.95), Color(red: 0.45, green: 0.82, blue: 0.95)], // Blue
            [Color(red: 0.67, green: 0.35, blue: 0.95), Color(red: 0.82, green: 0.45, blue: 0.95)], // Purple
            [Color(red: 0.35, green: 0.95, blue: 0.67), Color(red: 0.45, green: 0.95, blue: 0.82)], // Green
            [Color(red: 0.95, green: 0.67, blue: 0.35), Color(red: 0.95, green: 0.82, blue: 0.45)], // Orange-Yellow
            [Color(red: 0.95, green: 0.35, blue: 0.67), Color(red: 0.95, green: 0.45, blue: 0.82)]  // Pink
        ]

        return colorSets[abs(categoryHash) % colorSets.count]
    }
}

// MARK: - Customization Group View
struct CustomizationGroupView: View {
    let group: CustomizationGroup
    @Binding var selectedOptions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text(group.name)
                    .font(AppFonts.headline)
                    .foregroundColor(.textPrimary)

                if group.isRequired {
                    Text("Required")
                        .font(AppFonts.caption)
                        .foregroundColor(.error)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.error.opacity(0.1))
                        .cornerRadius(4)
                }

                if group.allowMultiple {
                    Text("Select multiple")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()
            }

            // Options
            ForEach(group.options) { option in
                CustomizationOptionRow(
                    option: option,
                    isSelected: selectedOptions.contains(option.id),
                    allowMultiple: group.allowMultiple
                ) {
                    toggleOption(option)
                }
            }
        }
    }

    private func toggleOption(_ option: CustomizationOption) {
        if group.allowMultiple {
            if selectedOptions.contains(option.id) {
                selectedOptions.removeAll { $0 == option.id }
            } else {
                selectedOptions.append(option.id)
            }
        } else {
            selectedOptions = [option.id]
        }
    }
}

// MARK: - Customization Option Row
struct CustomizationOptionRow: View {
    let option: CustomizationOption
    let isSelected: Bool
    let allowMultiple: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected
                    ? (allowMultiple ? "checkmark.square.fill" : "largecircle.fill.circle")
                    : (allowMultiple ? "square" : "circle"))
                    .foregroundColor(isSelected ? .brandPrimary : .textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.name)
                        .font(AppFonts.body)
                        .foregroundColor(.textPrimary)

                    if option.priceModifier != 0 {
                        Text(option.formattedPrice)
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                if option.isDefault {
                    Text("Default")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
#Preview {
    ItemDetailView(item: MockDataService.shared.getMenuItems()[3])
        .environmentObject(CartViewModel())
}
#endif
