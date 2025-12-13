# Global Architecture Guide

**Cameron's Connect - Multi-Region Infrastructure**

---

## Overview

Cameron's Connect operates a globally distributed architecture designed for:
- **Low latency** for customers across regions
- **High availability** through regional redundancy
- **Zero-downtime deployments** via hot version switching
- **Backward compatibility** across iOS and web clients

---

## Architecture Diagram

```
                                    ┌─────────────────────────────────────┐
                                    │           Client Apps               │
                                    │  Web │ Customer iOS │ Business iOS  │
                                    └──────────────┬──────────────────────┘
                                                   │
                                    ┌──────────────▼──────────────────────┐
                                    │        Global API Gateway           │
                                    │   (supabase/functions/api-gateway)  │
                                    │                                     │
                                    │  • Version negotiation (v1/v2/v3)   │
                                    │  • Region routing                   │
                                    │  • Client telemetry                 │
                                    │  • Request metrics                  │
                                    └──────────────┬──────────────────────┘
                                                   │
                    ┌──────────────────────────────┼──────────────────────────────┐
                    │                              │                              │
         ┌──────────▼──────────┐       ┌──────────▼──────────┐       ┌──────────▼──────────┐
         │     US-East-1       │       │     US-West-2       │       │     EU-West-1       │
         │     (Primary)       │       │   (Read Replica)    │       │   (Read Replica)    │
         │                     │       │                     │       │                     │
         │  ┌───────────────┐  │       │  ┌───────────────┐  │       │  ┌───────────────┐  │
         │  │   Supabase    │  │       │  │   Supabase    │  │       │  │   Supabase    │  │
         │  │   Project     │◄─┼───────┼──│   Project     │  │       │  │   Project     │  │
         │  │  (Primary DB) │──┼───────┼─►│ (Read Replica)│  │       │  │ (Read Replica)│  │
         │  └───────────────┘  │       │  └───────────────┘  │       │  └───────────────┘  │
         │         │           │       │                     │       │                     │
         │  ┌──────▼────────┐  │       │                     │       │                     │
         │  │   Realtime    │  │       │                     │       │                     │
         │  │    Fanout     │──┼───────┼─────────────────────┼───────┼─────────────────────┤
         │  └───────────────┘  │       │                     │       │                     │
         └─────────────────────┘       └─────────────────────┘       └─────────────────────┘
```

---

## Components

### 1. Global API Gateway

**Location**: `supabase/functions/api-gateway/index.ts`

The gateway is the single entry point for all API calls.

**Responsibilities**:
- Parse client version headers
- Route to optimal region
- Negotiate API version (v1/v2/v3)
- Set Postgres session context
- Log metrics and telemetry

**Request Flow**:
```
1. Client sends request with headers:
   - X-App-Version: 1.4.0
   - X-App-Name: customer
   - X-Api-Version: v3
   - X-Client-Region: us-west-2

2. Gateway determines:
   - Target region (primary for writes, closest for reads)
   - API version (based on client compatibility)

3. Gateway sets Postgres session context

4. Gateway routes to appropriate RPC dispatcher

5. Response includes metadata:
   - X-Request-ID
   - X-API-Version
   - X-Region
   - X-Execution-Time
```

**Usage**:
```typescript
const response = await fetch(`${SUPABASE_URL}/functions/v1/api-gateway`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-App-Version': '1.4.0',
    'X-App-Name': 'web',
    'X-Api-Version': 'v3',
    'X-Client-Region': 'us-east-1',
  },
  body: JSON.stringify({
    rpc: 'get_menu_items',
    payload: {},
  }),
});
```

---

### 2. Region Routing

**Client Library**: `src/lib/regioning.ts`

**Available Regions**:
| Region | Name | Role |
|--------|------|------|
| us-east-1 | US East (N. Virginia) | Primary |
| us-west-2 | US West (Oregon) | Read Replica |
| eu-west-1 | EU (Ireland) | Read Replica |
| ap-southeast-1 | Asia Pacific (Singapore) | Read Replica |

**Routing Rules**:
1. **Write operations** always go to primary (us-east-1)
2. **Read operations** use the closest replica
3. **Fallback** to primary if replica is unhealthy

**Client Region Detection**:
```typescript
import { detectUserRegion, getUserRegion, setUserRegion } from '@/lib/regioning';

// Auto-detect based on timezone
const detected = detectUserRegion();

// Get stored preference (or detect)
const current = getUserRegion();

// Override user preference
setUserRegion('eu-west-1');
```

**Health Checking**:
```typescript
import { checkRegionHealth, getFailoverRegion } from '@/lib/regioning';

const health = await checkRegionHealth('us-east-1');
if (!health.healthy) {
  const fallback = getFailoverRegion('us-east-1');
}
```

---

### 3. API Versioning

**Library**: `src/lib/versioning.ts`

**Supported Versions**:
| Version | Min App Version | Features |
|---------|-----------------|----------|
| v1 | 1.0.0 | Basic CRUD, guest checkout |
| v2 | 1.2.0 | Items array, feature flags, compatibility checking |
| v3 | 1.4.0 | Region tracking, enhanced metrics, full customizations |

**Version Selection**:
```typescript
import { getBestApiVersion, canUseApiVersion } from '@/lib/versioning';

// Get best version for current app
const version = getBestApiVersion(); // 'v3' if app >= 1.4.0

// Check if specific version is usable
if (canUseApiVersion('v3')) {
  // Use v3 features
}
```

**Direct RPC Dispatch**:
```typescript
import { dispatchRpc, routeApiCall } from '@/lib/versioning';

// Call specific version
const result = await dispatchRpc(supabase, 'get_menu_items', {}, {
  version: 'v2',
});

// Let router auto-select version
const result = await routeApiCall(supabase, 'get_menu_items', {});
```

---

### 4. Realtime Fanout

**Location**: `supabase/functions/realtime-fanout/index.ts`

Synchronizes real-time events across all regions.

**Supported Events**:
| Event Type | Description | Priority |
|------------|-------------|----------|
| order_status | Order status change | High |
| order_created | New order placed | Normal |
| menu_updated | Menu item changed | Normal |
| store_status | Store open/closed | High |
| custom | Generic events | Configurable |

**Usage**:
```typescript
const response = await fetch(`${SUPABASE_URL}/functions/v1/realtime-fanout`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    type: 'order_status',
    payload: {
      order_id: 123,
      status: 'preparing',
      previous_status: 'pending',
    },
    sourceRegion: 'us-east-1',
    priority: 'high',
  }),
});
```

**Response**:
```json
{
  "success": true,
  "eventId": 456,
  "deliveries": [
    { "region": "us-west-2", "success": true, "latencyMs": 45 },
    { "region": "eu-west-1", "success": true, "latencyMs": 120 }
  ],
  "totalLatencyMs": 125
}
```

---

### 5. Zero-Downtime Releases

**Hot Version Switching**:

The system maintains an `active_api_version` singleton table:

```sql
SELECT * FROM active_api_version;
-- current_version: 'v3'
-- fallback_version: 'v2'
-- updated_at: 2025-12-02T...
```

**Switching Versions** (requires super_admin):
```sql
SELECT switch_api_version('v3', 'v2');
-- Returns: { success: true, previous_version: 'v2', current_version: 'v3' }
```

**Universal Router**:
The `route_api_call` function automatically:
1. Checks active version
2. Validates client compatibility
3. Falls back if needed
4. Dispatches to correct version

```sql
SELECT route_api_call('get_menu_items', '{}', NULL);
-- Automatically routes to active version
```

---

## Database Schema (Migration 066)

### Tables

**regions**
```sql
CREATE TABLE regions (
  id TEXT PRIMARY KEY,           -- 'us-east-1', 'us-west-2', etc.
  name TEXT NOT NULL,            -- 'US East (N. Virginia)'
  is_primary BOOLEAN,            -- true for primary
  is_read_replica BOOLEAN,       -- true for replicas
  status TEXT                    -- 'active', 'degraded', 'offline'
);
```

**region_health**
```sql
CREATE TABLE region_health (
  region_id TEXT REFERENCES regions(id),
  healthy BOOLEAN,
  latency_ms INTEGER,
  consecutive_failures INTEGER,
  last_check_at TIMESTAMPTZ
);
```

**client_region_telemetry**
```sql
CREATE TABLE client_region_telemetry (
  client_id TEXT UNIQUE,
  region_id TEXT,
  app_name TEXT,
  app_version TEXT,
  api_version TEXT,
  last_seen_at TIMESTAMPTZ,
  request_count INTEGER
);
```

**active_api_version**
```sql
CREATE TABLE active_api_version (
  id INTEGER PRIMARY KEY DEFAULT 1,  -- Singleton
  current_version TEXT NOT NULL,
  fallback_version TEXT NOT NULL,
  updated_at TIMESTAMPTZ
);
```

**realtime_fanout_log**
```sql
CREATE TABLE realtime_fanout_log (
  id SERIAL PRIMARY KEY,
  event_type TEXT,
  source_region TEXT,
  target_regions TEXT[],
  payload_size INTEGER,
  fanout_at TIMESTAMPTZ,
  delivery_status JSONB
);
```

### Key Functions

| Function | Description |
|----------|-------------|
| `rpc_v3_dispatch(name, payload)` | V3 API dispatcher |
| `route_api_call(name, payload, version)` | Universal router |
| `switch_api_version(new, fallback)` | Hot version switch |
| `get_active_api_version()` | Get current config |
| `register_client_region(...)` | Update client telemetry |
| `get_region_sync_status()` | Get replication lag |
| `update_region_health(...)` | Update health status |
| `log_realtime_fanout(...)` | Log fanout event |

---

## Client Integration

### Web (React)

```typescript
// Initialize at app startup
import { initRegioning } from '@/lib/regioning';
import { initVersioning } from '@/lib/versioning';

async function init() {
  // Initialize region detection
  const { region, latency, healthy } = await initRegioning();
  console.log(`Connected to ${region} (${latency}ms)`);

  // Initialize versioning
  const { compatible, features } = await initVersioning(supabase);
  if (!compatible) {
    showUpdatePrompt();
  }
}
```

### iOS (Swift)

```swift
// Set version headers
let headers = [
    "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
    "X-App-Name": "customer", // or "business"
    "X-Api-Version": "v3",
    "X-Client-Region": detectRegion()
]

// Call API gateway
let request = URLRequest(url: URL(string: "\(supabaseUrl)/functions/v1/api-gateway")!)
request.httpMethod = "POST"
request.allHTTPHeaderFields = headers
request.httpBody = try? JSONEncoder().encode([
    "rpc": "get_menu_items",
    "payload": [:]
])
```

---

## Deployment

### Rolling Out New API Version

1. **Deploy migration with new RPC functions**
   ```bash
   # Run migration 066 in Supabase SQL Editor
   ```

2. **Deploy Edge Functions**
   ```bash
   supabase functions deploy api-gateway
   supabase functions deploy realtime-fanout
   ```

3. **Update clients** to send new version headers

4. **Switch active version** when ready
   ```sql
   SELECT switch_api_version('v3', 'v2');
   ```

5. **Monitor** via runtime_metrics and telemetry

### Rollback

If issues occur:
```sql
-- Switch back to previous version
SELECT switch_api_version('v2', 'v1');
```

Old clients continue working immediately.

---

## Monitoring

### Client Telemetry

```sql
-- Active clients by region
SELECT region_id, COUNT(*) as clients
FROM client_region_telemetry
WHERE last_seen_at > NOW() - INTERVAL '1 hour'
GROUP BY region_id;

-- API version distribution
SELECT api_version, COUNT(*) as clients
FROM client_region_telemetry
WHERE last_seen_at > NOW() - INTERVAL '1 day'
GROUP BY api_version;
```

### Gateway Metrics

```sql
-- Average latency by RPC
SELECT
  metadata->>'rpc' as rpc,
  AVG(metric_value) as avg_latency_ms
FROM runtime_metrics
WHERE metric_name LIKE 'gateway_%'
GROUP BY metadata->>'rpc'
ORDER BY avg_latency_ms DESC;
```

### Fanout Success Rate

```sql
-- Fanout delivery success rate
SELECT
  event_type,
  COUNT(*) as total,
  SUM(CASE WHEN (delivery_status->>'success')::boolean THEN 1 ELSE 0 END) as successful
FROM realtime_fanout_log
WHERE fanout_at > NOW() - INTERVAL '1 day'
GROUP BY event_type;
```

---

## Testing

### Run All Region Tests

```bash
# Region routing
npm run test:e2e -- tests/e2e/region_routing.spec.ts

# Realtime fanout
npm run test:e2e -- tests/e2e/realtime_fanout.spec.ts

# Zero-downtime
npm run test:e2e -- tests/e2e/zero_downtime.spec.ts

# All multi-region tests
npm run test:e2e -- --grep "Region|Fanout|Zero-Downtime"
```

### CI Workflow

The `ci-region-routing.yml` workflow runs on:
- Push to main/develop affecting region files
- Pull requests to main
- Manual dispatch with optional stress tests

---

## Troubleshooting

### "Region unavailable"

1. Check region health: `SELECT * FROM region_health;`
2. Verify Supabase project status
3. Check network connectivity

### "Version incompatible"

1. Check `active_api_version` table
2. Verify client version meets requirements
3. Check `api_versions` table for version status

### "Fanout failed"

1. Check `realtime_fanout_log` for delivery status
2. Verify target region health
3. Check Edge Function logs

### High latency

1. Check region latency: `SELECT * FROM region_health ORDER BY latency_ms;`
2. Verify client is routing to closest region
3. Check for replication lag

---

## Security

- **RLS Policies**: All tables have appropriate RLS
- **Service Role**: Only Edge Functions use service role
- **Client Keys**: Clients use anon key only
- **Version Switching**: Requires super_admin role

---

## Future Enhancements

1. **Auto-scaling regions** based on load
2. **Geo-DNS** for automatic region selection
3. **Read-your-writes consistency** for writes followed by reads
4. **Regional data residency** for compliance
5. **Active-active multi-primary** configuration
