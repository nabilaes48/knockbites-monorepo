# Cameron's Customer App - Implementation Plan
**Execution Order:** Priority 1 → Priority 2 → Priority 3
**Total Timeline:** 4-6 weeks to production-ready
**Last Updated:** November 19, 2025

---

## 📋 Overview

This document provides a step-by-step implementation plan for completing the Cameron's Customer App. Each priority is broken down into daily tasks with clear deliverables and testing checkpoints.

---

## 🔴 PRIORITY 1: Complete Backend Integration (Week 1-2)

**Goal:** Enable real-time order tracking and notifications
**Timeline:** 8-10 days
**Business Impact:** Customers can track orders live, reducing support calls

### Phase 1.1: Supabase Realtime Integration (Days 1-3)

#### Day 1: Setup & Channel Configuration
**Tasks:**
1. ✅ Install Supabase Realtime dependencies (already included in SDK)
2. Create `RealtimeManager.swift` service class
3. Configure Realtime channels for order subscriptions
4. Add connection state management (connected/disconnected)
5. Implement automatic reconnection logic

**Code Structure:**
```swift
RealtimeManager.swift
├── subscribeToOrder(orderId:) -> RealtimeChannel
├── unsubscribeFromOrder(orderId:)
├── handleOrderUpdate(payload:)
└── ConnectionState enum (connected, disconnecting, disconnected)
```

**Deliverables:**
- [ ] RealtimeManager service created
- [ ] Basic channel subscription working
- [ ] Console logging shows connection status

**Testing:**
- Subscribe to test order
- Manually update order in Supabase dashboard
- Verify app receives update without refresh

---

#### Day 2: OrderViewModel Integration
**Tasks:**
1. Update `OrderViewModel` to use RealtimeManager
2. Remove mock timer-based status updates
3. Add subscription lifecycle management (subscribe on view appear, unsubscribe on disappear)
4. Handle status transitions with animations
5. Add error handling for subscription failures

**Code Changes:**
```swift
OrderViewModel.swift
├── Remove: startMockStatusUpdates()
├── Add: subscribeToRealtime()
├── Add: handleRealtimeUpdate(_:)
└── Update: status progression logic
```

**Deliverables:**
- [ ] OrderTrackingView shows real-time updates
- [ ] No memory leaks (proper unsubscribe)
- [ ] Smooth animations on status changes

**Testing:**
- Place test order
- Update status in Supabase dashboard
- Verify UI updates within 2 seconds
- Background/foreground app, verify reconnection

---

#### Day 3: Multi-Order Support & Optimization
**Tasks:**
1. Support tracking multiple orders simultaneously
2. Add order list view with live status badges
3. Optimize subscription management (only subscribe to active orders)
4. Add network status indicator
5. Cache last known status for offline viewing

**Code Structure:**
```swift
OrderViewModel
├── activeOrderSubscriptions: [String: RealtimeChannel]
├── subscribeToActiveOrders()
└── updateOrderStatus(id:, newStatus:)
```

**Deliverables:**
- [ ] Order history shows live status updates
- [ ] Network indicator shows connection state
- [ ] Offline mode shows cached data

**Testing:**
- Place 3 orders
- Update all 3 in Supabase
- Verify all update correctly
- Test with airplane mode on/off

---

### Phase 1.2: Push Notifications (Days 4-6)

#### Day 4: APNs Setup & Configuration
**Tasks:**
1. Enable Push Notifications capability in Xcode
2. Create APNs certificates in Apple Developer Portal
3. Upload certificates to Supabase dashboard (or FCM if using Firebase)
4. Add notification permission request flow
5. Implement UNUserNotificationCenter delegate

**Code Structure:**
```swift
NotificationManager.swift
├── requestPermission()
├── registerForRemoteNotifications()
├── handleNotificationReceived(_:)
└── handleNotificationTapped(_:)
```

**Apple Developer Tasks:**
- [ ] Create APNs Auth Key or Certificate
- [ ] Enable Push Notifications for App ID
- [ ] Configure Notification entitlements

**Deliverables:**
- [ ] App requests notification permission on first launch
- [ ] Device token successfully registers
- [ ] Test notification sent from Supabase/FCM dashboard

**Testing:**
- Grant notification permission
- Send test push from Supabase dashboard
- Verify notification appears on device

---

#### Day 5: Order Status Notifications
**Tasks:**
1. Create Supabase Database Webhook for order updates
2. Set up Edge Function to send notifications
3. Implement notification templates for each status
4. Add deep linking (tap notification → open OrderTrackingView)
5. Handle foreground/background notification scenarios

**Supabase Setup:**
```sql
-- Database Webhook (Supabase Dashboard → Database → Webhooks)
CREATE TRIGGER order_status_changed
AFTER UPDATE ON orders
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION notify_order_update();
```

**Edge Function (JavaScript):**
```javascript
// supabase/functions/send-order-notification/index.ts
export default async function(req: Request) {
  const { order_id, status, user_id } = await req.json();

  // Get user's device token
  // Send push notification via APNs
  // Return success/failure
}
```

**Deliverables:**
- [ ] Database webhook triggers on status change
- [ ] Edge function sends push notification
- [ ] Notification includes order number and new status
- [ ] Tapping notification opens correct order

**Testing:**
- Place order
- Update status in Supabase
- Verify notification received
- Tap notification, verify deep link works

---

#### Day 6: Notification Preferences & Polish
**Tasks:**
1. Add notification settings screen
2. Allow users to enable/disable specific notification types
3. Add quiet hours preference
4. Store preferences in Supabase user profile
5. Add notification badge count on app icon

**Features:**
- [ ] Toggle: Order received
- [ ] Toggle: Order preparing
- [ ] Toggle: Order ready for pickup
- [ ] Toggle: Promotional offers
- [ ] Quiet hours: Start/end time picker

**Deliverables:**
- [ ] Settings screen with notification controls
- [ ] Preferences saved to database
- [ ] Edge function respects user preferences
- [ ] App badge shows unread notification count

**Testing:**
- Disable "preparing" notifications
- Update order to preparing
- Verify no notification sent
- Re-enable, verify notifications resume

---

### Phase 1.3: Enhanced Error Handling (Days 7-8)

#### Day 7: Network Error Recovery
**Tasks:**
1. Add network reachability monitoring
2. Implement exponential backoff for retries
3. Create offline queue for failed order submissions
4. Add user-friendly error messages
5. Implement toast notifications for errors

**Code Structure:**
```swift
NetworkMonitor.swift
├── isConnected: Published<Bool>
├── connectionType: WiFi/Cellular/None
└── startMonitoring()

OfflineQueue.swift
├── queuedOrders: [PendingOrder]
├── addToQueue(_:)
├── processQueue() async
└── retryFailedOrder(_:)
```

**Error Scenarios to Handle:**
- Network timeout (show retry button)
- Server error 500 (show "try again later")
- Invalid data (show "please contact support")
- Rate limiting (show wait time)

**Deliverables:**
- [ ] Network status indicator in UI
- [ ] Failed orders queued locally
- [ ] Auto-retry when connection restored
- [ ] Clear error messages for users

**Testing:**
- Enable airplane mode
- Try to place order
- Disable airplane mode
- Verify order auto-submits

---

#### Day 8: Monitoring & Crash Reporting
**Tasks:**
1. Integrate Firebase Crashlytics (or Sentry)
2. Add custom crash reporting for critical flows
3. Implement performance monitoring
4. Add analytics events for key actions
5. Create error logging service

**Analytics Events:**
```swift
Analytics.logEvent("order_placed", parameters: [
  "order_id": orderId,
  "total": total,
  "items": itemCount,
  "payment_method": paymentMethod
])

Analytics.logEvent("order_failed", parameters: [
  "error": errorMessage,
  "step": "payment" // or "submission", "validation"
])
```

**Deliverables:**
- [ ] Crashlytics integrated and tested
- [ ] Custom events tracked for order flow
- [ ] Performance metrics collected
- [ ] Error dashboard setup (Firebase Console)

**Testing:**
- Force a crash (test button)
- Verify crash appears in dashboard
- Log test events
- Verify events in analytics

---

### ✅ Phase 1 Checkpoint
**Validation Criteria:**
- ✅ Orders update in real-time without manual refresh
- ✅ Push notifications arrive within 5 seconds of status change
- ✅ App handles offline scenarios gracefully
- ✅ No crashes during order flow
- ✅ Error messages are clear and actionable

**Demo Video:**
- Record placing order, receiving real-time updates, and push notification

---

## 🟡 PRIORITY 2: User Experience Enhancements (Week 3-4)

**Goal:** Improve retention through better authentication and personalization
**Timeline:** 10-12 days
**Business Impact:** Increased repeat orders and customer lifetime value

### Phase 2.1: Full Authentication System (Days 9-12)

#### Day 9: Apple Sign-In Integration
**Tasks:**
1. Enable "Sign in with Apple" capability
2. Add AuthenticationServices framework
3. Create Apple Sign-In button with branding guidelines
4. Implement credential handling
5. Link Apple ID to Supabase auth

**Apple Setup:**
- [ ] Enable "Sign in with Apple" in Xcode capabilities
- [ ] Configure App ID in Developer Portal
- [ ] Add Sign in with Apple key to Supabase

**Code Implementation:**
```swift
AuthViewModel.swift
├── signInWithApple() async throws
├── handleAppleCredential(_:)
└── linkAppleAccountToSupabase(_:)
```

**Deliverables:**
- [ ] Apple Sign-In button on login screen
- [ ] One-tap sign in working
- [ ] User profile created in Supabase
- [ ] Session persists across app restarts

**Testing:**
- Tap Apple Sign-In button
- Authenticate with Face ID
- Verify user logged in
- Force quit app, reopen, verify still logged in

---

#### Day 10: Google Sign-In Integration
**Tasks:**
1. Add GoogleSignIn SDK via SPM
2. Configure Google OAuth in Supabase
3. Create Google Sign-In button
4. Implement credential exchange
5. Handle account selection for multi-Google accounts

**Google Setup:**
- [ ] Create OAuth 2.0 Client ID in Google Cloud Console
- [ ] Add URL schemes to Info.plist
- [ ] Configure redirect URLs

**Deliverables:**
- [ ] Google Sign-In button on login screen
- [ ] OAuth flow completes successfully
- [ ] User data syncs to Supabase

**Testing:**
- Sign in with Google
- Select different Google account
- Verify profile picture and name fetched

---

#### Day 11: Phone Verification (OTP)
**Tasks:**
1. Add phone number input with country code picker
2. Integrate Supabase Phone Auth
3. Create OTP input screen (6-digit code)
4. Implement SMS verification
5. Add resend code functionality

**UI Flow:**
```
LoginView
  ↓ Tap "Use Phone Number"
PhoneInputView (enter +1 555-123-4567)
  ↓ Tap "Send Code"
OTPInputView (enter 123456)
  ↓ Auto-verify when 6 digits entered
HomeView (logged in)
```

**Deliverables:**
- [ ] Phone input with country picker
- [ ] SMS sent via Supabase Auth
- [ ] OTP verification working
- [ ] Resend code after 30 seconds

**Testing:**
- Enter phone number
- Receive SMS code
- Enter code
- Verify login successful

---

#### Day 12: Biometric Authentication & Account Linking
**Tasks:**
1. Implement Face ID / Touch ID for quick login
2. Store credentials securely in Keychain
3. Add "Enable Face ID" toggle in settings
4. Implement guest → registered account migration
5. Transfer guest orders to registered account

**Security:**
```swift
KeychainManager.swift
├── saveCredentials(_:)
├── retrieveCredentials()
├── deleteCredentials()
└── biometricAuthenticate() -> Bool
```

**Guest Migration Flow:**
```
Guest User (has 3 orders in cart)
  ↓ Signs up with Apple
MigrationService
  ├── Transfer local order history to Supabase
  ├── Link favorites to user account
  └── Sync cart to cloud
```

**Deliverables:**
- [ ] Face ID login works
- [ ] Keychain stores tokens securely
- [ ] Guest orders migrate to account
- [ ] Settings allow disabling biometrics

**Testing:**
- Use app as guest, add items to cart
- Sign up with Apple
- Verify cart items still present
- Enable Face ID, force quit, reopen
- Verify Face ID prompt appears

---

### Phase 2.2: Saved Addresses (Days 13-14)

#### Day 13: Address Management UI
**Tasks:**
1. Create AddressListView
2. Add AddAddressView form
3. Implement address validation
4. Add Google Places autocomplete
5. Create "default address" selection

**Database Schema:**
```sql
CREATE TABLE user_addresses (
  id SERIAL PRIMARY KEY,
  user_id TEXT REFERENCES auth.users(id),
  label TEXT, -- "Home", "Work", "Mom's House"
  street_address TEXT,
  apt_unit TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  delivery_instructions TEXT,
  is_default BOOLEAN DEFAULT false,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Deliverables:**
- [ ] Address list screen
- [ ] Add/edit address form
- [ ] Address autocomplete working
- [ ] Set default address

**Testing:**
- Add 3 addresses
- Set one as default
- Edit address
- Delete address

---

#### Day 14: GPS Location Picker & Integration
**Tasks:**
1. Add location permission request
2. Implement map view for address selection
3. Reverse geocode lat/lng to address
4. Integrate addresses into checkout flow
5. Add "use current location" quick button

**Location Features:**
- [ ] Request location permission
- [ ] Show current location on map
- [ ] Drag pin to select delivery location
- [ ] Auto-fill address from GPS

**Deliverables:**
- [ ] Map picker for address selection
- [ ] Current location button
- [ ] Addresses selectable during checkout
- [ ] Recent addresses shown first

**Testing:**
- Tap "Use Current Location"
- Verify address auto-filled
- Place order with saved address
- Verify delivery address correct

---

### Phase 2.3: Cloud-Synced Order History (Days 15-16)

#### Day 15: Migrate Order History to Supabase
**Tasks:**
1. Create order history fetching function
2. Migrate local orders to database
3. Update OrderViewModel to fetch from cloud
4. Add pull-to-refresh
5. Implement infinite scroll pagination

**Code Changes:**
```swift
SupabaseManager.swift
├── fetchOrderHistory(userId:, limit:, offset:) async throws
├── fetchOrderDetails(orderId:) async throws
└── deleteOrder(orderId:) async throws

OrderViewModel.swift
├── Remove: UserDefaults order storage
├── Add: loadOrderHistory() async
└── Add: loadMoreOrders() async
```

**Deliverables:**
- [ ] Order history fetched from Supabase
- [ ] Pull-to-refresh updates list
- [ ] Pagination loads 20 orders at a time
- [ ] Cross-device sync working

**Testing:**
- Place order on device A
- Sign in on device B
- Verify order appears on device B
- Scroll to load older orders

---

#### Day 16: Enhanced Order Details & Receipts
**Tasks:**
1. Create detailed receipt view
2. Show itemized pricing breakdown
3. Add tax calculation display
4. Generate PDF receipt
5. Add email receipt functionality

**Receipt Features:**
- Order number and date
- Store location
- Itemized list with quantities
- Subtotal, tax, total
- Payment method
- Delivery/pickup details

**Deliverables:**
- [ ] Detailed receipt view
- [ ] PDF generation working
- [ ] Share receipt via email/text
- [ ] Printer-friendly format

**Testing:**
- View order receipt
- Generate PDF
- Share via Messages
- Print receipt (if printer available)

---

### ✅ Phase 2 Checkpoint
**Validation Criteria:**
- ✅ Users can sign in with Apple/Google in < 30 seconds
- ✅ Phone number login with OTP works
- ✅ Face ID/Touch ID quick login enabled
- ✅ Saved addresses work with autocomplete
- ✅ Order history syncs across all devices
- ✅ Receipts are detailed and shareable

**Demo Video:**
- Sign in with Apple
- Add address with autocomplete
- Place order
- View detailed receipt

---

## 🟢 PRIORITY 3: Payment & Checkout (Week 5-6)

**Goal:** Enable real payments and launch-ready checkout
**Timeline:** 10-12 days
**Business Impact:** CRITICAL - Unlocks revenue generation

### Phase 3.1: Stripe Integration (Days 17-20)

#### Day 17: Stripe Account & SDK Setup
**Tasks:**
1. Create Stripe account (or use existing)
2. Add Stripe iOS SDK via SPM
3. Configure Stripe publishable key
4. Create Supabase Edge Function for PaymentIntents
5. Set up Stripe webhook for payment events

**Stripe Dashboard Setup:**
- [ ] Create account at stripe.com
- [ ] Get API keys (test mode)
- [ ] Enable payment methods (card, Apple Pay)
- [ ] Configure webhook endpoint

**Dependencies:**
```swift
// Package.swift
.package(url: "https://github.com/stripe/stripe-ios", from: "23.0.0")
```

**Deliverables:**
- [ ] Stripe SDK integrated
- [ ] Test API keys configured
- [ ] Edge function created for server-side PaymentIntent

**Testing:**
- Import Stripe SDK successfully
- Call test API endpoint
- Verify connection to Stripe

---

#### Day 18: Payment Sheet Implementation
**Tasks:**
1. Create PaymentManager service
2. Implement Stripe PaymentSheet
3. Add card input UI
4. Handle payment confirmation
5. Implement 3D Secure authentication

**Payment Flow:**
```swift
1. User taps "Place Order"
2. CartViewModel.checkout()
3. Create PaymentIntent (server-side Edge Function)
4. Show Stripe PaymentSheet
5. User enters card or selects saved card
6. Stripe processes payment
7. On success: Submit order to Supabase
8. Navigate to order confirmation
```

**Code Structure:**
```swift
PaymentManager.swift
├── createPaymentIntent(amount:) async throws -> String
├── presentPaymentSheet(clientSecret:) async throws
├── handlePaymentResult(_:)
└── savePaymentMethod(_:)
```

**Deliverables:**
- [ ] Payment sheet appears on checkout
- [ ] Card entry works smoothly
- [ ] Payment processes successfully
- [ ] Error handling for declined cards

**Testing:**
- Use Stripe test card: 4242 4242 4242 4242
- Enter expiry: 12/34, CVC: 123
- Complete payment
- Verify charge in Stripe dashboard

---

#### Day 19: Saved Payment Methods
**Tasks:**
1. Enable "Save card for future" checkbox
2. Store payment method securely in Stripe
3. List saved cards in checkout
4. Allow deleting saved cards
5. Set default payment method

**Security:**
- **NEVER** store card numbers in your database
- Use Stripe's tokenization
- Store only `payment_method_id` from Stripe

**Database Schema:**
```sql
CREATE TABLE user_payment_methods (
  id SERIAL PRIMARY KEY,
  user_id TEXT REFERENCES auth.users(id),
  stripe_payment_method_id TEXT UNIQUE,
  card_brand TEXT, -- "visa", "mastercard"
  last_four TEXT, -- "4242"
  exp_month INTEGER,
  exp_year INTEGER,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Deliverables:**
- [ ] Save card option in payment sheet
- [ ] Saved cards listed in profile
- [ ] One-tap checkout with saved card
- [ ] Delete card functionality

**Testing:**
- Save test card
- Place new order
- Select saved card
- Verify no card entry required

---

#### Day 20: Payment Error Handling & Edge Cases
**Tasks:**
1. Handle declined cards gracefully
2. Implement retry logic for network failures
3. Add payment cancellation handling
4. Prevent duplicate charges
5. Handle refunds (future orders cancellations)

**Error Scenarios:**
- Card declined (insufficient funds)
- Card expired
- Invalid CVC
- Network timeout during payment
- User cancels payment sheet

**Deliverables:**
- [ ] Clear error messages for all scenarios
- [ ] Retry button on transient failures
- [ ] Idempotency keys prevent duplicate charges
- [ ] Payment status tracked in orders table

**Testing:**
- Use Stripe test cards for each error type
  - Declined: 4000 0000 0000 0002
  - Insufficient funds: 4000 0000 0000 9995
  - Expired: Use past expiry date
- Verify appropriate error shown

---

### Phase 3.2: Apple Pay Integration (Days 21-22)

#### Day 21: Apple Pay Setup
**Tasks:**
1. Enable Apple Pay capability in Xcode
2. Create Merchant ID in Apple Developer Portal
3. Upload CSR to create merchant identity certificate
4. Configure PassKit
5. Add Apple Pay button to checkout

**Apple Developer Setup:**
- [ ] Create Merchant ID: merchant.com.camerons.app
- [ ] Generate merchant identity certificate
- [ ] Add Merchant ID to App ID configuration
- [ ] Enable Apple Pay capability in Xcode

**Code Implementation:**
```swift
ApplePayManager.swift
├── canMakePayments() -> Bool
├── presentApplePaySheet(total:) async throws
├── handleApplePayAuthorization(_:)
└── processApplePayToken(_:)
```

**Deliverables:**
- [ ] Apple Pay button appears on checkout
- [ ] Payment sheet shows correct total
- [ ] Payment processes successfully
- [ ] Integrates with existing Stripe flow

**Testing:**
- Add test card to Wallet app
- Tap Apple Pay button
- Authenticate with Face ID
- Verify payment successful

---

#### Day 22: Apple Pay Optimization & Testing
**Tasks:**
1. Add shipping/delivery contact collection
2. Handle address selection in Apple Pay sheet
3. Update total dynamically based on delivery address
4. Add order summary in payment sheet
5. Optimize for one-tap checkout

**Features:**
- Pre-fill shipping address from Wallet
- Show order items in payment sheet
- Calculate tax based on delivery address
- Save shipping info to user profile

**Deliverables:**
- [ ] Address auto-fills from Wallet
- [ ] Tax calculated from address
- [ ] One-tap checkout complete in < 10 seconds
- [ ] Shipping info saved for future orders

**Testing:**
- Use Apple Pay with different addresses
- Verify tax recalculates
- Complete full checkout
- Time the checkout flow

---

### Phase 3.3: Cart Persistence & Promo Codes (Days 23-24)

#### Day 23: Cloud Cart Sync
**Tasks:**
1. Create `user_carts` table in Supabase
2. Sync cart to cloud on item add/remove
3. Restore cart on login from any device
4. Handle cart conflicts (merge vs replace)
5. Implement cart expiration (24 hours)

**Database Schema:**
```sql
CREATE TABLE user_carts (
  id SERIAL PRIMARY KEY,
  user_id TEXT REFERENCES auth.users(id),
  menu_item_id INTEGER REFERENCES menu_items(id),
  quantity INTEGER,
  selected_options JSONB,
  special_instructions TEXT,
  added_at TIMESTAMP DEFAULT NOW()
);
```

**Code Changes:**
```swift
CartViewModel.swift
├── syncCartToCloud() async
├── loadCartFromCloud() async
├── mergeLocalAndCloudCart()
└── clearExpiredCartItems()
```

**Deliverables:**
- [ ] Cart syncs to cloud on changes
- [ ] Cart restores on login
- [ ] Cart persists across devices
- [ ] Old cart items auto-deleted after 24h

**Testing:**
- Add items to cart on device A
- Sign in on device B
- Verify cart items appear
- Wait 24 hours, verify old items cleared

---

#### Day 24: Promo Code System
**Tasks:**
1. Create `promo_codes` table
2. Add promo code input field in cart
3. Validate code against database
4. Apply discount to order total
5. Track code usage and limits

**Database Schema:**
```sql
CREATE TABLE promo_codes (
  id SERIAL PRIMARY KEY,
  code TEXT UNIQUE,
  discount_type TEXT, -- "percentage", "fixed", "free_delivery"
  discount_value DECIMAL,
  min_order_amount DECIMAL,
  max_uses INTEGER,
  current_uses INTEGER DEFAULT 0,
  valid_from TIMESTAMP,
  valid_until TIMESTAMP,
  is_active BOOLEAN DEFAULT true
);

CREATE TABLE promo_code_usage (
  id SERIAL PRIMARY KEY,
  promo_code_id INTEGER REFERENCES promo_codes(id),
  user_id TEXT REFERENCES auth.users(id),
  order_id INTEGER REFERENCES orders(id),
  discount_amount DECIMAL,
  used_at TIMESTAMP DEFAULT NOW()
);
```

**Promo Types:**
- Percentage: 20% off total
- Fixed: $5 off total
- Free delivery: $0 delivery fee
- First order: 15% off first order only

**UI Flow:**
```
CartView
  ├── "Have a promo code?" button
  ├── Text field appears
  ├── User enters: WELCOME20
  ├── Tap "Apply"
  ├── Validate code
  ├── Show: "20% off applied! -$8.40"
  └── Update total
```

**Deliverables:**
- [ ] Promo code input in cart
- [ ] Code validation working
- [ ] Discount applied correctly
- [ ] Usage tracked in database
- [ ] Expired/invalid codes show error

**Testing:**
- Create test codes: WELCOME20, FIRST5, FREEDEL
- Apply valid code, verify discount
- Apply expired code, verify error
- Reach max uses, verify "code no longer valid"

---

### Phase 3.4: Final Testing & Polish (Days 25-26)

#### Day 25: End-to-End Payment Testing
**Tasks:**
1. Test full checkout flow (guest & logged in)
2. Test all payment methods (card, Apple Pay, saved cards)
3. Test error scenarios (declined, network issues)
4. Verify order submission after successful payment
5. Test refund flow for cancelled orders

**Test Cases:**
- [ ] Guest checkout with new card
- [ ] Logged in user with saved card
- [ ] Apple Pay one-tap checkout
- [ ] Declined card shows error, allows retry
- [ ] Network failure during payment, retry succeeds
- [ ] Order appears in history after payment
- [ ] Receipt shows payment method used

**Deliverables:**
- [ ] All payment flows working end-to-end
- [ ] No crashes or freezes
- [ ] Error messages clear and helpful
- [ ] Loading states smooth

---

#### Day 26: Production Readiness
**Tasks:**
1. Switch from Stripe test mode to live mode
2. Configure production Supabase instance
3. Update API keys and secrets
4. Enable rate limiting and fraud detection
5. Final security audit

**Production Checklist:**
- [ ] Stripe live keys configured
- [ ] Supabase production database ready
- [ ] SSL certificate valid
- [ ] API rate limiting enabled
- [ ] PCI compliance verified
- [ ] Privacy policy updated with payment terms
- [ ] Support email configured

**Deliverables:**
- [ ] App connected to production systems
- [ ] Live payment successful
- [ ] All secrets secured (not in git)
- [ ] Monitoring dashboards configured

---

### ✅ Phase 3 Checkpoint
**Validation Criteria:**
- ✅ Payment success rate > 95% in testing
- ✅ Apple Pay checkout completes in < 10 seconds
- ✅ Saved cards work correctly
- ✅ Promo codes apply discounts accurately
- ✅ Cart syncs across devices
- ✅ All payment errors handled gracefully
- ✅ Production systems ready

**Demo Video:**
- Complete checkout with card
- Complete checkout with Apple Pay
- Apply promo code
- Show cart syncing across devices

---

## 🚀 Launch Preparation (Days 27-28)

### Day 27: Beta Testing
**Tasks:**
1. Deploy to TestFlight
2. Invite 10-20 beta testers
3. Collect feedback
4. Fix critical bugs
5. Monitor crash reports

**TestFlight Setup:**
- [ ] Build and archive app
- [ ] Upload to App Store Connect
- [ ] Create beta testing group
- [ ] Invite testers via email
- [ ] Enable crash reporting

---

### Day 28: App Store Submission
**Tasks:**
1. Create App Store listing
2. Prepare screenshots (6.5" and 5.5" displays)
3. Write app description
4. Record demo video
5. Submit for review

**App Store Listing:**
- Title: Cameron's - Order Pickup & Delivery
- Subtitle: Fresh food, fast and easy
- Keywords: restaurant, food, delivery, pickup, order
- Category: Food & Drink
- Age Rating: 4+

---

## 📊 Progress Tracking

### Week 1-2 Summary: Priority 1
- [ ] Day 1-3: Realtime order updates
- [ ] Day 4-6: Push notifications
- [ ] Day 7-8: Error handling & monitoring
- [ ] **Checkpoint:** Real-time tracking works end-to-end

### Week 3-4 Summary: Priority 2
- [ ] Day 9-12: Full authentication (Apple, Google, Phone, Biometrics)
- [ ] Day 13-14: Saved addresses with GPS picker
- [ ] Day 15-16: Cloud-synced order history
- [ ] **Checkpoint:** User experience polished

### Week 5-6 Summary: Priority 3
- [ ] Day 17-20: Stripe integration & saved cards
- [ ] Day 21-22: Apple Pay
- [ ] Day 23-24: Cart sync & promo codes
- [ ] Day 25-26: Testing & production readiness
- [ ] **Checkpoint:** Payment system production-ready

### Launch Week: Days 27-28
- [ ] Day 27: Beta testing
- [ ] Day 28: App Store submission

---

## 🎯 Success Metrics

### Technical Metrics
- Payment success rate: > 95%
- Order placement time: < 30 seconds
- App crash rate: < 0.1%
- API response time: < 2 seconds
- Push notification delivery: > 90% within 5 seconds

### Business Metrics
- User registration rate: > 40%
- Repeat order rate: > 30% within 30 days
- Average order value: $18+
- Cart abandonment rate: < 50%
- Customer support tickets: < 5% of orders

---

## 🔧 Development Guidelines

### Daily Workflow
1. **Morning:** Review previous day's work, plan today's tasks
2. **Development:** Code, commit frequently with clear messages
3. **Testing:** Test each feature before marking complete
4. **Documentation:** Update READY_FOR_CUSTOMER.md with changes
5. **Evening:** Push to GitHub, update progress tracker

### Commit Message Format
```
feat: Add Apple Pay integration

- Configured Merchant ID and PassKit
- Implemented payment authorization flow
- Added Apple Pay button to checkout
- Tested with test card in Wallet

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Testing Standards
- Test on both simulator and physical device
- Test with slow network (Network Link Conditioner)
- Test in airplane mode (offline scenarios)
- Test with low battery (performance impact)
- Test edge cases (empty states, max values)

### Code Review Checklist
- [ ] No force unwraps (`!`) in production code
- [ ] Proper error handling (try/catch)
- [ ] Memory leaks checked (Instruments)
- [ ] Accessibility labels added
- [ ] Loading states implemented
- [ ] Analytics events logged

---

## 📞 Support & Resources

### Documentation
- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- [Stripe iOS SDK Docs](https://stripe.com/docs/mobile/ios)
- [Apple Pay Programming Guide](https://developer.apple.com/apple-pay/)
- [Push Notifications Guide](https://developer.apple.com/documentation/usernotifications)

### Key Contacts
- **Supabase Support:** support@supabase.io
- **Stripe Support:** support@stripe.com
- **Apple Developer:** developer.apple.com/support
- **Project Manager:** [Your contact]

---

## ✅ Final Checklist

### Before Each Priority Completion
- [ ] All features tested on device
- [ ] No console errors or warnings
- [ ] READY_FOR_CUSTOMER.md updated
- [ ] Changes committed and pushed to GitHub
- [ ] Demo video recorded
- [ ] Team notified of completion

### Before Production Launch
- [ ] All three priorities completed
- [ ] Beta testing feedback addressed
- [ ] App Store listing ready
- [ ] Support email configured
- [ ] Privacy policy published
- [ ] Analytics configured
- [ ] Monitoring alerts set up
- [ ] Rollback plan documented

---

**This plan will be updated daily with progress and any adjustments needed.**

**Next Action:** Begin Priority 1, Day 1 - Supabase Realtime Setup
