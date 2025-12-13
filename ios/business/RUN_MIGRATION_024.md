# How to Run Migration 024 - Analytics Setup

## ✅ Migration 024 is Ready!

The migration file has been created at:
```
/database/migrations/024_analytics_views.sql
```

## 🚀 How to Run It

### Option 1: Supabase Dashboard (Recommended - 2 minutes)

1. **Open Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Select your project

2. **Open SQL Editor**
   - Click **SQL Editor** in the left sidebar
   - Click **New Query**

3. **Copy & Paste Migration**
   - Open `database/migrations/024_analytics_views.sql`
   - Copy ALL contents (Cmd+A, Cmd+C)
   - Paste into SQL Editor

4. **Run Migration**
   - Click **Run** button (or press Cmd+Enter)
   - Wait for "Success" message

5. **Verify**
   ```sql
   -- Run this to verify views were created:
   SELECT * FROM analytics_daily_stats LIMIT 5;
   SELECT * FROM analytics_popular_items LIMIT 5;

   -- Run this to verify functions work:
   SELECT * FROM get_store_metrics(1, 'today');
   SELECT * FROM get_revenue_chart_data(1, 'week');
   ```

---

### Option 2: Supabase CLI (If you have it installed)

```bash
cd /Users/nabilimran/Developer/camerons-Bussiness-app

# Run migration
supabase db execute --file database/migrations/024_analytics_views.sql

# Or connect to your remote database
supabase db execute --file database/migrations/024_analytics_views.sql --db-url "postgresql://..."
```

---

### Option 3: Direct PostgreSQL Connection

If you have the PostgreSQL connection string:

```bash
psql "your-supabase-connection-string" -f database/migrations/024_analytics_views.sql
```

---

## 📊 What This Migration Creates

### 5 Analytics Views
1. ✅ `analytics_daily_stats` - Daily revenue, orders, customers per store
2. ✅ `analytics_hourly_today` - Hourly breakdown for today
3. ✅ `analytics_time_distribution` - Orders by Breakfast/Lunch/Dinner/Late Night
4. ✅ `analytics_category_distribution` - Revenue by menu category
5. ✅ `analytics_popular_items` - Top-selling items per store

### 2 PostgreSQL Functions
1. ✅ `get_store_metrics(store_id, date_range)` - KPIs with % changes
2. ✅ `get_revenue_chart_data(store_id, date_range)` - Time-series for charts

### Permissions
- ✅ Grants SELECT access to `anon` and `authenticated` roles
- ✅ Grants EXECUTE access for RPC functions

---

## 🎯 What Happens After Running

### Before Migration
- ✅ Categories show real data
- ✅ Popular items show real data
- ✅ Hourly data shows real data
- ⚠️ Revenue chart empty (needs function)
- ⚠️ % changes show 0 (needs function)

### After Migration
- ✅ **Everything above +**
- ✅ Revenue chart with real time-series
- ✅ Period comparisons (Today/Week/Month/Quarter/Year)
- ✅ % changes from previous period
- ✅ KPI cards show trend arrows

---

## 🧪 Test After Migration

Open your iOS app and go to:

**More → Reports**
- Should see revenue trend chart populated
- Should see percentage changes on KPI cards
- Should see period selector working (Today/Week/Month)

**More → Store Info**
- Should see daily performance chart
- Should see multi-store comparison
- Should see capacity utilization

---

## ⚠️ Troubleshooting

### Error: "relation already exists"
This means views/functions already exist. To recreate:

```sql
-- Drop existing views/functions
DROP VIEW IF EXISTS analytics_daily_stats CASCADE;
DROP VIEW IF EXISTS analytics_hourly_today CASCADE;
DROP VIEW IF EXISTS analytics_time_distribution CASCADE;
DROP VIEW IF EXISTS analytics_category_distribution CASCADE;
DROP VIEW IF EXISTS analytics_popular_items CASCADE;
DROP FUNCTION IF EXISTS get_store_metrics CASCADE;
DROP FUNCTION IF EXISTS get_revenue_chart_data CASCADE;

-- Then run the migration again
```

### Error: "column does not exist"
Check that your `orders` and `order_items` tables have the required columns:
- `orders`: store_id, created_at, status, subtotal, tax, total, user_id
- `order_items`: order_id, menu_item_id, item_name, item_price, quantity, subtotal

### Error: "permission denied"
Make sure you're connected as a superuser or have CREATE permissions.

---

## 📝 Notes

- Migration is **idempotent** (safe to run multiple times with `CREATE OR REPLACE`)
- All views update automatically as new orders are created
- Functions support 5 date ranges: today, week, month, quarter, year
- Performance is optimized with proper indexing on date columns

---

## ✅ Status

- [x] Migration file created
- [x] iOS app updated to use functions
- [x] Build succeeds
- [ ] **Run migration in Supabase** ← **YOU ARE HERE**
- [ ] Test in iOS app
- [ ] Verify real data appears

**Next step:** Go to Supabase Dashboard and run the migration! 🚀
