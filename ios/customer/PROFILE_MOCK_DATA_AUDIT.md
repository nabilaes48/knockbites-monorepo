# 🔍 Profile Screen Mock Data Audit

**Date:** November 19, 2025
**Status:** AUDIT COMPLETE

---

## 📋 **MOCK DATA FOUND:**

### **1. Order History** ✅ **ALREADY FIXED**
- **Status:** ✅ WORKING - Fetches from Supabase
- **File:** `OrderViewModel.swift`
- **Action:** None needed

### **2. Favorites** ❌ **USES MOCK DATA**
- **Status:** ❌ CRITICAL - Uses MockDataService
- **File:** `FavoritesViewModel.swift:40`
- **Code:** `MockDataService.shared.getMenuItems()`
- **Impact:** Users can't save real favorites
- **Action:** ⚠️ NEEDS FIX

### **3. Dietary Preferences** ❌ **USES LOCAL STORAGE**
- **Status:** ❌ MEDIUM - Uses UserDefaults only
- **File:** `ProfileViewModel.swift:21-78`
- **Code:** Saves to UserDefaults, no Supabase sync
- **Impact:** Preferences lost on device change
- **Action:** ⚠️ NEEDS FIX

### **4. Payment Methods** ❌ **USES MOCK DATA**
- **Status:** ❌ LOW PRIORITY - Mock credit cards
- **File:** `PaymentMethodViewModel.swift:44-80`
- **Code:** Generates fake Visa/Mastercard/Apple Pay
- **Impact:** Can't save real payment methods
- **Action:** ⚠️ COMPLEX - Needs payment provider integration
- **Note:** This requires Stripe/Braintree integration (out of scope for now)

### **5. Addresses** ❌ **NOT IMPLEMENTED**
- **Status:** ❌ MEDIUM - No ViewModel exists
- **File:** None - feature not built
- **Impact:** Can't save delivery addresses
- **Action:** ⚠️ NEEDS IMPLEMENTATION

### **6. Notifications** ❌ **NOT IMPLEMENTED**
- **Status:** ❌ LOW - No ViewModel exists
- **File:** None - feature not built
- **Impact:** Can't manage notification preferences
- **Action:** ⚠️ NEEDS IMPLEMENTATION

### **7. Settings** ❌ **USES LOCAL STORAGE**
- **Status:** ❌ LOW - Uses AppSettings singleton + UserDefaults
- **File:** `AppSettings.swift` (assumed)
- **Impact:** Settings lost on device change
- **Action:** ⚠️ Can be synced to user_profiles table

---

## 🎯 **PRIORITY RANKING:**

### **HIGH PRIORITY (Must Fix):**
1. ✅ **Order History** - DONE
2. ❌ **Favorites** - Easy fix, high user value
3. ❌ **Dietary Preferences** - Easy fix, safety concern (allergens)

### **MEDIUM PRIORITY (Should Fix):**
4. ❌ **Addresses** - Needed for delivery orders
5. ❌ **Settings** - Nice to have for cross-device

### **LOW PRIORITY (Can Wait):**
6. ❌ **Notifications** - Can use device defaults for now
7. ❌ **Payment Methods** - Requires third-party integration (Stripe/Braintree)

---

## 📊 **DATABASE SCHEMA CREATED:**

**File:** `database-migrations/002_user_profile_system.sql`

**Tables Created:**
1. `user_favorites` - Stores favorited menu items
2. `user_addresses` - Stores delivery addresses
3. `user_profiles` - Stores dietary preferences, notifications, settings

**Features:**
- ✅ Row Level Security (RLS) enabled
- ✅ Auto-create profile on user signup
- ✅ Helper functions for common operations
- ✅ Triggers for data integrity
- ✅ Indexes for performance

---

## ✅ **WHAT CAN BE FIXED NOW:**

### **1. Favorites** (Estimated: 1 hour)
**Changes Needed:**
- Update `FavoritesViewModel` to fetch from Supabase
- Add methods to `SupabaseManager`:
  - `toggleFavorite(userId, menuItemId)`
  - `getFavorites(userId)`
- Keep UserDefaults as cache

**Complexity:** 🟢 LOW

### **2. Dietary Preferences** (Estimated: 30 minutes)
**Changes Needed:**
- Update `ProfileViewModel` to sync with Supabase
- Add methods to `SupabaseManager`:
  - `updateUserProfile(userId, preferences)`
  - `getUserProfile(userId)`
- Keep UserDefaults as cache

**Complexity:** 🟢 LOW

### **3. Addresses** (Estimated: 2 hours)
**Changes Needed:**
- Create `AddressViewModel`
- Create `AddressesView`
- Add methods to `SupabaseManager`:
  - `getUserAddresses(userId)`
  - `addAddress(...)`
  - `updateAddress(...)`
  - `deleteAddress(...)`
  - `setDefaultAddress(...)`

**Complexity:** 🟡 MEDIUM

---

## ❌ **WHAT CANNOT BE FIXED YET:**

### **1. Payment Methods** (Requires External Integration)
**Why:**
- Real payment methods require Stripe/Braintree/Square API
- Need PCI compliance for storing card data
- Requires tokenization service
- Outside scope of simple Supabase migration

**Current Status:** Mock data is acceptable for MVP

**Future Work:**
- Integrate Stripe SDK
- Store only tokenized payment methods
- Never store actual card numbers

### **2. Notifications** (Requires Push Notification Setup)
**Why:**
- Needs APNs (Apple Push Notification service) setup
- Requires Firebase Cloud Messaging or similar
- Needs backend to send notifications

**Current Status:** Can use device defaults

**Future Work:**
- Setup push notification certificates
- Create notification service
- Store preferences in user_profiles table

---

## 🚀 **IMPLEMENTATION PLAN:**

### **Phase 1: Critical Fixes** (TODAY)
1. ✅ Order History - DONE
2. ⏳ Favorites - Switch to Supabase
3. ⏳ Dietary Preferences - Switch to Supabase

### **Phase 2: Important Features** (THIS WEEK)
4. ⏳ Addresses - Implement from scratch
5. ⏳ Settings Sync - Sync to user_profiles

### **Phase 3: Future Enhancements** (LATER)
6. ⏳ Payment Methods - Integrate Stripe
7. ⏳ Notifications - Setup push notifications

---

## 📝 **STEP-BY-STEP: What Happens Next**

### **Step 1: Run Database Migration**
```sql
-- Run this in Supabase SQL Editor
-- File: database-migrations/002_user_profile_system.sql
```

### **Step 2: Update FavoritesViewModel**
```swift
// Change from:
MockDataService.shared.getMenuItems()

// To:
SupabaseManager.shared.getUserFavorites()
```

### **Step 3: Update ProfileViewModel**
```swift
// Add sync to Supabase:
await SupabaseManager.shared.updateUserProfile(preferences)
```

### **Step 4: Test Each Feature**
- [ ] Add/remove favorites
- [ ] Update dietary preferences
- [ ] Verify data persists in Supabase

---

## ⚠️ **LIMITATIONS & KNOWN ISSUES:**

### **1. Payment Methods**
- **Current:** Uses mock data (fake Visa/Mastercard)
- **Future:** Needs Stripe/Braintree integration
- **Timeline:** 2-3 weeks for proper implementation
- **Cost:** Stripe setup + transaction fees

### **2. Notifications**
- **Current:** Not implemented
- **Future:** Needs APNs + backend service
- **Timeline:** 1-2 weeks
- **Cost:** Firebase setup (free tier available)

### **3. Settings Sync**
- **Current:** Local only (UserDefaults)
- **Future:** Can sync to user_profiles easily
- **Timeline:** 1-2 hours
- **Cost:** None (uses existing Supabase)

---

## 💰 **COST ESTIMATE:**

### **What's Free (Supabase):**
- ✅ Favorites - FREE
- ✅ Dietary Preferences - FREE
- ✅ Addresses - FREE
- ✅ Settings Sync - FREE

### **What Costs Money:**
- 💰 Payment Methods - Stripe fees (2.9% + $0.30 per transaction)
- 💰 Push Notifications - Firebase (free tier exists, paid for scale)

---

## 🎯 **RECOMMENDATION:**

**DO NOW (High Value, Low Effort):**
1. ✅ Favorites - Users expect this to work
2. ✅ Dietary Preferences - Safety concern (allergens!)
3. ✅ Addresses - Needed for delivery

**DO LATER (Requires External Services):**
4. ⏸️ Payment Methods - Use Stripe when ready for launch
5. ⏸️ Notifications - Add when user base grows

**KEEP AS MOCK (Acceptable for MVP):**
- Payment Methods (until Stripe integration)
- Notifications (until push setup)

---

## 📞 **WHAT I NEED FROM YOU:**

1. **Confirm Priority:** Which features do you want fixed first?
   - [ ] Favorites
   - [ ] Dietary Preferences
   - [ ] Addresses
   - [ ] All of the above

2. **Database Access:** Ready to run Migration 002?
   - [ ] Yes, run it now
   - [ ] No, I'll run it later

3. **Payment Decision:**
   - [ ] Keep mock payment methods for now
   - [ ] Start Stripe integration

4. **Timeline Preference:**
   - [ ] Fix critical items today
   - [ ] Take time for complete solution

---

## 📊 **SUMMARY TABLE:**

| Feature | Current Status | Priority | Complexity | Can Fix Now? |
|---------|---------------|----------|------------|--------------|
| Order History | ✅ Supabase | HIGH | LOW | ✅ DONE |
| Favorites | ❌ Mock | HIGH | LOW | ✅ YES |
| Dietary Pref | ❌ Local | HIGH | LOW | ✅ YES |
| Addresses | ❌ None | MEDIUM | MEDIUM | ✅ YES |
| Settings | ❌ Local | MEDIUM | LOW | ✅ YES |
| Notifications | ❌ None | LOW | HIGH | ❌ NO (needs APNs) |
| Payment Methods | ❌ Mock | LOW | HIGH | ❌ NO (needs Stripe) |

---

**Status:** Audit complete, ready for implementation decisions
**Next Step:** Your call - which features should I fix first?
