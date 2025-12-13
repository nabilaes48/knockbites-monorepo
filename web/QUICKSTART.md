# 🚀 Supabase Integration - Quick Start

Follow these steps to get your Cameron's Connect platform connected to Supabase.

## ✅ Checklist

### Phase 1: Supabase Setup (30 minutes)

- [ ] **Create Supabase account** at [supabase.com](https://supabase.com)
- [ ] **Create new project** named `camerons-connect-dev`
- [ ] **Save credentials** (Project URL and Anon Key)
- [ ] **Run migration 1** (`001_initial_schema.sql` in SQL Editor)
- [ ] **Run migration 2** (`002_row_level_security.sql` in SQL Editor)
- [ ] **Run migration 3** (`003_seed_data.sql` in SQL Editor)
- [ ] **Verify tables** exist in Table Editor (should see 13+ tables)
- [ ] **Verify stores** (should see 29 Cameron's Connect locations)

### Phase 2: React Web App Setup (15 minutes)

- [ ] **Install Supabase** client:
  ```bash
  npm install @supabase/supabase-js
  ```

- [ ] **Create `.env.local`** file:
  ```bash
  cp .env.example .env.local
  ```

- [ ] **Add your credentials** to `.env.local`:
  ```env
  VITE_SUPABASE_URL=https://xxxxx.supabase.co
  VITE_SUPABASE_ANON_KEY=eyJhbGc...
  ```

- [ ] **Create test user** (run SQL in Supabase):
  ```sql
  -- See SUPABASE_SETUP.md Step 4 for the SQL
  ```

- [ ] **Wrap App with AuthProvider** in `src/App.tsx`

- [ ] **Start dev server**:
  ```bash
  npm run dev
  ```

- [ ] **Test login** at `http://localhost:8080/dashboard/login`
  - Email: `admin@cameronsconnect.com`
  - Password: `admin123`

### Phase 3: Swift Apps Setup (Later - 1-2 hours each)

- [ ] **Business App:**
  - [ ] Install Supabase Swift SDK
  - [ ] Add credentials to Info.plist
  - [ ] Implement authentication
  - [ ] Create order management views
  - [ ] Test real-time order updates

- [ ] **Customer App:**
  - [ ] Same Supabase setup
  - [ ] Implement menu browsing
  - [ ] Implement cart & checkout
  - [ ] Test order placement

### Phase 4: Integration Testing

- [ ] **Test authentication** across all apps
- [ ] **Create test order** from web app
- [ ] **Verify real-time** updates in business app
- [ ] **Test all user roles** (super_admin, admin, manager, staff)
- [ ] **Test permissions** system
- [ ] **Test order workflow** (pending → confirmed → preparing → ready → completed)

## 📁 Files Created

All files are ready to use:

```
/Users/nabilimran/camerons-connect/
├── supabase/
│   ├── migrations/
│   │   ├── 001_initial_schema.sql       ✅ Database tables
│   │   ├── 002_row_level_security.sql   ✅ Security policies
│   │   └── 003_seed_data.sql            ✅ Initial data
│   └── README.md                         ✅ Migration docs
├── src/
│   ├── lib/
│   │   └── supabase.ts                   ✅ Supabase client
│   ├── contexts/
│   │   └── AuthContext.tsx               ✅ Authentication
│   ├── components/
│   │   └── ProtectedRoute.tsx            ✅ Route protection
│   └── hooks/
│       └── useRealtimeOrders.ts          ✅ Real-time orders
├── .env.example                          ✅ Environment template
├── SUPABASE_SETUP.md                     ✅ Detailed setup guide
├── SWIFT_INTEGRATION.md                  ✅ iOS integration guide
└── QUICKSTART.md                         ✅ This file
```

## 🎯 Next Steps After Setup

1. **Update DashboardLogin.tsx**
   - Replace localStorage auth with `useAuth()` hook
   - See `SUPABASE_SETUP.md` for code example

2. **Update Dashboard.tsx**
   - Use `useAuth()` instead of localStorage
   - Use profile data from context

3. **Update OrderManagement.tsx**
   - Use `useRealtimeOrders()` hook
   - Remove mock data

4. **Update Checkout component**
   - Save orders to Supabase
   - Generate order numbers
   - Save order items

5. **Add menu management**
   - Fetch menu from Supabase
   - Allow admins to edit menu
   - Handle per-store availability

## 🆘 Common Issues

| Issue | Solution |
|-------|----------|
| "Missing Supabase environment variables" | Create `.env.local` with credentials, restart dev server |
| Can't see tables in Supabase | Run all 3 migration files in order |
| Login fails | Make sure you created the test user (Step 4 in SUPABASE_SETUP.md) |
| RLS policy errors | Check user has correct role in `user_profiles` table |
| Real-time not working | Check Supabase Dashboard → Database → Replication is enabled |

## 📚 Documentation

- **Full setup:** `SUPABASE_SETUP.md`
- **Swift apps:** `SWIFT_INTEGRATION.md`
- **Migrations:** `supabase/README.md`
- **Supabase docs:** https://supabase.com/docs

## 💡 Pro Tips

1. **Use separate Supabase projects** for dev and production
2. **Test in incognito** to verify fresh sessions work
3. **Monitor usage** in Supabase Dashboard → Reports
4. **Enable email auth** for production (confirm emails)
5. **Upgrade to Pro** ($25/mo) before launch for backups

## ⏱️ Estimated Time

- Phase 1 (Supabase): **30 min**
- Phase 2 (Web App): **15 min**
- Phase 3 (Swift Apps): **2-4 hours**
- Testing: **1-2 hours**

**Total: 4-7 hours** to full integration

## 🎉 Success Criteria

You'll know it's working when:

1. ✅ You can login at `/dashboard/login`
2. ✅ Dashboard shows your role badge
3. ✅ Real-time order updates work
4. ✅ New orders appear across all apps instantly
5. ✅ All 29 stores visible in location selector

---

**Ready to start?** Begin with Phase 1! Open `SUPABASE_SETUP.md` for detailed step-by-step instructions.

**Questions?** Check the troubleshooting section in `SUPABASE_SETUP.md`
