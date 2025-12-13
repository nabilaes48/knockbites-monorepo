-- ============================================
-- USE PLACEHOLDER IMAGES TEMPORARILY
-- Update all menu items to use placeholder until real photos are uploaded
-- ============================================

UPDATE menu_items
SET image_url = '/images/menu/placeholder.svg'
WHERE image_url LIKE '/images/menu/page-%';

-- Verify update
SELECT
  category_id,
  COUNT(*) as items_updated
FROM menu_items
WHERE image_url = '/images/menu/placeholder.svg'
GROUP BY category_id
ORDER BY category_id;
