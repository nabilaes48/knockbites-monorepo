-- Migration: Fix Duplicate Ingredient Templates
-- This migration removes duplicate entries from ingredient_templates table
-- and adds a unique constraint to prevent future duplicates

-- Step 1: Create a temp table with unique ingredient templates (keeping the lowest ID for each name/category combination)
CREATE TEMP TABLE unique_templates AS
SELECT DISTINCT ON (name, category) *
FROM ingredient_templates
ORDER BY name, category, id;

-- Step 2: Delete all from ingredient_templates
DELETE FROM ingredient_templates;

-- Step 3: Re-insert unique records
INSERT INTO ingredient_templates
SELECT * FROM unique_templates;

-- Step 4: Drop temp table
DROP TABLE unique_templates;

-- Step 5: Add unique constraint to prevent future duplicates
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'ingredient_templates_name_category_unique'
    ) THEN
        ALTER TABLE ingredient_templates
        ADD CONSTRAINT ingredient_templates_name_category_unique
        UNIQUE (name, category);
    END IF;
END $$;

-- Log the cleanup
DO $$
DECLARE
    template_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO template_count FROM ingredient_templates;
    RAISE NOTICE 'Ingredient templates cleaned up. Total unique templates: %', template_count;
END $$;
