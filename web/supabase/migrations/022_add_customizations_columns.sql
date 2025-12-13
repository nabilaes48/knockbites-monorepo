-- ============================================
-- ADD iOS-COMPATIBLE CUSTOMIZATION COLUMNS
-- Match the iOS app data format for order items
-- ============================================

-- Rename existing customizations column to selected_options
ALTER TABLE order_items
RENAME COLUMN customizations TO selected_options;

-- Add new customizations column as TEXT array for human-readable display
ALTER TABLE order_items
ADD COLUMN customizations TEXT[];

-- Add comment explaining the difference
COMMENT ON COLUMN order_items.selected_options IS 'Raw customization data: {"group_id": ["option_id1", "option_id2"]}';
COMMENT ON COLUMN order_items.customizations IS 'Human-readable customizations: ["Cheese: Extra Cheese", "Size: Large"]';

-- Update existing orders to have empty customizations array
UPDATE order_items
SET customizations = ARRAY[]::TEXT[]
WHERE customizations IS NULL;

-- Verify the schema
SELECT
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'order_items'
AND column_name IN ('selected_options', 'customizations', 'notes')
ORDER BY ordinal_position;
