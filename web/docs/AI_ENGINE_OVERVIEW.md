# AI Engine Overview

## Introduction

Cameron's Connect AI Engine provides intelligent features for menu personalization, demand forecasting, and inventory management. Built on Supabase with pgvector for semantic search and custom RPC functions for efficient data processing.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Client Apps                             │
│   (Web Dashboard, Customer App, Business iOS App)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    API Gateway                               │
│   (Multi-region routing, Version negotiation)               │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  V4 Dispatcher  │  │  AI Engine      │  │  Vector Store   │
│  (AI RPCs)      │  │  Edge Function  │  │  (pgvector)     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    PostgreSQL Database                       │
│   - customer_taste_profile  - menu_item_embedding           │
│   - inventory_levels        - demand_forecast               │
│   - ai_recommendations_log  - inventory_alerts              │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Customer Taste Profiles

Store customer preferences as vector embeddings for personalized recommendations.

```typescript
interface CustomerTasteProfile {
  customer_id: UUID;
  embedding: VECTOR(1536);      // OpenAI embedding
  favorite_categories: TEXT[];  // Preferred food categories
  dietary_preferences: JSONB;   // Allergies, restrictions
  order_history_summary: JSONB; // Aggregated order patterns
}
```

### 2. Menu Item Embeddings

Semantic representations of menu items for similarity search.

```typescript
interface MenuItemEmbedding {
  item_id: BIGINT;
  embedding: VECTOR(1536);      // Semantic embedding
  category: TEXT;               // Category name
  tags: TEXT[];                 // Search tags
  semantic_description: TEXT;   // Combined description
}
```

### 3. Inventory Intelligence

Real-time stock tracking with predictive alerts.

```typescript
interface InventoryLevels {
  store_id: BIGINT;
  item_id: BIGINT;
  current_stock: INTEGER;
  minimum_stock: INTEGER;
  reorder_point: INTEGER;
  auto_reorder: BOOLEAN;
}
```

### 4. Demand Forecasting

AI-powered predictions for future demand.

```typescript
interface DemandForecast {
  store_id: BIGINT;
  item_id: BIGINT;
  forecast_date: DATE;
  predicted_quantity: INTEGER;
  confidence: FLOAT;           // 0-1 confidence score
  prediction_factors: JSONB;   // Contributing factors
}
```

## V4 API Endpoints

### Menu & Recommendations

| RPC | Description | Parameters |
|-----|-------------|------------|
| `get_smart_menu` | Personalized menu | customer_id, store_id, limit |
| `get_personalized_recommendations` | AI recommendations | customer_id, store_id, limit |
| `get_similar_items` | Similar items | item_id, limit, threshold |
| `get_substitute_items` | Out-of-stock alternatives | item_id, store_id, limit |

### Inventory Intelligence

| RPC | Description | Parameters |
|-----|-------------|------------|
| `predict_inventory_needs` | Stock predictions | store_id, days_ahead |
| `get_inventory_alerts` | Low stock alerts | store_id |
| `update_inventory` | Update stock level | store_id, item_id, current_stock |

### Demand Forecasting

| RPC | Description | Parameters |
|-----|-------------|------------|
| `get_demand_forecast` | Future demand | store_id, days_ahead |
| `get_top_sellers_predicted` | Top items prediction | store_id, days_ahead, limit |
| `explain_menu_performance` | Performance analysis | store_id |

## Usage Examples

### Frontend Integration

```typescript
import { getSmartMenu, getPersonalizedRecommendations } from '@/lib/ai';

// Get personalized menu
const { items, personalized } = await getSmartMenu(customerId, storeId, 20);

// Get recommendations
const recommendations = await getPersonalizedRecommendations(customerId, storeId, 10);
```

### Direct RPC Call

```typescript
const { data } = await supabase.rpc('rpc_v4_dispatch', {
  p_name: 'get_smart_menu',
  p_payload: { customer_id: userId, store_id: 1, limit: 20 }
});
```

### Edge Function

```typescript
const response = await fetch('/functions/v1/ai-engine', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    action: 'get_recommendations',
    payload: { customer_id: userId, store_id: 1 }
  })
});
```

## Embedding Generation

Embeddings are generated using OpenAI's `text-embedding-3-large` model:

```typescript
// Generate embedding for menu item
const embeddingText = `${item.name}. ${item.description}. Category: ${category}`;
const embedding = await generateEmbedding(embeddingText);

// Store in database
await supabase.from('menu_item_embedding').upsert({
  item_id: itemId,
  embedding: `[${embedding.join(',')}]`,
  category: categoryName
});
```

## Materialized Views

For efficient demand forecasting:

| View | Description | Refresh |
|------|-------------|---------|
| `mv_item_sales_last_90_days` | 90-day sales data | Hourly |
| `mv_daily_store_demand` | Daily demand patterns | Hourly |
| `mv_hourly_demand_patterns` | Hourly patterns | Hourly |
| `mv_item_affinity` | Item co-occurrences | Hourly |

Refresh views:
```sql
SELECT refresh_ai_materialized_views();
```

## Auto-Update Triggers

### Order → Inventory

When an order item is created, inventory automatically decreases:

```sql
TRIGGER: trg_decrease_inventory_on_order
AFTER INSERT ON order_items
→ UPDATE inventory_levels SET current_stock = current_stock - quantity
```

### Low Stock → Alert

When stock drops below minimum:

```sql
TRIGGER: trg_check_inventory_alert
AFTER UPDATE ON inventory_levels
→ INSERT INTO inventory_alerts (if current_stock <= minimum_stock)
```

## Performance Considerations

1. **Vector Indexes**: IVFFlat indexes for fast similarity search
2. **Materialized Views**: Pre-computed aggregations for forecasting
3. **Caching**: 5-minute TTL cache in Edge Function
4. **Batch Operations**: Use batch updates for inventory changes

## Security

- RLS policies restrict access based on user role
- Customer data only visible to the customer
- Store data restricted to assigned staff
- Super admins have full access

## Migration

Run migration 067 to set up AI infrastructure:

```bash
# Via Supabase CLI
supabase db push

# Or via SQL Editor
# Run supabase/migrations/067_ai_infrastructure.sql
```

## Environment Variables

```env
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-anon-key
OPENAI_API_KEY=your-openai-key  # For embedding generation
```
