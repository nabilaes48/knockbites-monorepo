# Phase 10 Implementation Report

**Cameron's Connect - Multi-App Versioning & Compatibility Layer**

**Date**: 2025-12-02
**Status**: COMPLETE

---

## Executive Summary

Phase 10 established a comprehensive API versioning and compatibility system that ensures the Business iOS app, Customer iOS app, and Web Dashboard remain compatible with the Supabase backend as features evolve.

---

## Deliverables Completed

### 1. Versioning Library (`src/lib/versioning.ts`)

**Features**:
- Version header generation for all clients
- Semantic version parsing and comparison
- Feature flag fetching and caching
- Schema compatibility checking
- Version dispatch helpers

**API**:
```typescript
import {
  APP_VERSION,
  APP_NAME,
  getVersionHeaders,
  fetchFeatureFlags,
  isFeatureEnabled,
  checkSchemaCompatibility,
  dispatchRpc,
  initVersioning,
} from '@/lib/versioning';

// Initialize at app startup
const { compatible, features } = await initVersioning(supabase);

// Check feature availability
if (isFeatureEnabled(features, 'portion_customization')) {
  // Show portion selector
}

// Call versioned RPC
const { data } = await dispatchRpc(supabase, 'get_menu_items', {});
```

---

### 2. Supabase Client Update (`src/lib/supabase.ts`)

Updated to automatically include version headers:

```typescript
export const supabase = createClient(url, key, {
  global: {
    headers: getVersionHeaders(),
  },
});
```

**Headers Sent**:
- `X-App-Version`: Current app version
- `X-App-Name`: 'web', 'customer', or 'business'
- `X-Api-Version`: 'v1' or 'v2'

---

### 3. Migration 065: Versioning Framework

**Tables Created**:

#### schema_migrations_contract
Tracks breaking schema changes and version requirements:
```sql
CREATE TABLE schema_migrations_contract (
  id SERIAL PRIMARY KEY,
  change_description TEXT NOT NULL,
  added_on TIMESTAMPTZ DEFAULT NOW(),
  min_app_version TEXT NOT NULL,
  breaking_change BOOLEAN DEFAULT false,
  affected_apps TEXT[],
  migration_file TEXT,
  notes TEXT
);
```

#### app_feature_flags
Controls feature availability per app/version:
```sql
CREATE TABLE app_feature_flags (
  id SERIAL PRIMARY KEY,
  app_name TEXT NOT NULL,
  min_version TEXT NOT NULL,
  max_version TEXT,
  feature TEXT NOT NULL,
  enabled BOOLEAN DEFAULT true,
  description TEXT
);
```

#### api_versions
Registry of supported API versions:
```sql
CREATE TABLE api_versions (
  version TEXT PRIMARY KEY,
  status TEXT DEFAULT 'active',
  min_app_version TEXT NOT NULL,
  sunset_date DATE
);
```

---

### 4. New RPC Functions

#### Version Comparison
```sql
parse_semver(version TEXT) → INTEGER
compare_versions(a TEXT, b TEXT) → INTEGER
meets_min_version(current TEXT, min TEXT) → BOOLEAN
```

#### Schema Compatibility
```sql
can_client_use_schema(p_app_version TEXT) → BOOLEAN
get_min_compatible_version() → TEXT
```

#### Feature Flags
```sql
get_feature_flags(p_app_name TEXT, p_app_version TEXT) → TABLE
is_feature_enabled(p_app_name TEXT, p_app_version TEXT, p_feature TEXT) → BOOLEAN
```

#### Versioned Dispatch
```sql
rpc_v1_dispatch(p_name TEXT, p_payload JSONB) → JSONB
rpc_v2_dispatch(p_name TEXT, p_payload JSONB) → JSONB
set_client_context(p_app_version TEXT, p_app_name TEXT, p_api_version TEXT) → VOID
```

---

### 5. API Dispatch Edge Function

**File**: `supabase/functions/api-dispatch/index.ts`

**Purpose**: Central gateway for versioned API calls

**Flow**:
1. Read version headers from request
2. Set Postgres session variables
3. Route to correct RPC version (v1 or v2)
4. Log to runtime_metrics
5. Return response with metadata

**Request**:
```json
{
  "rpc": "get_menu_items",
  "payload": {},
  "version": "v2"
}
```

**Response**:
```json
{
  "data": [...],
  "meta": {
    "rpc": "get_menu_items",
    "version": "v2",
    "executionTime": 45,
    "requestId": "req_123"
  }
}
```

---

### 6. Migration Compatibility Checker

**File**: `scripts/check-migration-compat.js`

**Features**:
- Parses migration header comments
- Validates against deployed app versions
- Blocks breaking changes that exceed deployed versions
- Reports compatibility status

**Usage**:
```bash
npm run migration:check
node scripts/check-migration-compat.js --file=supabase/migrations/066_new.sql
```

**Header Format**:
```sql
-- @requires_version: 1.3.0
-- @affects: customer, business, web
-- @breaking: false
-- @description: Add new feature
```

---

### 7. Contract E2E Tests

#### V1 Contract Tests (`tests/e2e/contract_v1.spec.ts`)
- Menu items response shape
- Stores response shape
- Order placement (basic)
- Guest checkout flow
- RLS enforcement

#### V2 Contract Tests (`tests/e2e/contract_v2.spec.ts`)
- Menu items with customizations
- Orders with items array
- Feature flags
- Compatibility checking
- Version headers
- Backward compatibility

---

### 8. GitHub Actions Workflow

**File**: `.github/workflows/migration-check.yml`

**Triggers**:
- PR with changes to `supabase/migrations/**`
- PR with changes to `supabase/safe_migrations/**`
- Manual workflow dispatch

**Checks**:
1. Changed files detection
2. Migration compatibility validation
3. Breaking change warnings
4. Header validation

---

### 9. API Versioning Documentation

**File**: `docs/API_VERSIONING.md`

**Contents**:
- Version header requirements
- API versions (v1, v2)
- RPC dispatch usage
- Feature flags system
- Schema compatibility
- Migration safety
- Breaking change process
- Deprecation timeline

---

## Files Created

| File | Purpose |
|------|---------|
| `src/lib/versioning.ts` | Versioning utilities |
| `supabase/migrations/065_versioning_framework.sql` | Version tables + RPCs |
| `supabase/functions/api-dispatch/index.ts` | API gateway |
| `scripts/check-migration-compat.js` | Migration validator |
| `supabase/safe_migrations/MIGRATION_TEMPLATE.sql` | Migration template |
| `tests/e2e/contract_v1.spec.ts` | V1 contract tests |
| `tests/e2e/contract_v2.spec.ts` | V2 contract tests |
| `docs/API_VERSIONING.md` | Documentation |
| `.github/workflows/migration-check.yml` | CI workflow |

## Files Modified

| File | Changes |
|------|---------|
| `src/lib/supabase.ts` | Added version headers |
| `package.json` | Added migration:check script |

---

## New RPCs Summary

| Function | Description | Auth |
|----------|-------------|------|
| `rpc_v1_dispatch` | Route to v1 implementations | Public |
| `rpc_v2_dispatch` | Route to v2 implementations | Public |
| `can_client_use_schema` | Check version compatibility | Public |
| `get_feature_flags` | Get enabled features | Public |
| `is_feature_enabled` | Check single feature | Public |
| `set_client_context` | Set session variables | Service |
| `parse_semver` | Parse version to int | Public |
| `compare_versions` | Compare two versions | Public |
| `meets_min_version` | Check min version | Public |
| `get_min_compatible_version` | Get required version | Public |

---

## Schema Changes Summary

### New Tables
- `schema_migrations_contract` - Breaking change tracking
- `app_feature_flags` - Per-app feature toggles
- `api_versions` - API version registry

### RLS Policies
- Public read on all new tables
- Write restricted to super_admin

### Indexes
- `idx_schema_migrations_breaking` - Breaking changes lookup
- `idx_feature_flags_lookup` - Feature flag queries

---

## Version Negotiation Flow

```
Client Request
    │
    ├─── Headers ───────────────────┐
    │    X-App-Version: 1.3.0       │
    │    X-App-Name: customer       │
    │    X-Api-Version: v2          │
    │                               │
    ▼                               ▼
┌───────────────┐           ┌───────────────┐
│ Direct REST   │           │ api-dispatch  │
│ Call          │           │ Edge Function │
└───────┬───────┘           └───────┬───────┘
        │                           │
        │                           ▼
        │                   ┌───────────────┐
        │                   │ set_client_   │
        │                   │ context()     │
        │                   └───────┬───────┘
        │                           │
        ▼                           ▼
┌───────────────────────────────────────────┐
│           Postgres RLS Check              │
│  current_setting('request.session...')    │
└───────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────┐
│     rpc_v1_dispatch / rpc_v2_dispatch     │
└───────────────────────────────────────────┘
        │
        ▼
    Response
```

---

## Compatibility Guarantees

### V1 Compatibility (app v1.0.0+)
- Basic menu listing
- Basic order placement
- Guest checkout
- Store listing
- Order retrieval

### V2 Compatibility (app v1.2.0+)
- All V1 features
- Menu with customizations
- Orders with items array
- Feature flags
- Compatibility checking
- Enhanced metrics

### Breaking Change Policy
1. Update `schema_migrations_contract`
2. Coordinate with mobile releases
3. Wait for 80% adoption
4. Apply migration
5. Maintain backward compatibility for 90 days

---

## Test Suites

### Contract Tests
```bash
# Run all contract tests
npm run test:e2e -- --grep "Contract"

# V1 only
npm run test:e2e -- tests/e2e/contract_v1.spec.ts

# V2 only
npm run test:e2e -- tests/e2e/contract_v2.spec.ts
```

### Migration Checks
```bash
# Check all migrations
npm run migration:check

# Check specific file
npm run migration:check -- --file=path/to/migration.sql
```

---

## Summary

Phase 10 establishes a robust multi-app compatibility system:

- **Version Headers**: All clients identify themselves
- **API Versioning**: v1 and v2 with different capabilities
- **Feature Flags**: Per-app feature control
- **Schema Compatibility**: Breaking change tracking
- **Safe Migrations**: Header requirements and CI checks
- **Contract Tests**: Ensure API stability

The platform can now safely evolve while maintaining backward compatibility with older mobile app versions.

---

**Next Steps**:
1. Run migration 065 in Supabase SQL Editor
2. Update iOS apps to send version headers
3. Deploy api-dispatch Edge Function
4. Configure deployed versions in CI workflow
5. Run contract tests to verify compatibility
