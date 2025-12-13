-- =====================================================
-- MARKETING SYSTEM MIGRATION
-- Restaurant Marketing Platform - Proven Strategies
-- =====================================================

-- =====================================================
-- 1. LOYALTY PROGRAM TABLES
-- =====================================================

-- Master loyalty program configuration
CREATE TABLE IF NOT EXISTS loyalty_programs (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id) ON DELETE CASCADE,
  name VARCHAR(200) NOT NULL DEFAULT 'Rewards Program',
  points_per_dollar DECIMAL(5,2) DEFAULT 1.00,
  welcome_bonus_points INT DEFAULT 100,
  referral_bonus_points INT DEFAULT 500,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Loyalty tiers (Bronze, Silver, Gold, Platinum)
CREATE TABLE IF NOT EXISTS loyalty_tiers (
  id SERIAL PRIMARY KEY,
  program_id INT REFERENCES loyalty_programs(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  min_points INT NOT NULL,
  discount_percentage DECIMAL(5,2) DEFAULT 0,
  free_delivery BOOLEAN DEFAULT false,
  priority_support BOOLEAN DEFAULT false,
  early_access_promos BOOLEAN DEFAULT false,
  birthday_reward_points INT DEFAULT 0,
  tier_color VARCHAR(20),
  sort_order INT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Customer loyalty tracking
CREATE TABLE IF NOT EXISTS customer_loyalty (
  id SERIAL PRIMARY KEY,
  customer_id INT UNIQUE,
  program_id INT REFERENCES loyalty_programs(id) ON DELETE CASCADE,
  current_tier_id INT REFERENCES loyalty_tiers(id),
  total_points INT DEFAULT 0,
  lifetime_points INT DEFAULT 0,
  total_orders INT DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0,
  joined_at TIMESTAMP DEFAULT NOW(),
  last_order_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Add foreign key constraint after customers table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customers') THEN
    ALTER TABLE customer_loyalty
    ADD CONSTRAINT fk_customer_loyalty_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Loyalty point transaction history
CREATE TABLE IF NOT EXISTS loyalty_transactions (
  id SERIAL PRIMARY KEY,
  customer_loyalty_id INT REFERENCES customer_loyalty(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  transaction_type VARCHAR(50) NOT NULL,
  points INT NOT NULL,
  reason VARCHAR(200),
  balance_after INT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 2. COUPONS & PROMOTIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS coupons (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id) ON DELETE CASCADE,

  -- Basic Info
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(200) NOT NULL,
  description TEXT,

  -- Discount Type
  discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed_amount', 'free_item', 'bogo')),
  discount_value DECIMAL(10,2) NOT NULL,

  -- Conditions
  min_order_value DECIMAL(10,2) DEFAULT 0,
  max_discount_amount DECIMAL(10,2),
  applicable_order_types TEXT[],
  applicable_menu_categories INT[],
  first_order_only BOOLEAN DEFAULT false,

  -- Usage Limits
  max_uses_total INT,
  max_uses_per_customer INT DEFAULT 1,
  current_uses INT DEFAULT 0,

  -- Timing
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP,
  active_days_of_week INT[],
  active_hours_start TIME,
  active_hours_end TIME,

  -- Targeting
  target_segment VARCHAR(50),
  minimum_tier_id INT REFERENCES loyalty_tiers(id),

  -- Status
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,

  -- Metadata
  created_by UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Track coupon usage
CREATE TABLE IF NOT EXISTS coupon_usage (
  id SERIAL PRIMARY KEY,
  coupon_id INT REFERENCES coupons(id) ON DELETE CASCADE,
  customer_id INT,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  discount_amount DECIMAL(10,2) NOT NULL,
  used_at TIMESTAMP DEFAULT NOW()
);

-- Add foreign key constraint after customers table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customers') THEN
    ALTER TABLE coupon_usage
    ADD CONSTRAINT fk_coupon_usage_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE;
  END IF;
END $$;

-- =====================================================
-- 3. PUSH NOTIFICATIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS push_notifications (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id) ON DELETE CASCADE,

  -- Content
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  image_url VARCHAR(500),
  action_url VARCHAR(500),

  -- Targeting
  target_segment VARCHAR(50),
  target_customer_ids INT[],
  target_tier_ids INT[],

  -- Scheduling
  scheduled_for TIMESTAMP,
  send_immediately BOOLEAN DEFAULT false,

  -- Status
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'failed')),
  sent_at TIMESTAMP,

  -- Analytics
  recipients_count INT DEFAULT 0,
  delivered_count INT DEFAULT 0,
  opened_count INT DEFAULT 0,
  clicked_count INT DEFAULT 0,

  -- Metadata
  created_by UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Individual notification deliveries
CREATE TABLE IF NOT EXISTS notification_deliveries (
  id SERIAL PRIMARY KEY,
  notification_id INT REFERENCES push_notifications(id) ON DELETE CASCADE,
  customer_id INT,
  device_token VARCHAR(500),

  -- Status
  delivery_status VARCHAR(20) CHECK (delivery_status IN ('sent', 'delivered', 'opened', 'clicked', 'failed')),

  -- Timestamps
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  opened_at TIMESTAMP,
  clicked_at TIMESTAMP,

  -- Error tracking
  error_message TEXT,

  created_at TIMESTAMP DEFAULT NOW()
);

-- Add foreign key constraint after customers table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customers') THEN
    ALTER TABLE notification_deliveries
    ADD CONSTRAINT fk_notification_deliveries_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE;
  END IF;
END $$;

-- =====================================================
-- 4. REFERRAL PROGRAM
-- =====================================================

CREATE TABLE IF NOT EXISTS referral_program (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id) ON DELETE CASCADE,

  -- Rewards
  referrer_reward_type VARCHAR(20) CHECK (referrer_reward_type IN ('points', 'credit', 'coupon')),
  referrer_reward_value DECIMAL(10,2),
  referee_reward_type VARCHAR(20) CHECK (referee_reward_type IN ('points', 'credit', 'coupon')),
  referee_reward_value DECIMAL(10,2),

  -- Conditions
  min_order_value DECIMAL(10,2) DEFAULT 0,
  max_referrals_per_customer INT,

  -- Status
  is_active BOOLEAN DEFAULT true,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS referrals (
  id SERIAL PRIMARY KEY,
  program_id INT REFERENCES referral_program(id) ON DELETE CASCADE,

  -- Participants
  referrer_customer_id INT,
  referee_customer_id INT,

  -- Referral Details
  referral_code VARCHAR(50) UNIQUE NOT NULL,

  -- Status
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'rewarded', 'expired')),

  -- Rewards
  referrer_rewarded BOOLEAN DEFAULT false,
  referee_rewarded BOOLEAN DEFAULT false,
  referrer_reward_order_id UUID REFERENCES orders(id),
  referee_first_order_id UUID REFERENCES orders(id),

  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  rewarded_at TIMESTAMP
);

-- Add foreign key constraints after customers table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customers') THEN
    ALTER TABLE referrals
    ADD CONSTRAINT fk_referrals_referrer
    FOREIGN KEY (referrer_customer_id) REFERENCES customers(id) ON DELETE CASCADE;

    ALTER TABLE referrals
    ADD CONSTRAINT fk_referrals_referee
    FOREIGN KEY (referee_customer_id) REFERENCES customers(id) ON DELETE CASCADE;
  END IF;
END $$;

-- =====================================================
-- 5. AUTOMATED CAMPAIGNS
-- =====================================================

CREATE TABLE IF NOT EXISTS automated_campaigns (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id) ON DELETE CASCADE,

  -- Campaign Info
  name VARCHAR(200) NOT NULL,
  description TEXT,
  campaign_type VARCHAR(50) CHECK (campaign_type IN ('welcome_series', 'win_back', 'birthday', 'abandoned_cart', 'order_reminder')),

  -- Trigger Conditions
  trigger_event VARCHAR(100),
  trigger_delay_hours INT DEFAULT 0,
  trigger_condition JSONB,

  -- Message Content
  notification_title VARCHAR(200),
  notification_body TEXT,
  coupon_id INT REFERENCES coupons(id),

  -- Status
  is_active BOOLEAN DEFAULT true,

  -- Analytics
  total_triggered INT DEFAULT 0,
  total_converted INT DEFAULT 0,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS campaign_executions (
  id SERIAL PRIMARY KEY,
  campaign_id INT REFERENCES automated_campaigns(id) ON DELETE CASCADE,
  customer_id INT,

  -- Execution
  triggered_at TIMESTAMP DEFAULT NOW(),
  notification_id INT REFERENCES push_notifications(id),

  -- Outcome
  converted BOOLEAN DEFAULT false,
  conversion_order_id UUID REFERENCES orders(id),
  converted_at TIMESTAMP
);

-- Add foreign key constraint after customers table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customers') THEN
    ALTER TABLE campaign_executions
    ADD CONSTRAINT fk_campaign_executions_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE;
  END IF;
END $$;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Coupons
CREATE INDEX IF NOT EXISTS idx_coupons_code ON coupons(code);
CREATE INDEX IF NOT EXISTS idx_coupons_store_active ON coupons(store_id, is_active);
CREATE INDEX IF NOT EXISTS idx_coupons_dates ON coupons(start_date, end_date);

-- Coupon Usage
CREATE INDEX IF NOT EXISTS idx_coupon_usage_customer ON coupon_usage(customer_id);
CREATE INDEX IF NOT EXISTS idx_coupon_usage_coupon ON coupon_usage(coupon_id);

-- Loyalty
CREATE INDEX IF NOT EXISTS idx_customer_loyalty_customer ON customer_loyalty(customer_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_customer ON loyalty_transactions(customer_loyalty_id);

-- Notifications
CREATE INDEX IF NOT EXISTS idx_notifications_store_status ON push_notifications(store_id, status);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled ON push_notifications(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_notification_deliveries_notification ON notification_deliveries(notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_deliveries_customer ON notification_deliveries(customer_id);

-- Referrals
CREATE INDEX IF NOT EXISTS idx_referrals_code ON referrals(referral_code);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_customer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referee ON referrals(referee_customer_id);

-- =====================================================
-- SEED DATA - Jay's Deli Loyalty Program
-- =====================================================

-- Create loyalty program for Jay's Deli (store_id = 1)
INSERT INTO loyalty_programs (store_id, name, points_per_dollar, welcome_bonus_points, referral_bonus_points, is_active)
VALUES (1, 'Jay''s Deli Rewards', 1.00, 100, 500, true)
ON CONFLICT DO NOTHING;

-- Create loyalty tiers
INSERT INTO loyalty_tiers (program_id, name, min_points, discount_percentage, free_delivery, priority_support, early_access_promos, birthday_reward_points, tier_color, sort_order)
VALUES
  (1, 'Bronze', 0, 0, false, false, false, 0, '#CD7F32', 1),
  (1, 'Silver', 500, 5, false, false, false, 50, '#C0C0C0', 2),
  (1, 'Gold', 2000, 10, true, false, true, 100, '#FFD700', 3),
  (1, 'Platinum', 5000, 15, true, true, true, 200, '#E5E4E2', 4)
ON CONFLICT DO NOTHING;

-- Create welcome coupon
INSERT INTO coupons (
  store_id, code, name, description,
  discount_type, discount_value,
  min_order_value, max_uses_per_customer,
  start_date, end_date,
  target_segment, first_order_only,
  is_active, is_featured,
  created_by
)
VALUES (
  1, 'WELCOME15', 'Welcome Discount', 'Get 15% off your first order!',
  'percentage', 15.00,
  0, 1,
  NOW(), NOW() + INTERVAL '1 year',
  'new_customers', true,
  true, true,
  NULL
)
ON CONFLICT (code) DO NOTHING;

-- Create minimum order coupon
INSERT INTO coupons (
  store_id, code, name, description,
  discount_type, discount_value,
  min_order_value, max_uses_per_customer,
  start_date, end_date,
  target_segment, first_order_only,
  is_active, is_featured,
  created_by
)
VALUES (
  1, 'SAVE5', '$5 Off $30+', 'Save $5 on orders $30 or more',
  'fixed_amount', 5.00,
  30.00, 5,
  NOW(), NOW() + INTERVAL '1 year',
  'all', false,
  true, true,
  NULL
)
ON CONFLICT (code) DO NOTHING;

-- Create happy hour coupon
INSERT INTO coupons (
  store_id, code, name, description,
  discount_type, discount_value,
  min_order_value, max_uses_per_customer,
  start_date, end_date,
  active_days_of_week, active_hours_start, active_hours_end,
  target_segment, first_order_only,
  is_active, is_featured,
  created_by
)
VALUES (
  1, 'HAPPYHOUR', 'Happy Hour Special', '20% off orders between 2-5pm weekdays',
  'percentage', 20.00,
  0, 1,
  NOW(), NOW() + INTERVAL '1 year',
  ARRAY[1,2,3,4,5], '14:00', '17:00',
  'all', false,
  true, false,
  NULL
)
ON CONFLICT (code) DO NOTHING;

-- Create referral program for Jay's Deli
INSERT INTO referral_program (
  store_id,
  referrer_reward_type, referrer_reward_value,
  referee_reward_type, referee_reward_value,
  min_order_value,
  is_active
)
VALUES (
  1,
  'credit', 10.00,
  'credit', 10.00,
  15.00,
  true
)
ON CONFLICT DO NOTHING;

-- Create automated win-back campaign
INSERT INTO automated_campaigns (
  store_id, name, description, campaign_type,
  trigger_event, trigger_delay_hours, trigger_condition,
  notification_title, notification_body,
  is_active
)
VALUES (
  1,
  'Win-Back Campaign',
  'Re-engage customers who haven''t ordered in 14 days',
  'win_back',
  'days_since_order',
  336, -- 14 days * 24 hours
  '{"days_inactive": 14, "min_past_orders": 1}',
  'We Miss You! 🍔',
  'It''s been a while! Come back and enjoy 20% off your next order with code COMEBACK20',
  true
)
ON CONFLICT DO NOTHING;

-- =====================================================
-- GRANT PERMISSIONS (if using RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE loyalty_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_loyalty ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupon_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_program ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE automated_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_executions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to allow re-running migration
DROP POLICY IF EXISTS "Allow read active coupons" ON coupons;
DROP POLICY IF EXISTS "Allow staff to manage coupons" ON coupons;

-- Allow authenticated users to read active coupons
CREATE POLICY "Allow read active coupons" ON coupons
  FOR SELECT
  USING (is_active = true);

-- Allow authenticated users to read their own loyalty data (if customers table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customers') THEN
    EXECUTE 'CREATE POLICY "Allow read own loyalty" ON customer_loyalty
      FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM customers
          WHERE customers.id = customer_loyalty.customer_id
          AND customers.auth_user_id = auth.uid()
        )
      )';
  END IF;
END $$;

-- Allow staff to manage coupons
CREATE POLICY "Allow staff to manage coupons" ON coupons
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id::text = auth.uid()::text
      AND user_profiles.role IN ('super_admin', 'admin', 'manager')
    )
  );

-- =====================================================
-- DONE! Marketing tables created successfully
-- =====================================================
