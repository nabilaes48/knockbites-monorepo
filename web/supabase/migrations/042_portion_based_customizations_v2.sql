-- ============================================
-- MIGRATION 042 V2: Portion-Based Customizations (Safe Re-run)
-- Modern ingredient system with Light/Regular/Extra portions
-- ============================================

-- Add portion-related columns to menu_item_customizations (safe - IF NOT EXISTS)
ALTER TABLE menu_item_customizations
ADD COLUMN IF NOT EXISTS supports_portions BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS portion_pricing JSONB DEFAULT '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb,
ADD COLUMN IF NOT EXISTS default_portion TEXT DEFAULT 'regular',
ADD COLUMN IF NOT EXISTS category TEXT;

-- Create ingredient templates table (safe - IF NOT EXISTS)
CREATE TABLE IF NOT EXISTS ingredient_templates (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  supports_portions BOOLEAN DEFAULT true,
  portion_pricing JSONB DEFAULT '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb,
  default_portion TEXT DEFAULT 'regular',
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS (safe - no error if already enabled)
ALTER TABLE ingredient_templates ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist, then recreate
DROP POLICY IF EXISTS "Active templates viewable by all" ON ingredient_templates;
DROP POLICY IF EXISTS "Staff can manage templates" ON ingredient_templates;

-- Public can view active templates
CREATE POLICY "Active templates viewable by all" ON ingredient_templates
  FOR SELECT USING (is_active = true);

-- Staff can manage templates
CREATE POLICY "Staff can manage templates" ON ingredient_templates
  FOR ALL
  TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager')
  );

-- Insert default ingredient templates (ON CONFLICT DO NOTHING prevents duplicates)
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

-- Create indexes (safe - IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS ingredient_templates_category_idx ON ingredient_templates(category);
CREATE INDEX IF NOT EXISTS ingredient_templates_active_idx ON ingredient_templates(is_active);

-- Add comments
COMMENT ON TABLE ingredient_templates IS 'Reusable ingredient templates with portion-based pricing (None/Light/Regular/Extra)';
COMMENT ON COLUMN menu_item_customizations.supports_portions IS 'If true, this customization uses portion levels (None/Light/Regular/Extra)';
COMMENT ON COLUMN menu_item_customizations.portion_pricing IS 'Price for each portion level: {"none": 0, "light": 0, "regular": 0, "extra": 0.50}';

-- Verify setup
SELECT 'Migration completed successfully!' as status;
SELECT COUNT(*) as ingredient_count FROM ingredient_templates WHERE is_active = true;
