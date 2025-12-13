# Phase 7: Multi-Client Shared Models + Auto-Schema Alignment

**Status:** COMPLETE
**Date:** December 2, 2025

---

## Overview

Phase 7 establishes a shared type system across all Camerons Connect clients (Business iOS, Customer iOS, Website) with automatic schema validation to prevent contract drift.

---

## Deliverables

### 1. Shared Canonical Models (Swift)

Created `camerons-Bussiness-app/SharedModels/` with 11 files:

| File | Purpose |
|------|---------|
| `SharedDateFormatting.swift` | ISO 8601 date parsing with fractional seconds support |
| `Orders.swift` | SharedOrder, SharedOrderItem, SharedOrderStatus, SharedOrderType |
| `Menu.swift` | SharedMenuItem, SharedMenuCategory, SharedMenuItemCustomization |
| `Loyalty.swift` | SharedLoyaltyProgram, SharedLoyaltyTier, SharedCustomerLoyalty |
| `Marketing.swift` | SharedCoupon, SharedAutomatedCampaign, TriggerConditionValue |
| `Notifications.swift` | SharedPushNotification, SharedNotificationStatus |
| `Referrals.swift` | SharedReferralProgram, SharedReferral, SharedReferralStatus |
| `Users.swift` | SharedCustomer, SharedCustomerAddress, SharedUserProfile |
| `Store.swift` | SharedStore with location helpers |
| `Analytics.swift` | SharedAnalyticsSummary, SharedDailyStats, SharedHourlyStats |
| `CompatibilityAliases.swift` | Type aliases for gradual migration |

**Key Features:**
- All field names match Supabase contract exactly (snake_case via CodingKeys)
- Flexible Codable types for JSON fields (CustomizationsValue, TriggerConditionValue)
- Field aliases support (phone/phone_number, price/base_price)
- Computed properties for backwards compatibility

### 2. Shared Canonical Models (TypeScript)

Created `camerons-connect/src/shared-models/` with 10 files:

| File | Types |
|------|-------|
| `orders.ts` | SharedOrder, SharedOrderItem, SharedOrderStatus, SharedOrderType |
| `menu.ts` | SharedMenuItem, SharedMenuCategory, SharedMenuItemCustomization |
| `loyalty.ts` | SharedLoyaltyProgram, SharedLoyaltyTier, SharedCustomerLoyalty |
| `marketing.ts` | SharedCoupon, SharedAutomatedCampaign, SharedDiscountType |
| `notifications.ts` | SharedPushNotification, SharedNotificationStatus |
| `referrals.ts` | SharedReferralProgram, SharedReferral, SharedReferralStatus |
| `users.ts` | SharedCustomer, SharedCustomerAddress, SharedUserProfile |
| `store.ts` | SharedStore with helper functions |
| `analytics.ts` | SharedAnalyticsSummary, SharedDailyStats, SharedHourlyStats |
| `index.ts` | Barrel export for all modules |

**Key Features:**
- Optional fields use `?` syntax matching Supabase nullability
- Helper functions for common operations (getCustomerDisplayName, formatAddress)
- Field aliases supported with union types

### 3. Schema Verification Script

Created `scripts/verify_supabase_contract.ts`:

- Connects to live Supabase database
- Validates schema against documented contract
- Checks for:
  - Missing tables
  - Missing columns
  - Type mismatches
  - Nullability mismatches
- Returns exit code 0 (pass) or 1 (fail)
- Human-readable output for CI logs

### 4. CI/CD Integration

Created `.github/workflows/check-contract.yml`:

```yaml
name: Supabase Contract Check
on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]
```

**Workflow:**
1. Checkout code
2. Setup Node.js 20
3. Install TypeScript dependencies
4. Run `scripts/verify_supabase_contract.ts`
5. Block merge if mismatches detected
6. Output human-readable diff

**Required Secrets:**
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

### 5. Pre-Commit Hook

Created `scripts/pre-commit-contract-check.sh`:

- Runs on commits touching contract-related files
- Validates schema before push
- Provides skip instruction for emergencies

**Installation:**
```bash
ln -sf ../../scripts/pre-commit-contract-check.sh .git/hooks/pre-commit
```

### 6. Compatibility Layer

Created `SharedModels/CompatibilityAliases.swift`:

```swift
// Type aliases for gradual migration
typealias OrderFromSupabase = SharedOrder
typealias MenuItemFromSupabase = SharedMenuItem
typealias CustomerFromSupabase = SharedCustomer
// ... etc
```

---

## Backwards Compatibility Features

### Field Aliases (Swift)

| Model | Alias Property | Maps To |
|-------|----------------|---------|
| SharedOrder | notes | specialInstructions |
| SharedOrderStatus | fromLegacy() | String → enum |
| SharedMenuItem | basePrice | price |
| SharedMenuItem | preparationTime | prepTime |
| SharedAutomatedCampaign | notificationMessage | notificationBody |
| SharedAutomatedCampaign | timesTriggered | totalTriggered |

### Flexible JSON Decoding

```swift
// Handles both string[] and single string
public enum CustomizationsValue: Codable {
    case stringArray([String])
    case string(String)
}

// Handles both JSON object and string
public enum TriggerConditionValue: Codable {
    case string(String)
    case json([String: AnyCodableValue])
}
```

---

## Validation Results

### iOS Build Status

```
✅ BUILD SUCCEEDED
   - All SharedModels compile without errors
   - No type mismatches with existing code
   - CompatibilityAliases resolve correctly
```

### TypeScript Models

```
✅ All files created and export correctly
   - camerons-connect/src/shared-models/index.ts
   - Barrel export provides single import point
```

---

## Migration Guide

### For iOS Developers

1. **Import SharedModels** (already in project):
   ```swift
   // Use directly
   let order: SharedOrder = try decoder.decode(...)

   // Or use alias for gradual migration
   let order: OrderFromSupabase = try decoder.decode(...)
   ```

2. **Access compatibility properties**:
   ```swift
   order.notes  // Maps to specialInstructions
   order.statusDisplayName  // User-friendly status
   ```

### For Website Developers

1. **Import from shared-models**:
   ```typescript
   import { SharedOrder, SharedOrderStatus } from '@/shared-models';
   ```

2. **Use helper functions**:
   ```typescript
   import { getOrderStatusDisplayName } from '@/shared-models/orders';
   ```

---

## Contract Enforcement

### Automatic Checks

| Trigger | Action |
|---------|--------|
| PR to main/develop | GitHub Actions runs schema check |
| Push to main | GitHub Actions runs schema check |
| Local commit (with hook) | Pre-commit validates schema |

### Manual Check

```bash
# Set environment variables
export SUPABASE_URL="your-project-url"
export SUPABASE_SERVICE_ROLE_KEY="your-service-key"

# Run verification
ts-node scripts/verify_supabase_contract.ts
```

---

## Files Created/Modified

### New Files

| Path | Purpose |
|------|---------|
| `camerons-Bussiness-app/SharedModels/*.swift` | 11 Swift model files |
| `camerons-connect/src/shared-models/*.ts` | 10 TypeScript model files |
| `scripts/verify_supabase_contract.ts` | Schema validation script |
| `scripts/pre-commit-contract-check.sh` | Git hook script |
| `.github/workflows/check-contract.yml` | CI workflow |
| `PHASE7_CLEANUP_REPORT.md` | This report |

### Previously Created (Phase 6)

| Path | Purpose |
|------|---------|
| `SUPABASE_CONTRACT_MAP.md` | Field mapping documentation |
| `CROSS_APP_COMPATIBILITY_REPORT.md` | Compatibility analysis |
| `docs/CAMERONS_SUPABASE_CONTRACT.md` | Canonical contract |

---

## Next Steps

1. **Customer iOS App**: Copy SharedModels folder to customer app
2. **Website Integration**: Update existing types to use shared-models imports
3. **CI Secrets**: Add SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY to GitHub
4. **Team Training**: Review migration guide with developers

---

## Summary

Phase 7 successfully established:

- **Unified Type System**: Identical model definitions across Swift and TypeScript
- **Contract Enforcement**: Automated schema validation on every PR
- **Backwards Compatibility**: Gradual migration path via aliases and flexible decoding
- **Build Verification**: iOS app builds successfully with new SharedModels

The Camerons Connect platform now has robust protection against schema drift between clients and the Supabase backend.
