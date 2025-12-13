# Cameron's Connect Release Checklist

**Version**: Use `npm run version:bump` to update version

---

## Pre-Release Checklist

### Code Quality

- [ ] All TypeScript errors resolved (`npm run build` passes)
- [ ] Linting passes (`npm run lint`)
- [ ] No console.log statements in production code (use `logger.*` instead)
- [ ] All TODO comments addressed or tracked in issues

### Testing

- [ ] E2E tests pass locally (`npx playwright test`)
- [ ] Guest checkout flow tested manually
- [ ] Authenticated checkout flow tested
- [ ] Dashboard order management tested
- [ ] Analytics access controls verified
- [ ] Mobile responsiveness verified (iOS Safari, Chrome)

### Database

- [ ] All migrations applied to staging
- [ ] Migration dry-run on production backup
- [ ] RLS policies verified (no unauthorized data access)
- [ ] Materialized views refreshed
- [ ] Database indexes optimized

### Security

- [ ] No secrets in codebase (`grep -r "sk_live\|password\|secret"`)
- [ ] Environment variables documented in `.env.example`
- [ ] CORS settings verified
- [ ] RLS policies block unauthorized analytics access
- [ ] JWT token handling secure

### Performance

- [ ] Lighthouse score > 90 (Performance)
- [ ] First Contentful Paint < 2s
- [ ] Bundle size checked (`npm run build` output)
- [ ] Images optimized and using Supabase Storage CDN
- [ ] Lazy loading working for routes

---

## Deployment Steps

### 1. Version Bump

```bash
# Patch release (bug fixes)
npm run version:bump patch

# Minor release (new features)
npm run version:bump minor

# Major release (breaking changes)
npm run version:bump major
```

### 2. Pre-deployment Verification

```bash
# Clean install and build
rm -rf node_modules dist
npm ci
npm run build

# Run E2E tests
npx playwright test

# Check for TypeScript errors
npx tsc --noEmit
```

### 3. Database Migrations (if any)

```bash
# 1. Backup production database (via Supabase dashboard)

# 2. Review migration files
cat supabase/migrations/XXX_*.sql

# 3. Apply to staging first
# (Use Supabase SQL Editor on staging project)

# 4. Verify staging works

# 5. Apply to production
# (Use Supabase SQL Editor on production project)

# 6. Refresh materialized views if needed
SELECT refresh_analytics_views();
```

### 4. Edge Functions Deployment

```bash
# Deploy all Edge Functions
supabase functions deploy --project-ref jwcuebbhkwwilqfblecq

# Or deploy specific function
supabase functions deploy send-verification-email --project-ref jwcuebbhkwwilqfblecq

# Verify deployments
supabase functions list --project-ref jwcuebbhkwwilqfblecq
```

### 5. Web App Deployment

**Option A: Automatic (GitHub Actions)**
```bash
# Push to main triggers deployment
git push origin main
```

**Option B: Manual (Vercel CLI)**
```bash
# Deploy to production
vercel --prod

# Or preview deployment
vercel
```

### 6. Post-Deployment Verification

```bash
# Health check
curl -s https://cameronsconnect.com | head -20

# API health check
curl -s "https://jwcuebbhkwwilqfblecq.supabase.co/rest/v1/stores?select=id&limit=1" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY"

# Check deployment logs
vercel logs --follow
```

---

## Rollback Procedures

### Web App Rollback

```bash
# List recent deployments
vercel list

# Rollback to previous deployment
vercel rollback <deployment-url>
```

### Database Rollback

1. Identify the migration to rollback
2. Run the corresponding `_rollback.sql` if available
3. Or restore from backup via Supabase dashboard

### Edge Functions Rollback

```bash
# Redeploy previous version from git
git checkout <previous-commit>
supabase functions deploy <function-name> --project-ref jwcuebbhkwwilqfblecq
git checkout main
```

---

## Environment Variables Checklist

### Required for Build

- [ ] `VITE_SUPABASE_URL`
- [ ] `VITE_SUPABASE_ANON_KEY`
- [ ] `VITE_APP_ENV` (production/staging)
- [ ] `VITE_APP_VERSION` (auto-set by CI)

### Required for Deployment (CI/CD)

- [ ] `VERCEL_TOKEN`
- [ ] `VERCEL_ORG_ID`
- [ ] `VERCEL_PROJECT_ID`
- [ ] `SUPABASE_ACCESS_TOKEN`
- [ ] `SUPABASE_PROJECT_REF`

### Optional

- [ ] `PRODUCTION_URL` (for health checks)
- [ ] `SENTRY_DSN` (error tracking)

---

## Communication

### Pre-Release

- [ ] Notify team of upcoming release
- [ ] Schedule maintenance window if needed
- [ ] Prepare release notes

### Post-Release

- [ ] Announce release in team channel
- [ ] Update changelog
- [ ] Tag release in GitHub
- [ ] Monitor error rates for 24 hours

---

## Monitoring Post-Release

### First Hour

- [ ] Check Vercel deployment status
- [ ] Verify all routes load correctly
- [ ] Test critical user flows
- [ ] Monitor Supabase logs for errors

### First 24 Hours

- [ ] Check error tracking dashboard
- [ ] Review API response times
- [ ] Monitor database performance
- [ ] Check for user-reported issues

### First Week

- [ ] Review analytics for anomalies
- [ ] Check for edge cases
- [ ] Gather user feedback
- [ ] Document any issues for next release

---

## Release Notes Template

```markdown
## v1.X.X (YYYY-MM-DD)

### New Features
- Feature description

### Improvements
- Improvement description

### Bug Fixes
- Fix description

### Breaking Changes
- Change description (migration guide if needed)

### Database Migrations
- Migration XXX: Description
```

---

## Emergency Contacts

| Role | Contact |
|------|---------|
| DevOps Lead | [TBD] |
| Backend Lead | [TBD] |
| Frontend Lead | [TBD] |
| Product Owner | [TBD] |

---

## Appendix: Common Issues

### Build Fails

```bash
# Clear cache and reinstall
rm -rf node_modules .vite dist
npm cache clean --force
npm ci
npm run build
```

### Supabase Connection Issues

1. Verify environment variables are set
2. Check Supabase project status
3. Verify RLS policies aren't blocking

### Vercel Deployment Fails

1. Check build logs in Vercel dashboard
2. Verify environment variables in Vercel settings
3. Try manual deployment with verbose logging

```bash
vercel --debug
```
