# iOS Business App - Real Analytics with Supabase

## 📱 Message for iOS Business App Developer (Cursor)

---

**Subject: Implement Real Analytics Using Supabase Database Views**

Hey!

The web app analytics has been upgraded from mock data to **real Supabase queries**. I need you to do the same for the iOS business app.

**What's Ready:**
- ✅ Database migration 024 creates analytics views and functions
- ✅ All analytics data is pre-computed in Postgres views
- ✅ Optimized queries for fast performance

**What You Need to Do:**
Replace your current mock/fake analytics data with real Supabase queries using the new database views and functions.

See full details below.

---

## 🎯 Goal

Replace fake analytics data with real data from Supabase database views.

**Before**: Mock data generators showing fake numbers
**After**: Real order data from Supabase showing actual business metrics

---

## 📊 Available Supabase Analytics

### Database Views (Already Created)

#### 1. analytics_daily_stats
Daily aggregated metrics per store.

```sql
SELECT * FROM analytics_daily_stats
WHERE store_id = 1
ORDER BY date DESC
LIMIT 30;
```

**Returns:**
```json
{
  "store_id": 1,
  "date": "2025-11-19",
  "total_orders": 45,
  "total_revenue": 1234.56,
  "total_tax": 98.76,
  "total_with_tax": 1333.32,
  "avg_order_value": 27.43,
  "unique_customers": 38
}
```

#### 2. analytics_hourly_today
Hourly breakdown for today.

```sql
SELECT * FROM analytics_hourly_today
WHERE store_id = 1
ORDER BY hour;
```

**Returns:**
```json
{
  "store_id": 1,
  "hour": 14,
  "orders": 12,
  "revenue": 345.67
}
```

#### 3. analytics_time_distribution
Orders grouped by time of day (Breakfast, Lunch, Dinner, Late Night).

```sql
SELECT * FROM analytics_time_distribution
WHERE store_id = 1;
```

**Returns:**
```json
{
  "store_id": 1,
  "time_period": "Lunch",
  "order_count": 150,
  "revenue": 4125.50
}
```

#### 4. analytics_category_distribution
Orders grouped by menu category.

```sql
SELECT * FROM analytics_category_distribution
LIMIT 10;
```

**Returns:**
```json
{
  "category": "Signature Sandwiches",
  "subcategory": "Classic",
  "order_count": 120,
  "items_sold": 180,
  "total_revenue": 2160.00
}
```

#### 5. analytics_popular_items
Top-selling menu items per store.

```sql
SELECT * FROM analytics_popular_items
WHERE store_id = 1
LIMIT 5;
```

**Returns:**
```json
{
  "store_id": 1,
  "menu_item_id": 15,
  "item_name": "Classic Cheeseburger",
  "times_ordered": 145,
  "total_quantity": 203,
  "total_revenue": 1595.00,
  "avg_price": 11.00
}
```

---

### Postgres Functions (Already Created)

#### 1. get_store_metrics(store_id, date_range)
Get KPI metrics with period comparison.

```sql
SELECT * FROM get_store_metrics(1, 'today');
```

**Parameters:**
- `store_id`: 1-29 (store ID)
- `date_range`: 'today', 'week', 'month', 'quarter', 'year'

**Returns:**
```json
{
  "total_revenue": 1234.56,
  "total_orders": 45,
  "avg_order_value": 27.43,
  "unique_customers": 38,
  "revenue_change": 12.5,   // % change vs previous period
  "orders_change": 5         // change vs previous period
}
```

#### 2. get_revenue_chart_data(store_id, date_range)
Time-series revenue data for charts.

```sql
SELECT * FROM get_revenue_chart_data(1, 'today');
```

**Parameters:**
- `store_id`: 1-29
- `date_range`: 'today', 'week', 'month', 'quarter', 'year'

**Returns (Today - Hourly):**
```json
{
  "time_label": "2pm",
  "revenue": 345.67,
  "orders": 12
}
```

**Returns (Week - Daily):**
```json
{
  "time_label": "Mon",
  "revenue": 1234.56,
  "orders": 45
}
```

---

## 💻 Implementation Guide

### Step 1: Run Database Migration

First, make sure migration 024 is run in Supabase:

```bash
File: supabase/migrations/024_analytics_views.sql
```

This creates all the views and functions.

### Step 2: Create Analytics Service/Manager

Create a Swift service to fetch analytics from Supabase:

```swift
import Supabase

class AnalyticsService {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    // Fetch KPI metrics
    func getStoreMetrics(storeId: Int, dateRange: String = "today") async throws -> StoreMetrics {
        let response = try await supabase
            .rpc("get_store_metrics", params: [
                "p_store_id": storeId,
                "p_date_range": dateRange
            ])
            .execute()

        let metrics = try JSONDecoder().decode([StoreMetrics].self, from: response.data)
        return metrics.first!
    }

    // Fetch revenue chart data
    func getRevenueChartData(storeId: Int, dateRange: String = "today") async throws -> [RevenueChartPoint] {
        let response = try await supabase
            .rpc("get_revenue_chart_data", params: [
                "p_store_id": storeId,
                "p_date_range": dateRange
            ])
            .execute()

        return try JSONDecoder().decode([RevenueChartPoint].self, from: response.data)
    }

    // Fetch time distribution
    func getTimeDistribution(storeId: Int) async throws -> [TimeDistribution] {
        let response = try await supabase
            .from("analytics_time_distribution")
            .select()
            .eq("store_id", value: storeId)
            .execute()

        return try JSONDecoder().decode([TimeDistribution].self, from: response.data)
    }

    // Fetch popular items
    func getPopularItems(storeId: Int, limit: Int = 5) async throws -> [PopularItem] {
        let response = try await supabase
            .from("analytics_popular_items")
            .select()
            .eq("store_id", value: storeId)
            .limit(limit)
            .execute()

        return try JSONDecoder().decode([PopularItem].self, from: response.data)
    }

    // Fetch category distribution
    func getCategoryDistribution(limit: Int = 10) async throws -> [CategoryDistribution] {
        let response = try await supabase
            .from("analytics_category_distribution")
            .select()
            .limit(limit)
            .execute()

        return try JSONDecoder().decode([CategoryDistribution].self, from: response.data)
    }
}
```

### Step 3: Define Data Models

```swift
struct StoreMetrics: Codable {
    let totalRevenue: Decimal
    let totalOrders: Int
    let avgOrderValue: Decimal
    let uniqueCustomers: Int
    let revenueChange: Decimal
    let ordersChange: Int

    enum CodingKeys: String, CodingKey {
        case totalRevenue = "total_revenue"
        case totalOrders = "total_orders"
        case avgOrderValue = "avg_order_value"
        case uniqueCustomers = "unique_customers"
        case revenueChange = "revenue_change"
        case ordersChange = "orders_change"
    }
}

struct RevenueChartPoint: Codable {
    let timeLabel: String
    let revenue: Decimal
    let orders: Int

    enum CodingKeys: String, CodingKey {
        case timeLabel = "time_label"
        case revenue
        case orders
    }
}

struct TimeDistribution: Codable {
    let timePeriod: String
    let orderCount: Int
    let revenue: Decimal

    enum CodingKeys: String, CodingKey {
        case timePeriod = "time_period"
        case orderCount = "order_count"
        case revenue
    }
}

struct PopularItem: Codable {
    let menuItemId: Int
    let itemName: String
    let timesOrdered: Int
    let totalQuantity: Int
    let totalRevenue: Decimal
    let avgPrice: Decimal

    enum CodingKeys: String, CodingKey {
        case menuItemId = "menu_item_id"
        case itemName = "item_name"
        case timesOrdered = "times_ordered"
        case totalQuantity = "total_quantity"
        case totalRevenue = "total_revenue"
        case avgPrice = "avg_price"
    }
}

struct CategoryDistribution: Codable {
    let category: String
    let subcategory: String?
    let orderCount: Int
    let itemsSold: Int
    let totalRevenue: Decimal

    enum CodingKeys: String, CodingKey {
        case category
        case subcategory
        case orderCount = "order_count"
        case itemsSold = "items_sold"
        case totalRevenue = "total_revenue"
    }
}
```

### Step 4: Update Analytics View/ViewModel

Replace mock data with real Supabase calls:

```swift
@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var metrics: StoreMetrics?
    @Published var revenueData: [RevenueChartPoint] = []
    @Published var timeDistribution: [TimeDistribution] = []
    @Published var popularItems: [PopularItem] = []
    @Published var categoryDistribution: [CategoryDistribution] = []
    @Published var isLoading = false
    @Published var error: String?

    private let analyticsService: AnalyticsService
    private let storeId: Int

    init(analyticsService: AnalyticsService, storeId: Int) {
        self.analyticsService = analyticsService
        self.storeId = storeId
    }

    func loadAnalytics(dateRange: String = "today") async {
        isLoading = true
        error = nil

        do {
            // Fetch all analytics data in parallel
            async let metricsTask = analyticsService.getStoreMetrics(storeId: storeId, dateRange: dateRange)
            async let revenueTask = analyticsService.getRevenueChartData(storeId: storeId, dateRange: dateRange)
            async let timeTask = analyticsService.getTimeDistribution(storeId: storeId)
            async let popularTask = analyticsService.getPopularItems(storeId: storeId)
            async let categoryTask = analyticsService.getCategoryDistribution()

            metrics = try await metricsTask
            revenueData = try await revenueTask
            timeDistribution = try await timeTask
            popularItems = try await popularTask
            categoryDistribution = try await categoryTask

        } catch {
            self.error = error.localizedDescription
            print("Analytics error: \\(error)")
        }

        isLoading = false
    }

    func refresh() {
        Task {
            await loadAnalytics()
        }
    }
}
```

### Step 5: Update SwiftUI View

```swift
struct AnalyticsView: View {
    @StateObject private var viewModel: AnalyticsViewModel
    @State private var dateRange: String = "today"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date Range Picker
                Picker("Range", selection: $dateRange) {
                    Text("Today").tag("today")
                    Text("Week").tag("week")
                    Text("Month").tag("month")
                    Text("Quarter").tag("quarter")
                    Text("Year").tag("year")
                }
                .pickerStyle(.segmented)
                .onChange(of: dateRange) { newValue in
                    Task {
                        await viewModel.loadAnalytics(dateRange: newValue)
                    }
                }

                if viewModel.isLoading {
                    ProgressView("Loading analytics...")
                } else if let error = viewModel.error {
                    Text("Error: \\(error)")
                        .foregroundColor(.red)
                } else {
                    // KPI Cards
                    if let metrics = viewModel.metrics {
                        KPICardsView(metrics: metrics)
                    }

                    // Revenue Chart
                    if !viewModel.revenueData.isEmpty {
                        RevenueChartView(data: viewModel.revenueData)
                    }

                    // Time Distribution
                    if !viewModel.timeDistribution.isEmpty {
                        TimeDistributionView(data: viewModel.timeDistribution)
                    }

                    // Popular Items
                    if !viewModel.popularItems.isEmpty {
                        PopularItemsView(items: viewModel.popularItems)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await viewModel.loadAnalytics(dateRange: dateRange)
        }
    }
}
```

---

## 🔄 Real-Time Updates (Optional)

Add Supabase real-time subscriptions to auto-update analytics when new orders arrive:

```swift
func subscribeToOrderUpdates() {
    let channel = supabase.channel("analytics-updates")

    channel
        .on("postgres_changes", schema: "public", table: "orders", filter: "store_id=eq.\\(storeId)") { payload in
            Task {
                await self.loadAnalytics()
            }
        }
        .subscribe()
}
```

---

## ✅ Testing Checklist

After implementation:

- [ ] Run migration 024 in Supabase
- [ ] Analytics screen shows real order data (not mock data)
- [ ] Revenue chart updates when date range changes
- [ ] KPI metrics show actual numbers from database
- [ ] Popular items list shows real menu items ordered
- [ ] Time distribution shows accurate hourly/daily patterns
- [ ] When new order is placed, analytics update (with refresh)
- [ ] No crashes or errors in console

---

## 🎯 What to Say to Cursor

**Prompt for Cursor AI:**

```
Replace the mock analytics data in our iOS business app with real Supabase queries.

Current state: We have fake data generators showing mock numbers.

Required changes:
1. Create AnalyticsService class that calls these Supabase functions:
   - get_store_metrics(store_id, date_range) → KPI metrics
   - get_revenue_chart_data(store_id, date_range) → time-series data

2. Query these Supabase views:
   - analytics_time_distribution → orders by time of day
   - analytics_popular_items → top-selling items
   - analytics_category_distribution → orders by category

3. Update AnalyticsViewModel to use AnalyticsService instead of mock data generators

4. Add proper Codable models for all response types with snake_case to camelCase mapping

5. Handle loading states and errors properly

6. Support date range filtering: today, week, month, quarter, year

Reference: See IOS_BUSINESS_ANALYTICS_GUIDE.md for full implementation details and code examples.
```

---

## 📝 Summary

**What you're doing**: Replacing fake analytics with real Supabase database queries

**What's ready**: All database views and functions are already created

**What you need**: Implement the Swift service layer and update your ViewModels

**Result**: Real business insights instead of mock data

All the hard database work is done - you just need to call the Supabase functions from Swift!
