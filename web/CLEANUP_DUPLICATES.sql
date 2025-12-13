-- ============================================
-- CLEANUP: Remove duplicate ingredients and keep only unique ones
-- ============================================

-- Delete all existing ingredients
DELETE FROM ingredient_templates;

-- Insert fresh set of 13 ingredients
INSERT INTO ingredient_templates (name, category, portion_pricing, display_order, supports_portions, default_portion, is_active) VALUES
-- Fresh Vegetables (free) - 4 items
('Lettuce', 'vegetables', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 1, true, 'regular', true),
('Tomato', 'vegetables', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 2, true, 'regular', true),
('Onion', 'vegetables', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 3, true, 'regular', true),
('Pickles', 'vegetables', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 4, true, 'regular', true),

-- Signature Sauces (free) - 6 items
('Chipotle Mayo', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 10, true, 'regular', true),
('Mayo', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 11, true, 'regular', true),
('Russian Dressing', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 12, true, 'regular', true),
('Ketchup', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 13, true, 'regular', true),
('Mustard', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 14, true, 'regular', true),
('Hot Sauce', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 15, true, 'regular', true),

-- Premium Extras (charged) - 3 items
('Extra Cheese', 'extras', '{"none": 0, "light": 0.75, "regular": 1.00, "extra": 1.50}'::jsonb, 20, true, 'regular', true),
('Bacon', 'extras', '{"none": 0, "light": 1.00, "regular": 1.50, "extra": 2.00}'::jsonb, 21, true, 'regular', true),
('Avocado', 'extras', '{"none": 0, "light": 1.50, "regular": 2.00, "extra": 2.50}'::jsonb, 22, true, 'regular', true);

-- Verify clean state
SELECT
  'Cleanup complete!' as status,
  COUNT(*) as total_ingredients,
  COUNT(*) FILTER (WHERE category = 'vegetables') as vegetables,
  COUNT(*) FILTER (WHERE category = 'sauces') as sauces,
  COUNT(*) FILTER (WHERE category = 'extras') as extras
FROM ingredient_templates;
