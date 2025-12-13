# Migration 045: Add Customizations to All Menu Items

## Overview
This migration adds portion-based customizations (lettuce, tomato, onion, pickles, mayo, mustard, etc.) to ALL applicable menu items across all categories.

## Why This Is Needed
Currently, only a few menu items have customization options. This migration ensures that ALL sandwiches, burgers, and breakfast items have the same customization capabilities as the "All American" sandwich.

## What Will Be Added
Each applicable menu item will get:
- **Vegetables**: Lettuce, Tomato, Onion, Pickles (default: regular portion, free)
- **Sauces**: Mayo, Mustard, Russian Dressing (default: varies by item, free)
- **Extras**: Extra Cheese (default: none, charged extra)

## How to Run

### Option 1: Via Supabase Dashboard (Recommended)

1. Go to your Supabase project: https://supabase.com/dashboard/project/jwcuebbhkwwilqfblecq
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the entire contents of `supabase/migrations/045_add_customizations_to_all_items.sql`
5. Paste into the SQL Editor
6. Click **Run** (or press Cmd/Ctrl + Enter)
7. Review the output to confirm success

### Option 2: Via Command Line (If you have psql installed)

```bash
psql "postgresql://postgres.jwcuebbhkwwilqfblecq:CameronConnect2024!@aws-0-us-east-1.pooler.supabase.com:6543/postgres" \
  -f supabase/migrations/045_add_customizations_to_all_items.sql
```

## Verification

After running the migration, you should see output showing:

1. **Items processed**: Each menu item that received customizations
2. **Customization count**: How many customizations were added to each item
3. **Summary by category**: Total items and customizations per category

### Expected Results

- **Breakfast**: ~9 items with customizations
- **Signature Sandwiches**: ~24 items with customizations
- **Classic Sandwiches**: ~12 items with customizations
- **Burgers**: ~3 items with customizations

## Testing

After running the migration, test by:

1. Go to http://localhost:8080/order
2. Click on any sandwich or burger item
3. The customization modal should now show portion controls for:
   - Lettuce, Tomato, Onion, Pickles
   - Mayo, Mustard, Russian Dressing (or other sauces)
   - Extra Cheese

4. Each ingredient should have portion options: None, Light, Regular, Extra

## What Items Get Customizations

### Breakfast Items (with customizations)
- Two Eggs with Cheese
- Two Eggs with Choice of Meat & Cheese
- Three Egg Omelette with Meat & Cheese
- Bacon, Egg & Cheese on a Bagel
- Bacon, Egg & Cheese w/ Hash Brown on a Fresh Croissant
- Shack Attack AKA Jimmy
- Grilled Cheese
- BLT
- Western Omelet

### ALL Signature Sandwiches (24 items)
- All items in the Signature Sandwiches category

### ALL Classic Sandwiches (12 items)
- All items in the Classic Sandwiches category

### ALL Burgers (3 items)
- All items in the Burgers category

### Munchies (NO customizations)
- Wings, fries, and other sides do not need customizations

## Rollback (if needed)

If you need to remove these customizations:

```sql
-- Remove all customizations added by this migration
DELETE FROM menu_item_customizations
WHERE menu_item_id IN (
  SELECT id FROM menu_items
  WHERE category_id IN (1, 2, 3, 4)
);
```

## Notes

- This migration uses the `add_standard_sandwich_customizations()` function created in Migration 044
- The migration is safe to run multiple times (uses `ON CONFLICT DO NOTHING`)
- Existing customizations will not be affected or duplicated
