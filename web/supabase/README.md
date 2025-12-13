# Supabase Database Migrations

This folder contains SQL migration scripts for setting up the Cameron's Connect database in Supabase.

## Migration Files

Run these in order:

1. **001_initial_schema.sql** - Creates all database tables, indexes, and triggers
2. **002_row_level_security.sql** - Sets up RLS policies for secure data access
3. **003_seed_data.sql** - Inserts initial data (29 stores, sample menu items)

## How to Apply Migrations

### Method 1: Supabase Dashboard (Recommended for first-time setup)

1. Go to your Supabase project dashboard
2. Click **SQL Editor** in the left sidebar
3. Copy contents of `001_initial_schema.sql`
4. Paste into editor and click **Run**
5. Repeat for `002_row_level_security.sql`
6. Repeat for `003_seed_data.sql`

### Method 2: Supabase CLI (For local development)

```bash
# Install Supabase CLI
npm install -D supabase

# Login
npx supabase login

# Link to your project
npx supabase link --project-ref your-project-ref

# Apply migrations
npx supabase db push
```

## Database Schema Overview

### Core Tables

- **stores** - 29 Cameron's Connect locations across NY
- **user_profiles** - Extends auth.users with roles and permissions
- **menu_categories** - Menu organization (Breakfast, Sandwiches, etc.)
- **menu_items** - Food items with pricing and details
- **menu_item_customizations** - Size, toppings, add-ons options
- **store_menu_items** - Per-store availability and custom pricing
- **orders** - Customer orders with status tracking
- **order_items** - Line items for each order
- **order_status_history** - Audit trail for order changes
- **customer_favorites** - Saved items for quick reorder
- **customer_rewards** - Loyalty points and tier tracking
- **rewards_transactions** - Points earning/redemption history
- **daily_analytics** - Aggregated store performance metrics

### Roles

- `super_admin` - Full access to all 29 stores
- `admin` - Full access to assigned store
- `manager` - Orders, menu, analytics access
- `staff` - Limited access based on permissions
- `customer` - Can place orders, view own history

### Permissions

- `orders` - Manage orders
- `menu` - Edit menu items
- `analytics` - View store analytics
- `settings` - Modify store settings

## Security

All tables have Row Level Security (RLS) enabled:
- Customers can only see their own orders
- Staff can only see orders for their assigned store
- Super admins can see all data
- Guests can browse menu and create orders

## Functions & Triggers

- **Auto-generate order numbers** - Format: `ORD-1234567890`
- **Track order status changes** - Automatic audit trail
- **Calculate rewards** - 1 point per dollar spent
- **Auto-create user profiles** - When user signs up
- **Update timestamps** - Auto-update `updated_at` fields

## Testing

After running migrations, verify:

```sql
-- Should return 29 stores
SELECT COUNT(*) FROM stores;

-- Should return menu categories
SELECT * FROM menu_categories ORDER BY display_order;

-- Should return sample menu items
SELECT COUNT(*) FROM menu_items;
```

## Rollback

If you need to start over:

```sql
-- WARNING: This deletes all data!
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

Then re-run all migrations.

## Production Checklist

Before going live:

- [ ] Run migrations in production Supabase project
- [ ] Create initial super admin user
- [ ] Test all RLS policies
- [ ] Configure email templates in Supabase Auth settings
- [ ] Set up database backups (Supabase Pro)
- [ ] Enable Point-in-Time Recovery (Supabase Pro)
- [ ] Test disaster recovery procedure
- [ ] Document admin procedures

## Support

See main documentation:
- `../SUPABASE_SETUP.md` - Complete setup guide
- `../SWIFT_INTEGRATION.md` - iOS app integration
- Supabase Docs: https://supabase.com/docs
