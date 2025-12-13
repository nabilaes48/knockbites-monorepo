-- =====================================================
-- Add Customer Columns to Existing user_profiles Table
-- Version: 3.1
-- Date: 2025-11-19
-- Note: user_profiles already exists, just add new columns
-- =====================================================

-- =====================================================
-- STEP 1: Drop old tables if they exist
-- =====================================================
DROP TABLE IF EXISTS user_favorites CASCADE;
DROP TABLE IF EXISTS user_addresses CASCADE;
DROP TABLE IF EXISTS customer_profiles CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS create_customer_profile() CASCADE;
DROP FUNCTION IF EXISTS update_customer_updated_at() CASCADE;
DROP FUNCTION IF EXISTS ensure_single_default_address() CASCADE;
DROP FUNCTION IF EXISTS toggle_favorite(UUID, INT) CASCADE;
DROP FUNCTION IF EXISTS get_user_favorites(UUID) CASCADE;

-- =====================================================
-- STEP 2: Add new columns to existing user_profiles table
-- =====================================================

-- Add dietary preferences columns
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS dietary_preferences JSONB DEFAULT '[]'::jsonb;

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS allergens JSONB DEFAULT '[]'::jsonb;

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS spicy_tolerance VARCHAR(20) DEFAULT 'mild';

-- Add notification preference columns
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS email_notifications BOOLEAN DEFAULT TRUE;

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS push_notifications BOOLEAN DEFAULT TRUE;

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS sms_notifications BOOLEAN DEFAULT FALSE;

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS marketing_emails BOOLEAN DEFAULT FALSE;

-- Add app preference columns
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS default_store_id INT REFERENCES stores(id) ON DELETE SET NULL;

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS preferred_order_type VARCHAR(20) DEFAULT 'pickup';

-- Create index for default_store_id
CREATE INDEX IF NOT EXISTS idx_user_profiles_default_store ON user_profiles(default_store_id);

-- =====================================================
-- STEP 3: Create user_favorites table
-- =====================================================
CREATE TABLE user_favorites (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    menu_item_id INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, menu_item_id)
);

CREATE INDEX idx_user_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_item ON user_favorites(menu_item_id);

-- =====================================================
-- STEP 4: Create user_addresses table
-- =====================================================
CREATE TABLE user_addresses (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    label VARCHAR(50),
    street_address VARCHAR(255) NOT NULL,
    apartment VARCHAR(50),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(20) NOT NULL,
    phone_number VARCHAR(50),
    delivery_instructions TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_user_addresses_user ON user_addresses(user_id);
CREATE INDEX idx_user_addresses_default ON user_addresses(user_id, is_default);

-- =====================================================
-- STEP 5: Enable Row Level Security
-- =====================================================
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;

-- user_profiles RLS should already be enabled

-- =====================================================
-- STEP 6: Create RLS Policies
-- =====================================================

-- Favorites policies
CREATE POLICY "Users can view their own favorites"
ON user_favorites FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own favorites"
ON user_favorites FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own favorites"
ON user_favorites FOR DELETE
USING (auth.uid() = user_id);

-- Addresses policies
CREATE POLICY "Users can view their own addresses"
ON user_addresses FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own addresses"
ON user_addresses FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own addresses"
ON user_addresses FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own addresses"
ON user_addresses FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- STEP 7: Create triggers
-- =====================================================

-- Auto-update updated_at for user_addresses
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_addresses_updated_at
BEFORE UPDATE ON user_addresses
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Ensure single default address
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = TRUE THEN
        UPDATE user_addresses
        SET is_default = FALSE
        WHERE user_id = NEW.user_id
        AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_single_default_address_trigger
BEFORE INSERT OR UPDATE ON user_addresses
FOR EACH ROW
WHEN (NEW.is_default = TRUE)
EXECUTE FUNCTION ensure_single_default_address();

-- =====================================================
-- STEP 8: Create helper functions
-- =====================================================

-- Toggle favorite
CREATE OR REPLACE FUNCTION toggle_favorite(p_user_id UUID, p_menu_item_id INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM user_favorites
        WHERE user_id = p_user_id AND menu_item_id = p_menu_item_id
    ) INTO v_exists;

    IF v_exists THEN
        DELETE FROM user_favorites
        WHERE user_id = p_user_id AND menu_item_id = p_menu_item_id;
        RETURN FALSE;
    ELSE
        INSERT INTO user_favorites (user_id, menu_item_id)
        VALUES (p_user_id, p_menu_item_id);
        RETURN TRUE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user favorites
CREATE OR REPLACE FUNCTION get_user_favorites(p_user_id UUID)
RETURNS TABLE (
    menu_item_id INT,
    favorited_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        uf.menu_item_id,
        uf.created_at
    FROM user_favorites uf
    WHERE uf.user_id = p_user_id
    ORDER BY uf.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 9: Grant permissions
-- =====================================================
GRANT SELECT, INSERT, DELETE ON user_favorites TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_addresses TO authenticated;

GRANT USAGE ON SEQUENCE user_favorites_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE user_addresses_id_seq TO authenticated;

GRANT EXECUTE ON FUNCTION get_user_favorites(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_favorite(UUID, INT) TO authenticated;

-- =====================================================
-- SUCCESS! Migration complete.
--
-- Modified:
-- ✅ user_profiles - Added dietary preferences, notifications, default_store_id
--
-- Created:
-- ✅ user_favorites - Store favorite menu items
-- ✅ user_addresses - Store delivery addresses
-- =====================================================
