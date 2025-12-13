# API Versioning Guide

**Cameron's Connect - Multi-App Compatibility Layer**

---

## Overview

Cameron's Connect supports multiple client applications:
- **Web Dashboard** (React)
- **Customer iOS App** (Swift)
- **Business iOS App** (Swift)

This document describes how API versioning ensures backward compatibility as features evolve.

---

## Version Headers

All clients MUST send these headers with every request:

```
X-App-Version: 1.3.0      # Semantic version of the app
X-App-Name: web           # 'web', 'customer', or 'business'
X-Api-Version: v2         # API version to use ('v1' or 'v2')
```

### Web (JavaScript/TypeScript)

```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';
import { getVersionHeaders } from './versioning';

export const supabase = createClient(url, key, {
  global: {
    headers: getVersionHeaders(),
  },
});
```

### iOS (Swift)

```swift
// SupabaseClient.swift
let headers = [
    "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
    "X-App-Name": "customer", // or "business"
    "X-Api-Version": "v2"
]

let config = URLSessionConfiguration.default
config.httpAdditionalHeaders = headers
```

---

## API Versions

### V1 (Legacy)

Minimum app version: `1.0.0`

Basic operations:
- Get menu items (flat list)
- Get stores
- Place order (basic)
- Get order

```typescript
// V1 order placement
const { data } = await supabase.rpc('rpc_v1_dispatch', {
  p_name: 'place_order',
  p_payload: {
    store_id: 1,
    customer_name: 'John',
    total: 15.99,
  },
});
```

### V2 (Current)

Minimum app version: `1.2.0`

Enhanced operations:
- Menu items with customizations
- Orders with items array
- Feature flags
- Compatibility checking
- Enhanced metrics

```typescript
// V2 order placement with items
const { data } = await supabase.rpc('rpc_v2_dispatch', {
  p_name: 'place_order',
  p_payload: {
    store_id: 1,
    customer_name: 'John',
    total: 15.99,
    items: [
      { menu_item_id: 1, quantity: 2, customizations: ['Extra bacon'] },
    ],
  },
});
```

---

## RPC Dispatch Functions

### rpc_v1_dispatch

```sql
SELECT rpc_v1_dispatch('get_menu_items', '{}');
SELECT rpc_v1_dispatch('place_order', '{"store_id": 1, "total": 15.99}');
```

Supported RPCs:
| RPC Name | Description |
|----------|-------------|
| `get_menu_items` | List available menu items |
| `get_stores` | List all stores |
| `get_order` | Get order by ID |
| `place_order` | Create new order |
| `get_rewards` | Get customer rewards |

### rpc_v2_dispatch

```sql
SELECT rpc_v2_dispatch('get_menu_items', '{}');
SELECT rpc_v2_dispatch('place_order', '{"store_id": 1, "items": [...]}');
```

Additional RPCs in V2:
| RPC Name | Description |
|----------|-------------|
| `get_features` | Get feature flags for app/version |
| `check_compatibility` | Check schema compatibility |
| `get_store_metrics` | Enhanced analytics (auth required) |

---

## API Gateway (Edge Function)

For centralized version routing, use the `api-dispatch` Edge Function:

```typescript
const response = await fetch(`${SUPABASE_URL}/functions/v1/api-dispatch`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-App-Version': '1.3.0',
    'X-App-Name': 'web',
  },
  body: JSON.stringify({
    rpc: 'get_menu_items',
    payload: {},
    version: 'v2', // Optional, uses header if not specified
  }),
});
```

Response format:

```json
{
  "data": [...],
  "meta": {
    "rpc": "get_menu_items",
    "version": "v2",
    "executionTime": 45,
    "requestId": "req_123456"
  }
}
```

---

## Feature Flags

Features can be toggled per app and version:

```typescript
// Check if feature is enabled
const { data: flags } = await supabase.rpc('get_feature_flags', {
  p_app_name: 'customer',
  p_app_version: '1.2.0',
});

const portionsEnabled = flags.find(f => f.feature === 'portion_customization')?.enabled;
```

### Default Feature Flags

| Feature | Min Version | Apps | Description |
|---------|-------------|------|-------------|
| `guest_checkout` | 1.0.0 | All | Guest checkout without account |
| `order_tracking` | 1.0.0 | All | Real-time order tracking |
| `rewards_program` | 1.0.0 | Customer | Points and tiers |
| `portion_customization` | 1.1.0 | Customer | None/Light/Regular/Extra |
| `analytics_basic` | 1.2.0 | Business | Basic analytics |
| `analytics_advanced` | 1.3.0 | Business | Advanced trends |
| `system_health` | 1.3.0 | Web | System health dashboard |

---

## Schema Compatibility

Check if client version is compatible with current schema:

```typescript
const { data } = await supabase.rpc('can_client_use_schema', {
  p_app_version: '1.2.0',
});

if (!data) {
  // Show update prompt
  alert('Please update your app to continue');
}
```

---

## Migration Safety

### Header Requirements

All migrations in `supabase/safe_migrations/` must include:

```sql
-- @requires_version: 1.3.0
-- @affects: customer, business, web
-- @breaking: false
-- @description: Add new analytics columns
```

### Compatibility Check

Before merging, run:

```bash
npm run migration:check
# or
node scripts/check-migration-compat.js
```

This validates that breaking changes don't exceed deployed app versions.

---

## Breaking Changes

When introducing breaking changes:

1. **Update `schema_migrations_contract`**:

```sql
INSERT INTO schema_migrations_contract (
  change_description,
  min_app_version,
  breaking_change,
  affected_apps
) VALUES (
  'Changed order status enum',
  '1.4.0',
  true,
  ARRAY['customer', 'business']
);
```

2. **Coordinate with mobile releases**:
   - Release new iOS apps first
   - Wait for adoption (e.g., 80% of users)
   - Then apply migration

3. **Provide backward compatibility**:
   - Keep old RPC versions working
   - Deprecate gradually (90 days minimum)

---

## Deprecation Process

1. **Announce**: Add `deprecated` status to API version
2. **Warn**: Log deprecation warnings in responses
3. **Sunset**: Set `sunset_date` in `api_versions`
4. **Remove**: After sunset date, remove support

```sql
UPDATE api_versions
SET status = 'deprecated', sunset_date = '2025-06-01'
WHERE version = 'v1';
```

---

## Testing Contracts

Run contract tests:

```bash
# All contract tests
npm run test:e2e -- --grep "Contract"

# V1 only
npm run test:e2e -- tests/e2e/contract_v1.spec.ts

# V2 only
npm run test:e2e -- tests/e2e/contract_v2.spec.ts
```

---

## Troubleshooting

### "Unsupported API version"

Client is using an API version that's no longer supported. Update the app.

### "App version incompatible"

Breaking schema changes require a newer app version. Prompt user to update.

### "Unknown RPC"

The requested RPC doesn't exist in the specified API version. Check spelling or upgrade API version.

---

## Version Matrix

| App | Current Version | Min Supported | Recommended |
|-----|-----------------|---------------|-------------|
| Web | 1.3.0 | 1.0.0 | 1.3.0 |
| Customer iOS | 1.2.0 | 1.0.0 | 1.2.0 |
| Business iOS | 1.2.0 | 1.0.0 | 1.2.0 |

---

## Changelog

### V2 (2025-12-02)
- Added feature flags system
- Added schema compatibility checking
- Enhanced order placement with items array
- Added rewards history
- Added metrics submission

### V1 (2024-01-01)
- Initial API version
- Basic CRUD operations
- Guest checkout support
