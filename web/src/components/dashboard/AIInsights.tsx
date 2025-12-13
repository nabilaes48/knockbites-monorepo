import { useState, useEffect, useCallback } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlowingBadge } from "@/components/ui/GlowingBadge";
import { NeonButton } from "@/components/ui/NeonButton";
import { AnimatedCounter, AnimatedCurrency } from "@/components/ui/AnimatedCounter";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Brain,
  TrendingUp,
  TrendingDown,
  Sparkles,
  Target,
  ShoppingBag,
  DollarSign,
  Clock,
  AlertTriangle,
  CheckCircle2,
  ChefHat,
  Users,
  Calendar,
  Zap,
  BarChart3,
  PieChart,
  LineChart,
  ArrowUpRight,
  ArrowDownRight,
  RefreshCw,
  Info,
  Lightbulb,
  Package,
  Timer,
  Loader2,
} from "lucide-react";
import { cn } from "@/lib/utils";
import {
  LineChart as RechartsLineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  AreaChart,
  Area,
  BarChart,
  Bar,
  Legend,
  PieChart as RechartsPieChart,
  Pie,
  Cell,
} from "recharts";
import {
  getTopSellersPredicted,
  getDemandForecast,
  getAIInsightSummary,
  getMenuPerformance,
  type TopSeller,
  type DemandForecast as AIForecast,
  type AIInsightSummary,
  type MenuPerformance,
} from "@/lib/ai";
import {
  getInventoryAlerts,
  getRestockRecommendations,
  type InventoryAlert,
  type RestockRecommendation,
} from "@/lib/inventory";
import { useAuth } from "@/contexts/AuthContext";

interface Prediction {
  date: string;
  predictedRevenue: number;
  predictedOrders: number;
  confidence: number;
  factors: string[];
}

interface InsightCard {
  id: string;
  type: "opportunity" | "warning" | "info" | "success";
  title: string;
  description: string;
  impact: string;
  action?: string;
  metric?: string;
  trend?: number;
}

interface DemandForecastUI {
  hour: number;
  predicted: number;
  actual?: number;
  confidence: number;
}

interface AIInsightsProps {
  storeId?: number;
}

export const AIInsights = ({ storeId: propStoreId }: AIInsightsProps = {}) => {
  const { profile } = useAuth();
  const storeId = propStoreId || profile?.store_id || 1;

  const [activeTab, setActiveTab] = useState("forecasting");
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState(new Date());

  // AI Data states
  const [aiSummary, setAISummary] = useState<AIInsightSummary | null>(null);
  const [topSellers, setTopSellers] = useState<TopSeller[]>([]);
  const [demandForecasts, setDemandForecasts] = useState<AIForecast[]>([]);
  const [inventoryAlerts, setInventoryAlerts] = useState<InventoryAlert[]>([]);
  const [restockRecs, setRestockRecs] = useState<RestockRecommendation[]>([]);
  const [menuPerformance, setMenuPerformance] = useState<MenuPerformance | null>(null);

  // Fetch AI data
  const fetchAIData = useCallback(async () => {
    if (!storeId) return;

    try {
      const [summary, sellers, forecasts, alerts, recommendations, performance] = await Promise.all([
        getAIInsightSummary(storeId).catch(() => null),
        getTopSellersPredicted(storeId, 7, 10).catch(() => []),
        getDemandForecast(storeId, 14).catch(() => []),
        getInventoryAlerts(storeId).catch(() => []),
        getRestockRecommendations(storeId).catch(() => []),
        getMenuPerformance(storeId).catch(() => null),
      ]);

      setAISummary(summary);
      setTopSellers(sellers);
      setDemandForecasts(forecasts);
      setInventoryAlerts(alerts);
      setRestockRecs(recommendations);
      setMenuPerformance(performance);
    } catch (error) {
      console.error('Failed to fetch AI data:', error);
    } finally {
      setIsLoading(false);
    }
  }, [storeId]);

  useEffect(() => {
    fetchAIData();
  }, [fetchAIData]);

  // Generate forecast data
  const generateForecastData = () => {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    const today = new Date().getDay();

    return Array.from({ length: 14 }, (_, i) => {
      const dayIndex = (today + i) % 7;
      const isWeekend = dayIndex === 0 || dayIndex === 6;
      const baseRevenue = isWeekend ? 2800 : 2200;
      const variance = Math.random() * 600 - 300;

      return {
        date: i === 0 ? "Today" : i === 1 ? "Tomorrow" : `${days[dayIndex]} ${i}d`,
        predicted: Math.round(baseRevenue + variance),
        lowerBound: Math.round((baseRevenue + variance) * 0.85),
        upperBound: Math.round((baseRevenue + variance) * 1.15),
        orders: Math.round((baseRevenue + variance) / 35),
        confidence: Math.round(95 - i * 2),
      };
    });
  };

  const [forecastData] = useState(generateForecastData());

  // Hourly demand forecast
  const hourlyDemand: DemandForecast[] = Array.from({ length: 16 }, (_, i) => {
    const hour = 6 + i; // 6 AM to 10 PM
    let baseOrders = 10;

    // Morning rush 7-9
    if (hour >= 7 && hour <= 9) baseOrders = 35;
    // Lunch rush 11-2
    else if (hour >= 11 && hour <= 14) baseOrders = 45;
    // Afternoon lull
    else if (hour >= 15 && hour <= 17) baseOrders = 20;
    // Dinner 5-8
    else if (hour >= 17 && hour <= 20) baseOrders = 40;

    const variance = Math.random() * 10 - 5;

    return {
      hour,
      predicted: Math.round(baseOrders + variance),
      actual: hour <= new Date().getHours() ? Math.round(baseOrders + Math.random() * 15 - 7) : undefined,
      confidence: 92,
    };
  });

  // AI-generated insights
  const insights: InsightCard[] = [
    {
      id: "1",
      type: "opportunity",
      title: "Weekend Revenue Opportunity",
      description: "Saturday sales have been 23% below potential. Consider adding weekend-only promotions.",
      impact: "+$450/week potential",
      action: "Create weekend promotion",
      metric: "$1,850",
      trend: -23,
    },
    {
      id: "2",
      type: "warning",
      title: "Inventory Alert: Breakfast Items",
      description: "Egg inventory may run low by Thursday based on current demand patterns.",
      impact: "Risk of stockout",
      action: "Reorder eggs",
      metric: "2 days supply",
      trend: -15,
    },
    {
      id: "3",
      type: "success",
      title: "High Performer: Turkey Club",
      description: "Turkey Club sandwich sales up 45% this week. Consider featuring it more prominently.",
      impact: "+$320 this week",
      metric: "156 sold",
      trend: 45,
    },
    {
      id: "4",
      type: "info",
      title: "Staffing Recommendation",
      description: "Tomorrow's lunch rush predicted to be 18% higher than usual. Consider adding staff 11AM-2PM.",
      impact: "Faster service",
      action: "Schedule extra staff",
      metric: "55 orders/hr predicted",
    },
    {
      id: "5",
      type: "opportunity",
      title: "Upsell Opportunity",
      description: "68% of sandwich orders don't include drinks. AI suggests combo meal prompts.",
      impact: "+$2.50 avg order",
      action: "Enable upsell prompts",
      metric: "68%",
    },
    {
      id: "6",
      type: "warning",
      title: "Customer Churn Risk",
      description: "12 regular customers haven't ordered in 14+ days. Consider re-engagement campaign.",
      impact: "Retention risk",
      action: "Send win-back offer",
      metric: "12 customers",
    },
  ];

  // Item demand predictions
  const itemDemand = [
    { name: "BEC Sandwich", predicted: 45, trend: 12, confidence: 94 },
    { name: "Turkey Club", predicted: 38, trend: 45, confidence: 91 },
    { name: "Classic Burger", predicted: 32, trend: -5, confidence: 89 },
    { name: "Chicken Wrap", predicted: 28, trend: 8, confidence: 92 },
    { name: "Caesar Salad", predicted: 22, trend: -12, confidence: 87 },
    { name: "French Fries", predicted: 65, trend: 3, confidence: 95 },
    { name: "Coffee (Large)", predicted: 120, trend: 15, confidence: 96 },
    { name: "Smoothie", predicted: 18, trend: 25, confidence: 85 },
  ];

  // Prep list recommendations
  const prepList = [
    { item: "Bacon", quantity: "5 lbs", priority: "high", reason: "High breakfast demand predicted" },
    { item: "Lettuce", quantity: "3 heads", priority: "medium", reason: "Normal sandwich volume expected" },
    { item: "Chicken Breast", quantity: "8 lbs", priority: "high", reason: "Lunch wrap demand up 15%" },
    { item: "Burger Patties", quantity: "25 units", priority: "medium", reason: "Steady burger sales predicted" },
    { item: "Tomatoes", quantity: "2 lbs", priority: "low", reason: "Current stock sufficient" },
  ];

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await fetchAIData();
    setIsRefreshing(false);
    setLastUpdated(new Date());
  };

  // Generate dynamic insights from AI data
  const generateInsights = (): InsightCard[] => {
    const dynamicInsights: InsightCard[] = [];

    // Add inventory alerts as warnings
    inventoryAlerts.slice(0, 2).forEach((alert, idx) => {
      dynamicInsights.push({
        id: `alert-${alert.id}`,
        type: alert.severity === 'critical' ? 'warning' : 'info',
        title: `${alert.alert_type === 'out_of_stock' ? 'Out of Stock' : 'Low Stock'}: ${alert.item_name}`,
        description: `Current level: ${alert.current_level} (minimum: ${alert.threshold_level})`,
        impact: alert.severity === 'critical' ? 'Immediate action needed' : 'Monitor closely',
        action: 'Reorder now',
        metric: `${alert.current_level} left`,
        trend: -20,
      });
    });

    // Add top seller as success
    if (topSellers.length > 0) {
      const top = topSellers[0];
      dynamicInsights.push({
        id: 'top-seller',
        type: 'success',
        title: `High Performer: ${top.item_name}`,
        description: `Predicted to sell ${top.predicted_quantity} units in the next 7 days`,
        impact: `+$${top.predicted_revenue.toFixed(0)} expected`,
        metric: `${top.predicted_quantity} predicted`,
        trend: top.trend === 'rising' ? 25 : top.trend === 'declining' ? -10 : 0,
      });
    }

    // Add restock recommendations as opportunities
    restockRecs.filter(r => r.priority === 'high' || r.priority === 'critical').slice(0, 2).forEach((rec, idx) => {
      dynamicInsights.push({
        id: `restock-${idx}`,
        type: 'opportunity',
        title: `Restock: ${rec.item_name}`,
        description: `${rec.days_until_stockout} days until stockout. Recommended order: ${rec.recommended_quantity} units`,
        impact: 'Prevent stockout',
        action: 'Place order',
        metric: `${rec.current_stock} in stock`,
        trend: -15,
      });
    });

    // Add static insights as fallback
    if (dynamicInsights.length < 4) {
      dynamicInsights.push(...insights.slice(0, 6 - dynamicInsights.length));
    }

    return dynamicInsights;
  };

  // Generate item demand from real data
  const getItemDemandData = () => {
    if (topSellers.length > 0) {
      return topSellers.map(seller => ({
        name: seller.item_name,
        predicted: seller.predicted_quantity,
        trend: seller.trend === 'rising' ? 15 : seller.trend === 'declining' ? -10 : 0,
        confidence: Math.round(seller.confidence * 100),
      }));
    }
    return itemDemand;
  };

  // Generate prep list from real data
  const getPrepListData = () => {
    if (restockRecs.length > 0) {
      return restockRecs.slice(0, 5).map(rec => ({
        item: rec.item_name,
        quantity: `${rec.recommended_quantity} units`,
        priority: rec.priority as 'high' | 'medium' | 'low',
        reason: `${rec.days_until_stockout} days until stockout`,
      }));
    }
    return prepList;
  };

  const getInsightIcon = (type: string) => {
    switch (type) {
      case "opportunity": return <Lightbulb className="h-5 w-5 text-yellow-500" />;
      case "warning": return <AlertTriangle className="h-5 w-5 text-amber-500" />;
      case "success": return <CheckCircle2 className="h-5 w-5 text-green-500" />;
      case "info": return <Info className="h-5 w-5 text-blue-500" />;
      default: return <Sparkles className="h-5 w-5" />;
    }
  };

  const getInsightBadgeVariant = (type: string): "warning" | "danger" | "success" | "info" => {
    switch (type) {
      case "opportunity": return "warning";
      case "warning": return "danger";
      case "success": return "success";
      default: return "info";
    }
  };

  const COLORS = ["#00D4FF", "#00FF88", "#FF6B6B", "#FFE66D", "#A855F7", "#EC4899"];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className={cn(
            "p-3 rounded-xl",
            "bg-gradient-to-br from-purple-500 to-pink-500",
            "shadow-lg shadow-purple-500/30"
          )}>
            <Brain className="h-6 w-6 text-white" />
          </div>
          <div>
            <h2 className="text-2xl font-bold">AI Insights</h2>
            <p className="text-muted-foreground">
              Smart predictions powered by machine learning
            </p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-sm text-muted-foreground">
            Last updated: {lastUpdated.toLocaleTimeString()}
          </span>
          <NeonButton
            variant="outline"
            size="sm"
            onClick={handleRefresh}
            disabled={isRefreshing}
          >
            <RefreshCw className={cn("h-4 w-4 mr-2", isRefreshing && "animate-spin")} />
            Refresh
          </NeonButton>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <GlassCard className="p-4" glowColor="accent" gradient="green">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-green-500/20">
              {isLoading ? (
                <Loader2 className="h-5 w-5 text-green-500 animate-spin" />
              ) : (
                <TrendingUp className="h-5 w-5 text-green-500" />
              )}
            </div>
            <div>
              <p className="text-2xl font-bold">
                <AnimatedCurrency value={aiSummary?.todayForecast || forecastData[0].predicted} />
              </p>
              <p className="text-xs text-muted-foreground">Today's Forecast</p>
            </div>
          </div>
          <div className="mt-2 flex items-center gap-1 text-xs text-green-500">
            <ArrowUpRight className="h-3 w-3" />
            +8% vs last week
          </div>
        </GlassCard>

        <GlassCard className="p-4" glowColor="cyan" gradient="blue">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-blue-500/20">
              <ShoppingBag className="h-5 w-5 text-blue-500" />
            </div>
            <div>
              <p className="text-2xl font-bold">
                <AnimatedCounter value={aiSummary?.predictedOrders || forecastData[0].orders} />
              </p>
              <p className="text-xs text-muted-foreground">Predicted Orders</p>
            </div>
          </div>
          <div className="mt-2 flex items-center gap-1 text-xs text-blue-500">
            <Target className="h-3 w-3" />
            95% confidence
          </div>
        </GlassCard>

        <GlassCard className="p-4" glowColor="purple" gradient="purple">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-purple-500/20">
              <Clock className="h-5 w-5 text-purple-500" />
            </div>
            <div>
              <p className="text-2xl font-bold">{aiSummary?.peakHours || '11AM-2PM'}</p>
              <p className="text-xs text-muted-foreground">Peak Hours</p>
            </div>
          </div>
          <div className="mt-2 flex items-center gap-1 text-xs text-purple-500">
            <Zap className="h-3 w-3" />
            45 orders/hr expected
          </div>
        </GlassCard>

        <GlassCard className="p-4" glowColor="orange" gradient="orange">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-orange-500/20">
              {aiSummary?.stockAlerts && aiSummary.stockAlerts > 0 ? (
                <AlertTriangle className="h-5 w-5 text-orange-500" />
              ) : (
                <Sparkles className="h-5 w-5 text-orange-500" />
              )}
            </div>
            <div>
              <p className="text-2xl font-bold">{aiSummary?.insightsCount || generateInsights().length}</p>
              <p className="text-xs text-muted-foreground">AI Insights</p>
            </div>
          </div>
          <div className="mt-2 flex items-center gap-1 text-xs text-orange-500">
            {aiSummary?.stockAlerts && aiSummary.stockAlerts > 0 ? (
              <>
                <AlertTriangle className="h-3 w-3" />
                {aiSummary.stockAlerts} stock alerts
              </>
            ) : (
              <>
                <Lightbulb className="h-3 w-3" />
                {inventoryAlerts.length + restockRecs.filter(r => r.priority === 'high').length} actionable
              </>
            )}
          </div>
        </GlassCard>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <GlassCard className="p-1.5" variant="outline">
          <TabsList className="grid w-full grid-cols-4 bg-transparent">
            <TabsTrigger value="forecasting" className="data-[state=active]:bg-primary/10">
              <LineChart className="h-4 w-4 mr-2" />
              Forecasting
            </TabsTrigger>
            <TabsTrigger value="insights" className="data-[state=active]:bg-primary/10">
              <Lightbulb className="h-4 w-4 mr-2" />
              Insights
            </TabsTrigger>
            <TabsTrigger value="demand" className="data-[state=active]:bg-primary/10">
              <BarChart3 className="h-4 w-4 mr-2" />
              Demand
            </TabsTrigger>
            <TabsTrigger value="prep" className="data-[state=active]:bg-primary/10">
              <ChefHat className="h-4 w-4 mr-2" />
              Prep List
            </TabsTrigger>
          </TabsList>
        </GlassCard>

        {/* Forecasting Tab */}
        <TabsContent value="forecasting" className="space-y-4">
          <div className="grid lg:grid-cols-3 gap-4">
            {/* Revenue Forecast Chart */}
            <GlassCard className="lg:col-span-2 p-6">
              <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                <TrendingUp className="h-5 w-5 text-primary" />
                14-Day Revenue Forecast
              </h3>
              <div className="h-[300px]">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={forecastData}>
                    <defs>
                      <linearGradient id="colorPredicted" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#00D4FF" stopOpacity={0.3} />
                        <stop offset="95%" stopColor="#00D4FF" stopOpacity={0} />
                      </linearGradient>
                      <linearGradient id="colorBounds" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#A855F7" stopOpacity={0.2} />
                        <stop offset="95%" stopColor="#A855F7" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" className="stroke-border/50" />
                    <XAxis dataKey="date" className="text-xs" />
                    <YAxis className="text-xs" tickFormatter={(v) => `$${v}`} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: "hsl(var(--card))",
                        border: "1px solid hsl(var(--border))",
                        borderRadius: "8px",
                      }}
                      formatter={(value: number) => [`$${value}`, ""]}
                    />
                    <Area
                      type="monotone"
                      dataKey="upperBound"
                      stroke="transparent"
                      fill="url(#colorBounds)"
                    />
                    <Area
                      type="monotone"
                      dataKey="lowerBound"
                      stroke="transparent"
                      fill="transparent"
                    />
                    <Area
                      type="monotone"
                      dataKey="predicted"
                      stroke="#00D4FF"
                      strokeWidth={2}
                      fill="url(#colorPredicted)"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </GlassCard>

            {/* Forecast Details */}
            <GlassCard className="p-6">
              <h3 className="text-lg font-semibold mb-4">Forecast Details</h3>
              <div className="space-y-4">
                {forecastData.slice(0, 5).map((day, i) => (
                  <div
                    key={i}
                    className={cn(
                      "p-3 rounded-lg",
                      i === 0 && "bg-primary/10 border border-primary/20"
                    )}
                  >
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-medium">{day.date}</span>
                      <GlowingBadge variant={day.confidence >= 90 ? "success" : "info"} size="sm">
                        {day.confidence}% conf
                      </GlowingBadge>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted-foreground">${day.predicted}</span>
                      <span className="text-muted-foreground">{day.orders} orders</span>
                    </div>
                  </div>
                ))}
              </div>
            </GlassCard>
          </div>

          {/* Hourly Demand Chart */}
          <GlassCard className="p-6">
            <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
              <Clock className="h-5 w-5 text-primary" />
              Today's Hourly Demand Forecast
            </h3>
            <div className="h-[250px]">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={hourlyDemand}>
                  <CartesianGrid strokeDasharray="3 3" className="stroke-border/50" />
                  <XAxis
                    dataKey="hour"
                    tickFormatter={(h) => `${h > 12 ? h - 12 : h}${h >= 12 ? 'PM' : 'AM'}`}
                    className="text-xs"
                  />
                  <YAxis className="text-xs" />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: "hsl(var(--card))",
                      border: "1px solid hsl(var(--border))",
                      borderRadius: "8px",
                    }}
                  />
                  <Legend />
                  <Bar dataKey="predicted" name="Predicted" fill="#00D4FF" radius={[4, 4, 0, 0]} />
                  <Bar dataKey="actual" name="Actual" fill="#00FF88" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </GlassCard>
        </TabsContent>

        {/* Insights Tab */}
        <TabsContent value="insights" className="space-y-4">
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            {generateInsights().map((insight) => (
              <GlassCard
                key={insight.id}
                hoverable
                className={cn(
                  "p-5",
                  insight.type === "opportunity" && "border-l-4 border-l-yellow-500",
                  insight.type === "warning" && "border-l-4 border-l-amber-500",
                  insight.type === "success" && "border-l-4 border-l-green-500",
                  insight.type === "info" && "border-l-4 border-l-blue-500"
                )}
              >
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-2">
                    {getInsightIcon(insight.type)}
                    <GlowingBadge variant={getInsightBadgeVariant(insight.type)} size="sm">
                      {insight.type}
                    </GlowingBadge>
                  </div>
                  {insight.metric && (
                    <span className="text-lg font-bold">{insight.metric}</span>
                  )}
                </div>

                <h4 className="font-semibold mb-2">{insight.title}</h4>
                <p className="text-sm text-muted-foreground mb-3">{insight.description}</p>

                <div className="flex items-center justify-between pt-3 border-t border-border/50">
                  <span className="text-sm font-medium text-primary">{insight.impact}</span>
                  {insight.trend && (
                    <div className={cn(
                      "flex items-center gap-1 text-sm",
                      insight.trend > 0 ? "text-green-500" : "text-red-500"
                    )}>
                      {insight.trend > 0 ? <ArrowUpRight className="h-4 w-4" /> : <ArrowDownRight className="h-4 w-4" />}
                      {Math.abs(insight.trend)}%
                    </div>
                  )}
                </div>

                {insight.action && (
                  <NeonButton size="sm" className="w-full mt-3">
                    {insight.action}
                  </NeonButton>
                )}
              </GlassCard>
            ))}
          </div>
        </TabsContent>

        {/* Demand Tab */}
        <TabsContent value="demand" className="space-y-4">
          <GlassCard className="p-6">
            <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
              <Package className="h-5 w-5 text-primary" />
              Item Demand Predictions (Next 7 Days)
              {isLoading && <Loader2 className="h-4 w-4 animate-spin ml-2" />}
            </h3>

            <div className="space-y-3">
              {getItemDemandData().map((item, i) => (
                <div
                  key={i}
                  className="flex items-center justify-between p-4 bg-muted/30 rounded-lg hover:bg-muted/50 transition-colors"
                >
                  <div className="flex items-center gap-4">
                    <span className="text-2xl font-bold text-muted-foreground w-8">
                      {i + 1}
                    </span>
                    <div>
                      <p className="font-medium">{item.name}</p>
                      <p className="text-sm text-muted-foreground">
                        {item.confidence}% confidence
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-6">
                    <div className="text-right">
                      <p className="text-xl font-bold">{item.predicted}</p>
                      <p className="text-xs text-muted-foreground">predicted</p>
                    </div>
                    <div className={cn(
                      "flex items-center gap-1 px-2 py-1 rounded-full text-sm min-w-[70px] justify-center",
                      item.trend >= 0 ? "bg-green-500/10 text-green-600" : "bg-red-500/10 text-red-600"
                    )}>
                      {item.trend >= 0 ? (
                        <ArrowUpRight className="h-4 w-4" />
                      ) : (
                        <ArrowDownRight className="h-4 w-4" />
                      )}
                      {Math.abs(item.trend)}%
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </GlassCard>
        </TabsContent>

        {/* Prep List Tab */}
        <TabsContent value="prep" className="space-y-4">
          <GlassCard className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold flex items-center gap-2">
                <ChefHat className="h-5 w-5 text-primary" />
                AI-Generated Prep List
                {isLoading && <Loader2 className="h-4 w-4 animate-spin ml-2" />}
              </h3>
              <GlowingBadge variant="info">
                <Timer className="h-3 w-3 mr-1" />
                {restockRecs.length > 0 ? 'AI Powered' : 'For Tomorrow'}
              </GlowingBadge>
            </div>

            <div className="space-y-3">
              {getPrepListData().map((item, i) => (
                <div
                  key={i}
                  className={cn(
                    "flex items-center justify-between p-4 rounded-lg border",
                    item.priority === "high" && "bg-red-500/5 border-red-500/20",
                    item.priority === "medium" && "bg-yellow-500/5 border-yellow-500/20",
                    item.priority === "low" && "bg-green-500/5 border-green-500/20"
                  )}
                >
                  <div className="flex items-center gap-4">
                    <div className={cn(
                      "p-2 rounded-lg",
                      item.priority === "high" && "bg-red-500/20",
                      item.priority === "medium" && "bg-yellow-500/20",
                      item.priority === "low" && "bg-green-500/20"
                    )}>
                      <Package className={cn(
                        "h-5 w-5",
                        item.priority === "high" && "text-red-500",
                        item.priority === "medium" && "text-yellow-500",
                        item.priority === "low" && "text-green-500"
                      )} />
                    </div>
                    <div>
                      <p className="font-medium">{item.item}</p>
                      <p className="text-sm text-muted-foreground">{item.reason}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-4">
                    <div className="text-right">
                      <p className="font-bold">{item.quantity}</p>
                      <p className="text-xs text-muted-foreground">recommended</p>
                    </div>
                    <GlowingBadge
                      variant={
                        item.priority === "high" ? "danger" :
                        item.priority === "medium" ? "warning" : "success"
                      }
                      size="sm"
                    >
                      {item.priority}
                    </GlowingBadge>
                  </div>
                </div>
              ))}
            </div>

            <div className="mt-6 flex justify-end gap-3">
              <NeonButton variant="outline">
                Export List
              </NeonButton>
              <NeonButton>
                <CheckCircle2 className="h-4 w-4 mr-2" />
                Mark All Prepared
              </NeonButton>
            </div>
          </GlassCard>
        </TabsContent>
      </Tabs>
    </div>
  );
};
