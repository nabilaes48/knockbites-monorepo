-- ============================================
-- CHECK CURRENT IMAGE URLs IN DATABASE
-- ============================================

SELECT
  c.name as category,
  COUNT(*) as total_items,
  COUNT(CASE WHEN image_url LIKE '/images/menu/items/%' THEN 1 END) as uploaded_photos,
  COUNT(CASE WHEN image_url LIKE 'https://images.unsplash%' THEN 1 END) as stock_photos,
  COUNT(CASE WHEN image_url LIKE '/images/menu/page-%' THEN 1 END) as old_pdf_pages,
  COUNT(CASE WHEN image_url LIKE '%placeholder%' THEN 1 END) as placeholders
FROM menu_items m
JOIN menu_categories c ON m.category_id = c.id
GROUP BY c.name, c.display_order
ORDER BY c.display_order;

-- Show sample image URLs
SELECT name, image_url
FROM menu_items
ORDER BY id
LIMIT 10;
