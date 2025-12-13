# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cameron's Connect is a multi-location food ordering and business management platform for Cameron's 24-7 stores across New York. React/TypeScript frontend with Supabase backend (PostgreSQL + Auth + Realtime).

## Commands

```bash
npm run dev              # Start dev server (http://localhost:8080)
npm run build            # Production build
npm run lint             # Run ESLint
npm run test:e2e         # Run Playwright E2E tests
npm run test:e2e:ui      # Run E2E tests with UI
npm run db:backup        # Backup database to storage
npm run db:restore       # Restore database from backup
npm run migration:check  # Check migration compatibility
```

## Tech Stack

- **Frontend**: React 18 + TypeScript + Vite + shadcn/ui + Tailwind CSS
- **Backend**: Supabase (PostgreSQL + Auth + Realtime + Edge Functions)
- **State**: React Context + local state (no Redux/Zustand)
- **Routing**: React Router v6 with lazy loading
- **Path alias**: `@/` resolves to `src/`

## Architecture

See `docs/ARCHITECTURE_OVERVIEW.md` for system diagrams and data model.

### Key Directories

- `src/pages/` - Route components (lazy loaded via React.lazy)
- `src/components/dashboard/` - Staff dashboard components
- `src/components/order/` - Customer order flow
- `src/components/ui/` - shadcn/ui components (auto-generated, do not edit)
- `src/contexts/AuthContext.tsx` - Authentication and permission helpers
- `src/hooks/` - Custom hooks (useRealtimeOrders, useAnalytics, useRewards)
- `src/data/locations.ts` - Single source of truth for 29 store locations
- `supabase/migrations/` - Database migrations (see `docs/DB_MIGRATIONS_OVERVIEW.md`)
- `supabase/functions/` - Edge Functions (Deno)

## Critical Patterns

### Route Registration

**CRITICAL**: Add new routes ABOVE the catch-all in `src/App.tsx`:

```tsx
<Route path="/new-route" element={<NewPage />} />
{/* ADD ALL ROUTES ABOVE THIS CATCH-ALL */}
<Route path="*" element={<NotFound />} />
```

### Authentication & Roles

Dual-profile system separates customers from business users:

```typescript
import { useAuth } from '@/contexts/AuthContext';

const {
  user,           // Supabase auth user
  profile,        // user_profiles (staff) or customers row
  isCustomer,     // Boolean checks
  isStaff, isManager, isAdmin, isSuperAdmin,
  hasPermission   // hasPermission('orders' | 'menu' | 'analytics' | 'settings')
} = useAuth();
```

- **Customers**: `customers` table, created automatically on signup
- **Business users**: `user_profiles` table, created by admins via dashboard
- Roles: `super_admin` > `admin` > `manager` > `staff` > `customer`

### Guest Checkout

Anonymous users can create orders and track status (no auth required):

```typescript
// Public can insert orders - essential for iOS app and web guest checkout
const { data } = await supabase.from('orders').insert({ ... });
```

### Cart Items

Use unique `cartId` (not menu item `id`) to support duplicate items with different customizations:

```typescript
{ id: number, cartId: number, name: string, price: number, quantity: number, customizations?: string[] }
```

### Store Data

Never hardcode store info. Always use `src/data/locations.ts` as single source of truth.

### Supabase Storage

Menu images are in Supabase Storage bucket `menu-images`, NOT local `/public/images/`:
- CDN URL pattern: `https://jwcuebbhkwwilqfblecq.supabase.co/storage/v1/object/public/menu-images/[category]/[filename].jpg`

## Database

See `docs/DB_MIGRATIONS_OVERVIEW.md` for full migration history.

### Key Tables

| Table | Purpose |
|-------|---------|
| `stores` | 29 Cameron's locations |
| `customers` | Customer profiles (separate from staff) |
| `user_profiles` | Business users with roles/permissions |
| `menu_items` | Menu items with pricing |
| `menu_item_customizations` | Portion-based ingredient customizations |
| `orders` / `order_items` | Orders and line items |

### Key Helper Functions (SQL)

```sql
get_current_user_role()              -- Returns role string
is_current_user_system_admin()       -- Boolean check
get_current_user_assigned_stores()   -- INT[] of store IDs
can_access_analytics(store_id)       -- Boolean access check
```

### Running Migrations

- **New environment**: Run `000_BASELINE_CANONICAL_SCHEMA.sql` only
- **Existing environment**: Run migrations 001-068 in order
- Always use `IF EXISTS` / `IF NOT EXISTS` for idempotency

## Testing

E2E tests use Playwright in `tests/e2e/`:

```bash
npm run test:e2e                                           # Run all tests
npm run test:e2e:ui                                        # Interactive UI mode
npm run test:e2e -- tests/e2e/01_guest_checkout.spec.ts   # Run single file
npm run test:e2e -- -g "guest checkout"                    # Run tests matching pattern
npm run test:e2e -- --project=chromium                     # Run on specific browser
```

Tests run against Chromium, Firefox, WebKit, and mobile viewports (Pixel 5, iPhone 12).

## Environment Variables

Required in `.env.local`:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

See `.env.example` for all available variables.

## Documentation

- `docs/ARCHITECTURE_OVERVIEW.md` - System design, data model, auth flows
- `docs/DB_MIGRATIONS_OVERVIEW.md` - Migration history and schema details
- `docs/API_CONTRACT.md` - REST API specification
- `docs/RELEASE_CHECKLIST.md` - Production deployment guide

## Development Notes

- Dev server runs on port **8080** (IPv6 `::`)
- TypeScript is relaxed (`noImplicitAny: false`, `strictNullChecks: false`) for rapid iteration
- shadcn/ui components in `src/components/ui/` are auto-generated - do not manually edit
- Use `cn()` from `src/lib/utils.ts` for conditional Tailwind classes
- Charts use both **Tremor** (`@tremor/react`) and **Recharts** - Tremor for dashboard analytics, Recharts for custom visualizations

## Realtime Subscriptions

Orders use Supabase Realtime for live updates. Pattern in `useRealtimeOrders`:

```typescript
const channel = supabase
  .channel('orders-changes')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'orders',
    filter: `store_id=eq.${storeId}`
  }, (payload) => {
    // Handle INSERT, UPDATE, DELETE
  })
  .subscribe();
```

## Edge Functions (Deno)

Located in `supabase/functions/`. To develop locally:

```bash
# Start Supabase locally (requires Docker)
supabase start

# Serve functions locally
supabase functions serve

# Deploy single function
supabase functions deploy send-order-notification

# View function logs
supabase functions logs send-order-notification
```

Shared utilities in `supabase/functions/_shared/` (auth, cors, email, logging).
