import { useState, useMemo } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Progress } from "@/components/ui/progress";
import {
  DollarSign,
  ShoppingBag,
  Users,
  TrendingUp,
  ArrowUp,
  ArrowDown,
  Store,
  Calendar,
  RefreshCw,
  Pause,
  Play,
  Target,
  Award,
  Clock,
  Star,
  ThumbsUp,
  Zap,
  TrendingDown,
  AlertCircle,
} from "lucide-react";
import {
  AreaChart,
  Area,
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart as RechartsPieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  Radar,
} from "recharts";
import { format } from "date-fns";
import { useAnalytics } from "@/hooks/useAnalytics";
import { Loader2 } from "lucide-react";

const COLORS = {
  primary: "#3b82f6",
  success: "#10b981",
  warning: "#f59e0b",
  danger: "#ef4444",
  purple: "#a855f7",
  cyan: "#06b6d4",
};

export const AnalyticsEnhanced = () => {
  // SINGLE STORE MODE: Highland Mills Snack Shop Inc (Store ID 1)
  const selectedStore = 1;
  const [dateRange, setDateRange] = useState<string>("today");
  const [autoRefresh, setAutoRefresh] = useState(false);

  // Fetch real analytics data from Supabase
  const {
    metrics,
    revenueData,
    timeDistribution,
    categoryDistribution,
    popularItems,
    customerInsights,
    peakHours,
    dayOfWeekStats,
    revenueGoals,
    topCustomers,
    businessInsights,
    loading,
    error,
    refresh
  } = useAnalytics(selectedStore, dateRange);

  // Auto-refresh logic
  useState(() => {
    if (!autoRefresh) return;
    const interval = setInterval(refresh, 30000); // 30 seconds
    return () => clearInterval(interval);
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin mx-auto mb-4 text-primary" />
          <p className="text-muted-foreground">Loading analytics...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-96">
        <Card className="max-w-md">
          <CardContent className="pt-6">
            <AlertCircle className="h-12 w-12 text-destructive mx-auto mb-4" />
            <p className="text-center text-destructive">{error}</p>
            <Button onClick={refresh} className="w-full mt-4">
              Try Again
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header with Controls */}
      <div className="flex flex-col md:flex-row justify-between gap-4">
        <div>
          <h2 className="text-3xl font-bold">Business Analytics</h2>
          <p className="text-muted-foreground">
            Real-time insights and performance metrics
          </p>
        </div>

        <div className="flex flex-wrap gap-3">
          <Select value={dateRange} onValueChange={setDateRange}>
            <SelectTrigger className="w-[180px]">
              <Calendar className="h-4 w-4 mr-2" />
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="today">Today</SelectItem>
              <SelectItem value="week">This Week</SelectItem>
              <SelectItem value="month">This Month</SelectItem>
              <SelectItem value="quarter">This Quarter</SelectItem>
              <SelectItem value="year">This Year</SelectItem>
            </SelectContent>
          </Select>

          <Badge variant="outline" className="px-4 py-2 text-sm">
            <Store className="h-4 w-4 mr-2" />
            Highland Mills Snack Shop Inc
          </Badge>

          <Button
            variant={autoRefresh ? "default" : "outline"}
            onClick={() => setAutoRefresh(!autoRefresh)}
            title="Toggle auto-refresh every 30s"
          >
            {autoRefresh ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
          </Button>

          <Button
            variant="outline"
            size="icon"
            onClick={refresh}
            title="Refresh now"
          >
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Business Insights Summary Banner */}
      {businessInsights && (
        <Card className="border-2 border-accent bg-gradient-to-r from-accent/10 to-accent/5">
          <CardContent className="pt-6">
            <div className="flex items-center gap-2 mb-4">
              <Zap className="h-5 w-5 text-accent" />
              <h3 className="font-bold text-lg">Quick Insights</h3>
            </div>
            <div className="grid md:grid-cols-5 gap-4">
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Peak Hour</p>
                <p className="text-2xl font-bold text-accent">
                  {businessInsights.peak_hour}:00
                </p>
              </div>
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Busiest Day</p>
                <p className="text-2xl font-bold text-accent">
                  {businessInsights.busiest_day?.trim()}
                </p>
              </div>
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Top Category</p>
                <p className="text-xl font-bold text-accent">
                  {businessInsights.top_category}
                </p>
              </div>
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Retention Rate</p>
                <p className="text-2xl font-bold text-accent">
                  {businessInsights.customer_retention?.toFixed(1)}%
                </p>
              </div>
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Avg Wait</p>
                <p className="text-2xl font-bold text-accent">
                  {businessInsights.avg_wait_time || 0} min
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* KPI Metrics */}
      {metrics && (
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card className="bg-gradient-to-br from-green-950 to-emerald-950 border-green-800">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between mb-2">
                <p className="text-sm font-medium text-green-300">Total Revenue</p>
                <DollarSign className="h-6 w-6 text-green-400" />
              </div>
              <div className="space-y-1">
                <p className="text-3xl font-bold text-green-100">
                  ${Number(metrics.total_revenue).toFixed(2)}
                </p>
                <div className="flex items-center gap-2 text-xs">
                  {Number(metrics.revenue_change) >= 0 ? (
                    <ArrowUp className="h-3 w-3 text-green-400" />
                  ) : (
                    <ArrowDown className="h-3 w-3 text-red-400" />
                  )}
                  <span className={Number(metrics.revenue_change) >= 0 ? "text-green-400" : "text-red-400"}>
                    {Number(metrics.revenue_change).toFixed(1)}%
                  </span>
                  <span className="text-green-300/70">vs last period</span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-blue-950 to-indigo-950 border-blue-800">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between mb-2">
                <p className="text-sm font-medium text-blue-300">Total Orders</p>
                <ShoppingBag className="h-6 w-6 text-blue-400" />
              </div>
              <div className="space-y-1">
                <p className="text-3xl font-bold text-blue-100">{metrics.total_orders}</p>
                <div className="flex items-center gap-2 text-xs">
                  {metrics.orders_change >= 0 ? (
                    <ArrowUp className="h-3 w-3 text-green-400" />
                  ) : (
                    <ArrowDown className="h-3 w-3 text-red-400" />
                  )}
                  <span className={metrics.orders_change >= 0 ? "text-green-400" : "text-red-400"}>
                    {metrics.orders_change >= 0 ? "+" : ""}{metrics.orders_change}
                  </span>
                  <span className="text-blue-300/70">from last period</span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-purple-950 to-violet-950 border-purple-800">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between mb-2">
                <p className="text-sm font-medium text-purple-300">Avg Order Value</p>
                <TrendingUp className="h-6 w-6 text-purple-400" />
              </div>
              <div className="space-y-1">
                <p className="text-3xl font-bold text-purple-100">
                  ${Number(metrics.avg_order_value).toFixed(2)}
                </p>
                <div className="flex items-center gap-2 text-xs">
                  <Target className="h-3 w-3 text-purple-400" />
                  <span className="text-purple-300/70">per transaction</span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-orange-950 to-amber-950 border-orange-800">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between mb-2">
                <p className="text-sm font-medium text-orange-300">Customers Served</p>
                <Users className="h-6 w-6 text-orange-400" />
              </div>
              <div className="space-y-1">
                <p className="text-3xl font-bold text-orange-100">{metrics.unique_customers}</p>
                <div className="flex items-center gap-2 text-xs">
                  <ThumbsUp className="h-3 w-3 text-orange-400" />
                  <span className="text-orange-300/70">unique customers</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Revenue Goals Progress */}
      {revenueGoals && metrics && (
        <Card className="border-2 border-purple-800 bg-gradient-to-br from-purple-950/20 to-pink-950/20">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Target className="h-5 w-5 text-purple-400" />
              Revenue Goals & Targets
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <div className="flex justify-between mb-2">
                  <span className="text-sm font-medium">Daily Revenue Goal</span>
                  <span className="text-sm text-muted-foreground">
                    ${Number(metrics.total_revenue).toFixed(2)} / ${Number(revenueGoals.revenue_goal).toFixed(2)}
                  </span>
                </div>
                <Progress
                  value={(Number(metrics.total_revenue) / Number(revenueGoals.revenue_goal)) * 100}
                  className="h-3"
                />
                <div className="mt-2 grid grid-cols-3 gap-2 text-xs">
                  <div>
                    <p className="text-muted-foreground">Best Day</p>
                    <p className="font-semibold text-green-400">${Number(revenueGoals.best_day_revenue).toFixed(2)}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Average</p>
                    <p className="font-semibold">${Number(revenueGoals.avg_daily_revenue).toFixed(2)}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Worst Day</p>
                    <p className="font-semibold text-orange-400">${Number(revenueGoals.worst_day_revenue).toFixed(2)}</p>
                  </div>
                </div>
              </div>
              <div>
                <div className="flex justify-between mb-2">
                  <span className="text-sm font-medium">Daily Orders Goal</span>
                  <span className="text-sm text-muted-foreground">
                    {metrics.total_orders} / {Number(revenueGoals.orders_goal).toFixed(0)}
                  </span>
                </div>
                <Progress
                  value={(metrics.total_orders / Number(revenueGoals.orders_goal)) * 100}
                  className="h-3"
                />
                <div className="mt-2 text-center">
                  <p className="text-2xl font-bold text-purple-400">
                    {Number(revenueGoals.avg_daily_orders).toFixed(1)}
                  </p>
                  <p className="text-xs text-muted-foreground">Average Orders/Day</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Tabs for Different Views */}
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="revenue">Revenue Analysis</TabsTrigger>
          <TabsTrigger value="customers">Customers</TabsTrigger>
          <TabsTrigger value="performance">Performance</TabsTrigger>
          <TabsTrigger value="items">Popular Items</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          {/* Revenue Chart and Time Distribution */}
          <div className="grid md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Revenue Trends</CardTitle>
                <p className="text-sm text-muted-foreground">Sales performance over time</p>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={revenueData.map(d => ({
                      time: d.time_label,
                      revenue: Number(d.revenue),
                      orders: Number(d.orders)
                    }))}>
                      <defs>
                        <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor={COLORS.primary} stopOpacity={0.8}/>
                          <stop offset="95%" stopColor={COLORS.primary} stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                      <XAxis dataKey="time" stroke="#9ca3af" style={{ fontSize: '12px' }} />
                      <YAxis
                        stroke="#9ca3af"
                        style={{ fontSize: '12px' }}
                        tickFormatter={(value) => `$${value >= 1000 ? (value / 1000).toFixed(0) + 'k' : value}`}
                      />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'rgba(17, 24, 39, 0.95)',
                          border: '1px solid #374151',
                          borderRadius: '8px',
                          padding: '12px',
                          color: '#fff'
                        }}
                        formatter={(value: number | string) => [`$${Number(value).toFixed(2)}`, 'Revenue']}
                      />
                      <Area
                        type="monotone"
                        dataKey="revenue"
                        stroke={COLORS.primary}
                        fillOpacity={1}
                        fill="url(#colorRevenue)"
                        strokeWidth={2}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Orders by Time of Day</CardTitle>
                <p className="text-sm text-muted-foreground">Distribution across meal periods</p>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <RechartsPieChart>
                      <Pie
                        data={timeDistribution.map(d => {
                          const total = timeDistribution.reduce((sum, item) => sum + item.order_count, 0);
                          return {
                            name: d.time_period,
                            value: d.order_count,
                            percentage: ((d.order_count / total) * 100).toFixed(1)
                          };
                        })}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={({ name, percentage }) => `${name}: ${percentage}%`}
                        outerRadius={80}
                        dataKey="value"
                      >
                        {timeDistribution.map((_, index) => (
                          <Cell key={`cell-${index}`} fill={Object.values(COLORS)[index % Object.values(COLORS).length]} />
                        ))}
                      </Pie>
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'rgba(17, 24, 39, 0.95)',
                          border: '1px solid #374151',
                          borderRadius: '8px',
                          padding: '12px',
                          color: '#fff'
                        }}
                      />
                    </RechartsPieChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="revenue" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Revenue by Category</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={categoryDistribution.map(d => ({
                    name: d.category,
                    revenue: Number(d.total_revenue),
                    orders: d.order_count
                  }))}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                    <XAxis dataKey="name" stroke="#9ca3af" style={{ fontSize: '12px' }} />
                    <YAxis stroke="#9ca3af" style={{ fontSize: '12px' }} tickFormatter={(value) => `$${value}`} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: 'rgba(17, 24, 39, 0.95)',
                        border: '1px solid #374151',
                        borderRadius: '8px',
                        color: '#fff'
                      }}
                      formatter={(value: number | string) => [`$${Number(value).toFixed(2)}`, 'Revenue']}
                    />
                    <Bar dataKey="revenue" fill={COLORS.primary} radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="customers" className="space-y-4">
          <div className="grid md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Users className="h-5 w-5" />
                  Customer Insights
                </CardTitle>
              </CardHeader>
              <CardContent>
                {customerInsights ? (
                  <div className="space-y-4">
                    <div className="flex justify-between items-center">
                      <span className="text-muted-foreground">Total Customers</span>
                      <span className="font-bold">{customerInsights.total_customers}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-muted-foreground">Returning Customers</span>
                      <span className="font-bold">{customerInsights.returning_customers}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-muted-foreground">New Customers</span>
                      <span className="font-bold">{customerInsights.new_customers}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-muted-foreground">Avg Orders/Customer</span>
                      <span className="font-bold">{Number(customerInsights.avg_orders_per_customer).toFixed(1)}</span>
                    </div>
                  </div>
                ) : (
                  <p className="text-muted-foreground">No customer data available</p>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Award className="h-5 w-5" />
                  Top Customers
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {topCustomers.slice(0, 5).map((customer, index) => (
                    <div key={index} className="flex justify-between items-center">
                      <div className="flex items-center gap-2">
                        <Badge variant="outline">{index + 1}</Badge>
                        <span className="truncate max-w-[150px]">{customer.customer_name || 'Guest'}</span>
                      </div>
                      <span className="font-semibold text-green-400">${Number(customer.total_spent).toFixed(2)}</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="performance" className="space-y-4">
          <div className="grid md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Clock className="h-5 w-5" />
                  Peak Hours
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={peakHours.map(d => ({
                      hour: `${d.hour}:00`,
                      orders: d.order_count,
                      revenue: Number(d.revenue)
                    }))}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                      <XAxis dataKey="hour" stroke="#9ca3af" style={{ fontSize: '10px' }} />
                      <YAxis stroke="#9ca3af" style={{ fontSize: '12px' }} />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'rgba(17, 24, 39, 0.95)',
                          border: '1px solid #374151',
                          borderRadius: '8px',
                          color: '#fff'
                        }}
                      />
                      <Bar dataKey="orders" fill={COLORS.cyan} radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Calendar className="h-5 w-5" />
                  Day of Week Performance
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <RadarChart data={dayOfWeekStats.map(d => ({
                      day: d.day_name?.substring(0, 3),
                      orders: d.order_count,
                      revenue: Number(d.revenue)
                    }))}>
                      <PolarGrid stroke="#374151" />
                      <PolarAngleAxis dataKey="day" stroke="#9ca3af" />
                      <PolarRadiusAxis stroke="#9ca3af" />
                      <Radar name="Orders" dataKey="orders" stroke={COLORS.primary} fill={COLORS.primary} fillOpacity={0.5} />
                    </RadarChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="items" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Star className="h-5 w-5" />
                Popular Items
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {popularItems.slice(0, 10).map((item, index) => (
                  <div key={index} className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Badge variant={index < 3 ? "default" : "outline"}>{index + 1}</Badge>
                      <span className="font-medium">{item.item_name}</span>
                    </div>
                    <div className="flex items-center gap-4 text-sm">
                      <span className="text-muted-foreground">{item.quantity_sold} sold</span>
                      <span className="font-semibold text-green-400">${Number(item.total_revenue).toFixed(2)}</span>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default AnalyticsEnhanced;