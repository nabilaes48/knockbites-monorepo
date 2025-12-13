# Cameron's Restaurant Management System
## Completion Roadmap - Phased Implementation Plan

**Last Updated:** November 19, 2025
**Current Progress:** ~75% Complete
**Philosophy:** Real Supabase data only, no mock data
**Total Timeline:** 10-12 weeks to full completion

---

## 📊 Current Status Overview

### ✅ Fully Implemented (Production-Ready)
- Authentication & User Management (Supabase Auth)
- Dashboard & Order Management (Real orders from database)
- Kitchen Display System (Drag-and-drop Kanban with persistence)
- Menu Management (CRUD operations with Supabase)
- Business Reports Analytics (Real-time charts with actual data)
- Store Analytics Dashboard (Multi-location performance metrics)
- Database Schema (Migrations 001, 002, 024)

### 🟡 Partially Implemented (UI Done, Needs Data)
- Marketing System (UIs built, ViewModels need Supabase integration)
- Notifications Analytics (UI complete, shows zeros)
- Export System (PDF/CSV infrastructure exists, charts show placeholders)
- Multi-Store Features (Basic support, needs expansion)

### ❌ Not Started
- Push Notification Sending Infrastructure
- Real-time Order Synchronization (Supabase Realtime)
- Customer-Facing iOS App
- Advanced automation features

---

## 🎯 Phase 1: Complete Core Analytics (Week 1)
**Goal:** Finish analytics suite with 100% real data
**Duration:** 3-5 days
**Effort:** Medium
**Dependencies:** Migration 024 must be run in Supabase

### Phase 1.1: Notifications Analytics Service (Day 1)
**Deliverables:**
- [ ] Create `NotificationsService.swift` in `/Services/`
- [ ] Implement queries for push_notifications table:
  ```swift
  - getTotalSentCount(storeId:, period:)
  - getDeliveryRate(storeId:, period:)
  - getOpenRate(storeId:, period:)
  - getClickRate(storeId:, period:)
  - getDeliverySuccessOverTime(storeId:, period:)
  - getPlatformDistribution(storeId:, period:)
  - getHourlySendPerformance(storeId:, period:)
  - getRecentNotifications(storeId:, limit:)
  ```
- [ ] Add error handling with graceful fallbacks
- [ ] Test with empty database (should show zeros, not crash)

**Files to Create:**
- `/camerons-Bussiness-app/Services/NotificationsService.swift`

**Files to Update:**
- `/camerons-Bussiness-app/Core/More/NotificationsAnalyticsView.swift` (line 573: remove TODO)

**Success Criteria:**
- ✅ NotificationsAnalyticsView loads without errors
- ✅ Shows zeros when no notification data exists
- ✅ Shows real metrics when test notifications added to database

---

### Phase 1.2: Marketing Data Integration (Days 2-3)
**Goal:** Connect all marketing ViewModels to real Supabase data

**Deliverables:**
- [ ] Create `MarketingService.swift` for centralized queries
- [ ] Update `LoyaltyProgramViewModel` to use real data:
  - [ ] Fetch loyalty_programs, loyalty_tiers, customer_loyalty tables
  - [ ] CRUD operations for tiers and program settings
  - [ ] Calculate real tier distribution from customer_loyalty
- [ ] Update `CustomerLoyaltyViewModel`:
  - [ ] Real customer list with points/tier from database
  - [ ] Search functionality with Supabase query
  - [ ] Award points (write to loyalty_transactions)
- [ ] Update `ReferralProgramViewModel`:
  - [ ] Fetch referral_program settings
  - [ ] Get active referrals from referrals table
  - [ ] Calculate conversion rates from real data
- [ ] Update `MarketingAnalyticsViewModel`:
  - [ ] Coupon redemption stats from coupon_usage
  - [ ] Notification performance from push_notifications
  - [ ] Campaign ROI from automated_campaigns + orders
- [ ] Update `AutomatedCampaignsViewModel`:
  - [ ] Fetch automated_campaigns table
  - [ ] Track executions in campaign_executions
  - [ ] Real performance metrics
- [ ] Update `CustomerSegmentsViewModel`:
  - [ ] Build segments from real customer/order data
  - [ ] Dynamic filtering based on actual behavior

**Files to Create:**
- `/camerons-Bussiness-app/Services/MarketingService.swift`

**Files to Update:**
- `/camerons-Bussiness-app/Core/Marketing/MarketingViewModels.swift` (all ViewModels)
- `/camerons-Bussiness-app/Core/Marketing/LoyaltyProgramView.swift`
- `/camerons-Bussiness-app/Core/Marketing/CustomerLoyaltyView.swift`
- `/camerons-Bussiness-app/Core/Marketing/ReferralProgramView.swift`
- `/camerons-Bussiness-app/Core/Marketing/MarketingAnalyticsView.swift`
- `/camerons-Bussiness-app/Core/Marketing/AutomatedCampaignsView.swift`
- `/camerons-Bussiness-app/Core/Marketing/CustomerSegmentsView.swift`

**Success Criteria:**
- ✅ All marketing screens show real data from Supabase
- ✅ Loyalty tiers can be created/edited/deleted
- ✅ Points can be awarded and tracked in database
- ✅ Referral codes generate and track conversions
- ✅ Segments filter customers based on actual order history
- ✅ Zero mock data anywhere in marketing module

---

### Phase 1.3: Export System Chart Rendering (Day 4)
**Goal:** Replace chart placeholders with actual graphics in PDFs

**Deliverables:**
- [ ] Implement `renderChartToImage()` function:
  ```swift
  - Takes SwiftUI Chart view
  - Renders to CGImage using ImageRenderer
  - Returns UIImage for PDF embedding
  ```
- [ ] Update `ReportExporter.drawChart()` (line 366):
  - [ ] Remove placeholder text rendering
  - [ ] Embed actual chart images
  - [ ] Handle chart sizing and positioning
- [ ] Add export buttons:
  - [ ] BusinessReportsView: "Export Report" button (line 279)
  - [ ] StoreAnalyticsView: "Export Analytics" button (line 413)
  - [ ] Implement share sheet for PDF/CSV
- [ ] Test all chart types:
  - [ ] Bar charts (revenue, categories, peak hours)
  - [ ] Line charts (daily performance, trends)
  - [ ] Donut charts (payment methods, order frequency)

**Files to Update:**
- `/camerons-Bussiness-app/Shared/ReportExporter.swift` (lines 152, 366-377)
- `/camerons-Bussiness-app/Shared/PDFReportTemplates.swift` (lines 513, 524, 546, 557)
- `/camerons-Bussiness-app/Core/More/BusinessReportsView.swift` (line 279)
- `/camerons-Bussiness-app/Core/More/StoreAnalyticsView.swift` (line 413)

**Success Criteria:**
- ✅ PDFs contain actual chart graphics, not placeholder boxes
- ✅ Export buttons functional with share sheet
- ✅ All chart types render correctly in PDF
- ✅ PDFs can be saved, emailed, or printed

---

### Phase 1.4: Historical Trend Calculations (Day 5)
**Goal:** Calculate percentage changes for KPI cards

**Deliverables:**
- [ ] Implement trend calculation for BusinessReportsView (line 104):
  - [ ] Compare current period to previous period
  - [ ] Calculate % change for revenue, orders, AOV
  - [ ] Add trend indicators (↑↓) based on change direction
- [ ] Implement fulfillment time change for StoreAnalyticsView (line 55):
  - [ ] Track average fulfillment time week-over-week
  - [ ] Show improvement/degradation percentage
- [ ] Add database queries for historical comparisons:
  - [ ] Previous day/week/month metrics
  - [ ] Year-over-year comparisons

**Files to Update:**
- `/camerons-Bussiness-app/Core/More/BusinessReportsView.swift` (line 104)
- `/camerons-Bussiness-app/Core/More/StoreAnalyticsView.swift` (line 55)
- `/camerons-Bussiness-app/Services/AnalyticsService.swift`

**Success Criteria:**
- ✅ KPI cards show "↑ 12%" style trend indicators
- ✅ Green for positive trends, red for negative
- ✅ Calculations based on real historical data
- ✅ Handles edge cases (no previous data, division by zero)

---

## 🔔 Phase 2: Push Notification Infrastructure (Week 2)
**Goal:** Enable staff to send push notifications to customers
**Duration:** 5-7 days
**Effort:** High
**Dependencies:** Phase 1 complete, Firebase/APNs account setup

### Phase 2.1: Firebase Cloud Messaging Setup (Days 1-2)
**Deliverables:**
- [ ] Create Firebase project for Cameron's Restaurant
- [ ] Add iOS app to Firebase (bundle ID: `com.-camerons.app.camerons-Bussiness-app`)
- [ ] Download `GoogleService-Info.plist`
- [ ] Add Firebase SDK to Xcode project:
  ```swift
  - FirebaseMessaging
  - FirebaseAnalytics
  ```
- [ ] Configure APNs certificates in Firebase Console
- [ ] Enable Push Notifications capability in Xcode
- [ ] Test push notification delivery to test device

**Files to Create:**
- `/camerons-Bussiness-app/GoogleService-Info.plist`
- `/camerons-Bussiness-app/Services/PushNotificationService.swift`

**Files to Update:**
- `/camerons-Bussiness-app/camerons_Bussiness_appApp.swift` (add Firebase initialization)
- `project.pbxproj` (add Push Notifications entitlement)

**Success Criteria:**
- ✅ App requests push notification permission on first launch
- ✅ Device token successfully registered with Firebase
- ✅ Test notification from Firebase Console reaches device
- ✅ Background/foreground notification handling works

---

### Phase 2.2: Notification Composer UI (Day 3)
**Goal:** Build UI for creating and sending notifications

**Deliverables:**
- [ ] Create `SendNotificationView.swift`:
  - [ ] Title input (200 char max)
  - [ ] Body text editor (multiline, 500 char max)
  - [ ] Image URL input (optional)
  - [ ] Action URL input (deep link to app screen)
  - [ ] Live preview showing how notification will appear
- [ ] Create targeting selector:
  - [ ] "All Customers" option
  - [ ] "Specific Loyalty Tier" picker
  - [ ] "Customer Segment" picker (use existing segments)
  - [ ] "Individual Customers" multi-select list
- [ ] Add scheduling options:
  - [ ] "Send Immediately" toggle
  - [ ] Date/time picker for scheduled delivery
  - [ ] "Optimal Time" suggestion (based on engagement analytics)
- [ ] Add campaign templates:
  - [ ] "Daily Special" template
  - [ ] "Order Ready" template
  - [ ] "Loyalty Reward" template
  - [ ] "We Miss You" re-engagement template
  - [ ] Custom template builder

**Files to Create:**
- `/camerons-Bussiness-app/Core/Marketing/SendNotificationView.swift`
- `/camerons-Bussiness-app/Core/Marketing/NotificationTemplates.swift`

**Files to Update:**
- `/camerons-Bussiness-app/Core/Marketing/MarketingDashboardView.swift` (add navigation)

**Success Criteria:**
- ✅ UI is intuitive and matches app design system
- ✅ Live preview updates as fields change
- ✅ Templates auto-fill fields correctly
- ✅ Validation prevents sending invalid notifications

---

### Phase 2.3: Notification Sending Logic (Days 4-5)
**Goal:** Implement backend logic to send notifications

**Deliverables:**
- [ ] Create Supabase Edge Function or use existing API:
  - [ ] Accept notification payload from iOS app
  - [ ] Query target customers based on criteria
  - [ ] Fetch device tokens for targeted users
  - [ ] Send to Firebase Cloud Messaging API
  - [ ] Write notification record to `push_notifications` table
  - [ ] Create `notification_deliveries` records for tracking
- [ ] Implement batching for large audiences:
  - [ ] Send in batches of 500 tokens
  - [ ] Progress tracking in app
  - [ ] Cancel option for in-progress sends
- [ ] Add webhook handlers:
  - [ ] Delivery confirmation from FCM
  - [ ] Open/click tracking
  - [ ] Update `notification_deliveries` status
  - [ ] Increment analytics counters in `push_notifications`
- [ ] Implement scheduled notifications:
  - [ ] Cron job checks for scheduled notifications
  - [ ] Sends at specified time
  - [ ] Updates status to 'sent'

**Files to Create:**
- `/supabase/functions/send-push-notification/index.ts` (Supabase Edge Function)

**Files to Update:**
- `/camerons-Bussiness-app/Services/PushNotificationService.swift`

**Success Criteria:**
- ✅ Notifications successfully sent to targeted users
- ✅ Delivery status tracked in database
- ✅ Analytics update when notifications opened/clicked
- ✅ Scheduled notifications send at correct time
- ✅ Batch sending handles 10,000+ users without timeout

---

### Phase 2.4: Device Token Management (Day 6)
**Goal:** Track customer device tokens for targeting

**Deliverables:**
- [ ] Create `device_tokens` table:
  ```sql
  - id, customer_id, token, platform (iOS/Android/Web)
  - last_used_at, created_at, is_active
  ```
- [ ] Create migration 025:
  - [ ] Create device_tokens table
  - [ ] Add indexes for fast lookups
  - [ ] Add foreign key to customers table
- [ ] Implement token registration:
  - [ ] Customer app sends token to backend on login
  - [ ] Upsert token (update if exists, insert if new)
  - [ ] Mark old tokens as inactive
- [ ] Implement token cleanup:
  - [ ] Remove tokens not used in 90 days
  - [ ] Remove tokens that failed delivery 5+ times

**Files to Create:**
- `/database/migrations/025_device_tokens.sql`

**Success Criteria:**
- ✅ Device tokens stored in database
- ✅ Tokens associate with correct customer accounts
- ✅ Inactive tokens pruned automatically
- ✅ Fast queries for notification targeting

---

### Phase 2.5: Testing & Analytics Integration (Day 7)
**Goal:** Ensure notifications work end-to-end and populate analytics

**Deliverables:**
- [ ] Send test notifications to real devices
- [ ] Verify analytics data populates NotificationsAnalyticsView:
  - [ ] Total sent count increments
  - [ ] Delivery rate calculates correctly
  - [ ] Open rate tracks taps
  - [ ] Click rate tracks action URL taps
- [ ] Test edge cases:
  - [ ] Notification to user with multiple devices
  - [ ] Notification when customer app not installed
  - [ ] Notification with invalid targeting criteria
  - [ ] Scheduled notification cancellation
- [ ] Load testing:
  - [ ] Send to 1,000 simulated users
  - [ ] Verify all deliveries tracked
  - [ ] Check database performance

**Success Criteria:**
- ✅ 95%+ delivery rate to active devices
- ✅ Analytics dashboards show real notification performance
- ✅ No data loss or tracking gaps
- ✅ System handles high volume without crashes

---

## ⚡ Phase 3: Real-Time Synchronization (Week 3)
**Goal:** Add Supabase Realtime for live updates across devices
**Duration:** 5-7 days
**Effort:** Medium-High
**Dependencies:** Supabase Realtime enabled on project

### Phase 3.1: Supabase Realtime Setup (Day 1)
**Deliverables:**
- [ ] Enable Realtime in Supabase Dashboard
- [ ] Configure Realtime policies for tables:
  - [ ] `orders` - staff can subscribe to their store's orders
  - [ ] `kitchen_orders` - kitchen staff see updates
  - [ ] `menu_items` - all staff see menu availability changes
- [ ] Create `RealtimeService.swift`:
  ```swift
  - subscribeToOrders(storeId:, callback:)
  - subscribeToKitchenOrders(storeId:, callback:)
  - subscribeToMenuItems(storeId:, callback:)
  - unsubscribeAll()
  ```
- [ ] Test subscription connects and receives events

**Files to Create:**
- `/camerons-Bussiness-app/Services/RealtimeService.swift`

**Success Criteria:**
- ✅ Realtime subscriptions connect successfully
- ✅ Callback fires when database changes
- ✅ Subscriptions auto-reconnect on network issues

---

### Phase 3.2: Dashboard Real-Time Updates (Days 2-3)
**Deliverables:**
- [ ] Update `DashboardViewModel`:
  - [ ] Subscribe to orders on appear
  - [ ] Insert new orders at top when received
  - [ ] Update order status when changed
  - [ ] Play sound/haptic for new orders
  - [ ] Show toast notification for updates
- [ ] Add "Live" indicator in UI:
  - [ ] Green dot when connected
  - [ ] Red dot when disconnected
  - [ ] Auto-reconnect logic
- [ ] Implement optimistic updates:
  - [ ] Update UI immediately on action
  - [ ] Rollback if server rejects change
  - [ ] Show loading state during sync

**Files to Update:**
- `/camerons-Bussiness-app/Core/Dashboard/DashboardViewModel.swift`
- `/camerons-Bussiness-app/Core/Dashboard/DashboardView.swift`

**Success Criteria:**
- ✅ New orders appear instantly without refresh
- ✅ Status changes sync across devices in <1 second
- ✅ UI shows connection status clearly
- ✅ Optimistic updates feel instant

---

### Phase 3.3: Kitchen Display Real-Time Sync (Day 4)
**Deliverables:**
- [ ] Update `KitchenViewModel`:
  - [ ] Subscribe to kitchen_orders changes
  - [ ] Update column when order dragged
  - [ ] Sync drag actions across devices
  - [ ] Resolve conflicts (two staff drag same order)
- [ ] Add multi-user indicators:
  - [ ] Show who's viewing/editing each order
  - [ ] Highlight orders being dragged by others
  - [ ] Toast when order updated by another staff

**Files to Update:**
- `/camerons-Bussiness-app/Core/Kitchen/KitchenViewModel.swift`
- `/camerons-Bussiness-app/Core/Kitchen/KitchenDisplayView.swift`

**Success Criteria:**
- ✅ Drag actions sync across all kitchen displays
- ✅ No conflicting updates when multiple staff active
- ✅ Visual feedback shows other users' actions
- ✅ Orders never get lost or duplicated

---

### Phase 3.4: Menu Availability Sync (Day 5)
**Deliverables:**
- [ ] Update `MenuManagementViewModel`:
  - [ ] Subscribe to menu_items changes
  - [ ] Update availability toggle in real-time
  - [ ] Notify when items marked out-of-stock by others
- [ ] Customer app integration (when built):
  - [ ] Customer app subscribes to menu_items
  - [ ] Out-of-stock items gray out immediately
  - [ ] New items appear without app restart

**Files to Update:**
- `/camerons-Bussiness-app/Core/Menu/MenuManagementView.swift`

**Success Criteria:**
- ✅ Menu changes propagate to all devices instantly
- ✅ Customer app reflects current availability (when implemented)
- ✅ Staff see when others make menu changes

---

### Phase 3.5: Presence & Activity Tracking (Days 6-7)
**Deliverables:**
- [ ] Implement Supabase Presence:
  - [ ] Track which staff members are online
  - [ ] Show presence in app (avatars, badges)
  - [ ] Track activity (viewing orders, kitchen, menu)
- [ ] Add activity feed:
  - [ ] Real-time log of actions across store
  - [ ] "Sarah marked Order #123 as ready"
  - [ ] "Mike updated Burger availability"
  - [ ] "New order received from Emma K."
- [ ] Add analytics tracking:
  - [ ] Staff login/logout times
  - [ ] Average time per order status
  - [ ] Peak activity hours

**Files to Create:**
- `/camerons-Bussiness-app/Core/Settings/ActivityFeedView.swift`

**Files to Update:**
- `/camerons-Bussiness-app/Services/RealtimeService.swift`

**Success Criteria:**
- ✅ Staff can see who's currently working
- ✅ Activity feed shows recent actions
- ✅ Presence updates in <2 seconds

---

## 🏪 Phase 4: Multi-Store Management (Week 4)
**Goal:** Full multi-location support with organization hierarchy
**Duration:** 5-7 days
**Effort:** High
**Dependencies:** Phase 1-3 complete

### Phase 4.1: Organization & Store Schema (Day 1)
**Deliverables:**
- [ ] Create migration 026 - Multi-Store Architecture:
  ```sql
  CREATE TABLE organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200),
    subscription_tier VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
  );

  ALTER TABLE stores ADD COLUMN organization_id INT REFERENCES organizations(id);

  CREATE TABLE staff_store_access (
    staff_id UUID REFERENCES user_profiles(id),
    store_id INT REFERENCES stores(id),
    role VARCHAR(50),
    PRIMARY KEY (staff_id, store_id)
  );
  ```
- [ ] Migrate existing stores to default organization
- [ ] Update RLS policies for multi-tenant access

**Files to Create:**
- `/database/migrations/026_multi_store_schema.sql`

**Success Criteria:**
- ✅ Migration runs without errors
- ✅ Existing data preserved
- ✅ RLS policies enforce store isolation

---

### Phase 4.2: Organization Management UI (Days 2-3)
**Deliverables:**
- [ ] Create `OrganizationSettingsView.swift`:
  - [ ] View organization details
  - [ ] List all stores in organization
  - [ ] Add/remove stores
  - [ ] Assign staff to stores
- [ ] Create `StoreSelectionView.swift`:
  - [ ] Staff login shows store picker
  - [ ] Switch between stores without re-login
  - [ ] Recent stores list
- [ ] Update navigation:
  - [ ] Store switcher in toolbar
  - [ ] Current store badge/indicator
  - [ ] Multi-store analytics views

**Files to Create:**
- `/camerons-Bussiness-app/Core/Settings/OrganizationSettingsView.swift`
- `/camerons-Bussiness-app/Core/Authentication/StoreSelectionView.swift`

**Files to Update:**
- `/camerons-Bussiness-app/Auth/AuthManager.swift` (store context)
- `/camerons-Bussiness-app/Core/MainTabView.swift` (store switcher)

**Success Criteria:**
- ✅ Staff can switch stores seamlessly
- ✅ Each view respects current store context
- ✅ Admins can manage organization hierarchy

---

### Phase 4.3: Cross-Store Analytics (Days 4-5)
**Deliverables:**
- [ ] Create `CrossStoreAnalyticsView.swift`:
  - [ ] Organization-wide revenue dashboard
  - [ ] Store comparison charts
  - [ ] Best/worst performing locations
  - [ ] Regional trends
- [ ] Update AnalyticsService:
  - [ ] Add `getOrganizationMetrics(orgId:, period:)`
  - [ ] Add `compareStores(storeIds:, metric:, period:)`
- [ ] Create leaderboard:
  - [ ] Rank stores by revenue, orders, rating
  - [ ] Gamification badges
  - [ ] Month-over-month winners

**Files to Create:**
- `/camerons-Bussiness-app/Core/More/CrossStoreAnalyticsView.swift`

**Files to Update:**
- `/camerons-Bussiness-app/Services/AnalyticsService.swift`

**Success Criteria:**
- ✅ Organization admins see aggregated metrics
- ✅ Store managers see only their store + benchmarks
- ✅ Charts visualize multi-location performance

---

### Phase 4.4: Centralized Inventory & Menu Sync (Days 6-7)
**Deliverables:**
- [ ] Implement menu template system:
  - [ ] Create master menu at organization level
  - [ ] Push to all stores or selected stores
  - [ ] Allow per-store customization
- [ ] Implement inventory sync:
  - [ ] Share inventory across locations
  - [ ] Transfer stock between stores
  - [ ] Centralized purchasing
- [ ] Implement pricing rules:
  - [ ] Organization-wide pricing
  - [ ] Regional pricing adjustments
  - [ ] Store-specific overrides

**Files to Create:**
- `/camerons-Bussiness-app/Core/Menu/MenuTemplatesView.swift`
- `/database/migrations/027_menu_templates.sql`

**Success Criteria:**
- ✅ Menu changes propagate to multiple stores
- ✅ Each store can customize as needed
- ✅ Inventory transfers tracked accurately

---

## 📱 Phase 5: Customer-Facing iOS App (Weeks 5-8)
**Goal:** Build companion customer app for ordering
**Duration:** 20-25 days
**Effort:** Very High
**Dependencies:** All backend APIs functional

### Phase 5.1: Project Setup & Authentication (Days 1-2)
**Deliverables:**
- [ ] Create new Xcode project: `Camerons-Customer-App`
- [ ] Setup Supabase client
- [ ] Implement customer authentication:
  - [ ] Email/password signup
  - [ ] Phone number SMS login
  - [ ] Apple Sign In
  - [ ] Google Sign In
- [ ] Implement onboarding flow:
  - [ ] Welcome screens
  - [ ] Location permission
  - [ ] Push notification permission
  - [ ] Loyalty program enrollment

**Files to Create:**
- `/Camerons-Customer-App/` (new Xcode project)

---

### Phase 5.2: Store Finder & Location Services (Days 3-4)
**Deliverables:**
- [ ] Create `StoreFindView.swift`:
  - [ ] Map showing nearby locations
  - [ ] List view with distances
  - [ ] Search by address/zip
  - [ ] Filter by hours, services
- [ ] Implement location services:
  - [ ] Get user's current location
  - [ ] Calculate distances to stores
  - [ ] Sort by proximity
  - [ ] Driving directions integration
- [ ] Store detail page:
  - [ ] Hours, address, phone
  - [ ] Photos, reviews
  - [ ] Menu preview
  - [ ] "Order Now" CTA

**Success Criteria:**
- ✅ Users find nearest restaurant easily
- ✅ Accurate distance calculations
- ✅ Smooth map interactions

---

### Phase 5.3: Menu Browsing & Customization (Days 5-8)
**Deliverables:**
- [ ] Create `MenuView.swift`:
  - [ ] Category tabs (Burgers, Sides, Drinks)
  - [ ] Grid/list toggle
  - [ ] Item images and descriptions
  - [ ] Real-time availability badges
- [ ] Create `MenuItemDetailView.swift`:
  - [ ] Large photo gallery
  - [ ] Detailed description
  - [ ] Nutrition info, allergens
  - [ ] Customization options (size, toppings, sides)
  - [ ] Quantity selector
  - [ ] "Add to Cart" button
- [ ] Implement search & filters:
  - [ ] Search by name/ingredient
  - [ ] Filter by dietary tags (vegan, gluten-free)
  - [ ] Sort by price, popularity, calories
- [ ] Implement favorites:
  - [ ] Heart icon to favorite items
  - [ ] Quick reorder from favorites

**Success Criteria:**
- ✅ Menu loads fast with images
- ✅ Customization options intuitive
- ✅ Cart updates smoothly

---

### Phase 5.4: Shopping Cart & Checkout (Days 9-12)
**Deliverables:**
- [ ] Create `CartView.swift`:
  - [ ] Line items with edit/remove
  - [ ] Subtotal, tax, fees breakdown
  - [ ] Coupon code input
  - [ ] Checkout button
- [ ] Create `CheckoutView.swift`:
  - [ ] Pickup vs Delivery selector
  - [ ] Pickup time scheduler
  - [ ] Payment method selector (saved cards, Apple Pay)
  - [ ] Special instructions
  - [ ] Tip selector (%, $ amount)
  - [ ] Order review
- [ ] Implement Stripe integration:
  - [ ] Save payment methods
  - [ ] Process payments securely
  - [ ] Handle 3D Secure
  - [ ] Refund handling
- [ ] Implement order placement:
  - [ ] POST to orders API
  - [ ] Create order_items records
  - [ ] Deduct loyalty points if used
  - [ ] Send confirmation email/SMS
  - [ ] Navigate to order tracking

**Success Criteria:**
- ✅ Payments process securely
- ✅ Orders appear in staff app immediately
- ✅ Confirmation sent within 5 seconds

---

### Phase 5.5: Order Tracking & History (Days 13-15)
**Deliverables:**
- [ ] Create `OrderTrackingView.swift`:
  - [ ] Real-time status updates (Supabase Realtime)
  - [ ] Estimated ready time countdown
  - [ ] Order details expandable
  - [ ] "Get Directions" button
  - [ ] Push notification when ready
- [ ] Create `OrderHistoryView.swift`:
  - [ ] Past orders list
  - [ ] Filter by date, store
  - [ ] "Reorder" button
  - [ ] View receipt
  - [ ] Leave review
- [ ] Create `OrderDetailView.swift`:
  - [ ] Full order breakdown
  - [ ] Items, customizations, totals
  - [ ] Payment details
  - [ ] Loyalty points earned
  - [ ] Receipt PDF download

**Success Criteria:**
- ✅ Order status updates in real-time
- ✅ Push notification when order ready
- ✅ Reorder in 2 taps

---

### Phase 5.6: Loyalty & Rewards (Days 16-18)
**Deliverables:**
- [ ] Create `LoyaltyView.swift`:
  - [ ] Points balance (big number)
  - [ ] Current tier badge
  - [ ] Progress to next tier
  - [ ] Tier benefits list
  - [ ] Rewards catalog
- [ ] Create `RewardsView.swift`:
  - [ ] Available rewards grid
  - [ ] Points cost displayed
  - [ ] Redeem button
  - [ ] Active rewards (already redeemed)
  - [ ] Expired rewards
- [ ] Implement redemption:
  - [ ] Deduct points from customer_loyalty
  - [ ] Create coupon in coupons table
  - [ ] Auto-apply at checkout
- [ ] Create `PointsHistoryView.swift`:
  - [ ] Transaction log (earned/spent)
  - [ ] Filters by type
  - [ ] Expiration warnings

**Success Criteria:**
- ✅ Points display accurately
- ✅ Redemptions process instantly
- ✅ Tier progress motivates customers

---

### Phase 5.7: Profile & Settings (Days 19-20)
**Deliverables:**
- [ ] Create `ProfileView.swift`:
  - [ ] Avatar, name, email
  - [ ] Loyalty card display
  - [ ] QR code for in-store scanning
  - [ ] Edit profile button
- [ ] Create `SettingsView.swift`:
  - [ ] Notification preferences
  - [ ] Payment methods management
  - [ ] Saved addresses
  - [ ] Dietary preferences
  - [ ] Language, units
  - [ ] Delete account
- [ ] Create `NotificationsSettingsView.swift`:
  - [ ] Order updates toggle
  - [ ] Promotions toggle
  - [ ] Loyalty milestones toggle
  - [ ] App badge toggle

**Success Criteria:**
- ✅ Profile edits save correctly
- ✅ Settings persist across sessions
- ✅ Account deletion works properly

---

### Phase 5.8: Testing & Polish (Days 21-25)
**Deliverables:**
- [ ] End-to-end testing:
  - [ ] Place test orders through full flow
  - [ ] Test all payment methods
  - [ ] Test loyalty redemption
  - [ ] Test notifications
- [ ] UI polish:
  - [ ] Animations smooth
  - [ ] Loading states consistent
  - [ ] Error messages helpful
  - [ ] Accessibility (VoiceOver, Dynamic Type)
- [ ] Performance optimization:
  - [ ] Image caching
  - [ ] API response caching
  - [ ] Lazy loading
  - [ ] Background fetch
- [ ] App Store preparation:
  - [ ] Screenshots (6.7", 6.5", 5.5")
  - [ ] App preview video
  - [ ] Description, keywords
  - [ ] Privacy policy, terms
  - [ ] Submit for review

**Success Criteria:**
- ✅ No crashes in testing
- ✅ 60fps scroll performance
- ✅ App Store approved

---

## 🤖 Phase 6: Advanced Automation & AI (Weeks 9-10)
**Goal:** Smart features that reduce manual work
**Duration:** 10-14 days
**Effort:** High
**Dependencies:** Phases 1-5 complete

### Phase 6.1: Automated Campaign Triggers (Days 1-3)
**Deliverables:**
- [ ] Implement trigger system:
  - [ ] Birthday campaign (send 1 day before)
  - [ ] Inactive user campaign (no order in 30 days)
  - [ ] High-value customer reward (spent $500+)
  - [ ] Order anniversary (1 year since first order)
  - [ ] Cart abandonment (started order, didn't complete)
- [ ] Create campaign execution engine:
  - [ ] Cron job checks triggers hourly
  - [ ] Queries customer database for matches
  - [ ] Sends personalized notifications
  - [ ] Tracks in campaign_executions table
  - [ ] Calculates ROI (orders attributed to campaign)
- [ ] Add A/B testing:
  - [ ] Test 2 versions of notification
  - [ ] Split audience randomly
  - [ ] Track open/click/conversion rates
  - [ ] Auto-select winning variant

**Files to Create:**
- `/supabase/functions/campaign-triggers/index.ts`

**Success Criteria:**
- ✅ Campaigns send automatically without manual work
- ✅ Triggers fire at correct times
- ✅ ROI tracked accurately

---

### Phase 6.2: Smart Menu Recommendations (Days 4-6)
**Deliverables:**
- [ ] Implement recommendation engine:
  - [ ] Track user's order history
  - [ ] Find similar customers (collaborative filtering)
  - [ ] Suggest items "customers like you ordered"
  - [ ] Upsell suggestions (fries with burger)
  - [ ] Cross-sell (drink with meal)
- [ ] Create "You May Also Like" section:
  - [ ] Show on item detail page
  - [ ] Show in cart
  - [ ] Show on order confirmation
- [ ] Implement dynamic pricing:
  - [ ] Surge pricing during peak hours (optional)
  - [ ] Bundle discounts
  - [ ] Loyalty tier discounts auto-applied
- [ ] Add inventory predictions:
  - [ ] Predict what will sell out
  - [ ] Suggest restocking items
  - [ ] Seasonal demand forecasting

**Success Criteria:**
- ✅ Recommendations increase AOV by 10%+
- ✅ Upsells convert at 15%+ rate
- ✅ Inventory predictions 80%+ accurate

---

### Phase 6.3: Chatbot Customer Support (Days 7-10)
**Deliverables:**
- [ ] Integrate AI assistant (OpenAI GPT or similar):
  - [ ] Train on menu data
  - [ ] Train on common FAQs
  - [ ] Connect to order database
- [ ] Create `ChatView.swift` in customer app:
  - [ ] Chat interface
  - [ ] Quick reply buttons
  - [ ] Handoff to human support
- [ ] Implement chatbot capabilities:
  - [ ] Answer menu questions ("Do you have vegan options?")
  - [ ] Track orders ("Where is order #456?")
  - [ ] Modify orders ("Add extra cheese")
  - [ ] Report issues ("My order was wrong")
  - [ ] Make reservations (if applicable)
- [ ] Add to staff app:
  - [ ] View chatbot conversations
  - [ ] Take over conversation
  - [ ] Rate chatbot responses for training

**Files to Create:**
- `/Camerons-Customer-App/Core/Chat/ChatView.swift`

**Success Criteria:**
- ✅ Chatbot resolves 60%+ of queries without human
- ✅ Customer satisfaction >4/5 stars
- ✅ Response time <2 seconds

---

### Phase 6.4: Fraud Detection & Security (Days 11-14)
**Deliverables:**
- [ ] Implement fraud scoring:
  - [ ] Unusual order patterns (10 orders in 1 hour)
  - [ ] Payment mismatches
  - [ ] Stolen card detection
  - [ ] Promo code abuse
- [ ] Create alert system:
  - [ ] Flag suspicious orders for manual review
  - [ ] Auto-reject high-risk transactions
  - [ ] Notify staff via push notification
- [ ] Add security enhancements:
  - [ ] Rate limiting on APIs
  - [ ] CAPTCHA on signup/login
  - [ ] IP blocking for repeated failures
  - [ ] Two-factor authentication (optional)
- [ ] Implement audit logging:
  - [ ] Log all admin actions
  - [ ] Track data access
  - [ ] Compliance reporting (GDPR, CCPA)

**Success Criteria:**
- ✅ Fraud reduced by 80%+
- ✅ False positives <5%
- ✅ Compliance requirements met

---

## 🎨 Phase 7: Polish & Launch Prep (Week 11)
**Goal:** Production-ready quality and app store submission
**Duration:** 5-7 days
**Effort:** Medium
**Dependencies:** All features complete

### Phase 7.1: Performance Optimization (Days 1-2)
**Deliverables:**
- [ ] App launch time <2 seconds
- [ ] API response caching
- [ ] Image lazy loading and caching
- [ ] Database query optimization
- [ ] Code splitting and minification
- [ ] Memory leak detection and fixes

**Success Criteria:**
- ✅ 60fps scroll performance
- ✅ Memory usage <150MB
- ✅ Battery drain minimal

---

### Phase 7.2: Bug Fixes & Testing (Days 3-4)
**Deliverables:**
- [ ] Fix all known bugs
- [ ] UAT with real restaurant staff
- [ ] Beta test with select customers
- [ ] Cross-device testing (iPhone, iPad)
- [ ] iOS version compatibility (iOS 16+)
- [ ] Dark mode support verification

**Success Criteria:**
- ✅ Zero critical bugs
- ✅ <5 minor bugs
- ✅ 95%+ feature completion

---

### Phase 7.3: Documentation & Training (Days 5-6)
**Deliverables:**
- [ ] Staff training guide (PDF + video)
- [ ] Customer FAQ
- [ ] API documentation (if needed)
- [ ] Database schema documentation
- [ ] Deployment runbook
- [ ] Troubleshooting guide

**Success Criteria:**
- ✅ All documentation complete
- ✅ Training materials tested with staff

---

### Phase 7.4: App Store Submission (Day 7)
**Deliverables:**
- [ ] Staff app submitted to App Store
- [ ] Customer app submitted to App Store
- [ ] Wait for Apple review
- [ ] Address any rejection feedback
- [ ] Marketing materials prepared

**Success Criteria:**
- ✅ Both apps approved
- ✅ Ready for public launch

---

## 📋 Summary Timeline

| Phase | Focus | Duration | Total Time |
|-------|-------|----------|------------|
| **Phase 1** | Complete Core Analytics | 3-5 days | Week 1 |
| **Phase 2** | Push Notification Infrastructure | 5-7 days | Week 2 |
| **Phase 3** | Real-Time Synchronization | 5-7 days | Week 3 |
| **Phase 4** | Multi-Store Management | 5-7 days | Week 4 |
| **Phase 5** | Customer-Facing iOS App | 20-25 days | Weeks 5-8 |
| **Phase 6** | Advanced Automation & AI | 10-14 days | Weeks 9-10 |
| **Phase 7** | Polish & Launch Prep | 5-7 days | Week 11 |

**Total Estimated Timeline:** 10-12 weeks (2.5-3 months)

---

## 🎯 Recommended Starting Point

### **Start with Phase 1.1: Notifications Analytics Service**

**Why?**
1. ✅ Quick win (1-2 days)
2. ✅ Completes analytics suite
3. ✅ Natural continuation of recent work
4. ✅ Database tables already exist
5. ✅ UI already built
6. ✅ Low risk, high visibility

**Next Steps After Phase 1.1:**
- Complete rest of Phase 1 (marketing data + export charts)
- Move to Phase 2 (push notifications) to populate the analytics you just built
- Then Phase 3 (real-time) for instant order updates

---

## 📊 Progress Tracking

### Current Status: Phase 0 Complete ✅

**Completed:**
- ✅ Authentication & User Management
- ✅ Dashboard & Order Management
- ✅ Kitchen Display System
- ✅ Menu Management
- ✅ Business Reports Analytics (real data)
- ✅ Store Analytics (real data)
- ✅ Database migrations (001, 002, 024)
- ✅ Export infrastructure (PDF/CSV)

**In Progress:**
- 🟡 Marketing system (UI done, needs data)
- 🟡 Notifications analytics (UI done, needs data)
- 🟡 Export charts (needs rendering)

**Not Started:**
- ❌ Push notifications
- ❌ Real-time sync
- ❌ Multi-store
- ❌ Customer app
- ❌ Automation/AI

---

### Phase Completion Checklist

- [ ] **Phase 1:** Complete Core Analytics
  - [ ] 1.1: Notifications Analytics Service
  - [ ] 1.2: Marketing Data Integration
  - [ ] 1.3: Export System Chart Rendering
  - [ ] 1.4: Historical Trend Calculations

- [ ] **Phase 2:** Push Notification Infrastructure
  - [ ] 2.1: Firebase Cloud Messaging Setup
  - [ ] 2.2: Notification Composer UI
  - [ ] 2.3: Notification Sending Logic
  - [ ] 2.4: Device Token Management
  - [ ] 2.5: Testing & Analytics Integration

- [ ] **Phase 3:** Real-Time Synchronization
  - [ ] 3.1: Supabase Realtime Setup
  - [ ] 3.2: Dashboard Real-Time Updates
  - [ ] 3.3: Kitchen Display Real-Time Sync
  - [ ] 3.4: Menu Availability Sync
  - [ ] 3.5: Presence & Activity Tracking

- [ ] **Phase 4:** Multi-Store Management
  - [ ] 4.1: Organization & Store Schema
  - [ ] 4.2: Organization Management UI
  - [ ] 4.3: Cross-Store Analytics
  - [ ] 4.4: Centralized Inventory & Menu Sync

- [ ] **Phase 5:** Customer-Facing iOS App
  - [ ] 5.1: Project Setup & Authentication
  - [ ] 5.2: Store Finder & Location Services
  - [ ] 5.3: Menu Browsing & Customization
  - [ ] 5.4: Shopping Cart & Checkout
  - [ ] 5.5: Order Tracking & History
  - [ ] 5.6: Loyalty & Rewards
  - [ ] 5.7: Profile & Settings
  - [ ] 5.8: Testing & Polish

- [ ] **Phase 6:** Advanced Automation & AI
  - [ ] 6.1: Automated Campaign Triggers
  - [ ] 6.2: Smart Menu Recommendations
  - [ ] 6.3: Chatbot Customer Support
  - [ ] 6.4: Fraud Detection & Security

- [ ] **Phase 7:** Polish & Launch Prep
  - [ ] 7.1: Performance Optimization
  - [ ] 7.2: Bug Fixes & Testing
  - [ ] 7.3: Documentation & Training
  - [ ] 7.4: App Store Submission

---

## 🚀 Ready to Begin?

**Let's start with Phase 1.1: Notifications Analytics Service**

This will complete your analytics suite and provide a solid foundation for the push notification infrastructure in Phase 2.

Would you like me to begin implementing Phase 1.1 now?
