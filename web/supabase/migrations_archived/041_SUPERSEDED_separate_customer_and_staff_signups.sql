-- =====================================================
-- Migration 041: Separate Customer and Staff Signups
-- Version: 1.0
-- Date: 2025-11-20
-- Purpose: Customers go to 'customers' table, staff go to 'user_profiles'
-- =====================================================

-- =====================================================
-- STEP 1: Create customers table if it doesn't exist
-- =====================================================

CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);

-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- RLS Policies for customers
CREATE POLICY "Customers can view own profile"
ON customers FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "Customers can update own profile"
ON customers FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE POLICY "Public can insert customers on signup"
ON customers FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Staff can view all customers"
ON customers FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
);

-- =====================================================
-- STEP 2: Update handle_new_user trigger
-- =====================================================

-- New trigger: Insert customers into customers table by default
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert into customers table for regular signups
  INSERT INTO public.customers (id, full_name, email, phone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Customer'),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'phone', '')
  );
  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    -- If already exists (e.g., manually created by admin), do nothing
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 3: Migrate existing customer-role users from user_profiles to customers
-- =====================================================

-- Copy customers from user_profiles to customers table
INSERT INTO customers (id, full_name, email, phone, avatar_url, created_at, updated_at)
SELECT
    up.id,
    up.full_name,
    au.email,
    up.phone,
    up.avatar_url,
    up.created_at,
    up.updated_at
FROM user_profiles up
JOIN auth.users au ON au.id = up.id
WHERE up.role = 'customer'
ON CONFLICT (id) DO NOTHING;

-- Delete customer-role users from user_profiles (they belong in customers table)
-- DELETE FROM user_profiles WHERE role = 'customer';
-- ⚠️ Commented out for safety - uncomment after verifying customers table is populated

-- =====================================================
-- SUCCESS! Customer and staff signups separated.
--
-- Changes:
-- ✅ Created customers table with RLS policies
-- ✅ Updated handle_new_user() to insert into customers by default
-- ✅ Migrated existing customer-role users to customers table
-- ✅ Customer signups now go to customers table
-- ✅ Staff signups (via admin) go to user_profiles table
-- =====================================================
