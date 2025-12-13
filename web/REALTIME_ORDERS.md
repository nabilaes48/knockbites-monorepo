# Real-Time Order Management System

## Overview

The Cameron's Connect dashboard includes a comprehensive real-time order management system that automatically refreshes and notifies staff of new orders. This works seamlessly across both the web dashboard and iOS app.

## Features

### 1. Automatic Real-Time Updates

Orders are automatically updated in real-time using **Supabase Realtime** subscriptions. No manual refresh needed!

**What gets updated automatically:**
- ✅ New orders appear instantly when customers place them
- ✅ Order status changes (pending → preparing → ready → completed)
- ✅ Order deletions/cancellations
- ✅ Order modifications

**How it works:**
- Uses WebSocket connection via Supabase Realtime
- Subscribes to PostgreSQL database changes
- Updates UI instantly without page refresh
- Works on both web and iOS apps

### 2. Active Tab: Pending Orders

**Default View:** The dashboard now opens to the **"Pending" tab** by default, showing only orders that need action.

This ensures staff immediately see:
- Orders awaiting acceptance
- Orders that need to be started
- New incoming orders

### 3. Visual Indicators for New Orders

When a new order arrives, you'll see multiple visual indicators:

**🟢 NEW Badge:**
- Bright green "NEW" badge with sparkle icon
- Appears for 10 seconds
- Pulsing animation to grab attention

**🎨 Card Highlighting:**
- Entire order card glows with green border
- Green shadow effect
- Pulsing animation for 10 seconds

**🔔 Notification Badge:**
- Red notification badge on "Pending" tab
- Shows count of new orders
- Pulsing animation

**📊 Auto-Switch:**
- Dashboard automatically switches to "Pending" tab when new order arrives
- Ensures you never miss a new order

### 4. Audio Notifications

**Sound Alert:**
- Two-tone beep when new order arrives
- Uses Web Audio API (works in all modern browsers)
- First beep: 800Hz
- Second beep: 1000Hz (200ms delay)
- Duration: 0.5 seconds each

**When sounds play:**
- ✅ New order received
- ✅ Order marked as "Ready for Pickup"

**Note:** Audio may require user interaction first (browser security policy)

### 5. Toast Notifications

**New Order Toast:**
- Title: "🔔 New Order Received!"
- Shows order number and customer name
- Duration: 8 seconds
- Example: "Order #1234 from John Doe"

**Status Update Toasts:**
- "Order marked as pending"
- "Order is now being prepared"
- "Order marked as ready for pickup"
- "Order completed"
- "Order has been cancelled"

### 6. Order Statistics Dashboard

Real-time stats at the top of the page:

**📊 Today's Revenue:**
- Total revenue from all orders
- Live updating
- Percentage change vs yesterday

**📦 Active Orders:**
- Count of non-completed orders
- Shows pending count below

**✅ Ready for Pickup:**
- Orders waiting for customer pickup
- "Awaiting customers" indicator

### 7. Search & Filter

**Status Filters:**
- All Orders
- Pending (awaiting action)
- Preparing (being made)
- Ready (for pickup)

**Search by:**
- Order number
- Customer name
- Phone number
- Email address

## How It Works: Technical Details

### Real-Time Subscription Flow

```
1. Dashboard loads
   ↓
2. useRealtimeOrders hook subscribes to Supabase
   ↓
3. WebSocket connection established
   ↓
4. Listen for INSERT/UPDATE/DELETE events
   ↓
5. New order placed on iOS/Web
   ↓
6. PostgreSQL fires NOTIFY event
   ↓
7. Supabase Realtime broadcasts to all subscribers
   ↓
8. Dashboard receives update
   ↓
9. UI updates instantly + notification sound + toast
```

### Database Events Monitored

**INSERT (New Orders):**
```sql
-- When a new order is inserted into `orders` table
-- Dashboard receives full order with items
-- Triggers: NEW badge, sound, toast, auto-switch to pending
```

**UPDATE (Status Changes):**
```sql
-- When order status changes (pending → preparing → ready → completed)
-- Dashboard updates the order card in real-time
-- Triggers: Status badge update, toast notification
```

**DELETE (Cancellations):**
```sql
-- When an order is deleted
-- Dashboard removes the order card
```

### Row Level Security (RLS)

Real-time subscriptions respect RLS policies:

**Super Admins:**
- See ALL orders from ALL stores
- No filter applied

**Admins/Managers/Staff:**
- See only orders from their assigned store
- Filter: `store_id = user.profile.store_id`

**Anonymous/Public:**
- Can insert orders (guest checkout)
- Can update order status (for mobile order tracking)

## Testing Real-Time Updates

### Test from Web Dashboard

1. Open dashboard: http://localhost:8080/dashboard-login
2. Log in as staff/admin
3. Go to "Orders" tab
4. Open a second browser tab/window
5. Navigate to: http://localhost:8080/order
6. Place a test order
7. **Result:** Dashboard should instantly show:
   - Toast notification "🔔 New Order Received!"
   - Audio beep
   - Order card with green "NEW" badge
   - Auto-switch to "Pending" tab
   - Notification badge on pending tab

### Test from iOS App

1. Open web dashboard on computer
2. Log in and go to Orders tab
3. Open iOS app on phone
4. Place an order as a guest
5. **Result:** Web dashboard should instantly update
   - Same visual/audio notifications
   - Order appears in real-time

### Test Status Updates

1. Dashboard shows pending order
2. Click "Accept" button
3. **Result:**
   - Order moves to "Preparing" tab
   - Status badge changes to blue "PREPARING"
   - Toast: "Order is now being prepared"
   - iOS app order tracking updates (if customer is tracking)

## Browser Compatibility

**Audio Notifications:**
- ✅ Chrome/Edge: Full support
- ✅ Firefox: Full support
- ✅ Safari: Full support (may require user interaction first)
- ✅ iOS Safari: Full support (may require user interaction first)

**Real-Time Updates:**
- ✅ All modern browsers with WebSocket support
- ✅ iOS Safari (native WebSocket)
- ✅ React Native (iOS app)

## Troubleshooting

### Orders Not Updating in Real-Time

**Check:**
1. **Network connection:** Ensure stable internet
2. **Supabase status:** Check https://status.supabase.io
3. **Browser console:** Look for WebSocket connection errors
4. **RLS policies:** Verify user has access to their store's orders

**Fix:**
- Click "Refresh" button in dashboard
- Reload page
- Check Supabase project settings

### Audio Not Playing

**Possible causes:**
- Browser autoplay policy (requires user interaction first)
- Device on silent/mute
- Browser permissions

**Fix:**
- Click anywhere on the page after loading (user interaction)
- Check device volume
- Check browser settings for audio permissions

### New Badge Stuck

**If "NEW" badge doesn't disappear:**
- Badge should auto-remove after 10 seconds
- Manual refresh will clear it
- This is a visual indicator only, doesn't affect functionality

## Configuration

### Notification Duration

To change how long the "NEW" indicator shows:

```typescript
// src/components/dashboard/OrderManagement.tsx
// Line ~103

setTimeout(() => {
  // Remove "new" indicator
}, 10000); // Change from 10000ms (10 sec) to desired duration
```

### Audio Notification Settings

To change beep frequency/volume:

```typescript
// src/components/dashboard/OrderManagement.tsx
// Lines 163-165

oscillator.frequency.value = 800;  // First beep (Hz)
oscillator2.frequency.value = 1000; // Second beep (Hz)
gainNode.gain.setValueAtTime(0.3, ...); // Volume (0.0 - 1.0)
```

### Toast Duration

To change notification popup duration:

```typescript
// src/components/dashboard/OrderManagement.tsx
// Line 93

duration: 8000, // Change from 8000ms (8 sec) to desired duration
```

## Performance Notes

**Efficient Updates:**
- Only fetches data that changed
- Uses Supabase's row-level diffing
- Minimal bandwidth usage
- No polling (push-based updates)

**Scalability:**
- Handles 100+ orders per day
- WebSocket connection is persistent
- Automatic reconnection on network issues
- Graceful degradation if realtime fails (manual refresh still works)

## Future Enhancements

Potential improvements for future versions:

- [ ] Desktop push notifications (using Notification API)
- [ ] SMS notifications for urgent orders
- [ ] Email notifications for order status changes
- [ ] Order sound customization (upload custom sounds)
- [ ] Kitchen display system (KDS) integration
- [ ] Printer auto-print for new orders
- [ ] Order queue management (drag and drop priority)
- [ ] Multi-device order claiming (prevent duplicate preparation)

## Related Files

**Hook:**
- `src/hooks/useRealtimeOrders.ts` - Real-time subscription logic

**Component:**
- `src/components/dashboard/OrderManagement.tsx` - UI and notifications

**Backend:**
- `supabase/migrations/019_allow_anon_order_updates.sql` - RLS policies
- `supabase/migrations/020_simplify_order_policies.sql` - Public access

**Documentation:**
- `CLAUDE.md` - Project overview
- `READY_FOR_CUSTOMER.md` - Launch documentation
