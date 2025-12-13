# Network Optimization Notes - Phase 9

This document tracks Supabase query optimizations and recommendations.

---

## Implemented Optimizations

### 1. In-Memory Caching Added

| Repository | Cache TTL | Data Type |
|------------|-----------|-----------|
| MenuRepository | 30s | Menu items |
| MenuRepository | 60s | Categories |
| MarketingRepository | 15s | Coupons |

### 2. Query Limits Added

| Repository | Method | Limit |
|------------|--------|-------|
| MarketingRepository | fetchCoupons | 50 items |

---

## Field Selection Analysis

### Current Wide Selects (Opportunities)

| File | Table | Current | Recommended Fields |
|------|-------|---------|-------------------|
| MenuRepository.swift:49 | menu_items | `select()` | `id, name, description, price, category_id, image_url, is_available` |
| MenuRepository.swift:86 | menu_categories | `select()` | `id, name, icon` |
| MarketingRepository.swift:118 | coupons | `select()` | `id, code, name, discount_type, discount_value, is_active, start_date, end_date` |

### Already Optimized

| File | Table | Selection |
|------|-------|-----------|
| AnalyticsRepository.swift:68 | orders | `id, total, created_at, customer_id` |
| OrdersRepository.swift:252 | user_profiles | `id, full_name` |
| NotificationsService.swift | notifications | Specific fields per use case |

---

## Index Recommendations

Based on query patterns, these indexes would improve performance:

### Orders Table
```sql
-- For store-specific order listings
CREATE INDEX idx_orders_store_status ON orders(store_id, status);

-- For date-range analytics
CREATE INDEX idx_orders_store_created ON orders(store_id, created_at DESC);
```

### Coupons Table
```sql
-- For active coupon lookups
CREATE INDEX idx_coupons_store_active ON coupons(store_id, is_active);
```

### Loyalty Customers Table
```sql
-- For store customer lookups
CREATE INDEX idx_loyalty_store ON loyalty_customers(store_id, tier);
```

*Note: These are recommendations only - not implemented in database yet.*

---

## RPC Candidates

These multi-step fetches could be consolidated into Postgres functions:

### 1. Analytics Summary
**Current**: 2 sequential queries (current period + previous period)
**Recommendation**: Create `get_analytics_summary(store_id, start_date, end_date)` RPC

### 2. Order Enrichment
**Current**: Fetch orders, then fetch user profiles
**Recommendation**: Create view or RPC with joined data

### 3. Tier Distribution
**Current**: Fetch all customers, then group client-side
**Recommendation**: Create `get_tier_distribution(store_id)` RPC

---

## Pagination Recommendations

For large data sets, implement cursor-based pagination:

| Endpoint | Current Limit | Max Expected | Action |
|----------|---------------|--------------|--------|
| fetchOrders | None | 100+ | Add `.limit(50)` + pagination |
| fetchMenuItems | None | 50-100 | Add `.limit(100)` |
| fetchLoyaltyCustomers | None | 1000+ | Implement pagination |

---

## Real-Time Subscription Efficiency

Current subscriptions are efficient:
- Filter by `store_id` at database level
- Only subscribe to relevant tables (orders)

No changes needed.

---

## Batch Request Opportunities

### Current Pattern (Sequential)
```swift
let program = try await fetchProgram()
let tiers = try await fetchTiers(programId: program.id)
let rewards = try await fetchRewards(programId: program.id)
```

### Recommended Pattern (Concurrent)
```swift
let program = try await fetchProgram()
async let tiersTask = fetchTiers(programId: program.id)
async let rewardsTask = fetchRewards(programId: program.id)
let (tiers, rewards) = try await (tiersTask, rewardsTask)
```

---

## Summary

| Category | Status | Priority |
|----------|--------|----------|
| Caching | Implemented | - |
| Query Limits | Partial | Medium |
| Field Selection | Documented | Low |
| Indexes | Recommended | High (DB admin) |
| RPCs | Recommended | Medium |
| Pagination | Recommended | Medium |
| Batch Requests | Documented | Low |
