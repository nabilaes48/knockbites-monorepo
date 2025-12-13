# Analytics Quick Start Guide

## 🚀 3 Simple Steps to Real Analytics

### Step 1: Run Migration in Supabase (5 minutes)

1. Open **Supabase Dashboard** → SQL Editor
2. Copy & paste entire file: `supabase/migrations/024_analytics_views.sql`
3. Click **Run**
4. ✅ You'll see success message

**What this does:**
- Creates 12 analytics database views
- Creates 3 Postgres functions
- Sets up all analytics infrastructure

---

### Step 2: Update Analytics Component (15 minutes)

Open `src/components/dashboard/Analytics.tsx` and add at the top:

```typescript
import { useAnalytics } from "@/hooks/useAnalytics";
```

Replace the mock data section with:

```typescript
const {
  metrics,
  revenueData,
  timeDistribution,
  categoryDistribution,
  popularItems,
  loading,
  error
} = useAnalytics(parseInt(selectedStore), dateRange);
```

Then replace these lines:

```typescript
// DELETE THIS:
const currentStoreData = generateStoreData(parseInt(selectedStore));
const revenueChartData = generateRevenueData(dateRange, selectedStore, timestamp);
const orderDistributionData = generateOrderDistribution(selectedStore, timestamp);
const categoryDistributionData = generateCategoryDistribution(selectedStore, timestamp);

// USE THIS INSTEAD:
// metrics is already loaded above
// revenueData is already loaded
// timeDistribution is already loaded
// categoryDistribution is already loaded
```

Update the KPI cards to use real data:

```typescript
// Revenue card
<p className="text-3xl font-bold text-green-100">
  ${metrics?.total_revenue ? Number(metrics.total_revenue).toFixed(2) : '0.00'}
</p>

// Orders card
<p className="text-3xl font-bold text-blue-100">
  {metrics?.total_orders || 0}
</p>

// Avg Order Value card
<p className="text-3xl font-bold text-purple-100">
  ${metrics?.avg_order_value ? Number(metrics.avg_order_value).toFixed(2) : '0.00'}
</p>

// Customers card
<p className="text-3xl font-bold text-orange-100">
  {metrics?.unique_customers || 0}
</p>
```

Update revenue chart data:

```typescript
<AreaChart data={revenueData.map(d => ({
  time: d.time_label,
  revenue: Number(d.revenue),
  orders: Number(d.orders)
}))}>
```

Update time distribution chart:

```typescript
<Pie
  data={timeDistribution.map(d => {
    const total = timeDistribution.reduce((sum, item) => sum + item.order_count, 0);
    return {
      name: d.time_period,
      value: d.order_count,
      percentage: total > 0 ? ((d.order_count / total) * 100).toFixed(1) : '0'
    };
  })}
```

Update popular items section:

```typescript
{popularItems.slice(0, 5).map((item, index) => (
  <div key={index} className="space-y-2">
    <div className="flex justify-between text-sm">
      <span className="font-medium">{item.item_name}</span>
      <div className="flex items-center gap-3">
        <span className="text-green-600 font-semibold">
          ${Number(item.total_revenue).toFixed(2)}
        </span>
        <span className="text-muted-foreground">
          {item.times_ordered} orders
        </span>
      </div>
    </div>
    <div className="w-full bg-muted rounded-full h-2">
      <div
        className="bg-secondary rounded-full h-2 transition-all"
        style={{
          width: `${(item.times_ordered / (popularItems[0]?.times_ordered || 1)) * 100}%`
        }}
      />
    </div>
  </div>
))}
```

Add loading and error states at the top of the component:

```typescript
if (loading) {
  return (
    <div className="flex items-center justify-center h-96">
      <Loader2 className="h-12 w-12 animate-spin text-primary" />
    </div>
  );
}

if (error) {
  return (
    <div className="text-center text-destructive py-8">
      <p>Error loading analytics: {error}</p>
      <Button onClick={refresh} className="mt-4">Retry</Button>
    </div>
  );
}
```

---

### Step 3: Test It! (5 minutes)

1. **Check the dashboard loads**
   - Go to Dashboard → Analytics tab
   - Should see $0.00 revenue, 0 orders (if no orders yet)
   - No errors in console

2. **Place a test order**
   - Go to http://localhost:8080/order
   - Select Highland Mills store
   - Add items to cart
   - Complete checkout

3. **Refresh analytics**
   - Go back to Analytics dashboard
   - Click refresh button
   - See your order appear in the metrics!

4. **Verify all data**
   - Revenue shows order total
   - Orders shows 1
   - Item appears in popular items
   - Charts update with real data

---

## ✅ Checklist

- [ ] Migration 024 ran successfully in Supabase
- [ ] useAnalytics hook imported
- [ ] KPI cards use metrics.* instead of mock data
- [ ] Charts use revenueData instead of generateRevenueData()
- [ ] Loading state added
- [ ] Error state added
- [ ] Test order placed
- [ ] Analytics shows real order data
- [ ] No console errors

---

## 🎯 What You Get

### Before
```typescript
const revenue = (1000 + (seed % 500)).toFixed(2); // FAKE!
```

### After
```typescript
const revenue = metrics.total_revenue; // REAL from database!
```

---

## 📊 Features Now Available

- ✅ Real-time revenue tracking
- ✅ Actual order counts
- ✅ Real customer metrics
- ✅ Genuine popular items
- ✅ True time distribution
- ✅ Accurate category sales
- ✅ Period comparisons
- ✅ Auto-refresh capability

---

## 🔥 Pro Mode (Optional)

### Add More Views

Customer insights:
```typescript
const { customerInsights } = useAnalytics(storeId, dateRange);

// Show:
// - customerInsights.repeat_rate (retention %)
// - customerInsights.avg_spent_per_customer
// - customerInsights.total_customers
```

Revenue goals:
```typescript
const { revenueGoals } = useAnalytics(storeId, dateRange);

// Show:
// - revenueGoals.revenue_goal (target)
// - revenueGoals.best_day_revenue
// - revenueGoals.avg_daily_revenue
```

Top customers:
```typescript
const { topCustomers } = useAnalytics(storeId, dateRange);

// Display top 10 customers by spending
topCustomers.map(customer => (
  <div>
    <p>{customer.customer_name}</p>
    <p>${customer.total_spent}</p>
    <p>{customer.total_orders} orders</p>
  </div>
))
```

Peak hours:
```typescript
const { peakHours } = useAnalytics(storeId, dateRange);

// Bar chart of orders by hour
<BarChart data={peakHours.map(h => ({
  hour: `${h.hour}:00`,
  orders: h.order_count,
  revenue: Number(h.revenue)
}))}>
```

---

## 🆘 Troubleshooting

### Error: "function get_store_metrics does not exist"
→ **Fix:** Run migration 024 in Supabase

### Error: "Cannot read property 'total_revenue' of null"
→ **Fix:** Add null checks: `metrics?.total_revenue || 0`

### Charts show no data
→ **Fix:** Place some test orders first

### Loading forever
→ **Fix:** Check Supabase connection, check console for errors

---

## 🎉 You're Done!

Your analytics now show **real business data** instead of fake numbers!

**Next:** Place more orders and watch your analytics grow! 📈
