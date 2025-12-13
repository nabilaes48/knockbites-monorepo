# Phase 2 – ViewModel + Services Dependency Map

**Date:** 2025-12-02
**App:** Camerons Connect Business iOS App (SwiftUI)

---

## 1. COMPLETE VIEWMODEL MAP

### Dedicated ViewModel Files

| ViewModel | File Path | Init Params | Services Used | Used By |
|-----------|-----------|-------------|---------------|---------|
| `DashboardViewModel` | `Core/Dashboard/DashboardViewModel.swift` | None | `SupabaseManager.fetchOrders()`, `SupabaseManager.subscribeToOrders()` | `DashboardView` |
| `KitchenViewModel` | `Core/Kitchen/KitchenViewModel.swift` | None | `SupabaseManager.fetchOrders()`, `SupabaseManager.updateOrderStatus()` | `KitchenDisplayView` |
| `MarketingViewModels` (multiple) | `Core/Marketing/MarketingViewModels.swift` | Various | `SupabaseManager.*` (coupons, notifications, loyalty, etc.) | Various Marketing views |
| `MenuManagementViewModel` | `Core/Menu/ViewModels/MenuManagementViewModel.swift` | None | `SupabaseManager.fetchCategories()`, `fetchMenuItems()`, `updateMenuItemAvailability()`, `updateMenuItemPrice()` | `MenuManagementView` |
| `AddMenuItemViewModel` | `Core/Menu/ViewModels/AddMenuItemViewModel.swift` | `item: MenuItem?` | None (creates local MenuItem) | `AddMenuItemView` |

### Embedded ViewModels (In View Files - CODE SMELL)

| ViewModel | File Path | Lines | Init Params | Services Used |
|-----------|-----------|-------|-------------|---------------|
| `AnalyticsViewModel` | `Core/Analytics/AnalyticsView.swift` | ~300 | None | `AnalyticsService.*`, `SupabaseManager.*` |
| `BusinessReportsViewModel` | `Core/More/BusinessReportsView.swift` | 136 | None | `AnalyticsService.shared.*` |
| `StoreAnalyticsViewModel` | `Core/More/StoreAnalyticsView.swift` | 140 | None | `AnalyticsService.shared.*` |
| `NotificationsAnalyticsViewModel` | `Core/More/NotificationsAnalyticsView.swift` | 158 | None | `NotificationsService.shared.*` |
| `DatabaseDiagnosticsViewModel` | `Core/Settings/DatabaseDiagnosticsView.swift` | 130 | None | `SupabaseManager.shared.client` (direct) |
| `ExportViewModel` | `Shared/ExportOptionsView.swift` | 4 | None | None |
| `QuickActionSettingsManager` | `Core/More/QuickActionSettings.swift` | 70 | None | `UserDefaults` |

---

## 2. COMPLETE SERVICES MAP

### Core Services (Singletons)

| Service | File Path | Purpose | Tables/Views Accessed |
|---------|-----------|---------|----------------------|
| `SupabaseManager` | `SupabaseManager.swift` | Central Supabase client, Order/Menu/Marketing CRUD | `orders`, `order_items`, `menu_items`, `menu_categories`, `stores`, `user_profiles`, `coupons`, `push_notifications`, `loyalty_*`, `referral_*`, `automated_campaigns`, `ingredient_templates`, `menu_item_customizations` |
| `AuthManager` | `Auth/AuthManager.swift` | Authentication, session, RBAC permissions | `user_profiles` |
| `AnalyticsService` | `Services/AnalyticsService.swift` | Analytics data fetching | `analytics_daily_stats`, `analytics_hourly_today`, `analytics_time_distribution`, `analytics_category_distribution`, `analytics_popular_items`, `orders`, `stores` |
| `MarketingService` | `Services/MarketingService.swift` | Loyalty, referrals, coupons, segments | `loyalty_programs`, `loyalty_tiers`, `customer_loyalty`, `loyalty_transactions`, `referral_program`, `referrals`, `coupons`, `coupon_usage`, `automated_campaigns` |
| `NotificationsService` | `Services/NotificationsService.swift` | Push notification analytics | `push_notifications` |
| `ReceiptService` | `Services/ReceiptService.swift` | Receipt generation for thermal printers | None (formatting only) |
| `MockDataService` | `Shared/MockDataService.swift` | Mock data for testing (should not be used in production) | None |

### Service Method Counts

| Service | Public Methods | RPC Functions | Direct Table Queries |
|---------|----------------|---------------|---------------------|
| `SupabaseManager` | 45+ | 0 | 45+ |
| `AuthManager` | 15 | 0 | 1 |
| `AnalyticsService` | 11 | 2 (`get_store_metrics`, `get_revenue_chart_data`) | 9 |
| `MarketingService` | 20+ | 0 | 20+ |
| `NotificationsService` | 12 | 0 | 12 |
| `ReceiptService` | 2 | 0 | 0 |

---

## 3. CANONICAL DEPENDENCY GRAPH

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    VIEW LAYER                                                │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│  DashboardView ─────────────► DashboardViewModel                                            │
│  KitchenDisplayView ────────► KitchenViewModel                                              │
│  MenuManagementView ────────► MenuManagementViewModel                                       │
│  AddMenuItemView ───────────► AddMenuItemViewModel                                          │
│                                                                                             │
│  MarketingDashboardView ────► MarketingDashboardViewModel ─┐                                │
│  LoyaltyProgramView ────────► LoyaltyProgramViewModel ─────┤                                │
│  CustomerLoyaltyView ───────► CustomerLoyaltyViewModel ────┤                                │
│  ReferralProgramView ───────► ReferralProgramViewModel ────┤                                │
│  AutomatedCampaignsView ────► AutomatedCampaignsViewModel ─┤                                │
│  CustomerSegmentsView ──────► CustomerSegmentsViewModel ───┘                                │
│                                                                                             │
│  AnalyticsView ─────────────► AnalyticsViewModel (EMBEDDED)                                 │
│  BusinessReportsView ───────► BusinessReportsViewModel (EMBEDDED)                           │
│  StoreAnalyticsView ────────► StoreAnalyticsViewModel (EMBEDDED)                            │
│  NotificationsAnalyticsView ► NotificationsAnalyticsViewModel (EMBEDDED)                    │
│  DatabaseDiagnosticsView ───► DatabaseDiagnosticsViewModel (EMBEDDED)                       │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                   VIEWMODEL LAYER                                            │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│  DashboardViewModel ────────► SupabaseManager.fetchOrders()                                 │
│                               SupabaseManager.subscribeToOrders()                           │
│                                                                                             │
│  KitchenViewModel ──────────► SupabaseManager.fetchOrders()                                 │
│                               SupabaseManager.updateOrderStatus()                           │
│                                                                                             │
│  MenuManagementViewModel ───► SupabaseManager.fetchCategories()                             │
│                               SupabaseManager.fetchMenuItems()                              │
│                               SupabaseManager.updateMenuItemAvailability()                  │
│                               SupabaseManager.updateMenuItemPrice()                         │
│                               MockDataService (fallback) ⚠️                                 │
│                                                                                             │
│  AnalyticsViewModel ────────► AnalyticsService.* (all methods)                              │
│                               SupabaseManager.fetchAnalyticsSummary()                       │
│                               SupabaseManager.fetchDailySales()                             │
│                               SupabaseManager.fetchTopSellingItems()                        │
│                                                                                             │
│  BusinessReportsViewModel ──► AnalyticsService.getStoreMetrics()                            │
│                               AnalyticsService.getRevenueChartData()                        │
│                               AnalyticsService.getCategoryDistribution()                    │
│                               AnalyticsService.getHourlyData()                              │
│                               AnalyticsService.getPopularItems()                            │
│                               AnalyticsService.getPaymentMethods()                          │
│                               AnalyticsService.getDailyStats()                              │
│                                                                                             │
│  StoreAnalyticsViewModel ───► AnalyticsService.getStoreMetrics()                            │
│                               AnalyticsService.getAverageFulfillmentTime()                  │
│                               AnalyticsService.getDailyStats()                              │
│                               AnalyticsService.getHourlyData()                              │
│                               AnalyticsService.getMultiStoreMetrics()                       │
│                                                                                             │
│  NotificationsAnalyticsVM ──► NotificationsService.getTotalSent()                           │
│                               NotificationsService.getDeliveryRate()                        │
│                               NotificationsService.getOpenRate()                            │
│                               NotificationsService.getClickRate()                           │
│                               NotificationsService.getEngagementFunnel()                    │
│                               NotificationsService.getPeriodChanges()                       │
│                               NotificationsService.getDeliverySuccessOverTime()             │
│                               NotificationsService.getHourlySendPerformance()               │
│                               NotificationsService.getPlatformDistribution()                │
│                               NotificationsService.getRecentNotifications()                 │
│                                                                                             │
│  DatabaseDiagnosticsVM ─────► SupabaseManager.shared.client (DIRECT ACCESS) ⚠️              │
│                               SupabaseManager.fetchOrders()                                 │
│                                                                                             │
│  Marketing ViewModels ──────► SupabaseManager.* (all marketing methods)                     │
│                               MarketingService.* (DUPLICATE FUNCTIONALITY) ⚠️               │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                   SERVICE LAYER                                              │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│  AnalyticsService ──────────► SupabaseManager.shared.client                                 │
│                               RPC: get_store_metrics, get_revenue_chart_data                │
│                                                                                             │
│  MarketingService ──────────► SupabaseManager.shared.client                                 │
│                               NotificationsService.shared                                   │
│                                                                                             │
│  NotificationsService ──────► SupabaseManager.shared.client                                 │
│                                                                                             │
│  AuthManager ───────────────► SupabaseManager.shared.client                                 │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                   DATA LAYER                                                 │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│  SupabaseManager.client ────► Supabase PostgreSQL Database                                  │
│                               ├── orders                                                    │
│                               ├── order_items                                               │
│                               ├── menu_items                                                │
│                               ├── menu_categories                                           │
│                               ├── stores                                                    │
│                               ├── user_profiles                                             │
│                               ├── coupons / coupon_usage                                    │
│                               ├── push_notifications                                        │
│                               ├── loyalty_programs / tiers / rewards                        │
│                               ├── customer_loyalty / transactions                           │
│                               ├── referral_program / referrals                              │
│                               ├── automated_campaigns                                       │
│                               ├── analytics_* views (requires migration 024)                │
│                               └── ingredient_templates / menu_item_customizations           │
│                                                                                             │
│  UserDefaults ──────────────► Local storage for settings                                    │
│                               ├── kitchen_orders                                            │
│                               ├── receipt_settings                                          │
│                               └── quick_actions                                             │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. DETECTED ISSUES / CODE SMELLS

### HIGH PRIORITY

| Issue | Location | Description | Impact |
|-------|----------|-------------|--------|
| **Duplicate Service Functions** | `SupabaseManager` + `MarketingService` | Loyalty program, tiers, coupons, campaigns functionality duplicated in both files | Maintenance nightmare, inconsistent behavior |
| **Embedded ViewModels** | 7 view files | ViewModels defined inside SwiftUI view files instead of dedicated files | Poor separation of concerns, hard to test |
| **Direct Client Access** | `DatabaseDiagnosticsViewModel` | Accesses `SupabaseManager.shared.client` directly, writes inline Supabase queries | Bypasses service layer, inconsistent patterns |
| **Hardcoded Store ID** | `SupabaseConfig.storeId` used everywhere | Store ID hardcoded in config, used directly in ViewModels | Multi-store scenarios break |

### MEDIUM PRIORITY

| Issue | Location | Description | Impact |
|-------|----------|-------------|--------|
| **MockDataService Fallback** | `MenuManagementViewModel` | Falls back to mock data on error instead of showing error state | Masks real issues in production |
| **Inconsistent Date Formatting** | All services | `ISO8601DateFormatter()` created inline in multiple places | Potential inconsistencies, wasted allocations |
| **Duplicate Response Types** | `SupabaseManager` vs `MarketingService` | Both define `LoyaltyProgramResponse`, `LoyaltyTierResponse`, `CouponResponse`, etc. | Type conflicts, confusion |
| **Missing Error Handling** | Various ViewModels | Some ViewModels print errors but don't expose them to UI | Silent failures |
| **Inline Codable Types** | `SupabaseManager.swift` | 50+ `struct` types defined inline in methods | File is 1800+ lines, hard to navigate |

### LOW PRIORITY

| Issue | Location | Description | Impact |
|-------|----------|-------------|--------|
| **Unused Properties** | Various ViewModels | Some `@Published` properties never read in views | Memory waste, confusion |
| **Magic Strings** | Table names, column names | Strings like `"orders"`, `"store_id"` repeated everywhere | Typo-prone, refactor-unfriendly |
| **Old Mock Data Functions** | `StoreAnalyticsViewModel` | Contains `oldGenerateMockData()` commented out | Dead code |
| **Platform Distribution Mock** | `NotificationsService` | `getPlatformDistribution()` returns hardcoded zeros | Incomplete implementation |

---

## 5. DUPLICATED FUNCTIONALITY ANALYSIS

### Loyalty Program Operations

| Operation | SupabaseManager Method | MarketingService Method |
|-----------|------------------------|-------------------------|
| Fetch program | `fetchLoyaltyProgram(storeId:)` | `getLoyaltyProgram(storeId:)` |
| Update program | `updateLoyaltyProgram(programId:...)` | `updateLoyaltyProgram(programId:settings:)` |
| Fetch tiers | `fetchLoyaltyTiers(programId:)` | `getLoyaltyTiers(programId:)` |
| Create tier | `createLoyaltyTier(programId:...)` | `createLoyaltyTier(programId:tier:)` |
| Update tier | `updateLoyaltyTier(tierId:...)` | `updateLoyaltyTier(tierId:tier:)` |
| Delete tier | `deleteLoyaltyTier(tierId:)` | `deleteLoyaltyTier(tierId:)` |

### Coupon Operations

| Operation | SupabaseManager Method | MarketingService Method |
|-----------|------------------------|-------------------------|
| Fetch coupons | `fetchCoupons(storeId:)` | `getCoupons(storeId:activeOnly:)` |
| Create coupon | `createCoupon(coupon:)` | (not implemented) |
| Update coupon | `updateCoupon(id:isActive:)` | (not implemented) |
| Delete coupon | `deleteCoupon(id:)` | (not implemented) |
| Get redemptions | (not implemented) | `getCouponRedemptions(couponId:)` |

### Campaign Operations

| Operation | SupabaseManager Method | MarketingService Method |
|-----------|------------------------|-------------------------|
| Fetch campaigns | `fetchAutomatedCampaigns(storeId:)` | `getAutomatedCampaigns(storeId:)` |
| Create campaign | `createAutomatedCampaign(...)` | `createAutomatedCampaign(storeId:campaign:)` |
| Toggle status | `toggleCampaignStatus(campaignId:isActive:)` | (not implemented) |
| Delete campaign | `deleteAutomatedCampaign(id:)` | (not implemented) |

---

## 6. SUPABASE TABLES ACCESSED

| Table | SupabaseManager | AnalyticsService | MarketingService | NotificationsService | AuthManager |
|-------|-----------------|------------------|------------------|---------------------|-------------|
| `orders` | ✅ CRUD | ✅ Read | - | - | - |
| `order_items` | ✅ Read (nested) | - | - | - | - |
| `menu_items` | ✅ CRUD | - | - | - | - |
| `menu_categories` | ✅ Read | - | - | - | - |
| `stores` | ✅ Read | ✅ Read | - | - | - |
| `user_profiles` | ✅ Read | - | - | - | ✅ Read |
| `coupons` | ✅ CRUD | - | ✅ Read | - | - |
| `coupon_usage` | - | - | ✅ Read | - | - |
| `push_notifications` | ✅ CRUD | - | - | ✅ Read | - |
| `loyalty_programs` | ✅ CRUD | - | ✅ CRUD | - | - |
| `loyalty_tiers` | ✅ CRUD | - | ✅ CRUD | - | - |
| `loyalty_rewards` | ✅ CRUD | - | - | - | - |
| `customer_loyalty` | ✅ CRUD | - | ✅ CRUD | - | - |
| `loyalty_transactions` | ✅ CRUD | - | ✅ Create | - | - |
| `referral_program` | ✅ Read | - | ✅ Read | - | - |
| `referrals` | ✅ Read | - | ✅ Read | - | - |
| `automated_campaigns` | ✅ CRUD | - | ✅ CRUD | - | - |
| `analytics_daily_stats` | - | ✅ Read | - | - | - |
| `analytics_hourly_today` | - | ✅ Read | - | - | - |
| `analytics_*` views | - | ✅ Read | - | - | - |
| `ingredient_templates` | ✅ Read | - | - | - | - |
| `menu_item_customizations` | ✅ Read | - | - | - | - |

---

## 7. RESTRUCTURING PLAN FOR PHASE 3

### 7.1 Immediate Actions (High Priority)

1. **Consolidate Duplicate Service Methods**
   - Move all marketing operations from `SupabaseManager` to `MarketingService`
   - `SupabaseManager` should only handle: orders, menu, core CRUD
   - Create clear separation of domains

2. **Extract Embedded ViewModels**
   - Create `Core/Analytics/ViewModels/AnalyticsViewModel.swift`
   - Create `Core/More/ViewModels/BusinessReportsViewModel.swift`
   - Create `Core/More/ViewModels/StoreAnalyticsViewModel.swift`
   - Create `Core/More/ViewModels/NotificationsAnalyticsViewModel.swift`
   - Create `Core/Settings/ViewModels/DatabaseDiagnosticsViewModel.swift`
   - Move `QuickActionSettingsManager` to `Core/More/ViewModels/`

3. **Refactor DatabaseDiagnosticsViewModel**
   - Remove direct Supabase client access
   - Add diagnostic methods to `SupabaseManager`

### 7.2 Short-Term Improvements (Medium Priority)

4. **Create Shared Types Module**
   - Move all Codable response types to `Shared/Models/`
   - Create `Shared/Models/Analytics/` for analytics response types
   - Create `Shared/Models/Marketing/` for marketing response types
   - Eliminate duplicate type definitions

5. **Standardize Date Handling**
   - Create shared `DateFormatters` utility class
   - Use consistent date strategies across all services

6. **Add Table Name Constants**
   - Create `Constants/Tables.swift` with table names
   - Replace all magic strings

### 7.3 Long-Term Improvements (Low Priority)

7. **Split SupabaseManager**
   - Create `OrdersRepository` for order operations
   - Create `MenuRepository` for menu operations
   - Keep `SupabaseManager` as thin facade

8. **Add Repository Pattern**
   - ViewModels should not call Services directly
   - Create Repository layer between ViewModels and Services

9. **Add Unit Tests**
   - Services should be injectable (protocol-based)
   - ViewModels should be testable with mock services

---

## 8. FILE SUMMARY

### Files Analyzed

| Category | Count | Lines (approx) |
|----------|-------|----------------|
| Dedicated ViewModel files | 5 | 800 |
| Embedded ViewModels (in view files) | 7 | 1,100 |
| Service files | 6 | 2,500 |
| Total | 18 | 4,400 |

### Largest Files Needing Refactor

| File | Lines | Issue |
|------|-------|-------|
| `SupabaseManager.swift` | 1,822 | Too many responsibilities, inline types |
| `AnalyticsView.swift` | 1,000+ | 300+ line embedded ViewModel |
| `MarketingViewModels.swift` | 800+ | Multiple ViewModels in one file |
| `MarketingService.swift` | 820 | Duplicates SupabaseManager functionality |

---

## 9. RECOMMENDATIONS SUMMARY

| Priority | Action | Effort |
|----------|--------|--------|
| 1 | Extract 7 embedded ViewModels to dedicated files | Medium |
| 2 | Remove duplicate marketing methods from SupabaseManager | Medium |
| 3 | Create shared response type definitions | Low |
| 4 | Add table name constants | Low |
| 5 | Refactor DatabaseDiagnosticsViewModel | Low |
| 6 | Split SupabaseManager into repositories | High |
| 7 | Add protocol abstractions for testability | High |

---

*Report generated by Claude Code - Phase 2 Analysis*
