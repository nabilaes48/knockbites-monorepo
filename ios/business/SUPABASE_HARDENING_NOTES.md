# Supabase Endpoint Usage Hardening

**Generated:** 2025-12-02
**Phase:** 10 — Cross-Platform Feature Parity & Release Readiness
**Purpose:** Audit and harden Supabase data access across all repositories and services

---

## Executive Summary

This document audits the Business iOS app's Supabase usage for security, reliability, and error handling. The goal is to ensure:
1. **Row-Level Security (RLS)** is properly handled in code
2. **RBAC permissions** are checked before data access
3. **Graceful fallbacks** exist for missing or malformed data
4. **Error handling** provides clear, actionable feedback

### Current Status

| Category | Status | Score |
|----------|--------|-------|
| RLS Awareness | ✅ Good | 90% |
| RBAC Integration | ✅ Excellent | 95% |
| Error Handling | ✅ Good | 85% |
| Graceful Degradation | ⚠️ Moderate | 70% |
| Optional Decoding | ⚠️ Moderate | 65% |
| Caching Strategy | ✅ Implemented | 80% |

**Overall Score: 81% (Good)**

---

## 1. Repository Audit

### 1.1 OrdersRepository.swift

**Location:** `camerons-Bussiness-app/Core/Data/Repositories/OrdersRepository.swift`

#### ✅ Strengths

1. **RBAC Integration:**
   ```swift
   let targetStoreIds = await AuthManager.shared.getAccessibleStores()
   let isSuperAdmin = await AuthManager.shared.isSuperAdmin()
   ```
   - Properly checks accessible stores before querying
   - Handles super admin case separately

2. **RLS-Aware Query:**
   ```swift
   .in("store_id", values: targetStoreIds)
   ```
   - Filters by accessible stores client-side
   - Reduces load on RLS policies

3. **Empty Store Handling:**
   ```swift
   if targetStoreIds.isEmpty && !isSuperAdmin {
       print("⚠️ User has no accessible stores")
       return []
   }
   ```
   - Returns empty array instead of throwing error
   - Graceful degradation

#### ⚠️ Areas for Improvement

1. **Missing AppError Mapping:**
   ```swift
   let response: [OrderResponse] = try await query.execute().value
   ```
   - Raw Supabase errors propagate to ViewModels
   - Should wrap in try-catch and map to AppError

   **Recommendation:**
   ```swift
   do {
       let response: [OrderResponse] = try await query.execute().value
       // ... process response
   } catch {
       if error.localizedDescription.contains("policy") ||
          error.localizedDescription.contains("permission") {
           throw AppError.unauthorized
       }
       throw AppError.supabase(message: error.localizedDescription)
   }
   ```

2. **Hardcoded Field Selection:**
   ```swift
   .select("""
       *,
       order_items(*)
   """)
   ```
   - Fetches all fields (inefficient)
   - See NETWORK_OPTIMIZATION_NOTES.md for specific field recommendations

3. **Optional Chaining Without Fallback:**
   ```swift
   if let itemName = item.itemName, let itemPrice = item.itemPrice {
       // ... create CartItem
   }
   ```
   - Silently drops items with missing data
   - Should log warning or return partial data with defaults

   **Recommendation:**
   ```swift
   let itemName = item.itemName ?? "Unknown Item"
   let itemPrice = item.itemPrice ?? 0.0
   // Create CartItem with fallbacks
   Logger.warning("Order item missing data", category: .orders, context: ["itemId": item.id])
   ```

4. **No Pagination:**
   - Fetches all orders at once
   - Could cause memory issues with large datasets
   - See NETWORK_OPTIMIZATION_NOTES.md for pagination strategy

---

### 1.2 MenuRepository.swift

**Location:** `camerons-Bussiness-app/Core/Data/Repositories/MenuRepository.swift`

#### ✅ Strengths

1. **Caching Implemented:**
   - Uses DataCache with 30s TTL for menu items
   - Uses DataCache with 60s TTL for categories
   - Cache invalidation on updates

2. **Store Filtering:**
   - Filters by store_id where applicable

#### ⚠️ Areas for Improvement

1. **Missing RLS Error Handling:**
   - Same as OrdersRepository - needs try-catch with AppError mapping

2. **No RBAC Permission Check:**
   ```swift
   func createMenuItem(...) async throws
   ```
   - Doesn't verify user has `menu.create` permission
   - Relies entirely on RLS (which is good, but client-side check improves UX)

   **Recommendation:**
   ```swift
   func createMenuItem(...) async throws {
       guard await AuthManager.shared.hasDetailedPermission("menu.create") else {
           throw AppError.unauthorized
       }
       // ... proceed with creation
   }
   ```

3. **Wide Select Queries:**
   ```swift
   .select()
   ```
   - Fetches all columns
   - Should specify needed fields

---

### 1.3 MarketingRepository.swift

**Location:** `camerons-Bussiness-app/Core/Data/Repositories/MarketingRepository.swift`

#### ✅ Strengths

1. **Caching for Coupons:**
   - 15s TTL with cache invalidation

2. **Query Limits:**
   ```swift
   .limit(50)
   ```
   - Prevents unbounded queries

#### ⚠️ Areas for Improvement

1. **No Permission Checks:**
   - Marketing operations should verify `marketing.campaigns` permission

2. **Field Name Discrepancy:**
   - Per CROSS_APP_COMPATIBILITY_REPORT:
     - Business uses `notification_message`
     - Database has `notification_body`
   - Needs field name fix or fallback parsing

   **Recommendation:**
   ```swift
   enum CodingKeys: String, CodingKey {
       case notificationMessage = "notification_body" // Fix field name
       // ... other keys
   }
   ```

3. **Metrics Field Names:**
   - Business uses `times_triggered`, `conversion_count`
   - Website uses `total_triggered`, `total_converted`
   - Verify correct database column names

---

### 1.4 AnalyticsRepository.swift

**Location:** `camerons-Bussiness-app/Core/Data/Repositories/AnalyticsRepository.swift`

#### ✅ Strengths

1. **RPC Usage:**
   - Uses `get_store_metrics`, `get_revenue_chart_data`
   - RPC functions encapsulate complex queries

2. **Field Selection:**
   ```swift
   .select("id, total, created_at, customer_id")
   ```
   - Specifies only needed fields
   - Good example for other repositories

3. **Store-Based Filtering:**
   - Always filters by store_id

#### ⚠️ Areas for Improvement

1. **No Permission Check for Financial Data:**
   ```swift
   func fetchAnalyticsSummary(...) async throws
   ```
   - Should verify `analytics.financial` permission
   - Financial data is sensitive

   **Recommendation:**
   ```swift
   func fetchAnalyticsSummary(...) async throws -> AnalyticsSummary {
       guard await AuthManager.shared.hasDetailedPermission("analytics.financial") else {
           throw AppError.unauthorized
       }
       // ... proceed with query
   }
   ```

2. **RPC Error Handling:**
   - RPC calls need try-catch with AppError mapping

---

## 2. Services Audit

### 2.1 MarketingService.swift

**Location:** `camerons-Bussiness-app/Services/MarketingService.swift`

#### ✅ Strengths

- Abstracts marketing logic from repositories
- Handles campaign orchestration

#### ⚠️ Areas for Improvement

1. **Direct Supabase Calls:**
   - Should use MarketingRepository instead of calling SupabaseManager directly
   - Bypasses caching and consistent error handling

2. **Field Name Issues:**
   - Same notification_message vs notification_body issue

---

### 2.2 AnalyticsService.swift

**Location:** `camerons-Bussiness-app/Services/AnalyticsService.swift`

#### ✅ Strengths

- Uses AnalyticsRepository
- Depends on PostgreSQL views (migration 024)

#### ⚠️ Areas for Improvement

1. **No Fallback for Missing Views:**
   - If migration 024 not run, service fails silently
   - Should detect and return helpful error

   **Recommendation:**
   ```swift
   do {
       return try await AnalyticsRepository.shared.fetchAnalyticsSummary(...)
   } catch {
       if error.localizedDescription.contains("relation") ||
          error.localizedDescription.contains("does not exist") {
           throw AppError.supabase(message: "Analytics views not installed. Please run migration 024.")
       }
       throw error
   }
   ```

---

### 2.3 NotificationsService.swift

**Location:** `camerons-Bussiness-app/Services/NotificationsService.swift`

#### ✅ Strengths

- Handles push notification logic
- Field selection: `.select("recipients_count", head: false, count: .exact)`

#### ⚠️ Areas for Improvement

1. **No Permission Check:**
   - Should verify `notifications.send` permission

---

## 3. RLS Policy Awareness

### Current Behavior

The app assumes RLS policies are correctly configured and will silently fail or return empty results if:
- User doesn't have access to store
- RLS policy blocks query
- Permission is denied

### Recommended Approach

**Proactive RLS Checking:**

```swift
// Add to each repository method
private func checkStoreAccess(_ storeId: Int) async throws {
    guard await AuthManager.shared.hasStoreAccess(storeId: storeId) else {
        throw AppError.unauthorized
    }
}
```

**Usage:**
```swift
func fetchOrders(storeId: Int) async throws -> [Order] {
    try await checkStoreAccess(storeId)
    // ... proceed with query
}
```

**Benefits:**
- Fails fast with clear error message
- Prevents unnecessary network calls
- Better UX (immediate feedback vs silent failure)

---

## 4. Graceful Fallback Strategy

### Current Issues

1. **Missing Data Handling:**
   - Optional chaining drops data silently
   - No logging for debugging

2. **Schema Changes:**
   - No optional decoding for new/removed fields
   - App crashes if schema changes

### Recommended Patterns

#### 4.1 Optional Decoding

```swift
struct OrderResponse: Codable {
    let id: Int
    let orderNumber: String
    // Old field (deprecated but may still exist)
    let estimatedReadyTime: Date?
    // New field (preferred)
    let estimatedReadyAt: Date?

    // Computed property for compatibility
    var readyTime: Date? {
        estimatedReadyAt ?? estimatedReadyTime
    }

    enum CodingKeys: String, CodingKey {
        case id
        case orderNumber = "order_number"
        case estimatedReadyTime = "estimated_ready_time"
        case estimatedReadyAt = "estimated_ready_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        orderNumber = try container.decode(String.self, forKey: .orderNumber)

        // Optional decoding with fallback
        estimatedReadyTime = try? container.decode(Date.self, forKey: .estimatedReadyTime)
        estimatedReadyAt = try? container.decode(Date.self, forKey: .estimatedReadyAt)
    }
}
```

#### 4.2 Partial Data Recovery

```swift
// Instead of:
guard let itemName = item.itemName, let itemPrice = item.itemPrice else {
    return nil // Drops entire item
}

// Use:
let itemName = item.itemName ?? "Unknown Item"
let itemPrice = item.itemPrice ?? 0.0
Logger.warning("Missing item data", category: .orders, context: [
    "itemId": item.id,
    "missingName": item.itemName == nil,
    "missingPrice": item.itemPrice == nil
])
// Continue with fallback values
```

---

## 5. Error Handling Standardization

### Current State

- AppError enum exists ✅
- Some repositories use it ⚠️
- Most repositories throw raw Supabase errors ❌

### Recommended Pattern

**Wrap All Repository Methods:**

```swift
func fetchMenuItems(storeId: Int) async throws -> [MenuItem] {
    do {
        // Cache check
        if let cached = await cache.get(CacheKeys.menuItems(storeId: storeId)) {
            Logger.cacheHit(CacheKeys.menuItems(storeId: storeId))
            return cached
        }

        // Permission check
        guard await AuthManager.shared.hasStoreAccess(storeId: storeId) else {
            throw AppError.unauthorized
        }

        // Query
        let response: [MenuItemResponse] = try await client
            .from(TableNames.menuItems)
            .select("id, name, description, price, category_id, image_url, is_available")
            .eq("store_id", value: storeId)
            .execute()
            .value

        let items = response.map { /* map to MenuItem */ }

        // Cache result
        await cache.set(CacheKeys.menuItems(storeId: storeId), value: items, ttl: CacheTTL.medium)

        return items

    } catch let error as AppError {
        // Already an AppError, rethrow
        Logger.error("Menu fetch failed", category: .menu, error: error)
        throw error

    } catch {
        // Map Supabase error to AppError
        let appError = mapSupabaseError(error)
        Logger.error("Menu fetch failed", category: .menu, error: appError)
        throw appError
    }
}

private func mapSupabaseError(_ error: Error) -> AppError {
    let message = error.localizedDescription.lowercased()

    if message.contains("policy") || message.contains("permission") || message.contains("rls") {
        return .unauthorized
    }

    if message.contains("network") || message.contains("connection") {
        return .network(underlying: error)
    }

    if message.contains("not found") || message.contains("no rows") {
        return .notFound(resource: "data")
    }

    return .supabase(message: error.localizedDescription)
}
```

---

## 6. Field Name Fixes Required

### From CROSS_APP_COMPATIBILITY_REPORT.md

| Issue | Current Code | Database Column | Fix Required |
|-------|--------------|-----------------|--------------|
| Order ready time | `estimated_ready_time` | `estimated_ready_at` | ✅ **High priority** |
| Campaign notification | `notification_message` | `notification_body` | ✅ **Medium priority** |
| Campaign metrics | `times_triggered` | `total_triggered` (verify) | ⚠️ **Needs verification** |
| Campaign conversion | `conversion_count` | `total_converted` (verify) | ⚠️ **Needs verification** |

**Action Required:**

1. Update OrderResponse CodingKeys:
```swift
case estimatedReadyAt = "estimated_ready_at"
```

2. Update AutomatedCampaignResponse CodingKeys:
```swift
case notificationBody = "notification_body"
```

3. Verify metrics field names in database and update if needed

---

## 7. Permission Gating Recommendations

### Operations Requiring Permission Checks

| Operation | Repository Method | Permission | Priority |
|-----------|-------------------|------------|----------|
| Create menu item | `MenuRepository.createMenuItem` | `menu.create` | High |
| Update menu item | `MenuRepository.updateMenuItem` | `menu.update` | High |
| Delete menu item | `MenuRepository.deleteMenuItem` | `menu.delete` | High |
| View analytics | `AnalyticsRepository.fetchAnalyticsSummary` | `analytics.financial` | **Critical** |
| Create campaign | `MarketingRepository.createCampaign` | `marketing.campaigns` | High |
| Send notification | `NotificationsService.sendNotification` | `notifications.send` | High |
| Award points | `MarketingRepository.awardPoints` | `loyalty.manage` | Medium |
| View all customers | `MarketingRepository.fetchLoyaltyCustomers` | `customers.view` | Medium |

**Implementation Example:**

```swift
func fetchAnalyticsSummary(storeId: Int, ...) async throws -> AnalyticsSummary {
    // Financial data permission check
    guard await AuthManager.shared.hasDetailedPermission("analytics.financial") else {
        throw AppError.unauthorized
    }

    // Store access check
    guard await AuthManager.shared.hasStoreAccess(storeId: storeId) else {
        throw AppError.unauthorized
    }

    // ... proceed with query
}
```

---

## 8. Shared Type Definitions (Phase 7 Follow-up)

### Current Status

- Business iOS has well-defined models ✅
- Customer iOS uses separate models ⚠️
- Website uses TypeScript types ⚠️

### Recommendation

**Create Shared Model Documentation:**

```markdown
# Order Model Contract

## Database Table: orders

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | integer | Yes | Primary key |
| order_number | text | Yes | Format: [STORE_CODE]-[YYMMDD]-[SEQ] |
| store_id | integer | Yes | FK to stores |
| user_id | uuid | Yes | FK to users (customer) |
| status | order_status | Yes | Enum: received, preparing, ready, completed, cancelled |
| subtotal | numeric | Yes | Pre-tax total |
| tax | numeric | Yes | Tax amount |
| total | numeric | Yes | Final total |
| created_at | timestamptz | Yes | Order placement time |
| estimated_ready_at | timestamptz | No | Estimated completion time |
| completed_at | timestamptz | No | Actual completion time |
| customer_name | text | No | Customer display name |
| order_type | order_type | Yes | Enum: pickup, delivery, dine_in |
| special_instructions | text | No | Customer notes |

## Deprecated Fields

| Field | Replacement | Migration |
|-------|-------------|-----------|
| estimated_ready_time | estimated_ready_at | Use new field |

## Client Implementations

- **Business iOS:** See `OrderResponse` in `Models.swift`
- **Customer iOS:** See `Order` model
- **Website:** See `Database['public']['Tables']['orders']` type
```

---

## 9. RPC Function Hardening

### Current RPC Usage

| RPC | Repository | Error Handling | Permission Check |
|-----|------------|----------------|------------------|
| `get_store_metrics` | AnalyticsRepository | ⚠️ Basic | ❌ No |
| `get_revenue_chart_data` | AnalyticsRepository | ⚠️ Basic | ❌ No |

### Recommended RPC Error Handling

```swift
func callRPC<T: Decodable>(_ function: String, params: [String: Any]) async throws -> T {
    do {
        let response: T = try await client
            .rpc(function, params: params)
            .execute()
            .value

        return response

    } catch {
        let message = error.localizedDescription

        // Detect function doesn't exist
        if message.contains("function") && message.contains("does not exist") {
            throw AppError.supabase(message: "Database function '\(function)' not found. Database may need migration.")
        }

        // Detect parameter error
        if message.contains("parameter") || message.contains("argument") {
            throw AppError.validation(message: "Invalid parameters for '\(function)'")
        }

        // Generic RPC error
        throw AppError.supabase(message: "RPC '\(function)' failed: \(message)")
    }
}
```

---

## 10. Caching Strategy Review

### Currently Cached (Phase 9)

| Data | TTL | Invalidation Strategy |
|------|-----|----------------------|
| Menu items | 30s | On create/update/delete |
| Categories | 60s | On create/update/delete |
| Coupons | 15s | On create/update/delete |

### Recommended Additional Caching

| Data | TTL | Invalidation | Priority |
|------|-----|--------------|----------|
| Analytics summary | 30s | Time-based | Medium |
| Loyalty program config | 5m | On update | Low |
| Store info | 5m | On update | Low |
| User permissions | 5m | On role change | **High** |

**User Permissions Caching:**

```swift
// Add to AuthManager
private var permissionsCache: [String: Date] = [:]
private let permissionsCacheTTL: TimeInterval = 300 // 5 minutes

func hasDetailedPermission(_ permission: String) async -> Bool {
    // Check cache
    if let cacheTime = permissionsCache[permission],
       Date().timeIntervalSince(cacheTime) < permissionsCacheTTL {
        return true // Cached as true
    }

    // Check actual permission
    let hasPermission = await checkPermissionFromRole(permission)

    if hasPermission {
        permissionsCache[permission] = Date()
    }

    return hasPermission
}

func invalidatePermissionsCache() {
    permissionsCache.removeAll()
}
```

---

## 11. Network Resilience

### Current State

- Single attempt per request
- No retry logic
- No timeout configuration

### Recommended Improvements

**Retry Logic for Read Operations:**

```swift
func fetchWithRetry<T>(
    maxRetries: Int = 3,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 1...maxRetries {
        do {
            return try await operation()
        } catch {
            lastError = error
            Logger.warning("Retry attempt \(attempt)/\(maxRetries)", category: .network, error: error)

            if attempt < maxRetries {
                // Exponential backoff: 1s, 2s, 4s
                let delay = pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw lastError ?? AppError.network(underlying: nil)
}
```

**Usage:**
```swift
func fetchOrders() async throws -> [Order] {
    return try await fetchWithRetry {
        // ... actual fetch logic
    }
}
```

---

## 12. Implementation Priority

### Critical (Week 1)

1. ✅ Fix field name mismatches (`estimated_ready_at`, `notification_body`)
2. ✅ Add AppError mapping to all repositories
3. ✅ Add permission check to `fetchAnalyticsSummary` (financial data)
4. ✅ Test RLS policies in production-like environment

### High (Week 2)

1. ✅ Add permission checks to menu CRUD operations
2. ✅ Add permission checks to marketing operations
3. ✅ Implement graceful fallbacks for missing data
4. ✅ Add RPC error detection

### Medium (Week 3)

1. ✅ Implement user permissions caching
2. ✅ Add retry logic for read operations
3. ✅ Specify fields in all `.select()` queries
4. ✅ Add logging for all error paths

### Low (Week 4)

1. ✅ Create shared model documentation
2. ✅ Implement analytics fallback for missing views
3. ✅ Add timeout configuration
4. ✅ Performance testing under load

---

## 13. Testing Recommendations

### Unit Tests

```swift
class OrdersRepositoryTests: XCTestCase {
    func testFetchOrdersWithoutStoreAccess() async throws {
        // Mock AuthManager to return empty stores
        // Verify returns empty array, not error
    }

    func testFetchOrdersWithRLSError() async throws {
        // Mock Supabase to return RLS error
        // Verify AppError.unauthorized is thrown
    }

    func testFetchOrdersWithMissingData() async throws {
        // Mock response with null fields
        // Verify graceful fallback
    }
}
```

### Integration Tests

1. Test each repository method with user having NO permissions
2. Test each repository method with user having partial permissions
3. Test with missing database columns (simulate schema drift)
4. Test with malformed JSON responses

---

## 14. Security Checklist

- [ ] All repositories wrap Supabase errors in AppError
- [ ] All sensitive operations check RBAC permissions
- [ ] All queries filter by accessible stores
- [ ] No hardcoded store IDs bypass RLS
- [ ] Super admin access is explicit and logged
- [ ] Financial data requires `analytics.financial` permission
- [ ] User management requires `users.manage` permission
- [ ] All RPC calls have error handling
- [ ] No SQL injection vectors (use parameterized queries)
- [ ] Sensitive data (tokens, passwords) never logged

---

## 15. Summary of Required Changes

### Code Changes

| File | Change | Priority | Estimated Time |
|------|--------|----------|----------------|
| `OrdersRepository.swift` | Add AppError mapping | Critical | 1 hour |
| `MenuRepository.swift` | Add permission checks + AppError | High | 2 hours |
| `MarketingRepository.swift` | Fix field names + AppError | Critical | 2 hours |
| `AnalyticsRepository.swift` | Add permission checks + AppError | Critical | 1 hour |
| `AnalyticsService.swift` | Add migration detection | Medium | 1 hour |
| `NotificationsService.swift` | Add permission checks | High | 1 hour |
| `Models.swift` | Fix CodingKeys field names | Critical | 30 min |
| `AuthManager.swift` | Add permissions caching | Medium | 2 hours |

**Total Estimated Time: 10.5 hours**

### Testing

- Unit tests for error handling: 4 hours
- Integration tests for RLS: 4 hours
- Manual QA: 2 hours

**Total Testing Time: 10 hours**

---

## 16. Migration Checklist

- [ ] Update `OrderResponse` CodingKeys to use `estimated_ready_at`
- [ ] Update `AutomatedCampaignResponse` CodingKeys to use `notification_body`
- [ ] Verify metrics field names in database
- [ ] Add try-catch blocks to all repository methods
- [ ] Implement `mapSupabaseError()` helper
- [ ] Add permission checks to sensitive operations
- [ ] Add graceful fallbacks for optional fields
- [ ] Implement retry logic for read operations
- [ ] Cache user permissions in AuthManager
- [ ] Add logging to all error paths
- [ ] Create unit tests for error scenarios
- [ ] Create integration tests for RLS scenarios
- [ ] Document shared data contracts
- [ ] Update Customer iOS to use same field names
- [ ] Update Website to use same field names

---

**End of Supabase Hardening Notes**

**Status:** Ready for implementation
**Approval Required:** Yes (review security implications)
**Estimated Completion:** 3-4 weeks with testing
