-- ============================================
-- LAUNCH PHASE - SINGLE STORE SETUP
-- Highland Mills Snack Shop Inc (Jay's Deli)
-- ============================================

-- Clear existing stores (if any from old seed data)
DELETE FROM stores;

-- Insert Highland Mills Snack Shop Inc with CORRECT information
INSERT INTO stores (
  id,
  name,
  address,
  city,
  state,
  zip,
  phone,
  hours,
  is_open,
  latitude,
  longitude,
  store_type,
  email
) VALUES (
  1,
  'Highland Mills Snack Shop Inc',
  '634 NY-32',
  'Highland Mills',
  'NY',
  '10930',
  '(845) 928-2883',
  'Open 24/7',
  true,
  41.3501,
  -74.1243,
  'deli',
  'jaydeli@outonemail.com'
);

-- ============================================
-- CREATE TEST STAFF ACCOUNTS FOR HIGHLAND MILLS
-- ============================================

-- Note: These are test accounts for the launch phase
-- Passwords are intentionally simple for testing
-- CHANGE THESE before production launch!

-- Test Super Admin (for system management)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@jaydeli.com',
  crypt('admin123', gen_salt('bf')),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Super Admin"}',
  NOW(),
  NOW(),
  '',
  ''
);

-- Set super admin profile
INSERT INTO user_profiles (id, role, full_name, store_id, permissions)
SELECT
  id,
  'super_admin',
  'Super Admin',
  NULL, -- super admin sees all stores
  '["orders", "menu", "analytics", "settings"]'::jsonb
FROM auth.users WHERE email = 'admin@jaydeli.com';

-- Test Store Manager for Highland Mills
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'manager@jaydeli.com',
  crypt('manager123', gen_salt('bf')),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Store Manager"}',
  NOW(),
  NOW(),
  '',
  ''
);

-- Set manager profile
INSERT INTO user_profiles (id, role, full_name, store_id, permissions)
SELECT
  id,
  'manager',
  'Store Manager',
  1, -- Highland Mills store
  '["orders", "menu", "analytics"]'::jsonb
FROM auth.users WHERE email = 'manager@jaydeli.com';

-- Test Staff Member for Highland Mills
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'staff@jaydeli.com',
  crypt('staff123', gen_salt('bf')),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Staff Member"}',
  NOW(),
  NOW(),
  '',
  ''
);

-- Set staff profile (orders only)
INSERT INTO user_profiles (id, role, full_name, store_id, permissions)
SELECT
  id,
  'staff',
  'Staff Member',
  1, -- Highland Mills store
  '["orders"]'::jsonb
FROM auth.users WHERE email = 'staff@jaydeli.com';

-- ============================================
-- TEST LOGIN CREDENTIALS
-- ============================================
-- Super Admin:  admin@jaydeli.com   / admin123
-- Manager:      manager@jaydeli.com / manager123
-- Staff:        staff@jaydeli.com   / staff123
-- ============================================

-- Verify setup
SELECT
  'Store Setup Complete' as status,
  (SELECT COUNT(*) FROM stores) as total_stores,
  (SELECT name FROM stores WHERE id = 1) as store_name,
  (SELECT COUNT(*) FROM user_profiles) as total_staff
;
