# Migration 044: Fix Portion-Based Customizations

## Problem
The "All American" sandwich (and other sandwiches) show "No customization options available" because migration 042 created ingredient templates but didn't link them to actual menu items.

## Solution
Migration 044 links ingredient templates to menu items, specifically:
- **All American** sandwich
- **American Combo**
- **Chicken Cutlet Sandwich**
- **Turkey Club**
- **BLT Sandwich**
- **Ham & Cheese**

## How to Run

### Step 1: Open Supabase SQL Editor
1. Go to https://supabase.com/dashboard
2. Select your project: `camerons-connect`
3. Navigate to **SQL Editor** in the left sidebar

### Step 2: Run Migration 044
1. Click **New Query**
2. Copy the contents of `supabase/migrations/044_link_ingredients_to_menu_items.sql`
3. Paste into the SQL editor
4. Click **Run** or press `Ctrl+Enter` / `Cmd+Enter`

### Step 3: Verify Results
You should see output showing:
```
Migration 044 Complete!

menu_item                  | customization_count | ingredients
---------------------------+--------------------+---------------------------------------------
All American               | 9                   | Lettuce, Tomato, Onion, Pickles, Mayo, ...
American Combo             | 9                   | Lettuce, Tomato, Onion, Pickles, Mayo, ...
...
```

### Step 4: Test on Website
1. Go to http://localhost:8080/order (or your production URL)
2. Click on "All American" sandwich
3. You should now see:
   - 🥗 **Fresh Vegetables** section (Lettuce, Tomato, Onion, Pickles)
   - 🥫 **Signature Sauces** section (Mayo, Mustard, Russian Dressing)
   - ✨ **Premium Extras** section (Extra Cheese)
4. Each ingredient should have portion options: **None ○**, **Light ◔**, **Regular ◑**, **Extra ●**

## What This Migration Does

1. **Links Templates to Menu Items**: Takes ingredient templates from migration 042 and creates `menu_item_customizations` records for sandwich items

2. **Sets Smart Defaults**:
   - Vegetables: Default to "Regular" (Lettuce, Tomato, Onion, Pickles)
   - Russian Dressing: Default to "Regular" (comes on All American)
   - Other sauces: Default to "None" (customer can add)
   - Extra Cheese: Default to "None" (premium add-on)

3. **Creates Helper Function**: `add_standard_sandwich_customizations()` can be used to quickly add customizations to other sandwiches

4. **Prevents Duplicates**: Adds unique constraint to prevent duplicate customizations

## Add Customizations to Other Items

To add customizations to another sandwich (e.g., "Beef Eater"), run:

```sql
-- Get the menu item ID
SELECT id, name FROM menu_items WHERE name = 'Beef Eater';

-- Add standard customizations (Russian dressing default)
SELECT add_standard_sandwich_customizations(
  123,  -- Replace with actual menu_item_id
  true,  -- Include Russian dressing as default
  false  -- Don't include Chipotle mayo as default
);

-- Or for a spicy sandwich with Chipotle mayo:
SELECT add_standard_sandwich_customizations(
  124,  -- Replace with actual menu_item_id
  false,  -- Don't include Russian dressing
  true    -- Include Chipotle mayo as default
);
```

## Troubleshooting

### Issue: "relation 'ingredient_templates' does not exist"
**Solution**: Run migration 042 first:
```bash
# Migration 042 creates the ingredient_templates table
cat supabase/migrations/042_portion_based_customizations_v2.sql
```

### Issue: Customizations still not showing
**Checklist**:
1. ✅ Ran migration 042 (creates ingredient_templates)
2. ✅ Ran migration 044 (links templates to menu items)
3. ✅ Cleared browser cache and refreshed page
4. ✅ Check Supabase logs for any RLS policy errors
5. ✅ Verify data:
   ```sql
   SELECT * FROM menu_item_customizations
   WHERE menu_item_id = (SELECT id FROM menu_items WHERE name = 'All American' LIMIT 1);
   ```

### Issue: Wrong default portions
**Solution**: Update the default_portion:
```sql
UPDATE menu_item_customizations
SET default_portion = 'regular'
WHERE menu_item_id = (SELECT id FROM menu_items WHERE name = 'All American' LIMIT 1)
  AND name = 'Lettuce';
```

## Files Modified
- ✅ `supabase/migrations/044_link_ingredients_to_menu_items.sql` - New migration
- ✅ `RUN_MIGRATION_044.md` - This guide

## Next Steps
After running this migration, you can:
1. Test the customization UI on all sandwich items
2. Add customizations to burger items using the helper function
3. Adjust default portions based on customer feedback
4. Add more ingredient templates (Bacon, Avocado) as needed
