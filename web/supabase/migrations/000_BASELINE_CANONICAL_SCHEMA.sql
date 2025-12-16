-- =====================================================
-- CAMERON'S CONNECT - CANONICAL BASELINE SCHEMA
-- =====================================================
-- Version: 1.0
-- Date: 2025-12-02
--
-- WARNING:
-- This baseline schema is for NEW databases only.
-- In existing environments, migrations 001-061 have already been applied.
-- Do NOT run this file on production or existing staging DBs.
--
-- This file represents the CURRENT intended production schema after
-- all migrations (001-061) have been applied. Use it to bootstrap
-- new development environments or create fresh staging databases.
-- =====================================================

-- =====================================================
-- EXTENSIONS
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =====================================================
-- ============ SECTION 1: CORE ORDERING ============
-- =====================================================

-- =====================================================
-- 1.1 STORES TABLE (29 Cameron's locations)
-- =====================================================
CREATE TABLE IF NOT EXISTS stores (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL DEFAULT 'NY',
  zip TEXT NOT NULL,
  phone TEXT,
  hours TEXT DEFAULT 'Open 24/7',
  is_open BOOLEAN DEFAULT true,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  store_type TEXT CHECK (store_type IN ('snack_shop', 'fuel', 'deli', 'pizza', 'cigar_shop')),
  -- Multi-location fields (migration 047)
  organization_id UUID,
  region_id UUID,
  store_code VARCHAR(20),
  manager_id UUID,
  performance_score DECIMAL(3,2) DEFAULT 0,
  monthly_revenue_target DECIMAL(10,2),
  settings JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS stores_location_idx ON stores(latitude, longitude);
CREATE INDEX IF NOT EXISTS stores_city_idx ON stores(city);
CREATE INDEX IF NOT EXISTS idx_stores_organization ON stores(organization_id);
CREATE INDEX IF NOT EXISTS idx_stores_region ON stores(region_id);

-- =====================================================
-- 1.2 ORDERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number TEXT UNIQUE NOT NULL,
  customer_id UUID, -- Links to customers table
  user_id UUID,     -- Links to auth.users for backwards compatibility
  store_id BIGINT REFERENCES stores(id) NOT NULL,

  -- Customer info (captured at checkout)
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  customer_email TEXT,

  -- Order details
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled')
  ),
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('normal', 'express', 'vip')),

  -- Pricing
  subtotal DECIMAL(10, 2) NOT NULL,
  tax DECIMAL(10, 2) NOT NULL,
  tip DECIMAL(10, 2) DEFAULT 0,
  total DECIMAL(10, 2) NOT NULL,

  -- Fulfillment
  order_type TEXT DEFAULT 'pickup' CHECK (order_type IN ('pickup', 'delivery')),
  estimated_ready_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  special_instructions TEXT,

  -- Metadata
  is_repeat_customer BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS orders_store_idx ON orders(store_id);
CREATE INDEX IF NOT EXISTS orders_customer_idx ON orders(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS orders_status_idx ON orders(status);
CREATE INDEX IF NOT EXISTS orders_created_at_idx ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS orders_store_status_idx ON orders(store_id, status);
CREATE INDEX IF NOT EXISTS orders_number_idx ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_store_status_created ON orders(store_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_customer_email ON orders(customer_email) WHERE customer_email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_status_updated ON orders(status, updated_at DESC);

-- =====================================================
-- 1.3 ORDER ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS order_items (
  id BIGSERIAL PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id BIGINT,

  -- Snapshot data (preserved even if menu item deleted)
  item_name TEXT NOT NULL,
  item_price DECIMAL(10, 2) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,

  -- Customizations applied
  customizations JSONB DEFAULT '[]'::jsonb,
  customization_notes TEXT, -- Added for iOS compatibility

  subtotal DECIMAL(10, 2) NOT NULL,
  notes TEXT
);

CREATE INDEX IF NOT EXISTS order_items_order_idx ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON order_items(menu_item_id);

-- =====================================================
-- 1.4 ORDER STATUS HISTORY (audit trail)
-- =====================================================
CREATE TABLE IF NOT EXISTS order_status_history (
  id BIGSERIAL PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  previous_status TEXT,
  new_status TEXT NOT NULL,
  changed_by UUID,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS order_status_history_order_idx ON order_status_history(order_id);

-- =====================================================
-- ============ SECTION 2: MENU / CATALOG ============
-- =====================================================

-- =====================================================
-- 2.1 MENU CATEGORIES
-- =====================================================
CREATE TABLE IF NOT EXISTS menu_categories (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS menu_categories_order_idx ON menu_categories(display_order);

-- =====================================================
-- 2.2 MENU ITEMS
-- =====================================================
CREATE TABLE IF NOT EXISTS menu_items (
  id BIGSERIAL PRIMARY KEY,
  category_id BIGINT REFERENCES menu_categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  base_price DECIMAL(10, 2) NOT NULL,
  price DECIMAL(10, 2), -- Added for iOS compatibility (mirrors base_price)
  image_url TEXT,
  is_available BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  preparation_time INTEGER DEFAULT 15,
  calories INTEGER,
  allergens TEXT[],
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS menu_items_category_idx ON menu_items(category_id);
CREATE INDEX IF NOT EXISTS menu_items_featured_idx ON menu_items(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS menu_items_available_idx ON menu_items(is_available) WHERE is_available = true;
CREATE INDEX IF NOT EXISTS idx_menu_items_category_available ON menu_items(category_id, is_available) WHERE is_available = true;

-- =====================================================
-- 2.3 MENU ITEM CUSTOMIZATIONS (Portion-based)
-- =====================================================
CREATE TABLE IF NOT EXISTS menu_item_customizations (
  id BIGSERIAL PRIMARY KEY,
  menu_item_id BIGINT REFERENCES menu_items(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT CHECK (type IN ('single', 'multiple')) DEFAULT 'single',
  options JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_required BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  -- Portion-based fields (migration 042)
  supports_portions BOOLEAN DEFAULT false,
  portion_pricing JSONB DEFAULT '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb,
  default_portion TEXT DEFAULT 'regular',
  category TEXT
);

CREATE INDEX IF NOT EXISTS menu_customizations_item_idx ON menu_item_customizations(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_customizations_item_portions ON menu_item_customizations(menu_item_id, supports_portions) WHERE supports_portions = true;
CREATE INDEX IF NOT EXISTS idx_customizations_category ON menu_item_customizations(category);

-- =====================================================
-- 2.4 INGREDIENT TEMPLATES (Reusable ingredients)
-- =====================================================
CREATE TABLE IF NOT EXISTS ingredient_templates (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  supports_portions BOOLEAN DEFAULT true,
  portion_pricing JSONB DEFAULT '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb,
  default_portion TEXT DEFAULT 'regular',
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ingredient_templates_category_idx ON ingredient_templates(category);
CREATE INDEX IF NOT EXISTS ingredient_templates_active_idx ON ingredient_templates(is_active) WHERE is_active = true;

-- =====================================================
-- 2.5 STORE MENU ITEMS (per-store pricing - historical)
-- Note: Currently unused but kept for future multi-location menu support
-- =====================================================
CREATE TABLE IF NOT EXISTS store_menu_items (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  menu_item_id BIGINT REFERENCES menu_items(id) ON DELETE CASCADE,
  is_available BOOLEAN DEFAULT true,
  custom_price DECIMAL(10, 2),
  UNIQUE(store_id, menu_item_id)
);

-- =====================================================
-- ============ SECTION 3: CUSTOMERS & REWARDS ============
-- =====================================================

-- =====================================================
-- 3.1 CUSTOMERS TABLE (separate from business users)
-- =====================================================
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT,
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone) WHERE phone IS NOT NULL;

-- =====================================================
-- 3.2 CUSTOMER REWARDS
-- =====================================================
CREATE TABLE IF NOT EXISTS customer_rewards (
  id BIGSERIAL PRIMARY KEY,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  points INTEGER DEFAULT 0,
  lifetime_points INTEGER DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  total_spent DECIMAL(10, 2) DEFAULT 0,
  tier VARCHAR(20) DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS customer_rewards_customer_idx ON customer_rewards(customer_id);
CREATE INDEX IF NOT EXISTS customer_rewards_tier_idx ON customer_rewards(tier);
CREATE INDEX IF NOT EXISTS idx_customer_rewards_tier ON customer_rewards(tier);

-- =====================================================
-- 3.3 REWARDS TRANSACTIONS
-- =====================================================
CREATE TABLE IF NOT EXISTS rewards_transactions (
  id BIGSERIAL PRIMARY KEY,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  points_change INTEGER NOT NULL,
  transaction_type TEXT CHECK (transaction_type IN ('earned', 'redeemed', 'expired', 'bonus')),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS rewards_transactions_customer_idx ON rewards_transactions(customer_id);
CREATE INDEX IF NOT EXISTS rewards_transactions_created_idx ON rewards_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rewards_transactions_customer ON rewards_transactions(customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rewards_transactions_order ON rewards_transactions(order_id) WHERE order_id IS NOT NULL;

-- =====================================================
-- 3.4 CUSTOMER FAVORITES
-- =====================================================
CREATE TABLE IF NOT EXISTS customer_favorites (
  id BIGSERIAL PRIMARY KEY,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  menu_item_id BIGINT REFERENCES menu_items(id) ON DELETE CASCADE,
  customizations JSONB DEFAULT '{}'::jsonb,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id, menu_item_id)
);

CREATE INDEX IF NOT EXISTS customer_favorites_customer_idx ON customer_favorites(customer_id);

-- =====================================================
-- ============ SECTION 4: ORG/REGIONS & STORES ============
-- =====================================================

-- =====================================================
-- 4.1 ORGANIZATIONS (Multi-location hierarchy)
-- =====================================================
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  logo_url TEXT,
  primary_color VARCHAR(7) DEFAULT '#2196F3',
  secondary_color VARCHAR(7) DEFAULT '#FF8C42',
  owner_id UUID,
  subscription_tier VARCHAR(50) DEFAULT 'professional',
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

-- Add FK after stores table exists
ALTER TABLE stores
ADD CONSTRAINT fk_stores_organization
FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL;

-- =====================================================
-- 4.2 REGIONS (Store groupings)
-- =====================================================
CREATE TABLE IF NOT EXISTS regions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  manager_id UUID,
  color VARCHAR(7) DEFAULT '#2196F3',
  is_active BOOLEAN DEFAULT true,
  settings JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, name)
);

CREATE INDEX IF NOT EXISTS idx_regions_organization ON regions(organization_id);

-- Add FK for stores.region_id
ALTER TABLE stores
ADD CONSTRAINT fk_stores_region
FOREIGN KEY (region_id) REFERENCES regions(id) ON DELETE SET NULL;

-- =====================================================
-- ============ SECTION 5: USER PROFILES & AUTH ============
-- =====================================================

-- =====================================================
-- 5.1 USER PROFILES (Business users only)
-- =====================================================
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('super_admin', 'admin', 'manager', 'staff', 'customer')) DEFAULT 'customer',
  full_name TEXT NOT NULL,
  phone TEXT,
  store_id BIGINT REFERENCES stores(id),
  assigned_stores INT[] DEFAULT '{}',
  permissions JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT true,
  is_system_admin BOOLEAN DEFAULT false,
  avatar_url TEXT,
  -- Multi-location fields (migration 047)
  organization_id UUID REFERENCES organizations(id),
  region_ids UUID[] DEFAULT '{}',
  is_regional_manager BOOLEAN DEFAULT false,
  is_org_admin BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS user_profiles_role_idx ON user_profiles(role);
CREATE INDEX IF NOT EXISTS user_profiles_store_idx ON user_profiles(store_id) WHERE store_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_profiles_store_role ON user_profiles(store_id, role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_assigned_stores ON user_profiles USING GIN (assigned_stores);
CREATE INDEX IF NOT EXISTS idx_user_profiles_active ON user_profiles(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_user_profiles_organization ON user_profiles(organization_id);

-- =====================================================
-- 5.2 STORE ASSIGNMENTS (Multi-store access)
-- =====================================================
CREATE TABLE IF NOT EXISTS store_assignments (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  assigned_by UUID,
  UNIQUE(user_id, store_id)
);

CREATE INDEX IF NOT EXISTS idx_store_assignments_user ON store_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_store_assignments_store ON store_assignments(store_id);

-- =====================================================
-- 5.3 PERMISSION CHANGES (Audit trail)
-- =====================================================
CREATE TABLE IF NOT EXISTS permission_changes (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  changed_by UUID,
  change_type TEXT NOT NULL,
  previous_value JSONB,
  new_value JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_permission_changes_user ON permission_changes(user_id);
CREATE INDEX IF NOT EXISTS idx_permission_changes_created ON permission_changes(created_at DESC);

-- =====================================================
-- ============ SECTION 6: ANALYTICS ============
-- =====================================================

-- =====================================================
-- 6.1 DAILY ANALYTICS (Legacy - historical aggregates)
-- =====================================================
CREATE TABLE IF NOT EXISTS daily_analytics (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  total_orders INTEGER DEFAULT 0,
  total_revenue DECIMAL(10, 2) DEFAULT 0,
  average_order_value DECIMAL(10, 2) DEFAULT 0,
  new_customers INTEGER DEFAULT 0,
  top_items JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, date)
);

CREATE INDEX IF NOT EXISTS daily_analytics_store_date_idx ON daily_analytics(store_id, date DESC);

-- =====================================================
-- 6.2 DAILY METRICS (Multi-location analytics)
-- =====================================================
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
  peak_hour INTEGER,
  popular_items JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, date)
);

CREATE INDEX IF NOT EXISTS idx_daily_metrics_store_date ON daily_metrics(store_id, date);

-- =====================================================
-- 6.3 HOURLY METRICS
-- =====================================================
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

CREATE INDEX IF NOT EXISTS idx_hourly_metrics_store_date ON hourly_metrics(store_id, date, hour);

-- =====================================================
-- ============ SECTION 7: MATERIALIZED VIEWS ============
-- =====================================================

-- =====================================================
-- 7.1 Popular Items View
-- =====================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_popular_items AS
SELECT
  oi.menu_item_id,
  mi.name AS item_name,
  mi.category_id,
  o.store_id,
  COUNT(*) AS order_count,
  SUM(oi.quantity) AS total_quantity,
  SUM(mi.price * oi.quantity) AS total_revenue,
  DATE_TRUNC('day', o.created_at) AS order_date
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
JOIN menu_items mi ON mi.id = oi.menu_item_id
WHERE o.status IN ('completed', 'ready', 'preparing')
  AND o.created_at >= NOW() - INTERVAL '90 days'
GROUP BY oi.menu_item_id, mi.name, mi.category_id, o.store_id, DATE_TRUNC('day', o.created_at);

CREATE UNIQUE INDEX IF NOT EXISTS mv_popular_items_unique_idx ON mv_popular_items (menu_item_id, store_id, order_date);
CREATE INDEX IF NOT EXISTS mv_popular_items_store_idx ON mv_popular_items (store_id);
CREATE INDEX IF NOT EXISTS mv_popular_items_category_idx ON mv_popular_items (category_id);

-- =====================================================
-- 7.2 Top Customers View
-- =====================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_top_customers AS
SELECT
  COALESCE(o.customer_id, o.user_id) AS customer_identifier,
  o.customer_email,
  o.customer_name,
  o.store_id,
  COUNT(DISTINCT o.id) AS total_orders,
  SUM(o.total) AS lifetime_value,
  AVG(o.total) AS average_order_value,
  MAX(o.created_at) AS last_order_date,
  MIN(o.created_at) AS first_order_date
FROM orders o
WHERE o.status IN ('completed', 'ready')
  AND o.total > 0
  AND (o.customer_email IS NOT NULL OR o.customer_id IS NOT NULL OR o.user_id IS NOT NULL)
GROUP BY COALESCE(o.customer_id, o.user_id), o.customer_email, o.customer_name, o.store_id;

CREATE UNIQUE INDEX IF NOT EXISTS mv_top_customers_unique_idx ON mv_top_customers (customer_identifier, customer_email, store_id);
CREATE INDEX IF NOT EXISTS mv_top_customers_store_idx ON mv_top_customers (store_id);
CREATE INDEX IF NOT EXISTS mv_top_customers_ltv_idx ON mv_top_customers (lifetime_value DESC);

-- =====================================================
-- 7.3 Store Daily Summary View
-- =====================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_store_daily_summary AS
SELECT
  o.store_id,
  DATE_TRUNC('day', o.created_at) AS summary_date,
  COUNT(*) AS total_orders,
  COUNT(*) FILTER (WHERE o.status = 'completed') AS completed_orders,
  COUNT(*) FILTER (WHERE o.status = 'cancelled') AS cancelled_orders,
  SUM(o.total) AS gross_revenue,
  SUM(o.total) FILTER (WHERE o.status IN ('completed', 'ready')) AS net_revenue,
  AVG(o.total) AS average_order_value,
  COUNT(DISTINCT COALESCE(o.customer_id::TEXT, o.customer_email)) AS unique_customers,
  MIN(o.created_at) AS first_order_time,
  MAX(o.created_at) AS last_order_time
FROM orders o
WHERE o.created_at >= NOW() - INTERVAL '365 days'
GROUP BY o.store_id, DATE_TRUNC('day', o.created_at);

CREATE UNIQUE INDEX IF NOT EXISTS mv_store_daily_summary_unique_idx ON mv_store_daily_summary (store_id, summary_date);
CREATE INDEX IF NOT EXISTS mv_store_daily_summary_date_idx ON mv_store_daily_summary (summary_date DESC);

-- =====================================================
-- 7.4 Hourly Traffic View
-- =====================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_hourly_traffic AS
SELECT
  o.store_id,
  EXTRACT(DOW FROM o.created_at) AS day_of_week,
  EXTRACT(HOUR FROM o.created_at) AS hour_of_day,
  COUNT(*) AS order_count,
  AVG(o.total) AS average_order_value,
  SUM(o.total) AS total_revenue
FROM orders o
WHERE o.status IN ('completed', 'ready', 'preparing')
  AND o.created_at >= NOW() - INTERVAL '90 days'
GROUP BY o.store_id, EXTRACT(DOW FROM o.created_at), EXTRACT(HOUR FROM o.created_at);

CREATE UNIQUE INDEX IF NOT EXISTS mv_hourly_traffic_unique_idx ON mv_hourly_traffic (store_id, day_of_week, hour_of_day);

-- =====================================================
-- 7.5 Organization Summary View
-- =====================================================
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
WHERE s.is_open = true;

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
LEFT JOIN stores s ON s.organization_id = o.id AND s.is_open = true
LEFT JOIN regions r ON r.organization_id = o.id AND r.is_active = true
LEFT JOIN daily_metrics dm ON s.id = dm.store_id AND dm.date = CURRENT_DATE
GROUP BY o.id, o.name;

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
LEFT JOIN stores s ON s.region_id = r.id AND s.is_open = true
LEFT JOIN daily_metrics dm ON s.id = dm.store_id AND dm.date = CURRENT_DATE
WHERE r.is_active = true
GROUP BY r.id, r.name, r.organization_id;

-- =====================================================
-- ============ SECTION 8: HELPER FUNCTIONS ============
-- =====================================================

-- =====================================================
-- 8.1 Core Auth Helper Functions (SECURITY DEFINER)
-- =====================================================

-- Get current user's role
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role
  FROM public.user_profiles
  WHERE id = auth.uid();
  RETURN COALESCE(user_role, 'customer');
END;
$$;

-- Check if current user is system admin
CREATE OR REPLACE FUNCTION public.is_current_user_system_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  is_admin BOOLEAN;
BEGIN
  SELECT COALESCE(is_system_admin, FALSE) INTO is_admin
  FROM public.user_profiles
  WHERE id = auth.uid();
  RETURN COALESCE(is_admin, FALSE);
END;
$$;

-- Get current user's assigned stores
CREATE OR REPLACE FUNCTION public.get_current_user_assigned_stores()
RETURNS INT[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  stores INT[];
BEGIN
  SELECT COALESCE(assigned_stores, ARRAY[]::INT[]) INTO stores
  FROM public.user_profiles
  WHERE id = auth.uid();
  RETURN COALESCE(stores, ARRAY[]::INT[]);
END;
$$;

-- Get current user's store_id
CREATE OR REPLACE FUNCTION public.get_current_user_store_id()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_store_id INT;
BEGIN
  SELECT store_id INTO user_store_id
  FROM public.user_profiles
  WHERE id = auth.uid();
  RETURN user_store_id;
END;
$$;

-- =====================================================
-- 8.2 Analytics Helper Functions (SECURITY DEFINER)
-- =====================================================

-- Check if user can access analytics for a store
CREATE OR REPLACE FUNCTION public.can_access_analytics(target_store_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_role TEXT;
  user_stores INT[];
  is_admin BOOLEAN;
BEGIN
  SELECT role, assigned_stores, COALESCE(is_system_admin, FALSE)
  INTO user_role, user_stores, is_admin
  FROM public.user_profiles
  WHERE id = auth.uid();

  -- System admins can access all
  IF is_admin THEN
    RETURN TRUE;
  END IF;

  -- Check if store is in user's assigned stores
  IF target_store_id = ANY(COALESCE(user_stores, ARRAY[]::INT[])) THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$;

-- =====================================================
-- 8.3 Materialized View Refresh Function
-- =====================================================

CREATE OR REPLACE FUNCTION refresh_analytics_materialized_views()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_popular_items;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_top_customers;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_store_daily_summary;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_hourly_traffic;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8.4 Daily Metrics Aggregation Function
-- =====================================================

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

-- =====================================================
-- ============ SECTION 9: TRIGGERS ============
-- =====================================================

-- =====================================================
-- 9.1 Updated_at Trigger Function
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER stores_updated_at BEFORE UPDATE ON stores
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER user_profiles_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER menu_items_updated_at BEFORE UPDATE ON menu_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER orders_updated_at BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER customer_rewards_updated_at BEFORE UPDATE ON customer_rewards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER customers_updated_at BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER organizations_updated_at BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER regions_updated_at BEFORE UPDATE ON regions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- 9.2 Order Number Generation
-- =====================================================

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

CREATE TRIGGER orders_generate_number BEFORE INSERT ON orders
  FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- =====================================================
-- 9.3 Order Status History Tracking
-- =====================================================

CREATE OR REPLACE FUNCTION track_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO order_status_history (order_id, previous_status, new_status, changed_by)
    VALUES (NEW.id, OLD.status, NEW.status, auth.uid());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_track_status AFTER UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION track_order_status_change();

-- =====================================================
-- 9.4 Rewards Calculation
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_order_rewards()
RETURNS TRIGGER AS $$
DECLARE
  points_earned INTEGER;
BEGIN
  -- Only award points for completed orders with a customer_id
  IF NEW.status = 'completed' AND NEW.customer_id IS NOT NULL AND
     (OLD IS NULL OR OLD.status != 'completed') THEN

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

CREATE TRIGGER orders_calculate_rewards AFTER INSERT OR UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION calculate_order_rewards();

-- =====================================================
-- 9.5 New User Handler (Creates customer profile)
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

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- ============ SECTION 10: RLS POLICIES ============
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_item_customizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredient_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE permission_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE hourly_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_analytics ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 10.1 Stores Policies
-- =====================================================

CREATE POLICY "stores_select_public" ON stores
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "stores_modify_admin" ON stores
  FOR ALL TO authenticated
  USING (public.is_current_user_system_admin())
  WITH CHECK (public.is_current_user_system_admin());

-- =====================================================
-- 10.2 Menu Policies (Public read)
-- =====================================================

CREATE POLICY "menu_categories_public_read" ON menu_categories
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "menu_items_public_read" ON menu_items
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "menu_customizations_public_read" ON menu_item_customizations
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Active templates viewable by all" ON ingredient_templates
  FOR SELECT USING (is_active = true);

CREATE POLICY "Staff can manage templates" ON ingredient_templates
  FOR ALL TO authenticated
  USING (public.get_current_user_role() IN ('super_admin', 'admin', 'manager'));

-- =====================================================
-- 10.3 Orders Policies (Guest checkout + Staff access)
-- =====================================================

CREATE POLICY "orders_insert_public" ON orders
  FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "orders_update_status" ON orders
  FOR UPDATE TO anon, authenticated
  USING (true) WITH CHECK (true);

CREATE POLICY "orders_select_customer" ON orders
  FOR SELECT TO authenticated
  USING (
    customer_id = (SELECT auth.uid())
    OR customer_email = (SELECT email FROM auth.users WHERE id = (SELECT auth.uid()))
  );

CREATE POLICY "orders_select_anon" ON orders
  FOR SELECT TO anon USING (true);

CREATE POLICY "orders_select_staff" ON orders
  FOR SELECT TO authenticated
  USING (
    public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff')
    AND (
      public.is_current_user_system_admin()
      OR store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

-- =====================================================
-- 10.4 Order Items Policies
-- =====================================================

CREATE POLICY "order_items_public_read" ON order_items
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "order_items_insert_public" ON order_items
  FOR INSERT TO anon, authenticated WITH CHECK (true);

-- =====================================================
-- 10.5 User Profiles Policies (Consolidated)
-- =====================================================

CREATE POLICY "select_user_profiles" ON user_profiles
  FOR SELECT TO authenticated
  USING (
    id = (SELECT auth.uid())
    OR public.is_current_user_system_admin()
    OR (
      public.get_current_user_role() IN ('admin', 'manager', 'staff')
      AND (
        store_id = ANY(public.get_current_user_assigned_stores())
        OR assigned_stores && public.get_current_user_assigned_stores()
      )
    )
  );

CREATE POLICY "insert_user_profiles" ON user_profiles
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_current_user_system_admin()
    OR (
      public.get_current_user_role() = 'admin'
      AND role IN ('manager', 'staff')
      AND store_id = ANY(public.get_current_user_assigned_stores())
    )
    OR (
      public.get_current_user_role() = 'manager'
      AND role = 'staff'
      AND store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

CREATE POLICY "update_user_profiles" ON user_profiles
  FOR UPDATE TO authenticated
  USING (
    id = (SELECT auth.uid())
    OR public.is_current_user_system_admin()
    OR (
      public.get_current_user_role() = 'admin'
      AND role IN ('manager', 'staff')
      AND store_id = ANY(public.get_current_user_assigned_stores())
    )
    OR (
      public.get_current_user_role() = 'manager'
      AND role = 'staff'
      AND store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

CREATE POLICY "delete_user_profiles" ON user_profiles
  FOR DELETE TO authenticated
  USING (
    public.is_current_user_system_admin()
    OR (
      public.get_current_user_role() = 'admin'
      AND role IN ('manager', 'staff')
      AND store_id = ANY(public.get_current_user_assigned_stores())
    )
    OR (
      public.get_current_user_role() = 'manager'
      AND role = 'staff'
      AND store_id = ANY(public.get_current_user_assigned_stores())
    )
  );

-- =====================================================
-- 10.6 Customers Policies
-- =====================================================

CREATE POLICY "customers_view_own" ON customers
  FOR SELECT TO authenticated USING (id = auth.uid());

CREATE POLICY "customers_update_own" ON customers
  FOR UPDATE TO authenticated
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY "public_insert_customers" ON customers
  FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "staff_view_customers" ON customers
  FOR SELECT TO authenticated
  USING (public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff'));

-- =====================================================
-- 10.7 Rewards Policies
-- =====================================================

CREATE POLICY "Customers can view their own rewards" ON customer_rewards
  FOR SELECT TO authenticated USING (customer_id = (SELECT auth.uid()));

CREATE POLICY "Staff can view all rewards" ON customer_rewards
  FOR SELECT TO authenticated
  USING (public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff'));

CREATE POLICY "Customers can view their own transactions" ON rewards_transactions
  FOR SELECT TO authenticated USING (customer_id = (SELECT auth.uid()));

CREATE POLICY "Staff can view all transactions" ON rewards_transactions
  FOR SELECT TO authenticated
  USING (public.get_current_user_role() IN ('super_admin', 'admin', 'manager', 'staff'));

-- =====================================================
-- 10.8 Organization/Region Policies
-- =====================================================

CREATE POLICY "Organizations: members can view" ON organizations
  FOR SELECT TO authenticated
  USING (
    owner_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND (organization_id = organizations.id OR is_system_admin = true)
    )
  );

CREATE POLICY "Organizations: owners can update" ON organizations
  FOR UPDATE USING (owner_id = auth.uid());

CREATE POLICY "Regions: org members can view" ON regions
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND (organization_id = regions.organization_id OR is_system_admin = true)
    )
  );

-- =====================================================
-- 10.9 Analytics Policies
-- =====================================================

CREATE POLICY "Daily metrics: staff can view their store" ON daily_metrics
  FOR SELECT TO authenticated
  USING (
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

CREATE POLICY "Hourly metrics: staff can view their store" ON hourly_metrics
  FOR SELECT TO authenticated
  USING (
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

-- =====================================================
-- ============ SECTION 11: GRANTS ============
-- =====================================================

-- Grant execute on helper functions
GRANT EXECUTE ON FUNCTION public.get_current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_current_user_system_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_assigned_stores() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_store_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_access_analytics(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.refresh_analytics_materialized_views() TO authenticated;

-- Grant select on materialized views
GRANT SELECT ON mv_popular_items TO authenticated;
GRANT SELECT ON mv_top_customers TO authenticated;
GRANT SELECT ON mv_store_daily_summary TO authenticated;
GRANT SELECT ON mv_hourly_traffic TO authenticated;

-- =====================================================
-- END OF CANONICAL BASELINE SCHEMA
-- =====================================================
