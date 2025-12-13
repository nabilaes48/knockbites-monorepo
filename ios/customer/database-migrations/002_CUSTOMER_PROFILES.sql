-- =====================================================
-- Customer Profile System Migration
-- Version: 3.0 - Uses customer_profiles (not user_profiles)
-- Date: 2025-11-19
-- Note: user_profiles already exists for business app
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
-- STEP 2: Create user_favorites table
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
-- STEP 3: Create user_addresses table
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
-- STEP 4: Create customer_profiles table
-- (Different from user_profiles which is for business app)
-- =====================================================
CREATE TABLE customer_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255),
    phone_number VARCHAR(50),
    email VARCHAR(255),

    -- Dietary Preferences
    dietary_preferences JSONB DEFAULT '[]'::jsonb,
    allergens JSONB DEFAULT '[]'::jsonb,
    spicy_tolerance VARCHAR(20) DEFAULT 'mild',

    -- Notification Preferences
    email_notifications BOOLEAN DEFAULT TRUE,
    push_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    marketing_emails BOOLEAN DEFAULT FALSE,

    -- App Preferences
    default_store_id INT REFERENCES stores(id) ON DELETE SET NULL,
    preferred_order_type VARCHAR(20) DEFAULT 'pickup',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_customer_profiles_store ON customer_profiles(default_store_id);

-- =====================================================
-- STEP 5: Enable Row Level Security
-- =====================================================
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_profiles ENABLE ROW LEVEL SECURITY;

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

-- Customer profiles policies
CREATE POLICY "Customers can view their own profile"
ON customer_profiles FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Customers can update their own profile"
ON customer_profiles FOR UPDATE
USING (auth.uid() = user_id);

-- =====================================================
-- STEP 7: Create triggers
-- =====================================================

-- Auto-update updated_at for customer_profiles
CREATE OR REPLACE FUNCTION update_customer_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customer_profiles_updated_at
BEFORE UPDATE ON customer_profiles
FOR EACH ROW
EXECUTE FUNCTION update_customer_updated_at();

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

-- Auto-create customer profile on signup
CREATE OR REPLACE FUNCTION create_customer_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO customer_profiles (user_id, email)
    VALUES (NEW.id, NEW.email)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_customer_signup
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION create_customer_profile();

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
GRANT SELECT, UPDATE ON customer_profiles TO authenticated;

GRANT USAGE ON SEQUENCE user_favorites_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE user_addresses_id_seq TO authenticated;

GRANT EXECUTE ON FUNCTION get_user_favorites(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_favorite(UUID, INT) TO authenticated;

-- =====================================================
-- SUCCESS! Customer profile system created.
--
-- Tables:
-- ✅ user_favorites - Customer favorite menu items
-- ✅ user_addresses - Customer delivery addresses
-- ✅ customer_profiles - Customer dietary prefs & settings
--
-- Note: user_profiles remains untouched (for business app)
-- =====================================================
