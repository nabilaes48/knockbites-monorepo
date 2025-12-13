# Phase 9 Implementation Report

**Cameron's Connect - Reliability, Monitoring & Auto-Heal**

**Date**: 2025-12-02
**Status**: COMPLETE

---

## Executive Summary

Phase 9 transformed Cameron's Connect into a self-monitoring, self-diagnosing, auto-healing system with comprehensive runtime metrics, alerting, deployment rollback capabilities, and backup/recovery infrastructure.

---

## Deliverables Completed

### 1. Runtime Metrics System

#### Frontend Metrics Collector (`src/lib/metrics.ts`)

**Features**:
- Page view tracking with automatic SPA navigation detection
- API latency recording with status codes
- Error capture (unhandled errors + promise rejections)
- User action tracking
- Web Vitals (LCP, FID, CLS) via PerformanceObserver
- Batched submission (5-second buffer, max 20 entries)
- Session persistence across navigation

**API**:
```typescript
import metrics from '@/lib/metrics';

metrics.recordPageView('/menu');
metrics.recordAPILatency('orders.select', 150, 200);
metrics.recordError('fetch_error', 'Network timeout');
metrics.recordUserAction('add_to_cart', { itemId: 123 });
metrics.recordPerformance('LCP', 1200);
```

#### Database Table (`migrations/062_runtime_metrics.sql`)

```sql
runtime_metrics
├── id BIGSERIAL PRIMARY KEY
├── created_at TIMESTAMPTZ
├── user_id UUID (nullable)
├── session_id TEXT
├── event_type TEXT (page_view, api_latency, error, etc.)
└── event_data JSONB
```

**RLS**: INSERT allowed for anon/authenticated, SELECT denied (service_role only)

**Secure RPC Functions**:
- `get_recent_errors(p_limit, p_hours)` - Super admin only
- `get_api_latency_stats(p_hours)` - Super admin only
- `get_metrics_summary(p_hours)` - Super admin only
- `get_error_rate_timeseries(p_hours, p_bucket_minutes)` - Super admin only
- `cleanup_old_metrics(p_retention_days)` - System maintenance

---

### 2. Alerting System

#### Alert Rules Table (`migrations/063_alert_rules.sql`)

```sql
alert_rules
├── id SERIAL PRIMARY KEY
├── name TEXT
├── metric_type TEXT
├── condition TEXT (gt, lt, gte, lte, eq)
├── threshold NUMERIC
├── window_minutes INTEGER
├── cooldown_minutes INTEGER
├── severity TEXT (info, warning, critical)
├── channels JSONB (email, slack, sms)
└── enabled BOOLEAN
```

**Default Alert Rules**:

| Rule | Metric | Threshold | Severity | Channels |
|------|--------|-----------|----------|----------|
| High Error Rate | error_rate | >5% in 15min | Critical | Email, Slack |
| High API Latency | api_latency_p95 | >2000ms | Warning | Email |
| Stuck Orders | stuck_orders | >0 for 45min | Warning | Email, Slack |
| Payment Failures | payment_failure | >0 in 5min | Critical | Email, Slack, SMS |
| Low Disk Space | storage_usage | >80% | Warning | Email |
| DB Connection Pool | db_connections | >90% | Critical | Email, Slack |

#### Alert History Table

```sql
alert_history
├── id BIGSERIAL PRIMARY KEY
├── alert_rule_id INTEGER
├── triggered_at TIMESTAMPTZ
├── resolved_at TIMESTAMPTZ
├── status TEXT (triggered, acknowledged, resolved)
├── severity TEXT
├── metric_value NUMERIC
├── message TEXT
└── channels_notified JSONB
```

#### Alert Dispatcher (`supabase/functions/send-alert/index.ts`)

**Supported Channels**:
- **Email**: Via Resend API with HTML templates
- **Slack**: Via Webhook with blocks formatting
- **SMS**: Via Twilio (optional)

**Required Secrets**:
- `RESEND_API_KEY`
- `ALERT_EMAIL`
- `SLACK_WEBHOOK_URL`
- `TWILIO_ACCOUNT_SID` (optional)
- `TWILIO_AUTH_TOKEN` (optional)
- `TWILIO_FROM_NUMBER` (optional)
- `ALERT_SMS_NUMBER` (optional)

---

### 3. Auto-Heal System

#### Auto-Heal Functions (`migrations/064_deployment_log.sql`)

**`auto_heal_stuck_orders()`**:
- Orders in `preparing` >45 minutes → Promoted to `ready`
- Orders in `ready` >2 hours → Marked as `completed`
- All corrections logged to `runtime_metrics`

**`refresh_order_health()`**:
- Refreshes `mv_order_health` materialized view
- Logs refresh to metrics

**`run_system_maintenance()`**:
- Runs auto-heal
- Refreshes views
- Evaluates alert rules
- Returns JSON summary

#### Order Health View (`mv_order_health`)

Pre-computed hourly metrics:
- Total/completed/cancelled/active orders
- Stuck orders (preparing >30min, ready >1hr)
- Average completion time
- Average order value
- Revenue totals

**RPC**: `get_order_health_summary(p_store_id, p_hours)`

---

### 4. Deployment Pipeline with Rollback

#### Deployment Log Table

```sql
deployment_log
├── id BIGSERIAL PRIMARY KEY
├── deployment_id TEXT UNIQUE
├── environment TEXT (staging, production)
├── version TEXT
├── commit_sha TEXT
├── deployed_at TIMESTAMPTZ
├── status TEXT (deploying, success, failed, rolled_back)
├── smoke_test_passed BOOLEAN
└── rollback_target_id BIGINT (self-reference)
```

#### Deploy-with-Rollback Workflow (`.github/workflows/deploy-with-rollback.yml`)

**Flow**:
1. Build application
2. Deploy to Vercel
3. Log deployment start
4. Run smoke tests:
   - Main page health check
   - Menu page health check
   - API health check
5. On success: Update status, send success notification
6. On failure:
   - Trigger rollback via Edge Function
   - Send critical alert
   - Restore previous deployment

#### Rollback Edge Function (`supabase/functions/deploy-rollback/index.ts`)

**Features**:
- Finds last successful deployment
- Triggers Vercel redeployment of previous version
- Logs rollback to `deployment_log`
- Sends alert notification

**Deployment Helper Functions**:
- `log_deployment()` - Record new deployment
- `update_deployment_status()` - Update status + smoke test results
- `get_last_successful_deployment()` - Find rollback target
- `log_rollback()` - Record rollback action

---

### 5. Backup & Recovery

#### Backup Script (`scripts/db-backup.js`)

**Features**:
- Backs up all core tables in dependency order
- Saves to local `backups/YYYY-MM-DD/` directory
- Uploads to Supabase Storage `backups/` bucket
- Creates manifest.json with metadata
- Logs backup to metrics

**Tables Backed Up**:
1. stores
2. menu_categories
3. menu_items
4. menu_item_customizations
5. ingredient_templates
6. customers
7. user_profiles
8. orders
9. order_items
10. alert_rules
11. alert_history
12. deployment_log

**Usage**:
```bash
npm run db:backup
# Or with env vars:
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node scripts/db-backup.js
```

#### Restore Script (`scripts/db-restore.js`)

**Features**:
- Restore from local or storage
- Dry-run mode for preview
- Selective table restore
- Respects foreign key order
- Logs restore to metrics

**Usage**:
```bash
# Preview
npm run db:restore 2025-12-01 --dry-run

# Restore specific tables
npm run db:restore 2025-12-01 --tables=orders,order_items

# Full restore from local
npm run db:restore 2025-12-01 --local
```

---

### 6. System Health Dashboard

#### New Page (`src/pages/SystemHealth.tsx`)

**Access**: Super admin only (redirects others to dashboard)

**Tabs**:

| Tab | Content |
|-----|---------|
| Errors | Recent errors (24h) with type, message, URL, session |
| Latency | API statistics table: avg, P50, P95, P99, request count, error count |
| Alerts | Alert history with acknowledge/resolve actions |
| Orders | Order health summary: completion rate, stuck counts, avg times |
| Deployments | Deployment history with status, version, smoke test results |

**Overview Cards**:
- Errors (24h) with affected sessions
- Active Alerts with critical count
- Avg Latency with P95
- Order Health with stuck count

**Route**: `/system-health`

---

## Files Created

| File | Purpose |
|------|---------|
| `src/lib/metrics.ts` | Frontend metrics collector |
| `supabase/migrations/062_runtime_metrics.sql` | Metrics table + RPC functions |
| `supabase/migrations/063_alert_rules.sql` | Alert rules + history tables |
| `supabase/migrations/064_deployment_log.sql` | Deployment log + auto-heal |
| `supabase/functions/send-alert/index.ts` | Multi-channel alert dispatcher |
| `supabase/functions/deploy-rollback/index.ts` | Deployment rollback endpoint |
| `scripts/db-backup.js` | Database backup script |
| `scripts/db-restore.js` | Database restore script |
| `src/pages/SystemHealth.tsx` | System health dashboard |
| `.github/workflows/deploy-with-rollback.yml` | CI/CD with auto-rollback |

## Files Modified

| File | Changes |
|------|---------|
| `src/App.tsx` | Added SystemHealth route |
| `supabase/functions/_shared/logger.ts` | Added metrics submission functions |
| `package.json` | Added db:backup and db:restore scripts |
| `README.md` | Added Monitoring & Alerting section |

---

## Metrics Captured

### Event Types

| Type | Description | Key Data |
|------|-------------|----------|
| `page_view` | Page navigation | page, referrer, userAgent |
| `api_latency` | API response time | endpoint, latency_ms, status |
| `error` | Application errors | error_type, message, stack |
| `user_action` | User interactions | action, metadata |
| `order_event` | Order lifecycle | event, order_id |
| `performance` | Web Vitals | metric (LCP/FID/CLS), value |
| `edge_function` | Edge Function execution | function_name, execution_time_ms |
| `alert_triggered` | Alert events | alert_id, rule_name, severity |
| `auto_heal` | Auto-healing actions | action, details |
| `deployment` | Deployment events | action, deployment_id, status |

---

## Alert Conditions

| Condition | Metric | Threshold | Action |
|-----------|--------|-----------|--------|
| High Error Rate | `error_rate` | >5% in 15min | Email + Slack (Critical) |
| High Latency | `api_latency_p95` | >2000ms | Email (Warning) |
| Stuck Orders | `stuck_orders` | >0 for 45min | Email + Slack (Warning) |
| Payment Failure | `payment_failure` | Any in 5min | Email + Slack + SMS (Critical) |
| Storage Alert | `storage_usage` | >80% | Email (Warning) |
| Connection Pool | `db_connections` | >90% | Email + Slack (Critical) |

---

## Auto-Heal Logic

### Order Status Auto-Correction

```
preparing (>45 min) → ready
  Reason: Likely prepared but staff forgot to update

ready (>2 hours) → completed
  Reason: Likely picked up but staff forgot to complete
```

### Metrics Cleanup

```
runtime_metrics older than 30 days → Deleted
  Reason: Prevent unbounded table growth
```

### Scheduled Maintenance

The `run_system_maintenance()` function should be called by a cron job every 15 minutes:
1. Execute `auto_heal_stuck_orders()`
2. Refresh `mv_order_health`
3. Evaluate `alert_rules`
4. Return summary JSON

---

## Rollback Pipeline Flow

```
Push to main
    │
    ▼
┌─────────────────┐
│  Build & Deploy │
│   to Vercel     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Smoke Tests    │
│  (3 endpoints)  │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
  Pass      Fail
    │         │
    ▼         ▼
┌─────────┐ ┌─────────────────┐
│ Success │ │ Trigger Rollback │
│ Notify  │ │ Edge Function    │
└─────────┘ └────────┬────────┘
                     │
                     ▼
            ┌─────────────────┐
            │ Find Last Good  │
            │ Deployment      │
            └────────┬────────┘
                     │
                     ▼
            ┌─────────────────┐
            │ Redeploy via    │
            │ Vercel API      │
            └────────┬────────┘
                     │
                     ▼
            ┌─────────────────┐
            │ Send Critical   │
            │ Alert           │
            └─────────────────┘
```

---

## Summary

Phase 9 establishes comprehensive observability and self-healing capabilities:

- **Metrics**: Complete runtime telemetry from web + Edge Functions
- **Alerting**: Rule-based alerts with multi-channel delivery
- **Auto-Heal**: Automatic correction of stuck orders
- **Rollback**: Automated deployment recovery on failures
- **Backup**: Full database backup/restore capability
- **Dashboard**: Central monitoring for super admins

The platform now detects, alerts, and automatically recovers from common failure modes while maintaining full visibility into system health.

---

**Next Steps**:
1. Run migrations 062-064 in Supabase SQL Editor
2. Configure alert channel secrets (Resend, Slack, Twilio)
3. Set up cron job for `run_system_maintenance()` (every 15 min)
4. Create `backups` storage bucket in Supabase
5. Configure GitHub secrets for rollback workflow
6. Test rollback flow with intentional failure
