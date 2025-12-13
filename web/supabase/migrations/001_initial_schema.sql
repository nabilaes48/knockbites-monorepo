-- ============================================
-- CAMERON'S CONNECT - INITIAL DATABASE SCHEMA
-- ============================================
-- This migration sets up the complete database structure for
-- the multi-location food ordering platform

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- For geospatial queries

-- ============================================
-- STORES TABLE (29 locations)
-- ============================================
CREATE TABLE stores (
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
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for location-based queries
CREATE INDEX stores_location_idx ON stores(latitude, longitude);
CREATE INDEX stores_city_idx ON stores(city);

-- ============================================
-- USER PROFILES TABLE (extends auth.users)
-- ============================================
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('super_admin', 'admin', 'manager', 'staff', 'customer')) DEFAULT 'customer',
  full_name TEXT NOT NULL,
  phone TEXT,
  store_id BIGINT REFERENCES stores(id), -- NULL for super_admin and customers
  permissions JSONB DEFAULT '[]'::jsonb, -- Array of permission strings
  is_active BOOLEAN DEFAULT true,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX user_profiles_role_idx ON user_profiles(role);
CREATE INDEX user_profiles_store_idx ON user_profiles(store_id) WHERE store_id IS NOT NULL;

-- ============================================
-- MENU CATEGORIES
-- ============================================
CREATE TABLE menu_categories (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX menu_categories_order_idx ON menu_categories(display_order);

-- ============================================
-- MENU ITEMS
-- ============================================
CREATE TABLE menu_items (
  id BIGSERIAL PRIMARY KEY,
  category_id BIGINT REFERENCES menu_categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  base_price DECIMAL(10, 2) NOT NULL,
  image_url TEXT,
  is_available BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  preparation_time INTEGER DEFAULT 15, -- minutes
  calories INTEGER,
  allergens TEXT[], -- array of allergen names
  tags TEXT[], -- ['spicy', 'vegetarian', etc.]
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX menu_items_category_idx ON menu_items(category_id);
CREATE INDEX menu_items_featured_idx ON menu_items(is_featured) WHERE is_featured = true;
CREATE INDEX menu_items_available_idx ON menu_items(is_available) WHERE is_available = true;

-- ============================================
-- MENU ITEM CUSTOMIZATIONS
-- ============================================
CREATE TABLE menu_item_customizations (
  id BIGSERIAL PRIMARY KEY,
  menu_item_id BIGINT REFERENCES menu_items(id) ON DELETE CASCADE,
  name TEXT NOT NULL, -- "Size", "Add-ons", "Toppings"
  type TEXT CHECK (type IN ('single', 'multiple')) DEFAULT 'single',
  options JSONB NOT NULL, -- [{"label": "Large", "price": 2.00}]
  is_required BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0
);

CREATE INDEX menu_customizations_item_idx ON menu_item_customizations(menu_item_id);

-- ============================================
-- STORE MENU AVAILABILITY (per-store pricing/availability)
-- ============================================
CREATE TABLE store_menu_items (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE,
  menu_item_id BIGINT REFERENCES menu_items(id) ON DELETE CASCADE,
  is_available BOOLEAN DEFAULT true,
  custom_price DECIMAL(10, 2), -- Override base price if needed
  UNIQUE(store_id, menu_item_id)
);

CREATE INDEX store_menu_items_store_idx ON store_menu_items(store_id);
CREATE INDEX store_menu_items_item_idx ON store_menu_items(menu_item_id);

-- ============================================
-- ORDERS
-- ============================================
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number TEXT UNIQUE NOT NULL, -- "ORD-1234567890"
  customer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
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

CREATE INDEX orders_store_idx ON orders(store_id);
CREATE INDEX orders_customer_idx ON orders(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX orders_status_idx ON orders(status);
CREATE INDEX orders_created_at_idx ON orders(created_at DESC);
CREATE INDEX orders_store_status_idx ON orders(store_id, status);
CREATE INDEX orders_number_idx ON orders(order_number);

-- ============================================
-- ORDER ITEMS
-- ============================================
CREATE TABLE order_items (
  id BIGSERIAL PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id BIGINT REFERENCES menu_items(id),

  -- Snapshot data (preserve even if menu item deleted)
  item_name TEXT NOT NULL,
  item_price DECIMAL(10, 2) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,

  -- Customizations applied
  customizations JSONB DEFAULT '[]'::jsonb, -- [{"name": "Size", "value": "Large", "price": 2.00}]

  subtotal DECIMAL(10, 2) NOT NULL, -- (item_price + sum(customization prices)) * quantity
  notes TEXT
);

CREATE INDEX order_items_order_idx ON order_items(order_id);

-- ============================================
-- ORDER STATUS HISTORY (audit trail)
-- ============================================
CREATE TABLE order_status_history (
  id BIGSERIAL PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  previous_status TEXT,
  new_status TEXT NOT NULL,
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX order_status_history_order_idx ON order_status_history(order_id);

-- ============================================
-- CUSTOMER FAVORITES
-- ============================================
CREATE TABLE customer_favorites (
  id BIGSERIAL PRIMARY KEY,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  menu_item_id BIGINT REFERENCES menu_items(id) ON DELETE CASCADE,
  customizations JSONB DEFAULT '{}'::jsonb,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id, menu_item_id)
);

CREATE INDEX customer_favorites_customer_idx ON customer_favorites(customer_id);

-- ============================================
-- CUSTOMER REWARDS/LOYALTY
-- ============================================
CREATE TABLE customer_rewards (
  id BIGSERIAL PRIMARY KEY,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  points INTEGER DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  total_spent DECIMAL(10, 2) DEFAULT 0,
  tier TEXT DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX customer_rewards_customer_idx ON customer_rewards(customer_id);
CREATE INDEX customer_rewards_tier_idx ON customer_rewards(tier);

-- ============================================
-- REWARDS TRANSACTIONS
-- ============================================
CREATE TABLE rewards_transactions (
  id BIGSERIAL PRIMARY KEY,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  points_change INTEGER NOT NULL, -- positive for earning, negative for redemption
  transaction_type TEXT CHECK (transaction_type IN ('earned', 'redeemed', 'expired', 'bonus')),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX rewards_transactions_customer_idx ON rewards_transactions(customer_id);
CREATE INDEX rewards_transactions_created_idx ON rewards_transactions(created_at DESC);

-- ============================================
-- ANALYTICS SNAPSHOTS (daily aggregates)
-- ============================================
CREATE TABLE daily_analytics (
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

CREATE INDEX daily_analytics_store_date_idx ON daily_analytics(store_id, date DESC);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get current user's role
CREATE OR REPLACE FUNCTION public.user_role()
RETURNS TEXT AS $$
  SELECT role FROM public.user_profiles WHERE id = auth.uid();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Get current user's store_id
CREATE OR REPLACE FUNCTION public.user_store_id()
RETURNS BIGINT AS $$
  SELECT store_id FROM public.user_profiles WHERE id = auth.uid();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Check if user has permission
CREATE OR REPLACE FUNCTION public.has_permission(permission TEXT)
RETURNS BOOLEAN AS $$
  SELECT permissions @> jsonb_build_array(permission)
  FROM public.user_profiles
  WHERE id = auth.uid();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ============================================
-- AUTOMATIC TIMESTAMP UPDATES
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

-- ============================================
-- ORDER NUMBER GENERATION
-- ============================================
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.order_number = 'ORD-' || EXTRACT(EPOCH FROM NOW())::BIGINT;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_generate_number BEFORE INSERT ON orders
  FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- ============================================
-- ORDER STATUS HISTORY TRACKING
-- ============================================
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

-- ============================================
-- REWARDS CALCULATION
-- ============================================
CREATE OR REPLACE FUNCTION calculate_order_rewards()
RETURNS TRIGGER AS $$
DECLARE
  points_earned INTEGER;
BEGIN
  -- Only award points for completed orders with a customer_id
  IF NEW.status = 'completed' AND NEW.customer_id IS NOT NULL AND
     (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- 1 point per dollar spent
    points_earned := FLOOR(NEW.total);

    -- Insert reward transaction
    INSERT INTO rewards_transactions (customer_id, order_id, points_change, transaction_type, description)
    VALUES (NEW.customer_id, NEW.id, points_earned, 'earned', 'Points earned from order ' || NEW.order_number);

    -- Update customer rewards
    INSERT INTO customer_rewards (customer_id, points, total_orders, total_spent)
    VALUES (NEW.customer_id, points_earned, 1, NEW.total)
    ON CONFLICT (customer_id) DO UPDATE SET
      points = customer_rewards.points + points_earned,
      total_orders = customer_rewards.total_orders + 1,
      total_spent = customer_rewards.total_spent + NEW.total,
      updated_at = NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_calculate_rewards AFTER INSERT OR UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION calculate_order_rewards();

-- ============================================
-- CREATE USER PROFILE ON SIGNUP
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, role, full_name, phone)
  VALUES (
    NEW.id,
    'customer', -- Default role
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Customer'),
    COALESCE(NEW.raw_user_meta_data->>'phone', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
