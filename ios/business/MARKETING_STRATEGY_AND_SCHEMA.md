# Restaurant Marketing Strategy & Database Schema

## 🎯 Proven Marketing Strategy Framework

### The 3 Core Goals
1. **Increase Order Frequency** - Get customers to order more often
2. **Increase Average Order Value (AOV)** - Get customers to spend more per order
3. **Reduce Customer Churn** - Keep customers coming back

---

## 📊 Strategic Marketing Pillars

### 1. **Loyalty & Rewards Program** (Retention & Frequency)
**Proven Strategy**: Points-based system with tiered rewards

**Why It Works**:
- 65% of revenue comes from repeat customers
- Loyalty members spend 12-18% more per order
- Gamification drives engagement

**Implementation**:
- Earn 1 point per $1 spent
- Bonus points for first order, referrals, reviews
- Tiered system: Bronze → Silver → Gold → Platinum
- Exclusive perks at higher tiers

---

### 2. **Smart Coupons & Promotions** (Acquisition & AOV)
**Proven Strategy**: Strategic discount timing and targeting

**Types of Coupons**:
- **Welcome Discount**: 15% off first order → Convert new customers
- **Minimum Order Coupons**: $5 off orders $30+ → Increase AOV
- **BOGO (Buy One Get One)**: → Increase order size
- **Seasonal Specials**: Holiday promotions → Drive urgency
- **Abandoned Cart Recovery**: 10% off if you complete order → Recover lost sales
- **Time-Based**: Happy Hour 20% off 2-5pm → Fill slow periods
- **Loyalty Tier Exclusive**: VIP-only coupons → Reward best customers

**Why It Works**:
- 57% of customers wait for deals before ordering
- Minimum order coupons increase AOV by 25-40%
- Time-based promotions smooth demand throughout day

---

### 3. **Automated Push Notifications** (Engagement & Re-activation)
**Proven Strategy**: Triggered, personalized messages at the right time

**Notification Types**:

**Transactional** (High Open Rate: 80%+):
- Order confirmed
- Order ready for pickup
- Driver on the way
- Order delivered

**Promotional** (Open Rate: 15-25%):
- **New Customer Welcome**: "Welcome! Here's 15% off your first order"
- **Order Reminder**: "Haven't seen you in 2 weeks! Here's $5 off"
- **Lunch Special**: "Today's special: $8.99 combo meal 🍔"
- **Weekend Promo**: "Friday Happy Hour: 20% off 4-7pm 🍻"
- **Birthday Rewards**: "Happy Birthday! Free dessert on us 🎂"
- **Re-engagement**: "We miss you! 20% off your next order"

**Smart Timing**:
- Lunch reminder: 11:00 AM
- Dinner reminder: 5:00 PM
- Weekend promo: Friday 3:00 PM
- Re-engagement: After 14 days of inactivity

**Why It Works**:
- Push notifications have 7x higher engagement than email
- Automated campaigns recover 20% of dormant customers
- Right message at right time = 3x conversion rate

---

### 4. **Customer Segmentation** (Targeting & Personalization)
**Proven Strategy**: Different messages for different customer types

**Segments**:
- **New Customers** (0-1 orders): Welcome journey, onboarding
- **Active Customers** (2+ orders/month): Loyalty rewards, new items
- **VIP Customers** (10+ orders): Exclusive perks, early access
- **At-Risk** (30+ days inactive): Win-back campaigns
- **Churned** (90+ days inactive): Aggressive re-activation

**Why It Works**:
- Personalized campaigns have 6x higher conversion
- Segmentation increases campaign ROI by 760%

---

### 5. **Referral Program** (Acquisition)
**Proven Strategy**: Give $10, Get $10

**How It Works**:
- Existing customer refers friend
- Friend gets $10 off first order
- Existing customer gets $10 credit when friend orders
- Unlimited referrals

**Why It Works**:
- Referred customers have 16% higher lifetime value
- 83% of satisfied customers willing to refer
- Lowest cost customer acquisition channel

---

## 🗄️ Database Schema

### Table 1: `loyalty_programs`
Master configuration for the loyalty program

```sql
CREATE TABLE loyalty_programs (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id),
  name VARCHAR(200) NOT NULL DEFAULT 'Rewards Program',
  points_per_dollar DECIMAL(5,2) DEFAULT 1.00,
  welcome_bonus_points INT DEFAULT 100,
  referral_bonus_points INT DEFAULT 500,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Table 2: `loyalty_tiers`
Different reward levels (Bronze, Silver, Gold, Platinum)

```sql
CREATE TABLE loyalty_tiers (
  id SERIAL PRIMARY KEY,
  program_id INT REFERENCES loyalty_programs(id),
  name VARCHAR(100) NOT NULL, -- 'Bronze', 'Silver', 'Gold', 'Platinum'
  min_points INT NOT NULL,
  discount_percentage DECIMAL(5,2) DEFAULT 0, -- e.g., 5% off all orders
  free_delivery BOOLEAN DEFAULT false,
  priority_support BOOLEAN DEFAULT false,
  early_access_promos BOOLEAN DEFAULT false,
  birthday_reward_points INT DEFAULT 0,
  tier_color VARCHAR(20), -- For UI: '#CD7F32', '#C0C0C0', '#FFD700', '#E5E4E2'
  sort_order INT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Example tiers:
-- Bronze: 0 points, no perks
-- Silver: 500 points, 5% discount
-- Gold: 2000 points, 10% discount + free delivery
-- Platinum: 5000 points, 15% discount + all perks
```

### Table 3: `customer_loyalty`
Track each customer's points and tier

```sql
CREATE TABLE customer_loyalty (
  id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customers(id) UNIQUE,
  program_id INT REFERENCES loyalty_programs(id),
  current_tier_id INT REFERENCES loyalty_tiers(id),
  total_points INT DEFAULT 0,
  lifetime_points INT DEFAULT 0, -- Never decreases
  total_orders INT DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0,
  joined_at TIMESTAMP DEFAULT NOW(),
  last_order_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Table 4: `loyalty_transactions`
Point earning and redemption history

```sql
CREATE TABLE loyalty_transactions (
  id SERIAL PRIMARY KEY,
  customer_loyalty_id INT REFERENCES customer_loyalty(id),
  order_id INT REFERENCES orders(id),
  transaction_type VARCHAR(50) NOT NULL, -- 'earn', 'redeem', 'bonus', 'expire', 'adjustment'
  points INT NOT NULL, -- Positive for earn, negative for redeem
  reason VARCHAR(200), -- 'Order #1234', 'Welcome bonus', 'Birthday reward', etc.
  balance_after INT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Table 5: `coupons`
All types of discounts and promotions

```sql
CREATE TABLE coupons (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id),

  -- Basic Info
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(200) NOT NULL,
  description TEXT,

  -- Discount Type
  discount_type VARCHAR(20) NOT NULL, -- 'percentage', 'fixed_amount', 'free_item', 'bogo'
  discount_value DECIMAL(10,2) NOT NULL, -- 15 for 15%, or 5.00 for $5 off

  -- Conditions
  min_order_value DECIMAL(10,2) DEFAULT 0,
  max_discount_amount DECIMAL(10,2), -- Cap for percentage discounts
  applicable_order_types TEXT[], -- ['takeout', 'delivery', 'dine-in'] or NULL for all
  applicable_menu_categories INT[], -- Array of category IDs, or NULL for all
  first_order_only BOOLEAN DEFAULT false,

  -- Usage Limits
  max_uses_total INT, -- NULL = unlimited
  max_uses_per_customer INT DEFAULT 1,
  current_uses INT DEFAULT 0,

  -- Timing
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP,
  active_days_of_week INT[], -- [0,1,2,3,4,5,6] for Sun-Sat, NULL for all days
  active_hours_start TIME, -- e.g., '14:00' for 2pm
  active_hours_end TIME,   -- e.g., '17:00' for 5pm

  -- Targeting
  target_segment VARCHAR(50), -- 'new_customers', 'loyal_customers', 'inactive', 'all'
  minimum_tier_id INT REFERENCES loyalty_tiers(id), -- Tier required to use coupon

  -- Status
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,

  -- Metadata
  created_by INT REFERENCES user_profiles(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_coupons_code ON coupons(code);
CREATE INDEX idx_coupons_store_active ON coupons(store_id, is_active);
CREATE INDEX idx_coupons_dates ON coupons(start_date, end_date);
```

### Table 6: `coupon_usage`
Track who used which coupons

```sql
CREATE TABLE coupon_usage (
  id SERIAL PRIMARY KEY,
  coupon_id INT REFERENCES coupons(id),
  customer_id INT REFERENCES customers(id),
  order_id INT REFERENCES orders(id),
  discount_amount DECIMAL(10,2) NOT NULL,
  used_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_coupon_usage_customer ON coupon_usage(customer_id);
CREATE INDEX idx_coupon_usage_coupon ON coupon_usage(coupon_id);
```

### Table 7: `push_notifications`
Scheduled and sent notifications

```sql
CREATE TABLE push_notifications (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id),

  -- Content
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  image_url VARCHAR(500),
  action_url VARCHAR(500), -- Deep link: 'app://menu/category/1' or 'app://order/123'

  -- Targeting
  target_segment VARCHAR(50), -- 'all', 'new_customers', 'active', 'inactive', 'vip'
  target_customer_ids INT[], -- Specific customers, or NULL for segment
  target_tier_ids INT[], -- Target specific loyalty tiers

  -- Scheduling
  scheduled_for TIMESTAMP,
  send_immediately BOOLEAN DEFAULT false,

  -- Status
  status VARCHAR(20) DEFAULT 'draft', -- 'draft', 'scheduled', 'sending', 'sent', 'failed'
  sent_at TIMESTAMP,

  -- Analytics
  recipients_count INT DEFAULT 0,
  delivered_count INT DEFAULT 0,
  opened_count INT DEFAULT 0,
  clicked_count INT DEFAULT 0,

  -- Metadata
  created_by INT REFERENCES user_profiles(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notifications_store_status ON push_notifications(store_id, status);
CREATE INDEX idx_notifications_scheduled ON push_notifications(scheduled_for);
```

### Table 8: `notification_deliveries`
Track individual notification sends

```sql
CREATE TABLE notification_deliveries (
  id SERIAL PRIMARY KEY,
  notification_id INT REFERENCES push_notifications(id),
  customer_id INT REFERENCES customers(id),
  device_token VARCHAR(500), -- FCM/APNs token

  -- Status
  delivery_status VARCHAR(20), -- 'sent', 'delivered', 'opened', 'clicked', 'failed'

  -- Timestamps
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  opened_at TIMESTAMP,
  clicked_at TIMESTAMP,

  -- Error tracking
  error_message TEXT,

  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notification_deliveries_notification ON notification_deliveries(notification_id);
CREATE INDEX idx_notification_deliveries_customer ON notification_deliveries(customer_id);
```

### Table 9: `referral_program`
Configuration for referral program

```sql
CREATE TABLE referral_program (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id),

  -- Rewards
  referrer_reward_type VARCHAR(20), -- 'points', 'credit', 'coupon'
  referrer_reward_value DECIMAL(10,2), -- e.g., 500 points or $10 credit
  referee_reward_type VARCHAR(20),
  referee_reward_value DECIMAL(10,2),

  -- Conditions
  min_order_value DECIMAL(10,2) DEFAULT 0, -- Referee must order at least this much
  max_referrals_per_customer INT, -- NULL = unlimited

  -- Status
  is_active BOOLEAN DEFAULT true,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Table 10: `referrals`
Track who referred whom

```sql
CREATE TABLE referrals (
  id SERIAL PRIMARY KEY,
  program_id INT REFERENCES referral_program(id),

  -- Participants
  referrer_customer_id INT REFERENCES customers(id), -- Person who shared
  referee_customer_id INT REFERENCES customers(id),  -- Person who used code

  -- Referral Details
  referral_code VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'JOHN_5ABC3'

  -- Status
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'completed', 'rewarded', 'expired'

  -- Rewards
  referrer_rewarded BOOLEAN DEFAULT false,
  referee_rewarded BOOLEAN DEFAULT false,
  referrer_reward_order_id INT REFERENCES orders(id),
  referee_first_order_id INT REFERENCES orders(id),

  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  rewarded_at TIMESTAMP
);

CREATE INDEX idx_referrals_code ON referrals(referral_code);
CREATE INDEX idx_referrals_referrer ON referrals(referrer_customer_id);
CREATE INDEX idx_referrals_referee ON referrals(referee_customer_id);
```

### Table 11: `automated_campaigns`
Automated marketing workflows

```sql
CREATE TABLE automated_campaigns (
  id SERIAL PRIMARY KEY,
  store_id INT REFERENCES stores(id),

  -- Campaign Info
  name VARCHAR(200) NOT NULL,
  description TEXT,
  campaign_type VARCHAR(50), -- 'welcome_series', 'win_back', 'birthday', 'abandoned_cart', 'order_reminder'

  -- Trigger Conditions
  trigger_event VARCHAR(100), -- 'customer_signup', 'days_since_order', 'birthday', 'cart_abandoned'
  trigger_delay_hours INT DEFAULT 0, -- Wait X hours after trigger
  trigger_condition JSONB, -- Additional conditions: {"days_inactive": 14, "min_past_orders": 1}

  -- Message Content
  notification_title VARCHAR(200),
  notification_body TEXT,
  coupon_id INT REFERENCES coupons(id), -- Attach a coupon to campaign

  -- Status
  is_active BOOLEAN DEFAULT true,

  -- Analytics
  total_triggered INT DEFAULT 0,
  total_converted INT DEFAULT 0, -- Resulted in order

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Table 12: `campaign_executions`
Track when automated campaigns fire

```sql
CREATE TABLE campaign_executions (
  id SERIAL PRIMARY KEY,
  campaign_id INT REFERENCES automated_campaigns(id),
  customer_id INT REFERENCES customers(id),

  -- Execution
  triggered_at TIMESTAMP DEFAULT NOW(),
  notification_id INT REFERENCES push_notifications(id),

  -- Outcome
  converted BOOLEAN DEFAULT false,
  conversion_order_id INT REFERENCES orders(id),
  converted_at TIMESTAMP
);
```

---

## 🎬 Implementation Priority

### Phase 1: Foundation (Week 1)
1. ✅ Loyalty program structure
2. ✅ Basic coupons (code-based discounts)
3. ✅ Manual push notifications

### Phase 2: Automation (Week 2)
4. Automated campaigns (welcome, win-back)
5. Coupon usage tracking and analytics
6. Loyalty point accrual on orders

### Phase 3: Advanced (Week 3)
7. Referral program
8. Segmentation and targeting
9. A/B testing framework

---

## 📈 Key Metrics to Track

### Coupon Performance
- Redemption rate = Uses / Distributed
- Revenue impact = (Orders with coupon × AOV) - Discount amount
- New customer acquisition cost

### Loyalty Program
- Active members %
- Average points balance
- Redemption rate
- Tier distribution
- Lifetime value by tier

### Push Notifications
- Delivery rate = Delivered / Sent
- Open rate = Opened / Delivered
- Click-through rate = Clicked / Opened
- Conversion rate = Orders / Clicked

### Campaigns
- Campaign ROI = (Revenue - Cost) / Cost
- Customer lifetime value (CLV)
- Churn rate reduction
- Order frequency increase

---

## 🚀 Quick Wins (Implement These First)

### 1. **Welcome Discount** (Immediate)
- New customer gets 15% off first order
- Auto-generate unique code on signup
- **Expected Impact**: 40% increase in first-order conversion

### 2. **Minimum Order Coupon** (Week 1)
- "$5 off orders $30+"
- **Expected Impact**: 25-35% increase in AOV

### 3. **Win-Back Campaign** (Week 2)
- Auto-send "We miss you! 20% off" after 14 days inactive
- **Expected Impact**: Recover 15-20% of churning customers

### 4. **Simple Loyalty** (Week 2)
- 1 point per $1 spent
- 100 points = $5 off
- **Expected Impact**: 12-18% increase in repeat orders

---

## 💡 Pro Tips

1. **Start Simple**: Don't build everything at once. Launch one campaign type, measure, optimize, then add more.

2. **Mobile-First**: 80% of food orders are on mobile. Push notifications > Email.

3. **Test Everything**: A/B test discount amounts, message copy, send times. Small changes = big impact.

4. **Personalize**: "John, your favorite burger is back!" converts 3x better than generic promos.

5. **Time It Right**:
   - Breakfast: 7-8 AM
   - Lunch: 11 AM - 12 PM
   - Dinner: 5-6 PM
   - Weekend: Friday 3 PM

6. **Urgency Works**: "Today only!" or "2 hours left!" increases conversion by 25%.

7. **Exclusivity Works**: "VIP members only" or "First 50 customers" drives action.

---

**Next Steps**: Ready to create these tables in Supabase? 🚀
