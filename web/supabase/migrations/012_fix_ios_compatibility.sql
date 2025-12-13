-- ============================================
-- FIX iOS APP COMPATIBILITY
-- 1. Ensure only Highland Mills store exists
-- 2. Create categories view for iOS app
-- ============================================

-- ============================================
-- PART 1: FIX STORES - Only Highland Mills
-- ============================================

-- Delete all existing stores
DELETE FROM stores;

-- Insert ONLY Highland Mills
INSERT INTO stores (
  id, name, address, city, state, zip, phone, hours, is_open,
  latitude, longitude, store_type
) VALUES (
  1,
  'Highland Mills Snack Shop Inc',
  '634 NY-32',
  'Highland Mills',
  'NY',
  '10930',
  '(845) 928-2883',
  'Open 24/7',
  true,
  41.3501,
  -74.1243,
  'deli'
);

-- Reset sequence
SELECT setval('stores_id_seq', (SELECT MAX(id) FROM stores));

-- ============================================
-- PART 2: CREATE CATEGORIES VIEW FOR iOS APP
-- ============================================

-- Drop existing view if it exists
DROP VIEW IF EXISTS categories CASCADE;

-- Create view that iOS app expects (categories instead of menu_categories)
CREATE VIEW categories AS
SELECT
  id,
  name,
  description,
  display_order,
  display_order as sort_order,  -- iOS app expects 'sort_order'
  is_active,
  created_at
FROM menu_categories;

-- Grant access
GRANT SELECT ON categories TO anon;
GRANT SELECT ON categories TO authenticated;

-- ============================================
-- PART 3: CREATE MENU_ITEMS_VIEW WITH PRICE
-- ============================================

-- Drop existing view if it exists
DROP VIEW IF EXISTS menu_items_view CASCADE;

CREATE VIEW menu_items_view AS
SELECT
  id,
  name,
  description,
  base_price as price,  -- iOS app expects 'price'
  base_price,           -- Keep for web app
  category_id,
  image_url,
  tags,
  is_featured,
  is_available,
  preparation_time,
  created_at
FROM menu_items;

-- Grant access
GRANT SELECT ON menu_items_view TO anon;
GRANT SELECT ON menu_items_view TO authenticated;

-- ============================================
-- VERIFY
-- ============================================

-- Check stores (should be only 1)
SELECT COUNT(*) as store_count,
       string_agg(name, ', ') as store_names
FROM stores;

-- Check categories view
SELECT COUNT(*) as category_count
FROM categories;

-- Check menu items view
SELECT COUNT(*) as item_count
FROM menu_items_view;
