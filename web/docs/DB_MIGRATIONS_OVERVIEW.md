# Database Migrations Overview

This document provides a comprehensive overview of all database migrations for Cameron's Connect.

## Migration Strategy

- **000_BASELINE**: Canonical schema for NEW environments only
- **001-061**: Incremental migrations for existing databases
- **Archived**: Superseded migrations moved to `/supabase/migrations_archived/`

---

## 000_BASELINE_CANONICAL_SCHEMA (Bootstrap)

**Purpose**: Complete schema for bootstrapping new development/staging environments.

**WARNING**: Do NOT run on existing databases. For new environments only.

**Contains**:
- All tables (stores, orders, menu_items, customers, user_profiles, etc.)
- All indexes and constraints
- All helper functions (get_current_user_role, is_current_user_system_admin, etc.)
- All RLS policies
- All triggers (order_number generation, rewards calculation, etc.)
- Materialized views for analytics

---

## Migration Groups

### 001-003: Initial Schema + Seed Data

| Migration | Purpose |
|-----------|---------|
| 001_initial_schema.sql | Core tables: stores, user_profiles, menu_items, orders, order_items, rewards |
| 002_row_level_security.sql | Initial RLS policies for all tables |
| 003_seed_data.sql | Sample data for development |

### 004-009: Schema Fixes + Real Data

| Migration | Purpose |
|-----------|---------|
| 004_fix_rls_circular_dependency.sql | Fix recursive RLS policy issues |
| 005_fix_auth_schema.sql | Auth schema corrections |
| 006_launch_single_store.sql | Highland Mills single-store launch config |
| 007_real_menu_data.sql | Real menu items from Cross River location |
| 008_use_placeholder_images.sql | Placeholder images for menu items |
| 009_update_menu_images.sql | Menu image URL updates |

### 010-020: Menu Access + Guest Checkout

| Migration | Purpose |
|-----------|---------|
| 010_allow_anonymous_menu_access.sql | Public menu browsing |
| 011_create_menu_view_with_price.sql | Menu view with pricing |
| 012_fix_ios_compatibility.sql | iOS app compatibility fixes |
| 013_add_price_column_to_menu_items.sql | Price column for iOS |
| 014-016 | **ARCHIVED** - Image checking scripts |
| 017_update_to_storage_urls.sql | Supabase Storage CDN URLs |
| 018_update_storage_urls_final.sql | Final storage URL updates |
| 019_allow_anon_order_updates.sql | Guest order status updates |
| 020_simplify_order_policies.sql | Simplified order RLS |

### 021-030: Order Features + Customer Profiles

| Migration | Purpose |
|-----------|---------|
| 021_allow_public_order_history_insert.sql | Order history for guests |
| 022_add_customizations_columns.sql | Order item customizations |
| 023_order_number_system.sql | Human-readable order numbers |
| 024_analytics_views.sql | Analytics views and functions |
| 025_customer_profiles.sql | Customer profile enhancements |
| 026_rollback_user_profiles.sql | User profile rollback |
| 027_fix_security_vulnerabilities.sql | Security fixes |
| 028_fix_remaining_security_issues.sql | Additional security fixes |
| 029_update_user_profiles_rbac.sql | RBAC updates |
| 030_create_store_assignments.sql | Multi-store assignments |

### 031-040: RLS Evolution + Hierarchy

| Migration | Purpose |
|-----------|---------|
| 031_create_user_hierarchy.sql | **DEPRECATED** - User hierarchy |
| 032_create_permission_changes.sql | Permission audit trail |
| 033_comprehensive_rls_policies.sql | Comprehensive RLS |
| 034_fix_rls_infinite_recursion.sql | Fix RLS recursion |
| 035_fix_rls_with_public_functions.sql | SECURITY DEFINER helpers |
| 036_complete_policy_cleanup.sql | Policy cleanup |
| 037_comprehensive_policy_migration.sql | Full policy migration |
| 038_fix_permission_changes_policies.sql | Permission changes RLS |
| 039_fix_all_remaining_recursive_policies.sql | Final recursion fixes |
| 040_fix_orders_auth_users_access.sql | Orders auth access |

### 041-049: Customer/Staff Separation + Multi-Location

| Migration | Purpose |
|-----------|---------|
| 041_SUPERSEDED | **ARCHIVED** - First attempt at customer separation |
| 041_v2_separate_customer_and_staff_signups.sql | Dual-profile system |
| 042_SUPERSEDED | **ARCHIVED** - First attempt at portions |
| 042_portion_based_customizations_v2.sql | Portion-based customizations |
| 043_optimize_rls_performance.sql | RLS performance optimization |
| 044_link_ingredients_to_menu_items.sql | Ingredient linking |
| 045_add_customizations_to_all_items.sql | Universal customizations |
| 046_fix_guest_checkout.sql | Guest checkout fixes |
| 047_multi_location_management.sql | Organizations, regions, multi-store |
| 048_security_fixes.sql | Security hardening |
| 049_setup_scheduled_jobs.sql | Scheduled cleanup jobs |

### 050-061: Performance + Rewards + Cleanup

| Migration | Purpose |
|-----------|---------|
| 055_deprecate_hierarchy.sql | Mark hierarchy as deprecated |
| 056_rewards_schema_alignment.sql | Rewards table alignment |
| 057_remove_user_hierarchy.sql | Remove unused hierarchy |
| 058_wrap_legacy_analytics.sql | Analytics function wrappers |
| 059_rls_policy_cleanup.sql | Consolidate RLS policies |
| 060_create_materialized_views.sql | Analytics materialized views |
| 061_add_missing_indexes.sql | Performance indexes |

---

## Archived Migrations

Located in `/supabase/migrations_archived/`:

| File | Reason |
|------|--------|
| 014_check_current_images.sql | Diagnostic script, not a migration |
| 015_check_signature_sandwich_images.sql | Diagnostic script |
| 016_comprehensive_image_check.sql | Diagnostic script |
| 041_SUPERSEDED_separate_customer_and_staff_signups.sql | Replaced by 041_v2 |
| 042_SUPERSEDED_portion_based_customizations.sql | Replaced by 042_v2 |

---

## Key Schema Components

### Core Tables

```
stores                    - 29 Cameron's locations
orders                    - Customer orders
order_items              - Items within orders
order_status_history     - Order audit trail
```

### Menu/Catalog

```
menu_categories          - Food categories
menu_items              - Individual menu items
menu_item_customizations - Portion-based customizations
ingredient_templates    - Reusable ingredient definitions
```

### Customers & Rewards

```
customers               - Customer profiles (separate from staff)
customer_rewards        - Points, tier, lifetime stats
rewards_transactions    - Points earned/redeemed history
customer_favorites      - Saved menu items
```

### Organization/Staff

```
user_profiles           - Business users (staff/manager/admin)
store_assignments       - Multi-store access
permission_changes      - Audit trail
organizations          - Multi-location hierarchy
regions                - Store groupings
```

### Analytics

```
daily_analytics         - Legacy daily aggregates
daily_metrics          - Modern daily metrics
hourly_metrics         - Hourly breakdowns
mv_popular_items       - Materialized view
mv_top_customers       - Materialized view
mv_store_daily_summary - Materialized view
mv_hourly_traffic      - Materialized view
```

---

## Helper Functions

| Function | Purpose |
|----------|---------|
| `get_current_user_role()` | Returns user's role (super_admin, admin, manager, staff, customer) |
| `is_current_user_system_admin()` | Checks if user is system admin |
| `get_current_user_assigned_stores()` | Returns INT[] of assigned store IDs |
| `get_current_user_store_id()` | Returns user's primary store ID |
| `can_access_analytics(store_id)` | Checks analytics access permission |
| `refresh_analytics_materialized_views()` | Refreshes all analytics views |

---

## Running Migrations

### New Environment

```sql
-- Run ONLY the baseline
\i supabase/migrations/000_BASELINE_CANONICAL_SCHEMA.sql
```

### Existing Environment

```sql
-- Run migrations in numerical order
\i supabase/migrations/001_initial_schema.sql
\i supabase/migrations/002_row_level_security.sql
-- ... continue through 061
```

### Via Supabase CLI

```bash
# Apply all pending migrations
supabase db push

# Reset and reapply all
supabase db reset
```

---

## Notes

1. **Never delete migrations** - Keep for historical reference
2. **Use IF EXISTS/IF NOT EXISTS** - Make migrations idempotent
3. **Test on staging first** - Always validate before production
4. **Backup before major changes** - Especially RLS policy changes
