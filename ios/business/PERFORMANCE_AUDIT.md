# Performance Audit - Phase 9

This document catalogs performance hotspots, redundant network calls, and optimization opportunities.

---

## 1. Network Call Analysis

### Multiple Network Calls on Appear

| View | File | Issue | Severity |
|------|------|-------|----------|
| MarketingDashboardView | `MarketingDashboardView.swift:94` | Calls `loadCoupons()` AND `loadNotifications()` on appear | Medium |
| AnalyticsSummary | `AnalyticsRepository.swift:66-90` | Makes 2 sequential queries (current + previous period) | Medium |
| CustomerLoyaltyView | `CustomerLoyaltyView.swift:98,260` | Multiple nested `.onAppear` blocks | Low |
| DashboardView | `DashboardView.swift:100` | Loads orders + starts realtime subscription | Low (intentional) |

### Repositories Without Caching

| Repository | Location | Data Type | Recommended TTL |
|------------|----------|-----------|-----------------|
| OrdersRepository | `Core/Data/Repositories/` | Orders | 5 seconds (real-time critical) |
| MenuRepository | `Core/Data/Repositories/` | Menu items, Categories | 30 seconds |
| MarketingRepository | `Core/Data/Repositories/` | Coupons, Rewards, Tiers | 15 seconds |
| AnalyticsRepository | `Core/Data/Repositories/` | Analytics summaries | 30 seconds |

---

## 2. Task {} Usage in Views

### Direct Task in Views (Should be in ViewModels)

| File | Line | Issue |
|------|------|-------|
| ExportOptionsView.swift | 132 | Task in view for export operation |
| MoreView.swift | 334 | Task for sign out operation |
| SettingsView.swift | 225 | Task for sign out operation |

### Proper Task Usage in ViewModels (Good)

- DashboardViewModel.swift - Properly uses Task for async loading
- KitchenViewModel.swift - Properly uses Task with @MainActor
- MarketingViewModels.swift - Properly wraps network calls in Tasks

---

## 3. Supabase Query Analysis

### Queries Using `.select()` Without Field Specification

| File | Line | Table | Recommendation |
|------|------|-------|----------------|
| MarketingService.swift | 23 | loyalty_programs | Specify needed fields |
| MarketingService.swift | 65 | loyalty_tiers | Specify needed fields |
| MarketingService.swift | 108 | loyalty_rewards | Specify needed fields |
| MenuRepository.swift | 49 | menu_items | Specify needed fields |
| MenuRepository.swift | 86 | menu_categories | Specify needed fields |
| MarketingRepository.swift | 118 | coupons | Specify needed fields |
| AuthManager.swift | 155 | user_profiles | Specify needed fields |

### Optimized Queries (Good Examples)

- `AnalyticsRepository.swift:68` - `select("id, total, created_at, customer_id")`
- `OrdersRepository.swift:252` - `select("id, full_name")`
- `NotificationsService.swift:25` - `select("recipients_count", head: false, count: .exact)`

### Missing `.limit()` Clauses

| File | Query | Recommendation |
|------|-------|----------------|
| MenuRepository.swift | fetchMenuItems | Add `.limit(100)` for safety |
| MarketingRepository.swift | fetchCoupons | Add `.limit(50)` |
| AnalyticsRepository.swift | fetchDailySales | Already bounded by date |

---

## 4. Sheet & Navigation Analysis

### Multiple Boolean Sheet States (Refactoring Candidates)

| View | Booleans | Recommendation |
|------|----------|----------------|
| LoyaltyProgramView | `showEditSettings`, `showCreateTier` | Convert to enum |
| SettingsView | `showStoreInfo`, `showOperatingHours` | Convert to enum |
| CustomerLoyaltyView | `showBulkAward`, `showExportOptions`, `showAddPoints` | Convert to enum |
| RewardsCatalogView | `showCreateReward` + `rewardToEdit` | Mixed pattern OK |

### NavigationLink in ForEach (Check Stable IDs)

| File | Line | Status |
|------|------|--------|
| CustomerLoyaltyView.swift | 56 | Uses `customer.id` - OK |
| CustomerSegmentsView.swift | 165 | Uses `segment` - OK |
| MenuManagementView.swift | ForEach groups | Uses `category.id` - OK |

---

## 5. Heavy Computations in View Body

### Computed Properties in Views

| File | Property | Issue |
|------|----------|-------|
| MenuManagementView.swift | `filteredItems`, `groupedItems` | Computed on each render |
| KitchenDisplayView.swift | `filteredOrders(for:)` | Called in ForEach - acceptable |
| CustomerLoyaltyView.swift | `filteredCustomers(searchText:)` | Filter on render |

### Recommendation
Move expensive computations to ViewModel with `@Published` properties that update on data change.

---

## 6. Real-Time Subscription Analysis

| ViewModel | Subscription | Cleanup |
|-----------|--------------|---------|
| DashboardViewModel | Orders via `subscribeToOrders` | `onDisappear` cleanup |
| KitchenViewModel | Orders via `startRealtimeUpdates` | `onDisappear` cleanup |

Both implement proper cleanup patterns.

---

## 7. Logging Volume

### High-Volume Debug Prints

| File | Issue |
|------|-------|
| OrdersRepository.swift | Multiple prints per order item |
| MenuRepository.swift | Print on every fetch |
| All ViewModels | Print on every state change |

### Recommendation
Create centralized Logger with debug guards.

---

## Summary of Priority Actions

### High Priority
1. Add in-memory caching to repositories (MenuRepository, MarketingRepository)
2. Create centralized Logger utility
3. Specify fields in `.select()` queries

### Medium Priority
4. Convert remaining boolean sheet states to enum pattern
5. Add `.limit()` to unbounded queries
6. Move computed filters from View to ViewModel

### Low Priority
7. Batch sequential analytics queries where possible
8. Add performance monitoring for production
