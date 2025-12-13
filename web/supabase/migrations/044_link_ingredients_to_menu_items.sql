-- ============================================
-- MIGRATION 044: Link Ingredient Templates to Menu Items
-- Add portion-based customizations to sandwich items
-- ============================================

-- This migration adds ingredient customizations to sandwich menu items
-- using the ingredient templates created in migration 042

-- ============================================
-- STEP 1: Add unique constraint FIRST (required for ON CONFLICT)
-- ============================================

-- Add unique constraint to prevent duplicate customizations (safe - DO NOTHING if exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'menu_item_customizations_unique_name'
  ) THEN
    ALTER TABLE menu_item_customizations
    ADD CONSTRAINT menu_item_customizations_unique_name
    UNIQUE (menu_item_id, name);
    RAISE NOTICE 'Created unique constraint: menu_item_customizations_unique_name';
  ELSE
    RAISE NOTICE 'Constraint already exists: menu_item_customizations_unique_name';
  END IF;
END $$;

-- ============================================
-- STEP 2: Add customizations to "All American" sandwich
-- ============================================

-- Get the menu item ID for "All American"
DO $$
DECLARE
  v_menu_item_id BIGINT;
  v_lettuce_template RECORD;
  v_tomato_template RECORD;
  v_onion_template RECORD;
  v_pickles_template RECORD;
  v_mayo_template RECORD;
  v_mustard_template RECORD;
  v_russian_template RECORD;
  v_cheese_template RECORD;
BEGIN
  -- Get menu item ID
  SELECT id INTO v_menu_item_id FROM menu_items WHERE name = 'All American' LIMIT 1;

  IF v_menu_item_id IS NULL THEN
    RAISE NOTICE 'Menu item "All American" not found';
    RETURN;
  END IF;

  -- Get ingredient templates
  SELECT * INTO v_lettuce_template FROM ingredient_templates WHERE name = 'Lettuce' LIMIT 1;
  SELECT * INTO v_tomato_template FROM ingredient_templates WHERE name = 'Tomato' LIMIT 1;
  SELECT * INTO v_onion_template FROM ingredient_templates WHERE name = 'Onion' LIMIT 1;
  SELECT * INTO v_pickles_template FROM ingredient_templates WHERE name = 'Pickles' LIMIT 1;
  SELECT * INTO v_mayo_template FROM ingredient_templates WHERE name = 'Mayo' LIMIT 1;
  SELECT * INTO v_mustard_template FROM ingredient_templates WHERE name = 'Mustard' LIMIT 1;
  SELECT * INTO v_russian_template FROM ingredient_templates WHERE name = 'Russian Dressing' LIMIT 1;
  SELECT * INTO v_cheese_template FROM ingredient_templates WHERE name = 'Extra Cheese' LIMIT 1;

  -- Insert customizations for vegetables (default: regular)
  INSERT INTO menu_item_customizations (
    menu_item_id, name, type, options, category, supports_portions,
    portion_pricing, default_portion, display_order
  ) VALUES
  (v_menu_item_id, v_lettuce_template.name, 'single', '[]'::jsonb, 'vegetables', true,
   v_lettuce_template.portion_pricing, 'regular', 1),
  (v_menu_item_id, v_tomato_template.name, 'single', '[]'::jsonb, 'vegetables', true,
   v_tomato_template.portion_pricing, 'regular', 2),
  (v_menu_item_id, v_onion_template.name, 'single', '[]'::jsonb, 'vegetables', true,
   v_onion_template.portion_pricing, 'regular', 3),
  (v_menu_item_id, v_pickles_template.name, 'single', '[]'::jsonb, 'vegetables', true,
   v_pickles_template.portion_pricing, 'regular', 4)
  ON CONFLICT (menu_item_id, name) DO NOTHING;

  -- Insert customizations for sauces (default: regular for Russian dressing, none for others)
  INSERT INTO menu_item_customizations (
    menu_item_id, name, type, options, category, supports_portions,
    portion_pricing, default_portion, display_order
  ) VALUES
  (v_menu_item_id, v_mayo_template.name, 'single', '[]'::jsonb, 'sauces', true,
   v_mayo_template.portion_pricing, 'none', 10),
  (v_menu_item_id, v_mustard_template.name, 'single', '[]'::jsonb, 'sauces', true,
   v_mustard_template.portion_pricing, 'none', 11),
  (v_menu_item_id, v_russian_template.name, 'single', '[]'::jsonb, 'sauces', true,
   v_russian_template.portion_pricing, 'regular', 12)
  ON CONFLICT (menu_item_id, name) DO NOTHING;

  -- Insert customizations for premium extras (default: none)
  INSERT INTO menu_item_customizations (
    menu_item_id, name, type, options, category, supports_portions,
    portion_pricing, default_portion, display_order
  ) VALUES
  (v_menu_item_id, v_cheese_template.name, 'single', '[]'::jsonb, 'extras', true,
   v_cheese_template.portion_pricing, 'none', 20)
  ON CONFLICT (menu_item_id, name) DO NOTHING;

  RAISE NOTICE 'Added customizations to "All American" (menu_item_id: %)', v_menu_item_id;
END $$;

-- ============================================
-- STEP 3: Function to bulk add ingredients to a menu item
-- ============================================

CREATE OR REPLACE FUNCTION add_standard_sandwich_customizations(
  p_menu_item_id BIGINT,
  p_include_russian BOOLEAN DEFAULT true,
  p_include_chipotle BOOLEAN DEFAULT false
)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
  v_temp INTEGER;
BEGIN
  -- Add vegetables (all sandwiches)
  INSERT INTO menu_item_customizations (
    menu_item_id, name, type, options, category, supports_portions,
    portion_pricing, default_portion, display_order
  )
  SELECT
    p_menu_item_id,
    name,
    'single',
    '[]'::jsonb,
    category,
    supports_portions,
    portion_pricing,
    default_portion,
    display_order
  FROM ingredient_templates
  WHERE category = 'vegetables' AND is_active = true
  ON CONFLICT (menu_item_id, name) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  -- Add basic sauces
  INSERT INTO menu_item_customizations (
    menu_item_id, name, type, options, category, supports_portions,
    portion_pricing, default_portion, display_order
  )
  SELECT
    p_menu_item_id,
    name,
    'single',
    '[]'::jsonb,
    category,
    supports_portions,
    portion_pricing,
    CASE
      WHEN name = 'Russian Dressing' AND p_include_russian THEN 'regular'
      WHEN name = 'Chipotle Mayo' AND p_include_chipotle THEN 'regular'
      ELSE 'none'
    END as default_portion,
    display_order
  FROM ingredient_templates
  WHERE category = 'sauces' AND is_active = true
  ON CONFLICT (menu_item_id, name) DO NOTHING;

  GET DIAGNOSTICS v_temp = ROW_COUNT;
  v_count := v_count + v_temp;

  -- Add cheese
  INSERT INTO menu_item_customizations (
    menu_item_id, name, type, options, category, supports_portions,
    portion_pricing, default_portion, display_order
  )
  SELECT
    p_menu_item_id,
    name,
    'single',
    '[]'::jsonb,
    category,
    supports_portions,
    portion_pricing,
    'none' as default_portion,
    display_order
  FROM ingredient_templates
  WHERE name = 'Extra Cheese' AND is_active = true
  ON CONFLICT (menu_item_id, name) DO NOTHING;

  GET DIAGNOSTICS v_temp = ROW_COUNT;
  v_count := v_count + v_temp;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STEP 4: Apply to common sandwich items
-- ============================================

DO $$
DECLARE
  v_item RECORD;
  v_count INTEGER;
BEGIN
  -- Apply to signature sandwiches
  FOR v_item IN
    SELECT id, name
    FROM menu_items
    WHERE name IN (
      'American Combo',
      'Chicken Cutlet Sandwich',
      'Turkey Club',
      'BLT Sandwich',
      'Ham & Cheese'
    )
  LOOP
    v_count := add_standard_sandwich_customizations(v_item.id, true, false);
    RAISE NOTICE 'Added % customizations to "%"', v_count, v_item.name;
  END LOOP;
END $$;

-- ============================================
-- Verification
-- ============================================

SELECT 'Migration 044 Complete!' as status;

-- Show customizations added
SELECT
  mi.name as menu_item,
  COUNT(*) as customization_count,
  string_agg(mic.name, ', ' ORDER BY mic.display_order) as ingredients
FROM menu_items mi
JOIN menu_item_customizations mic ON mi.id = mic.menu_item_id
WHERE mic.supports_portions = true
GROUP BY mi.id, mi.name
ORDER BY mi.name;

-- Show summary by category
SELECT
  category,
  COUNT(*) as total_customizations,
  COUNT(DISTINCT menu_item_id) as menu_items_with_customizations
FROM menu_item_customizations
WHERE supports_portions = true
GROUP BY category
ORDER BY category;
