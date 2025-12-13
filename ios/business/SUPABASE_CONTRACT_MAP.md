# Supabase Contract Map — Camerons Connect Platform

**Generated:** 2025-12-02
**Scope:** Business iOS App, Customer iOS App, Website (React)

This document serves as the canonical reference for all Supabase table contracts shared across the three Camerons Connect clients.

---

## Table of Contents

1. [Orders Domain](#orders-domain)
2. [Menu Domain](#menu-domain)
3. [Marketing Domain](#marketing-domain)
4. [Analytics Domain](#analytics-domain)
5. [Customer Domain](#customer-domain)
6. [RPC Functions](#rpc-functions)
7. [Date Format Standards](#date-format-standards)

---

## Orders Domain

### Table: `orders`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | UUID (string) | Yes | All |
| `order_number` | string | Yes | All |
| `user_id` | UUID (string) | No | All |
| `customer_id` | string | No | Website |
| `customer_name` | string | Yes | All |
| `customer_email` | string | No | Business |
| `customer_phone` | string | Yes | All |
| `store_id` | int | Yes | All |
| `order_type` | string | No | All |
| `status` | string | Yes | All |
| `subtotal` | double | Yes | All |
| `tax` | double | Yes | All |
| `tip` | double | No | Website |
| `total` | double | Yes | All |
| `special_instructions` | string | No | Website |
| `priority` | string | No | Website |
| `is_repeat_customer` | boolean | No | Website |
| `created_at` | ISO8601 string | Yes | All |
| `estimated_ready_time` | ISO8601 string | No | Business |
| `estimated_ready_at` | ISO8601 string | No | Customer, Website |
| `completed_at` | ISO8601 string | No | All |
| `updated_at` | ISO8601 string | No | Website |

**Contract Notes:**
- Business app uses `estimated_ready_time`, Customer/Website use `estimated_ready_at`
- Both field names map to the same database column
- Status values: `pending`, `received`, `acknowledged`, `preparing`, `ready`, `completed`, `cancelled`, `scheduled`
- Order types: `pickup`, `delivery`, `dine-in` (Website also accepts `dine_in`)

### Table: `order_items`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `order_id` | UUID (string) | Yes | All |
| `menu_item_id` | int | No | All |
| `item_name` | string | Yes | All |
| `item_price` | double | Yes | All |
| `quantity` | int | Yes | All |
| `subtotal` | double | Yes | All |
| `special_instructions` | string | No | Business |
| `notes` | string | No | Website |
| `customizations` | string[] | No | All |
| `selected_options` | JSON | No | All |

**Contract Notes:**
- Business uses `special_instructions`, Website uses `notes` - same purpose
- `customizations` can be string[] or JSON string
- `selected_options` is `[String: [String]]` dict or JSON

---

## Menu Domain

### Table: `menu_items`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `name` | string | Yes | All |
| `description` | string | No | All |
| `price` | double | No | Customer |
| `base_price` | double | Yes | Website |
| `item_price` | double | No | Customer (fallback) |
| `category_id` | int | No | All |
| `category` | string | No | Customer (fallback) |
| `image_url` | string | No | All |
| `is_available` | boolean | Yes | All |
| `is_featured` | boolean | No | Website |
| `calories` | int | No | All |
| `prep_time` | int | No | Business, Customer |
| `prep_time_minutes` | int | No | Customer (fallback) |
| `preparation_time` | int | No | Website |
| `allergens` | string[] | No | Website |
| `tags` | string[] | No | Website |
| `created_at` | ISO8601 string | No | All |
| `updated_at` | ISO8601 string | No | Website |

**Contract Notes:**
- Customer app handles multiple price field names: `price`, `item_price`, `base_price`
- Customer app handles multiple prep time fields: `prep_time`, `prep_time_minutes`
- Website uses `base_price` as primary, `price` as fallback

### Table: `menu_categories` / `categories`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `name` | string | Yes | All |
| `icon` | string | No | Business, Customer |
| `description` | string | No | Website |
| `sort_order` | int | No | Customer |
| `display_order` | int | No | Customer, Website |
| `is_active` | boolean | No | Website |
| `created_at` | ISO8601 string | No | Website |

**Contract Notes:**
- Customer app uses table name `categories`
- Business app uses table name `menu_categories`
- Both refer to same table (alias)

### Table: `menu_item_customizations`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `menu_item_id` | int | Yes | All |
| `name` | string | Yes | All |
| `category` | string | No | All |
| `type` | string | No | Website |
| `options` | JSON | Yes | Website |
| `supports_portions` | boolean | No | All |
| `default_portion` | string | No | All |
| `portion_pricing` | JSON | No | All |
| `display_order` | int | No | All |
| `is_required` | boolean | No | Website |

### Table: `ingredient_templates`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `name` | string | Yes | All |
| `category` | string | Yes | All |
| `supports_portions` | boolean | No | All |
| `default_portion` | string | No | All |
| `portion_pricing` | JSON | No | All |
| `display_order` | int | No | All |
| `is_active` | boolean | Yes | All |
| `created_at` | ISO8601 string | No | All |
| `updated_at` | ISO8601 string | No | All |

---

## Marketing Domain

### Table: `coupons`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `store_id` | int | Yes | All |
| `code` | string | Yes | All |
| `name` | string | Yes | All |
| `description` | string | No | All |
| `discount_type` | string | Yes | All |
| `discount_value` | double | Yes | All |
| `min_order_value` | double | No | All |
| `max_discount_amount` | double | No | Business |
| `applicable_order_types` | string[] | No | Business |
| `applicable_menu_categories` | int[] | No | Business |
| `first_order_only` | boolean | No | All |
| `max_uses_total` | int | No | All |
| `max_uses_per_customer` | int | Yes | All |
| `current_uses` | int | No | All |
| `start_date` | ISO8601 string | Yes | All |
| `end_date` | ISO8601 string | No | All |
| `active_days_of_week` | int[] | No | Business |
| `active_hours_start` | string | No | Business |
| `active_hours_end` | string | No | Business |
| `target_segment` | string | No | Business |
| `minimum_tier_id` | int | No | All |
| `is_active` | boolean | Yes | All |
| `is_featured` | boolean | No | All |
| `created_at` | ISO8601 string | No | All |
| `created_by` | UUID | No | Website |
| `updated_at` | ISO8601 string | No | All |

### Table: `push_notifications`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `store_id` | int | Yes | All |
| `title` | string | Yes | All |
| `body` | string | Yes | All |
| `image_url` | string | No | All |
| `action_url` | string | No | All |
| `target_segment` | string | No | All |
| `target_customer_ids` | int[] | No | All |
| `target_tier_ids` | int[] | No | All |
| `scheduled_for` | ISO8601 string | No | All |
| `send_immediately` | boolean | Yes | All |
| `status` | string | Yes | All |
| `sent_at` | ISO8601 string | No | All |
| `recipients_count` | int | No | All |
| `delivered_count` | int | No | All |
| `opened_count` | int | No | All |
| `clicked_count` | int | No | All |
| `created_at` | ISO8601 string | No | All |
| `created_by` | UUID | No | Website |
| `updated_at` | ISO8601 string | No | All |

### Table: `loyalty_programs`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `store_id` | int | Yes | All |
| `name` | string | Yes | All |
| `points_per_dollar` | double | No | All |
| `welcome_bonus_points` | int | No | All |
| `referral_bonus_points` | int | No | All |
| `is_active` | boolean | Yes | All |
| `created_at` | ISO8601 string | No | All |
| `updated_at` | ISO8601 string | No | All |

### Table: `loyalty_tiers`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `program_id` | int | Yes | All |
| `name` | string | Yes | All |
| `min_points` | int | Yes | All |
| `discount_percentage` | double | No | All |
| `free_delivery` | boolean | No | All |
| `priority_support` | boolean | No | All |
| `early_access_promos` | boolean | No | All |
| `birthday_reward_points` | int | No | All |
| `tier_color` | string | No | All |
| `sort_order` | int | Yes | All |
| `created_at` | ISO8601 string | No | All |

### Table: `loyalty_rewards`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | Business |
| `program_id` | int | Yes | Business |
| `name` | string | Yes | Business |
| `description` | string | No | Business |
| `points_cost` | int | Yes | Business |
| `reward_type` | string | Yes | Business |
| `reward_value` | string | Yes | Business |
| `image_url` | string | No | Business |
| `is_active` | boolean | Yes | Business |
| `stock_quantity` | int | No | Business |
| `redemption_count` | int | No | Business |
| `sort_order` | int | No | Business |
| `created_at` | ISO8601 string | No | Business |
| `updated_at` | ISO8601 string | No | Business |

### Table: `customer_loyalty`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `customer_id` | int | No | All |
| `program_id` | int | No | All |
| `current_tier_id` | int | No | All |
| `total_points` | int | No | All |
| `lifetime_points` | int | No | All |
| `total_orders` | int | No | All |
| `total_spent` | double | No | All |
| `joined_at` | ISO8601 string | No | All |
| `last_order_at` | ISO8601 string | No | All |
| `updated_at` | ISO8601 string | No | All |

### Table: `loyalty_transactions`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `customer_loyalty_id` | int | No | All |
| `order_id` | UUID | No | All |
| `transaction_type` | string | Yes | All |
| `points` | int | Yes | All |
| `reason` | string | No | All |
| `balance_after` | int | Yes | All |
| `created_at` | ISO8601 string | No | All |

### Table: `referral_program`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `store_id` | int | No | All |
| `referrer_reward_type` | string | No | All |
| `referrer_reward_value` | double | No | All |
| `referee_reward_type` | string | No | All |
| `referee_reward_value` | double | No | All |
| `min_order_value` | double | No | All |
| `max_referrals_per_customer` | int | No | All |
| `is_active` | boolean | No | All |
| `created_at` | ISO8601 string | No | All |
| `updated_at` | ISO8601 string | No | All |

### Table: `referrals`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `program_id` | int | No | All |
| `referral_code` | string | Yes | All |
| `referrer_customer_id` | int | No | All |
| `referee_customer_id` | int | No | All |
| `status` | string | No | All |
| `referrer_rewarded` | boolean | No | All |
| `referee_rewarded` | boolean | No | All |
| `created_at` | ISO8601 string | No | All |
| `completed_at` | ISO8601 string | No | All |
| `rewarded_at` | ISO8601 string | No | All |

### Table: `automated_campaigns`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `store_id` | int | No | All |
| `campaign_type` | string | No | All |
| `name` | string | Yes | All |
| `description` | string | No | All |
| `trigger_condition` | string/JSON | No | Business/Website |
| `trigger_value` | int | No | Business |
| `trigger_event` | string | No | Website |
| `trigger_delay_hours` | int | No | Website |
| `notification_title` | string | Yes | Business |
| `notification_message` | string | Yes | Business |
| `notification_body` | string | No | Website |
| `cta_type` | string | No | Business |
| `cta_value` | string | No | Business |
| `coupon_id` | int | No | Website |
| `target_audience` | string | No | Business |
| `is_active` | boolean | No | All |
| `times_triggered` | int | No | Business |
| `total_triggered` | int | No | Website |
| `conversion_count` | int | No | Business |
| `total_converted` | int | No | Website |
| `revenue_generated` | double | No | Business |
| `created_at` | ISO8601 string | No | All |
| `updated_at` | ISO8601 string | No | All |

**Contract Notes:**
- Business uses `notification_title`/`notification_message`
- Website uses `notification_title`/`notification_body`
- Business uses `times_triggered`/`conversion_count`
- Website uses `total_triggered`/`total_converted`

---

## Analytics Domain

### Table: `analytics_daily_stats` (View)

| Column | Type | Used By |
|--------|------|---------|
| `store_id` | int | Business |
| `date` | string | Business |
| `total_orders` | int | Business |
| `total_revenue` | decimal | Business |
| `total_tax` | decimal | Business |
| `avg_order_value` | decimal | Business |
| `unique_customers` | int | Business |

### Table: `analytics_hourly_today` (View)

| Column | Type | Used By |
|--------|------|---------|
| `store_id` | int | Business |
| `hour` | int | Business |
| `orders` | int | Business |
| `revenue` | decimal | Business |

### Table: `analytics_popular_items` (View)

| Column | Type | Used By |
|--------|------|---------|
| `store_id` | int | Business |
| `menu_item_id` | int | Business |
| `item_name` | string | Business |
| `times_ordered` | int | Business |
| `total_quantity` | int | Business |
| `total_revenue` | decimal | Business |
| `avg_price` | decimal | Business |

---

## Customer Domain

### Table: `stores`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `name` | string | Yes | All |
| `address` | string | Yes | Customer |
| `city` | string | Yes | Customer |
| `state` | string | Yes | Customer |
| `zip` | string | Yes | Customer |
| `phone_number` | string | No | Customer |
| `latitude` | double | Yes | Customer |
| `longitude` | double | Yes | Customer |
| `hours_open` | string | No | Customer |
| `hours_close` | string | No | Customer |
| `is_open` | boolean | Yes | Customer |
| `created_at` | ISO8601 string | No | All |

### Table: `customers`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | UUID | Yes | All |
| `auth_user_id` | UUID | No | Customer |
| `email` | string | No | All |
| `full_name` | string | No | All |
| `first_name` | string | No | Customer |
| `last_name` | string | No | Customer |
| `phone` | string | No | Website |
| `phone_number` | string | No | Customer |
| `avatar_url` | string | No | Website |
| `dietary_preferences` | string[] | No | Customer |
| `allergens` | string[] | No | Customer |
| `spicy_tolerance` | string | No | Customer |
| `default_store_id` | int | No | Customer |
| `preferred_order_type` | string | No | Customer |
| `created_at` | ISO8601 string | No | All |
| `updated_at` | ISO8601 string | No | All |

**Contract Notes:**
- Website uses `phone`, Customer uses `phone_number`
- Customer uses separate `first_name`/`last_name`, others use `full_name`

### Table: `customer_addresses`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `customer_id` | string | Yes | All |
| `label` | string | No | All |
| `street_address` | string | Yes | All |
| `apartment` | string | No | All |
| `city` | string | Yes | All |
| `state` | string | Yes | All |
| `zip_code` | string | Yes | All |
| `phone_number` | string | No | All |
| `delivery_instructions` | string | No | All |
| `is_default` | boolean | No | All |
| `created_at` | ISO8601 string | No | All |
| `updated_at` | ISO8601 string | No | All |

### Table: `customer_favorites`

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | int | Yes | All |
| `customer_id` | string | Yes | All |
| `menu_item_id` | int | Yes | All |
| `created_at` | ISO8601 string | No | All |

### Table: `user_profiles` (Business Staff)

| Column | Type | Required | Used By |
|--------|------|----------|---------|
| `id` | UUID | Yes | Business |
| `full_name` | string | No | Business |
| `role` | string | No | Business |
| `store_ids` | int[] | No | Business |
| `permissions` | string[] | No | Business |
| `created_at` | ISO8601 string | No | Business |
| `updated_at` | ISO8601 string | No | Business |

---

## RPC Functions

### `get_store_metrics`

**Parameters:**
- `p_store_id`: int
- `p_date_range`: string (`today`, `week`, `month`, `year`)

**Returns:**
```json
{
  "total_revenue": decimal,
  "total_orders": int,
  "avg_order_value": decimal,
  "unique_customers": int,
  "revenue_change": decimal (nullable),
  "orders_change": int (nullable)
}
```

**Used By:** Business iOS (AnalyticsService)

### `get_revenue_chart_data`

**Parameters:**
- `p_store_id`: int
- `p_date_range`: string (`today`, `week`, `month`, `year`)

**Returns:**
```json
[
  {
    "time_label": string,
    "revenue": decimal,
    "orders": int
  }
]
```

**Used By:** Business iOS (AnalyticsService)

---

## Date Format Standards

All dates in Supabase follow ISO 8601 format:

### Standard Format (No Fractional Seconds)
```
2025-12-02T10:30:00Z
```

### Fractional Seconds Format
```
2025-12-02T10:30:00.123456Z
```

### Parsing Requirements

All clients MUST support both formats. The Business app's `DateFormatting` utility handles this:

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

---

## Cross-App Field Aliases

| Database Column | Business App | Customer App | Website |
|-----------------|--------------|--------------|---------|
| `estimated_ready_at` | `estimated_ready_time` | `estimated_ready_at` | `estimated_ready_at` |
| `base_price` | `price` | `price`/`item_price`/`base_price` | `base_price`/`price` |
| `preparation_time` | `prep_time` | `prep_time`/`prep_time_minutes` | `preparation_time` |
| `notification_body` | `notification_message` | N/A | `notification_body` |
| `total_triggered` | `times_triggered` | N/A | `total_triggered` |
| `phone_number` | `phone_number` | `phone_number` | `phone` |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-02 | Initial contract map from Phase 6 |
