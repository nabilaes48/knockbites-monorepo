-- Check signature sandwich image URLs
SELECT name, image_url
FROM menu_items
WHERE category_id = 2
ORDER BY name
LIMIT 15;
