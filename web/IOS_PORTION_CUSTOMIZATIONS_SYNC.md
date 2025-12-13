# iOS Sync Update: Portion-Based Customizations

**Date**: 2025-11-20
**Feature**: Modern Portion-Based Ingredient Customization System

## 🎯 What Changed

### New Database Schema
- **New Table**: `ingredient_templates` for reusable ingredients
- **Enhanced Table**: `menu_item_customizations` with portion support
- **Migration File**: `042_portion_based_customizations.sql`

### New Ingredient System
Replaces simple add-ons with a sophisticated portion-based system where every ingredient has 4 levels:
- **None** (○) - Don't include
- **Light** (◔) - 25% portion
- **Regular** (◑) - 50% portion (default)
- **Extra** (●) - 100% portion

## 📱 iOS Implementation Requirements

### 1. Database Migration

Run this migration in Supabase (already applied to web):
```sql
supabase/migrations/042_portion_based_customizations.sql
```

### 2. New Data Models

#### IngredientTemplate (Swift)
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
        case id
        case name
        case category
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
}

enum PortionLevel: String, Codable, CaseIterable {
    case none
    case light
    case regular
    case extra

    var emoji: String {
        switch self {
        case .none: return "○"
        case .light: return "◔"
        case .regular: return "◑"
        case .extra: return "●"
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

struct PortionPricing: Codable {
    let none: Double
    let light: Double
    let regular: Double
    let extra: Double
}
```

#### Enhanced MenuItemCustomization (Swift)
```swift
struct MenuItemCustomization: Codable, Identifiable {
    let id: Int
    let menuItemId: Int
    let templateId: Int?
    let name: String
    let type: CustomizationType
    let category: String?
    let supportsPortions: Bool
    let portionPricing: PortionPricing?
    let defaultPortion: PortionLevel?
    let options: [CustomizationOption]?
    let isRequired: Bool
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case menuItemId = "menu_item_id"
        case templateId = "template_id"
        case name
        case type
        case category
        case supportsPortions = "supports_portions"
        case portionPricing = "portion_pricing"
        case defaultPortion = "default_portion"
        case options
        case isRequired = "is_required"
        case displayOrder = "display_order"
    }
}
```

### 3. UI Components Needed

#### PortionSelector View (SwiftUI)
```swift
struct PortionSelectorView: View {
    let ingredient: MenuItemCustomization
    @Binding var selectedPortion: PortionLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(ingredient.name)
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                if let pricing = ingredient.portionPricing,
                   pricing[selectedPortion] > 0 {
                    Text("+$\(pricing[selectedPortion], specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                ForEach(PortionLevel.allCases, id: \.self) { portion in
                    PortionButton(
                        portion: portion,
                        isSelected: selectedPortion == portion,
                        action: { selectedPortion = portion }
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PortionButton: View {
    let portion: PortionLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(portion.emoji)
                    .font(.title2)
                Text(portion.label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}
```

#### Ingredient Category Section (SwiftUI)
```swift
struct IngredientCategorySection: View {
    let category: IngredientCategory
    let ingredients: [MenuItemCustomization]
    @Binding var selections: [Int: PortionLevel]

    var categoryConfig: (icon: String, title: String, color: Color) {
        switch category {
        case .vegetables:
            return ("leaf.fill", "Fresh Vegetables", .green)
        case .sauces:
            return ("drop.fill", "Signature Sauces", .orange)
        case .extras:
            return ("sparkles", "Premium Extras", .purple)
        }
    }

    var body: some View {
        Section {
            ForEach(ingredients) { ingredient in
                PortionSelectorView(
                    ingredient: ingredient,
                    selectedPortion: Binding(
                        get: { selections[ingredient.id] ?? .regular },
                        set: { selections[ingredient.id] = $0 }
                    )
                )
            }
        } header: {
            Label(categoryConfig.title, systemImage: categoryConfig.icon)
                .foregroundColor(categoryConfig.color)
                .font(.headline)
        }
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

#### Fetch Item Customizations with Portions
```swift
func fetchItemCustomizations(menuItemId: Int) async throws -> [MenuItemCustomization] {
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

When submitting an order with portion customizations:

```swift
struct OrderItemCustomization {
    let customizationId: Int
    let selectedPortion: PortionLevel?
    let selectedOptions: [String]?  // For non-portion customizations
}

// Example order item
let orderItem = [
    "menu_item_id": 5,
    "quantity": 1,
    "customizations": [
        "Lettuce: Regular",
        "Tomato: Light",
        "Chipotle Mayo: Extra",
        "Extra Cheese: Regular"
    ],
    "selected_options": [
        "1": ["regular"],      // Lettuce (customization_id: 1)
        "2": ["light"],        // Tomato (customization_id: 2)
        "3": ["extra"],        // Chipotle Mayo (customization_id: 3)
        "4": ["regular"]       // Extra Cheese (customization_id: 4)
    ],
    "base_price": 6.49,
    "customization_price": 1.00,  // Extra Cheese
    "total_price": 7.49
]
```

### 6. Price Calculation Logic

```swift
func calculateCustomizationPrice(
    customizations: [MenuItemCustomization],
    selections: [Int: PortionLevel]
) -> Double {
    var total: Double = 0

    for customization in customizations where customization.supportsPortions {
        guard let pricing = customization.portionPricing,
              let selectedPortion = selections[customization.id] else {
            continue
        }

        switch selectedPortion {
        case .none:
            total += pricing.none
        case .light:
            total += pricing.light
        case .regular:
            total += pricing.regular
        case .extra:
            total += pricing.extra
        }
    }

    return total
}
```

## 🎨 UI/UX Guidelines

### Design Principles
1. **Visual Hierarchy**: Group ingredients by category (Vegetables, Sauces, Extras)
2. **Clear Icons**: Use emoji/SF Symbols for portion levels (○ ◔ ◑ ●)
3. **Instant Feedback**: Update total price immediately when portions change
4. **Smart Defaults**: Pre-select "Regular" for common ingredients
5. **Premium Highlighting**: Show "$" badge on charged items

### Color Scheme
- **Vegetables**: Green (#10B981)
- **Sauces**: Orange/Amber (#F59E0B)
- **Extras**: Purple (#8B5CF6)

### Accessibility
- Use SF Symbols for icons (better than emoji for accessibility)
- Ensure sufficient contrast ratios
- Support VoiceOver with clear labels
- Make buttons at least 44x44pt

## 📋 Default Templates (13 Ingredients)

### 🥗 Fresh Vegetables (4)
1. Lettuce - Free
2. Tomato - Free
3. Onion - Free
4. Pickles - Free

### 🥫 Signature Sauces (6)
1. Chipotle Mayo - Free
2. Mayo - Free
3. Russian Dressing - Free
4. Ketchup - Free
5. Mustard - Free
6. Hot Sauce - Free

### ✨ Premium Extras (3)
1. Extra Cheese - $0.75 (Light) to $1.50 (Extra)
2. Bacon - $1.00 (Light) to $2.00 (Extra)
3. Avocado - $1.50 (Light) to $2.50 (Extra)

## 🔄 Migration Steps for iOS

1. **Update Supabase Client**: Ensure latest version
2. **Run Migration**: Execute SQL in Supabase dashboard
3. **Add Models**: Copy Swift models above
4. **Create UI Components**: Build PortionSelector and category sections
5. **Update Order Flow**: Integrate new customization format
6. **Test Thoroughly**: Verify pricing calculations
7. **Update Admin**: Allow staff to manage ingredients (optional)

## ⚠️ Breaking Changes

### What Changed
- New column `supports_portions` in `menu_item_customizations`
- New table `ingredient_templates`
- Customization format now includes portion levels

### Backward Compatibility
- Old customizations (non-portion) still work
- Items without `supports_portions = true` use old UI
- No changes to existing orders in database

## ✅ Testing Checklist

- [ ] Migration runs successfully
- [ ] Ingredient templates load correctly
- [ ] Portion selector displays all 4 levels
- [ ] Price updates when portion changes
- [ ] Free items show no price
- [ ] Premium items show correct pricing
- [ ] Order submission includes portion data
- [ ] Orders display correctly in order history
- [ ] Staff can view portion selections in dashboard

## 📞 Support

If you encounter issues during iOS implementation:
1. Check Supabase logs for API errors
2. Verify JSON decoder matches exact column names (snake_case)
3. Ensure RLS policies allow public read access to `ingredient_templates`
4. Test with a simple sandwich item first before complex items

## 🚀 Go Live

Once iOS implementation is complete:
1. Test on TestFlight with real users
2. Verify order flow end-to-end
3. Confirm pricing calculations are correct
4. Deploy to production
5. Monitor for any issues

---

**Web Implementation**: ✅ Complete
**iOS Implementation**: 🔄 Pending
**Database Migration**: ✅ Ready to run
