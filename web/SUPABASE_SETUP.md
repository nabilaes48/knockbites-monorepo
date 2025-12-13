# Supabase Integration Setup Guide

This guide will walk you through integrating Supabase with your Cameron's Connect platform.

## Step 1: Create Supabase Account & Project

1. **Go to Supabase**
   - Visit [https://supabase.com](https://supabase.com)
   - Click "Start your project" and sign up (free)

2. **Create New Project**
   - Click "New Project"
   - Name: `camerons-connect-dev` (for development)
   - Database Password: Create a strong password and **save it**
   - Region: Choose `US East (North Virginia)` (closest to NY)
   - Pricing: Select "Free" for development
   - Click "Create new project" (takes ~2 minutes)

3. **Save Your Credentials**
   Once your project is created, go to **Settings > API**:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **Anon/Public Key**: `eyJhbGc...` (long string)

   Copy these - you'll need them in Step 3!

## Step 2: Run Database Migrations

1. **Open Supabase SQL Editor**
   - In your Supabase dashboard, click **SQL Editor** (in the left sidebar)

2. **Run Each Migration**
   Run the migration files in order by copying and pasting their contents:

   **Migration 1: Initial Schema**
   - Open `supabase/migrations/001_initial_schema.sql`
   - Copy the entire contents
   - Paste into Supabase SQL Editor
   - Click "Run" (bottom right)
   - Wait for "Success" message

   **Migration 2: Row Level Security**
   - Open `supabase/migrations/002_row_level_security.sql`
   - Copy and paste into SQL Editor
   - Click "Run"

   **Migration 3: Seed Data**
   - Open `supabase/migrations/003_seed_data.sql`
   - Copy and paste into SQL Editor
   - Click "Run"

3. **Verify Setup**
   - Go to **Table Editor** in Supabase
   - You should see tables: `stores`, `user_profiles`, `orders`, `menu_items`, etc.
   - Click on `stores` - you should see 29 Cameron's Connect locations

## Step 3: Configure React App

1. **Install Supabase Client**
   ```bash
   cd /Users/nabilimran/camerons-connect
   npm install @supabase/supabase-js
   ```

2. **Create Environment File**
   - Copy `.env.example` to `.env.local`:
     ```bash
     cp .env.example .env.local
     ```
   - Open `.env.local` and add your credentials:
     ```env
     VITE_SUPABASE_URL=https://your-project-ref.supabase.co
     VITE_SUPABASE_ANON_KEY=your-anon-key-here
     ```
   - Replace with your actual values from Step 1!

3. **Wrap App with AuthProvider**
   - Open `src/App.tsx`
   - Add import: `import { AuthProvider } from '@/contexts/AuthContext'`
   - Wrap the app:
     ```tsx
     <AuthProvider>
       <QueryClientProvider client={queryClient}>
         {/* existing code */}
       </QueryClientProvider>
     </AuthProvider>
     ```

## Step 4: Create Test Users

Go back to Supabase and run this SQL to create test accounts:

```sql
-- Create a test super admin
-- You'll use this to login and test the dashboard

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
  'admin@cameronsconnect.com',
  crypt('admin123', gen_salt('bf')),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Super Admin","phone":"555-0100"}',
  NOW(),
  NOW(),
  '',
  ''
);

-- Update the user profile to be super_admin
UPDATE user_profiles
SET role = 'super_admin',
    full_name = 'Super Admin',
    permissions = '["orders", "menu", "analytics", "settings"]'::jsonb
WHERE id = (
  SELECT id FROM auth.users WHERE email = 'admin@cameronsconnect.com'
);
```

**Test Login Credentials:**
- Email: `admin@cameronsconnect.com`
- Password: `admin123`

## Step 5: Test the Integration

1. **Start Development Server**
   ```bash
   npm run dev
   ```

2. **Test Login**
   - Go to `http://localhost:8080/dashboard/login`
   - Login with: `admin@cameronsconnect.com` / `admin123`
   - You should see the dashboard with super admin access

3. **Verify Real-time**
   - Open the dashboard in two browser windows
   - In window 1: view orders
   - In window 2: create a test order (when you implement that)
   - Window 1 should update automatically

## Step 6: Connect Swift Apps (Later)

Once the web app is working, you can connect your Swift apps:

1. **Install Supabase Swift SDK**
   ```swift
   // In Package.swift or via SPM
   dependencies: [
       .package(url: "https://github.com/supabase-community/supabase-swift", from: "2.0.0")
   ]
   ```

2. **Use Same Credentials**
   - Use the same `SUPABASE_URL` and `SUPABASE_ANON_KEY`
   - All 3 apps will share the same database

## Troubleshooting

### Error: "Missing Supabase environment variables"
- Make sure `.env.local` exists in the project root
- Make sure variable names start with `VITE_`
- Restart dev server after creating `.env.local`

### Error: "JWT expired" or "Invalid token"
- Your session expired
- Just logout and login again
- Sessions last 1 hour by default

### Can't see tables in Supabase
- Make sure you ran all 3 migration files
- Check for errors in SQL Editor
- Try running them one at a time

### RLS Policy Errors
- This means Row Level Security is blocking access
- Check that you're logged in
- Make sure your user has the correct role in `user_profiles`

## Next Steps

Now that Supabase is set up:

1. **Update DashboardLogin** to use Supabase auth instead of localStorage
2. **Update OrderManagement** to use `useRealtimeOrders` hook
3. **Update Checkout** to save orders to Supabase
4. **Test customer signup** flow
5. **Implement menu management** with Supabase

See `INTEGRATION_GUIDE.md` for detailed code examples.

## Production Setup (Later)

When ready to launch:

1. Create a **production Supabase project** (separate from dev)
2. Run the same migrations in production
3. Upgrade to Supabase Pro ($25/month) for:
   - Daily backups
   - Better performance
   - Support
4. Update production environment variables
5. Deploy web app with production credentials
6. Submit iOS apps with production config

## Security Notes

- ✅ Never commit `.env.local` to git (already in `.gitignore`)
- ✅ Never use service role key in frontend code
- ✅ RLS policies protect all data access
- ✅ Test all permissions before going live
- ✅ Use different projects for dev and production

## Need Help?

- Supabase Docs: https://supabase.com/docs
- Supabase Discord: https://discord.supabase.com
- Your integration files are in:
  - `src/lib/supabase.ts` - Supabase client
  - `src/contexts/AuthContext.tsx` - Authentication
  - `src/hooks/useRealtimeOrders.ts` - Real-time orders
  - `src/components/ProtectedRoute.tsx` - Route protection
