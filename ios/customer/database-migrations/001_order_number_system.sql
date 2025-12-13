-- =====================================================
-- Order Number System Migration
-- Version: 1.0
-- Date: 2025-11-19
-- Description: Implements scalable multi-store order numbering
--              Format: [STORE_CODE]-[YYMMDD]-[SEQUENCE]
--              Example: HM-241119-001
-- =====================================================

-- Step 1: Add store_code column to stores table
-- =====================================================
ALTER TABLE stores
ADD COLUMN IF NOT EXISTS store_code VARCHAR(3);

-- Add unique constraint
ALTER TABLE stores
ADD CONSTRAINT stores_store_code_unique UNIQUE (store_code);

-- Step 2: Populate store codes for all 29 stores (MATCHES PRODUCTION DATABASE)
-- =====================================================
UPDATE stores SET store_code = 'HM' WHERE id = 1;   -- Highland Mills
UPDATE stores SET store_code = 'MO' WHERE id = 2;   -- Monroe
UPDATE stores SET store_code = 'MW' WHERE id = 3;   -- Middletown
UPDATE stores SET store_code = 'NW' WHERE id = 4;   -- Newburgh
UPDATE stores SET store_code = 'WP' WHERE id = 5;   -- West Point
UPDATE stores SET store_code = 'SL' WHERE id = 6;   -- Slate Hill
UPDATE stores SET store_code = 'PS' WHERE id = 7;   -- Port Jervis
UPDATE stores SET store_code = 'GW' WHERE id = 8;   -- Goshen West
UPDATE stores SET store_code = 'GE' WHERE id = 9;   -- Goshen East
UPDATE stores SET store_code = 'CH' WHERE id = 10;  -- Chester
UPDATE stores SET store_code = 'WR' WHERE id = 11;  -- Warwick
UPDATE stores SET store_code = 'FL' WHERE id = 12;  -- Florida
UPDATE stores SET store_code = 'VV' WHERE id = 13;  -- Vails Gate
UPDATE stores SET store_code = 'WL' WHERE id = 14;  -- Walden
UPDATE stores SET store_code = 'ML' WHERE id = 15;  -- Maybrook
UPDATE stores SET store_code = 'CR' WHERE id = 16;  -- Cornwall
UPDATE stores SET store_code = 'NP' WHERE id = 17;  -- New Paltz
UPDATE stores SET store_code = 'KG' WHERE id = 18;  -- Kingston
UPDATE stores SET store_code = 'RH' WHERE id = 19;  -- Rhinebeck
UPDATE stores SET store_code = 'PK' WHERE id = 20;  -- Poughkeepsie
UPDATE stores SET store_code = 'FI' WHERE id = 21;  -- Fishkill
UPDATE stores SET store_code = 'BE' WHERE id = 22;  -- Beacon
UPDATE stores SET store_code = 'WP2' WHERE id = 23; -- Wappingers Falls
UPDATE stores SET store_code = 'HD' WHERE id = 24;  -- Hyde Park
UPDATE stores SET store_code = 'RD' WHERE id = 25;  -- Red Hook
UPDATE stores SET store_code = 'MI' WHERE id = 26;  -- Millbrook
UPDATE stores SET store_code = 'DV' WHERE id = 27;  -- Dover Plains
UPDATE stores SET store_code = 'AM' WHERE id = 28;  -- Amenia
UPDATE stores SET store_code = 'PW' WHERE id = 29;  -- Pawling

-- Step 3: Modify orders table to support new format
-- =====================================================
-- Expand order_number column to support longer format
ALTER TABLE orders
ALTER COLUMN order_number TYPE VARCHAR(20);

-- Step 4: Create sequence tracking table
-- =====================================================
CREATE TABLE IF NOT EXISTS order_sequences (
    store_id INT NOT NULL,
    date DATE NOT NULL,
    last_sequence INT DEFAULT 0,
    PRIMARY KEY (store_id, date),
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_order_sequences_lookup
ON order_sequences(store_id, date);

-- Step 5: Create function to generate order numbers
-- =====================================================
CREATE OR REPLACE FUNCTION generate_order_number(p_store_id INT)
RETURNS TEXT AS $$
DECLARE
    v_store_code TEXT;
    v_date_str TEXT;
    v_sequence INT;
    v_order_number TEXT;
BEGIN
    -- Get store code
    SELECT store_code INTO v_store_code
    FROM stores
    WHERE id = p_store_id;

    -- If store code not found, use 'XX'
    IF v_store_code IS NULL THEN
        v_store_code := 'XX';
    END IF;

    -- Format date as YYMMDD
    v_date_str := TO_CHAR(CURRENT_DATE, 'YYMMDD');

    -- Get and increment sequence for this store+date
    -- This uses ON CONFLICT to handle race conditions
    INSERT INTO order_sequences (store_id, date, last_sequence)
    VALUES (p_store_id, CURRENT_DATE, 1)
    ON CONFLICT (store_id, date)
    DO UPDATE SET last_sequence = order_sequences.last_sequence + 1
    RETURNING last_sequence INTO v_sequence;

    -- Build order number: HM-241119-001
    v_order_number := v_store_code || '-' || v_date_str || '-' ||
                      LPAD(v_sequence::TEXT, 3, '0');

    RETURN v_order_number;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Create trigger function to auto-generate order numbers
-- =====================================================
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS TRIGGER AS $$
BEGIN
    -- Only generate if order_number is NULL or empty
    IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
        NEW.order_number := generate_order_number(NEW.store_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 7: Create trigger on orders table
-- =====================================================
DROP TRIGGER IF EXISTS trigger_set_order_number ON orders;

CREATE TRIGGER trigger_set_order_number
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION set_order_number();

-- Step 8: Grant necessary permissions (adjust role names as needed)
-- =====================================================
-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION generate_order_number(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION set_order_number() TO authenticated;
GRANT EXECUTE ON FUNCTION generate_order_number(INT) TO anon;
GRANT EXECUTE ON FUNCTION set_order_number() TO anon;

-- Grant access to order_sequences table
GRANT SELECT, INSERT, UPDATE ON order_sequences TO authenticated;
GRANT SELECT, INSERT, UPDATE ON order_sequences TO anon;

-- =====================================================
-- Testing Queries (Run these to verify)
-- =====================================================

-- Test 1: Manually generate an order number for store 1 (Highland Mills)
-- SELECT generate_order_number(1);
-- Expected: HM-251119-001 (or current date)

-- Test 2: Check sequence tracking
-- SELECT * FROM order_sequences ORDER BY date DESC, store_id;

-- Test 3: Insert test order (trigger should auto-generate order_number)
-- INSERT INTO orders (store_id, customer_name, customer_phone, order_type, status, subtotal, tax, total)
-- VALUES (1, 'Test Customer', '555-1234', 'pickup', 'pending', 10.00, 0.80, 10.80)
-- RETURNING id, order_number;
-- Expected order_number: HM-251119-001

-- Test 4: Verify order was created with correct number
-- SELECT id, order_number, store_id, customer_name, created_at
-- FROM orders
-- ORDER BY created_at DESC
-- LIMIT 5;

-- =====================================================
-- Rollback Script (in case you need to undo)
-- =====================================================
-- DROP TRIGGER IF EXISTS trigger_set_order_number ON orders;
-- DROP FUNCTION IF EXISTS set_order_number();
-- DROP FUNCTION IF EXISTS generate_order_number(INT);
-- DROP TABLE IF EXISTS order_sequences;
-- ALTER TABLE orders ALTER COLUMN order_number TYPE TEXT;
-- ALTER TABLE stores DROP COLUMN IF EXISTS store_code;

-- =====================================================
-- Migration Complete!
-- =====================================================
-- Next steps:
-- 1. Run this migration on your Supabase database
-- 2. Update customer app code to use returned order_number
-- 3. Test with a real order
-- 4. Verify order number appears in both apps
-- =====================================================
