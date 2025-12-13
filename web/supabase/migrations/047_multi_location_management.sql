-- Migration 047: Multi-Location Management System
-- Creates organization hierarchy, regions, and multi-store management

-- =============================================
-- 1. ORGANIZATIONS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  logo_url TEXT,
  primary_color VARCHAR(7) DEFAULT '#2196F3',
  secondary_color VARCHAR(7) DEFAULT '#FF8C42',
  owner_id UUID REFERENCES auth.users(id),
  subscription_tier VARCHAR(50) DEFAULT 'professional', -- starter, professional, business, enterprise, ultimate
  max_locations INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  settings JSONB DEFAULT '{
    "timezone": "America/New_York",
    "currency": "USD",
    "date_format": "MM/DD/YYYY",
    "allow_cross_store_orders": false,
    "unified_menu": false,
    "unified_rewards": true
  }'::jsonb,
  billing_email VARCHAR(255),
  billing_address JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 2. REGIONS TABLE (for grouping stores)
-- =============================================
CREATE TABLE IF NOT EXISTS regions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  manager_id UUID REFERENCES auth.users(id),
  color VARCHAR(7) DEFAULT '#2196F3',
  is_active BOOLEAN DEFAULT true,
  settings JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, name)
);

-- =============================================
-- 3. UPDATE STORES TABLE
-- =============================================
-- Add organization and region references to stores
ALTER TABLE stores
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id),
ADD COLUMN IF NOT EXISTS region_id UUID REFERENCES regions(id),
ADD COLUMN IF NOT EXISTS store_code VARCHAR(20),
ADD COLUMN IF NOT EXISTS manager_id UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS performance_score DECIMAL(3,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS monthly_revenue_target DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{}'::jsonb;

-- =============================================
-- 4. DAILY METRICS TABLE (for store performance)
-- =============================================
CREATE TABLE IF NOT EXISTS daily_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id INTEGER REFERENCES stores(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  total_orders INTEGER DEFAULT 0,
  total_revenue DECIMAL(10,2) DEFAULT 0,
  avg_order_value DECIMAL(10,2) DEFAULT 0,
  unique_customers INTEGER DEFAULT 0,
  new_customers INTEGER DEFAULT 0,
  returning_customers INTEGER DEFAULT 0,
  cancelled_orders INTEGER DEFAULT 0,
  avg_prep_time_minutes INTEGER,
  peak_hour INTEGER, -- 0-23
  popular_items JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, date)
);

-- =============================================
-- 5. HOURLY METRICS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS hourly_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id INTEGER REFERENCES stores(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  hour INTEGER NOT NULL CHECK (hour >= 0 AND hour <= 23),
  orders_count INTEGER DEFAULT 0,
  revenue DECIMAL(10,2) DEFAULT 0,
  avg_prep_time INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, date, hour)
);

-- =============================================
-- 6. STORE LEADERBOARD VIEW
-- =============================================
CREATE OR REPLACE VIEW store_leaderboard AS
SELECT
  s.id,
  s.name,
  s.store_code,
  r.name as region_name,
  COALESCE(dm.total_revenue, 0) as today_revenue,
  COALESCE(dm.total_orders, 0) as today_orders,
  COALESCE(dm.avg_order_value, 0) as avg_order_value,
  s.monthly_revenue_target,
  s.performance_score,
  CASE
    WHEN s.monthly_revenue_target > 0 THEN
      ROUND((COALESCE(dm.total_revenue, 0) / s.monthly_revenue_target) * 100, 1)
    ELSE 0
  END as target_progress,
  RANK() OVER (ORDER BY COALESCE(dm.total_revenue, 0) DESC) as revenue_rank
FROM stores s
LEFT JOIN regions r ON s.region_id = r.id
LEFT JOIN daily_metrics dm ON s.id = dm.store_id AND dm.date = CURRENT_DATE
WHERE s.is_active = true;

-- =============================================
-- 7. ORGANIZATION SUMMARY VIEW
-- =============================================
CREATE OR REPLACE VIEW organization_summary AS
SELECT
  o.id as organization_id,
  o.name as organization_name,
  COUNT(DISTINCT s.id) as total_stores,
  COUNT(DISTINCT r.id) as total_regions,
  COALESCE(SUM(dm.total_revenue), 0) as today_total_revenue,
  COALESCE(SUM(dm.total_orders), 0) as today_total_orders,
  COALESCE(AVG(dm.avg_order_value), 0) as avg_order_value,
  COALESCE(SUM(dm.unique_customers), 0) as today_unique_customers
FROM organizations o
LEFT JOIN stores s ON s.organization_id = o.id AND s.is_active = true
LEFT JOIN regions r ON r.organization_id = o.id AND r.is_active = true
LEFT JOIN daily_metrics dm ON s.id = dm.store_id AND dm.date = CURRENT_DATE
GROUP BY o.id, o.name;

-- =============================================
-- 8. REGION SUMMARY VIEW
-- =============================================
CREATE OR REPLACE VIEW region_summary AS
SELECT
  r.id as region_id,
  r.name as region_name,
  r.organization_id,
  COUNT(DISTINCT s.id) as store_count,
  COALESCE(SUM(dm.total_revenue), 0) as today_revenue,
  COALESCE(SUM(dm.total_orders), 0) as today_orders,
  COALESCE(AVG(dm.avg_order_value), 0) as avg_order_value,
  COALESCE(AVG(s.performance_score), 0) as avg_performance_score
FROM regions r
LEFT JOIN stores s ON s.region_id = r.id AND s.is_active = true
LEFT JOIN daily_metrics dm ON s.id = dm.store_id AND dm.date = CURRENT_DATE
WHERE r.is_active = true
GROUP BY r.id, r.name, r.organization_id;

-- =============================================
-- 9. UPDATE USER_PROFILES FOR MULTI-LOCATION
-- =============================================
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id),
ADD COLUMN IF NOT EXISTS region_ids UUID[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS is_regional_manager BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS is_org_admin BOOLEAN DEFAULT false;

-- =============================================
-- 10. RLS POLICIES
-- =============================================

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE hourly_metrics ENABLE ROW LEVEL SECURITY;

-- Organizations policies
DROP POLICY IF EXISTS "Organizations: owners and admins can view" ON organizations;
CREATE POLICY "Organizations: owners and admins can view" ON organizations
  FOR SELECT USING (
    owner_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND (organization_id = organizations.id OR is_system_admin = true)
    )
  );

DROP POLICY IF EXISTS "Organizations: owners can update" ON organizations;
CREATE POLICY "Organizations: owners can update" ON organizations
  FOR UPDATE USING (owner_id = auth.uid());

-- Regions policies
DROP POLICY IF EXISTS "Regions: org members can view" ON regions;
CREATE POLICY "Regions: org members can view" ON regions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND (organization_id = regions.organization_id OR is_system_admin = true)
    )
  );

DROP POLICY IF EXISTS "Regions: org admins can manage" ON regions;
CREATE POLICY "Regions: org admins can manage" ON regions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND organization_id = regions.organization_id
      AND (is_org_admin = true OR role IN ('super_admin', 'admin'))
    )
  );

-- Daily metrics policies
DROP POLICY IF EXISTS "Daily metrics: staff can view their store" ON daily_metrics;
CREATE POLICY "Daily metrics: staff can view their store" ON daily_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid()
      AND (
        up.is_system_admin = true OR
        up.store_id = daily_metrics.store_id OR
        daily_metrics.store_id = ANY(up.assigned_stores)
      )
    )
  );

-- Hourly metrics policies
DROP POLICY IF EXISTS "Hourly metrics: staff can view their store" ON hourly_metrics;
CREATE POLICY "Hourly metrics: staff can view their store" ON hourly_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid()
      AND (
        up.is_system_admin = true OR
        up.store_id = hourly_metrics.store_id OR
        hourly_metrics.store_id = ANY(up.assigned_stores)
      )
    )
  );

-- =============================================
-- 11. INDEXES FOR PERFORMANCE
-- =============================================
CREATE INDEX IF NOT EXISTS idx_stores_organization ON stores(organization_id);
CREATE INDEX IF NOT EXISTS idx_stores_region ON stores(region_id);
CREATE INDEX IF NOT EXISTS idx_regions_organization ON regions(organization_id);
CREATE INDEX IF NOT EXISTS idx_daily_metrics_store_date ON daily_metrics(store_id, date);
CREATE INDEX IF NOT EXISTS idx_hourly_metrics_store_date ON hourly_metrics(store_id, date, hour);
CREATE INDEX IF NOT EXISTS idx_user_profiles_organization ON user_profiles(organization_id);

-- =============================================
-- 12. SEED DEFAULT ORGANIZATION
-- =============================================
INSERT INTO organizations (name, slug, owner_id, subscription_tier, max_locations)
SELECT
  'Highland Mills Snack Shop Inc',
  'highland-mills',
  (SELECT id FROM user_profiles WHERE role = 'super_admin' LIMIT 1),
  'business',
  29
WHERE NOT EXISTS (SELECT 1 FROM organizations WHERE slug = 'highland-mills');

-- Link existing stores to organization
UPDATE stores
SET organization_id = (SELECT id FROM organizations WHERE slug = 'highland-mills' LIMIT 1)
WHERE organization_id IS NULL;

-- Link existing users to organization
UPDATE user_profiles
SET organization_id = (SELECT id FROM organizations WHERE slug = 'highland-mills' LIMIT 1)
WHERE organization_id IS NULL AND role != 'customer';

-- =============================================
-- 13. FUNCTION TO AGGREGATE DAILY METRICS
-- =============================================
CREATE OR REPLACE FUNCTION aggregate_daily_metrics(target_date DATE DEFAULT CURRENT_DATE)
RETURNS void AS $$
BEGIN
  INSERT INTO daily_metrics (store_id, date, total_orders, total_revenue, avg_order_value, unique_customers, cancelled_orders)
  SELECT
    o.store_id,
    target_date,
    COUNT(*) FILTER (WHERE o.status != 'cancelled'),
    COALESCE(SUM(o.total) FILTER (WHERE o.status != 'cancelled'), 0),
    COALESCE(AVG(o.total) FILTER (WHERE o.status != 'cancelled'), 0),
    COUNT(DISTINCT o.customer_email),
    COUNT(*) FILTER (WHERE o.status = 'cancelled')
  FROM orders o
  WHERE DATE(o.created_at) = target_date
  GROUP BY o.store_id
  ON CONFLICT (store_id, date)
  DO UPDATE SET
    total_orders = EXCLUDED.total_orders,
    total_revenue = EXCLUDED.total_revenue,
    avg_order_value = EXCLUDED.avg_order_value,
    unique_customers = EXCLUDED.unique_customers,
    cancelled_orders = EXCLUDED.cancelled_orders;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 14. UPDATED_AT TRIGGERS
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_regions_updated_at ON regions;
CREATE TRIGGER update_regions_updated_at
  BEFORE UPDATE ON regions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE organizations IS 'Multi-location organization hierarchy';
COMMENT ON TABLE regions IS 'Regional groupings of stores within an organization';
COMMENT ON TABLE daily_metrics IS 'Aggregated daily performance metrics per store';
COMMENT ON TABLE hourly_metrics IS 'Hourly breakdown of store performance';
