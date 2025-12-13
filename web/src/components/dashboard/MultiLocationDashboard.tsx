import { useState, useEffect } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlowingBadge } from "@/components/ui/GlowingBadge";
import { NeonButton } from "@/components/ui/NeonButton";
import { AnimatedCounter, AnimatedCurrency } from "@/components/ui/AnimatedCounter";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import {
  Building2,
  MapPin,
  TrendingUp,
  TrendingDown,
  DollarSign,
  ShoppingBag,
  Users,
  Target,
  Trophy,
  Crown,
  Medal,
  Award,
  Search,
  Filter,
  ChevronRight,
  BarChart3,
  Map,
  Settings,
  Plus,
  ArrowUpRight,
  ArrowDownRight,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/lib/supabase";
import { locations } from "@/data/locations";

interface StorePerformance {
  id: number;
  name: string;
  storeCode: string;
  region: string;
  todayRevenue: number;
  todayOrders: number;
  avgOrderValue: number;
  targetProgress: number;
  trend: number; // percentage change from yesterday
  rank: number;
  isTopPerformer: boolean;
}

interface RegionSummary {
  id: string;
  name: string;
  storeCount: number;
  todayRevenue: number;
  todayOrders: number;
  avgPerformance: number;
}

interface OrgSummary {
  totalStores: number;
  totalRegions: number;
  todayRevenue: number;
  todayOrders: number;
  avgOrderValue: number;
  uniqueCustomers: number;
}

export const MultiLocationDashboard = () => {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState("overview");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedRegion, setSelectedRegion] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // Mock data - replace with real Supabase queries
  const [orgSummary, setOrgSummary] = useState<OrgSummary>({
    totalStores: 29,
    totalRegions: 5,
    todayRevenue: 45678.90,
    todayOrders: 1234,
    avgOrderValue: 37.02,
    uniqueCustomers: 892,
  });

  const [regions, setRegions] = useState<RegionSummary[]>([
    { id: "1", name: "Hudson Valley", storeCount: 8, todayRevenue: 12450, todayOrders: 340, avgPerformance: 87 },
    { id: "2", name: "Westchester", storeCount: 6, todayRevenue: 9820, todayOrders: 265, avgPerformance: 92 },
    { id: "3", name: "Dutchess County", storeCount: 5, todayRevenue: 8340, todayOrders: 228, avgPerformance: 78 },
    { id: "4", name: "Orange County", storeCount: 6, todayRevenue: 10230, todayOrders: 276, avgPerformance: 85 },
    { id: "5", name: "Putnam County", storeCount: 4, todayRevenue: 4838, todayOrders: 125, avgPerformance: 81 },
  ]);

  const [storePerformances, setStorePerformances] = useState<StorePerformance[]>([]);

  useEffect(() => {
    // Generate store performances from locations data
    const performances: StorePerformance[] = locations.map((loc, index) => ({
      id: loc.id,
      name: loc.name,
      storeCode: `CAM-${String(loc.id).padStart(3, "0")}`,
      region: regions[index % regions.length].name,
      todayRevenue: Math.floor(Math.random() * 3000) + 800,
      todayOrders: Math.floor(Math.random() * 100) + 20,
      avgOrderValue: Math.floor(Math.random() * 20) + 25,
      targetProgress: Math.floor(Math.random() * 40) + 60,
      trend: Math.floor(Math.random() * 30) - 10,
      rank: index + 1,
      isTopPerformer: index < 3,
    }));

    // Sort by revenue
    performances.sort((a, b) => b.todayRevenue - a.todayRevenue);
    performances.forEach((p, i) => {
      p.rank = i + 1;
      p.isTopPerformer = i < 3;
    });

    setStorePerformances(performances);
    setLoading(false);
  }, []);

  const filteredStores = storePerformances.filter((store) => {
    const matchesSearch =
      store.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      store.storeCode.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesRegion = !selectedRegion || store.region === selectedRegion;
    return matchesSearch && matchesRegion;
  });

  const getRankIcon = (rank: number) => {
    if (rank === 1) return <Crown className="h-5 w-5 text-yellow-500" />;
    if (rank === 2) return <Medal className="h-5 w-5 text-gray-400" />;
    if (rank === 3) return <Award className="h-5 w-5 text-amber-600" />;
    return <span className="text-sm font-bold text-muted-foreground">#{rank}</span>;
  };

  const getRankBadgeVariant = (rank: number): "vip" | "info" | "success" | "default" => {
    if (rank === 1) return "vip";
    if (rank <= 3) return "success";
    if (rank <= 10) return "info";
    return "default";
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <div className="h-12 w-12 rounded-full border-2 border-primary/30 border-t-primary animate-spin mx-auto" />
          <p className="mt-4 text-muted-foreground">Loading multi-location data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Organization Overview Header */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <div className={cn(
              "p-2.5 rounded-xl",
              "bg-gradient-to-br from-blue-500 to-cyan-500",
              "shadow-lg shadow-blue-500/30"
            )}>
              <Building2 className="h-6 w-6 text-white" />
            </div>
            <div>
              <h2 className="text-2xl font-bold">Highland Mills Snack Shop Inc</h2>
              <p className="text-muted-foreground">Multi-Location Overview</p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <GlowingBadge variant="success" pulse>
            <TrendingUp className="h-3 w-3" />
            +12.5% vs Yesterday
          </GlowingBadge>
          <NeonButton size="sm">
            <Plus className="h-4 w-4 mr-2" />
            Add Store
          </NeonButton>
        </div>
      </div>

      {/* Organization Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <GlassCard className="p-4" glowColor="accent" gradient="green">
          <div className="text-center">
            <DollarSign className="h-6 w-6 mx-auto mb-2 text-ios-green dark:text-neon-green" />
            <p className="text-2xl font-bold">
              <AnimatedCurrency value={orgSummary.todayRevenue} />
            </p>
            <p className="text-xs text-muted-foreground">Today's Revenue</p>
          </div>
        </GlassCard>

        <GlassCard className="p-4" glowColor="cyan" gradient="blue">
          <div className="text-center">
            <ShoppingBag className="h-6 w-6 mx-auto mb-2 text-ios-blue dark:text-neon-cyan" />
            <p className="text-2xl font-bold">
              <AnimatedCounter value={orgSummary.todayOrders} />
            </p>
            <p className="text-xs text-muted-foreground">Total Orders</p>
          </div>
        </GlassCard>

        <GlassCard className="p-4" glowColor="purple" gradient="purple">
          <div className="text-center">
            <Building2 className="h-6 w-6 mx-auto mb-2 text-ios-purple dark:text-neon-purple" />
            <p className="text-2xl font-bold">
              <AnimatedCounter value={orgSummary.totalStores} />
            </p>
            <p className="text-xs text-muted-foreground">Active Stores</p>
          </div>
        </GlassCard>

        <GlassCard className="p-4" glowColor="orange" gradient="orange">
          <div className="text-center">
            <MapPin className="h-6 w-6 mx-auto mb-2 text-ios-orange dark:text-neon-orange" />
            <p className="text-2xl font-bold">
              <AnimatedCounter value={orgSummary.totalRegions} />
            </p>
            <p className="text-xs text-muted-foreground">Regions</p>
          </div>
        </GlassCard>

        <GlassCard className="p-4" glowColor="cyan" gradient="cyan">
          <div className="text-center">
            <Target className="h-6 w-6 mx-auto mb-2 text-ios-teal dark:text-neon-cyan" />
            <p className="text-2xl font-bold">
              $<AnimatedCounter value={orgSummary.avgOrderValue} decimals={2} />
            </p>
            <p className="text-xs text-muted-foreground">Avg Order</p>
          </div>
        </GlassCard>

        <GlassCard className="p-4" glowColor="pink" gradient="pink">
          <div className="text-center">
            <Users className="h-6 w-6 mx-auto mb-2 text-ios-pink dark:text-neon-pink" />
            <p className="text-2xl font-bold">
              <AnimatedCounter value={orgSummary.uniqueCustomers} />
            </p>
            <p className="text-xs text-muted-foreground">Customers</p>
          </div>
        </GlassCard>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <GlassCard className="p-1.5" variant="outline">
          <TabsList className="grid w-full grid-cols-4 bg-transparent">
            <TabsTrigger value="overview" className="data-[state=active]:bg-primary/10">
              <BarChart3 className="h-4 w-4 mr-2" />
              Leaderboard
            </TabsTrigger>
            <TabsTrigger value="regions" className="data-[state=active]:bg-primary/10">
              <Map className="h-4 w-4 mr-2" />
              Regions
            </TabsTrigger>
            <TabsTrigger value="stores" className="data-[state=active]:bg-primary/10">
              <Building2 className="h-4 w-4 mr-2" />
              All Stores
            </TabsTrigger>
            <TabsTrigger value="settings" className="data-[state=active]:bg-primary/10">
              <Settings className="h-4 w-4 mr-2" />
              Settings
            </TabsTrigger>
          </TabsList>
        </GlassCard>

        {/* Leaderboard Tab */}
        <TabsContent value="overview" className="space-y-4">
          <GlassCard className="p-6">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <Trophy className="h-6 w-6 text-yellow-500" />
                <h3 className="text-lg font-semibold">Store Leaderboard</h3>
              </div>
              <p className="text-sm text-muted-foreground">Today's Performance</p>
            </div>

            <div className="space-y-3">
              {storePerformances.slice(0, 10).map((store, index) => (
                <div
                  key={store.id}
                  className={cn(
                    "flex items-center justify-between p-4 rounded-xl transition-all",
                    index === 0 && "bg-gradient-to-r from-yellow-500/10 to-amber-500/10 border border-yellow-500/20",
                    index === 1 && "bg-gradient-to-r from-gray-300/10 to-gray-400/10 border border-gray-400/20",
                    index === 2 && "bg-gradient-to-r from-amber-600/10 to-orange-500/10 border border-amber-600/20",
                    index > 2 && "bg-muted/30 hover:bg-muted/50"
                  )}
                >
                  <div className="flex items-center gap-4">
                    <div className="w-10 flex justify-center">
                      {getRankIcon(store.rank)}
                    </div>
                    <div>
                      <p className="font-semibold">{store.name}</p>
                      <p className="text-sm text-muted-foreground">{store.storeCode} • {store.region}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-6">
                    <div className="text-right">
                      <p className="font-bold text-lg">${store.todayRevenue.toLocaleString()}</p>
                      <p className="text-xs text-muted-foreground">{store.todayOrders} orders</p>
                    </div>
                    <div className={cn(
                      "flex items-center gap-1 px-2 py-1 rounded-full text-sm",
                      store.trend >= 0 ? "bg-green-500/10 text-green-600" : "bg-red-500/10 text-red-600"
                    )}>
                      {store.trend >= 0 ? (
                        <ArrowUpRight className="h-4 w-4" />
                      ) : (
                        <ArrowDownRight className="h-4 w-4" />
                      )}
                      {Math.abs(store.trend)}%
                    </div>
                    <ChevronRight className="h-5 w-5 text-muted-foreground" />
                  </div>
                </div>
              ))}
            </div>
          </GlassCard>
        </TabsContent>

        {/* Regions Tab */}
        <TabsContent value="regions" className="space-y-4">
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            {regions.map((region) => (
              <GlassCard
                key={region.id}
                hoverable
                className="p-5 cursor-pointer"
                onClick={() => setSelectedRegion(region.name)}
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <div className={cn(
                      "p-2 rounded-lg",
                      "bg-gradient-to-br from-blue-500/20 to-cyan-500/20"
                    )}>
                      <MapPin className="h-5 w-5 text-primary" />
                    </div>
                    <div>
                      <h4 className="font-semibold">{region.name}</h4>
                      <p className="text-sm text-muted-foreground">{region.storeCount} stores</p>
                    </div>
                  </div>
                  <GlowingBadge
                    variant={region.avgPerformance >= 85 ? "success" : region.avgPerformance >= 70 ? "warning" : "danger"}
                    size="sm"
                  >
                    {region.avgPerformance}%
                  </GlowingBadge>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-2xl font-bold">${region.todayRevenue.toLocaleString()}</p>
                    <p className="text-xs text-muted-foreground">Today's Revenue</p>
                  </div>
                  <div>
                    <p className="text-2xl font-bold">{region.todayOrders}</p>
                    <p className="text-xs text-muted-foreground">Orders</p>
                  </div>
                </div>

                <div className="mt-4 pt-4 border-t border-border/50">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">View stores</span>
                    <ChevronRight className="h-4 w-4" />
                  </div>
                </div>
              </GlassCard>
            ))}
          </div>
        </TabsContent>

        {/* All Stores Tab */}
        <TabsContent value="stores" className="space-y-4">
          {/* Search and Filter */}
          <div className="flex flex-col md:flex-row gap-4">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search stores by name or code..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>
            <div className="flex gap-2">
              {regions.map((region) => (
                <NeonButton
                  key={region.id}
                  variant={selectedRegion === region.name ? "primary" : "outline"}
                  size="sm"
                  onClick={() => setSelectedRegion(selectedRegion === region.name ? null : region.name)}
                >
                  {region.name}
                </NeonButton>
              ))}
            </div>
          </div>

          {/* Stores Grid */}
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredStores.map((store) => (
              <GlassCard
                key={store.id}
                hoverable
                glowColor={store.isTopPerformer ? "accent" : "none"}
                className="p-5"
              >
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <h4 className="font-semibold">{store.name}</h4>
                      {store.isTopPerformer && (
                        <Crown className="h-4 w-4 text-yellow-500" />
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground">{store.storeCode}</p>
                  </div>
                  <GlowingBadge variant={getRankBadgeVariant(store.rank)} size="sm">
                    #{store.rank}
                  </GlowingBadge>
                </div>

                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">Revenue</span>
                    <span className="font-semibold">${store.todayRevenue.toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">Orders</span>
                    <span className="font-semibold">{store.todayOrders}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">Avg Order</span>
                    <span className="font-semibold">${store.avgOrderValue}</span>
                  </div>

                  {/* Progress Bar */}
                  <div>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="text-muted-foreground">Target Progress</span>
                      <span className={cn(
                        store.targetProgress >= 80 ? "text-green-500" :
                        store.targetProgress >= 50 ? "text-yellow-500" : "text-red-500"
                      )}>
                        {store.targetProgress}%
                      </span>
                    </div>
                    <div className="h-2 bg-muted rounded-full overflow-hidden">
                      <div
                        className={cn(
                          "h-full rounded-full transition-all",
                          store.targetProgress >= 80 ? "bg-gradient-to-r from-green-500 to-emerald-500" :
                          store.targetProgress >= 50 ? "bg-gradient-to-r from-yellow-500 to-amber-500" :
                          "bg-gradient-to-r from-red-500 to-orange-500"
                        )}
                        style={{ width: `${Math.min(store.targetProgress, 100)}%` }}
                      />
                    </div>
                  </div>

                  {/* Trend */}
                  <div className="flex items-center justify-between pt-2 border-t border-border/50">
                    <span className="text-xs text-muted-foreground">{store.region}</span>
                    <div className={cn(
                      "flex items-center gap-1 text-sm",
                      store.trend >= 0 ? "text-green-500" : "text-red-500"
                    )}>
                      {store.trend >= 0 ? <TrendingUp className="h-4 w-4" /> : <TrendingDown className="h-4 w-4" />}
                      {Math.abs(store.trend)}%
                    </div>
                  </div>
                </div>
              </GlassCard>
            ))}
          </div>
        </TabsContent>

        {/* Settings Tab */}
        <TabsContent value="settings" className="space-y-4">
          <GlassCard className="p-6">
            <h3 className="text-lg font-semibold mb-4">Organization Settings</h3>
            <p className="text-muted-foreground">
              Configure multi-location settings, regional assignments, and organization preferences.
            </p>

            <div className="grid md:grid-cols-2 gap-6 mt-6">
              <div className="space-y-4">
                <h4 className="font-medium">General</h4>
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-3 bg-muted/30 rounded-lg">
                    <span>Allow Cross-Store Orders</span>
                    <input type="checkbox" className="toggle" />
                  </div>
                  <div className="flex items-center justify-between p-3 bg-muted/30 rounded-lg">
                    <span>Unified Menu</span>
                    <input type="checkbox" className="toggle" />
                  </div>
                  <div className="flex items-center justify-between p-3 bg-muted/30 rounded-lg">
                    <span>Unified Rewards Program</span>
                    <input type="checkbox" defaultChecked className="toggle" />
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <h4 className="font-medium">Subscription</h4>
                <div className="p-4 bg-gradient-to-r from-blue-500/10 to-cyan-500/10 rounded-lg border border-blue-500/20">
                  <div className="flex items-center gap-3 mb-2">
                    <Crown className="h-5 w-5 text-yellow-500" />
                    <span className="font-semibold">Business Plan</span>
                  </div>
                  <p className="text-sm text-muted-foreground mb-3">Up to 5 locations included</p>
                  <div className="flex items-center justify-between">
                    <span className="text-2xl font-bold">$499<span className="text-sm font-normal text-muted-foreground">/mo</span></span>
                    <NeonButton size="sm" variant="outline">
                      Upgrade Plan
                    </NeonButton>
                  </div>
                </div>
              </div>
            </div>
          </GlassCard>
        </TabsContent>
      </Tabs>
    </div>
  );
};
