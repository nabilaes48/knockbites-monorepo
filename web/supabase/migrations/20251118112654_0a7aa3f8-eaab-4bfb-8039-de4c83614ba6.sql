-- Fix auth.users schema by ensuring all required columns exist with proper defaults
-- This addresses the "email_change" NULL conversion error

-- Add missing columns to auth.users if they don't exist
DO $$ 
BEGIN
    -- Add email_change column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'auth' 
        AND table_name = 'users' 
        AND column_name = 'email_change'
    ) THEN
        ALTER TABLE auth.users ADD COLUMN email_change text DEFAULT ''::text;
    END IF;

    -- Add email_change_token_new column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'auth' 
        AND table_name = 'users' 
        AND column_name = 'email_change_token_new'
    ) THEN
        ALTER TABLE auth.users ADD COLUMN email_change_token_new text DEFAULT ''::text;
    END IF;

    -- Add email_change_token_current column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'auth' 
        AND table_name = 'users' 
        AND column_name = 'email_change_token_current'
    ) THEN
        ALTER TABLE auth.users ADD COLUMN email_change_token_current text DEFAULT ''::text;
    END IF;
END $$;

-- Update any NULL values in these columns to empty strings
UPDATE auth.users 
SET 
    email_change = COALESCE(email_change, ''::text),
    email_change_token_new = COALESCE(email_change_token_new, ''::text),
    email_change_token_current = COALESCE(email_change_token_current, ''::text)
WHERE 
    email_change IS NULL 
    OR email_change_token_new IS NULL 
    OR email_change_token_current IS NULL;