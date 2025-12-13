# Real Data Integration Plan - All Pages

This document outlines the plan to connect all Business App pages to real Supabase data.

## ✅ Already Completed

### 1. Dashboard View (Orders)
- ✅ Fetches real orders from Supabase
- ✅ Real-time order subscriptions
- ✅ Status updates sync to database
- ✅ Filtered by store_id = 1

### 2. Kitchen Display View
- ✅ Fetches real orders from Supabase
- ✅ Real-time order subscriptions
- ✅ Drag-and-drop status updates to database
- ✅ Filtered by store_id = 1

### 3. Menu Management View
- ✅ Fetches real menu items from `menu_items` table
- ✅ Fetches real categories from `menu_categories` table
- ✅ Toggle availability updates database
- ✅ Pull to refresh
- ✅ Error handling with fallback to mock data

## 🔄 Needs Real Data Integration

### 4. Analytics View

**Current Status**: Uses mock data

**Required Database Tables**:
- `orders` - For revenue, order count
- `order_items` - For top selling items
- `menu_items` - For item details

**Functions to Add to SupabaseManager**:
```swift
// Analytics queries
func fetchTodaySummary(storeId: Int) async throws -> AnalyticsSummary
func fetchWeeklySales(storeId: Int) async throws -> [DailySales]
func fetchTopSellingItems(storeId: Int, limit: Int) async throws -> [TopSellingItem]
func fetchPeakHours(storeId: Int) async throws -> [HourlyStats]
```

**Implementation Steps**:
1. Add analytics query functions to SupabaseManager
2. Update AnalyticsViewModel to fetch real data
3. Add loading states and error handling
4. Calculate metrics from order data:
   - Today's orders count
   - Today's revenue (sum of order totals)
   - Average order value
   - Top selling items (group by menu_item_id, count quantity)
   - Peak hours (group by hour, count orders)
   - 7-day sales trend

**Database Queries Needed**:
- Count orders for today/this week
- Sum revenue for today/this week
- Group orders by hour for peak hours
- Join order_items with menu_items for top sellers

---

### 5. Marketing Dashboard View

**Current Status**: Uses mock data for coupons, notifications, rewards

#### 5a. Coupons Management

**Required Database Table**: `coupons`
```sql
CREATE TABLE coupons (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id),
  code VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  discount_type VARCHAR(20), -- 'percentage' or 'fixed'
  discount_value DECIMAL(10,2),
  min_order_value DECIMAL(10,2),
  max_uses INT,
  current_uses INT DEFAULT 0,
  start_date TIMESTAMP,
  end_date TIMESTAMP,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Functions to Add**:
```swift
func fetchCoupons(storeId: Int) async throws -> [Coupon]
func createCoupon(_ coupon: Coupon) async throws -> String
func updateCoupon(_ coupon: Coupon) async throws
func deleteCoupon(couponId: String) async throws
func toggleCouponStatus(couponId: String, isActive: Bool) async throws
```

#### 5b. Push Notifications

**Required Database Table**: `notifications`
```sql
CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id),
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  target_audience VARCHAR(50), -- 'all', 'new_customers', 'loyal_customers'
  scheduled_for TIMESTAMP,
  sent_at TIMESTAMP,
  status VARCHAR(20), -- 'draft', 'scheduled', 'sent'
  recipient_count INT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Functions to Add**:
```swift
func fetchNotifications(storeId: Int) async throws -> [Notification]
func createNotification(_ notification: Notification) async throws -> String
func sendNotification(notificationId: String) async throws
func fetchNotificationStats(notificationId: String) async throws -> NotificationStats
```

**Note**: Actual push notification sending requires:
- Firebase Cloud Messaging (FCM) integration
- APNs (Apple Push Notification service) setup
- Customer app to register device tokens

#### 5c. Rewards Program

**Required Database Table**: `rewards`
```sql
CREATE TABLE rewards (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id),
  name VARCHAR(200) NOT NULL,
  description TEXT,
  points_required INT NOT NULL,
  reward_type VARCHAR(50), -- 'free_item', 'discount', 'special_offer'
  reward_value JSONB, -- Details of the reward
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Functions to Add**:
```swift
func fetchRewards(storeId: Int) async throws -> [Reward]
func createReward(_ reward: Reward) async throws -> String
func updateReward(_ reward: Reward) async throws
func deleteReward(rewardId: String) async throws
func toggleRewardStatus(rewardId: String, isActive: Bool) async throws
```

---

### 6. Settings/Profile View

**Current Status**: Shows basic user profile from `user_profiles` table ✅

**Additional Features Needed**:

#### 6a. Store Settings

**Required Database Tables**:
- `stores` (already exists) - For store information
- `store_settings` (optional) - For additional settings

**Functions to Add**:
```swift
func fetchStoreDetails(storeId: Int) async throws -> Store
func updateStoreDetails(_ store: Store) async throws
func updateStoreHours(storeId: Int, hours: StoreHours) async throws
```

#### 6b. Staff Management

**Required Database Table**: `user_profiles` (already exists)

**Functions to Add**:
```swift
func fetchStaffMembers(storeId: Int) async throws -> [UserProfile]
func updateStaffPermissions(userId: String, permissions: [Permission]) async throws
func deactivateStaffMember(userId: String) async throws
```

#### 6c. Order Settings

**Required Database Table**: `store_settings`
```sql
CREATE TABLE store_settings (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id) UNIQUE,
  auto_accept_orders BOOLEAN DEFAULT false,
  prep_time_buffer INT DEFAULT 15, -- minutes
  max_orders_per_hour INT,
  enable_delivery BOOLEAN DEFAULT true,
  enable_pickup BOOLEAN DEFAULT true,
  enable_dine_in BOOLEAN DEFAULT true,
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Functions to Add**:
```swift
func fetchStoreSettings(storeId: Int) async throws -> StoreSettings
func updateStoreSettings(_ settings: StoreSettings) async throws
```

---

## 📊 Implementation Priority

### Phase 1 (Immediate) - Core Operations
1. ✅ Dashboard (Orders) - **DONE**
2. ✅ Kitchen Display - **DONE**
3. ✅ Menu Management - **DONE**

### Phase 2 (High Priority) - Analytics & Insights
4. Analytics View - **Implement real-time analytics**
   - Today's summary
   - Weekly sales chart
   - Top selling items
   - Peak hours

### Phase 3 (Medium Priority) - Marketing Tools
5. Coupons Management
   - Create/edit/delete coupons
   - Track coupon usage
   - Enable/disable coupons

6. Notifications (Basic)
   - Send test notifications
   - View notification history
   - Schedule notifications (future enhancement)

### Phase 4 (Low Priority) - Advanced Features
7. Rewards Program
8. Staff Management
9. Advanced Store Settings

---

## 🛠️ Technical Requirements

### Database Schema Updates Needed

1. **Analytics** - Use existing tables (orders, order_items, menu_items)
2. **Marketing** - Create new tables (coupons, notifications, rewards)
3. **Settings** - Create store_settings table

### SupabaseManager Updates

Add new sections:
```swift
// MARK: - Analytics
func fetchTodaySummary(storeId: Int) async throws -> AnalyticsSummary
func fetchWeeklySales(storeId: Int) async throws -> [DailySales]
func fetchTopSellingItems(storeId: Int, limit: Int) async throws -> [TopSellingItem]

// MARK: - Marketing - Coupons
func fetchCoupons(storeId: Int) async throws -> [Coupon]
func createCoupon(_ coupon: Coupon) async throws -> String
func updateCoupon(_ coupon: Coupon) async throws

// MARK: - Marketing - Notifications
func fetchNotifications(storeId: Int) async throws -> [Notification]
func createNotification(_ notification: Notification) async throws -> String

// MARK: - Marketing - Rewards
func fetchRewards(storeId: Int) async throws -> [Reward]
func createReward(_ reward: Reward) async throws -> String

// MARK: - Store Settings
func fetchStoreSettings(storeId: Int) async throws -> StoreSettings
func updateStoreSettings(_ settings: StoreSettings) async throws
```

### ViewModel Updates

Each view needs:
1. Replace mock data calls with Supabase calls
2. Add loading states (`@Published var isLoading = false`)
3. Add error handling (`@Published var errorMessage: String?`)
4. Add pull-to-refresh
5. Add real-time subscriptions where applicable

---

## 🎯 Next Steps

### Immediate Actions:
1. **Analytics View** - High impact, uses existing data
   - Add analytics functions to SupabaseManager
   - Update AnalyticsViewModel
   - Test with real order data

### Short Term (This Week):
2. **Create Marketing Tables** in Supabase
   - Run SQL scripts to create coupons, notifications, rewards tables
   - Add some sample data for testing

3. **Implement Coupons Management**
   - Add coupon CRUD functions
   - Update MarketingDashboardView
   - Test coupon creation and usage

### Medium Term (Next Week):
4. **Settings & Store Management**
   - Store settings table
   - Update settings views
   - Staff management features

---

## 📝 Database Migration Scripts

### Create Marketing Tables
```sql
-- Coupons
CREATE TABLE coupons (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id),
  code VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  discount_type VARCHAR(20),
  discount_value DECIMAL(10,2),
  min_order_value DECIMAL(10,2),
  max_uses INT,
  current_uses INT DEFAULT 0,
  start_date TIMESTAMP,
  end_date TIMESTAMP,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id),
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  target_audience VARCHAR(50),
  scheduled_for TIMESTAMP,
  sent_at TIMESTAMP,
  status VARCHAR(20) DEFAULT 'draft',
  recipient_count INT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Rewards
CREATE TABLE rewards (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id),
  name VARCHAR(200) NOT NULL,
  description TEXT,
  points_required INT NOT NULL,
  reward_type VARCHAR(50),
  reward_value JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Store Settings
CREATE TABLE store_settings (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id) UNIQUE,
  auto_accept_orders BOOLEAN DEFAULT false,
  prep_time_buffer INT DEFAULT 15,
  max_orders_per_hour INT,
  enable_delivery BOOLEAN DEFAULT true,
  enable_pickup BOOLEAN DEFAULT true,
  enable_dine_in BOOLEAN DEFAULT true,
  notification_preferences JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes
CREATE INDEX idx_coupons_store_id ON coupons(store_id);
CREATE INDEX idx_coupons_code ON coupons(code);
CREATE INDEX idx_notifications_store_id ON notifications(store_id);
CREATE INDEX idx_rewards_store_id ON rewards(store_id);
```

---

## ✅ Success Criteria

Each view integration is complete when:
1. ✅ Data loads from Supabase (not mock data)
2. ✅ Loading indicator shows during fetch
3. ✅ Error handling with user-friendly messages
4. ✅ Pull-to-refresh works
5. ✅ CRUD operations persist to database
6. ✅ Console logs confirm Supabase calls
7. ✅ Fallback to mock data on error (development only)

---

**Last Updated**: November 18, 2025
**Status**: Menu Management completed ✅ | Analytics next in queue 🔄
