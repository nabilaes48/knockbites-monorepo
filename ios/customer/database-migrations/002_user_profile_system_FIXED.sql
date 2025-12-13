-- =====================================================
-- User Profile System Migration (FIXED)
-- Version: 2.1
-- Date: 2025-11-19
-- Description: Complete user profile management for customer app
--              Includes: favorites, addresses, dietary preferences
-- =====================================================

-- =====================================================
-- Step 1: Create user_favorites table
-- =====================================================
CREATE TABLE IF NOT EXISTS user_favorites (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    menu_item_id INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, menu_item_id)
);

CREATE INDEX IF NOT EXISTS idx_user_favorites_user ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_item ON user_favorites(menu_item_id);

-- =====================================================
-- Step 2: Create user_addresses table
-- =====================================================
CREATE TABLE IF NOT EXISTS user_addresses (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    label VARCHAR(50),  -- e.g., "Home", "Work", "Mom's House"
    street_address VARCHAR(255) NOT NULL,
    apartment VARCHAR(50),  -- Optional apartment/unit number
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(20) NOT NULL,
    phone_number VARCHAR(50),
    delivery_instructions TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_addresses_user ON user_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_addresses_default ON user_addresses(user_id, is_default);

-- =====================================================
-- Step 3: Create user_profiles table
-- =====================================================
CREATE TABLE IF NOT EXISTS user_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255),
    phone_number VARCHAR(50),
    email VARCHAR(255),

    -- Dietary Preferences (JSON arrays)
    dietary_preferences JSONB DEFAULT '[]'::jsonb,  -- ["vegetarian", "gluten_free"]
    allergens JSONB DEFAULT '[]'::jsonb,  -- ["peanuts", "dairy"]
    spicy_tolerance VARCHAR(20) DEFAULT 'mild',  -- none, mild, medium, hot

    -- Notification Preferences
    email_notifications BOOLEAN DEFAULT TRUE,
    push_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    marketing_emails BOOLEAN DEFAULT FALSE,

    -- App Preferences (nullable, no foreign key for now)
    default_store_id INT,  -- Will reference stores(id) when available
    preferred_order_type VARCHAR(20) DEFAULT 'pickup',  -- pickup, delivery, dine-in

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index without foreign key constraint
CREATE INDEX IF NOT EXISTS idx_user_profiles_store ON user_profiles(default_store_id);

-- =====================================================
-- Step 4: Trigger to auto-create user profile
-- =====================================================
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_profiles (user_id, email)
    VALUES (NEW.id, NEW.email)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION create_user_profile();

-- =====================================================
-- Step 5: Trigger to auto-update updated_at
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
BEFORE UPDATE ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_addresses_updated_at ON user_addresses;
CREATE TRIGGER update_user_addresses_updated_at
BEFORE UPDATE ON user_addresses
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Step 6: Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- user_favorites policies
DROP POLICY IF EXISTS "Users can view their own favorites" ON user_favorites;
CREATE POLICY "Users can view their own favorites"
ON user_favorites FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own favorites" ON user_favorites;
CREATE POLICY "Users can insert their own favorites"
ON user_favorites FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own favorites" ON user_favorites;
CREATE POLICY "Users can delete their own favorites"
ON user_favorites FOR DELETE
USING (auth.uid() = user_id);

-- user_addresses policies
DROP POLICY IF EXISTS "Users can view their own addresses" ON user_addresses;
CREATE POLICY "Users can view their own addresses"
ON user_addresses FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own addresses" ON user_addresses;
CREATE POLICY "Users can insert their own addresses"
ON user_addresses FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own addresses" ON user_addresses;
CREATE POLICY "Users can update their own addresses"
ON user_addresses FOR UPDATE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own addresses" ON user_addresses;
CREATE POLICY "Users can delete their own addresses"
ON user_addresses FOR DELETE
USING (auth.uid() = user_id);

-- user_profiles policies
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
CREATE POLICY "Users can view their own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
CREATE POLICY "Users can update their own profile"
ON user_profiles FOR UPDATE
USING (auth.uid() = user_id);

-- =====================================================
-- Step 7: Helper Functions
-- =====================================================

-- Function to get user's favorite menu items
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

-- Function to toggle favorite
CREATE OR REPLACE FUNCTION toggle_favorite(p_user_id UUID, p_menu_item_id INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    -- Check if already favorited
    SELECT EXISTS(
        SELECT 1 FROM user_favorites
        WHERE user_id = p_user_id AND menu_item_id = p_menu_item_id
    ) INTO v_exists;

    IF v_exists THEN
        -- Remove favorite
        DELETE FROM user_favorites
        WHERE user_id = p_user_id AND menu_item_id = p_menu_item_id;
        RETURN FALSE;  -- Unfavorited
    ELSE
        -- Add favorite
        INSERT INTO user_favorites (user_id, menu_item_id)
        VALUES (p_user_id, p_menu_item_id);
        RETURN TRUE;  -- Favorited
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to ensure only one default address
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = TRUE THEN
        -- Remove default from all other addresses for this user
        UPDATE user_addresses
        SET is_default = FALSE
        WHERE user_id = NEW.user_id
        AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ensure_single_default_address_trigger ON user_addresses;
CREATE TRIGGER ensure_single_default_address_trigger
BEFORE INSERT OR UPDATE ON user_addresses
FOR EACH ROW
WHEN (NEW.is_default = TRUE)
EXECUTE FUNCTION ensure_single_default_address();

-- =====================================================
-- Step 8: Grant Permissions
-- =====================================================
GRANT SELECT, INSERT, DELETE ON user_favorites TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_addresses TO authenticated;
GRANT SELECT, UPDATE ON user_profiles TO authenticated;

GRANT USAGE ON SEQUENCE user_favorites_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE user_addresses_id_seq TO authenticated;

GRANT EXECUTE ON FUNCTION get_user_favorites(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_favorite(UUID, INT) TO authenticated;

-- =====================================================
-- Step 9: Add foreign key to stores table (OPTIONAL)
-- =====================================================
-- Uncomment this section if you have a stores table with id column:
-- ALTER TABLE user_profiles
-- ADD CONSTRAINT fk_user_profiles_store
-- FOREIGN KEY (default_store_id) REFERENCES stores(id)
-- ON DELETE SET NULL;

-- =====================================================
-- Testing Queries
-- =====================================================

-- Test 1: Add a favorite
-- INSERT INTO user_favorites (user_id, menu_item_id)
-- VALUES ('your-user-id', 1);

-- Test 2: Get user favorites
-- SELECT * FROM get_user_favorites('your-user-id');

-- Test 3: Toggle favorite
-- SELECT toggle_favorite('your-user-id', 1);

-- Test 4: Add an address
-- INSERT INTO user_addresses (user_id, label, street_address, city, state, zip_code, is_default)
-- VALUES ('your-user-id', 'Home', '123 Main St', 'Highland Mills', 'NY', '10930', TRUE);

-- Test 5: Get user profile
-- SELECT * FROM user_profiles WHERE user_id = 'your-user-id';

-- Test 6: Update dietary preferences
-- UPDATE user_profiles
-- SET dietary_preferences = '["vegetarian", "gluten_free"]'::jsonb,
--     allergens = '["peanuts"]'::jsonb
-- WHERE user_id = 'your-user-id';

-- =====================================================
-- Migration Complete!
-- =====================================================
