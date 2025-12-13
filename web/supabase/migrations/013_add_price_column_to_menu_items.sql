-- ============================================
-- ADD PRICE COLUMN TO MENU_ITEMS TABLE
-- Makes iOS app work without code changes
-- ============================================

-- Add price as a generated column (always equals base_price)
ALTER TABLE menu_items
ADD COLUMN IF NOT EXISTS price DECIMAL(10,2)
GENERATED ALWAYS AS (base_price) STORED;

-- Verify
SELECT id, name, base_price, price
FROM menu_items
LIMIT 5;
