# Phase 13 Implementation Report

## Autonomous Operations Engine

**Date**: December 2, 2025
**Version**: 1.6.0
**Status**: Complete

---

## Executive Summary

Phase 13 introduces the Autonomous Operations Engine for Cameron's Connect, providing AI-powered automation for:

- **Dynamic Pricing**: Real-time price adjustments with safety guardrails (±15% caps)
- **Kitchen Load Prediction**: Forecasting and auto-response to kitchen capacity
- **Staffing Optimization**: AI-generated shift recommendations
- **Menu Profitability**: Margin analysis with matrix categorization
- **Operational Health**: Unified scoring across all metrics
- **V5 API Dispatcher**: New API version with autonomous ops RPCs
- **Cross-Platform Support**: Compatible with Web, Business iOS, and Customer apps

---

## Deliverables

### Database Migration (068_autonomous_ops_core.sql)

| Component | Status | Description |
|-----------|--------|-------------|
| `dynamic_pricing_rules` | ✅ | Per-item pricing rules with safety bounds |
| `kitchen_load_predictions` | ✅ | Kitchen capacity forecasts |
| `staffing_recommendations` | ✅ | AI-generated shift levels |
| `menu_profitability` | ✅ | Margin and sales analysis |
| `store_ops_settings` | ✅ | Per-store automation settings |
| `ops_alerts` | ✅ | Operational alerts and notifications |
| Safety Constraints | ✅ | ±15% price caps enforced at DB level |
| Indexes | ✅ | Optimized for all query patterns |
| RLS Policies | ✅ | Role-based data access |

### Materialized Views

| View | Purpose | Refresh |
|------|---------|---------|
| `mv_kitchen_load_60min` | 60-minute load aggregation | Concurrent |
| `mv_item_profitability_trends` | Profit trends with rising/stable/falling | Concurrent |

### V5 API RPCs

| RPC | Function | Safety |
|-----|----------|--------|
| `get_dynamic_pricing` | Get pricing suggestions | Bounds-checked |
| `calculate_dynamic_price` | Single item price calc | Capped ±15% |
| `get_kitchen_load` | Current load prediction | N/A |
| `predict_wait_time` | Customer wait estimate | N/A |
| `get_staffing_recommendations` | Shift recommendations | Confidence-filtered |
| `generate_staffing_recommendations` | Create new recommendations | N/A |
| `get_menu_profitability` | Profitability analysis | N/A |
| `calculate_menu_profitability` | Run analysis | N/A |
| `get_operational_health` | Unified health score | N/A |
| `get_ops_alerts` | Active alerts | N/A |
| `run_autonomous_cycle` | Full automation cycle | Dry-run default |

### Edge Function

| Function | Purpose | Auth Required |
|----------|---------|---------------|
| `autonomous-ops-engine` | Autonomous ops processing | Optional |

### Frontend Libraries

| File | Purpose |
|------|---------|
| `src/lib/autonomous-ops.ts` | TypeScript API client + React hooks |

### React Hooks

| Hook | Purpose |
|------|---------|
| `useAutonomousOps` | Main dashboard data + subscriptions |
| `useWaitTime` | Customer-facing wait time |
| `useDynamicPricing` | Pricing display + updates |
| `useMenuProfitability` | Profitability analysis |
| `useStaffingRecommendations` | Staffing data |

### Dashboard Component

| Component | Features |
|-----------|----------|
| `AutonomousOps.tsx` | 6-tab dashboard with Overview, Pricing, Kitchen, Staffing, Profitability, Settings |

### E2E Tests

| Test File | Coverage |
|-----------|----------|
| `ops_dynamic_pricing.spec.ts` | Safety bounds, confidence, constraints |
| `ops_kitchen_load.spec.ts` | Load prediction, wait times, auto-hide |
| `ops_staffing.spec.ts` | Recommendations, confidence, storage |
| `ops_profitability.spec.ts` | Margins, categorization, alerts |

### Documentation

| Document | Contents |
|----------|----------|
| `docs/AUTONOMOUS_OPS_ENGINE.md` | Complete system documentation |

---

## Technical Implementation

### Safety-First Architecture

**Database Constraints**:
```sql
-- Max price cannot exceed 15% of base
ALTER TABLE dynamic_pricing_rules
ADD CONSTRAINT dynamic_pricing_max_cap
CHECK (max_price <= base_price * 1.15);

-- Min price cannot be below 15% of base
ALTER TABLE dynamic_pricing_rules
ADD CONSTRAINT dynamic_pricing_min_floor
CHECK (min_price >= base_price * 0.85);
```

**Edge Function Validation**:
```typescript
const MAX_PRICE_MULTIPLIER = 1.15;
const MIN_PRICE_MULTIPLIER = 0.85;
const MIN_CONFIDENCE_THRESHOLD = 0.6;

// Always validate before returning
const validatedPricing = data.map((item) => ({
  ...item,
  suggested_price: Math.min(
    Math.max(item.suggested_price, item.base_price * MIN_PRICE_MULTIPLIER),
    item.base_price * MAX_PRICE_MULTIPLIER
  ),
  is_safe: item.confidence >= MIN_CONFIDENCE_THRESHOLD,
}));
```

### Dynamic Pricing Algorithm

**Price Calculation**:
```sql
CREATE OR REPLACE FUNCTION calculate_dynamic_price(p_item_id BIGINT, p_store_id BIGINT)
RETURNS TABLE (suggested_price NUMERIC, price_multiplier NUMERIC, confidence FLOAT, reason TEXT)
AS $$
DECLARE
  v_base_price NUMERIC;
  v_demand_score FLOAT;
  v_inventory_factor FLOAT;
  v_time_factor FLOAT;
  v_combined_multiplier FLOAT;
BEGIN
  -- Get base price
  SELECT base_price INTO v_base_price
  FROM dynamic_pricing_rules
  WHERE store_id = p_store_id AND item_id = p_item_id;

  -- Calculate demand score (0.8 - 1.2)
  v_demand_score := calculate_demand_score(p_item_id, p_store_id);

  -- Calculate inventory factor (0.9 - 1.1)
  v_inventory_factor := calculate_inventory_factor(p_item_id, p_store_id);

  -- Calculate time factor (0.95 - 1.05)
  v_time_factor := calculate_time_factor();

  -- Combine with weights
  v_combined_multiplier := (
    v_demand_score * 0.4 +
    v_inventory_factor * 0.3 +
    v_time_factor * 0.3
  );

  -- Return capped result
  RETURN QUERY SELECT
    LEAST(GREATEST(v_base_price * v_combined_multiplier, v_base_price * 0.85), v_base_price * 1.15),
    v_combined_multiplier,
    calculate_confidence(v_demand_score, v_inventory_factor),
    build_reason(v_demand_score, v_inventory_factor, v_time_factor);
END;
$$ LANGUAGE plpgsql;
```

### Kitchen Load Prediction

**Load Level Classification**:
```sql
CASE
  WHEN capacity_percentage >= 85 THEN 'critical'
  WHEN capacity_percentage >= 65 THEN 'high'
  WHEN capacity_percentage >= 40 THEN 'moderate'
  ELSE 'low'
END AS load_level
```

**Auto-Hide Trigger**:
```sql
CREATE TRIGGER trg_auto_hide_slow_items
  AFTER INSERT ON kitchen_load_predictions
  FOR EACH ROW
  WHEN (NEW.load_level = 'critical')
  EXECUTE FUNCTION auto_hide_slow_items();
```

### Menu Matrix Categorization

| Category | Criteria | Action |
|----------|----------|--------|
| **Stars** | margin ≥ 60%, quantity ≥ 10 | Feature prominently |
| **Puzzles** | margin ≥ 60%, quantity < 10 | Promote more |
| **Plowhorses** | margin < 60%, quantity ≥ 10 | Consider price increase |
| **Dogs** | margin < 60%, quantity < 10 | Consider removal |

### Operational Health Score

**Calculation**:
```sql
overall_score = (
  kitchen_score * 0.25 +
  inventory_score * 0.25 +
  staff_score * 0.25 +
  pricing_score * 0.25
)

grade = CASE
  WHEN overall_score >= 90 THEN 'A'
  WHEN overall_score >= 80 THEN 'B'
  WHEN overall_score >= 70 THEN 'C'
  WHEN overall_score >= 60 THEN 'D'
  ELSE 'F'
END
```

### V5 API Compatibility

**Backward Compatibility**:
```sql
CREATE OR REPLACE FUNCTION rpc_v5_dispatch(p_name TEXT, p_payload JSONB)
RETURNS JSONB AS $$
BEGIN
  CASE p_name
    -- V5 autonomous ops RPCs
    WHEN 'get_dynamic_pricing' THEN RETURN get_dynamic_pricing_impl(p_payload);
    WHEN 'get_kitchen_load' THEN RETURN get_kitchen_load_impl(p_payload);
    -- ...more V5 RPCs...

    -- Fall back to V4 for unknown RPCs
    ELSE RETURN rpc_v4_dispatch(p_name, p_payload);
  END CASE;
END;
$$ LANGUAGE plpgsql;
```

**Route API Call Update**:
```sql
ALTER FUNCTION route_api_call ADD CASE
  WHEN p_requested_version = 'v5' THEN
    RETURN rpc_v5_dispatch(p_name, p_payload);
```

---

## Web + iOS Compatibility

### Web Dashboard

- **AutonomousOps.tsx**: 6-tab dashboard with real-time data
- **Real-time subscriptions**: Live updates for alerts, load, pricing
- **Settings management**: Per-store automation configuration
- **Dry-run support**: Preview autonomous actions before applying

### Business iOS App

**Kitchen Load Indicator**:
```swift
let response = try await supabase.rpc(
    "rpc_v5_dispatch",
    params: [
        "p_name": "get_kitchen_load",
        "p_payload": ["store_id": storeId, "window_minutes": 30]
    ]
)
// Display color-coded load level
```

**Pricing Alerts**:
```swift
let alerts = try await supabase.rpc(
    "rpc_v5_dispatch",
    params: [
        "p_name": "get_ops_alerts",
        "p_payload": ["store_id": storeId]
    ]
)
// Show critical alerts in-app
```

**Staffing View**:
```swift
let staffing = try await supabase.rpc(
    "rpc_v5_dispatch",
    params: [
        "p_name": "get_staffing_recommendations",
        "p_payload": ["store_id": storeId, "date": todayStr]
    ]
)
// Display hourly recommendations
```

### Customer iOS App

**Wait Time Display**:
```swift
let waitTime = try await supabase.rpc(
    "rpc_v5_dispatch",
    params: [
        "p_name": "predict_wait_time",
        "p_payload": ["store_id": storeId, "item_ids": cartItemIds]
    ]
)
// Show: "Estimated wait: 15-20 min"
```

**Dynamic Price Badge**:
```swift
let pricing = try await supabase.rpc(
    "rpc_v5_dispatch",
    params: [
        "p_name": "get_dynamic_pricing",
        "p_payload": ["store_id": storeId, "item_id": itemId]
    ]
)
// If multiplier > 1: Show "Peak pricing" badge
```

---

## Performance Metrics

### Expected Latencies

| Operation | Target | Notes |
|-----------|--------|-------|
| Dynamic pricing | <100ms | Cached 1 minute |
| Kitchen load | <100ms | Real-time calculation |
| Wait time prediction | <150ms | Based on current load |
| Staffing recommendations | <200ms | Date-based query |
| Profitability analysis | <300ms | 30-day aggregation |
| Operational health | <150ms | Combined scores |

### Caching Strategy

- **Edge Function**: 1-minute TTL for operational data (time-sensitive)
- **Materialized Views**: Refreshed CONCURRENTLY (no downtime)
- **Client-side**: React Query with stale-while-revalidate

---

## Deployment Checklist

### Pre-Deployment

- [ ] Run migration 068 on staging
- [ ] Verify safety constraints work correctly
- [ ] Test V5 RPCs with existing data
- [ ] Validate materialized views populate

### Deployment

- [ ] Apply migration 068 to production
- [ ] Deploy `autonomous-ops-engine` Edge Function
- [ ] Configure store_ops_settings for active stores
- [ ] Set conservative initial bounds (±10%)

### Post-Deployment

- [ ] Monitor runtime_metrics for errors
- [ ] Review first week of pricing suggestions
- [ ] Gather staff feedback on recommendations
- [ ] Adjust confidence thresholds based on accuracy

---

## Future Enhancements

### Planned for Phase 14+

1. **External Data Integration**: Weather API for demand prediction
2. **Advanced ML Models**: Custom demand forecasting
3. **Competitor Pricing**: Price matching intelligence
4. **Auto-Ordering**: Supplier integration for inventory
5. **Labor Cost Optimization**: Factor in overtime, breaks
6. **Multi-Store Optimization**: Cross-store inventory balancing

---

## Files Created/Modified

### New Files

```
supabase/migrations/068_autonomous_ops_core.sql
supabase/functions/autonomous-ops-engine/index.ts
src/lib/autonomous-ops.ts
src/components/dashboard/AutonomousOps.tsx
tests/e2e/ops_dynamic_pricing.spec.ts
tests/e2e/ops_kitchen_load.spec.ts
tests/e2e/ops_staffing.spec.ts
tests/e2e/ops_profitability.spec.ts
docs/AUTONOMOUS_OPS_ENGINE.md
PHASE_13_IMPLEMENTATION_REPORT.md
```

---

## Conclusion

Phase 13 successfully implements the Autonomous Operations Engine for Cameron's Connect with:

**Key Achievements**:
- Safety-first design with database-level constraints
- Full backward compatibility with V1-V4 clients
- Real-time dashboard with 6 functional tabs
- Comprehensive E2E test coverage
- Production-ready documentation

**Safety Guarantees**:
- Maximum ±15% price change enforced at database level
- Minimum 60% confidence for automated actions
- Dry-run mode default for autonomous cycles
- Manual approval required for pricing changes

**Recommended Next Steps**:
1. Run migration on staging environment
2. Configure initial store settings conservatively
3. Monitor pricing suggestions for 2 weeks before enabling
4. Train staff on dashboard and alert responses
