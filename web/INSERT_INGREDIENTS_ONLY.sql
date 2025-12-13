-- ============================================
-- SIMPLE FIX: Just insert the ingredient templates
-- (Table and policies already exist, so we just need the data)
-- ============================================

-- Insert default ingredient templates
INSERT INTO ingredient_templates (name, category, portion_pricing, display_order) VALUES
-- Fresh Vegetables (free)
('Lettuce', 'vegetables', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 1),
('Tomato', 'vegetables', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 2),
('Onion', 'vegetables', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 3),
('Pickles', 'vegetables', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 4),

-- Signature Sauces (free)
('Chipotle Mayo', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 10),
('Mayo', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 11),
('Russian Dressing', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 12),
('Ketchup', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 13),
('Mustard', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 14),
('Hot Sauce', 'sauces', '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb, 15),

-- Premium Extras (charged)
('Extra Cheese', 'extras', '{"none": 0, "light": 0.75, "regular": 1.00, "extra": 1.50}'::jsonb, 20),
('Bacon', 'extras', '{"none": 0, "light": 1.00, "regular": 1.50, "extra": 2.00}'::jsonb, 21),
('Avocado', 'extras', '{"none": 0, "light": 1.50, "regular": 2.00, "extra": 2.50}'::jsonb, 22)
ON CONFLICT DO NOTHING;

-- Verify
SELECT 'Ingredients inserted successfully!' as status;
SELECT COUNT(*) as total_ingredients,
       COUNT(*) FILTER (WHERE category = 'vegetables') as vegetables,
       COUNT(*) FILTER (WHERE category = 'sauces') as sauces,
       COUNT(*) FILTER (WHERE category = 'extras') as extras
FROM ingredient_templates;
