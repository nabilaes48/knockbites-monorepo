import { useState, useEffect } from "react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlowingBadge } from "@/components/ui/GlowingBadge";
import { NeonButton } from "@/components/ui/NeonButton";
import { AnimatedCounter, AnimatedCurrency, AnimatedPercentage } from "@/components/ui/AnimatedCounter";
import {
  DollarSign,
  ShoppingBag,
  Users,
  TrendingUp,
  Store,
  Calendar,
  RefreshCw,
  Pause,
  Play,
  AlertCircle,
  Clock,
  Star,
  BarChart3,
} from "lucide-react";
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
} from "recharts";
import { useAnalytics } from "@/hooks/useAnalytics";
import { useAuth } from "@/contexts/AuthContext";
import { cn } from "@/lib/utils";

export const Analytics = () => {
  const { profile } = useAuth();

  // SECURITY: Derive store from authenticated user profile, never hardcode
  // CVE-2025-KB002: Previously hardcoded to store_id=1, leaking other stores' data
  const [selectedStore, setSelectedStore] = useState<number | null>(null);

  useEffect(() => {
    if (!profile) return;

    if (profile.role === 'super_admin') {
      // Super admin: can see all stores, but must explicitly select
      // Default to first assigned store or null for "all stores"
      setSelectedStore(profile.assigned_stores?.[0] || profile.store_id || null);
    } else if (profile.store_id) {
      // Staff/manager/admin: use their primary store
      setSelectedStore(profile.store_id);
    } else if (profile.assigned_stores?.length > 0) {
      // Fallback to first assigned store
      setSelectedStore(profile.assigned_stores[0]);
    }
  }, [profile]);

  const [dateRange, setDateRange] = useState<string>("today");
  const [autoRefresh, setAutoRefresh] = useState(false);

  const {
    metrics,
    revenueData,
    timeDistribution,
    categoryDistribution,
    popularItems,
    loading,
    error,
    refresh,
  } = useAnalytics(selectedStore, dateRange);

  // Auto-refresh effect
  useEffect(() => {
    if (!autoRefresh) return;
    const interval = setInterval(() => {
      refresh();
    }, 30000);
    return () => clearInterval(interval);
  }, [autoRefresh, refresh]);

  // Loading state
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <div
            className={cn(
              "h-12 w-12 rounded-full border-2 animate-spin mx-auto",
              "border-primary/30 border-t-primary"
            )}
          />
          <p className="mt-4 text-muted-foreground">Loading analytics...</p>
        </div>
      </div>
    );
  }

  // Error state
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

  // Map data for charts
  const revenueChartData = revenueData.map((d) => ({
    time: d.time_label,
    revenue: Number(d.revenue),
    orders: Number(d.orders),
  }));

  const orderDistributionData = timeDistribution.map((d) => {
    const total = timeDistribution.reduce((sum, item) => sum + item.order_count, 0);
    const colors: Record<string, string> = {
      Breakfast: "#f59e0b",
      Lunch: "#10b981",
      Dinner: "#3b82f6",
      Evening: "#8b5cf6",
    };
    return {
      name: d.time_period,
      value: d.order_count,
      percentage: total > 0 ? ((d.order_count / total) * 100).toFixed(1) : "0",
      color: colors[d.time_period] || "#6b7280",
    };
  });

  const categoryColors = ["#00f0ff", "#a855f7", "#22c55e", "#ff7700", "#ff4d94", "#3b82f6"];
  const categoryDistributionData = categoryDistribution.map((d, i) => ({
    name: d.category || "Uncategorized",
    value: d.order_count,
    color: categoryColors[i % categoryColors.length],
  }));

  return (
    <div className="space-y-6">
      {/* Header with Controls */}
      <div className="flex flex-col md:flex-row justify-between gap-4">
        <div>
          <h2 className="text-2xl font-semibold flex items-center gap-2 text-foreground">
            <div
              className={cn(
                "p-2 rounded-lg",
                "bg-primary/10 text-primary",
                "dark:shadow-glow-primary"
              )}
            >
              <BarChart3 className="h-5 w-5" />
            </div>
            Analytics Dashboard
          </h2>
          <p className="text-muted-foreground mt-1">
            {dateRange === "today"
              ? "Today's"
              : dateRange === "week"
              ? "This Week's"
              : "This Month's"}{" "}
            performance metrics
          </p>
        </div>

        <div className="flex flex-wrap gap-3">
          <Select value={dateRange} onValueChange={setDateRange}>
            <SelectTrigger
              className={cn(
                "w-[180px]",
                "bg-secondary/50 border-border/50",
                "dark:bg-card/50 dark:border-primary/10"
              )}
            >
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

          <GlowingBadge variant="info" className="px-3 py-2">
            <Store className="h-4 w-4 mr-2" />
            Highland Mills Snack Shop Inc
          </GlowingBadge>

          <NeonButton
            variant={autoRefresh ? "primary" : "secondary"}
            size="icon"
            onClick={() => setAutoRefresh(!autoRefresh)}
            title="Toggle auto-refresh every 30s"
          >
            {autoRefresh ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
          </NeonButton>

          <NeonButton
            variant="secondary"
            size="icon"
            onClick={refresh}
            disabled={loading}
            title="Refresh now"
          >
            <RefreshCw className={cn("h-4 w-4", loading && "animate-spin")} />
          </NeonButton>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-4">
        <GlassCard glowColor="accent" gradient="green" className="p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Total Revenue</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCurrency value={metrics?.total_revenue ? Number(metrics.total_revenue) : 0} />
              </h3>
              <p className="text-xs text-accent dark:text-neon-green mt-1 flex items-center gap-1">
                <TrendingUp className="h-3 w-3" />
                +8.2% from last period
              </p>
            </div>
            <div
              className={cn(
                "h-12 w-12 rounded-2xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-green/20 to-ios-teal/10 text-ios-green",
                "dark:from-neon-green/20 dark:to-neon-cyan/10 dark:text-neon-green",
                "shadow-[0_4px_15px_rgba(52,199,89,0.2)] dark:shadow-[0_4px_20px_rgba(0,255,136,0.3)]"
              )}
            >
              <DollarSign className="h-6 w-6" />
            </div>
          </div>
        </GlassCard>

        <GlassCard glowColor="cyan" gradient="blue" className="p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Total Orders</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={metrics?.total_orders || 0} />
              </h3>
              <p className="text-xs text-ios-blue dark:text-neon-cyan mt-1 flex items-center gap-1">
                <ShoppingBag className="h-3 w-3" />
                Active tracking
              </p>
            </div>
            <div
              className={cn(
                "h-12 w-12 rounded-2xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-blue/20 to-ios-teal/10 text-ios-blue",
                "dark:from-neon-cyan/20 dark:to-neon-blue/10 dark:text-neon-cyan",
                "shadow-[0_4px_15px_rgba(0,122,255,0.2)] dark:shadow-[0_4px_20px_rgba(0,255,255,0.3)]"
              )}
            >
              <ShoppingBag className="h-6 w-6" />
            </div>
          </div>
        </GlassCard>

        <GlassCard glowColor="purple" gradient="purple" className="p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Avg Order Value</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCurrency value={metrics?.avg_order_value ? Number(metrics.avg_order_value) : 0} />
              </h3>
              <p className="text-xs text-ios-purple dark:text-neon-purple mt-1 flex items-center gap-1">
                <TrendingUp className="h-3 w-3" />
                +3.5% increase
              </p>
            </div>
            <div
              className={cn(
                "h-12 w-12 rounded-2xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-purple/20 to-ios-pink/10 text-ios-purple",
                "dark:from-neon-purple/20 dark:to-neon-pink/10 dark:text-neon-purple",
                "shadow-[0_4px_15px_rgba(175,82,222,0.2)] dark:shadow-[0_4px_20px_rgba(168,85,247,0.3)]"
              )}
            >
              <TrendingUp className="h-6 w-6" />
            </div>
          </div>
        </GlassCard>

        <GlassCard glowColor="orange" gradient="orange" className="p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Customers</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={metrics?.unique_customers || 0} />
              </h3>
              <p className="text-xs text-ios-orange dark:text-neon-orange mt-1 flex items-center gap-1">
                <Users className="h-3 w-3" />
                Unique visitors
              </p>
            </div>
            <div
              className={cn(
                "h-12 w-12 rounded-2xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-orange/20 to-ios-yellow/10 text-ios-orange",
                "dark:from-neon-orange/20 dark:to-amber-500/10 dark:text-neon-orange",
                "shadow-[0_4px_15px_rgba(255,149,0,0.2)] dark:shadow-[0_4px_20px_rgba(255,136,0,0.3)]"
              )}
            >
              <Users className="h-6 w-6" />
            </div>
          </div>
        </GlassCard>
      </div>

      {/* Tabs for Different Views */}
      <GlassCard className="p-1.5" gradient="cyan" intensity="subtle">
        <Tabs defaultValue="overview" className="space-y-4">
          <TabsList className="bg-transparent h-auto">
            <TabsTrigger
              value="overview"
              className={cn(
                "py-2 px-4 rounded-lg",
                "data-[state=active]:bg-secondary data-[state=active]:shadow-soft",
                "dark:data-[state=active]:bg-white/5 dark:data-[state=active]:shadow-glow-subtle"
              )}
            >
              Overview
            </TabsTrigger>
            <TabsTrigger
              value="items"
              className={cn(
                "py-2 px-4 rounded-lg",
                "data-[state=active]:bg-secondary data-[state=active]:shadow-soft",
                "dark:data-[state=active]:bg-white/5 dark:data-[state=active]:shadow-glow-subtle"
              )}
            >
              Popular Items
            </TabsTrigger>
            <TabsTrigger
              value="trends"
              className={cn(
                "py-2 px-4 rounded-lg",
                "data-[state=active]:bg-secondary data-[state=active]:shadow-soft",
                "dark:data-[state=active]:bg-white/5 dark:data-[state=active]:shadow-glow-subtle"
              )}
            >
              Trends
            </TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-4 p-4">
            <div className="grid md:grid-cols-2 gap-6">
              {/* Revenue Chart */}
              <GlassCard className="p-4" gradient="green" glowColor="accent">
                <div className="mb-4">
                  <h3 className="font-semibold">Sales Overview</h3>
                  <p className="text-sm text-muted-foreground">Revenue trends over time</p>
                </div>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={revenueChartData}>
                      <defs>
                        <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.3} />
                          <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" opacity={0.5} />
                      <XAxis
                        dataKey="time"
                        stroke="hsl(var(--muted-foreground))"
                        style={{ fontSize: "12px" }}
                      />
                      <YAxis
                        stroke="hsl(var(--muted-foreground))"
                        style={{ fontSize: "12px" }}
                        tickFormatter={(value) => `$${value >= 1000 ? (value / 1000).toFixed(0) + "k" : value}`}
                      />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: "hsl(var(--card))",
                          border: "1px solid hsl(var(--border))",
                          borderRadius: "8px",
                          padding: "12px",
                        }}
                        formatter={(value: number | string) => [`$${Number(value).toLocaleString()}`, "Revenue"]}
                      />
                      <Area
                        type="monotone"
                        dataKey="revenue"
                        stroke="hsl(var(--primary))"
                        fillOpacity={1}
                        fill="url(#colorRevenue)"
                        strokeWidth={2}
                        animationDuration={800}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </GlassCard>

              {/* Order Distribution Pie Chart */}
              <GlassCard className="p-4" gradient="purple" glowColor="purple">
                <div className="mb-4">
                  <h3 className="font-semibold">Order Distribution</h3>
                  <p className="text-sm text-muted-foreground">Orders by time of day</p>
                </div>
                <div className="h-64 flex items-center justify-center">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={orderDistributionData}
                        cx="50%"
                        cy="50%"
                        innerRadius={60}
                        outerRadius={90}
                        paddingAngle={4}
                        dataKey="value"
                      >
                        {orderDistributionData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip
                        contentStyle={{
                          backgroundColor: "hsl(var(--card))",
                          border: "1px solid hsl(var(--border))",
                          borderRadius: "8px",
                        }}
                        formatter={(value: number | string, name: string) => [value, name]}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
                <div className="flex flex-wrap justify-center gap-4 mt-4">
                  {orderDistributionData.map((entry, index) => (
                    <div key={index} className="flex items-center gap-2 text-sm">
                      <div
                        className="w-3 h-3 rounded-full"
                        style={{ backgroundColor: entry.color }}
                      />
                      <span className="text-muted-foreground">{entry.name}</span>
                      <span className="font-medium">{entry.percentage}%</span>
                    </div>
                  ))}
                </div>
              </GlassCard>
            </div>

            {/* Category Distribution */}
            <GlassCard className="p-4" gradient="rainbow" glowColor="cyan">
              <div className="mb-4">
                <h3 className="font-semibold">Category Distribution</h3>
                <p className="text-sm text-muted-foreground">Orders by menu category</p>
              </div>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={categoryDistributionData}
                      cx="50%"
                      cy="50%"
                      innerRadius={70}
                      outerRadius={100}
                      paddingAngle={3}
                      dataKey="value"
                    >
                      {categoryDistributionData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip
                      contentStyle={{
                        backgroundColor: "hsl(var(--card))",
                        border: "1px solid hsl(var(--border))",
                        borderRadius: "8px",
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div className="flex flex-wrap justify-center gap-4 mt-4">
                {categoryDistributionData.map((entry, index) => (
                  <div key={index} className="flex items-center gap-2 text-sm">
                    <div
                      className="w-3 h-3 rounded-full"
                      style={{ backgroundColor: entry.color }}
                    />
                    <span className="text-muted-foreground">{entry.name}</span>
                    <span className="font-medium">{entry.value}</span>
                  </div>
                ))}
              </div>
            </GlassCard>
          </TabsContent>

          <TabsContent value="items" className="p-4">
            <GlassCard className="p-4">
              <div className="mb-4">
                <h3 className="font-semibold">Popular Menu Items</h3>
                <p className="text-sm text-muted-foreground">Best sellers at Highland Mills Snack Shop Inc</p>
              </div>
              <div className="space-y-4">
                {popularItems.length > 0 ? (
                  popularItems.slice(0, 5).map((item, index) => (
                    <div key={item.menu_item_id} className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span className="font-medium flex items-center gap-2">
                          <span
                            className={cn(
                              "w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold",
                              index === 0
                                ? "bg-accent/20 text-accent dark:bg-neon-green/20 dark:text-neon-green"
                                : "bg-muted text-muted-foreground"
                            )}
                          >
                            {index + 1}
                          </span>
                          {item.item_name}
                        </span>
                        <div className="flex items-center gap-3">
                          <span className="text-accent dark:text-neon-green font-semibold">
                            ${Number(item.total_revenue).toFixed(2)}
                          </span>
                          <span className="text-muted-foreground">{item.times_ordered} orders</span>
                        </div>
                      </div>
                      <div className="w-full bg-muted rounded-full h-2 overflow-hidden">
                        <div
                          className={cn(
                            "h-2 rounded-full transition-all",
                            "bg-primary dark:bg-primary dark:shadow-glow-primary"
                          )}
                          style={{
                            width: `${(item.times_ordered / (popularItems[0]?.times_ordered || 1)) * 100}%`,
                          }}
                        />
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="text-center py-8 text-muted-foreground">
                    <ShoppingBag className="h-12 w-12 mx-auto mb-3 opacity-50" />
                    <p>No orders yet. Place your first order to see popular items!</p>
                  </div>
                )}
              </div>
            </GlassCard>
          </TabsContent>

          <TabsContent value="trends" className="p-4">
            <div className="grid md:grid-cols-3 gap-4">
              <GlassCard className="p-4">
                <h4 className="font-medium mb-3">Peak Hours</h4>
                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">Breakfast</span>
                    <GlowingBadge variant="warning" size="sm">7-10 AM</GlowingBadge>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">Lunch</span>
                    <GlowingBadge variant="success" size="sm">12-2 PM</GlowingBadge>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">Dinner</span>
                    <GlowingBadge variant="info" size="sm">6-8 PM</GlowingBadge>
                  </div>
                </div>
              </GlassCard>

              <GlassCard glowColor="primary" className="p-4 text-center">
                <h4 className="font-medium mb-3">Average Wait Time</h4>
                <div className="py-4">
                  <div className="flex items-center justify-center gap-2">
                    <Clock className="h-8 w-8 text-primary" />
                    <span className="text-4xl font-bold text-primary">12m</span>
                  </div>
                  <p className="text-sm text-accent dark:text-neon-green mt-3">
                    <TrendingUp className="h-3 w-3 inline mr-1" />
                    -2 min from last week
                  </p>
                </div>
              </GlassCard>

              <GlassCard glowColor="accent" className="p-4 text-center">
                <h4 className="font-medium mb-3">Customer Satisfaction</h4>
                <div className="py-4">
                  <div className="flex items-center justify-center gap-2">
                    <Star className="h-8 w-8 text-ios-yellow dark:text-neon-orange fill-current" />
                    <span className="text-4xl font-bold text-ios-yellow dark:text-neon-orange">4.7</span>
                  </div>
                  <p className="text-sm text-muted-foreground mt-3">Based on 1,248 reviews</p>
                </div>
              </GlassCard>
            </div>
          </TabsContent>
        </Tabs>
      </GlassCard>
    </div>
  );
};
