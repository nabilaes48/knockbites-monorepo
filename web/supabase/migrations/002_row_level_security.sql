-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================
-- This migration sets up all RLS policies to ensure
-- proper data access control based on user roles

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_item_customizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_analytics ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STORES POLICIES
-- ============================================

-- Everyone can view stores (public info)
CREATE POLICY "Stores are viewable by everyone" ON stores
  FOR SELECT USING (true);

-- Only super_admins can modify stores
CREATE POLICY "Super admins can update stores" ON stores
  FOR UPDATE USING (public.user_role() = 'super_admin');

CREATE POLICY "Super admins can insert stores" ON stores
  FOR INSERT WITH CHECK (public.user_role() = 'super_admin');

CREATE POLICY "Super admins can delete stores" ON stores
  FOR DELETE USING (public.user_role() = 'super_admin');

-- ============================================
-- USER PROFILES POLICIES
-- ============================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

-- Staff can view profiles in their store
CREATE POLICY "Staff can view store profiles" ON user_profiles
  FOR SELECT USING (
    public.user_role() IN ('admin', 'manager', 'super_admin') AND
    (store_id = public.user_store_id() OR public.user_role() = 'super_admin')
  );

-- Users can update their own basic info
CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND
    -- Can't change own role or permissions
    role = (SELECT role FROM user_profiles WHERE id = auth.uid()) AND
    permissions = (SELECT permissions FROM user_profiles WHERE id = auth.uid())
  );

-- Only super_admins and admins can create profiles
CREATE POLICY "Admins can insert profiles" ON user_profiles
  FOR INSERT WITH CHECK (
    public.user_role() IN ('super_admin', 'admin')
  );

-- Only super_admins and admins can modify profiles
CREATE POLICY "Admins can update profiles" ON user_profiles
  FOR UPDATE USING (
    public.user_role() IN ('super_admin', 'admin')
  );

-- ============================================
-- MENU CATEGORIES POLICIES
-- ============================================

-- Everyone can view active categories
CREATE POLICY "Categories viewable by all" ON menu_categories
  FOR SELECT USING (is_active = true OR public.user_role() IN ('super_admin', 'admin', 'manager', 'staff'));

-- Staff with menu permission can manage categories
CREATE POLICY "Staff can manage categories" ON menu_categories
  FOR ALL USING (
    public.has_permission('menu') OR
    public.user_role() IN ('super_admin', 'admin', 'manager')
  );

-- ============================================
-- MENU ITEMS POLICIES
-- ============================================

-- Everyone can view available menu items
CREATE POLICY "Menu items viewable by everyone" ON menu_items
  FOR SELECT USING (
    is_available = true OR
    public.user_role() IN ('super_admin', 'admin', 'manager', 'staff')
  );

-- Staff with menu permission can manage items
CREATE POLICY "Staff can insert menu items" ON menu_items
  FOR INSERT WITH CHECK (
    public.has_permission('menu') OR
    public.user_role() IN ('super_admin', 'admin', 'manager')
  );

CREATE POLICY "Staff can update menu items" ON menu_items
  FOR UPDATE USING (
    public.has_permission('menu') OR
    public.user_role() IN ('super_admin', 'admin', 'manager')
  );

CREATE POLICY "Staff can delete menu items" ON menu_items
  FOR DELETE USING (
    public.has_permission('menu') OR
    public.user_role() IN ('super_admin', 'admin')
  );

-- ============================================
-- MENU CUSTOMIZATIONS POLICIES
-- ============================================

-- Everyone can view customizations
CREATE POLICY "Customizations viewable by all" ON menu_item_customizations
  FOR SELECT USING (true);

-- Staff can manage customizations
CREATE POLICY "Staff can manage customizations" ON menu_item_customizations
  FOR ALL USING (
    public.has_permission('menu') OR
    public.user_role() IN ('super_admin', 'admin', 'manager')
  );

-- ============================================
-- STORE MENU ITEMS POLICIES
-- ============================================

-- Everyone can view store menu availability
CREATE POLICY "Store menu viewable by all" ON store_menu_items
  FOR SELECT USING (true);

-- Store staff can manage their store's menu
CREATE POLICY "Staff can manage store menu" ON store_menu_items
  FOR ALL USING (
    (public.has_permission('menu') AND store_id = public.user_store_id()) OR
    public.user_role() IN ('super_admin', 'admin')
  );

-- ============================================
-- ORDERS POLICIES
-- ============================================

-- Customers can view their own orders
CREATE POLICY "Customers can view own orders" ON orders
  FOR SELECT USING (
    customer_id = auth.uid() OR
    public.user_role() IN ('staff', 'manager', 'admin', 'super_admin')
  );

-- Anyone (including guests) can create orders
CREATE POLICY "Anyone can create orders" ON orders
  FOR INSERT WITH CHECK (true);

-- Staff can view orders for their store
CREATE POLICY "Staff can view store orders" ON orders
  FOR SELECT USING (
    public.user_role() IN ('staff', 'manager', 'admin') AND
    (store_id = public.user_store_id() OR public.user_role() = 'super_admin')
  );

-- Staff can update orders in their store
CREATE POLICY "Staff can update store orders" ON orders
  FOR UPDATE USING (
    (public.has_permission('orders') OR public.user_role() IN ('admin', 'manager')) AND
    (store_id = public.user_store_id() OR public.user_role() = 'super_admin')
  );

-- Staff can cancel orders (soft delete via status)
CREATE POLICY "Staff can cancel orders" ON orders
  FOR UPDATE USING (
    public.user_role() IN ('staff', 'manager', 'admin', 'super_admin') AND
    (store_id = public.user_store_id() OR public.user_role() = 'super_admin')
  )
  WITH CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled'));

-- ============================================
-- ORDER ITEMS POLICIES
-- ============================================

-- Order items follow same rules as orders
CREATE POLICY "Order items viewable with order" ON order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id AND
      (orders.customer_id = auth.uid() OR
       public.user_role() IN ('staff', 'manager', 'admin', 'super_admin'))
    )
  );

-- Anyone can insert order items (during checkout)
CREATE POLICY "Anyone can insert order items" ON order_items
  FOR INSERT WITH CHECK (true);

-- Staff can update order items
CREATE POLICY "Staff can update order items" ON order_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id AND
      public.user_role() IN ('staff', 'manager', 'admin', 'super_admin') AND
      (orders.store_id = public.user_store_id() OR public.user_role() = 'super_admin')
    )
  );

-- ============================================
-- ORDER STATUS HISTORY POLICIES
-- ============================================

-- Staff can view order status history for their store
CREATE POLICY "Staff can view order history" ON order_status_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_status_history.order_id AND
      (public.user_role() IN ('staff', 'manager', 'admin', 'super_admin')) AND
      (orders.store_id = public.user_store_id() OR public.user_role() = 'super_admin')
    )
  );

-- System automatically inserts status history (via trigger)
-- No manual INSERT policy needed

-- ============================================
-- CUSTOMER FAVORITES POLICIES
-- ============================================

-- Customers can manage their own favorites
CREATE POLICY "Customers manage own favorites" ON customer_favorites
  FOR ALL USING (customer_id = auth.uid());

-- ============================================
-- CUSTOMER REWARDS POLICIES
-- ============================================

-- Customers can view their own rewards
CREATE POLICY "Customers view own rewards" ON customer_rewards
  FOR SELECT USING (customer_id = auth.uid());

-- Staff can view customer rewards
CREATE POLICY "Staff can view customer rewards" ON customer_rewards
  FOR SELECT USING (
    public.user_role() IN ('staff', 'manager', 'admin', 'super_admin')
  );

-- System manages rewards (via triggers, using service role)
-- Only super_admin can manually update
CREATE POLICY "Super admin can update rewards" ON customer_rewards
  FOR UPDATE USING (public.user_role() = 'super_admin');

-- ============================================
-- REWARDS TRANSACTIONS POLICIES
-- ============================================

-- Customers view their own transaction history
CREATE POLICY "Customers view own transactions" ON rewards_transactions
  FOR SELECT USING (customer_id = auth.uid());

-- Staff can view transactions
CREATE POLICY "Staff can view transactions" ON rewards_transactions
  FOR SELECT USING (
    public.user_role() IN ('staff', 'manager', 'admin', 'super_admin')
  );

-- System manages transactions (via triggers)
-- Only super_admin can manually insert
CREATE POLICY "Super admin can manage transactions" ON rewards_transactions
  FOR INSERT WITH CHECK (public.user_role() = 'super_admin');

-- ============================================
-- ANALYTICS POLICIES
-- ============================================

-- Only staff with analytics permission can view
CREATE POLICY "Staff can view analytics" ON daily_analytics
  FOR SELECT USING (
    (public.has_permission('analytics') OR public.user_role() IN ('admin', 'manager', 'super_admin')) AND
    (store_id = public.user_store_id() OR public.user_role() = 'super_admin')
  );

-- Only super_admin can insert/update analytics
CREATE POLICY "Super admin can manage analytics" ON daily_analytics
  FOR ALL USING (public.user_role() = 'super_admin');
