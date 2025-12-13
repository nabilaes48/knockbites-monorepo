# Jay's Deli Business App - Setup Guide

This guide explains the configuration changes made to set up the iOS Business App for **Highland Mills Snack Shop Inc (Jay's Deli)**.

## 🎯 What's Been Configured

### 1. Store Information (SupabaseConfig.swift)
- **Store ID**: 1 (Jay's Deli)
- **Store Name**: Highland Mills Snack Shop Inc
- **Address**: 634 NY-32, Highland Mills, NY 10930
- **Phone**: (845) 928-2883
- **Email**: jaydeli@outonemail.com

### 2. Staff Login Credentials
The app now works with these Supabase Auth credentials:

- **Super Admin**: admin@jaydeli.com / admin123
- **Manager**: manager@jaydeli.com / manager123
- **Staff**: staff@jaydeli.com / staff123

### 3. Real-Time Order Integration
Both the Dashboard and Kitchen Display now have **live order updates** via Supabase Realtime:
- New orders appear instantly when placed from the web app
- Order status changes sync automatically across all devices
- Filtered by store_id = 1 (Jay's Deli only)

## 🔄 Key Changes Made

### Files Updated:

1. **SupabaseConfig.swift**
   - Added Jay's Deli store constants
   - Store ID, name, address, phone, email

2. **SupabaseManager.swift**
   - Updated `fetchOrders()` to default to store_id = 1
   - Enhanced `subscribeToOrders()` with store-specific filtering
   - Real-time channels filtered by store: `orders_store_1`

3. **DashboardViewModel.swift**
   - Updated to use Int for store_id (matches database)
   - Automatically defaults to Jay's Deli (store_id = 1)
   - Real-time subscription active on view appear

4. **KitchenViewModel.swift**
   - Fetches real orders from Supabase (no more mock data)
   - Converts Supabase orders to KitchenOrder format
   - Real-time updates for kitchen display
   - Syncs status changes back to Supabase

5. **DashboardView.swift & KitchenDisplayView.swift**
   - Both views now call `startRealtimeUpdates()` on appear
   - Both views call `stopRealtimeUpdates()` on disappear
   - Live indicator shows real-time connection status

6. **Models.swift (OrderStatus)**
   - Updated raw values to match database:
     - `received` = "pending"
     - `preparing` = "preparing"
     - `ready` = "ready"
     - `completed` = "completed"
   - Added `displayName` property for UI display

## 🚀 How to Test

### Step 1: Build and Run the App
```bash
xcodebuild -scheme camerons-Bussiness-app -configuration Debug build
```

Or open in Xcode and press Cmd+R

### Step 2: Login
Use any of the staff credentials:
- Email: `staff@jaydeli.com`
- Password: `staff123`

### Step 3: Test Real-Time Orders

#### From Web App to Business App:
1. Open the web app (customer side)
2. Place a new order for Jay's Deli
3. Watch the Business App - the order should appear **instantly** in both:
   - Dashboard tab (Active Orders)
   - Kitchen Display tab (New Orders column)

#### Test Order Status Updates:
1. In the Business App, tap on an order in Dashboard
2. Tap "Start Prep" to move it to Preparing
3. Check the Kitchen Display - the order should move to the "Cooking" column
4. Continue updating: Preparing → Ready → Completed
5. Verify changes sync to the web app

### Step 4: Test Multi-Device Sync
1. Run the app on two simulators or devices
2. Login to both with the same or different staff accounts
3. Update an order status on one device
4. Watch it update **instantly** on the second device

## 📱 Features Now Working

### ✅ Dashboard View
- Fetches orders from Supabase (store_id = 1)
- Real-time subscription for new orders
- Real-time status update notifications
- Pulls to refresh
- Order detail view with status updates

### ✅ Kitchen Display View
- Drag-and-drop Kanban board (6 columns)
- Real orders from Supabase
- Real-time new order alerts
- Status updates sync to database
- Filters by order type (pickup/delivery/dine-in)
- Urgent order highlighting (>15 min)

### ✅ Authentication
- Supabase Auth integration
- Role-based access (super_admin, manager, staff)
- Persistent sessions
- User profile from database

## 🔧 Database Schema Requirements

The app expects these tables in Supabase:

### `stores` table
- id (int)
- name (text)
- address (text)
- phone (text)
- email (text)

### `user_profiles` table
- id (uuid, references auth.users)
- role (text: 'super_admin', 'admin', 'manager', 'staff')
- full_name (text)
- phone (text)
- store_id (int, references stores)
- permissions (jsonb array)
- is_active (boolean)

### `orders` table
- id (uuid)
- order_number (text)
- user_id (uuid, references auth.users)
- customer_name (text)
- store_id (int, references stores)
- subtotal (decimal)
- tax (decimal)
- total (decimal)
- status (text: 'pending', 'preparing', 'ready', 'completed', 'cancelled')
- order_type (text: 'pickup', 'delivery', 'dine_in')
- created_at (timestamp)
- estimated_ready_time (timestamp)
- completed_at (timestamp)

### `order_items` table
- id (uuid)
- order_id (uuid, references orders)
- menu_item_id (uuid, references menu_items)
- quantity (int)
- selected_options (jsonb)
- special_instructions (text)

### `menu_items` table
- id (uuid)
- name (text)
- description (text)
- price (decimal)
- category_id (uuid)
- image_url (text)
- is_available (boolean)

## 🔔 Real-Time Subscriptions

The app subscribes to the following Realtime events:

### Channel: `orders_store_1`
- **INSERT**: New orders placed → triggers refresh
- **UPDATE**: Status changes → triggers refresh

### Subscription Lifecycle:
- **Started**: When Dashboard or Kitchen view appears
- **Stopped**: When view disappears (saves resources)
- **Filter**: Only orders for store_id = 1

## 🐛 Troubleshooting

### Orders Not Appearing?
1. Check Supabase connection on app launch (see console logs)
2. Verify the order has `store_id = 1`
3. Check that Realtime is enabled in Supabase for the `orders` table
4. Look for console logs: "✅ Subscribed to real-time order updates for store 1"

### Login Not Working?
1. Verify the user exists in `auth.users` table
2. Check that a matching profile exists in `user_profiles` table
3. Ensure `store_id = 1` in the user_profile
4. Password must match what's set in Supabase Auth

### Real-Time Not Working?
1. Enable Realtime in Supabase dashboard for `orders` table
2. Check Supabase logs for subscription errors
3. Verify the app shows "Live" indicator in Kitchen Display
4. Test with a simple INSERT in Supabase SQL editor

### Status Updates Not Syncing?
1. Verify the order ID exists in the database
2. Check Row Level Security (RLS) policies allow updates
3. Check console for update errors
4. Ensure status values match: 'pending', 'preparing', 'ready', 'completed'

## 📊 Console Logs to Look For

### Successful Connection:
```
✅ Supabase Business connection successful!
📍 Found X stores
✅ Loaded Y orders from Supabase for store 1
✅ Subscribed to real-time order updates for store 1
🔔 Real-time order updates ACTIVE - new orders will appear instantly!
```

### New Order Received:
```
🔔 New order received via real-time for store 1!
🔔 Real-time update triggered - refreshing orders
✅ Loaded Y orders from Supabase for store 1
```

### Status Update:
```
🔄 Updating order <order-id> to status: preparing
✅ Order status updated successfully
```

## 🎉 Success Indicators

You'll know everything is working when:

1. ✅ You can login with staff@jaydeli.com / staff123
2. ✅ Dashboard shows orders for Jay's Deli (if any exist)
3. ✅ Kitchen Display shows same orders in Kanban columns
4. ✅ "Live" indicator shows in Kitchen Display toolbar
5. ✅ New orders from web app appear instantly (no refresh needed)
6. ✅ Status updates sync between Dashboard and Kitchen views
7. ✅ Dragging orders in Kitchen Display updates the database
8. ✅ Changes sync to other devices in real-time

## 🔐 Security Notes

- App uses Supabase anon key (stored in SupabaseConfig.swift)
- User authentication via JWT tokens (Supabase Auth)
- All queries filtered by store_id = 1 for non-super_admin users
- RLS policies should be configured in Supabase for data security

## 🚦 Next Steps

1. **Test thoroughly** with real orders from web app
2. **Verify** all staff can login and see orders
3. **Train staff** on how to use Dashboard and Kitchen Display
4. **Monitor** Supabase usage and real-time connections
5. **Set up** push notifications for new orders (future enhancement)

---

**Built with ❤️ for Jay's Deli**
*Highland Mills Snack Shop Inc - Serving the community since [year]*
