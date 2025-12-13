# Inventory Forecasting System

## Overview

Cameron's Connect inventory forecasting system uses historical order data and AI predictions to help store managers:

- Track real-time stock levels
- Predict future demand
- Get automatic low-stock alerts
- Receive restock recommendations
- Prevent stockouts

## Database Schema

### inventory_levels

Tracks current stock for each menu item per store.

```sql
CREATE TABLE inventory_levels (
  store_id BIGINT,
  item_id BIGINT,
  ingredient_name TEXT,
  current_stock INTEGER DEFAULT 0,
  minimum_stock INTEGER DEFAULT 10,
  maximum_stock INTEGER DEFAULT 100,
  unit_type TEXT DEFAULT 'units',
  cost_per_unit DECIMAL(10, 2),
  supplier_name TEXT,
  reorder_point INTEGER DEFAULT 15,
  auto_reorder BOOLEAN DEFAULT false,
  last_restock_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (store_id, item_id)
);
```

### inventory_alerts

Automatic alerts generated when stock levels are concerning.

```sql
CREATE TABLE inventory_alerts (
  id BIGSERIAL PRIMARY KEY,
  store_id BIGINT,
  item_id BIGINT,
  alert_type TEXT,  -- 'low_stock', 'out_of_stock', 'expiring_soon', 'overstock'
  current_level INTEGER,
  threshold_level INTEGER,
  severity TEXT,    -- 'info', 'warning', 'critical'
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### demand_forecast

AI-generated demand predictions.

```sql
CREATE TABLE demand_forecast (
  store_id BIGINT,
  item_id BIGINT,
  forecast_date DATE,
  predicted_quantity INTEGER,
  confidence FLOAT,
  actual_quantity INTEGER,
  model_version TEXT,
  PRIMARY KEY (store_id, item_id, forecast_date)
);
```

## Automatic Triggers

### 1. Order Inventory Deduction

When a customer places an order, inventory is automatically decreased:

```sql
-- Trigger: trg_decrease_inventory_on_order
AFTER INSERT ON order_items
→ Decreases current_stock for the ordered item
```

### 2. Low Stock Alert Generation

When inventory drops below threshold:

```sql
-- Trigger: trg_check_inventory_alert
AFTER UPDATE ON inventory_levels
→ Creates alert if current_stock <= minimum_stock
→ Auto-resolves alert if stock replenished
```

## Forecasting Algorithm

The forecasting system uses multiple data points:

### 1. Historical Sales Analysis (mv_item_sales_last_90_days)

```sql
-- Aggregates sales data by:
- Item
- Store
- Day of week
- Hour of day
- Revenue
```

### 2. Daily Demand Patterns (mv_daily_store_demand)

```sql
-- Calculates:
- Daily average sales
- Standard deviation
- Seasonal multiplier (recent vs historical)
- Weighted trend (recency-biased)
```

### 3. Hourly Patterns (mv_hourly_demand_patterns)

```sql
-- Identifies:
- Peak hours per item
- Day-of-week patterns
- Optimal staffing windows
```

### 4. Item Affinity (mv_item_affinity)

```sql
-- Finds:
- Items frequently purchased together
- Upsell opportunities
- Bundle suggestions
```

## API Endpoints

### Get Inventory Predictions

```typescript
// Via RPC
const { data } = await supabase.rpc('rpc_v4_dispatch', {
  p_name: 'predict_inventory_needs',
  p_payload: { store_id: 1, days_ahead: 7 }
});

// Returns:
[{
  item_id: 123,
  item_name: "BEC Sandwich",
  current_stock: 15,
  predicted_demand: 45,
  days_until_stockout: 2,
  recommended_reorder: 40,
  confidence: 0.85,
  priority: "high"
}]
```

### Get Top Sellers Predicted

```typescript
const { data } = await supabase.rpc('rpc_v4_dispatch', {
  p_name: 'get_top_sellers_predicted',
  p_payload: { store_id: 1, days_ahead: 7, limit: 10 }
});

// Returns:
[{
  item_id: 123,
  item_name: "Turkey Club",
  category: "Sandwiches",
  predicted_quantity: 156,
  predicted_revenue: 1248.00,
  confidence: 0.91,
  trend: "rising"
}]
```

### Get Inventory Alerts

```typescript
const { data } = await supabase.rpc('rpc_v4_dispatch', {
  p_name: 'get_inventory_alerts',
  p_payload: { store_id: 1 }
});

// Returns:
[{
  id: 1,
  item_id: 45,
  item_name: "Eggs",
  alert_type: "low_stock",
  current_level: 12,
  threshold_level: 20,
  severity: "warning",
  created_at: "2024-01-15T10:30:00Z"
}]
```

### Update Inventory

```typescript
// Via library
import { updateStock } from '@/lib/inventory';

await updateStock({
  item_id: 123,
  store_id: 1,
  quantity: 50,
  type: 'add'  // or 'remove', 'set'
});
```

## Frontend Usage

### Using the Inventory Hook

```typescript
import { useInventory } from '@/lib/inventory';

function InventoryDashboard({ storeId }) {
  const inventory = useInventory(storeId);

  // Get all inventory
  const items = await inventory.getInventory();

  // Get low stock items only
  const lowStock = await inventory.getLowStock();

  // Get alerts
  const alerts = await inventory.getAlerts();

  // Update stock
  await inventory.updateStock(itemId, 50, 'add');

  // Resolve an alert
  await inventory.resolveAlert(alertId, 'Restocked from supplier');

  // Get AI recommendations
  const recommendations = await inventory.getRecommendations();

  // Subscribe to real-time alerts
  const unsubscribe = inventory.subscribeAlerts((alert) => {
    console.log('New alert:', alert);
  });
}
```

### Real-time Updates

```typescript
import { subscribeToInventoryChanges } from '@/lib/inventory';

// Subscribe to inventory changes
const unsubscribe = subscribeToInventoryChanges(storeId, (item) => {
  console.log('Inventory updated:', item.item_name, item.current_stock);
});

// Cleanup
onUnmount(() => unsubscribe());
```

## Refreshing Forecasts

Materialized views should be refreshed regularly:

```sql
-- Manual refresh
SELECT refresh_ai_materialized_views();

-- Or via scheduled job (pg_cron)
SELECT cron.schedule(
  'refresh-ai-views',
  '0 * * * *',  -- Every hour
  'SELECT refresh_ai_materialized_views()'
);
```

## Priority Calculation

Items are prioritized based on:

| Priority | Condition |
|----------|-----------|
| **Critical** | current_stock <= minimum_stock |
| **High** | current_stock <= reorder_point |
| **Medium** | current_stock <= minimum_stock * 2 |
| **Low** | All others |

## Best Practices

### 1. Initial Setup

```sql
-- Populate initial inventory for a store
INSERT INTO inventory_levels (store_id, item_id, current_stock, minimum_stock)
SELECT
  1 as store_id,
  id as item_id,
  50 as current_stock,
  10 as minimum_stock
FROM menu_items
WHERE is_available = true;
```

### 2. Regular Maintenance

- Refresh materialized views hourly
- Review alerts daily
- Adjust minimum_stock based on actual usage
- Update reorder_point based on supplier lead times

### 3. Supplier Integration

```typescript
// When receiving a shipment
await updateStock({
  item_id: itemId,
  store_id: storeId,
  quantity: receivedQuantity,
  type: 'add',
  reason: 'Supplier shipment #12345'
});
```

### 4. Waste Tracking

```typescript
// When discarding expired items
await updateStock({
  item_id: itemId,
  store_id: storeId,
  quantity: wastedQuantity,
  type: 'remove',
  reason: 'Expired items disposed'
});
```

## Dashboard Integration

The AI Insights dashboard (`src/components/dashboard/AIInsights.tsx`) displays:

1. **Quick Stats**: Today's forecast, predicted orders, peak hours, alerts count
2. **Forecasting Tab**: 14-day revenue forecast, hourly demand chart
3. **Insights Tab**: AI-generated recommendations and alerts
4. **Demand Tab**: Item-level demand predictions with trends
5. **Prep List Tab**: AI-generated preparation recommendations

## Troubleshooting

### No Forecasts Generated

1. Check if historical order data exists
2. Verify materialized views are populated:
   ```sql
   SELECT COUNT(*) FROM mv_item_sales_last_90_days;
   ```
3. Manually refresh views:
   ```sql
   SELECT refresh_ai_materialized_views();
   ```

### Alerts Not Generating

1. Check trigger exists:
   ```sql
   SELECT * FROM pg_trigger WHERE tgname = 'trg_check_inventory_alert';
   ```
2. Verify inventory thresholds are set correctly
3. Check RLS policies allow alert insertion

### Inaccurate Predictions

1. Ensure sufficient historical data (30+ days recommended)
2. Check for anomalies in order data
3. Adjust seasonal_multiplier manually if needed
4. Review and exclude outlier days
