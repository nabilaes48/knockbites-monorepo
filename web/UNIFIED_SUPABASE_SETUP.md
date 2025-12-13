# Unified Supabase Setup - One Backend for All Platforms
## Web + iOS + Android + Local Development - Single Supabase Instance

---

## Overview: One Supabase Instance, Everywhere

You're using **Supabase Cloud** (`jwcuebbhkwwilqfblecq.supabase.co`), which is the PERFECT approach for your ecosystem. Here's why:

### Benefits of Single Supabase Instance

✅ **One Source of Truth**
- Web app, iOS app, Android app all use the SAME database
- Staff updates menu in dashboard → Changes appear INSTANTLY on all apps
- Customer places order on iOS → Appears IMMEDIATELY in web dashboard

✅ **Real-Time Synchronization**
- All platforms subscribe to the same Supabase Realtime channels
- Order status updates broadcast to ALL connected devices
- Zero delay, true real-time experience

✅ **Cost Effective**
- Free tier: 500MB database, 1GB storage, 50GB bandwidth
- Serves unlimited devices and platforms
- Only pay when you scale past free tier ($25/month for Pro)

✅ **Simple Management**
- One dashboard to manage everything
- One set of migrations
- One backup strategy
- One security policy (RLS)

✅ **Development & Production**
- Use SAME Supabase instance for local development
- No need for separate "local Supabase"
- Test with real data in development mode
- Safe with RLS policies protecting data

---

## Current Setup (Already Perfect!)

### Your Supabase Cloud Instance

**Project:** Cameron's Connect
**URL:** `https://jwcuebbhkwwilqfblecq.supabase.co`
**Region:** Probably US (check in Supabase dashboard)
**Status:** ✅ Production-ready

**What's Already Working:**
- 45 migrations applied
- 61 menu items loaded
- 41 images in Supabase Storage
- RLS policies protecting data
- Real-time subscriptions enabled
- Authentication configured

---

## Platform Configuration Guide

### 1. Web Application (React/Vite) ✅ CONFIGURED

**Location:** `/Users/nabilimran/camerons-connect`

**Environment File:** `.env.local`
```bash
VITE_SUPABASE_URL=https://jwcuebbhkwwilqfblecq.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Client Configuration:** `src/lib/supabase.ts`
```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storage: window.localStorage,
  },
  realtime: {
    params: {
      eventsPerSecond: 10,
    },
  },
})
```

**Status:** ✅ Working perfectly

---

### 2. iOS Application (Swift/SwiftUI) ⚠️ NEEDS CONFIGURATION

**Required:** Swift Supabase SDK
```swift
// In your Package.swift or SPM dependencies:
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
]
```

**Configuration:** Create `Config.swift` or use `.xcconfig`

#### Option A: Config.swift (Recommended)
```swift
// Config.swift
enum Config {
    static let supabaseURL = URL(string: "https://jwcuebbhkwwilqfblecq.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Option B: Info.plist
```xml
<!-- Info.plist -->
<key>SUPABASE_URL</key>
<string>https://jwcuebbhkwwilqfblecq.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...</string>
```

**Supabase Client:** Create in your App entry point
```swift
// CameronsConnectApp.swift or AppDelegate.swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: Config.supabaseURL,
    supabaseKey: Config.supabaseAnonKey,
    options: SupabaseClientOptions(
        db: SupabaseClientOptions.DatabaseOptions(
            schema: "public"
        ),
        auth: SupabaseClientOptions.AuthOptions(
            storage: .standard,
            autoRefreshToken: true,
            persistSession: true
        ),
        realtime: SupabaseClientOptions.RealtimeOptions(
            timeout: 10
        )
    )
)
```

**Make Available App-Wide:**
```swift
// Add to @main App struct or use dependency injection
@main
struct CameronsConnectApp: App {
    let supabase: SupabaseClient

    init() {
        self.supabase = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabase)
        }
    }
}
```

**Usage in Views:**
```swift
// MenuView.swift
import SwiftUI
import Supabase

struct MenuView: View {
    @EnvironmentObject var supabase: SupabaseClient
    @State private var menuItems: [MenuItem] = []

    var body: some View {
        List(menuItems) { item in
            MenuItemRow(item: item)
        }
        .task {
            await loadMenu()
        }
    }

    func loadMenu() async {
        do {
            let response: [MenuItem] = try await supabase
                .from("menu_items")
                .select()
                .eq("available", true)
                .order("name")
                .execute()
                .value

            menuItems = response
        } catch {
            print("Error loading menu: \(error)")
        }
    }
}
```

---

### 3. Android Application (Kotlin/Jetpack Compose) ⏳ FUTURE

**Required:** Supabase Kotlin SDK
```kotlin
// build.gradle.kts
dependencies {
    implementation("io.github.jan-tennert.supabase:supabase-kt:2.0.0")
    implementation("io.github.jan-tennert.supabase:postgrest-kt:2.0.0")
    implementation("io.github.jan-tennert.supabase:realtime-kt:2.0.0")
    implementation("io.github.jan-tennert.supabase:auth-kt:2.0.0")
}
```

**Configuration:**
```kotlin
// SupabaseClient.kt
object SupabaseClient {
    val client = createSupabaseClient(
        supabaseUrl = "https://jwcuebbhkwwilqfblecq.supabase.co",
        supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    ) {
        install(Postgrest)
        install(Auth) {
            autoSaveToStorage = true
            autoLoadFromStorage = true
        }
        install(Realtime)
    }
}
```

**Usage:**
```kotlin
// MenuViewModel.kt
class MenuViewModel : ViewModel() {
    private val supabase = SupabaseClient.client

    val menuItems = MutableStateFlow<List<MenuItem>>(emptyList())

    suspend fun loadMenu() {
        val response = supabase
            .from("menu_items")
            .select()
            .eq("available", true)
            .decodeList<MenuItem>()

        menuItems.value = response
    }
}
```

---

### 4. Local Development (All Platforms) ✅ CURRENT APPROACH

**Current Setup:** Using Supabase Cloud for local development

**Benefits:**
- Same data as production (or separate project if desired)
- Real-time works out of the box
- No local server setup needed
- Test with real network conditions

**Running Locally:**
```bash
# Web app
cd /Users/nabilimran/camerons-connect
npm run dev
# Runs at http://localhost:8081

# iOS app (in Xcode)
# Uses same Supabase URL/Key
# Connect iPhone to Mac or use Simulator
```

**Environment Variables:**
- Web: `.env.local` (already set up)
- iOS: `Config.swift` or `Info.plist`
- Both use SAME credentials

---

## Real-Time Synchronization Examples

### Example 1: Order Placed on iOS → Shows in Web Dashboard

**iOS (Customer App):**
```swift
// OrderView.swift
func placeOrder() async {
    let newOrder = [
        "customer_name": customerName,
        "customer_phone": customerPhone,
        "store_id": 1,
        "status": "pending",
        "total": cartTotal
    ]

    try await supabase
        .from("orders")
        .insert(newOrder)
        .execute()

    // Order inserted into database
}
```

**Web (Staff Dashboard):**
```typescript
// OrderManagement.tsx
useEffect(() => {
  // Subscribe to new orders
  const channel = supabase
    .channel('orders-channel')
    .on('postgres_changes', {
      event: 'INSERT',
      schema: 'public',
      table: 'orders',
      filter: `store_id=eq.1`
    }, (payload) => {
      // New order appears INSTANTLY
      setOrders(prev => [payload.new, ...prev])
      playNotificationSound()
    })
    .subscribe()

  return () => supabase.removeChannel(channel)
}, [])
```

**Result:** Order appears in dashboard within 100-300ms!

---

### Example 2: Staff Updates Order Status → Customer iOS App Updates

**Web (Staff Dashboard):**
```typescript
// OrderManagement.tsx
const updateOrderStatus = async (orderId: number, status: string) => {
  await supabase
    .from('orders')
    .update({ status })
    .eq('id', orderId)

  // Status updated in database
}
```

**iOS (Customer App):**
```swift
// OrderTrackingView.swift
func subscribeToOrderUpdates() {
    supabase.realtime
        .channel("order:\(orderId)")
        .on(.postgresChanges(
            event: .update,
            schema: "public",
            table: "orders",
            filter: "id=eq.\(orderId)"
        )) { payload in
            // Update UI instantly
            if let order = payload.new as? Order {
                self.orderStatus = order.status
            }
        }
        .subscribe()
}
```

**Result:** Customer sees "Preparing" → "Ready" in real-time!

---

### Example 3: Staff Updates Menu → Changes on All Apps

**Web (Staff Dashboard):**
```typescript
// MenuManagement.tsx
const updateMenuItem = async (itemId: number, updates: any) => {
  await supabase
    .from('menu_items')
    .update(updates)
    .eq('id', itemId)

  // Menu updated in database
}
```

**iOS (Customer App):**
```swift
// MenuView.swift
func subscribeToMenuChanges() {
    supabase.realtime
        .channel("menu-updates")
        .on(.postgresChanges(
            event: .update,
            schema: "public",
            table: "menu_items"
        )) { payload in
            // Refresh menu
            Task {
                await loadMenu()
            }
        }
        .subscribe()
}
```

**Result:** Menu changes appear instantly on all customer apps!

---

## Database Access Examples

### Fetching Menu Items (Same Query, Every Platform)

**Web (TypeScript):**
```typescript
const { data, error } = await supabase
  .from('menu_items')
  .select('*')
  .eq('available', true)
  .order('name')
```

**iOS (Swift):**
```swift
let menuItems: [MenuItem] = try await supabase
    .from("menu_items")
    .select()
    .eq("available", true)
    .order("name")
    .execute()
    .value
```

**Android (Kotlin):**
```kotlin
val menuItems = supabase
    .from("menu_items")
    .select()
    .eq("available", true)
    .order("name")
    .decodeList<MenuItem>()
```

**Same database, same query, same data!**

---

## Security: How RLS Protects Your Data

### Row Level Security (RLS) Works Across ALL Platforms

**Anonymous Users (Customers):**
```sql
-- Can read menu
CREATE POLICY "Anyone can view available menu items"
ON menu_items FOR SELECT
TO anon
USING (available = true);

-- Can create orders
CREATE POLICY "Anyone can create orders"
ON orders FOR INSERT
TO anon
WITH CHECK (true);
```

**Authenticated Staff:**
```sql
-- Can manage menu
CREATE POLICY "Staff can manage menu items"
ON menu_items FOR ALL
TO authenticated
USING (auth.role() = 'staff');

-- Can view/update orders
CREATE POLICY "Staff can manage orders"
ON orders FOR ALL
TO authenticated
USING (auth.role() = 'staff');
```

**How It Works:**
- Web app uses anon key → Can only read menu, create orders
- Staff logs in → Gets authenticated token → Can manage everything
- iOS customer app uses anon key → Same permissions as web
- iOS staff app with login → Same permissions as web staff dashboard
- Supabase enforces these rules at DATABASE LEVEL (can't bypass!)

---

## Testing the Unified Setup

### Quick Test: All Platforms Working Together

**Step 1: Start Web App**
```bash
cd /Users/nabilimran/camerons-connect
npm run dev
# Open http://localhost:8081
```

**Step 2: Open iOS App (Simulator or Device)**
```bash
# In Xcode:
# 1. Open your iOS project
# 2. Set your Mac's IP address if using device: http://YOUR_MAC_IP:8081
# 3. Run app (Cmd+R)
```

**Step 3: Test Real-Time Sync**

1. **Web Dashboard:** Log in as staff
2. **iOS Customer App:** Browse menu
3. **Web Dashboard:** Toggle a menu item availability OFF
4. **iOS Customer App:** Menu refreshes, item disappears
5. **iOS Customer App:** Place an order
6. **Web Dashboard:** Order appears instantly with notification
7. **Web Dashboard:** Mark order as "Preparing"
8. **iOS Customer App:** Order tracking shows "Preparing" status

**Result:** Everything syncs in real-time across all platforms!

---

## Network Configuration for iOS Testing

### Testing iOS App with Local Web Server

**Problem:** iOS device can't access `localhost:8081`

**Solution 1: Use Your Mac's IP Address**

1. **Find Your Mac's IP:**
```bash
# macOS
ipconfig getifaddr en0  # WiFi
# or
ipconfig getifaddr en1  # Ethernet
# Example output: 192.168.1.100
```

2. **Update Vite Config** (for iOS to access dev server):
```typescript
// vite.config.ts
export default defineConfig({
  server: {
    host: '0.0.0.0',  // Listen on all interfaces
    port: 8081,
    strictPort: true,
  }
})
```

3. **Restart Dev Server:**
```bash
npm run dev
# Now accessible at:
# - http://localhost:8081 (Mac)
# - http://192.168.1.100:8081 (iPhone on same WiFi)
```

4. **iOS App Already Uses Supabase Cloud:**
- No need to change anything!
- Supabase URL is `https://jwcuebbhkwwilqfblecq.supabase.co` (public internet)
- Works from anywhere: local, office, home, App Store

**Solution 2: Use Supabase Only (Recommended for App Store)**
- Don't connect to local web server
- Use Supabase Cloud API directly
- Web dashboard runs on local machine (staff only)
- iOS customer app connects directly to Supabase
- Both see same data, no network issues

---

## Production Deployment (Same Supabase Instance!)

### Web App Deployment

**Current:** http://localhost:8081 (local only)
**Deploy To:** Vercel, Netlify, or Cloudflare Pages

**Environment Variables (Production):**
```bash
# Same as local!
VITE_SUPABASE_URL=https://jwcuebbhkwwilqfblecq.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Deploy to Vercel:**
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd /Users/nabilimran/camerons-connect
vercel

# Add environment variables in Vercel dashboard
# Project Settings → Environment Variables
# Add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
```

**Result:**
- Production URL: https://cameronsconnect.vercel.app
- Same Supabase backend
- Same data as iOS app
- Real-time sync works

---

### iOS App Deployment

**TestFlight / App Store:**
- Use SAME Supabase URL and anon key
- No changes needed
- Submit to App Store

**Configuration:**
```swift
// Config.swift (same for dev and production)
enum Config {
    static let supabaseURL = URL(string: "https://jwcuebbhkwwilqfblecq.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Optional: Environment-Specific Config**
```swift
// Config.swift (if you want separate dev/prod)
enum Config {
    #if DEBUG
    static let supabaseURL = URL(string: "https://jwcuebbhkwwilqfblecq.supabase.co")!
    #else
    static let supabaseURL = URL(string: "https://jwcuebbhkwwilqfblecq.supabase.co")!
    #endif

    // Same URL! Or use different Supabase project for staging
}
```

---

## Cost Implications

### Single Supabase Instance Cost

**Free Tier (Current):**
- 500MB database storage
- 1GB file storage (Supabase Storage)
- 50GB bandwidth/month
- Unlimited API requests
- Unlimited real-time connections (with some limits)
- 2 GB RAM for database

**Expected Usage (Single Store):**
- Database: ~50MB (menu items, orders, customers)
- Storage: ~100MB (menu images)
- Bandwidth: ~5-10GB/month (web + iOS traffic)
- **Cost: $0/month** ✅

**When to Upgrade to Pro ($25/month):**
- Database >500MB (thousands of orders)
- Storage >1GB (more menu images)
- Bandwidth >50GB/month (viral growth!)
- Need >2GB RAM for database

**Multi-Store Scaling (All 29 Locations):**
- Database: ~100-200MB
- Storage: ~500MB (all store images)
- Bandwidth: ~20-30GB/month
- **Cost: Still free tier!** ✅
- Only upgrade if >10,000 orders/month

---

## Alternative: Separate Environments (Not Recommended)

If you wanted separate dev/staging/production (you don't need this):

### Multiple Supabase Projects

**Development:**
- Project: `camerons-dev`
- URL: `https://camerons-dev.supabase.co`
- Test data, no real customers

**Production:**
- Project: `camerons-prod`
- URL: `https://jwcuebbhkwwilqfblecq.supabase.co` (current)
- Real customer data

**Cost:** Free if both under limits, $25/month each if over

**Why We Don't Need This:**
- RLS protects production data
- Can use same instance for dev (just don't delete production data!)
- Single instance is simpler and cheaper

---

## Troubleshooting

### Issue: iOS App Can't Connect to Supabase

**Symptoms:** Network errors, "Invalid API key", timeouts

**Solutions:**

1. **Check URL/Key:**
```swift
print("Supabase URL: \(Config.supabaseURL)")
print("Anon Key: \(Config.supabaseAnonKey)")
// Should match .env.local exactly
```

2. **Check Info.plist App Transport Security:**
```xml
<!-- Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <!-- Supabase uses HTTPS, so no need for insecure loads -->
</dict>
```

3. **Test with curl:**
```bash
curl https://jwcuebbhkwwilqfblecq.supabase.co/rest/v1/menu_items \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
# Should return menu items JSON
```

4. **Check Supabase Dashboard:**
- https://supabase.com/dashboard
- Project Settings → API
- Verify URL and anon key match

---

### Issue: Real-Time Not Working

**Symptoms:** Order status doesn't update, menu changes not live

**Solutions:**

1. **Enable Realtime on Table:**
```sql
-- In Supabase SQL Editor
ALTER TABLE orders REPLICA IDENTITY FULL;
ALTER TABLE menu_items REPLICA IDENTITY FULL;
```

2. **Check RLS Policies:**
```sql
-- Users must have SELECT permission for real-time
-- Check in Supabase Dashboard → Authentication → Policies
```

3. **Verify Channel Subscription:**
```typescript
// Web
const channel = supabase
  .channel('orders')
  .on('postgres_changes', { /* ... */ }, (payload) => {
    console.log('Received:', payload)  // Should log on changes
  })
  .subscribe((status) => {
    console.log('Subscription status:', status)  // Should be "SUBSCRIBED"
  })
```

4. **Check Connection:**
```typescript
// Monitor connection status
supabase.auth.onAuthStateChange((event, session) => {
  console.log('Auth event:', event, session)
})
```

---

### Issue: Environment Variables Not Loading

**Web (Vite):**
```bash
# Must restart dev server after changing .env.local
npm run dev

# Verify variables are loaded
console.log(import.meta.env.VITE_SUPABASE_URL)
```

**iOS:**
```swift
// Rebuild app after changing Config.swift
// Clean build folder: Cmd+Shift+K
// Rebuild: Cmd+B
```

---

## Summary: Your Perfect Setup

### What You Have (Already Working)

✅ **One Supabase Cloud Instance**
- URL: `https://jwcuebbhkwwilqfblecq.supabase.co`
- Shared across ALL platforms
- Production-ready, 99.9% uptime
- Free tier (plenty of capacity)

✅ **Web App Connected**
- Running at http://localhost:8081
- Real-time working
- Staff dashboard functional
- Modern analytics charts

✅ **Database Complete**
- 45 migrations applied
- 61 menu items
- 41 images in storage
- RLS policies enforced

### What You Need to Do

⚠️ **iOS App Configuration** (10 minutes)
1. Add Supabase Swift SDK to Xcode project
2. Create `Config.swift` with URL and anon key
3. Initialize SupabaseClient in App entry point
4. Test connection with simple query

⚠️ **Test Real-Time Sync** (5 minutes)
1. Run web app (already running)
2. Run iOS app in simulator
3. Create order on iOS
4. Verify appears in web dashboard
5. Update status in web dashboard
6. Verify updates on iOS

⚠️ **Deploy Web App** (30 minutes)
1. Sign up for Vercel (free)
2. Connect GitHub repo
3. Add environment variables
4. Deploy
5. Test at production URL

### Result

🎯 **One Unified Ecosystem**
- Web, iOS, (future Android) all use same Supabase backend
- Real-time sync across all platforms (100-300ms latency)
- Data stays consistent everywhere
- Staff updates propagate instantly to all customers
- Simple to manage, cost-effective to scale
- Ready for App Store submission

**You're already 90% there!** 🚀

---

## Quick Reference Card

### Essential Credentials

**Supabase Project:**
- URL: `https://jwcuebbhkwwilqfblecq.supabase.co`
- Anon Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- Dashboard: https://supabase.com/dashboard

**Web App:**
- Local: http://localhost:8081
- Production: (to be deployed)

**iOS App:**
- Uses same Supabase credentials
- TestFlight: (to be distributed)
- App Store: (future)

### Key Files

**Web:**
- `.env.local` - Environment variables
- `src/lib/supabase.ts` - Supabase client

**iOS:**
- `Config.swift` - Supabase credentials
- `SupabaseClient.swift` - Client initialization

### Common Commands

```bash
# Start web dev server
npm run dev

# Deploy to Vercel
vercel

# Check Supabase connection
curl https://jwcuebbhkwwilqfblecq.supabase.co/rest/v1/menu_items \
  -H "apikey: YOUR_ANON_KEY"
```

---

**Document Version:** 1.0
**Date:** November 24, 2025
**Status:** Complete Guide
**Next Update:** After iOS app integration testing
