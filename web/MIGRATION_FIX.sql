-- ============================================
-- STEP 1: Clean up existing policies (run this first)
-- ============================================
DROP POLICY IF EXISTS "Active templates viewable by all" ON ingredient_templates;
DROP POLICY IF EXISTS "Staff can manage templates" ON ingredient_templates;
