# Cameron's Connect API Contract

**Version**: 1.0.0
**Last Updated**: 2025-12-02
**Base URL**: `https://jwcuebbhkwwilqfblecq.supabase.co`

---

## Overview

This document defines the API contract for Cameron's Connect, a multi-location food ordering platform. The API is built on Supabase (PostgreSQL + PostgREST) with Row Level Security (RLS) policies enforcing access control.

## Authentication

### Headers

All authenticated requests require:

```
apikey: <SUPABASE_ANON_KEY>
Authorization: Bearer <JWT_TOKEN>
```

For anonymous/guest requests, only the `apikey` header is required.

### Auth Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/v1/signup` | POST | Create new user account |
| `/auth/v1/token?grant_type=password` | POST | Sign in with email/password |
| `/auth/v1/logout` | POST | Sign out current session |
| `/auth/v1/user` | GET | Get current user |

---

## REST API Endpoints

Base path: `/rest/v1/`

### Stores

#### List Stores
```
GET /rest/v1/stores?select=*
```

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "name": "Highland Mills Snack Shop Inc",
    "address": "634 NY-32",
    "city": "Highland Mills",
    "state": "NY",
    "zip": "10930",
    "phone": "(845) 928-2400",
    "hours": "Open 24 Hours",
    "lat": 41.3445,
    "lng": -74.1282,
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

**Access**: Public (anonymous)

#### Get Store by ID
```
GET /rest/v1/stores?id=eq.1&select=*
```

**Access**: Public (anonymous)

---

### Menu Items

#### List Menu Items
```
GET /rest/v1/menu_items?select=*,menu_item_customizations(*)
```

**Query Parameters**:
- `category_id=eq.<id>` - Filter by category
- `is_available=eq.true` - Only available items
- `is_featured=eq.true` - Only featured items

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "name": "Bacon Egg & Cheese",
    "description": "Classic breakfast sandwich",
    "price": 7.99,
    "category_id": 1,
    "image_url": "https://jwcuebbhkwwilqfblecq.supabase.co/storage/v1/object/public/menu-images/breakfast/bacon-egg-cheese.jpg",
    "is_available": true,
    "is_featured": true,
    "allergens": ["eggs", "dairy", "gluten"],
    "created_at": "2024-01-01T00:00:00Z",
    "menu_item_customizations": [
      {
        "id": 1,
        "name": "Extra Bacon",
        "price": 1.50,
        "supports_portions": true,
        "portion_pricing": {"none": 0, "light": 0.75, "regular": 1.50, "extra": 2.25},
        "default_portion": "regular",
        "category": "extras"
      }
    ]
  }
]
```

**Access**: Public (anonymous)

#### Get Menu Item by ID
```
GET /rest/v1/menu_items?id=eq.1&select=*,menu_item_customizations(*)
```

**Access**: Public (anonymous)

---

### Menu Categories

#### List Categories
```
GET /rest/v1/menu_categories?select=*&order=display_order
```

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "name": "Breakfast",
    "description": "Start your day right",
    "display_order": 1,
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

**Access**: Public (anonymous)

---

### Orders

#### Create Order (Guest Checkout)
```
POST /rest/v1/orders
Content-Type: application/json

{
  "store_id": 1,
  "customer_name": "John Doe",
  "customer_email": "john@example.com",
  "customer_phone": "555-0100",
  "subtotal": 15.98,
  "tax": 1.28,
  "total": 17.26,
  "status": "pending",
  "payment_method": "card",
  "notes": "Extra napkins please"
}
```

**Response** (201 Created):
```json
{
  "id": 123,
  "store_id": 1,
  "customer_name": "John Doe",
  "status": "pending",
  "total": 17.26,
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Access**: Public (anonymous) - Guest checkout enabled

#### Create Order (Authenticated)
```
POST /rest/v1/orders
Authorization: Bearer <JWT_TOKEN>

{
  "store_id": 1,
  "customer_id": "<user_uuid>",
  "subtotal": 15.98,
  "tax": 1.28,
  "total": 17.26,
  "status": "pending"
}
```

**Access**: Authenticated users

#### Get Order by ID
```
GET /rest/v1/orders?id=eq.123&select=*,order_items(*)
```

**Access**:
- Own orders (authenticated)
- Guest orders by email match
- Staff: assigned store orders
- Admin/Super Admin: all orders

#### Update Order Status
```
PATCH /rest/v1/orders?id=eq.123
Content-Type: application/json

{
  "status": "preparing"
}
```

**Valid Status Values**:
- `pending` - Order received
- `confirmed` - Order confirmed by staff
- `preparing` - Being prepared
- `ready` - Ready for pickup
- `completed` - Order fulfilled
- `cancelled` - Order cancelled

**Access**:
- Staff/Manager/Admin: assigned store
- Super Admin: all stores

#### List Store Orders (Staff)
```
GET /rest/v1/orders?store_id=eq.1&select=*,order_items(*)&order=created_at.desc
```

**Access**: Staff with `orders` permission, Manager, Admin, Super Admin

---

### Order Items

#### Create Order Items
```
POST /rest/v1/order_items
Content-Type: application/json

[
  {
    "order_id": 123,
    "menu_item_id": 1,
    "quantity": 2,
    "customizations": ["Extra Bacon", "No Onions"],
    "notes": "Well done"
  }
]
```

**Access**: Same as order creation

---

### User Profiles (Business Users)

#### Get Current Profile
```
GET /rest/v1/user_profiles?user_id=eq.<user_uuid>&select=*
```

**Response** (200 OK):
```json
{
  "id": 1,
  "user_id": "uuid",
  "email": "staff@camerons.com",
  "full_name": "Jane Staff",
  "role": "manager",
  "store_id": 1,
  "permissions": ["orders", "menu", "analytics"],
  "created_at": "2024-01-01T00:00:00Z"
}
```

**Access**: Own profile only (except Admin/Super Admin)

#### Update Profile
```
PATCH /rest/v1/user_profiles?id=eq.1

{
  "full_name": "Jane Manager"
}
```

**Access**: Own profile, or Admin for their store's users

---

### Customers

#### Get Customer Profile
```
GET /rest/v1/customers?user_id=eq.<user_uuid>&select=*
```

**Response** (200 OK):
```json
{
  "id": 1,
  "user_id": "uuid",
  "email": "customer@example.com",
  "full_name": "John Customer",
  "phone": "555-0100",
  "rewards_points": 150,
  "rewards_tier": "silver",
  "created_at": "2024-01-01T00:00:00Z"
}
```

**Access**: Own profile only

---

## RPC Functions

Base path: `/rest/v1/rpc/`

### Analytics (Secure)

#### Get Store Metrics
```
POST /rest/v1/rpc/get_store_metrics_secure
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>

{
  "p_store_id": 1,
  "p_date_range": "today"
}
```

**Date Range Options**: `today`, `week`, `month`, `year`

**Response** (200 OK):
```json
{
  "total_revenue": 1250.50,
  "order_count": 45,
  "avg_order_value": 27.79,
  "top_items": [
    {"name": "Bacon Egg & Cheese", "count": 12}
  ]
}
```

**Access**: Manager, Admin (own store), Super Admin (all stores)

#### Get Revenue Trends
```
POST /rest/v1/rpc/get_revenue_trends_secure
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>

{
  "p_store_id": 1,
  "p_days": 30
}
```

**Access**: Manager, Admin (own store), Super Admin (all stores)

### Order Management

#### Get Active Orders
```
POST /rest/v1/rpc/get_active_orders
Content-Type: application/json

{
  "p_store_id": 1
}
```

**Access**: Staff with `orders` permission, Manager, Admin, Super Admin

---

## Real-time Subscriptions

### Subscribe to Order Changes

```javascript
const channel = supabase
  .channel('orders-store-1')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'orders',
    filter: 'store_id=eq.1'
  }, (payload) => {
    console.log('Order change:', payload);
  })
  .subscribe();
```

**Events**: `INSERT`, `UPDATE`, `DELETE`

**Access**: Same RLS policies apply to real-time subscriptions

---

## Error Responses

### Standard Error Format
```json
{
  "code": "PGRST116",
  "details": null,
  "hint": null,
  "message": "The result contains 0 rows"
}
```

### Common Error Codes

| HTTP Status | Code | Description |
|-------------|------|-------------|
| 400 | `PGRST102` | Invalid request syntax |
| 401 | `PGRST301` | JWT expired or invalid |
| 403 | `PGRST301` | RLS policy violation |
| 404 | `PGRST116` | Resource not found |
| 409 | `23505` | Unique constraint violation |
| 500 | `PGRST000` | Server error |

---

## Rate Limits

| Tier | Requests/minute | Realtime connections |
|------|-----------------|---------------------|
| Anonymous | 100 | 10 |
| Authenticated | 500 | 50 |
| Service Role | Unlimited | 100 |

---

## Versioning

This API follows semantic versioning. Breaking changes will increment the major version.

| Version | Status | Notes |
|---------|--------|-------|
| 1.0.0 | Current | Initial release |

### Deprecation Policy

- Deprecated endpoints will be announced 90 days before removal
- Deprecated features will include `X-Deprecated` header in responses
- Migration guides will be provided for breaking changes

---

## SDKs & Examples

### JavaScript/TypeScript (Supabase Client)

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

// Fetch menu items
const { data: menuItems, error } = await supabase
  .from('menu_items')
  .select('*, menu_item_customizations(*)')
  .eq('is_available', true);

// Create order
const { data: order, error } = await supabase
  .from('orders')
  .insert({
    store_id: 1,
    customer_name: 'John Doe',
    total: 17.26,
    status: 'pending'
  })
  .select()
  .single();
```

### Swift (iOS)

```swift
import Supabase

let client = SupabaseClient(
    supabaseURL: URL(string: "https://jwcuebbhkwwilqfblecq.supabase.co")!,
    supabaseKey: "your-anon-key"
)

// Fetch menu items
let menuItems: [MenuItem] = try await client
    .from("menu_items")
    .select("*, menu_item_customizations(*)")
    .eq("is_available", true)
    .execute()
    .value
```

---

## Changelog

### v1.0.0 (2025-12-02)
- Initial API contract documentation
- Guest checkout support
- Portion-based customizations
- Real-time order subscriptions
- Secure analytics RPC functions
