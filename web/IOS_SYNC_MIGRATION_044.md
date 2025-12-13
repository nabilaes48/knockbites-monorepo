# iOS Sync: Migration 044 - Menu Item Customizations

**Migration**: 044_link_ingredients_to_menu_items.sql
**Date**: November 20, 2025
**Status**: ✅ Deployed to Production
**iOS Impact**: Data Ready - Fetch and Display

---

## 🎯 What This Migration Does

Migration 044 completes the portion-based customization system by **linking ingredient templates to actual menu items**.

### Before Migration 044
- ✅ Migration 042 created 13 ingredient templates
- ❌ Templates weren't linked to any menu items
- ❌ iOS couldn't fetch customizations for specific items
- ❌ Modals showed "No customization options available"

### After Migration 044
- ✅ 6 sandwich items now have customizations
- ✅ 9 customizations per sandwich (vegetables + sauces + extras)
- ✅ Smart defaults set (Lettuce = Regular, Extra Cheese = None)
- ✅ iOS can fetch and display customizations

---

## 📊 What's Available Now

### Menu Items with Customizations
| Menu Item | Customizations | Default Portions |
|-----------|----------------|------------------|
| All American | 9 | Vegetables: Regular, Russian Dressing: Regular |
| American Combo | 9 | Vegetables: Regular, Russian Dressing: Regular |
| Chicken Cutlet | 9 | Vegetables: Regular, Sauces: None |
| Turkey Club | 9 | Vegetables: Regular, Russian Dressing: Regular |
| BLT Sandwich | 9 | Vegetables: Regular, Russian Dressing: Regular |
| Ham & Cheese | 9 | Vegetables: Regular, Russian Dressing: Regular |

### Customizations Per Item (9 Total)
**🥗 Fresh Vegetables (4)** - All default to Regular
- Lettuce
- Tomato
- Onion
- Pickles

**🥫 Signature Sauces (4)** - Default varies by item
- Mayo (default: None)
- Mustard (default: None)
- Russian Dressing (default: Regular for most items)
- Chipotle Mayo (optional, default: None)

**✨ Premium Extras (1)** - Default to None
- Extra Cheese (pricing: Light $0.75, Regular $1.00, Extra $1.50)

---

## 🔌 iOS API Integration

### 1. Fetch Customizations for a Menu Item

```swift
// Query menu_item_customizations table
func fetchCustomizations(for menuItemId: Int) async throws -> [MenuItemCustomization] {
    let response = try await supabase
        .from("menu_item_customizations")
        .select("*")
        .eq("menu_item_id", value: menuItemId)
        .eq("supports_portions", value: true)
        .order("display_order")
        .execute()

    return try JSONDecoder().decode([MenuItemCustomization].self, from: response.data)
}
```

### 2. Expected Response Format

```json
[
  {
    "id": 12,
    "menu_item_id": 84,
    "name": "Lettuce",
    "type": "single",
    "options": [],
    "category": "vegetables",
    "supports_portions": true,
    "portion_pricing": {
      "none": 0,
      "light": 0,
      "regular": 0,
      "extra": 0
    },
    "default_portion": "regular",
    "display_order": 1
  },
  {
    "id": 13,
    "menu_item_id": 84,
    "name": "Extra Cheese",
    "type": "single",
    "options": [],
    "category": "extras",
    "supports_portions": true,
    "portion_pricing": {
      "none": 0,
      "light": 0.75,
      "regular": 1.00,
      "extra": 1.50
    },
    "default_portion": "none",
    "display_order": 20
  }
]
```

### 3. Group by Category

```swift
func groupByCategory(_ customizations: [MenuItemCustomization]) -> [String: [MenuItemCustomization]] {
    Dictionary(grouping: customizations, by: { $0.category })
}

// Result:
// [
//   "vegetables": [Lettuce, Tomato, Onion, Pickles],
//   "sauces": [Mayo, Mustard, Russian Dressing],
//   "extras": [Extra Cheese]
// ]
```

---

## 💰 Pricing Logic

### Calculate Additional Cost

```swift
func calculateAdditionalCost(
    customizations: [MenuItemCustomization],
    selections: [Int: PortionLevel]
) -> Decimal {
    var total: Decimal = 0

    for customization in customizations {
        guard let selectedPortion = selections[customization.id] else { continue }

        let price = customization.portionPricing[selectedPortion.rawValue] ?? 0
        total += Decimal(price)
    }

    return total
}

// Example:
// - Lettuce (Regular): $0.00
// - Extra Cheese (Regular): $1.00
// Total additional cost: $1.00
```

---

## 🎨 UI Display Pattern

### Display Order
1. **🥗 Fresh Vegetables** (category = "vegetables")
2. **🥫 Signature Sauces** (category = "sauces")
3. **✨ Premium Extras** (category = "extras")

### Default State
- Load `default_portion` from database
- Pre-select portion buttons based on defaults
- Show initial price with defaults applied

### User Interaction
1. User taps portion button (None/Light/Regular/Extra)
2. Update selection state
3. Recalculate total price
4. Show updated price in real-time

---

## 📝 Order Submission Format

### Save Customizations

```swift
// Format for order_items.customizations (human-readable array)
let customizations = selections
    .compactMap { (id, portion) -> String? in
        guard let customization = findCustomization(id: id),
              portion != .none else { return nil }

        let portionText = portion.rawValue.capitalized
        return "\(portionText) \(customization.name)"
    }

// Example output:
// ["Regular Lettuce", "Light Tomato", "Extra Cheese"]
```

---

## ✅ Testing Checklist

### Database Verification
- [ ] Query returns 9 customizations for "All American" (menu_item_id = 84)
- [ ] All customizations have `supports_portions = true`
- [ ] Categories are correct (vegetables, sauces, extras)
- [ ] Default portions are set correctly

### iOS UI Testing
- [ ] Customizations load for all 6 sandwich items
- [ ] Portion buttons display correctly (None/Light/Regular/Extra)
- [ ] Default portions are pre-selected
- [ ] Tapping portion buttons updates selection
- [ ] Price updates in real-time
- [ ] Free ingredients don't add to price
- [ ] Extra Cheese adds $1.00 (Regular portion)

### Order Flow Testing
- [ ] Selected customizations save to order
- [ ] Customizations display correctly in order history
- [ ] Business app shows customizations
- [ ] Price matches expected total

---

## 🔧 Helper Function Available

Migration 044 created a helper function you can use to add customizations to more menu items:

```sql
-- Add standard customizations to any sandwich
SELECT add_standard_sandwich_customizations(
  123,   -- menu_item_id
  true,  -- include Russian dressing as default
  false  -- include Chipotle mayo as default
);
```

This is useful if you want to add customizations to additional menu items in the future.

---

## 🚨 Common Issues

### Issue: No customizations returned
**Check:**
1. Does menu item exist? `SELECT * FROM menu_items WHERE id = 84`
2. Are customizations linked? `SELECT * FROM menu_item_customizations WHERE menu_item_id = 84`
3. RLS policies allow read? Should be public SELECT

### Issue: Wrong default portions
**Fix:**
```sql
UPDATE menu_item_customizations
SET default_portion = 'regular'
WHERE menu_item_id = 84 AND name = 'Lettuce';
```

### Issue: Missing pricing
**Check:**
```sql
SELECT name, portion_pricing
FROM menu_item_customizations
WHERE menu_item_id = 84 AND category = 'extras';
```

---

## 📚 Related Documentation

- **Swift Implementation**: `IOS_SYNC_PORTION_CUSTOMIZATIONS.md`
- **Feature Overview**: `PORTION_BASED_CUSTOMIZATIONS.md`
- **Verification Guide**: `RUN_MIGRATION_044.md`
- **Changelog**: `CHANGELOG_iOS.md`

---

## 🎯 Next Steps for iOS

1. ✅ Migration 044 deployed (done)
2. 🔄 Implement Swift models from `IOS_SYNC_PORTION_CUSTOMIZATIONS.md`
3. 🔄 Build PortionSelector UI component
4. 🔄 Update menu item detail view to fetch customizations
5. 🔄 Test with "All American" sandwich first
6. 🔄 Roll out to other menu items

---

**Questions?** Check `IOS_SYNC_PORTION_CUSTOMIZATIONS.md` for complete Swift code examples!
