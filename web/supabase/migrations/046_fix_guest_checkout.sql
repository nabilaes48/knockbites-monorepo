-- =====================================================
-- Migration 046: Guest Checkout with Email Verification
-- Version: 2.0
-- Date: 2025-11-25
-- Purpose: Require email verification before placing orders
-- Rule:
--   1. Customer enters name, phone, email
--   2. System sends verification code to email
--   3. Customer confirms code
--   4. Order can be placed
--   5. Email/phone blocked until order completed/picked up
-- =====================================================

-- =====================================================
-- STEP 1: Create verification codes table
-- =====================================================

CREATE TABLE IF NOT EXISTS order_verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL,
    phone TEXT,
    verification_code TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE
);

-- Create partial unique index to prevent duplicate pending verifications
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_pending_verification
ON order_verifications (email)
WHERE is_verified = FALSE;

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_verification_email ON order_verifications(email);
CREATE INDEX IF NOT EXISTS idx_verification_code ON order_verifications(verification_code);
CREATE INDEX IF NOT EXISTS idx_verification_expires ON order_verifications(expires_at);

-- Enable RLS
ALTER TABLE order_verifications ENABLE ROW LEVEL SECURITY;

-- Public can create and verify
CREATE POLICY "anon_create_verification"
ON order_verifications FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "anon_update_verification"
ON order_verifications FOR UPDATE
TO anon, authenticated
USING (true);

CREATE POLICY "anon_read_verification"
ON order_verifications FOR SELECT
TO anon, authenticated
USING (true);

-- =====================================================
-- STEP 2: Function to generate verification code
-- =====================================================

CREATE OR REPLACE FUNCTION public.create_order_verification(
    p_email TEXT,
    p_phone TEXT DEFAULT NULL
)
RETURNS TABLE (
    verification_id UUID,
    code TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    can_order BOOLEAN,
    pending_order_exists BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_id UUID;
    v_code TEXT;
    v_expires TIMESTAMP WITH TIME ZONE;
    v_pending_count INT;
    v_can_order BOOLEAN := TRUE;
BEGIN
    -- Check if customer already has pending/unpicked orders
    SELECT COUNT(*) INTO v_pending_count
    FROM orders
    WHERE (
        (customer_email = p_email AND p_email IS NOT NULL AND p_email != '')
        OR
        (customer_phone = p_phone AND p_phone IS NOT NULL AND p_phone != '')
    )
    AND status NOT IN ('completed', 'cancelled', 'picked_up', 'delivered');

    IF v_pending_count > 0 THEN
        v_can_order := FALSE;
        RETURN QUERY SELECT
            NULL::UUID,
            NULL::TEXT,
            NULL::TIMESTAMP WITH TIME ZONE,
            FALSE,
            TRUE;
        RETURN;
    END IF;

    -- Delete any existing unverified codes for this email
    DELETE FROM order_verifications
    WHERE email = p_email AND is_verified = FALSE;

    -- Generate 6-digit code
    v_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    v_expires := NOW() + INTERVAL '10 minutes';

    -- Insert verification record
    INSERT INTO order_verifications (email, phone, verification_code, expires_at)
    VALUES (p_email, p_phone, v_code, v_expires)
    RETURNING id INTO v_id;

    -- Return the verification details
    RETURN QUERY SELECT v_id, v_code, v_expires, TRUE, FALSE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_order_verification(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.create_order_verification(TEXT, TEXT) TO authenticated;

-- =====================================================
-- STEP 3: Function to verify code
-- =====================================================

CREATE OR REPLACE FUNCTION public.verify_order_code(
    p_email TEXT,
    p_code TEXT
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    verification_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_record RECORD;
BEGIN
    -- Find the verification record
    SELECT * INTO v_record
    FROM order_verifications
    WHERE email = p_email
    AND verification_code = p_code
    AND is_verified = FALSE
    AND expires_at > NOW();

    IF v_record IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Invalid or expired code'::TEXT, NULL::UUID;
        RETURN;
    END IF;

    -- Mark as verified
    UPDATE order_verifications
    SET is_verified = TRUE, verified_at = NOW()
    WHERE id = v_record.id;

    RETURN QUERY SELECT TRUE, 'Verified successfully'::TEXT, v_record.id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_order_code(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.verify_order_code(TEXT, TEXT) TO authenticated;

-- =====================================================
-- STEP 4: Function to check if customer can place order
-- =====================================================

CREATE OR REPLACE FUNCTION public.customer_can_place_order(
    p_email TEXT,
    p_phone TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    pending_orders INT;
    is_verified BOOLEAN;
BEGIN
    -- Check for pending orders
    SELECT COUNT(*) INTO pending_orders
    FROM orders
    WHERE (
        (customer_email = p_email AND p_email IS NOT NULL AND p_email != '')
        OR
        (customer_phone = p_phone AND p_phone IS NOT NULL AND p_phone != '')
    )
    AND status NOT IN ('completed', 'cancelled', 'picked_up', 'delivered');

    IF pending_orders > 0 THEN
        RETURN FALSE;
    END IF;

    -- Check if email is verified (within last 30 minutes)
    SELECT EXISTS (
        SELECT 1 FROM order_verifications
        WHERE email = p_email
        AND is_verified = TRUE
        AND verified_at > NOW() - INTERVAL '30 minutes'
    ) INTO is_verified;

    RETURN is_verified;
END;
$$;

GRANT EXECUTE ON FUNCTION public.customer_can_place_order(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.customer_can_place_order(TEXT, TEXT) TO authenticated;

-- =====================================================
-- STEP 5: Create order policies with verification check
-- =====================================================

-- Drop any conflicting policies
DROP POLICY IF EXISTS "rbac_public_create_orders" ON orders;
DROP POLICY IF EXISTS "Anyone can create orders" ON orders;
DROP POLICY IF EXISTS "anon_can_create_orders" ON orders;
DROP POLICY IF EXISTS "guest_checkout_create_orders" ON orders;
DROP POLICY IF EXISTS "guest_checkout_with_limit" ON orders;

-- Create policy: Only verified customers with no pending orders can create
CREATE POLICY "verified_guest_checkout"
ON orders FOR INSERT
TO anon, authenticated
WITH CHECK (
    public.customer_can_place_order(customer_email, customer_phone)
);

-- Ensure order_items can also be inserted by guests
DROP POLICY IF EXISTS "Anyone can insert order items" ON order_items;
DROP POLICY IF EXISTS "anon_can_insert_order_items" ON order_items;
DROP POLICY IF EXISTS "guest_checkout_create_order_items" ON order_items;

CREATE POLICY "guest_checkout_create_order_items"
ON order_items FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Allow public to SELECT orders (for order tracking)
DROP POLICY IF EXISTS "public_view_orders_by_id" ON orders;
DROP POLICY IF EXISTS "guest_track_order_by_id" ON orders;

CREATE POLICY "guest_track_order_by_id"
ON orders FOR SELECT
TO anon
USING (true);

-- Allow public to SELECT order items (for order tracking)
DROP POLICY IF EXISTS "public_view_order_items" ON order_items;
DROP POLICY IF EXISTS "guest_view_order_items" ON order_items;

CREATE POLICY "guest_view_order_items"
ON order_items FOR SELECT
TO anon
USING (true);

-- =====================================================
-- STEP 6: Cleanup function for expired verifications
-- =====================================================

CREATE OR REPLACE FUNCTION public.cleanup_expired_verifications()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM order_verifications
    WHERE expires_at < NOW() - INTERVAL '1 hour';
END;
$$;

-- =====================================================
-- SUCCESS! Guest checkout with email verification is enabled.
--
-- Flow:
-- 1. Customer enters email/phone
-- 2. Call: create_order_verification(email, phone)
--    → Returns verification code (send via email)
--    → Also checks for pending orders first
-- 3. Customer enters code
-- 4. Call: verify_order_code(email, code)
--    → Returns success/failure
-- 5. Customer can place order (within 30 min of verification)
-- 6. After order placed, email/phone blocked until completed
--
-- Tables Created:
-- ✅ order_verifications - Stores verification codes
--
-- Functions Created:
-- ✅ create_order_verification(email, phone) - Generate code
-- ✅ verify_order_code(email, code) - Verify code
-- ✅ customer_can_place_order(email, phone) - Check if allowed
-- ✅ cleanup_expired_verifications() - Remove old codes
--
-- Policies Created:
-- ✅ verified_guest_checkout - Only verified + no pending orders
-- =====================================================
