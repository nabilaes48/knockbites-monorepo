# Cameron's Connect

Multi-location food ordering and business management platform for Cameron's 24-7 stores across New York.

## Quick Start

### Prerequisites

- Node.js 18+ (install via [nvm](https://github.com/nvm-sh/nvm))
- npm 9+
- Supabase account ([supabase.com](https://supabase.com))

### 1. Clone & Install

```bash
git clone <YOUR_GIT_URL>
cd camerons-connect
npm install
```

### 2. Environment Setup

```bash
# Copy the example env file
cp .env.example .env.local

# Edit .env.local with your Supabase credentials
# Get these from: https://supabase.com/dashboard/project/_/settings/api
```

Required variables:
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### 3. Database Setup

**For NEW environments** (fresh database):
```sql
-- Run the baseline schema in Supabase SQL Editor
\i supabase/migrations/000_BASELINE_CANONICAL_SCHEMA.sql
```

**For EXISTING environments** (incremental):
```sql
-- Run migrations in numerical order (001-061)
-- Skip any already applied
```

### 4. Run Development Server

```bash
npm run dev
# Opens at http://localhost:8080
```

### 5. Deploy Edge Functions (Optional)

```bash
# Install Supabase CLI
npm install -g supabase

# Link to your project
supabase link --project-ref your-project-ref

# Deploy all functions
supabase functions deploy
```

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | React 18 + TypeScript + Vite |
| UI | shadcn/ui + Tailwind CSS |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| Edge Functions | Deno (Supabase Edge Functions) |
| iOS Apps | Swift/SwiftUI (separate repos) |

---

## Project Structure

```
camerons-connect/
├── src/
│   ├── pages/           # Route components
│   ├── components/      # UI components
│   ├── contexts/        # React contexts (Auth)
│   ├── hooks/           # Custom hooks
│   ├── lib/             # Utilities
│   └── data/            # Static data (locations)
├── supabase/
│   ├── migrations/      # Database migrations (001-061)
│   ├── migrations_archived/  # Historical/superseded
│   └── functions/       # Edge Functions
├── docs/                # Documentation
│   ├── ARCHITECTURE_OVERVIEW.md
│   └── DB_MIGRATIONS_OVERVIEW.md
└── public/              # Static assets
```

---

## Available Scripts

```bash
npm run dev           # Start dev server (port 8080)
npm run build         # Production build
npm run preview       # Preview production build
npm run lint          # Run ESLint
npm run test:e2e      # Run Playwright E2E tests
npm run test:e2e:ui   # Run E2E tests with UI
npm run version:bump  # Bump version (patch|minor|major)
npm run db:backup     # Backup database to storage
npm run db:restore    # Restore database from backup
```

---

## Documentation

- **[Architecture Overview](docs/ARCHITECTURE_OVERVIEW.md)** - System design, data model, auth flows
- **[Database Migrations](docs/DB_MIGRATIONS_OVERVIEW.md)** - Migration history and schema details
- **[API Contract](docs/API_CONTRACT.md)** - REST API specification and examples
- **[Release Checklist](docs/RELEASE_CHECKLIST.md)** - Production deployment guide
- **[CLAUDE.md](CLAUDE.md)** - AI assistant context and coding guidelines

---

## Key Features

### Customer Features
- Browse menu by category
- Customizable orders (portions: None/Light/Regular/Extra)
- Guest checkout (no account required)
- Order tracking
- Rewards program (points, tiers)

### Staff Dashboard
- Real-time order management
- Accept/Reject/Update orders
- Menu management
- Analytics dashboard

### Admin Features
- Multi-store management
- Staff management with RBAC
- Store performance analytics
- Materialized views for fast reporting

---

## iOS Apps

Two companion iOS apps share the same Supabase backend:

1. **Customer App** - Order placement, tracking, rewards
2. **Business App** - Order management for staff

iOS apps use the same `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

---

## Environment Variables

See [.env.example](.env.example) for all available variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `VITE_SUPABASE_URL` | Yes | Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | Yes | Public anon key |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge only | Service role (server-side) |
| `RESEND_API_KEY` | Optional | Email sending |
| `STRIPE_WEBHOOK_SECRET` | Future | Payment webhooks |

---

## Deployment

### CI/CD Pipelines (GitHub Actions)

The project includes automated deployment workflows:

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `e2e-tests.yml` | Push to main/develop, PRs | Runs Playwright E2E tests |
| `deploy-web.yml` | Push to main | Builds and deploys to Vercel |
| `deploy-with-rollback.yml` | Push to main | Deploy with smoke tests + auto-rollback |
| `deploy-edge-functions.yml` | Changes to `supabase/functions/**` | Deploys Edge Functions |
| `build-ios.yml` | Manual | iOS build stub (future) |

**Required Secrets (GitHub)**:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_PROJECT_REF`

### Manual Deployment

**Vercel (Recommended)**:
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy to production
vercel --prod
```

**Manual Build**:
```bash
npm run build
# Deploy dist/ folder to any static host
```

### Edge Functions

```bash
# Install Supabase CLI
npm i -g supabase

# Link project
supabase link --project-ref your-project-ref

# Deploy all functions
supabase functions deploy

# Or specific function
supabase functions deploy send-verification-email
```

---

## Monitoring & Alerting

### System Health Dashboard

Access `/system-health` (super admin only) to view:
- Recent errors and exceptions
- API latency statistics
- Alert history and management
- Order health metrics
- Deployment history

### Alert Rules

Default alerts configured in `alert_rules` table:
- High error rate (>5% in 15 min) - Critical
- High API latency (P95 >2000ms) - Warning
- Stuck orders (>45 min) - Warning
- Payment failures - Critical

Alerts sent via:
- Email (Resend)
- Slack (Webhook)
- SMS (Twilio) - Optional

### Auto-Heal System

Automatic recovery for:
- **Stuck orders in "preparing"** (>45 min) → Auto-promote to "ready"
- **Stuck orders in "ready"** (>2 hours) → Auto-complete
- **Metrics cleanup** → Auto-delete after 30 days

### Backup & Recovery

```bash
# Manual backup
npm run db:backup

# Restore (use with caution!)
npm run db:restore 2025-12-01 --dry-run  # Preview
npm run db:restore 2025-12-01            # Execute
```

Backups stored in Supabase Storage bucket `backups/YYYY-MM-DD/`.

---

## Contributing

1. Create feature branch from `main`
2. Make changes
3. Run `npm run lint` and `npm run build`
4. Submit PR

---

## Support

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Docs**: See `/docs` folder

---

## License

Proprietary - Cameron's Connect / Highland Mills Snack Shop Inc.
