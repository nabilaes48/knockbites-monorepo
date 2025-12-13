-- ============================================
-- CREATE MENU VIEW WITH PRICE FIELD
-- Provides backwards compatibility for iOS app expecting "price"
-- ============================================

-- Create a view that maps base_price to price
CREATE OR REPLACE VIEW menu_items_view AS
SELECT
  id,
  name,
  description,
  base_price as price,  -- Alias for iOS app compatibility
  base_price,           -- Keep original for web app
  category_id,
  image_url,
  tags,
  is_featured,
  is_available,
  preparation_time,
  created_at,
  updated_at
FROM menu_items;

-- Grant access to anonymous users (for customer apps)
GRANT SELECT ON menu_items_view TO anon;
GRANT SELECT ON menu_items_view TO authenticated;

-- Add RLS policy
ALTER VIEW menu_items_view SET (security_invoker = true);

-- Verify view
SELECT id, name, price, base_price
FROM menu_items_view
LIMIT 5;
