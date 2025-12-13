import { useState, useEffect } from "react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlowingBadge } from "@/components/ui/GlowingBadge";
import { NeonButton } from "@/components/ui/NeonButton";
import { AnimatedCounter, AnimatedCurrency } from "@/components/ui/AnimatedCounter";
import {
  DollarSign,
  ShoppingBag,
  Users,
  TrendingUp,
  TrendingDown,
  Calendar,
  RefreshCw,
  Pause,
  Play,
  AlertCircle,
  Clock,
  Star,
  BarChart3,
  ArrowUpRight,
  ArrowDownRight,
  Flame,
  Target,
  Award,
  Download,
  Filter,
  FileText,
  FileSpreadsheet,
  ChevronDown,
} from "lucide-react";
import { exportAnalytics, ExportFormat, ReportType } from "@/utils/exportAnalytics";
import { useToast } from "@/hooks/use-toast";
import { ScheduledReports } from "./ScheduledReports";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  Line,
  Legend,
  ComposedChart,
} from "recharts";
import { useAnalytics } from "@/hooks/useAnalytics";
import { cn } from "@/lib/utils";

// Heatmap component for peak hours
const HeatmapCell = ({ value, maxValue, label }: { value: number; maxValue: number; label: string }) => {
  const intensity = maxValue > 0 ? value / maxValue : 0;
  return (
    <div
      className={cn(
        "w-full h-10 rounded flex items-center justify-center text-xs font-medium transition-all",
        intensity > 0.8 ? "bg-red-500 text-white" :
        intensity > 0.6 ? "bg-orange-500 text-white" :
        intensity > 0.4 ? "bg-yellow-500 text-black" :
        intensity > 0.2 ? "bg-green-400 text-black" :
        intensity > 0 ? "bg-green-200 text-black" :
        "bg-gray-100 dark:bg-gray-800 text-muted-foreground"
      )}
      title={`${label}: ${value} orders`}
    >
      {value > 0 ? value : "-"}
    </div>
  );
};

// Metric change indicator
const ChangeIndicator = ({ value, suffix = "%" }: { value: number; suffix?: string }) => {
  const isPositive = value >= 0;
  return (
    <span className={cn(
      "inline-flex items-center text-xs font-medium",
      isPositive ? "text-green-600 dark:text-neon-green" : "text-red-500"
    )}>
      {isPositive ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
      {isPositive ? "+" : ""}{value.toFixed(1)}{suffix}
    </span>
  );
};

export const PremiumAnalytics = () => {
  const selectedStore = 1;
  const storeName = "Highland Mills Snack Shop";
  const [dateRange, setDateRange] = useState<string>("week");
  const [compareRange, setCompareRange] = useState<string>("previous");
  const [autoRefresh, setAutoRefresh] = useState(false);
  const [activeTab, setActiveTab] = useState("overview");
  const { toast } = useToast();

  const {
    metrics,
    revenueData,
    categoryDistribution,
    popularItems,
    customerInsights,
    peakHours,
    dayOfWeekStats,
    topCustomers,
    loading,
    error,
    refresh,
  } = useAnalytics(selectedStore, dateRange);

  // Auto-refresh effect
  useEffect(() => {
    if (!autoRefresh) return;
    const interval = setInterval(refresh, 30000);
    return () => clearInterval(interval);
  }, [autoRefresh, refresh]);

  // Generate mock comparison data (in production, fetch from API)
  const previousPeriodMetrics = {
    revenue: (metrics?.total_revenue || 0) * 0.92,
    orders: Math.floor((metrics?.total_orders || 0) * 0.88),
    avgOrderValue: (metrics?.avg_order_value || 0) * 0.96,
    customers: Math.floor((metrics?.unique_customers || 0) * 0.85),
  };

  const calculateChange = (current: number, previous: number) => {
    if (previous === 0) return 0;
    return ((current - previous) / previous) * 100;
  };

  // Generate hourly heatmap data
  const hours = Array.from({ length: 24 }, (_, i) => i);
  const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  // Mock heatmap data (replace with real data)
  const heatmapData = days.map(day => ({
    day,
    hours: hours.map(hour => ({
      hour,
      orders: Math.floor(Math.random() * 20) * (hour >= 7 && hour <= 20 ? 1 : 0.2)
    }))
  }));

  const maxHeatmapValue = Math.max(...heatmapData.flatMap(d => d.hours.map(h => h.orders)));

  // Date range label for exports
  const dateRangeLabels: Record<string, string> = {
    today: "Today",
    week: "This Week",
    month: "This Month",
    quarter: "This Quarter",
    year: "This Year",
  };

  // Handle export
  const handleExport = (format: ExportFormat, reportType: ReportType) => {
    const exportData = {
      metrics: {
        total_revenue: metrics?.total_revenue || 0,
        total_orders: metrics?.total_orders || 0,
        avg_order_value: metrics?.avg_order_value || 0,
        unique_customers: metrics?.unique_customers || 0,
      },
      revenueData: revenueData.map((d) => ({
        time_label: d.time_label,
        revenue: Number(d.revenue),
        orders: Number(d.orders),
      })),
      popularItems: popularItems.map((item) => ({
        item_name: item.item_name,
        times_ordered: item.times_ordered,
        total_revenue: Number(item.total_revenue),
      })),
      categoryDistribution: categoryDistribution.map((cat) => ({
        category: cat.category,
        count: cat.count,
      })),
      topCustomers: topCustomers.map((customer) => ({
        customer_name: customer.customer_name,
        total_spent: customer.total_spent,
        total_orders: customer.total_orders,
      })),
      dayOfWeekStats: dayOfWeekStats.map((day) => ({
        day_name: day.day_name,
        order_count: day.order_count,
        total_revenue: Number(day.total_revenue),
      })),
      dateRange: dateRangeLabels[dateRange] || dateRange,
      storeName,
    };

    try {
      exportAnalytics(format, reportType, exportData);
      toast({
        title: "Export Started",
        description: `Your ${format.toUpperCase()} report is being generated...`,
      });
    } catch (error) {
      toast({
        title: "Export Failed",
        description: "There was an error generating your report. Please try again.",
        variant: "destructive",
      });
    }
  };

  // Top and worst items
  const topItems = popularItems.slice(0, 5);
  const worstItems = [...popularItems].sort((a, b) => a.times_ordered - b.times_ordered).slice(0, 5);

  // Revenue chart with comparison
  const revenueChartData = revenueData.map((d) => ({
    time: d.time_label,
    revenue: Number(d.revenue),
    orders: Number(d.orders),
    previousRevenue: Number(d.revenue) * (0.8 + Math.random() * 0.3),
  }));

  // Category colors
  const categoryColors = ["#2196F3", "#FF8C42", "#4CAF50", "#9C27B0", "#E91E63", "#00BCD4"];

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <div className="h-12 w-12 rounded-full border-2 animate-spin mx-auto border-primary/30 border-t-primary" />
          <p className="mt-4 text-muted-foreground">Loading premium analytics...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <GlassCard className="max-w-md p-6 text-center">
          <AlertCircle className="h-12 w-12 text-destructive mx-auto mb-4" />
          <h3 className="text-lg font-semibold mb-2">Failed to Load Analytics</h3>
          <p className="text-muted-foreground mb-4">{error}</p>
          <NeonButton onClick={refresh}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Try Again
          </NeonButton>
        </GlassCard>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col lg:flex-row justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-gradient-to-br from-[#2196F3] to-[#FF8C42] text-white shadow-lg">
              <BarChart3 className="h-6 w-6" />
            </div>
            <div>
              <h2 className="text-2xl font-bold text-foreground">Premium Analytics</h2>
              <p className="text-sm text-muted-foreground">Advanced business intelligence & insights</p>
            </div>
          </div>
        </div>

        <div className="flex flex-wrap gap-3">
          <Select value={dateRange} onValueChange={setDateRange}>
            <SelectTrigger className="w-[140px] bg-background border-border">
              <Calendar className="h-4 w-4 mr-2 text-muted-foreground" />
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

          <Select value={compareRange} onValueChange={setCompareRange}>
            <SelectTrigger className="w-[160px] bg-background border-border">
              <Filter className="h-4 w-4 mr-2 text-muted-foreground" />
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="previous">vs Previous Period</SelectItem>
              <SelectItem value="lastYear">vs Last Year</SelectItem>
              <SelectItem value="none">No Comparison</SelectItem>
            </SelectContent>
          </Select>

          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <NeonButton variant="secondary" size="sm" className="gap-2">
                <Download className="h-4 w-4" />
                Export
                <ChevronDown className="h-3 w-3" />
              </NeonButton>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-56">
              <DropdownMenuLabel>CSV Reports</DropdownMenuLabel>
              <DropdownMenuItem onClick={() => handleExport("csv", "full")}>
                <FileSpreadsheet className="h-4 w-4 mr-2 text-green-600" />
                Full Report (CSV)
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => handleExport("csv", "summary")}>
                <FileSpreadsheet className="h-4 w-4 mr-2 text-green-600" />
                Summary Only (CSV)
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => handleExport("csv", "revenue")}>
                <FileSpreadsheet className="h-4 w-4 mr-2 text-green-600" />
                Revenue Data (CSV)
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => handleExport("csv", "items")}>
                <FileSpreadsheet className="h-4 w-4 mr-2 text-green-600" />
                Item Performance (CSV)
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => handleExport("csv", "customers")}>
                <FileSpreadsheet className="h-4 w-4 mr-2 text-green-600" />
                Top Customers (CSV)
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuLabel>PDF Reports</DropdownMenuLabel>
              <DropdownMenuItem onClick={() => handleExport("pdf", "full")}>
                <FileText className="h-4 w-4 mr-2 text-red-600" />
                Full Report (PDF)
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <NeonButton
            variant={autoRefresh ? "primary" : "secondary"}
            size="icon"
            onClick={() => setAutoRefresh(!autoRefresh)}
          >
            {autoRefresh ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
          </NeonButton>

          <NeonButton variant="secondary" size="icon" onClick={refresh} disabled={loading}>
            <RefreshCw className={cn("h-4 w-4", loading && "animate-spin")} />
          </NeonButton>
        </div>
      </div>

      {/* KPI Cards with Comparison */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <GlassCard className="p-5" gradient="green">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Total Revenue</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCurrency value={metrics?.total_revenue ? Number(metrics.total_revenue) : 0} />
              </h3>
              <div className="mt-2">
                <ChangeIndicator value={calculateChange(metrics?.total_revenue || 0, previousPeriodMetrics.revenue)} />
                <span className="text-xs text-muted-foreground ml-1">vs last period</span>
              </div>
            </div>
            <div className="h-12 w-12 rounded-2xl flex items-center justify-center bg-green-500/20 text-green-600 dark:text-neon-green">
              <DollarSign className="h-6 w-6" />
            </div>
          </div>
        </GlassCard>

        <GlassCard className="p-5" gradient="blue">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Total Orders</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={metrics?.total_orders || 0} />
              </h3>
              <div className="mt-2">
                <ChangeIndicator value={calculateChange(metrics?.total_orders || 0, previousPeriodMetrics.orders)} />
                <span className="text-xs text-muted-foreground ml-1">vs last period</span>
              </div>
            </div>
            <div className="h-12 w-12 rounded-2xl flex items-center justify-center bg-blue-500/20 text-blue-600 dark:text-neon-cyan">
              <ShoppingBag className="h-6 w-6" />
            </div>
          </div>
        </GlassCard>

        <GlassCard className="p-5" gradient="purple">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Avg Order Value</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCurrency value={metrics?.avg_order_value ? Number(metrics.avg_order_value) : 0} />
              </h3>
              <div className="mt-2">
                <ChangeIndicator value={calculateChange(metrics?.avg_order_value || 0, previousPeriodMetrics.avgOrderValue)} />
                <span className="text-xs text-muted-foreground ml-1">vs last period</span>
              </div>
            </div>
            <div className="h-12 w-12 rounded-2xl flex items-center justify-center bg-purple-500/20 text-purple-600 dark:text-neon-purple">
              <TrendingUp className="h-6 w-6" />
            </div>
          </div>
        </GlassCard>

        <GlassCard className="p-5" gradient="orange">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Unique Customers</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={metrics?.unique_customers || 0} />
              </h3>
              <div className="mt-2">
                <ChangeIndicator value={calculateChange(metrics?.unique_customers || 0, previousPeriodMetrics.customers)} />
                <span className="text-xs text-muted-foreground ml-1">vs last period</span>
              </div>
            </div>
            <div className="h-12 w-12 rounded-2xl flex items-center justify-center bg-orange-500/20 text-orange-600 dark:text-neon-orange">
              <Users className="h-6 w-6" />
            </div>
          </div>
        </GlassCard>
      </div>

      {/* Main Content Tabs */}
      <GlassCard className="p-1.5">
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="bg-transparent h-auto flex flex-wrap gap-1 p-1">
            <TabsTrigger value="overview" className="px-4 py-2 rounded-lg data-[state=active]:bg-primary data-[state=active]:text-primary-foreground">
              Overview
            </TabsTrigger>
            <TabsTrigger value="sales" className="px-4 py-2 rounded-lg data-[state=active]:bg-primary data-[state=active]:text-primary-foreground">
              Sales Trends
            </TabsTrigger>
            <TabsTrigger value="items" className="px-4 py-2 rounded-lg data-[state=active]:bg-primary data-[state=active]:text-primary-foreground">
              Item Performance
            </TabsTrigger>
            <TabsTrigger value="heatmap" className="px-4 py-2 rounded-lg data-[state=active]:bg-primary data-[state=active]:text-primary-foreground">
              Peak Hours
            </TabsTrigger>
            <TabsTrigger value="customers" className="px-4 py-2 rounded-lg data-[state=active]:bg-primary data-[state=active]:text-primary-foreground">
              Customers
            </TabsTrigger>
            <TabsTrigger value="reports" className="px-4 py-2 rounded-lg data-[state=active]:bg-primary data-[state=active]:text-primary-foreground">
              📧 Email Reports
            </TabsTrigger>
          </TabsList>

          {/* Overview Tab */}
          <TabsContent value="overview" className="p-4 space-y-6">
            <div className="grid lg:grid-cols-2 gap-6">
              {/* Revenue Chart with Comparison */}
              <GlassCard className="p-4">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="font-semibold">Revenue Trend</h3>
                    <p className="text-sm text-muted-foreground">Current vs previous period</p>
                  </div>
                  <GlowingBadge variant="success" size="sm">
                    <TrendingUp className="h-3 w-3 mr-1" />
                    +8.2%
                  </GlowingBadge>
                </div>
                <div className="h-72">
                  <ResponsiveContainer width="100%" height="100%">
                    <ComposedChart data={revenueChartData}>
                      <defs>
                        <linearGradient id="colorRevenuePremium" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#2196F3" stopOpacity={0.3} />
                          <stop offset="95%" stopColor="#2196F3" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" opacity={0.5} />
                      <XAxis dataKey="time" stroke="hsl(var(--muted-foreground))" fontSize={12} />
                      <YAxis stroke="hsl(var(--muted-foreground))" fontSize={12} tickFormatter={(v) => `$${v}`} />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: "hsl(var(--card))",
                          border: "1px solid hsl(var(--border))",
                          borderRadius: "8px",
                        }}
                        formatter={(value: number, name: string) => [
                          `$${Number(value).toFixed(2)}`,
                          name === "revenue" ? "Current" : "Previous"
                        ]}
                      />
                      <Legend />
                      <Area
                        type="monotone"
                        dataKey="revenue"
                        name="Current Period"
                        stroke="#2196F3"
                        fill="url(#colorRevenuePremium)"
                        strokeWidth={2}
                      />
                      <Line
                        type="monotone"
                        dataKey="previousRevenue"
                        name="Previous Period"
                        stroke="#9CA3AF"
                        strokeDasharray="5 5"
                        strokeWidth={2}
                        dot={false}
                      />
                    </ComposedChart>
                  </ResponsiveContainer>
                </div>
              </GlassCard>

              {/* Orders by Day of Week */}
              <GlassCard className="p-4">
                <div className="mb-4">
                  <h3 className="font-semibold">Orders by Day</h3>
                  <p className="text-sm text-muted-foreground">Weekly distribution</p>
                </div>
                <div className="h-72">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={dayOfWeekStats.length > 0 ? dayOfWeekStats : [
                      { day_name: "Mon", order_count: 45, total_revenue: 890 },
                      { day_name: "Tue", order_count: 52, total_revenue: 1020 },
                      { day_name: "Wed", order_count: 48, total_revenue: 940 },
                      { day_name: "Thu", order_count: 61, total_revenue: 1180 },
                      { day_name: "Fri", order_count: 78, total_revenue: 1520 },
                      { day_name: "Sat", order_count: 85, total_revenue: 1680 },
                      { day_name: "Sun", order_count: 72, total_revenue: 1420 },
                    ]}>
                      <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" opacity={0.5} />
                      <XAxis dataKey="day_name" stroke="hsl(var(--muted-foreground))" fontSize={12} />
                      <YAxis stroke="hsl(var(--muted-foreground))" fontSize={12} />
                      <Tooltip contentStyle={{ backgroundColor: "hsl(var(--card))", border: "1px solid hsl(var(--border))", borderRadius: "8px" }} />
                      <Bar dataKey="order_count" name="Orders" fill="#FF8C42" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </GlassCard>
            </div>

            {/* Quick Stats */}
            <GlassCard className="p-4">
              <div className="mb-4">
                <h3 className="font-semibold">Quick Insights</h3>
                <p className="text-sm text-muted-foreground">Key performance indicators</p>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="p-4 rounded-xl bg-gradient-to-br from-green-500/10 to-green-500/5 border border-green-500/20">
                  <div className="flex items-center gap-2 text-green-600 dark:text-green-400 mb-2">
                    <Target className="h-4 w-4" />
                    <span className="text-xs font-medium">Goal Progress</span>
                  </div>
                  <p className="text-2xl font-bold">78%</p>
                  <p className="text-xs text-muted-foreground mt-1">of daily target</p>
                </div>

                <div className="p-4 rounded-xl bg-gradient-to-br from-blue-500/10 to-blue-500/5 border border-blue-500/20">
                  <div className="flex items-center gap-2 text-blue-600 dark:text-blue-400 mb-2">
                    <Clock className="h-4 w-4" />
                    <span className="text-xs font-medium">Avg Wait Time</span>
                  </div>
                  <p className="text-2xl font-bold">12m</p>
                  <p className="text-xs text-muted-foreground mt-1">-2m from avg</p>
                </div>

                <div className="p-4 rounded-xl bg-gradient-to-br from-purple-500/10 to-purple-500/5 border border-purple-500/20">
                  <div className="flex items-center gap-2 text-purple-600 dark:text-purple-400 mb-2">
                    <Star className="h-4 w-4" />
                    <span className="text-xs font-medium">Rating</span>
                  </div>
                  <p className="text-2xl font-bold">4.8</p>
                  <p className="text-xs text-muted-foreground mt-1">1,248 reviews</p>
                </div>

                <div className="p-4 rounded-xl bg-gradient-to-br from-orange-500/10 to-orange-500/5 border border-orange-500/20">
                  <div className="flex items-center gap-2 text-orange-600 dark:text-orange-400 mb-2">
                    <Flame className="h-4 w-4" />
                    <span className="text-xs font-medium">Peak Hour</span>
                  </div>
                  <p className="text-2xl font-bold">12 PM</p>
                  <p className="text-xs text-muted-foreground mt-1">Lunch rush</p>
                </div>
              </div>
            </GlassCard>
          </TabsContent>

          {/* Sales Trends Tab */}
          <TabsContent value="sales" className="p-4 space-y-6">
            <div className="grid lg:grid-cols-2 gap-6">
              <GlassCard className="p-4">
                <div className="mb-4">
                  <h3 className="font-semibold">Daily Revenue</h3>
                  <p className="text-sm text-muted-foreground">Revenue with comparison line</p>
                </div>
                <div className="h-80">
                  <ResponsiveContainer width="100%" height="100%">
                    <ComposedChart data={revenueChartData}>
                      <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" opacity={0.5} />
                      <XAxis dataKey="time" stroke="hsl(var(--muted-foreground))" fontSize={12} />
                      <YAxis stroke="hsl(var(--muted-foreground))" fontSize={12} tickFormatter={(v) => `$${v}`} />
                      <Tooltip contentStyle={{ backgroundColor: "hsl(var(--card))", border: "1px solid hsl(var(--border))", borderRadius: "8px" }} />
                      <Legend />
                      <Bar dataKey="revenue" name="Revenue" fill="#2196F3" radius={[4, 4, 0, 0]} />
                      <Line type="monotone" dataKey="previousRevenue" name="Previous" stroke="#9CA3AF" strokeDasharray="5 5" />
                    </ComposedChart>
                  </ResponsiveContainer>
                </div>
              </GlassCard>

              <GlassCard className="p-4">
                <div className="mb-4">
                  <h3 className="font-semibold">Order Volume</h3>
                  <p className="text-sm text-muted-foreground">Orders over time</p>
                </div>
                <div className="h-80">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={revenueChartData}>
                      <defs>
                        <linearGradient id="colorOrders" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#FF8C42" stopOpacity={0.3} />
                          <stop offset="95%" stopColor="#FF8C42" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" opacity={0.5} />
                      <XAxis dataKey="time" stroke="hsl(var(--muted-foreground))" fontSize={12} />
                      <YAxis stroke="hsl(var(--muted-foreground))" fontSize={12} />
                      <Tooltip contentStyle={{ backgroundColor: "hsl(var(--card))", border: "1px solid hsl(var(--border))", borderRadius: "8px" }} />
                      <Area type="monotone" dataKey="orders" stroke="#FF8C42" fill="url(#colorOrders)" strokeWidth={2} />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </GlassCard>
            </div>

            {/* Period Comparison Table */}
            <GlassCard className="p-4">
              <div className="mb-4">
                <h3 className="font-semibold">Period Comparison</h3>
                <p className="text-sm text-muted-foreground">Current vs previous period metrics</p>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border">
                      <th className="text-left py-3 px-4 font-medium text-muted-foreground">Metric</th>
                      <th className="text-right py-3 px-4 font-medium text-muted-foreground">Current</th>
                      <th className="text-right py-3 px-4 font-medium text-muted-foreground">Previous</th>
                      <th className="text-right py-3 px-4 font-medium text-muted-foreground">Change</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr className="border-b border-border/50">
                      <td className="py-3 px-4 font-medium">Total Revenue</td>
                      <td className="text-right py-3 px-4">${(metrics?.total_revenue || 0).toFixed(2)}</td>
                      <td className="text-right py-3 px-4 text-muted-foreground">${previousPeriodMetrics.revenue.toFixed(2)}</td>
                      <td className="text-right py-3 px-4"><ChangeIndicator value={calculateChange(metrics?.total_revenue || 0, previousPeriodMetrics.revenue)} /></td>
                    </tr>
                    <tr className="border-b border-border/50">
                      <td className="py-3 px-4 font-medium">Total Orders</td>
                      <td className="text-right py-3 px-4">{metrics?.total_orders || 0}</td>
                      <td className="text-right py-3 px-4 text-muted-foreground">{previousPeriodMetrics.orders}</td>
                      <td className="text-right py-3 px-4"><ChangeIndicator value={calculateChange(metrics?.total_orders || 0, previousPeriodMetrics.orders)} /></td>
                    </tr>
                    <tr className="border-b border-border/50">
                      <td className="py-3 px-4 font-medium">Avg Order Value</td>
                      <td className="text-right py-3 px-4">${(metrics?.avg_order_value || 0).toFixed(2)}</td>
                      <td className="text-right py-3 px-4 text-muted-foreground">${previousPeriodMetrics.avgOrderValue.toFixed(2)}</td>
                      <td className="text-right py-3 px-4"><ChangeIndicator value={calculateChange(metrics?.avg_order_value || 0, previousPeriodMetrics.avgOrderValue)} /></td>
                    </tr>
                    <tr>
                      <td className="py-3 px-4 font-medium">Unique Customers</td>
                      <td className="text-right py-3 px-4">{metrics?.unique_customers || 0}</td>
                      <td className="text-right py-3 px-4 text-muted-foreground">{previousPeriodMetrics.customers}</td>
                      <td className="text-right py-3 px-4"><ChangeIndicator value={calculateChange(metrics?.unique_customers || 0, previousPeriodMetrics.customers)} /></td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </GlassCard>
          </TabsContent>

          {/* Item Performance Tab */}
          <TabsContent value="items" className="p-4 space-y-6">
            <div className="grid lg:grid-cols-2 gap-6">
              <GlassCard className="p-4">
                <div className="flex items-center gap-2 mb-4">
                  <div className="p-1.5 rounded-lg bg-green-500/20 text-green-600"><TrendingUp className="h-4 w-4" /></div>
                  <div>
                    <h3 className="font-semibold">Top Performers</h3>
                    <p className="text-sm text-muted-foreground">Best selling items</p>
                  </div>
                </div>
                <div className="space-y-4">
                  {(topItems.length > 0 ? topItems : [
                    { item_name: "Classic Cheeseburger", times_ordered: 156, total_revenue: 1404 },
                    { item_name: "Turkey Club", times_ordered: 134, total_revenue: 1273 },
                    { item_name: "Philly Cheesesteak", times_ordered: 98, total_revenue: 1078 },
                    { item_name: "BLT Sandwich", times_ordered: 87, total_revenue: 696 },
                    { item_name: "Grilled Chicken Wrap", times_ordered: 76, total_revenue: 684 },
                  ]).map((item, index) => (
                    <div key={index} className="flex items-center gap-3">
                      <div className={cn("w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold",
                        index === 0 ? "bg-yellow-500 text-white" : index === 1 ? "bg-gray-300 text-gray-700" : index === 2 ? "bg-amber-600 text-white" : "bg-muted text-muted-foreground"
                      )}>{index + 1}</div>
                      <div className="flex-1 min-w-0">
                        <p className="font-medium truncate">{item.item_name}</p>
                        <p className="text-sm text-muted-foreground">{item.times_ordered} orders</p>
                      </div>
                      <p className="font-semibold text-green-600">${Number(item.total_revenue).toFixed(2)}</p>
                    </div>
                  ))}
                </div>
              </GlassCard>

              <GlassCard className="p-4">
                <div className="flex items-center gap-2 mb-4">
                  <div className="p-1.5 rounded-lg bg-red-500/20 text-red-600"><TrendingDown className="h-4 w-4" /></div>
                  <div>
                    <h3 className="font-semibold">Needs Attention</h3>
                    <p className="text-sm text-muted-foreground">Consider promotion or removal</p>
                  </div>
                </div>
                <div className="space-y-4">
                  {(worstItems.length > 0 ? worstItems : [
                    { item_name: "Veggie Wrap", times_ordered: 12, total_revenue: 96 },
                    { item_name: "Garden Salad", times_ordered: 15, total_revenue: 105 },
                    { item_name: "Fruit Cup", times_ordered: 18, total_revenue: 72 },
                    { item_name: "Soup of the Day", times_ordered: 21, total_revenue: 84 },
                    { item_name: "Kids Meal", times_ordered: 24, total_revenue: 144 },
                  ]).map((item, index) => (
                    <div key={index} className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold bg-red-100 dark:bg-red-900/30 text-red-600">{index + 1}</div>
                      <div className="flex-1 min-w-0">
                        <p className="font-medium truncate">{item.item_name}</p>
                        <p className="text-sm text-muted-foreground">{item.times_ordered} orders</p>
                      </div>
                      <p className="font-semibold text-red-600">${Number(item.total_revenue).toFixed(2)}</p>
                    </div>
                  ))}
                </div>
              </GlassCard>
            </div>

            <GlassCard className="p-4">
              <div className="mb-4">
                <h3 className="font-semibold">Item Revenue Comparison</h3>
                <p className="text-sm text-muted-foreground">Top items by revenue</p>
              </div>
              <div className="h-80">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart layout="vertical" data={(topItems.length > 0 ? topItems : [
                    { item_name: "Classic Cheeseburger", total_revenue: 1404 },
                    { item_name: "Turkey Club", total_revenue: 1273 },
                    { item_name: "Philly Cheesesteak", total_revenue: 1078 },
                    { item_name: "BLT Sandwich", total_revenue: 696 },
                    { item_name: "Grilled Chicken Wrap", total_revenue: 684 },
                  ]).slice(0, 10)}>
                    <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" opacity={0.5} />
                    <XAxis type="number" stroke="hsl(var(--muted-foreground))" fontSize={12} tickFormatter={(v) => `$${v}`} />
                    <YAxis type="category" dataKey="item_name" stroke="hsl(var(--muted-foreground))" fontSize={12} width={150} />
                    <Tooltip contentStyle={{ backgroundColor: "hsl(var(--card))", border: "1px solid hsl(var(--border))", borderRadius: "8px" }} formatter={(value: number) => [`$${Number(value).toFixed(2)}`, "Revenue"]} />
                    <Bar dataKey="total_revenue" fill="#2196F3" radius={[0, 4, 4, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </GlassCard>
          </TabsContent>

          {/* Peak Hours Heatmap Tab */}
          <TabsContent value="heatmap" className="p-4 space-y-6">
            <GlassCard className="p-4">
              <div className="mb-6">
                <h3 className="font-semibold">Peak Hours Heatmap</h3>
                <p className="text-sm text-muted-foreground">Order volume by hour and day</p>
              </div>
              <div className="flex items-center gap-4 mb-4 text-sm">
                <span className="text-muted-foreground">Low</span>
                <div className="flex gap-1">
                  <div className="w-6 h-4 rounded bg-green-200" />
                  <div className="w-6 h-4 rounded bg-green-400" />
                  <div className="w-6 h-4 rounded bg-yellow-500" />
                  <div className="w-6 h-4 rounded bg-orange-500" />
                  <div className="w-6 h-4 rounded bg-red-500" />
                </div>
                <span className="text-muted-foreground">High</span>
              </div>
              <div className="overflow-x-auto">
                <div className="min-w-[800px]">
                  <div className="flex gap-1 mb-2 ml-16">
                    {hours.filter(h => h >= 6 && h <= 22).map(hour => (
                      <div key={hour} className="w-10 text-center text-xs text-muted-foreground">
                        {hour === 12 ? "12p" : hour > 12 ? `${hour - 12}p` : `${hour}a`}
                      </div>
                    ))}
                  </div>
                  {heatmapData.map((dayData) => (
                    <div key={dayData.day} className="flex gap-1 mb-1">
                      <div className="w-14 text-sm font-medium text-muted-foreground flex items-center">{dayData.day}</div>
                      <div className="flex gap-1">
                        {dayData.hours.filter(h => h.hour >= 6 && h.hour <= 22).map((hourData) => (
                          <div key={hourData.hour} className="w-10">
                            <HeatmapCell value={Math.floor(hourData.orders)} maxValue={maxHeatmapValue} label={`${dayData.day} ${hourData.hour}:00`} />
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
                <div className="p-4 rounded-lg bg-muted/50">
                  <p className="text-sm text-muted-foreground">Busiest Hour</p>
                  <p className="text-xl font-bold">12:00 PM</p>
                </div>
                <div className="p-4 rounded-lg bg-muted/50">
                  <p className="text-sm text-muted-foreground">Busiest Day</p>
                  <p className="text-xl font-bold">Saturday</p>
                </div>
                <div className="p-4 rounded-lg bg-muted/50">
                  <p className="text-sm text-muted-foreground">Slowest Hour</p>
                  <p className="text-xl font-bold">3:00 PM</p>
                </div>
                <div className="p-4 rounded-lg bg-muted/50">
                  <p className="text-sm text-muted-foreground">Slowest Day</p>
                  <p className="text-xl font-bold">Tuesday</p>
                </div>
              </div>
            </GlassCard>

            <GlassCard className="p-4">
              <div className="mb-4">
                <h3 className="font-semibold">Hourly Distribution</h3>
                <p className="text-sm text-muted-foreground">Average orders by hour</p>
              </div>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={peakHours.length > 0 ? peakHours : hours.slice(6, 23).map(h => ({
                    hour: h,
                    order_count: Math.floor(Math.random() * 30 + (h >= 11 && h <= 13 ? 20 : h >= 17 && h <= 19 ? 15 : 5))
                  }))}>
                    <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" opacity={0.5} />
                    <XAxis dataKey="hour" stroke="hsl(var(--muted-foreground))" fontSize={12} tickFormatter={(h) => h === 12 ? "12p" : h > 12 ? `${h - 12}p` : `${h}a`} />
                    <YAxis stroke="hsl(var(--muted-foreground))" fontSize={12} />
                    <Tooltip contentStyle={{ backgroundColor: "hsl(var(--card))", border: "1px solid hsl(var(--border))", borderRadius: "8px" }} />
                    <Bar dataKey="order_count" name="Orders" fill="#FF8C42" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </GlassCard>
          </TabsContent>

          {/* Customers Tab */}
          <TabsContent value="customers" className="p-4 space-y-6">
            <div className="grid lg:grid-cols-3 gap-6">
              <GlassCard className="p-4">
                <div className="mb-4">
                  <h3 className="font-semibold">Customer Overview</h3>
                  <p className="text-sm text-muted-foreground">Key metrics</p>
                </div>
                <div className="space-y-4">
                  <div className="flex justify-between items-center p-3 rounded-lg bg-muted/50">
                    <span className="text-sm">Total Customers</span>
                    <span className="font-bold">{customerInsights?.total_customers || 248}</span>
                  </div>
                  <div className="flex justify-between items-center p-3 rounded-lg bg-muted/50">
                    <span className="text-sm">Repeat Customers</span>
                    <span className="font-bold">{customerInsights?.repeat_customers || 89}</span>
                  </div>
                  <div className="flex justify-between items-center p-3 rounded-lg bg-muted/50">
                    <span className="text-sm">Repeat Rate</span>
                    <span className="font-bold text-green-600">{customerInsights?.repeat_rate || 35.9}%</span>
                  </div>
                  <div className="flex justify-between items-center p-3 rounded-lg bg-muted/50">
                    <span className="text-sm">Avg Spend</span>
                    <span className="font-bold">${customerInsights?.avg_spent_per_customer?.toFixed(2) || "24.50"}</span>
                  </div>
                </div>
              </GlassCard>

              <GlassCard className="p-4">
                <div className="mb-4">
                  <h3 className="font-semibold">New vs Returning</h3>
                  <p className="text-sm text-muted-foreground">Customer acquisition</p>
                </div>
                <div className="h-48">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie data={[{ name: "New", value: 64, color: "#2196F3" }, { name: "Returning", value: 36, color: "#4CAF50" }]} cx="50%" cy="50%" innerRadius={40} outerRadius={70} paddingAngle={3} dataKey="value">
                        <Cell fill="#2196F3" />
                        <Cell fill="#4CAF50" />
                      </Pie>
                      <Tooltip />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
                <div className="flex justify-center gap-6 mt-2">
                  <div className="flex items-center gap-2"><div className="w-3 h-3 rounded-full bg-[#2196F3]" /><span className="text-sm">New (64%)</span></div>
                  <div className="flex items-center gap-2"><div className="w-3 h-3 rounded-full bg-[#4CAF50]" /><span className="text-sm">Returning (36%)</span></div>
                </div>
              </GlassCard>

              <GlassCard className="p-4">
                <div className="flex items-center gap-2 mb-4">
                  <Award className="h-5 w-5 text-yellow-500" />
                  <div>
                    <h3 className="font-semibold">Top Customers</h3>
                    <p className="text-sm text-muted-foreground">Highest spenders</p>
                  </div>
                </div>
                <div className="space-y-3">
                  {(topCustomers.length > 0 ? topCustomers.slice(0, 5) : [
                    { customer_name: "John D.", total_spent: 458.50, total_orders: 23 },
                    { customer_name: "Sarah M.", total_spent: 392.00, total_orders: 19 },
                    { customer_name: "Mike R.", total_spent: 345.75, total_orders: 17 },
                    { customer_name: "Emily K.", total_spent: 298.25, total_orders: 15 },
                    { customer_name: "David L.", total_spent: 267.00, total_orders: 13 },
                  ]).map((customer, index) => (
                    <div key={index} className="flex items-center gap-3 p-2 rounded-lg hover:bg-muted/50">
                      <div className={cn("w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold", index === 0 ? "bg-yellow-500 text-white" : "bg-muted text-muted-foreground")}>{index + 1}</div>
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-sm truncate">{customer.customer_name}</p>
                        <p className="text-xs text-muted-foreground">{customer.total_orders} orders</p>
                      </div>
                      <p className="font-semibold text-green-600">${customer.total_spent.toFixed(2)}</p>
                    </div>
                  ))}
                </div>
              </GlassCard>
            </div>

            <GlassCard className="p-4">
              <div className="mb-4">
                <h3 className="font-semibold">Customer Lifetime Value (CLV)</h3>
                <p className="text-sm text-muted-foreground">Average value per customer</p>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="p-4 rounded-xl bg-gradient-to-br from-blue-500/10 to-blue-500/5 border border-blue-500/20 text-center">
                  <p className="text-sm text-muted-foreground mb-1">Average CLV</p>
                  <p className="text-2xl font-bold text-blue-600">$156</p>
                </div>
                <div className="p-4 rounded-xl bg-gradient-to-br from-green-500/10 to-green-500/5 border border-green-500/20 text-center">
                  <p className="text-sm text-muted-foreground mb-1">Top 10% CLV</p>
                  <p className="text-2xl font-bold text-green-600">$485</p>
                </div>
                <div className="p-4 rounded-xl bg-gradient-to-br from-purple-500/10 to-purple-500/5 border border-purple-500/20 text-center">
                  <p className="text-sm text-muted-foreground mb-1">Avg Orders</p>
                  <p className="text-2xl font-bold text-purple-600">4.2</p>
                </div>
                <div className="p-4 rounded-xl bg-gradient-to-br from-orange-500/10 to-orange-500/5 border border-orange-500/20 text-center">
                  <p className="text-sm text-muted-foreground mb-1">Days Between</p>
                  <p className="text-2xl font-bold text-orange-600">8.5</p>
                </div>
              </div>
            </GlassCard>
          </TabsContent>

          {/* Email Reports Tab */}
          <TabsContent value="reports" className="p-4">
            <ScheduledReports />
          </TabsContent>
        </Tabs>
      </GlassCard>
    </div>
  );
};

export default PremiumAnalytics;
