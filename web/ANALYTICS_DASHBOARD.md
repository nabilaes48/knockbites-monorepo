# 📊 Premium Analytics Dashboard

High-end, real-time analytics dashboard with stunning visualizations matching professional dashboards.

## 🎨 Features

### Real-Time Updates
- ✅ Automatic refresh when new orders come in
- ✅ WebSocket subscription to order changes
- ✅ Live metrics updates without page reload

### KPI Cards (Top Row)
1. **Total Revenue**
   - Current period revenue with trend indicator
   - Percentage change vs previous period
   - Beautiful gradient background (blue)

2. **Total Orders**
   - Order count with growth indicator
   - Comparison with last period
   - Purple gradient theme

3. **Average Order Value**
   - Revenue per order metric
   - Health indicator
   - Emerald gradient theme

4. **Unique Customers**
   - Customer count for period
   - Active user indicator
   - Orange gradient theme

### Sales Overview Chart
- Area chart showing revenue trends over time
- Smooth animations
- Date range selector (24h, 7d, 30d)
- Currency formatting

### Order Distribution (Donut Chart)
- Orders by time of day:
  - Morning
  - Afternoon
  - Dinner (66.7%)
  - Late Night (33.3%)
- Beautiful color coding
- Interactive tooltips

### Category Distribution (Large Donut + Progress Bars)
- Breakfast: 35.3%
- Classic Sandwiches: 23.5%
- Munchies: 23.5%
- Signature Sandwiches: 17.7%
- Animated progress bars
- Color-coded categories

## 🚀 How to Access

### URL
```
http://localhost:8080/analytics
```

### From Dashboard
Add a link in your staff dashboard navigation:

```tsx
<Link to="/analytics">
  <Button variant="ghost" className="gap-2">
    <TrendingUp className="w-4 h-4" />
    Analytics
  </Button>
</Link>
```

## 🎨 Design Features

### Dark Premium Theme
- Slate-950/900 gradient background
- Glass-morphism cards with backdrop blur
- Glowing effects on interactive elements
- Professional color palette:
  - Blue (#3B82F6) - Revenue/Primary
  - Purple (#A855F7) - Orders
  - Emerald (#10B981) - Growth
  - Orange (#F59E0B) - Customers
  - Cyan (#06B6D4) - Accents
  - Pink (#EC4899) - Special metrics

### Animations
- Smooth fade-ins on load
- Number counting animations
- Chart entrance animations
- Hover effects with glow
- Real-time pulse indicator

### Typography
- Bold, large metrics (text-3xl/4xl)
- Clear hierarchy
- Professional sans-serif (Inter/system)
- Proper contrast for readability

## 📊 Data Sources

### Currently Using
- PocketBase `orders` collection
- Real-time WebSocket subscriptions
- Automatic data aggregation

### Future Enhancements
- Store performance comparison (all 29 stores)
- Top selling items ranking
- Customer retention metrics
- Hour-by-hour breakdown
- Peak hours heatmap
- Revenue forecasting

## 🔧 Customization

### Change Time Range
The dashboard supports 3 time ranges:
```typescript
'24h' // Last 24 hours
'7d'  // Last 7 days
'30d' // Last 30 days
```

Click the buttons in the top-right to switch.

### Add New Metrics

1. **Add to AnalyticsData interface:**
```typescript
interface AnalyticsData {
  // ... existing fields
  newMetric: number
}
```

2. **Calculate in loadAnalyticsData():**
```typescript
const newMetric = orders.reduce((sum, o) => sum + o.someValue, 0)
```

3. **Add KPI Card:**
```tsx
<Card className="bg-gradient-to-br from-blue-900/40 to-blue-800/20">
  <Metric>{formatCurrency(data.newMetric)}</Metric>
</Card>
```

### Change Colors
Edit the card gradients:
```tsx
// From this:
className="bg-gradient-to-br from-blue-900/40 to-blue-800/20"

// To custom colors:
className="bg-gradient-to-br from-indigo-900/40 to-indigo-800/20"
```

## 🎯 Pro Tips

### Performance
- Charts auto-animate on first load only
- Real-time updates are throttled
- Data cached locally
- Efficient re-rendering with React memo

### Responsive Design
- Mobile-friendly grid layout
- Touch-optimized charts
- Collapsible sections on small screens
- Works on tablets and phones

### Accessibility
- High contrast ratios
- Keyboard navigation
- Screen reader friendly
- Focus indicators

## 🚀 Future Features

### Phase 2: Advanced Analytics
- [ ] Revenue forecasting with ML
- [ ] Customer segmentation
- [ ] A/B testing results
- [ ] Inventory predictions
- [ ] Staff performance metrics

### Phase 3: Comparisons
- [ ] Store vs store comparison
- [ ] Year over year trends
- [ ] Seasonal patterns
- [ ] Holiday performance

### Phase 4: Exports
- [ ] PDF report generation
- [ ] CSV data exports
- [ ] Scheduled email reports
- [ ] Custom dashboards

## 🎨 Premium Dashboard Examples

The design is inspired by:
- **Stripe Dashboard** - Clean, professional metrics
- **Vercel Analytics** - Smooth animations, dark theme
- **Linear** - Modern, gradient-heavy design
- **Notion Calendar** - Data visualization excellence

## 📱 Mobile View

The dashboard is fully responsive:
- Cards stack vertically on mobile
- Charts scale to fit screen
- Touch-friendly interactions
- Optimized for tablets

## 🆘 Troubleshooting

### No Data Showing
1. Create some test orders
2. Check browser console for errors
3. Verify PocketBase connection
4. Check date range selector

### Charts Not Loading
1. Ensure @tremor/react is installed
2. Check tailwind.config.ts includes Tremor
3. Verify data structure matches interface
4. Check browser console

### Real-Time Not Working
1. Verify WebSocket connection (DevTools → Network → WS)
2. Check PocketBase is running
3. Ensure subscription code is active
4. Look for green pulse indicator

## 🎉 You're Done!

Visit **http://localhost:8080/analytics** to see your premium dashboard!

The dashboard updates in REAL-TIME as orders come in. Try:
1. Open analytics in one browser tab
2. Create order in another tab (or iOS app)
3. Watch metrics update automatically!

**Enjoy your premium analytics dashboard! 📊✨**
