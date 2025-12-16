-- ============================================
-- FIX ORDER NUMBER TIMESTAMP
-- Use clock_timestamp() instead of NOW() to get actual submission time
-- NOW() returns transaction start time, which can be stale if user browsed for a while
-- ============================================

-- Update the generate_order_number function to use clock_timestamp()
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    -- Use clock_timestamp() for actual current time, not transaction start time
    NEW.order_number = 'ORD-' || EXTRACT(EPOCH FROM clock_timestamp())::BIGINT;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Also update the more sophisticated order number generator if it exists
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

  -- If store doesn't have a code, fall back to timestamp-based number
  IF v_store_code IS NULL THEN
    RETURN 'ORD-' || EXTRACT(EPOCH FROM clock_timestamp())::BIGINT;
  END IF;

  -- Get current date in YYMMDD format using clock_timestamp for accuracy
  v_date_key := TO_CHAR(clock_timestamp()::DATE, 'YYMMDD');

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

-- Update the set_order_number trigger function as well
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    -- Try to use store-based order number first
    BEGIN
      NEW.order_number := generate_order_number(NEW.store_id);
    EXCEPTION WHEN OTHERS THEN
      -- Fall back to timestamp-based order number
      NEW.order_number := 'ORD-' || EXTRACT(EPOCH FROM clock_timestamp())::BIGINT;
    END;
  END IF;
  RETURN NEW;
END;
$$;
