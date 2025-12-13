# 🚀 Profile Features Implementation Plan

**Date:** November 19, 2025
**Scope:** Option A + B (All Fixable Features)
**Estimated Time:** 4.5 hours
**Status:** STARTING NOW

---

## 📋 **IMPLEMENTATION ORDER:**

### **Phase 1: Foundation** (10 minutes)
1. ✅ Run database migration
2. ✅ Add Supabase helper methods to SupabaseManager

### **Phase 2: Critical Features** (1.5 hours)
3. ⏳ **Favorites** - Switch from MockData to Supabase (1 hour)
4. ⏳ **Dietary Preferences** - Sync with Supabase (30 min)

### **Phase 3: Additional Features** (3 hours)
5. ⏳ **Addresses** - Build complete feature (2 hours)
6. ⏳ **Settings Sync** - Connect to user_profiles (1 hour)

### **Phase 4: Testing** (30 minutes)
7. ⏳ Build and test all features
8. ⏳ Verify data persists in Supabase

**Total:** ~5 hours (including buffer)

---

## 🎯 **FEATURE 1: FAVORITES**

### **Current State:**
```swift
// FavoritesViewModel.swift:40
func getFavoriteItems() -> [MenuItem] {
    let allItems = MockDataService.shared.getMenuItems()  // ❌ MOCK
    return allItems.filter { favoriteItemIds.contains($0.id) }
}
```

### **Changes Needed:**

#### **A. SupabaseManager (New Methods):**
```swift
// 1. Toggle favorite
func toggleFavorite(menuItemId: String) async throws -> Bool

// 2. Get user's favorites
func getUserFavorites() async throws -> [MenuItem]

// 3. Check if favorited
func isFavorited(menuItemId: String) async throws -> Bool
```

#### **B. FavoritesViewModel (Updates):**
```swift
// Replace mock data with Supabase calls
@Published var favoriteItems: [MenuItem] = []
@Published var isLoading = false

func fetchFavorites() async {
    favoriteItems = try await SupabaseManager.shared.getUserFavorites()
}

func toggleFavorite(_ item: MenuItem) async {
    let isFavorited = try await SupabaseManager.shared.toggleFavorite(menuItemId: item.id)
    // Update local state
    await fetchFavorites()
}
```

#### **C. FavoritesView (UI Updates):**
- Add loading indicator
- Add pull to refresh
- Show empty state
- Handle errors gracefully

### **Data Flow:**
```
User taps heart icon
    ↓
FavoritesViewModel.toggleFavorite()
    ↓
SupabaseManager.toggleFavorite()
    ↓
INSERT/DELETE in user_favorites table
    ↓
Refresh favorites list
    ↓
UI updates
```

### **Files to Modify:**
1. ✅ `SupabaseManager.swift` - Add methods
2. ✅ `FavoritesViewModel.swift` - Replace mock logic
3. ✅ `FavoritesView.swift` - Add loading/error states

---

## 🎯 **FEATURE 2: DIETARY PREFERENCES**

### **Current State:**
```swift
// ProfileViewModel.swift:74-78
private func saveProfile() {
    if let encoded = try? JSONEncoder().encode(profile) {
        UserDefaults.standard.set(encoded, forKey: profileKey)  // ❌ LOCAL ONLY
    }
}
```

### **Changes Needed:**

#### **A. SupabaseManager (New Methods):**
```swift
// 1. Get user profile
func getUserProfile() async throws -> UserProfile

// 2. Update dietary preferences
func updateUserProfile(profile: UserProfile) async throws

// 3. Sync profile
func syncUserProfile() async throws -> UserProfile
```

#### **B. ProfileViewModel (Updates):**
```swift
// Add Supabase sync
func updateDietaryPreferences(_ preferences: Set<DietaryTag>) async {
    profile.dietaryPreferences = preferences

    // Save to Supabase
    try await SupabaseManager.shared.updateUserProfile(profile)

    // Also cache locally
    saveProfileLocally()
}

func fetchProfile() async {
    profile = try await SupabaseManager.shared.getUserProfile()
    saveProfileLocally()  // Cache for offline
}
```

### **Data Flow:**
```
User updates preferences
    ↓
ProfileViewModel.updateDietaryPreferences()
    ↓
SupabaseManager.updateUserProfile()
    ↓
UPDATE user_profiles table
    ↓
Cache in UserDefaults
    ↓
UI updates
```

### **Files to Modify:**
1. ✅ `SupabaseManager.swift` - Add profile methods
2. ✅ `ProfileViewModel.swift` - Add sync logic
3. ✅ `DietaryPreferencesView.swift` - Add loading states

---

## 🎯 **FEATURE 3: ADDRESSES**

### **Current State:**
- ❌ Not implemented at all
- No ViewModel, no View, no data layer

### **Changes Needed:**

#### **A. Create Address Model:**
```swift
struct Address: Identifiable, Codable {
    let id: String
    let userId: String
    var label: String  // "Home", "Work"
    var streetAddress: String
    var apartment: String?
    var city: String
    var state: String
    var zipCode: String
    var phoneNumber: String?
    var deliveryInstructions: String?
    var isDefault: Bool
    let createdAt: Date
    let updatedAt: Date
}
```

#### **B. Create AddressViewModel:**
```swift
@MainActor
class AddressViewModel: ObservableObject {
    @Published var addresses: [Address] = []
    @Published var isLoading = false

    func fetchAddresses() async
    func addAddress(_ address: Address) async throws
    func updateAddress(_ address: Address) async throws
    func deleteAddress(_ address: Address) async throws
    func setDefaultAddress(_ address: Address) async throws
}
```

#### **C. SupabaseManager (New Methods):**
```swift
func getUserAddresses() async throws -> [Address]
func addAddress(_ address: Address) async throws
func updateAddress(_ address: Address) async throws
func deleteAddress(_ addressId: String) async throws
func setDefaultAddress(_ addressId: String) async throws
```

#### **D. Create AddressesView:**
```swift
struct AddressesView: View {
    @StateObject var viewModel = AddressViewModel()
    @State private var showAddAddress = false

    var body: some View {
        // List of addresses
        // Add/Edit/Delete functionality
        // Set default address
    }
}

struct AddAddressView: View {
    // Form to add new address
    // Validation
    // Save button
}
```

### **Files to Create:**
1. ✅ `Models.swift` - Add Address model (or update existing)
2. ✅ `AddressViewModel.swift` - New file
3. ✅ `AddressesView.swift` - New file
4. ✅ `AddAddressView.swift` - New file
5. ✅ `SupabaseManager.swift` - Add address methods

---

## 🎯 **FEATURE 4: SETTINGS SYNC**

### **Current State:**
```swift
// AppSettings.swift (assumed)
@Published var isDarkMode: Bool {
    didSet { UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode") }
}
```

### **Changes Needed:**

#### **A. Map Settings to UserProfile:**
```swift
// Add to user_profiles table:
- preferred_order_type: String
- default_store_id: Int
- email_notifications: Bool
- push_notifications: Bool
- marketing_emails: Bool
```

#### **B. SupabaseManager (New Methods):**
```swift
func updateUserSettings(settings: UserSettings) async throws
func getUserSettings() async throws -> UserSettings
```

#### **C. AppSettings (Updates):**
```swift
// Add sync method
func syncToSupabase() async {
    let settings = UserSettings(
        preferredOrderType: self.preferredOrderType,
        defaultStoreId: self.defaultStoreId,
        emailNotifications: self.emailNotifications
    )
    try await SupabaseManager.shared.updateUserSettings(settings)
}

// Auto-sync on change
var isDarkMode: Bool {
    didSet {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        Task { await syncToSupabase() }
    }
}
```

### **Files to Modify:**
1. ✅ `AppSettings.swift` - Add sync logic
2. ✅ `SupabaseManager.swift` - Add settings methods

---

## 🔧 **IMPLEMENTATION STEPS:**

### **Step 1: Database Migration** ✅
```bash
# Already created: database-migrations/002_user_profile_system.sql
# Run in Supabase SQL Editor
```

### **Step 2: SupabaseManager Foundation** ⏳
Add all helper methods at once:
- Favorites methods (3 methods)
- Profile methods (3 methods)
- Address methods (5 methods)
- Settings methods (2 methods)

**Total:** 13 new methods in SupabaseManager

### **Step 3: Implement Favorites** ⏳
1. Update SupabaseManager
2. Update FavoritesViewModel
3. Update FavoritesView
4. Test

### **Step 4: Implement Dietary Preferences** ⏳
1. Update SupabaseManager (if not done in Step 2)
2. Update ProfileViewModel
3. Update DietaryPreferencesView
4. Test

### **Step 5: Implement Addresses** ⏳
1. Create Address model
2. Create AddressViewModel
3. Create AddressesView
4. Create AddAddressView
5. Wire up to ProfileView
6. Test

### **Step 6: Implement Settings Sync** ⏳
1. Update AppSettings
2. Add sync methods to SupabaseManager
3. Test

### **Step 7: Final Testing** ⏳
1. Build project
2. Test each feature
3. Verify Supabase data
4. Test offline mode (cache)

---

## 📊 **TIME BREAKDOWN:**

| Task | Estimated | Actual | Status |
|------|-----------|--------|--------|
| Database Migration | 5 min | - | ⏳ |
| SupabaseManager Foundation | 30 min | - | ⏳ |
| Favorites Implementation | 1 hour | - | ⏳ |
| Dietary Preferences | 30 min | - | ⏳ |
| Addresses Implementation | 2 hours | - | ⏳ |
| Settings Sync | 1 hour | - | ⏳ |
| Testing & Fixes | 30 min | - | ⏳ |
| **TOTAL** | **5.5 hours** | - | ⏳ |

---

## ✅ **SUCCESS CRITERIA:**

### **Favorites:**
- [ ] Can add/remove favorites
- [ ] Favorites persist in Supabase
- [ ] Favorites sync across devices
- [ ] Works offline (cached)

### **Dietary Preferences:**
- [ ] Can update preferences
- [ ] Preferences save to Supabase
- [ ] Preferences sync across devices
- [ ] Allergen warnings still work

### **Addresses:**
- [ ] Can add new address
- [ ] Can edit address
- [ ] Can delete address
- [ ] Can set default address
- [ ] Addresses persist in Supabase

### **Settings:**
- [ ] Settings save to Supabase
- [ ] Settings sync across devices
- [ ] Still works offline

---

## 🚨 **KNOWN LIMITATIONS:**

### **What We're NOT Doing:**
1. ❌ Payment Methods - Needs Stripe integration
2. ❌ Push Notifications - Needs APNs setup
3. ❌ Real-time sync - Simple load/save for now
4. ❌ Conflict resolution - Last write wins

### **Future Enhancements:**
- Add real-time listeners for profile changes
- Add optimistic updates for better UX
- Add conflict resolution for multi-device
- Add undo/redo for changes

---

## 📝 **TESTING PLAN:**

### **Test 1: Favorites**
```
1. Login to app
2. Browse menu
3. Tap heart on 3 items
4. Go to Favorites tab → See 3 items ✅
5. Check Supabase → user_favorites has 3 rows ✅
6. Logout and login → Favorites still there ✅
7. Remove 1 favorite → Supabase updated ✅
```

### **Test 2: Dietary Preferences**
```
1. Go to Profile → Dietary Preferences
2. Select "Vegetarian" and "Gluten Free"
3. Add allergen: "Peanuts"
4. Save
5. Check Supabase → user_profiles updated ✅
6. Restart app → Preferences still there ✅
7. Menu items show warnings for allergens ✅
```

### **Test 3: Addresses**
```
1. Go to Profile → Addresses
2. Add new address "Home"
3. Set as default ✅
4. Add second address "Work"
5. Check Supabase → user_addresses has 2 rows ✅
6. Edit "Home" address
7. Delete "Work" address
8. Verify Supabase updated ✅
```

### **Test 4: Settings**
```
1. Change notification preferences
2. Select default store
3. Check Supabase → user_profiles updated ✅
4. Logout/Login → Settings persist ✅
```

---

## 🚀 **LET'S START!**

**Next Action:**
1. Run database migration in Supabase
2. I'll start implementing SupabaseManager methods
3. Then go feature by feature

**Ready?** Let me know when migration is ready, and I'll begin! 🎊
