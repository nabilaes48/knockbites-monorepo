import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import { BarChart3, Users, Building2, ShoppingBag, DollarSign } from "lucide-react";

export function SystemAnalytics() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalStores: 29,
    totalOrders: 0,
    totalRevenue: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      // Count users
      const { count: userCount } = await supabase
        .from("staff_profiles")
        .select("*", { count: "exact", head: true });

      // Count orders
      const { count: orderCount } = await supabase
        .from("orders")
        .select("*", { count: "exact", head: true });

      // Calculate total revenue
      const { data: orders } = await supabase
        .from("orders")
        .select("total")
        .eq("status", "completed");

      const revenue = orders?.reduce((sum, order) => sum + (order.total || 0), 0) || 0;

      setStats({
        totalUsers: userCount || 0,
        totalStores: 29,
        totalOrders: orderCount || 0,
        totalRevenue: revenue,
      });
    } catch (error) {
      console.error("Error fetching stats:", error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="bg-gray-800/50 border border-gray-700 rounded-lg p-8">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-500 mx-auto"></div>
          <p className="mt-4 text-gray-300">Loading analytics...</p>
        </div>
      </div>
    );
  }

  const statCards = [
    {
      label: "Total Users",
      value: stats.totalUsers,
      icon: Users,
      color: "from-blue-500 to-blue-600",
    },
    {
      label: "Total Stores",
      value: stats.totalStores,
      icon: Building2,
      color: "from-green-500 to-green-600",
    },
    {
      label: "Total Orders",
      value: stats.totalOrders,
      icon: ShoppingBag,
      color: "from-purple-500 to-purple-600",
    },
    {
      label: "Total Revenue",
      value: `$${stats.totalRevenue.toFixed(2)}`,
      icon: DollarSign,
      color: "from-pink-500 to-pink-600",
    },
  ];

  return (
    <div className="space-y-4">
      <div className="bg-gray-800/50 border border-gray-700 rounded-lg p-6">
        <h2 className="text-2xl font-bold text-white flex items-center gap-2">
          <BarChart3 className="h-6 w-6 text-purple-400" />
          System Analytics
        </h2>
        <p className="text-gray-400 mt-1">Overview of all stores and system-wide metrics</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((stat) => {
          const Icon = stat.icon;
          return (
            <div
              key={stat.label}
              className="bg-gray-800/50 border border-gray-700 rounded-lg p-6 hover:border-purple-500/50 transition-colors"
            >
              <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${stat.color} flex items-center justify-center mb-4`}>
                <Icon className="h-6 w-6 text-white" />
              </div>
              <p className="text-sm text-gray-400 mb-1">{stat.label}</p>
              <p className="text-3xl font-bold text-white">{stat.value}</p>
            </div>
          );
        })}
      </div>

      <div className="bg-gray-800/50 border border-gray-700 rounded-lg p-6">
        <h3 className="text-lg font-bold text-white mb-4">Coming Soon</h3>
        <p className="text-gray-400">
          Advanced analytics including revenue charts, user activity graphs, and store performance comparisons will be available here.
        </p>
      </div>
    </div>
  );
}
