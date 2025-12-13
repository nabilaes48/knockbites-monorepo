-- ============================================
-- COMPREHENSIVE IMAGE CHECK
-- ============================================

-- Check ALL categories
SELECT
  c.name as category,
  COUNT(*) as total_items,
  COUNT(CASE WHEN m.image_url LIKE '/images/menu/items/%' THEN 1 END) as uploaded_photos,
  COUNT(CASE WHEN m.image_url LIKE 'https://images.unsplash%' THEN 1 END) as stock_photos,
  string_agg(DISTINCT
    CASE
      WHEN m.image_url LIKE '/images/menu/items/%' THEN m.name
    END, ', ') as items_with_uploaded_photos
FROM menu_items m
JOIN menu_categories c ON m.category_id = c.id
GROUP BY c.name, c.display_order
ORDER BY c.display_order;

-- Check specific signature sandwiches
SELECT name, image_url
FROM menu_items
WHERE category_id = 2
AND name IN ('Cluck''en Russian®', 'Chopped Cheese', 'Cam''s Spicy Chicken', 'Buffalo Blu')
ORDER BY name;

-- Check classic sandwiches
SELECT name, image_url
FROM menu_items
WHERE category_id = 3
AND name IN ('Chicken Cutlet', 'Reuben', 'Philly Cheesesteak')
ORDER BY name;
