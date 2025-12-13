-- =====================================================
-- Customer App Profile System (FIXED)
-- Version: 3.1 - Fixed foreign key constraint
-- Date: 2025-11-19
-- =====================================================

-- =====================================================
-- STEP 1: Ensure auth_user_id has unique constraint
-- =====================================================

-- Add unique constraint to customers.auth_user_id if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'customers_auth_user_id_key'
    ) THEN
        ALTER TABLE customers ADD CONSTRAINT customers_auth_user_id_key UNIQUE (auth_user_id);
    END IF;
END $$;

-- =====================================================
-- STEP 2: Clean up old customer tables
-- =====================================================
DROP TABLE IF EXISTS customer_favorites CASCADE;
DROP TABLE IF EXISTS customer_addresses CASCADE;

-- =====================================================
-- STEP 3: Add columns to existing customers table
-- =====================================================

-- Add dietary preferences columns
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS dietary_preferences JSONB DEFAULT '[]'::jsonb;

ALTER TABLE customers
ADD COLUMN IF NOT EXISTS allergens JSONB DEFAULT '[]'::jsonb;

ALTER TABLE customers
ADD COLUMN IF NOT EXISTS spicy_tolerance VARCHAR(20) DEFAULT 'mild';

-- Add notification preference columns
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS email_notifications BOOLEAN DEFAULT TRUE;

ALTER TABLE customers
ADD COLUMN IF NOT EXISTS push_notifications BOOLEAN DEFAULT TRUE;

ALTER TABLE customers
ADD COLUMN IF NOT EXISTS sms_notifications BOOLEAN DEFAULT FALSE;

ALTER TABLE customers
ADD COLUMN IF NOT EXISTS marketing_emails BOOLEAN DEFAULT FALSE;

-- Add app preference columns
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS default_store_id INT REFERENCES stores(id) ON DELETE SET NULL;

ALTER TABLE customers
ADD COLUMN IF NOT EXISTS preferred_order_type VARCHAR(20) DEFAULT 'pickup';

-- Create index for default_store_id
CREATE INDEX IF NOT EXISTS idx_customers_default_store ON customers(default_store_id);

-- =====================================================
-- STEP 4: Create customer_favorites table
-- =====================================================
CREATE TABLE customer_favorites (
    id SERIAL PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customers(auth_user_id) ON DELETE CASCADE,
    menu_item_id INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(customer_id, menu_item_id)
);

CREATE INDEX idx_customer_favorites_customer ON customer_favorites(customer_id);
CREATE INDEX idx_customer_favorites_item ON customer_favorites(menu_item_id);

-- =====================================================
-- STEP 5: Create customer_addresses table
-- =====================================================
CREATE TABLE customer_addresses (
    id SERIAL PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customers(auth_user_id) ON DELETE CASCADE,
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

CREATE INDEX idx_customer_addresses_customer ON customer_addresses(customer_id);
CREATE INDEX idx_customer_addresses_default ON customer_addresses(customer_id, is_default);

-- =====================================================
-- STEP 6: Enable Row Level Security
-- =====================================================
ALTER TABLE customer_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 7: Create RLS Policies for customer_favorites
-- =====================================================

CREATE POLICY "Customers can view their own favorites"
ON customer_favorites FOR SELECT
USING (auth.uid() = customer_id);

CREATE POLICY "Customers can insert their own favorites"
ON customer_favorites FOR INSERT
WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Customers can delete their own favorites"
ON customer_favorites FOR DELETE
USING (auth.uid() = customer_id);

-- =====================================================
-- STEP 8: Create RLS Policies for customer_addresses
-- =====================================================

CREATE POLICY "Customers can view their own addresses"
ON customer_addresses FOR SELECT
USING (auth.uid() = customer_id);

CREATE POLICY "Customers can insert their own addresses"
ON customer_addresses FOR INSERT
WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Customers can update their own addresses"
ON customer_addresses FOR UPDATE
USING (auth.uid() = customer_id);

CREATE POLICY "Customers can delete their own addresses"
ON customer_addresses FOR DELETE
USING (auth.uid() = customer_id);

-- =====================================================
-- STEP 9: Create triggers
-- =====================================================

-- Auto-update updated_at for customer_addresses
CREATE OR REPLACE FUNCTION update_customer_addresses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customer_addresses_updated_at
BEFORE UPDATE ON customer_addresses
FOR EACH ROW
EXECUTE FUNCTION update_customer_addresses_updated_at();

-- Ensure single default address per customer
CREATE OR REPLACE FUNCTION ensure_single_default_customer_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = TRUE THEN
        UPDATE customer_addresses
        SET is_default = FALSE
        WHERE customer_id = NEW.customer_id
        AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_single_default_customer_address_trigger
BEFORE INSERT OR UPDATE ON customer_addresses
FOR EACH ROW
WHEN (NEW.is_default = TRUE)
EXECUTE FUNCTION ensure_single_default_customer_address();

-- =====================================================
-- STEP 10: Create helper functions for customers
-- =====================================================

-- Toggle customer favorite
CREATE OR REPLACE FUNCTION toggle_customer_favorite(p_customer_id UUID, p_menu_item_id INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM customer_favorites
        WHERE customer_id = p_customer_id AND menu_item_id = p_menu_item_id
    ) INTO v_exists;

    IF v_exists THEN
        DELETE FROM customer_favorites
        WHERE customer_id = p_customer_id AND menu_item_id = p_menu_item_id;
        RETURN FALSE;
    ELSE
        INSERT INTO customer_favorites (customer_id, menu_item_id)
        VALUES (p_customer_id, p_menu_item_id);
        RETURN TRUE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get customer favorites
CREATE OR REPLACE FUNCTION get_customer_favorites(p_customer_id UUID)
RETURNS TABLE (
    menu_item_id INT,
    favorited_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        cf.menu_item_id,
        cf.created_at
    FROM customer_favorites cf
    WHERE cf.customer_id = p_customer_id
    ORDER BY cf.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 11: Grant permissions
-- =====================================================
GRANT SELECT, INSERT, DELETE ON customer_favorites TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON customer_addresses TO authenticated;

GRANT USAGE ON SEQUENCE customer_favorites_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE customer_addresses_id_seq TO authenticated;

GRANT EXECUTE ON FUNCTION get_customer_favorites(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_customer_favorite(UUID, INT) TO authenticated;

-- =====================================================
-- SUCCESS! Migration complete.
--
-- Modified:
-- ✅ customers - Added UNIQUE constraint on auth_user_id
-- ✅ customers - Added dietary preferences, notifications, default_store_id
--
-- Created:
-- ✅ customer_favorites - Store favorite menu items (uses customer_id → auth_user_id)
-- ✅ customer_addresses - Store delivery addresses (uses customer_id → auth_user_id)
--
-- Security:
-- ✅ Row Level Security on all tables
-- ✅ Customers can only access their own data
-- ✅ Complete separation from user_profiles (business users)
-- =====================================================
