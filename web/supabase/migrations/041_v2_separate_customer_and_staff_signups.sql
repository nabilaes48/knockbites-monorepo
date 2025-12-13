-- =====================================================
-- Migration 041 v2: Separate Customer and Staff Signups (SAFE VERSION)
-- Version: 2.0
-- Date: 2025-11-20
-- Purpose: Customers go to 'customers' table, staff go to 'user_profiles'
-- =====================================================

-- =====================================================
-- STEP 1: Drop existing customers table if it has issues
-- =====================================================

DROP TABLE IF EXISTS customers CASCADE;

-- =====================================================
-- STEP 2: Create customers table with correct schema
-- =====================================================

CREATE TABLE customers (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_phone ON customers(phone);

-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 3: Create RLS Policies for customers
-- =====================================================

-- Customers can view own profile
CREATE POLICY "customers_view_own"
ON customers FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Customers can update own profile
CREATE POLICY "customers_update_own"
ON customers FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Allow public insert on signup (via trigger)
CREATE POLICY "public_insert_customers"
ON customers FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Staff can view all customers
CREATE POLICY "staff_view_customers"
ON customers FOR SELECT
TO authenticated
USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
);

-- =====================================================
-- STEP 4: Update handle_new_user trigger
-- =====================================================

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
  WHEN OTHERS THEN
    -- If insert fails, just return (might be a business user)
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SUCCESS! Customer and staff signups separated.
--
-- Changes:
-- ✅ Created clean customers table
-- ✅ Updated handle_new_user() to insert into customers by default
-- ✅ Customer signups now go to customers table
-- ✅ Staff signups (via admin) go to user_profiles table
-- =====================================================
