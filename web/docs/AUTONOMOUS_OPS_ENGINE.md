# Autonomous Operations Engine

## Overview

The Autonomous Operations Engine is an AI-powered system that automates key operational decisions for Cameron's Connect stores. It provides:

- **Dynamic Pricing**: AI-adjusted prices based on demand, inventory, and time factors
- **Kitchen Load Prediction**: Real-time load forecasting and wait time estimates
- **Staffing Optimization**: AI-generated shift recommendations based on predicted demand
- **Menu Profitability**: Margin analysis and item categorization (Stars, Puzzles, Plowhorses, Dogs)
- **Operational Health**: Unified score across all operational metrics

## Safety-First Design

The system prioritizes safety with built-in guardrails:

| Guardrail | Default Value | Purpose |
|-----------|---------------|---------|
| Max Price Increase | 15% | Prevent price gouging |
| Max Price Decrease | 15% | Protect margins |
| Min Confidence Threshold | 60% | Require high confidence for automation |
| Dry Run Mode | Enabled | Preview changes before applying |
| Manual Approval | Required | Manager sign-off for pricing changes |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Client Apps                             │
│   (Web Dashboard, Customer App, Business iOS App)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 V5 API Dispatcher                            │
│   (Autonomous Ops RPCs + V4/V3/V2 Fallback)                 │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Autonomous Ops │  │  Materialized   │  │  Safety         │
│  Edge Function  │  │  Views          │  │  Validators     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    PostgreSQL Database                       │
│   - dynamic_pricing_rules   - kitchen_load_predictions      │
│   - staffing_recommendations - menu_profitability           │
│   - store_ops_settings      - ops_alerts                    │
└─────────────────────────────────────────────────────────────┘
```

## Database Schema

### dynamic_pricing_rules

Stores pricing rules per item per store with safety bounds.

```sql
CREATE TABLE dynamic_pricing_rules (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id),
  item_id BIGINT REFERENCES menu_items(id),
  base_price NUMERIC(10, 2) NOT NULL,
  min_price NUMERIC(10, 2) NOT NULL,
  max_price NUMERIC(10, 2) NOT NULL,
  demand_multiplier FLOAT DEFAULT 1.0,
  inventory_multiplier FLOAT DEFAULT 1.0,
  time_multiplier FLOAT DEFAULT 1.0,
  is_enabled BOOLEAN DEFAULT true,
  last_updated_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, item_id)
);

-- Safety constraint: Max price cannot exceed 15% of base
ALTER TABLE dynamic_pricing_rules
ADD CONSTRAINT dynamic_pricing_max_cap
CHECK (max_price <= base_price * 1.15);

-- Safety constraint: Min price cannot be below 15% of base
ALTER TABLE dynamic_pricing_rules
ADD CONSTRAINT dynamic_pricing_min_floor
CHECK (min_price >= base_price * 0.85);
```

### kitchen_load_predictions

Stores kitchen load forecasts.

```sql
CREATE TABLE kitchen_load_predictions (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id),
  prediction_time TIMESTAMPTZ NOT NULL,
  window_minutes INTEGER NOT NULL,
  predicted_orders INTEGER NOT NULL,
  predicted_prep_time INTEGER NOT NULL,
  load_level TEXT NOT NULL,  -- 'low', 'moderate', 'high', 'critical'
  capacity_percentage FLOAT NOT NULL,
  bottleneck_items BIGINT[] DEFAULT '{}',
  confidence FLOAT NOT NULL,
  factors JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### staffing_recommendations

AI-generated staffing levels.

```sql
CREATE TABLE staffing_recommendations (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id),
  recommendation_date DATE NOT NULL,
  hour_of_day INTEGER NOT NULL,
  current_staff INTEGER DEFAULT 0,
  recommended_staff INTEGER NOT NULL,
  predicted_orders INTEGER NOT NULL,
  confidence FLOAT NOT NULL,
  reason TEXT,
  is_approved BOOLEAN DEFAULT false,
  approved_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, recommendation_date, hour_of_day)
);
```

### menu_profitability

Stores margin and sales analysis.

```sql
CREATE TABLE menu_profitability (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id),
  item_id BIGINT REFERENCES menu_items(id),
  analysis_date DATE NOT NULL,
  total_quantity INTEGER DEFAULT 0,
  total_revenue NUMERIC(12, 2) DEFAULT 0,
  total_cost NUMERIC(12, 2) DEFAULT 0,
  total_profit NUMERIC(12, 2) DEFAULT 0,
  margin_percentage FLOAT DEFAULT 0,
  avg_daily_sales FLOAT DEFAULT 0,
  trend TEXT,  -- 'rising', 'stable', 'falling'
  category TEXT,  -- 'star', 'puzzle', 'plowhorse', 'dog'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, item_id, analysis_date)
);
```

### store_ops_settings

Per-store autonomous operations configuration.

```sql
CREATE TABLE store_ops_settings (
  store_id BIGINT PRIMARY KEY REFERENCES stores(id),
  dynamic_pricing_enabled BOOLEAN DEFAULT false,
  auto_hide_slow_items BOOLEAN DEFAULT true,
  kitchen_capacity_per_hour INTEGER DEFAULT 30,
  max_price_increase_pct INTEGER DEFAULT 15,
  max_price_decrease_pct INTEGER DEFAULT 15,
  min_confidence_threshold FLOAT DEFAULT 0.6,
  alert_on_critical_load BOOLEAN DEFAULT true,
  auto_staffing_suggestions BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### ops_alerts

Operational alerts and notifications.

```sql
CREATE TABLE ops_alerts (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT REFERENCES stores(id),
  alert_type TEXT NOT NULL,
  severity TEXT NOT NULL,  -- 'info', 'warning', 'critical'
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## V5 API Endpoints

### Dynamic Pricing

| RPC | Description | Parameters |
|-----|-------------|------------|
| `get_dynamic_pricing` | Get all pricing suggestions | store_id, item_id (optional) |
| `calculate_dynamic_price` | Calculate price for single item | item_id, store_id |
| `update_pricing_rule` | Update pricing rule | store_id, item_id, base_price, min_price, max_price |
| `approve_pricing_change` | Approve a suggested price | store_id, item_id, approved_price, approved_by |

### Kitchen Load

| RPC | Description | Parameters |
|-----|-------------|------------|
| `get_kitchen_load` | Get current load prediction | store_id, window_minutes |
| `predict_wait_time` | Estimate wait for cart | store_id, item_ids (optional) |
| `predict_kitchen_load` | Generate new prediction | store_id, window_minutes |

### Staffing

| RPC | Description | Parameters |
|-----|-------------|------------|
| `get_staffing_recommendations` | Get staffing suggestions | store_id, date |
| `generate_staffing_recommendations` | Generate new recommendations | store_id, date |

### Profitability

| RPC | Description | Parameters |
|-----|-------------|------------|
| `get_menu_profitability` | Get profitability analysis | store_id, days |
| `calculate_menu_profitability` | Run analysis | store_id, days |

### Operations

| RPC | Description | Parameters |
|-----|-------------|------------|
| `get_operational_health` | Get unified health score | store_id |
| `get_ops_alerts` | Get active alerts | store_id, include_resolved |
| `run_autonomous_cycle` | Run full autonomous cycle | store_id, dry_run |

## Usage Examples

### Frontend Integration

```typescript
import {
  useAutonomousOps,
  useDynamicPricing,
  useWaitTime,
  useMenuProfitability,
} from '@/lib/autonomous-ops';

// Dashboard component
function OperationsDashboard({ storeId }) {
  const { health, alerts, kitchenLoad, refresh } = useAutonomousOps(storeId);

  return (
    <div>
      <HealthScore score={health?.overall_score} grade={health?.grade} />
      <KitchenLoadIndicator load={kitchenLoad} />
      <AlertsList alerts={alerts?.all} />
    </div>
  );
}

// Customer wait time display
function WaitTimeDisplay({ storeId, cartItems }) {
  const { waitTime, loading } = useWaitTime(storeId, cartItems.map(i => i.id));

  if (loading) return <Spinner />;

  return (
    <div>
      <span>Estimated wait: {waitTime?.estimated_minutes} min</span>
      <span>({waitTime?.range_min}-{waitTime?.range_max} min)</span>
    </div>
  );
}
```

### Direct RPC Calls

```typescript
// Get dynamic pricing
const { data } = await supabase.rpc('rpc_v5_dispatch', {
  p_name: 'get_dynamic_pricing',
  p_payload: { store_id: 1 },
});

// Calculate specific item price
const { data } = await supabase.rpc('calculate_dynamic_price', {
  p_item_id: 123,
  p_store_id: 1,
});

// Predict kitchen load
const { data } = await supabase.rpc('predict_kitchen_load', {
  p_store_id: 1,
  p_window_minutes: 30,
});

// Run autonomous cycle (dry run)
const { data } = await supabase.rpc('rpc_v5_dispatch', {
  p_name: 'run_autonomous_cycle',
  p_payload: { store_id: 1, dry_run: true },
});
```

### Edge Function

```typescript
const response = await fetch('/functions/v1/autonomous-ops-engine', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    action: 'get_operational_health',
    payload: { store_id: 1 },
  }),
});

const { success, data } = await response.json();
```

## Dynamic Pricing Algorithm

### Price Calculation Formula

```sql
suggested_price = base_price × combined_multiplier

combined_multiplier = (
  demand_score × 0.4 +
  inventory_factor × 0.3 +
  time_factor × 0.3
)

-- Capped to safety bounds
final_price = CLAMP(suggested_price, base_price × 0.85, base_price × 1.15)
```

### Factor Calculation

**Demand Score** (0.8 - 1.2):
- Based on recent sales velocity vs. historical average
- Higher demand = higher multiplier

**Inventory Factor** (0.9 - 1.1):
- Based on current stock vs. reorder point
- Low stock = higher multiplier
- Overstock = lower multiplier

**Time Factor** (0.95 - 1.05):
- Based on day of week and hour
- Peak hours = slight increase
- Off-peak = slight decrease

## Kitchen Load Prediction

### Load Levels

| Level | Capacity | Action |
|-------|----------|--------|
| Low | 0-40% | Normal operations |
| Moderate | 40-65% | Monitor |
| High | 65-85% | Consider hiding slow items |
| Critical | 85%+ | Auto-hide slow items, alert manager |

### Prediction Factors

1. **Pending orders**: Currently in queue
2. **Historical patterns**: Same day/hour historical average
3. **Recent trend**: Last 30 minutes order velocity
4. **Prep times**: Average prep time per item type

## Menu Matrix Categories

| Category | Margin | Volume | Action |
|----------|--------|--------|--------|
| Stars | High (≥60%) | High (≥10/day) | Feature prominently |
| Puzzles | High (≥60%) | Low (<10/day) | Promote more |
| Plowhorses | Low (<60%) | High (≥10/day) | Consider price increase |
| Dogs | Low (<60%) | Low (<10/day) | Consider removal |

## Operational Health Score

The unified health score combines:

| Component | Weight | Source |
|-----------|--------|--------|
| Kitchen Score | 25% | Load predictions, wait times |
| Inventory Score | 25% | Stock levels, alerts |
| Staff Score | 25% | Staffing vs. recommended |
| Pricing Score | 25% | Price optimization status |

### Grade Scale

| Score | Grade | Status |
|-------|-------|--------|
| 90-100 | A | Healthy |
| 80-89 | B | Healthy |
| 70-79 | C | Attention |
| 60-69 | D | Attention |
| 0-59 | F | Critical |

## iOS Integration

### Business iOS App

```swift
// Get kitchen load indicator
let response = try await supabase.rpc(
    "rpc_v5_dispatch",
    params: [
        "p_name": "get_kitchen_load",
        "p_payload": ["store_id": storeId, "window_minutes": 30]
    ]
)

// Display pricing alerts
let alerts = try await supabase.rpc(
    "rpc_v5_dispatch",
    params: [
        "p_name": "get_ops_alerts",
        "p_payload": ["store_id": storeId]
    ]
)
```

### Customer iOS App

```swift
// Show wait time to customer
let waitTime = try await supabase.rpc(
    "rpc_v5_dispatch",
    params: [
        "p_name": "predict_wait_time",
        "p_payload": ["store_id": storeId, "item_ids": cartItemIds]
    ]
)

// Display dynamic price badge (if enabled)
let pricing = try await supabase.rpc(
    "rpc_v5_dispatch",
    params: [
        "p_name": "get_dynamic_pricing",
        "p_payload": ["store_id": storeId, "item_id": itemId]
    ]
)
```

## Materialized Views

### mv_kitchen_load_60min

Pre-computed 60-minute kitchen load data.

```sql
CREATE MATERIALIZED VIEW mv_kitchen_load_60min AS
SELECT
  o.store_id,
  COUNT(*) AS total_pending_orders,
  SUM(COALESCE(mi.prep_time_minutes, 5)) AS total_prep_time_minutes,
  MAX(o.created_at) AS latest_order_time
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
LEFT JOIN menu_items mi ON oi.menu_item_id = mi.id
WHERE o.status IN ('pending', 'preparing')
  AND o.created_at >= NOW() - INTERVAL '60 minutes'
GROUP BY o.store_id;
```

### mv_item_profitability_trends

Pre-computed profitability trends.

```sql
CREATE MATERIALIZED VIEW mv_item_profitability_trends AS
SELECT
  store_id,
  item_id,
  AVG(margin_percentage) AS avg_margin,
  AVG(total_quantity) AS avg_daily_quantity,
  -- Trend calculation
  CASE
    WHEN recent_avg > historical_avg * 1.1 THEN 'rising'
    WHEN recent_avg < historical_avg * 0.9 THEN 'falling'
    ELSE 'stable'
  END AS trend
FROM menu_profitability
WHERE analysis_date >= CURRENT_DATE - 30
GROUP BY store_id, item_id;
```

## Triggers

### Auto-Hide Slow Items

```sql
CREATE TRIGGER trg_auto_hide_slow_items
  AFTER INSERT ON kitchen_load_predictions
  FOR EACH ROW
  WHEN (NEW.load_level = 'critical')
  EXECUTE FUNCTION auto_hide_slow_items();
```

### Log Pricing Changes

```sql
CREATE TRIGGER trg_log_pricing_changes
  AFTER UPDATE ON dynamic_pricing_rules
  FOR EACH ROW
  EXECUTE FUNCTION log_pricing_change();
```

### Generate Profitability Alerts

```sql
CREATE TRIGGER trg_generate_profitability_alerts
  AFTER INSERT ON menu_profitability
  FOR EACH ROW
  WHEN (NEW.margin_percentage < 30)
  EXECUTE FUNCTION generate_profitability_alert();
```

## Best Practices

### 1. Start with Dry Run

Always run `run_autonomous_cycle` with `dry_run: true` first to preview actions.

### 2. Monitor Confidence Scores

Only trust automated actions with confidence ≥ 60%. Lower confidence should require manual review.

### 3. Review Pricing Daily

Check dynamic pricing suggestions daily and adjust bounds based on actual results.

### 4. Act on Alerts

Critical alerts require immediate attention. Set up notification channels for ops_alerts.

### 5. Track Profitability Trends

Review menu profitability weekly. Act on "dogs" (remove or reprice) and "puzzles" (promote).

## Troubleshooting

### No Predictions Generated

1. Check if historical order data exists
2. Verify materialized views are populated:
   ```sql
   SELECT COUNT(*) FROM mv_kitchen_load_60min;
   ```
3. Manually refresh views:
   ```sql
   REFRESH MATERIALIZED VIEW CONCURRENTLY mv_kitchen_load_60min;
   ```

### Pricing Not Updating

1. Verify `dynamic_pricing_enabled` is true in store settings
2. Check pricing rules exist for items
3. Ensure confidence threshold is met

### Staffing Recommendations Missing

1. Verify sufficient historical order data
2. Check `auto_staffing_suggestions` is enabled
3. Run `generate_staffing_recommendations` manually

### Low Confidence Scores

1. Collect more historical data (30+ days recommended)
2. Exclude anomaly days from calculations
3. Adjust seasonal multipliers if patterns don't match

## Migration

Run migration 068 to set up autonomous operations infrastructure:

```bash
# Via Supabase CLI
supabase db push

# Or via SQL Editor
# Run supabase/migrations/068_autonomous_ops_core.sql
```

## Environment Variables

```env
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-anon-key
```
