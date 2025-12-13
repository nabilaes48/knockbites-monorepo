-- =====================================================
-- CUSTOMERS TABLE MIGRATION
-- Create customers table for user management
-- =====================================================

-- Create customers table
CREATE TABLE IF NOT EXISTS customers (
  id SERIAL PRIMARY KEY,

  -- Authentication
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Profile Info
  email VARCHAR(255),
  phone VARCHAR(20),
  full_name VARCHAR(200),

  -- Preferences
  default_store_id INT REFERENCES stores(id),
  favorite_items JSONB DEFAULT '[]',
  dietary_restrictions TEXT[],

  -- Account Status
  is_active BOOLEAN DEFAULT true,
  email_verified BOOLEAN DEFAULT false,
  phone_verified BOOLEAN DEFAULT false,

  -- Marketing Preferences
  marketing_opt_in BOOLEAN DEFAULT true,
  push_notifications_enabled BOOLEAN DEFAULT true,
  sms_opt_in BOOLEAN DEFAULT false,

  -- Device Info (for push notifications)
  device_tokens JSONB DEFAULT '[]', -- Array of FCM/APNs tokens

  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_login_at TIMESTAMP,

  -- Constraints
  CONSTRAINT customers_email_phone_check CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_auth_user ON customers(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_customers_store ON customers(default_store_id);

-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- RLS Policies (drop if exist to allow re-running migration)
DROP POLICY IF EXISTS "Allow users to read own data" ON customers;
DROP POLICY IF EXISTS "Allow users to update own data" ON customers;
DROP POLICY IF EXISTS "Allow staff to read customers" ON customers;

-- Allow users to read their own data
CREATE POLICY "Allow users to read own data" ON customers
  FOR SELECT
  USING (auth.uid() = auth_user_id);

-- Allow users to update their own data
CREATE POLICY "Allow users to update own data" ON customers
  FOR UPDATE
  USING (auth.uid() = auth_user_id);

-- Allow staff to read all customers
CREATE POLICY "Allow staff to read customers" ON customers
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id::text = auth.uid()::text
      AND user_profiles.role IN ('super_admin', 'admin', 'manager', 'staff')
    )
  );

-- =====================================================
-- Migrate existing order data to customers table
-- =====================================================

-- Extract unique customers from orders table and create customer records
-- Note: orders.customer_id is UUID (links to auth.users), so we create
-- separate customer records based on email/phone
INSERT INTO customers (email, phone, full_name, default_store_id, is_active, created_at)
SELECT DISTINCT
  customer_email,
  customer_phone,
  customer_name,
  store_id,
  true,
  MIN(created_at)
FROM orders
WHERE customer_email IS NOT NULL OR customer_phone IS NOT NULL
GROUP BY customer_email, customer_phone, customer_name, store_id
ON CONFLICT DO NOTHING;

-- =====================================================
-- Note: We don't modify orders.customer_id since it's UUID type
-- Future enhancement: Link customers via auth_user_id or email/phone matching
-- =====================================================

-- =====================================================
-- Done! Customers table created successfully
-- =====================================================
