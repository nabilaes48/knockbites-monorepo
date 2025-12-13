# Cameron's Connect - Architecture Overview

## High-Level System Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CLIENTS                                        │
├──────────────────┬──────────────────┬──────────────────────────────────┤
│   Web App        │  iOS Customer    │  iOS Business                    │
│   (React/Vite)   │  App (Swift)     │  App (Swift)                     │
│   Port 8080      │                  │                                  │
└────────┬─────────┴────────┬─────────┴────────────┬─────────────────────┘
         │                  │                      │
         │    HTTPS/WSS     │                      │
         ▼                  ▼                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         SUPABASE                                         │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │    Auth     │  │  Database   │  │   Storage   │  │  Realtime   │    │
│  │  (GoTrue)   │  │ (PostgreSQL)│  │   (S3)      │  │  (Phoenix)  │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     Edge Functions (Deno)                        │   │
│  │  • send-verification-email                                       │   │
│  │  • send-order-notification                                       │   │
│  │  • webhook-stripe (stub)                                         │   │
│  │  • webhook-n8n (stub)                                            │   │
│  │  • scheduled-cleanup                                             │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
         │                  │                      │
         ▼                  ▼                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     EXTERNAL SERVICES (Future)                           │
├──────────────────┬──────────────────┬──────────────────────────────────┤
│   Resend/        │   Stripe         │   n8n                            │
│   SendGrid       │   (Payments)     │   (Automation)                   │
│   (Email)        │                  │                                  │
└──────────────────┴──────────────────┴──────────────────────────────────┘
```

---

## Data Model Overview

### Core Ordering

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   stores    │       │   orders    │       │ order_items │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ id (PK)     │◄──────│ store_id    │       │ order_id    │───►orders
│ name        │       │ id (PK)     │◄──────│ menu_item_id│───►menu_items
│ address     │       │ customer_id │       │ item_name   │
│ city, state │       │ status      │       │ quantity    │
│ latitude    │       │ total       │       │ subtotal    │
│ longitude   │       │ order_number│       │customizations│
└─────────────┘       └─────────────┘       └─────────────┘
                             │
                             ▼
                    ┌─────────────────────┐
                    │ order_status_history│
                    ├─────────────────────┤
                    │ order_id            │
                    │ previous_status     │
                    │ new_status          │
                    │ changed_by          │
                    └─────────────────────┘
```

### Menu/Catalog

```
┌───────────────────┐       ┌─────────────┐       ┌───────────────────────┐
│ menu_categories   │       │ menu_items  │       │menu_item_customizations│
├───────────────────┤       ├─────────────┤       ├───────────────────────┤
│ id (PK)           │◄──────│ category_id │       │ menu_item_id          │───►menu_items
│ name              │       │ id (PK)     │◄──────│ name                  │
│ display_order     │       │ name        │       │ supports_portions     │
│ is_active         │       │ price       │       │ portion_pricing (JSON)│
└───────────────────┘       │ image_url   │       │ category              │
                            │ is_available│       └───────────────────────┘
                            └─────────────┘
                                                  ┌───────────────────────┐
                                                  │ ingredient_templates  │
                                                  ├───────────────────────┤
                                                  │ id (PK)               │
                                                  │ name                  │
                                                  │ category              │
                                                  │ portion_pricing       │
                                                  └───────────────────────┘
```

### Customers vs Staff (Dual Profile System)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          auth.users                                      │
│                     (Supabase Auth table)                               │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
           ┌───────────────────┴───────────────────┐
           │                                       │
           ▼                                       ▼
┌─────────────────────┐               ┌─────────────────────┐
│     customers       │               │   user_profiles     │
├─────────────────────┤               ├─────────────────────┤
│ id (FK→auth.users)  │               │ id (FK→auth.users)  │
│ full_name           │               │ full_name           │
│ email               │               │ role                │
│ phone               │               │ store_id            │
│ avatar_url          │               │ assigned_stores[]   │
└─────────────────────┘               │ permissions (JSON)  │
     │                                │ is_system_admin     │
     │                                └─────────────────────┘
     ▼
┌─────────────────────┐
│  customer_rewards   │
├─────────────────────┤
│ customer_id         │
│ points              │
│ lifetime_points     │
│ tier                │
│ total_spent         │
└─────────────────────┘
```

### Organizations & Multi-Location

```
┌─────────────────────┐
│   organizations     │
├─────────────────────┤
│ id (PK)             │
│ name                │
│ slug                │
│ owner_id            │
│ subscription_tier   │
│ max_locations       │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐       ┌─────────────────────┐
│      regions        │       │       stores        │
├─────────────────────┤       ├─────────────────────┤
│ organization_id     │───────│ organization_id     │
│ name                │       │ region_id           │◄───┘
│ manager_id          │       │ store_code          │
└─────────────────────┘       │ performance_score   │
                              └─────────────────────┘
```

---

## Authentication & Authorization

### User Roles

| Role | Description | Access |
|------|-------------|--------|
| `customer` | End users who place orders | Own orders, rewards, favorites |
| `staff` | Store employees | Assigned store orders, menu view |
| `manager` | Store managers | Full store access, staff management |
| `admin` | Multi-store admin | Multiple store access, analytics |
| `super_admin` | System administrator | All stores, all features |

### Key Database Helper Functions

```sql
-- Get current user's role
get_current_user_role() → TEXT

-- Check if system admin
is_current_user_system_admin() → BOOLEAN

-- Get assigned stores array
get_current_user_assigned_stores() → INT[]

-- Get primary store ID
get_current_user_store_id() → INT

-- Check analytics access
can_access_analytics(store_id) → BOOLEAN
```

### RLS (Row Level Security) Enforcement

All tables have RLS enabled with policies that enforce:

1. **Customers**: Can only view/edit their own data
2. **Staff**: Can view their assigned store's data
3. **Managers**: Full access to their store, can manage staff
4. **Admins**: Multi-store access based on `assigned_stores[]`
5. **Super Admins**: Full access via `is_system_admin` flag

### Frontend Permission Checking

```typescript
// src/contexts/AuthContext.tsx
const {
  user,           // Supabase auth user
  profile,        // user_profiles row (if staff) or customers row
  isCustomer,     // Boolean - is this a customer?
  isStaff,        // Boolean - staff role
  isManager,      // Boolean - manager role
  isAdmin,        // Boolean - admin role
  isSuperAdmin,   // Boolean - super_admin role
  hasPermission   // (permission: string) => boolean
} = useAuth();

// Check specific permissions
if (hasPermission('analytics')) {
  // Show analytics tab
}
```

---

## Application Flows

### 1. Guest Checkout Flow

```
Customer                    Web/iOS App                 Supabase
    │                           │                           │
    │   Browse Menu             │                           │
    │──────────────────────────►│   SELECT menu_items       │
    │                           │──────────────────────────►│
    │   Menu Items              │                           │
    │◄──────────────────────────│◄──────────────────────────│
    │                           │                           │
    │   Add to Cart             │                           │
    │──────────────────────────►│   (Local state)           │
    │                           │                           │
    │   Checkout (no login)     │                           │
    │──────────────────────────►│   INSERT orders           │
    │                           │──────────────────────────►│
    │                           │   (RLS: anon can insert)  │
    │   Order Confirmation      │                           │
    │◄──────────────────────────│◄──────────────────────────│
    │                           │                           │
    │   Track Order             │   SELECT orders           │
    │──────────────────────────►│──────────────────────────►│
    │   Order Status            │   (RLS: anon can view)    │
    │◄──────────────────────────│◄──────────────────────────│
```

### 2. Authenticated Order + Rewards

```
Customer                    Web/iOS App                 Supabase
    │                           │                           │
    │   Sign In                 │                           │
    │──────────────────────────►│   auth.signIn()           │
    │                           │──────────────────────────►│
    │   Session + Profile       │   (trigger: customers)    │
    │◄──────────────────────────│◄──────────────────────────│
    │                           │                           │
    │   Place Order             │   INSERT orders           │
    │──────────────────────────►│   (customer_id = user.id) │
    │                           │──────────────────────────►│
    │                           │                           │
    │                           │   (trigger: rewards)      │
    │                           │   INSERT rewards_trans    │
    │                           │   UPDATE customer_rewards │
    │   Order + Points Earned   │                           │
    │◄──────────────────────────│◄──────────────────────────│
```

### 3. Staff Dashboard Access

```
Staff                       Dashboard                   Supabase
    │                           │                           │
    │   Sign In                 │                           │
    │──────────────────────────►│   auth.signIn()           │
    │                           │──────────────────────────►│
    │   Session                 │                           │
    │◄──────────────────────────│◄──────────────────────────│
    │                           │                           │
    │   Load Profile            │   SELECT user_profiles    │
    │                           │──────────────────────────►│
    │   Role + Permissions      │   (RLS: own profile)      │
    │◄──────────────────────────│◄──────────────────────────│
    │                           │                           │
    │   View Orders             │   SELECT orders           │
    │                           │   WHERE store_id = X      │
    │                           │──────────────────────────►│
    │   Store Orders            │   (RLS: staff store only) │
    │◄──────────────────────────│◄──────────────────────────│
    │                           │                           │
    │   Update Order Status     │   UPDATE orders           │
    │──────────────────────────►│──────────────────────────►│
    │                           │   (trigger: history)      │
    │   Updated + Realtime      │   Realtime broadcast      │
    │◄──────────────────────────│◄──────────────────────────│
```

### 4. Analytics Dashboard Flow

```
Admin                       Dashboard                   Supabase
    │                           │                           │
    │   Request Analytics       │                           │
    │──────────────────────────►│   RPC get_store_metrics   │
    │                           │   _secure(store_id)       │
    │                           │──────────────────────────►│
    │                           │   SECURITY DEFINER:       │
    │                           │   - Check can_access()    │
    │                           │   - Query orders          │
    │   Metrics Response        │   - Aggregate data        │
    │◄──────────────────────────│◄──────────────────────────│
    │                           │                           │
    │   Request Charts          │   RPC get_revenue_chart   │
    │──────────────────────────►│   _data_secure()          │
    │                           │──────────────────────────►│
    │   Chart Data              │                           │
    │◄──────────────────────────│◄──────────────────────────│
    │                           │                           │
    │   (Alternative)           │   SELECT mv_popular_items │
    │──────────────────────────►│──────────────────────────►│
    │   Materialized View Data  │   (Pre-aggregated)        │
    │◄──────────────────────────│◄──────────────────────────│
```

---

## Edge Functions

| Function | Trigger | Purpose |
|----------|---------|---------|
| `send-verification-email` | HTTP POST | Send email verification on signup |
| `send-order-notification` | HTTP POST | Email/SMS/Push on order status change |
| `webhook-stripe` | Stripe webhook | Handle payment events (stub) |
| `webhook-n8n` | n8n automation | Handle automation triggers (stub) |
| `scheduled-cleanup` | Cron | Clean up old sessions, expired data |

### Shared Utilities

```
supabase/functions/_shared/
├── auth.ts      - Supabase client creation, API key validation
├── cors.ts      - CORS headers and preflight handling
├── email.ts     - Email sending (Resend/SendGrid)
├── error.ts     - Error formatting
└── logger.ts    - Structured JSON logging
```

---

## Frontend Architecture

### Tech Stack

- **React 18** + TypeScript + Vite
- **shadcn/ui** (Radix UI primitives)
- **Tailwind CSS** with CSS variables
- **React Router v6** with lazy loading
- **Supabase JS Client** for all backend operations

### Directory Structure

```
src/
├── pages/              # Route components (lazy loaded)
├── components/
│   ├── dashboard/      # Staff dashboard components
│   ├── order/          # Customer order flow
│   ├── rewards/        # Rewards UI
│   └── ui/             # shadcn/ui components
├── contexts/
│   └── AuthContext.tsx # Auth state + permission helpers
├── hooks/
│   ├── useRealtimeOrders.ts  # Real-time order updates
│   ├── useAnalytics.ts       # Analytics data fetching
│   ├── useRewards.ts         # Customer rewards
│   └── usePermissions.ts     # Permission checking
├── data/
│   └── locations.ts    # 29 store locations
└── lib/
    ├── supabase.ts     # Supabase client config
    └── utils.ts        # Utility functions
```

### Key Hooks

```typescript
// Real-time orders (for dashboard)
const { orders, loading, updateOrderStatus } = useRealtimeOrders({
  storeId: 1,
  status: 'pending'
});

// Analytics (secure RPC calls)
const { metrics, chartData, insights, loading } = useAnalytics({
  storeId: 1,
  dateRange: 'today'
});

// Customer rewards
const { rewards, transactions, loading } = useRewards();
```

---

## Deployment

### Web App

- **Vercel** recommended (zero-config for Vite)
- Environment variables set in Vercel dashboard
- Automatic deployments on push to main

### Supabase

- **Edge Functions**: `supabase functions deploy`
- **Migrations**: Run via SQL Editor or `supabase db push`
- **Storage**: menu-images bucket is public

### iOS Apps

- Share same Supabase project
- Use `SUPABASE_URL` and `SUPABASE_ANON_KEY` in Config.plist
- Guest checkout works with anon key (no auth required)

---

## Security Considerations

1. **RLS Everywhere**: All tables have row-level security
2. **SECURITY DEFINER**: Helper functions bypass RLS safely
3. **Service Role Key**: Never exposed to frontend
4. **Guest Checkout**: Carefully scoped anon access
5. **Input Validation**: Zod schemas on frontend
6. **CORS**: Properly configured for Edge Functions
