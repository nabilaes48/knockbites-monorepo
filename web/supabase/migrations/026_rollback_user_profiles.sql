-- =====================================================
-- Rollback Customer Columns from user_profiles Table
-- Version: 4.0
-- Date: 2025-11-19
-- Purpose: Remove customer-related columns/tables added to business system
-- Note: This cleans up the 002_ADD_CUSTOMER_COLUMNS.sql migration
-- =====================================================

-- =====================================================
-- STEP 1: Drop tables created for customers (wrong location)
-- =====================================================
DROP TABLE IF EXISTS user_favorites CASCADE;
DROP TABLE IF EXISTS user_addresses CASCADE;

-- =====================================================
-- STEP 2: Drop functions
-- =====================================================
DROP FUNCTION IF EXISTS toggle_favorite(UUID, INT) CASCADE;
DROP FUNCTION IF EXISTS get_user_favorites(UUID) CASCADE;
DROP FUNCTION IF EXISTS ensure_single_default_address() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- =====================================================
-- STEP 3: Remove customer columns from user_profiles
-- =====================================================

-- Remove dietary preferences columns
ALTER TABLE user_profiles
DROP COLUMN IF EXISTS dietary_preferences CASCADE;

ALTER TABLE user_profiles
DROP COLUMN IF EXISTS allergens CASCADE;

ALTER TABLE user_profiles
DROP COLUMN IF EXISTS spicy_tolerance CASCADE;

-- Remove notification preference columns
ALTER TABLE user_profiles
DROP COLUMN IF EXISTS email_notifications CASCADE;

ALTER TABLE user_profiles
DROP COLUMN IF EXISTS push_notifications CASCADE;

ALTER TABLE user_profiles
DROP COLUMN IF EXISTS sms_notifications CASCADE;

ALTER TABLE user_profiles
DROP COLUMN IF EXISTS marketing_emails CASCADE;

-- Remove app preference columns
ALTER TABLE user_profiles
DROP COLUMN IF EXISTS default_store_id CASCADE;

ALTER TABLE user_profiles
DROP COLUMN IF EXISTS preferred_order_type CASCADE;

-- Drop index (if it exists)
DROP INDEX IF EXISTS idx_user_profiles_default_store;

-- =====================================================
-- SUCCESS! Rollback complete.
--
-- Removed:
-- ❌ user_favorites table (moved to customer_favorites)
-- ❌ user_addresses table (moved to customer_addresses)
-- ❌ Customer columns from user_profiles
--
-- user_profiles table is now clean and only for business users!
--
-- Next: Run 003_CUSTOMERS_FIXED.sql to set up proper customer tables
-- =====================================================
