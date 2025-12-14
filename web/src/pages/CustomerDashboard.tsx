import { useState, useEffect } from "react";
import { Navigate, Link, useNavigate } from "react-router-dom";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Separator } from "@/components/ui/separator";
import { PointsBalance } from "@/components/rewards/PointsBalance";
import { RewardsHistory } from "@/components/rewards/RewardsHistory";
import { useRewards, convertTransactionsForDisplay } from "@/hooks/useRewards";
import { POINTS_TO_DOLLAR, calculateTier } from "@/types/rewards";
import { useAuth } from "@/contexts/AuthContext";
import {
  ShoppingBag,
  Heart,
  Gift,
  User,
  Clock,
  MapPin,
  Star,
  LogOut,
} from "lucide-react";

interface Order {
  orderId: string;
  createdAt: string;
  total: number;
  status: string;
  items: any[];
}

const CustomerDashboard = () => {
  const navigate = useNavigate();
  const { user, profile, isCustomer, signOut, loading } = useAuth();

  // Use Supabase-backed rewards hook
  const { rewards: dbRewards, transactions: dbTransactions, loading: rewardsLoading, refresh: refreshRewards, lifetimePoints } = useRewards();

  // SECURITY: Only trust Supabase auth state - never localStorage
  // localStorage fallback removed due to auth bypass vulnerability (CVE-2025-KB001)
  const isLoggedIn = !!user && isCustomer;
  const userRole = isCustomer ? "customer" : null;
  const userName = profile?.full_name || "Customer";

  const [orders, setOrders] = useState<Order[]>([]);
  const [activeTab, setActiveTab] = useState("orders");

  // Convert DB rewards to display format
  const rewards = dbRewards ? {
    userId: dbRewards.customer_id,
    points: dbRewards.points,
    lifetimePoints: lifetimePoints,
    tier: calculateTier(lifetimePoints),
    transactions: convertTransactionsForDisplay(dbTransactions),
  } : {
    userId: user?.id || "guest",
    points: 0,
    lifetimePoints: 0,
    tier: "bronze" as const,
    transactions: [],
  };

  useEffect(() => {
    loadOrders();
  }, []);

  const loadOrders = () => {
    const allOrders: Order[] = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key?.startsWith("order_")) {
        const orderData = localStorage.getItem(key);
        if (orderData) {
          allOrders.push(JSON.parse(orderData));
        }
      }
    }
    allOrders.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    setOrders(allOrders);
  };

  const handleReorder = (order: Order) => {
    // Store the order items in localStorage as cart items
    try {
      localStorage.setItem("cartItems", JSON.stringify(order.items));
      // Navigate to order page
      navigate("/order");
    } catch (error) {
      console.error("Failed to reorder:", error);
    }
  };

  const handleLogout = async () => {
    // Clear localStorage legacy auth
    localStorage.removeItem("dashboardAuth");
    localStorage.removeItem("userRole");
    localStorage.removeItem("userName");
    localStorage.removeItem("storeName");
    localStorage.removeItem("userPermissions");

    // Sign out from Supabase if authenticated
    try {
      await signOut();
    } catch (error) {
      console.error("Sign out error:", error);
    }

    window.location.href = "/";
  };

  // Wait for auth to finish loading before checking
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#FF8C42]"></div>
      </div>
    );
  }

  // Redirect if not logged in as customer
  if (!isLoggedIn || userRole !== "customer") {
    return <Navigate to="/signin" replace />;
  }

  const favoriteItems = [
    { id: 1, name: "Classic Cheeseburger", price: 8.99, orders: 12 },
    { id: 2, name: "Turkey Club", price: 9.49, orders: 8 },
    { id: 3, name: "Philly Cheesesteak", price: 10.99, orders: 6 },
  ];

  const pointsValue = rewards.points * POINTS_TO_DOLLAR;

  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      <main className="pt-20 pb-16">
        <div className="container mx-auto px-4">
          {/* Welcome Header */}
          <div className="mb-8">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-3xl font-bold mb-2">Welcome back, {userName}!</h1>
                <p className="text-muted-foreground">Manage your orders and rewards</p>
              </div>
              <Button
                variant="outline"
                onClick={handleLogout}
                className="border-[#FF8C42] text-[#FF8C42] hover:bg-[#FF8C42] hover:text-white transition-colors"
              >
                <LogOut className="h-4 w-4 mr-2" />
                Logout
              </Button>
            </div>
          </div>

          {/* Stats Cards */}
          <div className="grid md:grid-cols-3 gap-4 mb-8">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <p className="text-sm font-medium text-muted-foreground">Total Orders</p>
                <ShoppingBag className="h-4 w-4 text-[#FF8C42]" />
              </CardHeader>
              <CardContent>
                <p className="text-2xl font-bold">{orders.length}</p>
                <p className="text-xs text-muted-foreground mt-1">All time</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <p className="text-sm font-medium text-muted-foreground">Rewards Points</p>
                <Gift className="h-4 w-4 text-[#FF8C42]" />
              </CardHeader>
              <CardContent>
                <p className="text-2xl font-bold text-[#FF8C42]">{rewards.points.toLocaleString()}</p>
                <p className="text-xs text-muted-foreground mt-1">
                  ${pointsValue.toFixed(2)} cash value
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <p className="text-sm font-medium text-muted-foreground">Favorites</p>
                <Heart className="h-4 w-4 text-red-500" />
              </CardHeader>
              <CardContent>
                <p className="text-2xl font-bold">{favoriteItems.length}</p>
                <p className="text-xs text-muted-foreground mt-1">Saved items</p>
              </CardContent>
            </Card>
          </div>

          {/* Tabs */}
          <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="orders">Order History</TabsTrigger>
              <TabsTrigger value="favorites">Favorites</TabsTrigger>
              <TabsTrigger value="rewards">Rewards</TabsTrigger>
            </TabsList>

            {/* Order History */}
            <TabsContent value="orders" className="mt-0">
              <Card>
                <CardHeader>
                  <CardTitle>Order History</CardTitle>
                </CardHeader>
                <CardContent>
                  {orders.length === 0 ? (
                    <div className="text-center py-12">
                      <ShoppingBag className="h-12 w-12 text-muted-foreground mx-auto mb-3" />
                      <p className="text-lg font-semibold mb-1">No orders yet</p>
                      <p className="text-sm text-muted-foreground mb-4">
                        Start ordering to see your history here
                      </p>
                      <Link to="/order">
                        <Button className="bg-[#FF8C42] hover:bg-[#F57C00] text-white">Order Now</Button>
                      </Link>
                    </div>
                  ) : (
                    <div className="space-y-4">
                      {orders.map((order) => (
                        <div
                          key={order.orderId}
                          className="border rounded-lg p-4 hover:shadow-md transition-all"
                        >
                          <div className="flex items-start justify-between mb-3">
                            <div>
                              <p className="font-semibold">
                                Order #{order.orderId.split("-")[1]}
                              </p>
                              <p className="text-sm text-muted-foreground">
                                {new Date(order.createdAt).toLocaleDateString()} at{" "}
                                {new Date(order.createdAt).toLocaleTimeString()}
                              </p>
                            </div>
                            <Badge
                              variant={
                                order.status === "completed"
                                  ? "default"
                                  : order.status === "ready"
                                  ? "default"
                                  : "secondary"
                              }
                              className={
                                order.status === "completed"
                                  ? "bg-gray-500"
                                  : order.status === "ready"
                                  ? "bg-accent"
                                  : ""
                              }
                            >
                              {order.status}
                            </Badge>
                          </div>

                          <Separator className="my-3" />

                          <div className="space-y-2">
                            {order.items.map((item: any, idx: number) => (
                              <div key={idx} className="flex justify-between text-sm">
                                <span>
                                  {item.quantity}x {item.name}
                                </span>
                                <span className="font-semibold">
                                  ${(item.price * item.quantity).toFixed(2)}
                                </span>
                              </div>
                            ))}
                          </div>

                          <Separator className="my-3" />

                          <div className="flex items-center justify-between">
                            <span className="font-bold">Total: ${order.total.toFixed(2)}</span>
                            <div className="flex gap-2">
                              <Link to={`/order/tracking/${order.orderId}`}>
                                <Button
                                  variant="outline"
                                  size="sm"
                                  className="border-[#FF8C42] text-[#FF8C42] hover:bg-[#FF8C42] hover:text-white"
                                >
                                  Track Order
                                </Button>
                              </Link>
                              <Button
                                size="sm"
                                onClick={() => handleReorder(order)}
                                className="bg-[#FF8C42] hover:bg-[#F57C00] text-white"
                              >
                                Reorder
                              </Button>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            {/* Favorites */}
            <TabsContent value="favorites" className="mt-0">
              <Card>
                <CardHeader>
                  <CardTitle>Your Favorites</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {favoriteItems.map((item) => (
                      <div
                        key={item.id}
                        className="flex items-center justify-between border rounded-lg p-4"
                      >
                        <div className="flex items-center gap-3">
                          <Heart className="h-5 w-5 text-red-500 fill-red-500" />
                          <div>
                            <p className="font-semibold">{item.name}</p>
                            <p className="text-sm text-muted-foreground">
                              Ordered {item.orders} times
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="text-lg font-bold text-[#FF8C42]">
                            ${item.price.toFixed(2)}
                          </span>
                          <Link to="/order">
                            <Button size="sm" className="bg-[#FF8C42] hover:bg-[#F57C00] text-white">
                              Order Again
                            </Button>
                          </Link>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Rewards */}
            <TabsContent value="rewards" className="mt-0">
              <div className="grid gap-6">
                <PointsBalance rewards={rewards} />
                <RewardsHistory transactions={rewards.transactions} />
              </div>
            </TabsContent>
          </Tabs>
        </div>
      </main>

      <Footer />
    </div>
  );
};

export default CustomerDashboard;
