-- ============================================
-- MIGRATION 045: Add Customizations to ALL Menu Items
-- Apply portion-based customizations to all sandwiches and applicable items
-- ============================================

-- This migration ensures that ALL menu items that can have customizations
-- will have the standard ingredient options available

-- ============================================
-- STEP 1: Apply customizations to ALL Breakfast Sandwiches
-- ============================================

DO $$
DECLARE
  v_item RECORD;
  v_count INTEGER;
BEGIN
  -- Apply to all breakfast sandwiches (excluding hash browns, french toast sticks, etc.)
  FOR v_item IN
    SELECT id, name
    FROM menu_items
    WHERE category_id = 1 -- Breakfast
    AND name IN (
      'Two Eggs with Cheese',
      'Two Eggs with Choice of Meat & Cheese',
      'Three Egg Omelette with Meat & Cheese',
      'Bacon, Egg & Cheese on a Bagel',
      'Bacon, Egg & Cheese w/ Hash Brown on a Fresh Croissant',
      'Shack Attack AKA Jimmy',
      'Grilled Cheese',
      'BLT',
      'Western Omelet'
    )
  LOOP
    v_count := add_standard_sandwich_customizations(v_item.id, false, false);
    RAISE NOTICE 'Added % customizations to "%"', v_count, v_item.name;
  END LOOP;
END $$;

-- ============================================
-- STEP 2: Apply customizations to ALL Signature Sandwiches
-- ============================================

DO $$
DECLARE
  v_item RECORD;
  v_count INTEGER;
BEGIN
  -- Apply to ALL signature sandwiches
  FOR v_item IN
    SELECT id, name
    FROM menu_items
    WHERE category_id = 2 -- Signature Sandwiches
  LOOP
    -- Use chipotle mayo for specific items, Russian dressing for others
    CASE
      WHEN v_item.name IN ('Cluck''en Russian®', 'Eggplanter', 'All American', 'Yankee Peddler') THEN
        v_count := add_standard_sandwich_customizations(v_item.id, true, false);
      WHEN v_item.name IN ('Cluck''en Club®', 'Healthy Bird', 'Turkey Dijon') THEN
        v_count := add_standard_sandwich_customizations(v_item.id, false, true);
      ELSE
        v_count := add_standard_sandwich_customizations(v_item.id, false, false);
    END CASE;

    RAISE NOTICE 'Added % customizations to "%"', v_count, v_item.name;
  END LOOP;
END $$;

-- ============================================
-- STEP 3: Apply customizations to ALL Classic Sandwiches
-- ============================================

DO $$
DECLARE
  v_item RECORD;
  v_count INTEGER;
BEGIN
  -- Apply to ALL classic sandwiches (excluding just sides/soups)
  FOR v_item IN
    SELECT id, name
    FROM menu_items
    WHERE category_id = 3 -- Classic Sandwiches
  LOOP
    CASE
      WHEN v_item.name = 'All American' THEN
        v_count := add_standard_sandwich_customizations(v_item.id, true, false);
      ELSE
        v_count := add_standard_sandwich_customizations(v_item.id, false, false);
    END CASE;

    RAISE NOTICE 'Added % customizations to "%"', v_count, v_item.name;
  END LOOP;
END $$;

-- ============================================
-- STEP 4: Apply customizations to ALL Burgers
-- ============================================

DO $$
DECLARE
  v_item RECORD;
  v_count INTEGER;
BEGIN
  -- Apply to ALL burgers
  FOR v_item IN
    SELECT id, name
    FROM menu_items
    WHERE category_id = 4 -- Burgers
  LOOP
    v_count := add_standard_sandwich_customizations(v_item.id, false, false);
    RAISE NOTICE 'Added % customizations to "%"', v_count, v_item.name;
  END LOOP;
END $$;

-- ============================================
-- STEP 5: Apply customizations to applicable Munchies items
-- ============================================

DO $$
DECLARE
  v_item RECORD;
  v_count INTEGER;
BEGIN
  -- Apply to sandwich-like munchies (wings, tenders, etc. don't need customizations)
  -- But we can skip this section since munchies don't typically have customizations
  RAISE NOTICE 'Skipping Munchies category - items do not require customizations';
END $$;

-- ============================================
-- VERIFICATION: Show all items with customizations
-- ============================================

SELECT 'Migration 045 Complete!' as status;

-- Show detailed customization count by menu item
SELECT
  mc.name as category,
  mi.name as menu_item,
  COUNT(*) as customization_count,
  string_agg(mic.name, ', ' ORDER BY mic.display_order) as ingredients
FROM menu_items mi
JOIN menu_categories mc ON mi.category_id = mc.id
LEFT JOIN menu_item_customizations mic ON mi.id = mic.menu_item_id AND mic.supports_portions = true
WHERE mi.category_id IN (1, 2, 3, 4) -- Breakfast, Signature, Classic, Burgers
GROUP BY mc.name, mc.id, mi.id, mi.name
ORDER BY mc.id, mi.name;

-- Show summary by category
SELECT
  mc.name as category,
  COUNT(DISTINCT mi.id) as total_menu_items,
  COUNT(DISTINCT CASE WHEN mic.id IS NOT NULL THEN mi.id END) as items_with_customizations,
  COUNT(mic.id) as total_customizations
FROM menu_categories mc
LEFT JOIN menu_items mi ON mc.id = mi.category_id
LEFT JOIN menu_item_customizations mic ON mi.id = mic.menu_item_id AND mic.supports_portions = true
WHERE mc.id IN (1, 2, 3, 4)
GROUP BY mc.name, mc.id
ORDER BY mc.id;

-- Show any items that might be missing customizations
SELECT
  mc.name as category,
  mi.name as menu_item_missing_customizations
FROM menu_items mi
JOIN menu_categories mc ON mi.category_id = mc.id
LEFT JOIN menu_item_customizations mic ON mi.id = mic.menu_item_id
WHERE mi.category_id IN (1, 2, 3, 4)
  AND mic.id IS NULL
ORDER BY mc.id, mi.name;
