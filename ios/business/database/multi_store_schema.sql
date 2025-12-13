-- ============================================================================
-- Multi-Store Architecture Database Schema
-- Cameron's Business App - Phase 11
-- ============================================================================
--
-- This schema adds multi-store support to the existing database.
-- Organizations can own multiple stores, and staff can be assigned to stores.
--
-- Migration Strategy:
-- 1. Create new tables (organizations, store_assignments)
-- 2. Enhance stores table with additional columns
-- 3. Add store_id foreign keys to existing tables
-- 4. Migrate existing single-store data to default organization
-- 5. Create database functions for multi-store queries
--
-- ============================================================================

-- ============================================================================
-- 1. ORGANIZATIONS TABLE
-- ============================================================================
-- Top-level entity that owns multiple restaurant locations

CREATE TABLE IF NOT EXISTS organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    subdomain VARCHAR(100) UNIQUE,
    owner_id INT,  -- Will reference users table when created
    subscription_tier VARCHAR(50) DEFAULT 'basic',
    logo_url TEXT,
    website VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_organizations_subdomain ON organizations(subdomain);
CREATE INDEX idx_organizations_owner ON organizations(owner_id);
CREATE INDEX idx_organizations_active ON organizations(is_active);

-- ============================================================================
-- 2. ENHANCED STORES TABLE
-- ============================================================================
-- Individual restaurant locations belonging to an organization

CREATE TABLE IF NOT EXISTS stores (
    id SERIAL PRIMARY KEY,
    organization_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    store_code VARCHAR(50) UNIQUE,

    -- Location information
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    zip VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),

    -- Contact information
    phone VARCHAR(20),
    email VARCHAR(255),

    -- Operating information
    timezone VARCHAR(50) DEFAULT 'America/New_York',
    currency VARCHAR(3) DEFAULT 'USD',
    opening_date DATE,
    is_active BOOLEAN DEFAULT true,

    -- Staff assignment
    manager_id INT,  -- Will reference users table

    -- Settings (JSON for flexibility)
    settings JSONB DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    -- Constraints
    CONSTRAINT store_code_format CHECK (store_code ~ '^[A-Z0-9-]+$')
);

-- Indexes for performance
CREATE INDEX idx_stores_organization ON stores(organization_id);
CREATE INDEX idx_stores_code ON stores(store_code);
CREATE INDEX idx_stores_active ON stores(is_active);
CREATE INDEX idx_stores_manager ON stores(manager_id);
CREATE INDEX idx_stores_location ON stores(city, state);

-- ============================================================================
-- 3. STORE ASSIGNMENTS TABLE
-- ============================================================================
-- Maps staff members to stores with roles

CREATE TABLE IF NOT EXISTS store_assignments (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,  -- Will reference users table
    store_id INT REFERENCES stores(id) ON DELETE CASCADE,

    -- Role at this specific store
    role VARCHAR(50) NOT NULL,  -- 'manager', 'staff', 'kitchen', 'delivery'

    -- Primary store designation (for default login)
    is_primary BOOLEAN DEFAULT false,

    -- Work schedule (optional, for future use)
    schedule JSONB DEFAULT '{}',

    -- Timestamps
    assigned_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    -- Ensure unique user-store combination
    UNIQUE(user_id, store_id),

    -- Ensure only one primary store per user
    CONSTRAINT one_primary_per_user UNIQUE NULLS NOT DISTINCT (user_id, is_primary)
);

-- Indexes for performance
CREATE INDEX idx_store_assignments_user ON store_assignments(user_id);
CREATE INDEX idx_store_assignments_store ON store_assignments(store_id);
CREATE INDEX idx_store_assignments_primary ON store_assignments(is_primary) WHERE is_primary = true;

-- ============================================================================
-- 4. ADD STORE_ID TO EXISTING TABLES
-- ============================================================================
-- These ALTER TABLE statements add store_id foreign keys to existing tables
-- Run these carefully in production with proper migration strategy

-- Note: In production, you would:
-- 1. Add columns as nullable first
-- 2. Backfill with default store ID
-- 3. Make columns NOT NULL
-- 4. Add foreign key constraints

-- Orders table
-- ALTER TABLE orders ADD COLUMN store_id INT REFERENCES stores(id);
-- CREATE INDEX idx_orders_store ON orders(store_id);

-- Menu items table
-- ALTER TABLE menu_items ADD COLUMN store_id INT REFERENCES stores(id);
-- CREATE INDEX idx_menu_items_store ON menu_items(store_id);

-- Loyalty programs table
-- ALTER TABLE loyalty_programs ADD COLUMN store_id INT REFERENCES stores(id);
-- CREATE INDEX idx_loyalty_programs_store ON loyalty_programs(store_id);

-- Marketing campaigns table
-- ALTER TABLE marketing_campaigns ADD COLUMN store_id INT REFERENCES stores(id);
-- CREATE INDEX idx_campaigns_store ON marketing_campaigns(store_id);

-- Inventory items table (when created)
-- ALTER TABLE inventory_items ADD COLUMN store_id INT REFERENCES stores(id);
-- CREATE INDEX idx_inventory_store ON inventory_items(store_id);

-- ============================================================================
-- 5. DATABASE FUNCTIONS
-- ============================================================================

-- Function: Get all stores a user can access
CREATE OR REPLACE FUNCTION get_user_stores(user_id_param INT)
RETURNS TABLE (
    store_id INT,
    store_name VARCHAR,
    store_code VARCHAR,
    organization_id INT,
    organization_name VARCHAR,
    role VARCHAR,
    is_primary BOOLEAN,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id AS store_id,
        s.name AS store_name,
        s.store_code,
        s.organization_id,
        o.name AS organization_name,
        sa.role,
        sa.is_primary,
        s.is_active
    FROM stores s
    JOIN store_assignments sa ON sa.store_id = s.id
    JOIN organizations o ON o.id = s.organization_id
    WHERE sa.user_id = user_id_param
      AND s.is_active = true
      AND o.is_active = true
    ORDER BY sa.is_primary DESC, s.name;
END;
$$ LANGUAGE plpgsql;

-- Function: Get organization analytics across all stores
CREATE OR REPLACE FUNCTION get_organization_analytics(
    org_id_param INT,
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    store_id INT,
    store_name VARCHAR,
    total_orders BIGINT,
    total_revenue DECIMAL,
    avg_order_value DECIMAL,
    new_customers INT,
    returning_customers INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id AS store_id,
        s.name AS store_name,
        COUNT(o.id) AS total_orders,
        COALESCE(SUM(o.total), 0)::DECIMAL AS total_revenue,
        COALESCE(AVG(o.total), 0)::DECIMAL AS avg_order_value,
        0 AS new_customers,  -- Placeholder, calculate based on customer table
        0 AS returning_customers  -- Placeholder
    FROM stores s
    LEFT JOIN orders o ON o.store_id = s.id
        AND o.created_at BETWEEN start_date AND end_date
        AND o.status != 'cancelled'
    WHERE s.organization_id = org_id_param
      AND s.is_active = true
    GROUP BY s.id, s.name
    ORDER BY total_revenue DESC;
END;
$$ LANGUAGE plpgsql;

-- Function: Get store performance comparison
CREATE OR REPLACE FUNCTION get_stores_performance_comparison(
    org_id_param INT,
    period VARCHAR DEFAULT 'month'  -- 'week', 'month', 'quarter', 'year'
)
RETURNS TABLE (
    store_id INT,
    store_name VARCHAR,
    store_code VARCHAR,
    orders_count BIGINT,
    revenue DECIMAL,
    revenue_change_pct DECIMAL,
    avg_order_value DECIMAL,
    top_selling_item VARCHAR
) AS $$
DECLARE
    start_date DATE;
    prev_start_date DATE;
    prev_end_date DATE;
BEGIN
    -- Calculate date ranges based on period
    CASE period
        WHEN 'week' THEN
            start_date := CURRENT_DATE - INTERVAL '7 days';
            prev_start_date := CURRENT_DATE - INTERVAL '14 days';
            prev_end_date := CURRENT_DATE - INTERVAL '7 days';
        WHEN 'month' THEN
            start_date := CURRENT_DATE - INTERVAL '30 days';
            prev_start_date := CURRENT_DATE - INTERVAL '60 days';
            prev_end_date := CURRENT_DATE - INTERVAL '30 days';
        WHEN 'quarter' THEN
            start_date := CURRENT_DATE - INTERVAL '90 days';
            prev_start_date := CURRENT_DATE - INTERVAL '180 days';
            prev_end_date := CURRENT_DATE - INTERVAL '90 days';
        WHEN 'year' THEN
            start_date := CURRENT_DATE - INTERVAL '365 days';
            prev_start_date := CURRENT_DATE - INTERVAL '730 days';
            prev_end_date := CURRENT_DATE - INTERVAL '365 days';
        ELSE
            start_date := CURRENT_DATE - INTERVAL '30 days';
            prev_start_date := CURRENT_DATE - INTERVAL '60 days';
            prev_end_date := CURRENT_DATE - INTERVAL '30 days';
    END CASE;

    RETURN QUERY
    WITH current_period AS (
        SELECT
            s.id,
            COUNT(o.id) AS orders,
            COALESCE(SUM(o.total), 0) AS revenue
        FROM stores s
        LEFT JOIN orders o ON o.store_id = s.id
            AND o.created_at >= start_date
            AND o.status != 'cancelled'
        WHERE s.organization_id = org_id_param
        GROUP BY s.id
    ),
    previous_period AS (
        SELECT
            s.id,
            COALESCE(SUM(o.total), 0) AS revenue
        FROM stores s
        LEFT JOIN orders o ON o.store_id = s.id
            AND o.created_at BETWEEN prev_start_date AND prev_end_date
            AND o.status != 'cancelled'
        WHERE s.organization_id = org_id_param
        GROUP BY s.id
    )
    SELECT
        s.id AS store_id,
        s.name AS store_name,
        s.store_code,
        cp.orders AS orders_count,
        cp.revenue::DECIMAL,
        CASE
            WHEN pp.revenue > 0 THEN ((cp.revenue - pp.revenue) / pp.revenue * 100)::DECIMAL
            ELSE 0::DECIMAL
        END AS revenue_change_pct,
        CASE
            WHEN cp.orders > 0 THEN (cp.revenue / cp.orders)::DECIMAL
            ELSE 0::DECIMAL
        END AS avg_order_value,
        ''::VARCHAR AS top_selling_item  -- Placeholder
    FROM stores s
    JOIN current_period cp ON cp.id = s.id
    LEFT JOIN previous_period pp ON pp.id = s.id
    WHERE s.organization_id = org_id_param
      AND s.is_active = true
    ORDER BY cp.revenue DESC;
END;
$$ LANGUAGE plpgsql;

-- Function: Check if user has access to store
CREATE OR REPLACE FUNCTION user_has_store_access(
    user_id_param INT,
    store_id_param INT
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM store_assignments sa
        JOIN stores s ON s.id = sa.store_id
        WHERE sa.user_id = user_id_param
          AND sa.store_id = store_id_param
          AND s.is_active = true
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 6. TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Trigger: Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to organizations table
CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON organizations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply to stores table
CREATE TRIGGER update_stores_updated_at
    BEFORE UPDATE ON stores
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply to store_assignments table
CREATE TRIGGER update_store_assignments_updated_at
    BEFORE UPDATE ON store_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. SAMPLE DATA FOR TESTING
-- ============================================================================

-- Insert sample organization
INSERT INTO organizations (name, subdomain, subscription_tier, is_active)
VALUES ('Cameron''s Restaurants', 'camerons', 'premium', true)
ON CONFLICT DO NOTHING;

-- Insert sample stores
WITH org AS (SELECT id FROM organizations WHERE subdomain = 'camerons' LIMIT 1)
INSERT INTO stores (
    organization_id, name, store_code, address, city, state, zip,
    phone, email, timezone, is_active
)
SELECT
    org.id,
    'Cameron''s Downtown',
    'CAM-DT-001',
    '123 Main Street',
    'New York',
    'NY',
    '10001',
    '(555) 123-4567',
    'downtown@camerons.com',
    'America/New_York',
    true
FROM org
UNION ALL
SELECT
    org.id,
    'Cameron''s Uptown',
    'CAM-UT-002',
    '456 Broadway',
    'New York',
    'NY',
    '10024',
    '(555) 234-5678',
    'uptown@camerons.com',
    'America/New_York',
    true
FROM org
UNION ALL
SELECT
    org.id,
    'Cameron''s Brooklyn',
    'CAM-BK-003',
    '789 Bedford Ave',
    'Brooklyn',
    'NY',
    '11211',
    '(555) 345-6789',
    'brooklyn@camerons.com',
    'America/New_York',
    true
FROM org
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 8. VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View: Store details with organization info
CREATE OR REPLACE VIEW store_details AS
SELECT
    s.id AS store_id,
    s.name AS store_name,
    s.store_code,
    s.address,
    s.city,
    s.state,
    s.zip,
    s.phone,
    s.email,
    s.is_active AS store_active,
    o.id AS organization_id,
    o.name AS organization_name,
    o.subscription_tier,
    o.is_active AS organization_active
FROM stores s
JOIN organizations o ON o.id = s.organization_id;

-- View: Staff assignments with store and org info
CREATE OR REPLACE VIEW staff_assignments AS
SELECT
    sa.user_id,
    sa.role,
    sa.is_primary,
    s.id AS store_id,
    s.name AS store_name,
    s.store_code,
    o.id AS organization_id,
    o.name AS organization_name
FROM store_assignments sa
JOIN stores s ON s.id = sa.store_id
JOIN organizations o ON o.id = s.organization_id
WHERE s.is_active = true AND o.is_active = true;

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================
--
-- For existing single-store deployments:
--
-- 1. Create a default organization:
--    INSERT INTO organizations (name, subdomain, is_active)
--    VALUES ('Default Organization', 'default', true);
--
-- 2. Create a default store linked to that organization:
--    INSERT INTO stores (organization_id, name, store_code, is_active)
--    SELECT id, 'Main Store', 'MAIN-001', true
--    FROM organizations WHERE subdomain = 'default';
--
-- 3. Assign all existing staff to the default store:
--    INSERT INTO store_assignments (user_id, store_id, role, is_primary)
--    SELECT u.id, s.id, u.role, true
--    FROM users u
--    CROSS JOIN stores s
--    WHERE s.store_code = 'MAIN-001';
--
-- 4. Backfill store_id in existing tables:
--    UPDATE orders SET store_id = (SELECT id FROM stores WHERE store_code = 'MAIN-001');
--    UPDATE menu_items SET store_id = (SELECT id FROM stores WHERE store_code = 'MAIN-001');
--    -- etc.
--
-- 5. Make store_id NOT NULL after backfilling:
--    ALTER TABLE orders ALTER COLUMN store_id SET NOT NULL;
--    -- etc.
--
-- ============================================================================
