-- ============================================
-- Verify Migration 044 Results
-- ============================================

-- Check which menu items have portion-based customizations
SELECT
  mi.id,
  mi.name as menu_item,
  COUNT(*) as customization_count,
  string_agg(mic.name, ', ' ORDER BY mic.display_order) as ingredients
FROM menu_items mi
JOIN menu_item_customizations mic ON mi.id = mic.menu_item_id
WHERE mic.supports_portions = true
GROUP BY mi.id, mi.name
ORDER BY mi.name;

-- Show details of All American customizations
SELECT
  mic.id,
  mic.name as ingredient,
  mic.category,
  mic.default_portion,
  mic.portion_pricing
FROM menu_item_customizations mic
JOIN menu_items mi ON mic.menu_item_id = mi.id
WHERE mi.name = 'All American'
  AND mic.supports_portions = true
ORDER BY mic.display_order;
