-- =====================================================
-- Migration 056: Rewards Schema Alignment
-- Version: 1.0
-- Date: 2025-12-02
-- Purpose: Ensure customer_rewards and rewards_transactions
--          tables have correct schema for frontend integration
-- =====================================================

-- =====================================================
-- 1. Ensure customer_rewards table has correct columns
-- =====================================================

-- Add lifetime_points column if it doesn't exist
ALTER TABLE customer_rewards
ADD COLUMN IF NOT EXISTS lifetime_points INTEGER DEFAULT 0;

-- Add tier column if it doesn't exist
ALTER TABLE customer_rewards
ADD COLUMN IF NOT EXISTS tier VARCHAR(20) DEFAULT 'bronze';

-- Update tier based on total_spent (1 point per dollar)
UPDATE customer_rewards
SET
  lifetime_points = COALESCE(FLOOR(total_spent), 0),
  tier = CASE
    WHEN COALESCE(total_spent, 0) >= 1500 THEN 'gold'
    WHEN COALESCE(total_spent, 0) >= 500 THEN 'silver'
    ELSE 'bronze'
  END
WHERE tier IS NULL OR tier = '';

-- =====================================================
-- 2. Ensure rewards_transactions has correct columns
-- =====================================================

-- Verify order_id FK exists (create if not)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'rewards_transactions'
    AND column_name = 'order_id'
  ) THEN
    ALTER TABLE rewards_transactions
    ADD COLUMN order_id UUID REFERENCES orders(id) ON DELETE SET NULL;
  END IF;
END $$;

-- =====================================================
-- 3. Add indexes for rewards queries
-- =====================================================

-- Index for customer lookups
CREATE INDEX IF NOT EXISTS idx_customer_rewards_customer
ON customer_rewards(customer_id);

-- Index for transactions by customer (most common query)
CREATE INDEX IF NOT EXISTS idx_rewards_transactions_customer
ON rewards_transactions(customer_id);

-- Index for transactions by order (for linking)
CREATE INDEX IF NOT EXISTS idx_rewards_transactions_order
ON rewards_transactions(order_id);

-- Index for recent transactions
CREATE INDEX IF NOT EXISTS idx_rewards_transactions_created
ON rewards_transactions(created_at DESC);

-- Composite index for customer + recent transactions
CREATE INDEX IF NOT EXISTS idx_rewards_transactions_customer_created
ON rewards_transactions(customer_id, created_at DESC);

-- =====================================================
-- 4. RLS Policies for customer rewards access
-- =====================================================

-- Enable RLS if not already enabled
ALTER TABLE customer_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards_transactions ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Customers can view their own rewards" ON customer_rewards;
DROP POLICY IF EXISTS "Customers can view their own transactions" ON rewards_transactions;

-- Customers can view their own rewards
CREATE POLICY "Customers can view their own rewards"
ON customer_rewards FOR SELECT
TO authenticated
USING (customer_id = (SELECT auth.uid()));

-- Staff can view all rewards
CREATE POLICY "Staff can view all rewards"
ON customer_rewards FOR SELECT
TO authenticated
USING (
  public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
);

-- Customers can view their own transactions
CREATE POLICY "Customers can view their own transactions"
ON rewards_transactions FOR SELECT
TO authenticated
USING (customer_id = (SELECT auth.uid()));

-- Staff can view all transactions
CREATE POLICY "Staff can view all transactions"
ON rewards_transactions FOR SELECT
TO authenticated
USING (
  public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
);

-- System can insert/update (trigger-based)
CREATE POLICY "System can manage rewards"
ON customer_rewards FOR ALL
TO authenticated
USING (
  public.is_current_user_system_admin()
);

CREATE POLICY "System can manage transactions"
ON rewards_transactions FOR ALL
TO authenticated
USING (
  public.is_current_user_system_admin()
);

-- =====================================================
-- 5. Update calculate_order_rewards trigger function
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_order_rewards()
RETURNS TRIGGER AS $$
DECLARE
  points_earned INTEGER;
  customer_tier VARCHAR(20);
BEGIN
  -- Only award points for completed orders with a customer_id
  IF NEW.status = 'completed' AND NEW.customer_id IS NOT NULL AND
     (OLD.status IS NULL OR OLD.status != 'completed') THEN

    -- Calculate points: 1 point per dollar spent
    points_earned := FLOOR(NEW.total);

    -- Insert reward transaction
    INSERT INTO rewards_transactions (
      customer_id,
      order_id,
      points_change,
      transaction_type,
      description
    ) VALUES (
      NEW.customer_id,
      NEW.id,
      points_earned,
      'earned',
      'Points earned from order ' || COALESCE(NEW.order_number, NEW.id::TEXT)
    );

    -- Upsert customer rewards
    INSERT INTO customer_rewards (
      customer_id,
      points,
      lifetime_points,
      total_orders,
      total_spent,
      tier
    ) VALUES (
      NEW.customer_id,
      points_earned,
      points_earned,
      1,
      NEW.total,
      'bronze'
    )
    ON CONFLICT (customer_id) DO UPDATE SET
      points = customer_rewards.points + points_earned,
      lifetime_points = customer_rewards.lifetime_points + points_earned,
      total_orders = customer_rewards.total_orders + 1,
      total_spent = customer_rewards.total_spent + NEW.total,
      tier = CASE
        WHEN customer_rewards.total_spent + NEW.total >= 1500 THEN 'gold'
        WHEN customer_rewards.total_spent + NEW.total >= 500 THEN 'silver'
        ELSE 'bronze'
      END,
      updated_at = NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SUCCESS! Migration 056 complete.
--
-- Changes:
-- - Added lifetime_points and tier columns to customer_rewards
-- - Added indexes for efficient rewards queries
-- - Added RLS policies for customer access
-- - Updated calculate_order_rewards to track lifetime points and tier
--
-- Frontend can now use useRewards hook to fetch from Supabase
-- =====================================================
