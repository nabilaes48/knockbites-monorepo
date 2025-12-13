# Camerons Connect — Supabase Contract

**Single Source of Truth for All Three Clients**

This document defines the canonical data contracts shared between:
- **Business iOS App** — Staff management, orders, analytics
- **Customer iOS App** — Customer ordering, favorites, profiles
- **Website (React)** — Full-featured web interface

All three apps share the same Supabase backend. Any schema changes MUST be reflected here and backwards-compatible with all clients.

---

## Table of Contents

1. [Core Tables](#core-tables)
2. [Order Domain](#order-domain)
3. [Menu Domain](#menu-domain)
4. [Marketing Domain](#marketing-domain)
5. [Customer Domain](#customer-domain)
6. [Analytics Domain](#analytics-domain)
7. [RPC Functions](#rpc-functions)
8. [Date Format Standard](#date-format-standard)
9. [Field Aliasing Rules](#field-aliasing-rules)
10. [Deprecation Policy](#deprecation-policy)

---

## Core Tables

### Table Names (Canonical)

```swift
// Swift (Business & Customer apps)
enum TableNames {
    static let stores = "stores"
    static let orders = "orders"
    static let orderItems = "order_items"
    static let menuItems = "menu_items"
    static let menuCategories = "menu_categories"  // Also aliased as "categories"
    static let userProfiles = "user_profiles"
    static let customers = "customers"
}
```

```typescript
// TypeScript (Website)
const TableNames = {
  stores: "stores",
  orders: "orders",
  orderItems: "order_items",
  menuItems: "menu_items",
  menuCategories: "menu_categories",  // Alias: "categories"
  userProfiles: "user_profiles",
  customers: "customers",
} as const;
```

---

## Order Domain

### `orders` Table

| Column | Type | Nullable | Used By | Notes |
|--------|------|----------|---------|-------|
| `id` | UUID | No | All | Primary key |
| `order_number` | varchar | No | All | Human-readable (HM-251119-001) |
| `user_id` | UUID | Yes | All | Auth user ID |
| `customer_id` | varchar | Yes | Website | Customer table FK |
| `customer_name` | varchar | No | All | Display name |
| `customer_email` | varchar | Yes | Business | |
| `customer_phone` | varchar | No | All | |
| `store_id` | int | No | All | FK to stores |
| `order_type` | varchar | Yes | All | `pickup`, `delivery`, `dine-in` |
| `status` | varchar | No | All | See status values below |
| `subtotal` | decimal | No | All | |
| `tax` | decimal | No | All | |
| `tip` | decimal | Yes | Website | |
| `total` | decimal | No | All | |
| `special_instructions` | text | Yes | Website | Order-level notes |
| `priority` | varchar | Yes | Website | |
| `is_repeat_customer` | bool | Yes | Website | |
| `created_at` | timestamp | No | All | ISO 8601 |
| `estimated_ready_at` | timestamp | Yes | All | ISO 8601 |
| `completed_at` | timestamp | Yes | All | ISO 8601 |
| `updated_at` | timestamp | Yes | Website | ISO 8601 |

**Order Status Values:**
- `pending` — Order created, awaiting confirmation
- `received` — Confirmed, queued for kitchen
- `acknowledged` — Kitchen acknowledged (KDS)
- `preparing` — Currently being made
- `ready` — Ready for pickup/delivery
- `completed` — Order fulfilled
- `cancelled` — Order cancelled
- `scheduled` — Future order

### `order_items` Table

| Column | Type | Nullable | Used By | Notes |
|--------|------|----------|---------|-------|
| `id` | int | No | All | Primary key |
| `order_id` | UUID | No | All | FK to orders |
| `menu_item_id` | int | Yes | All | FK to menu_items |
| `item_name` | varchar | No | All | Snapshot of name |
| `item_price` | decimal | No | All | Snapshot of price |
| `quantity` | int | No | All | |
| `subtotal` | decimal | No | All | |
| `special_instructions` | text | Yes | iOS | Item-level notes |
| `notes` | text | Yes | Website | Same as special_instructions |
| `customizations` | varchar[] | Yes | All | Array of strings |
| `selected_options` | jsonb | Yes | All | Structured options |

---

## Menu Domain

### `menu_items` Table

| Column | Type | Nullable | Used By | Notes |
|--------|------|----------|---------|-------|
| `id` | int | No | All | Primary key |
| `name` | varchar | No | All | |
| `description` | text | Yes | All | |
| `price` | decimal | Yes | Customer | Legacy field |
| `base_price` | decimal | No | Website | Primary price field |
| `category_id` | int | Yes | All | FK to menu_categories |
| `image_url` | varchar | Yes | All | Relative or absolute |
| `is_available` | bool | No | All | |
| `is_featured` | bool | Yes | Website | |
| `calories` | int | Yes | All | |
| `prep_time` | int | Yes | iOS | Minutes |
| `preparation_time` | int | Yes | Website | Minutes (alias) |
| `allergens` | varchar[] | Yes | Website | |
| `tags` | varchar[] | Yes | Website | |
| `created_at` | timestamp | Yes | All | |
| `updated_at` | timestamp | Yes | Website | |

**Price Field Resolution:**
```swift
// Customer app handles multiple price fields
var actualPrice: Double {
    return price ?? item_price ?? base_price ?? 0.0
}
```

### `menu_categories` Table

| Column | Type | Nullable | Used By | Notes |
|--------|------|----------|---------|-------|
| `id` | int | No | All | Primary key |
| `name` | varchar | No | All | |
| `icon` | varchar | Yes | iOS | Emoji |
| `description` | text | Yes | Website | |
| `display_order` | int | Yes | All | Sort order |
| `is_active` | bool | Yes | Website | |

**Note:** Customer app uses table name `categories` which is an alias.

### `menu_item_customizations` Table

| Column | Type | Nullable | Used By | Notes |
|--------|------|----------|---------|-------|
| `id` | int | No | All | Primary key |
| `menu_item_id` | int | No | All | FK to menu_items |
| `name` | varchar | No | All | |
| `category` | varchar | Yes | All | Grouping |
| `type` | varchar | Yes | Website | |
| `options` | jsonb | No | Website | Option definitions |
| `supports_portions` | bool | Yes | All | Portion-based |
| `default_portion` | varchar | Yes | All | |
| `portion_pricing` | jsonb | Yes | All | Price per portion |
| `display_order` | int | Yes | All | |
| `is_required` | bool | Yes | Website | |

### `ingredient_templates` Table

| Column | Type | Nullable | Used By | Notes |
|--------|------|----------|---------|-------|
| `id` | int | No | All | Primary key |
| `name` | varchar | No | All | |
| `category` | varchar | No | All | |
| `supports_portions` | bool | Yes | All | |
| `default_portion` | varchar | Yes | All | |
| `portion_pricing` | jsonb | Yes | All | |
| `display_order` | int | Yes | All | |
| `is_active` | bool | No | All | |

---

## Marketing Domain

### `coupons` Table

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | int | No | Primary key |
| `store_id` | int | No | FK to stores |
| `code` | varchar | No | Unique code |
| `name` | varchar | No | |
| `description` | text | Yes | |
| `discount_type` | varchar | No | `percentage`, `fixed` |
| `discount_value` | decimal | No | |
| `min_order_value` | decimal | Yes | |
| `max_discount_amount` | decimal | Yes | |
| `first_order_only` | bool | Yes | |
| `max_uses_total` | int | Yes | |
| `max_uses_per_customer` | int | No | |
| `current_uses` | int | Yes | |
| `start_date` | timestamp | No | |
| `end_date` | timestamp | Yes | |
| `is_active` | bool | No | |
| `is_featured` | bool | Yes | |
| `created_at` | timestamp | Yes | |
| `updated_at` | timestamp | Yes | |

### `loyalty_programs` Table

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | int | No | Primary key |
| `store_id` | int | No | FK to stores |
| `name` | varchar | No | |
| `points_per_dollar` | decimal | Yes | |
| `welcome_bonus_points` | int | Yes | |
| `referral_bonus_points` | int | Yes | |
| `is_active` | bool | No | |
| `created_at` | timestamp | Yes | |
| `updated_at` | timestamp | Yes | |

### `loyalty_tiers` Table

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | int | No | Primary key |
| `program_id` | int | No | FK to loyalty_programs |
| `name` | varchar | No | e.g., "Bronze", "Silver" |
| `min_points` | int | No | Points threshold |
| `discount_percentage` | decimal | Yes | |
| `free_delivery` | bool | Yes | |
| `priority_support` | bool | Yes | |
| `early_access_promos` | bool | Yes | |
| `birthday_reward_points` | int | Yes | |
| `tier_color` | varchar | Yes | Hex color |
| `sort_order` | int | No | |
| `created_at` | timestamp | Yes | |

### `customer_loyalty` Table

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | int | No | Primary key |
| `customer_id` | int | Yes | FK to customers |
| `program_id` | int | Yes | FK to loyalty_programs |
| `current_tier_id` | int | Yes | FK to loyalty_tiers |
| `total_points` | int | Yes | Current balance |
| `lifetime_points` | int | Yes | All-time earned |
| `total_orders` | int | Yes | |
| `total_spent` | decimal | Yes | |
| `joined_at` | timestamp | Yes | |
| `last_order_at` | timestamp | Yes | |
| `updated_at` | timestamp | Yes | |

### `loyalty_transactions` Table

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | int | No | Primary key |
| `customer_loyalty_id` | int | Yes | FK |
| `order_id` | UUID | Yes | FK to orders |
| `transaction_type` | varchar | No | `earn`, `redeem`, `bonus`, `adjustment` |
| `points` | int | No | Positive or negative |
| `reason` | text | Yes | Description |
| `balance_after` | int | No | Running balance |
| `created_at` | timestamp | Yes | |

### `automated_campaigns` Table

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | int | No | Primary key |
| `store_id` | int | Yes | FK to stores |
| `campaign_type` | varchar | Yes | |
| `name` | varchar | No | |
| `description` | text | Yes | |
| `trigger_condition` | jsonb | Yes | Complex rules |
| `trigger_event` | varchar | Yes | |
| `trigger_delay_hours` | int | Yes | |
| `notification_title` | varchar | Yes | |
| `notification_body` | text | Yes | |
| `coupon_id` | int | Yes | FK to coupons |
| `is_active` | bool | Yes | |
| `total_triggered` | int | Yes | |
| `total_converted` | int | Yes | |
| `created_at` | timestamp | Yes | |
| `updated_at` | timestamp | Yes | |

---

## Customer Domain

### `customers` Table

| Column | Type | Nullable | Used By | Notes |
|--------|------|----------|---------|-------|
| `id` | UUID | No | All | Primary key |
| `auth_user_id` | UUID | Yes | Customer | Auth FK |
| `email` | varchar | Yes | All | |
| `full_name` | varchar | Yes | All | |
| `first_name` | varchar | Yes | Customer | |
| `last_name` | varchar | Yes | Customer | |
| `phone` | varchar | Yes | Website | |
| `phone_number` | varchar | Yes | Customer | Alias |
| `avatar_url` | varchar | Yes | Website | |
| `dietary_preferences` | varchar[] | Yes | Customer | |
| `allergens` | varchar[] | Yes | Customer | |
| `spicy_tolerance` | varchar | Yes | Customer | |
| `default_store_id` | int | Yes | Customer | |
| `preferred_order_type` | varchar | Yes | Customer | |
| `created_at` | timestamp | Yes | All | |
| `updated_at` | timestamp | Yes | All | |

### `customer_addresses` Table

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | int | No | Primary key |
| `customer_id` | varchar | No | FK |
| `label` | varchar | Yes | e.g., "Home", "Work" |
| `street_address` | varchar | No | |
| `apartment` | varchar | Yes | |
| `city` | varchar | No | |
| `state` | varchar | No | |
| `zip_code` | varchar | No | |
| `phone_number` | varchar | Yes | |
| `delivery_instructions` | text | Yes | |
| `is_default` | bool | Yes | |
| `created_at` | timestamp | Yes | |
| `updated_at` | timestamp | Yes | |

### `customer_favorites` Table

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | int | No | Primary key |
| `customer_id` | varchar | No | FK |
| `menu_item_id` | int | No | FK to menu_items |
| `created_at` | timestamp | Yes | |

---

## Analytics Domain

### Views (Read-Only)

These are PostgreSQL views created by migration 024.

#### `analytics_daily_stats`

```sql
SELECT
    store_id,
    date,
    total_orders,
    total_revenue,
    total_tax,
    avg_order_value,
    unique_customers
FROM analytics_daily_stats
WHERE store_id = ?;
```

#### `analytics_hourly_today`

```sql
SELECT
    store_id,
    hour,
    orders,
    revenue
FROM analytics_hourly_today
WHERE store_id = ?;
```

#### `analytics_popular_items`

```sql
SELECT
    store_id,
    menu_item_id,
    item_name,
    times_ordered,
    total_quantity,
    total_revenue,
    avg_price
FROM analytics_popular_items
WHERE store_id = ?;
```

---

## RPC Functions

### `get_store_metrics`

**Purpose:** Get aggregated metrics for a store with period comparison.

**Parameters:**
```sql
p_store_id: int
p_date_range: text  -- 'today', 'week', 'month', 'year'
```

**Returns:**
```typescript
{
  total_revenue: number;
  total_orders: number;
  avg_order_value: number;
  unique_customers: number;
  revenue_change: number | null;  // Comparison to previous period
  orders_change: number | null;
}
```

**Used By:** Business iOS only

### `get_revenue_chart_data`

**Purpose:** Get time-series revenue data for charts.

**Parameters:**
```sql
p_store_id: int
p_date_range: text  -- 'today', 'week', 'month', 'year'
```

**Returns:**
```typescript
Array<{
  time_label: string;
  revenue: number;
  orders: number;
}>
```

**Used By:** Business iOS only

---

## Date Format Standard

All timestamps use ISO 8601 format.

### Accepted Formats

```
Standard:    2025-12-02T10:30:00Z
Fractional:  2025-12-02T10:30:00.123456Z
```

### Parsing Implementation

**Swift (Required for all iOS apps):**
```swift
static func parseISO8601(_ string: String) -> Date? {
    // Try standard format first
    if let date = iso8601.date(from: string) {
        return date
    }
    // Try with fractional seconds
    if let date = iso8601Fractional.date(from: string) {
        return date
    }
    return nil
}
```

**TypeScript (Website):**
```typescript
// JavaScript's Date handles both formats automatically
const date = new Date(timestamp);
```

---

## Field Aliasing Rules

Some fields have different names in different clients. These are canonical mappings:

| Database Column | Business iOS | Customer iOS | Website |
|-----------------|--------------|--------------|---------|
| `estimated_ready_at` | `estimatedReadyTime`* | `estimated_ready_at` | `estimated_ready_at` |
| `base_price` | `price` | `price`/`base_price` | `base_price` |
| `preparation_time` | `prep_time` | `prep_time` | `preparation_time` |
| `notification_body` | `notificationMessage`* | N/A | `notification_body` |
| `total_triggered` | `timesTriggered`* | N/A | `total_triggered` |
| `phone_number` | N/A | `phone_number` | `phone` |

\* Business app uses computed properties for backwards compatibility

---

## Deprecation Policy

### Adding New Fields

1. Add field as **nullable** in database
2. Update Website types (auto-generated)
3. Update iOS apps to handle presence/absence gracefully
4. Document in this contract

### Removing Fields

1. Add deprecation notice to this document
2. Wait minimum 30 days
3. Keep field in database, make optional
4. Remove from code after all clients updated

### Renaming Fields

**Never rename fields directly.** Instead:
1. Add new field
2. Copy data from old field
3. Update all clients to use new field
4. Deprecate old field
5. After 30 days, remove old field

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-02 | Phase 6 | Initial contract document |
