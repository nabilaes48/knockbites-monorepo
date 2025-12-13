-- ============================================
-- ALLOW ANONYMOUS ACCESS TO MENU DATA
-- Enable customers to browse menu without login
-- ============================================

-- Allow anonymous users to read menu categories
DROP POLICY IF EXISTS "Allow anonymous read menu_categories" ON menu_categories;
CREATE POLICY "Allow anonymous read menu_categories"
ON menu_categories FOR SELECT
TO anon
USING (is_active = true);

-- Allow anonymous users to read menu items
DROP POLICY IF EXISTS "Allow anonymous read menu_items" ON menu_items;
CREATE POLICY "Allow anonymous read menu_items"
ON menu_items FOR SELECT
TO anon
USING (is_available = true);

-- Verify policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('menu_categories', 'menu_items')
ORDER BY tablename, policyname;
