# iOS Apps Sync Update - November 21, 2025

## 🎯 What Changed

The web app has been updated to match the iOS apps' data format. Critical database migrations have been deployed to production:

### Migration 042 - Portion-Based Customizations (Nov 21, 2025)
- ✅ Deployed to production Supabase
- Adds modern ingredient customization system with portion levels (None/Light/Regular/Extra)
- 13 pre-loaded ingredient templates (vegetables, sauces, premium extras)
- **See detailed guide**: `IOS_SYNC_PORTION_CUSTOMIZATIONS.md`

### Migration 043 - RLS Performance Optimization (Nov 21, 2025)
- ✅ Deployed to production Supabase (backend-only optimization)
- Optimizes 22 RLS policies for 10-100x faster queries
- Removes duplicate indexes
- **No iOS code changes needed** - automatic performance boost
- **See detailed guide**: `IOS_SYNC_RLS_OPTIMIZATION.md`

### 🆕 NEW: Migration 044 - Link Ingredients to Menu Items (Nov 20, 2025)
- ✅ Deployed to production Supabase
- Links ingredient templates to actual menu items (6 sandwiches ready)
- Creates helper function for bulk ingredient assignment
- Sets smart defaults (vegetables default to Regular, extras default to None)
- **iOS can now fetch customizations** for menu items
- **See verification guide**: `RUN_MIGRATION_044.md`

### Migration 022 - Customizations Schema
- ✅ Deployed to production Supabase
- Adds dual-format customization storage to match iOS implementation

### Migration 023 - Order Number System
- ✅ Deployed to production Supabase
- Implements multi-store order numbering: `[STORE_CODE]-[YYMMDD]-[SEQUENCE]`
- Example: `HM-251119-009` (Highland Mills, Nov 19 2025, order #9)

---

## 📋 Quick Reference

### All Active Migrations
1. **Migration 022** - Dual customization format (Nov 19)
2. **Migration 023** - Multi-store order numbering (Nov 19)
3. **Migration 042** - Portion-based ingredients (Nov 21)
4. **Migration 043** - RLS performance optimization (Nov 21)
5. **Migration 044** - Link ingredients to menu items (Nov 20) ⭐ NEW

### Key Files for iOS Implementation
- `IOS_SYNC_PORTION_CUSTOMIZATIONS.md` - Complete Swift implementation guide
- `PORTION_BASED_CUSTOMIZATIONS.md` - Feature documentation
- `supabase/migrations/042_portion_based_customizations_v2.sql` - Database schema

### Current Ingredient Count
- **13 Total Ingredients**
  - 🥗 Fresh Vegetables: 4 (Lettuce, Tomato, Onion, Pickles)
  - 🥫 Signature Sauces: 6 (Chipotle Mayo, Mayo, Russian, Ketchup, Mustard, Hot Sauce)
  - ✨ Premium Extras: 3 (Extra Cheese, Bacon, Avocado - with tiered pricing)

### Menu Items with Customizations (Migration 044)
- **6 Sandwiches Ready**
  - All American (9 customizations)
  - American Combo (9 customizations)
  - Chicken Cutlet Sandwich (9 customizations)
  - Turkey Club (9 customizations)
  - BLT Sandwich (9 customizations)
  - Ham & Cheese (9 customizations)

---

## 📱 For Customer App Developer

### What's Ready
✅ Database schema matches your iOS app format
✅ Web app updated to send customizations in both formats
✅ Order numbering system fully deployed

### What You Need to Test
1. **Place a test order** from iOS customer app
2. **Verify order number format**: Should be `HM-251119-XXX` (not random numbers)
3. **Check customizations**: Both `selected_options` and `customizations` should save
4. **Confirm order appears** in business app with correct format

### Expected Behavior
```swift
// Order should have:
order_number: "HM-251119-010"  // Not random numbers anymore

// Order items should have both:
customizations: ["Cheese: Extra Cheese", "Size: Large"]
selected_options: {"group_cheese": ["extra_cheese"], "group_size": ["large"]}
```

### Test Checklist (Previous Features)
- [ ] Order gets proper store-based order number
- [ ] Customizations save in both formats
- [ ] Order appears in business app immediately
- [ ] Order tracking works on web (http://localhost:8080/order/tracking/{order_id})

### 🆕 New Test Checklist (Portion-Based Customizations - Migrations 042 + 044)
- [ ] Ingredient templates load (should be 13 total)
- [ ] Menu item customizations fetch correctly (9 per sandwich)
- [ ] Portion selectors display (None/Light/Regular/Extra)
- [ ] Default portions load correctly (Lettuce = Regular, Extra Cheese = None)
- [ ] Price updates when selecting "Extra Cheese" (+$1.00)
- [ ] Free ingredients (Lettuce, Tomato, Mayo) don't change price
- [ ] Customizations save in format: ["Regular Lettuce", "Extra Chipotle Mayo"]
- [ ] Order displays ingredient portions correctly

---

## 💼 For Business App Developer

### What's Ready
✅ Database schema updated with customizations columns
✅ Order number system matches your implementation
✅ Web orders will now have the same format as iOS orders

### What You Need to Test
1. **Check existing orders** in business app - should show new order numbers
2. **Place test order from web** (http://localhost:8080/order)
3. **Verify it appears** in iOS business app with proper order number
4. **Check customizations display** correctly

### Expected Behavior
```swift
// All orders (iOS + Web) should have:
order_number: "HM-251119-010"  // Multi-store format

// Order items from web should have:
customizations: ["Cheese: Extra Cheese"]  // Human-readable array
selected_options: {"group_cheese": ["extra_cheese"]}  // Raw JSON
```

### Test Checklist
- [ ] Existing orders show new order number format
- [ ] Web orders appear in real-time
- [ ] Order numbers are consistent across all apps
- [ ] Customizations from web orders display properly
- [ ] Order details show item customizations

---

## 🔄 Data Format Reference

### Order Number Format
```
[STORE_CODE]-[YYMMDD]-[SEQUENCE]

Examples:
HM-251119-001   (Highland Mills, Nov 19, order #1)
MO-251119-015   (Monroe, Nov 19, order #15)
MW-251120-001   (Middletown, Nov 20, order #1)
```

### Store Codes (All 29 Stores)
| ID | Store | Code | ID | Store | Code | ID | Store | Code |
|----|-------|------|----|----- |------|----|----- |------|
| 1  | Highland Mills | HM | 11 | Warwick | WR | 21 | Fishkill | FI |
| 2  | Monroe | MO | 12 | Florida | FL | 22 | Beacon | BE |
| 3  | Middletown | MW | 13 | Vails Gate | VV | 23 | Wappingers Falls | WP2 |
| 4  | Newburgh | NW | 14 | Walden | WL | 24 | Hyde Park | HD |
| 5  | West Point | WP | 15 | Maybrook | ML | 25 | Red Hook | RD |
| 6  | Slate Hill | SL | 16 | Cornwall | CR | 26 | Millbrook | MI |
| 7  | Port Jervis | PS | 17 | New Paltz | NP | 27 | Dover Plains | DV |
| 8  | Goshen West | GW | 18 | Kingston | KG | 28 | Amenia | AM |
| 9  | Goshen East | GE | 19 | Rhinebeck | RH | 29 | Pawling | PW |
| 10 | Chester | CH | 20 | Poughkeepsie | PK |

### Customizations Format
```json
{
  "customizations": [
    "Cheese: Extra Cheese",
    "Size: Large",
    "Toppings: Lettuce, Tomato"
  ],
  "selected_options": {
    "group_cheese": ["extra_cheese"],
    "group_size": ["large"],
    "group_toppings": ["lettuce", "tomato"]
  }
}
```

---

## 🧪 Testing Workflow

### Complete End-to-End Test

1. **iOS Customer App → iOS Business App**
   - Place order from iOS customer app
   - Verify appears in iOS business app
   - Check order number format
   - Verify customizations display

2. **Web → iOS Business App**
   - Place order from web (http://localhost:8080/order)
   - Verify appears in iOS business app
   - Check order number matches format
   - Verify customizations display

3. **Cross-Platform Order Tracking**
   - Place order from iOS
   - Track on web: http://localhost:8080/order/tracking/{order_id}
   - Verify real-time status updates work

4. **Order Number Sequence**
   - Place 3 orders from Highland Mills store
   - Verify sequence: HM-251119-001, HM-251119-002, HM-251119-003
   - Place 1 order from Monroe store
   - Verify: MO-251119-001

---

## 🚨 What to Report Back

Please test and report:

**Customer App Developer:**
- [ ] Screenshot of order with new order number
- [ ] Confirm customizations save correctly
- [ ] Any errors in console logs

**Business App Developer:**
- [ ] Screenshot showing web order in business app
- [ ] Confirm order numbers match across platforms
- [ ] Confirm customizations display correctly
- [ ] Any errors or mismatches

---

## 📞 Support

If you encounter any issues:
1. Check Supabase logs for errors
2. Verify database migrations ran successfully:
   - Migration 022 (customizations columns)
   - Migration 023 (order number system)
3. Share console logs and error messages

**Database Status:**
- ✅ Migration 022: Completed successfully
- ✅ Migration 023: Completed successfully
- ✅ Order numbering: Active and tested (HM-251119-009)
- ✅ Customizations schema: Ready for both formats

All systems are ready for testing! 🚀
