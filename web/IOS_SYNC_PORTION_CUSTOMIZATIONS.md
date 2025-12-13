# iOS Sync Update: Portion-Based Customizations

**Date**: 2025-11-21
**Status**: ✅ Web Implementation Complete - iOS Pending
**Feature**: Modern Portion-Based Ingredient Customization System

---

## 🎯 What Changed

### Database Changes
✅ **New Table**: `ingredient_templates` (13 default ingredients loaded)
✅ **Enhanced**: `menu_item_customizations` table with portion support columns
✅ **Migration**: Successfully applied to production database

### Web Implementation Status
✅ Admin dashboard updated with ingredient template selector
✅ Customer menu updated with portion-based customization modal
✅ Real-time price calculation implemented
✅ Category-based ingredient organization (Vegetables, Sauces, Extras)

---

## 📊 Current Ingredient Templates (13 Total)

### 🥗 Fresh Vegetables (4 items - FREE)
1. Lettuce
2. Tomato
3. Onion
4. Pickles

### 🥫 Signature Sauces (6 items - FREE)
1. Chipotle Mayo ✅ *
2. Mayo
3. Russian Dressing ✅ *
4. Ketchup
5. Mustard
6. Hot Sauce

### ✨ Premium Extras (3 items - CHARGED)
1. Extra Cheese - $0.75 (Light) / $1.00 (Regular) / $1.50 (Extra)
2. Bacon - $1.00 (Light) / $1.50 (Regular) / $2.00 (Extra)
3. Avocado - $1.50 (Light) / $2.00 (Regular) / $2.50 (Extra)

**Note**: Items marked with ✅ * are specifically requested by customer

---

## 📱 iOS Implementation Guide

### 1. Database Schema (Already Applied)

The following columns were added to `menu_item_customizations`:
```sql
supports_portions BOOLEAN DEFAULT false
portion_pricing JSONB
default_portion TEXT DEFAULT 'regular'
category TEXT
```

New table `ingredient_templates` with RLS policies already created.

### 2. Swift Data Models

#### IngredientTemplate
```swift
struct IngredientTemplate: Codable, Identifiable {
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
}

enum IngredientCategory: String, Codable {
    case vegetables
    case sauces
    case extras

    var displayName: String {
        switch self {
        case .vegetables: return "Fresh Vegetables"
        case .sauces: return "Signature Sauces"
        case .extras: return "Premium Extras"
        }
    }

    var icon: String {
        switch self {
        case .vegetables: return "leaf.fill"
        case .sauces: return "drop.fill"
        case .extras: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .vegetables: return .green
        case .sauces: return .orange
        case .extras: return .purple
        }
    }
}

enum PortionLevel: String, Codable, CaseIterable {
    case none, light, regular, extra

    var emoji: String {
        switch self {
        case .none: return "○"
        case .light: return "◔"
        case .regular: return "◑"
        case .extra: return "●"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

struct PortionPricing: Codable {
    let none: Double
    let light: Double
    let regular: Double
    let extra: Double

    subscript(level: PortionLevel) -> Double {
        switch level {
        case .none: return none
        case .light: return light
        case .regular: return regular
        case .extra: return extra
        }
    }
}
```

#### Enhanced MenuItemCustomization
```swift
struct MenuItemCustomization: Codable, Identifiable {
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
}
```

### 3. SwiftUI Components

#### PortionSelectorButton
```swift
struct PortionSelectorButton: View {
    let portion: PortionLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(portion.emoji)
                    .font(.title2)
                Text(portion.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
```

#### IngredientRow
```swift
struct IngredientRow: View {
    let ingredient: MenuItemCustomization
    @Binding var selectedPortion: PortionLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ingredient.name)
                    .font(.body)
                    .fontWeight(.semibold)

                Spacer()

                if let pricing = ingredient.portionPricing,
                   pricing[selectedPortion] > 0 {
                    Text("+$\(pricing[selectedPortion], specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 8) {
                ForEach(PortionLevel.allCases, id: \.self) { portion in
                    PortionSelectorButton(
                        portion: portion,
                        isSelected: selectedPortion == portion,
                        action: { selectedPortion = portion }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

#### CustomizationView
```swift
struct CustomizationView: View {
    let menuItem: MenuItem
    @State private var selections: [Int: PortionLevel] = [:]
    @State private var customizations: [MenuItemCustomization] = []
    @State private var specialInstructions = ""
    @State private var quantity = 1

    var totalPrice: Double {
        var total = menuItem.basePrice

        for customization in customizations where customization.supportsPortions {
            if let pricing = customization.portionPricing,
               let selectedPortion = selections[customization.id] {
                total += pricing[selectedPortion]
            }
        }

        return total * Double(quantity)
    }

    var groupedCustomizations: [IngredientCategory: [MenuItemCustomization]] {
        Dictionary(grouping: customizations.filter { $0.supportsPortions }) { customization in
            IngredientCategory(rawValue: customization.category ?? "extras") ?? .extras
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Menu Item Image
                AsyncImage(url: URL(string: menuItem.imageUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(height: 200)
                .clipped()

                VStack(alignment: .leading, spacing: 16) {
                    // Item Info
                    HStack {
                        VStack(alignment: .leading) {
                            Text(menuItem.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(menuItem.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("$\(menuItem.basePrice, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }

                    // Customizations by Category
                    ForEach(IngredientCategory.allCases, id: \.self) { category in
                        if let ingredients = groupedCustomizations[category], !ingredients.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label(category.displayName, systemImage: category.icon)
                                    .font(.headline)
                                    .foregroundColor(category.color)

                                ForEach(ingredients) { ingredient in
                                    IngredientRow(
                                        ingredient: ingredient,
                                        selectedPortion: Binding(
                                            get: { selections[ingredient.id] ?? .regular },
                                            set: { selections[ingredient.id] = $0 }
                                        )
                                    )
                                }
                            }
                        }
                    }

                    // Special Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Special Instructions")
                            .font(.headline)
                        TextEditor(text: $specialInstructions)
                            .frame(height: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    // Quantity
                    HStack {
                        Text("Quantity")
                            .font(.headline)
                        Spacer()
                        HStack(spacing: 16) {
                            Button {
                                if quantity > 1 { quantity -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(quantity <= 1)

                            Text("\(quantity)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(width: 40)

                            Button {
                                quantity += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                addToCart()
            } label: {
                HStack {
                    Image(systemName: "cart.fill")
                    Text("Add to Cart")
                    Spacer()
                    Text("$\(totalPrice, specifier: "%.2f")")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding()
            }
        }
        .task {
            await loadCustomizations()
        }
    }

    func loadCustomizations() async {
        do {
            let response = try await supabase
                .from("menu_item_customizations")
                .select()
                .eq("menu_item_id", value: menuItem.id)
                .eq("supports_portions", value: true)
                .order("category")
                .order("display_order")
                .execute()

            customizations = try JSONDecoder().decode([MenuItemCustomization].self, from: response.data)

            // Set default portions
            for customization in customizations {
                if let defaultPortion = customization.defaultPortion {
                    selections[customization.id] = defaultPortion
                }
            }
        } catch {
            print("Error loading customizations: \(error)")
        }
    }

    func addToCart() {
        // Build customization summary
        var customizationList: [String] = []

        for customization in customizations {
            if let portion = selections[customization.id], portion != .none {
                customizationList.append("\(portion.displayName) \(customization.name)")
            }
        }

        // Create cart item
        let cartItem = CartItem(
            menuItemId: menuItem.id,
            name: menuItem.name,
            basePrice: menuItem.basePrice,
            quantity: quantity,
            customizations: customizationList,
            specialInstructions: specialInstructions.isEmpty ? nil : specialInstructions,
            totalPrice: totalPrice
        )

        // Add to cart (implement your cart logic)
        CartManager.shared.addItem(cartItem)
    }
}
```

### 4. API Calls

#### Fetch Ingredient Templates
```swift
func fetchIngredientTemplates() async throws -> [IngredientTemplate] {
    let response = try await supabase
        .from("ingredient_templates")
        .select()
        .eq("is_active", value: true)
        .order("category")
        .order("display_order")
        .execute()

    return try JSONDecoder().decode([IngredientTemplate].self, from: response.data)
}
```

#### Fetch Menu Item Customizations
```swift
func fetchCustomizations(for menuItemId: Int) async throws -> [MenuItemCustomization] {
    let response = try await supabase
        .from("menu_item_customizations")
        .select()
        .eq("menu_item_id", value: menuItemId)
        .order("category")
        .order("display_order")
        .execute()

    return try JSONDecoder().decode([MenuItemCustomization].self, from: response.data)
}
```

### 5. Order Submission Format

```swift
struct OrderItemSubmission: Codable {
    let menuItemId: Int
    let quantity: Int
    let basePrice: Double
    let customizations: [String]  // ["Regular Lettuce", "Extra Chipotle Mayo"]
    let selectedOptions: [String: [String]]  // For backward compatibility
    let notes: String?
    let totalPrice: Double

    enum CodingKeys: String, CodingKey {
        case menuItemId = "menu_item_id"
        case quantity
        case basePrice = "base_price"
        case customizations
        case selectedOptions = "selected_options"
        case notes
        case totalPrice = "total_price"
    }
}
```

---

## 🔄 Migration Checklist

### Backend (Supabase)
- [x] Run migration 042 (ingredient templates table)
- [x] Add portion columns to menu_item_customizations
- [x] Insert 13 default ingredient templates
- [x] Set up RLS policies
- [x] Clean up duplicate templates

### Web App
- [x] Create PortionSelector UI component
- [x] Create IngredientTemplateSelector component
- [x] Update EditItemModalV2 for admin
- [x] Update ItemCustomizationModalV2 for customers
- [x] Update MenuBrowse to use new modal
- [x] Test ingredient assignment
- [x] Test customer ordering flow

### iOS App (Pending)
- [ ] Add Swift data models
- [ ] Create PortionSelector SwiftUI component
- [ ] Create CustomizationView
- [ ] Update API layer for new schema
- [ ] Update order submission format
- [ ] Test real-time price calculation
- [ ] Test ingredient category grouping
- [ ] Test order placement with portions

---

## 🧪 Testing Instructions

### For iOS Developers:

1. **Test Template Loading**:
   ```swift
   let templates = try await fetchIngredientTemplates()
   print("Loaded \(templates.count) templates")  // Should be 13
   ```

2. **Test Item Customizations**:
   ```swift
   let customizations = try await fetchCustomizations(for: menuItemId)
   let portionBased = customizations.filter { $0.supportsPortions }
   print("Portion-based: \(portionBased.count)")
   ```

3. **Test Price Calculation**:
   - Select "Extra Bacon" → price should increase by $2.00
   - Select "Light Avocado" → price should increase by $1.50
   - Free items (Lettuce, Mayo) should not change price

4. **Test Order Submission**:
   - Create order with multiple portion selections
   - Verify customizations array format
   - Check total price calculation

---

## 📊 Performance Considerations

- **Caching**: Cache ingredient templates (they rarely change)
- **Lazy Loading**: Load customizations only when modal opens
- **Debouncing**: Debounce price calculations (if needed)
- **Offline**: Cache last known templates for offline browsing

---

## 🐛 Common Issues & Solutions

### Issue: Templates not loading
**Solution**: Check RLS policies allow public SELECT on `ingredient_templates`

### Issue: Price not updating
**Solution**: Verify `portionPricing` JSON structure matches exactly

### Issue: Duplicate ingredients in UI
**Solution**: Run CLEANUP_DUPLICATES.sql from web repo

### Issue: Customizations not saving
**Solution**: Ensure `supports_portions = true` flag is set

---

## 📞 Support

**Web Implementation**: Complete and tested
**Database**: Clean state with 13 ingredients
**Documentation**: This file + PORTION_BASED_CUSTOMIZATIONS.md

For questions during iOS implementation, refer to web implementation in:
- `src/components/ui/PortionSelector.tsx`
- `src/components/order/ItemCustomizationModalV2.tsx`
- `src/components/dashboard/IngredientTemplateSelector.tsx`

---

**Last Updated**: 2025-11-21
**Migration Status**: ✅ Production Ready
**iOS Status**: 🔄 Awaiting Implementation
