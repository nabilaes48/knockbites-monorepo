# iOS Portion-Based Customizations - Implementation Plan

**Created**: November 21, 2025
**Status**: Ready for Implementation
**Goal**: Match web app design 100% with portion-based ingredient customization system

---

## 📋 Executive Summary

This plan outlines the complete implementation of the portion-based customization system in the iOS customer app to match the web app's functionality and design.

### Current State
- ✅ **Backend**: 5 migrations applied, 13 ingredient templates loaded, 6 menu items ready
- ✅ **Web App**: Fully functional with portion-based UI
- ⚠️ **iOS App**: Uses legacy customization groups (non-portion based)

### Target State
- 🎯 iOS app displays portion selectors (None/Light/Regular/Extra) matching web design
- 🎯 Real-time price calculations with tiered pricing
- 🎯 Category-based ingredient organization (🥗 Vegetables, 🥫 Sauces, ✨ Extras)
- 🎯 Smart defaults (vegetables pre-selected at Regular)
- 🎯 Backward compatibility with existing non-portion customizations

---

## 🎨 Design Requirements

### Visual Design (Match Web App)
```
┌─────────────────────────────────────┐
│ [X] All American Sandwich           │
│ Fresh breakfast sandwich            │
│ [Item Image]                         │
│ Base: $8.49                          │
├─────────────────────────────────────┤
│ 🥗 Fresh Vegetables                  │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                      │
│ Lettuce                              │
│ [ ○ ]  [ ◔ ]  [●◑●]  [ ● ]          │
│ None   Light  Regular Extra          │
│                                      │
│ Tomato                               │
│ [ ○ ]  [ ◔ ]  [●◑●]  [ ● ]          │
│ None   Light  Regular Extra          │
├─────────────────────────────────────┤
│ 🥫 Signature Sauces                  │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                      │
│ Russian Dressing                     │
│ [ ○ ]  [ ◔ ]  [●◑●]  [ ● ]          │
│                                      │
│ Chipotle Mayo                        │
│ [ ○ ]  [●◔●]  [ ◑ ]  [ ● ]          │
│                      (Light selected)│
├─────────────────────────────────────┤
│ ✨ Premium Extras                    │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                      │
│ Extra Cheese          +$1.00         │
│ [●○●]  [ ◔ ]  [ ◑ ]  [ ● ]          │
│ None   Light  Regular Extra          │
│        +$0.75 +$1.00  +$1.50         │
├─────────────────────────────────────┤
│ Special Instructions                 │
│ [Optional notes...]                  │
├─────────────────────────────────────┤
│ Quantity: [-] 2 [+]                  │
├─────────────────────────────────────┤
│ [  Add to Cart - $17.98  ] 🛒        │
└─────────────────────────────────────┘
```

### Key Design Elements
1. **Category Headers**: Icon + Name with separator line
2. **Portion Buttons**: 4 horizontal buttons with emoji indicators
3. **Selected State**: Filled background, white text
4. **Pricing Display**: Show price next to ingredient name for premium items
5. **Price Breakdown**: Show pricing for each portion level under premium extras
6. **Real-time Total**: Update cart button with live total

---

## 🏗️ Implementation Phases

### Phase 1: Data Models (Day 1)
**Goal**: Add Swift models for portion-based system

#### 1.1 Add New Models to `Models.swift`
```swift
// MARK: - Ingredient Templates & Portions

enum PortionLevel: String, Codable, CaseIterable {
    case none = "none"
    case light = "light"
    case regular = "regular"
    case extra = "extra"

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

struct PortionPricing: Codable, Hashable {
    let none: Double
    let light: Double
    let regular: Double
    let extra: Double

    init(none: Double = 0, light: Double = 0, regular: Double = 0, extra: Double = 0) {
        self.none = none
        self.light = light
        self.regular = regular
        self.extra = extra
    }

    subscript(level: PortionLevel) -> Double {
        switch level {
        case .none: return none
        case .light: return light
        case .regular: return regular
        case .extra: return extra
        }
    }
}

enum IngredientCategory: String, Codable, CaseIterable {
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

    var displayOrder: Int {
        switch self {
        case .vegetables: return 1
        case .sauces: return 2
        case .extras: return 3
        }
    }
}

struct IngredientTemplate: Codable, Identifiable, Hashable {
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

struct MenuItemCustomization: Codable, Identifiable, Hashable {
    let id: Int
    let menuItemId: Int
    let name: String
    let type: String
    let category: String?
    let supportsPortions: Bool
    let portionPricing: PortionPricing?
    let defaultPortion: PortionLevel?
    let isRequired: Bool
    let displayOrder: Int

    // For legacy customization groups
    let options: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, type, category, options
        case menuItemId = "menu_item_id"
        case supportsPortions = "supports_portions"
        case portionPricing = "portion_pricing"
        case defaultPortion = "default_portion"
        case isRequired = "is_required"
        case displayOrder = "display_order"
    }

    var ingredientCategory: IngredientCategory? {
        guard let cat = category else { return nil }
        return IngredientCategory(rawValue: cat)
    }
}
```

#### 1.2 Update MenuItem Model
```swift
struct MenuItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let categoryId: String
    let imageURL: String
    let isAvailable: Bool
    let dietaryInfo: [DietaryTag]

    // Legacy customization groups (keep for backward compatibility)
    let customizationGroups: [CustomizationGroup]

    // NEW: Portion-based customizations
    var portionCustomizations: [MenuItemCustomization]?

    let calories: Int?
    let prepTime: Int

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    var hasPortionCustomizations: Bool {
        portionCustomizations?.contains { $0.supportsPortions } ?? false
    }
}
```

#### 1.3 Update CartItem Model
```swift
struct CartItem: Identifiable, Codable {
    let id: String
    let menuItem: MenuItem
    var quantity: Int

    // Legacy format (keep for backward compatibility)
    let selectedOptions: [String: [String]] // groupId: [optionIds]

    // NEW: Portion selections
    var portionSelections: [Int: PortionLevel]? // customizationId: portionLevel

    let specialInstructions: String?

    var totalPrice: Double {
        var price = menuItem.price * Double(quantity)

        // Add legacy customization costs
        for (groupId, optionIds) in selectedOptions {
            if let group = menuItem.customizationGroups.first(where: { $0.id == groupId }) {
                for optionId in optionIds {
                    if let option = group.options.first(where: { $0.id == optionId }) {
                        price += option.priceModifier * Double(quantity)
                    }
                }
            }
        }

        // Add portion-based customization costs
        if let portions = portionSelections,
           let customizations = menuItem.portionCustomizations {
            for (customizationId, portion) in portions {
                if let customization = customizations.first(where: { $0.id == customizationId }),
                   let pricing = customization.portionPricing {
                    price += pricing[portion] * Double(quantity)
                }
            }
        }

        return price
    }

    // Generate human-readable customization list for order submission
    var customizationsList: [String] {
        var list: [String] = []

        // Legacy customizations
        for (groupId, optionIds) in selectedOptions {
            if let group = menuItem.customizationGroups.first(where: { $0.id == groupId }) {
                let selectedNames = optionIds.compactMap { optionId in
                    group.options.first(where: { $0.id == optionId })?.name
                }
                list.append(contentsOf: selectedNames.map { "\(group.name): \($0)" })
            }
        }

        // Portion-based customizations
        if let portions = portionSelections,
           let customizations = menuItem.portionCustomizations {
            for (customizationId, portion) in portions where portion != .none {
                if let customization = customizations.first(where: { $0.id == customizationId }) {
                    list.append("\(portion.displayName) \(customization.name)")
                }
            }
        }

        return list
    }

    var formattedTotalPrice: String {
        String(format: "$%.2f", totalPrice)
    }
}
```

**Testing Checklist**:
- [ ] Models compile without errors
- [ ] PortionLevel enum has all 4 cases with correct emojis
- [ ] PortionPricing subscript returns correct prices
- [ ] IngredientCategory has correct icons and display order
- [ ] MenuItem backward compatible with existing code
- [ ] CartItem totalPrice calculation works for both legacy and portion-based

---

### Phase 2: API Integration (Day 2)
**Goal**: Fetch ingredient templates and menu item customizations from Supabase

#### 2.1 Add to `SupabaseManager.swift`
```swift
// MARK: - Ingredient Templates & Customizations

func fetchIngredientTemplates() async throws -> [IngredientTemplate] {
    print("🔍 Fetching ingredient templates...")

    let response = try await client
        .from("ingredient_templates")
        .select()
        .eq("is_active", value: true)
        .order("category")
        .order("display_order")
        .execute()

    let templates = try JSONDecoder().decode([IngredientTemplate].self, from: response.data)
    print("✅ Fetched \(templates.count) ingredient templates")

    return templates
}

func fetchMenuItemCustomizations(for menuItemId: Int) async throws -> [MenuItemCustomization] {
    print("🔍 Fetching customizations for menu item \(menuItemId)...")

    let response = try await client
        .from("menu_item_customizations")
        .select()
        .eq("menu_item_id", value: menuItemId)
        .order("category")
        .order("display_order")
        .execute()

    let customizations = try JSONDecoder().decode([MenuItemCustomization].self, from: response.data)
    print("✅ Fetched \(customizations.count) customizations")

    // Debug: Print portion-based customizations
    let portionBased = customizations.filter { $0.supportsPortions }
    print("   📊 Portion-based: \(portionBased.count)")
    for custom in portionBased {
        print("      - \(custom.name) (\(custom.category ?? "no category"))")
    }

    return customizations
}
```

#### 2.2 Update `fetchMenuItems()` to Include Customizations
```swift
func fetchMenuItems() async throws -> [MenuItem] {
    print("🔍 Fetching menu items from database...")

    struct DBMenuItem: Codable {
        let id: Int
        let name: String
        let description: String
        let price: Double
        let category_id: Int
        let image_url: String?
        let is_available: Bool
        let dietary_info: [String]?
        let calories: Int?
        let prep_time_minutes: Int?
    }

    let items: [DBMenuItem] = try await client
        .from("menu_items")
        .select()
        .eq("is_available", value: true)
        .execute()
        .value

    print("✅ Fetched \(items.count) menu items from database")

    // Convert to MenuItem and fetch customizations
    var menuItems: [MenuItem] = []

    for dbItem in items {
        // Fetch portion-based customizations for this item
        let customizations = try? await fetchMenuItemCustomizations(for: dbItem.id)

        let menuItem = MenuItem(
            id: String(dbItem.id),
            name: dbItem.name,
            description: dbItem.description,
            price: dbItem.price,
            categoryId: String(dbItem.category_id),
            imageURL: SupabaseConfig.imageURL(from: dbItem.image_url ?? ""),
            isAvailable: dbItem.is_available,
            dietaryInfo: (dbItem.dietary_info ?? []).compactMap { DietaryTag(rawValue: $0) },
            customizationGroups: [], // Legacy - can be populated if needed
            portionCustomizations: customizations,
            calories: dbItem.calories,
            prepTime: dbItem.prep_time_minutes ?? 15
        )

        menuItems.append(menuItem)
    }

    return menuItems
}
```

**Testing Checklist**:
- [ ] `fetchIngredientTemplates()` returns 13 templates
- [ ] Templates are sorted by category then display_order
- [ ] `fetchMenuItemCustomizations(84)` returns 9 items for "All American"
- [ ] Customizations have correct portion pricing
- [ ] Menu items include portionCustomizations array
- [ ] Verify "All American" has `hasPortionCustomizations == true`

---

### Phase 3: UI Components (Day 3-4)
**Goal**: Build SwiftUI components matching web app design

#### 3.1 Create `PortionSelectorButton.swift`
```swift
//
//  PortionSelectorButton.swift
//  camerons-customer-app
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
    HStack(spacing: 8) {
        PortionSelectorButton(portion: .none, isSelected: false, price: nil) {}
        PortionSelectorButton(portion: .light, isSelected: false, price: 0.75) {}
        PortionSelectorButton(portion: .regular, isSelected: true, price: 1.00) {}
        PortionSelectorButton(portion: .extra, isSelected: false, price: 1.50) {}
    }
    .padding()
}
```

#### 3.2 Create `IngredientRow.swift`
```swift
//
//  IngredientRow.swift
//  camerons-customer-app
//
//  Created by Claude Code on 11/21/25.
//

import SwiftUI

struct IngredientRow: View {
    let customization: MenuItemCustomization
    @Binding var selectedPortion: PortionLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ingredient Name & Price
            HStack {
                Text(customization.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Spacer()

                if let pricing = customization.portionPricing,
                   pricing[selectedPortion] > 0 {
                    Text("+$\(pricing[selectedPortion], specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.brandPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brandPrimary.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Portion Selector Buttons
            HStack(spacing: 8) {
                ForEach(PortionLevel.allCases, id: \.self) { portion in
                    PortionSelectorButton(
                        portion: portion,
                        isSelected: selectedPortion == portion,
                        price: customization.portionPricing?[portion],
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

#Preview {
    @Previewable @State var selectedPortion: PortionLevel = .regular

    IngredientRow(
        customization: MenuItemCustomization(
            id: 1,
            menuItemId: 84,
            name: "Extra Cheese",
            type: "single",
            category: "extras",
            supportsPortions: true,
            portionPricing: PortionPricing(none: 0, light: 0.75, regular: 1.00, extra: 1.50),
            defaultPortion: .none,
            isRequired: false,
            displayOrder: 1,
            options: nil
        ),
        selectedPortion: $selectedPortion
    )
    .padding()
}
```

#### 3.3 Create `CategorySection.swift`
```swift
//
//  CategorySection.swift
//  camerons-customer-app
//
//  Created by Claude Code on 11/21/25.
//

import SwiftUI

struct CategorySection: View {
    let category: IngredientCategory
    let customizations: [MenuItemCustomization]
    @Binding var selections: [Int: PortionLevel]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Category Header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(categoryColor)

                Text(category.displayName)
                    .font(AppFonts.headline)
                    .foregroundColor(.textPrimary)

                Spacer()
            }
            .padding(.bottom, 4)

            // Separator Line
            Rectangle()
                .fill(categoryColor.opacity(0.3))
                .frame(height: 2)
                .padding(.bottom, 8)

            // Ingredients
            ForEach(customizations) { customization in
                IngredientRow(
                    customization: customization,
                    selectedPortion: Binding(
                        get: { selections[customization.id] ?? customization.defaultPortion ?? .regular },
                        set: { selections[customization.id] = $0 }
                    )
                )
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
```

#### 3.4 Update `ItemDetailView.swift`
Replace the existing customization section with portion-based UI:

```swift
// Around line 172-186, replace customization groups section with:

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
```

Add state variable at the top:
```swift
@State private var portionSelections: [Int: PortionLevel] = [:]
```

Update `onAppear` to set defaults:
```swift
.onAppear {
    menuViewModel.trackItemView(item)

    // Set default portions
    if let customizations = item.portionCustomizations {
        for customization in customizations where customization.supportsPortions {
            if let defaultPortion = customization.defaultPortion {
                portionSelections[customization.id] = defaultPortion
            }
        }
    }
}
```

Update `totalPrice` computation:
```swift
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

    // Add portion-based costs
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
```

Update `addToCart`:
```swift
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
```

**Testing Checklist**:
- [ ] PortionSelectorButton displays correctly
- [ ] Selected state has blue background, white text
- [ ] Pricing shows below button for premium items
- [ ] IngredientRow displays name and portion selector
- [ ] CategorySection shows correct icon and color
- [ ] Categories appear in correct order (Vegetables, Sauces, Extras)
- [ ] Tapping portion button updates selection
- [ ] Price updates in real-time in sticky button
- [ ] Default portions pre-selected on view load

---

### Phase 4: Cart & Order Integration (Day 5)
**Goal**: Update cart and order submission to handle portion selections

#### 4.1 Update `CartViewModel.swift`
```swift
func addItem(
    menuItem: MenuItem,
    quantity: Int,
    selectedOptions: [String: [String]] = [:],
    portionSelections: [Int: PortionLevel]? = nil,
    specialInstructions: String? = nil
) {
    let cartItem = CartItem(
        id: UUID().uuidString,
        menuItem: menuItem,
        quantity: quantity,
        selectedOptions: selectedOptions,
        portionSelections: portionSelections,
        specialInstructions: specialInstructions
    )

    items.append(cartItem)
    ToastManager.shared.show(
        message: "Added to cart",
        icon: "checkmark.circle.fill",
        type: .success
    )
}
```

#### 4.2 Update `SupabaseManager.submitOrder()`
```swift
func submitOrder(
    items: [CartItem],
    storeId: String,
    orderType: OrderType,
    subtotal: Double,
    tax: Double,
    total: Double,
    deliveryAddress: String? = nil,
    customerEmail: String,
    customerName: String?
) async throws -> (orderId: String, orderNumber: String) {
    print("📦 Submitting order...")

    // ... existing order creation code ...

    // Create order items with portion data
    for item in items {
        var customizationsList: [String] = []

        // Add legacy customizations
        for (groupId, optionIds) in item.selectedOptions {
            if let group = item.menuItem.customizationGroups.first(where: { $0.id == groupId }) {
                let selectedNames = optionIds.compactMap { optionId in
                    group.options.first(where: { $0.id == optionId })?.name
                }
                customizationsList.append(contentsOf: selectedNames.map { "\(group.name): \($0)" })
            }
        }

        // Add portion-based customizations
        if let portions = item.portionSelections,
           let customizations = item.menuItem.portionCustomizations {
            for (customizationId, portion) in portions where portion != .none {
                if let customization = customizations.first(where: { $0.id == customizationId }) {
                    customizationsList.append("\(portion.displayName) \(customization.name)")
                }
            }
        }

        let orderItem: [String: Any] = [
            "order_id": orderId,
            "menu_item_id": Int(item.menuItem.id) ?? 0,
            "quantity": item.quantity,
            "unit_price": item.menuItem.price,
            "customizations": customizationsList,
            "selected_options": item.selectedOptions,
            "notes": item.specialInstructions as Any,
            "subtotal": item.totalPrice
        ]

        try await client
            .from("order_items")
            .insert(orderItem)
            .execute()
    }

    print("✅ Order submitted successfully")
    return (orderId, orderNumber)
}
```

**Testing Checklist**:
- [ ] Items with portion selections add to cart correctly
- [ ] Cart displays portion selections in item details
- [ ] Cart total price includes portion costs
- [ ] Order submission includes portion data in customizations array
- [ ] Order appears in database with correct format
- [ ] Legacy items (non-portion) still work correctly

---

### Phase 5: Testing & Polish (Day 6)
**Goal**: Comprehensive testing and UI polish

#### 5.1 Test Cases
1. **"All American" Sandwich (menu_item_id = 84)**
   - [ ] Load item detail view
   - [ ] Verify 9 customizations display
   - [ ] Verify 3 categories (Vegetables, Sauces, Extras)
   - [ ] Verify Lettuce defaults to Regular
   - [ ] Verify Extra Cheese defaults to None
   - [ ] Change Extra Cheese to Regular (+$1.00)
   - [ ] Verify total updates to $9.49
   - [ ] Add to cart
   - [ ] Verify cart shows "Regular Extra Cheese"
   - [ ] Submit order
   - [ ] Verify database has correct customizations

2. **Pricing Verification**
   - [ ] Free ingredients (Lettuce, Tomato) don't change price at any portion
   - [ ] Extra Cheese: None=$0, Light=$0.75, Regular=$1.00, Extra=$1.50
   - [ ] Multiple extras add correctly (Extra Cheese + Bacon)
   - [ ] Quantity multiplies portion costs correctly

3. **UI/UX Testing**
   - [ ] Portion buttons are tappable and responsive
   - [ ] Selected state is visually clear
   - [ ] Categories have correct icons and colors
   - [ ] Scrolling works smoothly with many customizations
   - [ ] Sticky "Add to Cart" button always visible
   - [ ] Price updates are instant (no lag)

4. **Edge Cases**
   - [ ] Item with no portion customizations shows legacy UI
   - [ ] Item with both portion and legacy customizations handles correctly
   - [ ] Empty cart handles portion items
   - [ ] Offline mode caches ingredient data
   - [ ] Network error during customization fetch shows graceful error

#### 5.2 Performance Optimization
- [ ] Cache ingredient templates (they rarely change)
- [ ] Debounce price calculations if needed
- [ ] Lazy load customizations (fetch when detail view opens)
- [ ] Test with 20+ customizations per item

#### 5.3 Accessibility
- [ ] Portion buttons have proper accessibility labels
- [ ] VoiceOver reads category headers correctly
- [ ] Dynamic Type supports all text sizes
- [ ] High contrast mode works for selected states

---

## 📝 Implementation Checklist

### Day 1: Data Models ✅
- [ ] Add `PortionLevel`, `PortionPricing`, `IngredientCategory` enums
- [ ] Add `IngredientTemplate`, `MenuItemCustomization` structs
- [ ] Update `MenuItem` with `portionCustomizations`
- [ ] Update `CartItem` with `portionSelections`
- [ ] Test all models compile and work correctly

### Day 2: API Integration ✅
- [ ] Add `fetchIngredientTemplates()` to SupabaseManager
- [ ] Add `fetchMenuItemCustomizations()` to SupabaseManager
- [ ] Update `fetchMenuItems()` to include customizations
- [ ] Test API calls return correct data
- [ ] Verify "All American" has 9 customizations

### Day 3-4: UI Components ✅
- [ ] Create `PortionSelectorButton.swift`
- [ ] Create `IngredientRow.swift`
- [ ] Create `CategorySection.swift`
- [ ] Update `ItemDetailView.swift` with portion UI
- [ ] Test UI matches web app design
- [ ] Verify price updates in real-time

### Day 5: Cart & Orders ✅
- [ ] Update `CartViewModel.addItem()` for portions
- [ ] Update `SupabaseManager.submitOrder()` for portions
- [ ] Test cart displays portion selections
- [ ] Test order submission includes portion data
- [ ] Verify database records are correct

### Day 6: Testing & Polish ✅
- [ ] Complete all test cases
- [ ] Fix any bugs found
- [ ] Optimize performance
- [ ] Verify accessibility
- [ ] Final QA with "All American" sandwich

---

## 🎯 Success Criteria

### Functional Requirements
✅ All 6 sandwich items display portion-based customizations
✅ UI matches web app design 100%
✅ Real-time price calculations work correctly
✅ Cart correctly handles portion selections
✅ Orders submit with correct portion data to database
✅ Backward compatibility with legacy customizations maintained

### Design Requirements
✅ Category headers with icons match web design
✅ Portion buttons use emoji indicators (○ ◔ ◑ ●)
✅ Selected state visually clear (blue background, white text)
✅ Premium items show pricing next to name
✅ Portion pricing displayed under buttons for extras
✅ Sticky cart button updates in real-time

### Performance Requirements
✅ Customizations load in < 500ms
✅ UI remains responsive with 20+ customizations
✅ Price calculations instant (< 100ms)
✅ Smooth scrolling with no lag

---

## 📚 Reference Materials

### Web App Files (For Design Reference)
- `src/components/ui/PortionSelector.tsx` - React portion selector
- `src/components/order/ItemCustomizationModalV2.tsx` - Customer modal
- `src/components/dashboard/IngredientTemplateSelector.tsx` - Admin UI

### iOS Sync Documentation (Web Repo)
- `README_IOS_SYNC.md` - Overview
- `IOS_SYNC_PORTION_CUSTOMIZATIONS.md` - Swift examples
- `CHANGELOG_iOS.md` - Migration details

### Database Schema
- `supabase/migrations/042_portion_based_customizations.sql`
- `supabase/migrations/044_link_ingredients_to_menu_items.sql`

---

## 🚀 Getting Started

1. **Read this document fully**
2. **Review web app UI** at http://localhost:8080/menu
3. **Start with Phase 1** (Data Models)
4. **Test incrementally** after each phase
5. **Refer to web implementation** when stuck

---

**Last Updated**: November 21, 2025
**Estimated Duration**: 6 days
**Priority**: High
**Status**: Ready to Start
