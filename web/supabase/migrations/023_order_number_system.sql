-- ============================================
-- ORDER NUMBER SYSTEM
-- Multi-store order numbering: [STORE_CODE]-[YYMMDD]-[SEQUENCE]
-- Example: HM-241119-001 (Highland Mills, Nov 19, order #1)
-- ============================================

-- Step 1: Check what stores exist in the database
SELECT id, name FROM stores ORDER BY id;

-- Step 2: Add store_code column to stores table
ALTER TABLE stores
ADD COLUMN IF NOT EXISTS store_code VARCHAR(3) UNIQUE;

-- Step 3: Update all 29 stores with their store codes
UPDATE stores SET store_code = 'HM' WHERE id = 1;  -- Highland Mills
UPDATE stores SET store_code = 'MO' WHERE id = 2;  -- Monroe
UPDATE stores SET store_code = 'MW' WHERE id = 3;  -- Middletown
UPDATE stores SET store_code = 'NW' WHERE id = 4;  -- Newburgh
UPDATE stores SET store_code = 'WP' WHERE id = 5;  -- West Point
UPDATE stores SET store_code = 'SL' WHERE id = 6;  -- Slate Hill
UPDATE stores SET store_code = 'PS' WHERE id = 7;  -- Port Jervis
UPDATE stores SET store_code = 'GW' WHERE id = 8;  -- Goshen West
UPDATE stores SET store_code = 'GE' WHERE id = 9;  -- Goshen East
UPDATE stores SET store_code = 'CH' WHERE id = 10; -- Chester
UPDATE stores SET store_code = 'WR' WHERE id = 11; -- Warwick
UPDATE stores SET store_code = 'FL' WHERE id = 12; -- Florida
UPDATE stores SET store_code = 'VV' WHERE id = 13; -- Vails Gate
UPDATE stores SET store_code = 'WL' WHERE id = 14; -- Walden
UPDATE stores SET store_code = 'ML' WHERE id = 15; -- Maybrook
UPDATE stores SET store_code = 'CR' WHERE id = 16; -- Cornwall
UPDATE stores SET store_code = 'NP' WHERE id = 17; -- New Paltz
UPDATE stores SET store_code = 'KG' WHERE id = 18; -- Kingston
UPDATE stores SET store_code = 'RH' WHERE id = 19; -- Rhinebeck
UPDATE stores SET store_code = 'PK' WHERE id = 20; -- Poughkeepsie
UPDATE stores SET store_code = 'FI' WHERE id = 21; -- Fishkill
UPDATE stores SET store_code = 'BE' WHERE id = 22; -- Beacon
UPDATE stores SET store_code = 'WP2' WHERE id = 23; -- Wappingers Falls
UPDATE stores SET store_code = 'HD' WHERE id = 24; -- Hyde Park
UPDATE stores SET store_code = 'RD' WHERE id = 25; -- Red Hook
UPDATE stores SET store_code = 'MI' WHERE id = 26; -- Millbrook
UPDATE stores SET store_code = 'DV' WHERE id = 27; -- Dover Plains
UPDATE stores SET store_code = 'AM' WHERE id = 28; -- Amenia
UPDATE stores SET store_code = 'PW' WHERE id = 29; -- Pawling

-- Step 4: Create sequence table for daily order counters per store
CREATE TABLE IF NOT EXISTS order_sequences (
  store_id BIGINT NOT NULL,
  date_key VARCHAR(6) NOT NULL, -- Format: YYMMDD
  sequence_number INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (store_id, date_key),
  FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
);

-- Step 5: Create function to generate order number
CREATE OR REPLACE FUNCTION generate_order_number(p_store_id BIGINT)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
  v_store_code VARCHAR(3);
  v_date_key VARCHAR(6);
  v_sequence INTEGER;
  v_order_number VARCHAR(20);
BEGIN
  -- Get store code
  SELECT store_code INTO v_store_code
  FROM stores
  WHERE id = p_store_id;

  IF v_store_code IS NULL THEN
    RAISE EXCEPTION 'Store code not found for store_id: %', p_store_id;
  END IF;

  -- Get current date in YYMMDD format
  v_date_key := TO_CHAR(CURRENT_DATE, 'YYMMDD');

  -- Get and increment sequence for this store and date
  INSERT INTO order_sequences (store_id, date_key, sequence_number)
  VALUES (p_store_id, v_date_key, 1)
  ON CONFLICT (store_id, date_key)
  DO UPDATE SET sequence_number = order_sequences.sequence_number + 1
  RETURNING sequence_number INTO v_sequence;

  -- Format: [STORE_CODE]-[YYMMDD]-[SEQUENCE]
  v_order_number := v_store_code || '-' || v_date_key || '-' || LPAD(v_sequence::TEXT, 3, '0');

  RETURN v_order_number;
END;
$$;

-- Step 6: Create trigger to auto-generate order numbers
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.order_number IS NULL THEN
    NEW.order_number := generate_order_number(NEW.store_id);
  END IF;
  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_set_order_number ON orders;

-- Create trigger
CREATE TRIGGER trigger_set_order_number
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION set_order_number();

-- Step 7: Update existing orders with new order numbers (only for stores with codes)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT o.id, o.store_id, o.created_at
    FROM orders o
    INNER JOIN stores s ON s.id = o.store_id
    WHERE s.store_code IS NOT NULL
    AND (o.order_number IS NULL OR o.order_number LIKE 'ORD-%')
  LOOP
    UPDATE orders
    SET order_number = generate_order_number(r.store_id)
    WHERE id = r.id;
  END LOOP;
END $$;

-- Verify the setup
SELECT
  s.id as store_id,
  s.name as store_name,
  s.store_code,
  COUNT(o.id) as order_count
FROM stores s
LEFT JOIN orders o ON o.store_id = s.id
GROUP BY s.id, s.name, s.store_code
ORDER BY s.id;

-- Test the function (only for stores that exist with codes)
SELECT generate_order_number(id) as test_order_number, name
FROM stores
WHERE store_code IS NOT NULL
LIMIT 2;
