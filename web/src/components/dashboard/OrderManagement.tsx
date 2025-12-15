import { useState, useEffect, useRef } from "react";
import { Separator } from "@/components/ui/separator";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlowingBadge } from "@/components/ui/GlowingBadge";
import { NeonButton } from "@/components/ui/NeonButton";
import { AnimatedCounter, AnimatedCurrency } from "@/components/ui/AnimatedCounter";
import { StatusPulse } from "@/components/ui/StatusPulse";
import {
  Clock,
  CheckCircle2,
  ChefHat,
  ShoppingBag,
  Phone,
  Mail,
  AlertCircle,
  DollarSign,
  TrendingUp,
  Users,
  Star,
  Flame,
  Search,
  Sparkles,
  Crown,
  RefreshCw,
  XCircle,
  Printer,
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { useRealtimeOrders } from "@/hooks/useRealtimeOrders";
import type { Order as SupabaseOrder } from "@/hooks/useRealtimeOrders";
import { cn } from "@/lib/utils";
import { autoPrintOrder, playNewOrderSound, printOrder, type PrintableOrder } from "@/utils/orderPrint";
import { locations } from "@/data/locations";

// Local order interface for component use
interface OrderItem {
  name: string;
  price: number;
  quantity: number;
  customizations?: string[];
}

interface Order {
  id: string;
  orderId: string;
  name: string;
  phone: string;
  email?: string;
  items: OrderItem[];
  total: number;
  status: "pending" | "preparing" | "ready" | "completed" | "cancelled";
  createdAt: string;
  estimatedReadyTime: string;
  specialInstructions?: string;
  priority?: "normal" | "express" | "vip";
  isRepeatCustomer?: boolean;
}

export const OrderManagement = () => {
  const { toast } = useToast();
  const { orders: supabaseOrders, loading, error, updateOrderStatus: updateSupabaseStatus } = useRealtimeOrders({ includeAll: true });

  const [filter, setFilter] = useState<"all" | "pending" | "preparing" | "ready" | "cancelled" | "completed">("pending");
  const [searchQuery, setSearchQuery] = useState("");
  const lastOrderCountRef = useRef(0);
  const [newOrderIds, setNewOrderIds] = useState<Set<string>>(new Set());

  // Map Supabase orders to component format
  const orders: Order[] = supabaseOrders.map((order: SupabaseOrder) => ({
    id: order.id,
    orderId: order.order_number || order.id,
    name: order.customer_name,
    phone: order.customer_phone,
    email: order.customer_email || undefined,
    items: order.order_items || [],
    total: order.total,
    status: order.status === 'confirmed' ? 'pending' : order.status as Order["status"],
    createdAt: order.created_at,
    estimatedReadyTime: order.estimated_ready_at || new Date(Date.now() + 20 * 60000).toISOString(),
    specialInstructions: order.special_instructions || undefined,
    priority: order.priority as Order["priority"],
    isRepeatCustomer: order.is_repeat_customer,
  }));

  // Convert order to printable format
  const toPrintableOrder = (order: Order, storeId?: number): PrintableOrder => {
    const store = storeId ? locations.find(l => l.id === storeId) : undefined;
    return {
      id: order.id,
      orderNumber: order.orderId.split("-")[1] || order.orderId,
      customerName: order.name,
      customerPhone: order.phone,
      customerEmail: order.email,
      items: order.items.map(item => ({
        name: item.item_name || item.name,
        quantity: item.quantity,
        price: item.item_price || item.price,
        customizations: item.customizations,
        notes: item.notes,
      })),
      subtotal: order.total * 0.92, // Approximate subtotal
      tax: order.total * 0.08, // Approximate tax
      total: order.total,
      specialInstructions: order.specialInstructions,
      createdAt: order.createdAt,
      storeName: store?.name,
    };
  };

  // Manual print handler
  const handlePrintOrder = (order: Order, storeId?: number) => {
    const printableOrder = toPrintableOrder(order, storeId);
    printOrder(printableOrder);
  };

  // Notify on new orders
  useEffect(() => {
    const currentCount = orders.length;
    if (currentCount > lastOrderCountRef.current && lastOrderCountRef.current > 0) {
      // Play loud notification sound
      playNewOrderSound();

      const latestOrder = orders[0];

      setNewOrderIds(prev => new Set(prev).add(latestOrder.id));

      if (latestOrder.status === 'pending') {
        setFilter('pending');
      }

      toast({
        title: "🔔 New Order Received!",
        description: `Order #${latestOrder.orderId.split("-")[1]} from ${latestOrder.name} - $${latestOrder.total.toFixed(2)}`,
        duration: 10000,
      });

      // Auto-print the new order
      const supabaseOrder = supabaseOrders.find(o => o.id === latestOrder.id);
      if (supabaseOrder) {
        const printableOrder = toPrintableOrder(latestOrder, supabaseOrder.store_id);
        autoPrintOrder(printableOrder);
      }

      setTimeout(() => {
        setNewOrderIds(prev => {
          const newSet = new Set(prev);
          newSet.delete(latestOrder.id);
          return newSet;
        });
      }, 10000);
    }
    lastOrderCountRef.current = currentCount;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [orders.length]);

  const updateOrderStatus = async (orderId: string, newStatus: Order["status"]) => {
    const supabaseStatus = newStatus === 'pending' ? 'confirmed' : newStatus;
    const result = await updateSupabaseStatus(orderId, supabaseStatus as 'pending' | 'confirmed' | 'preparing' | 'ready' | 'completed' | 'cancelled');

    if (result.success) {
      const statusMessages = {
        pending: "Order marked as pending",
        preparing: "Order is now being prepared",
        ready: "Order marked as ready for pickup",
        completed: "Order completed",
        cancelled: "Order has been cancelled",
      };

      toast({
        title: "Status Updated",
        description: statusMessages[newStatus],
      });

      if (newStatus === "ready") {
        playNewOrderSound();
      }
    } else {
      toast({
        title: "Error",
        description: result.error || "Failed to update order status",
        variant: "destructive",
      });
    }
  };

  const handleRejectOrder = (orderId: string) => {
    if (window.confirm("Are you sure you want to reject this order? This action cannot be undone.")) {
      updateOrderStatus(orderId, "cancelled");
    }
  };


  // Calculate statistics
  const stats = {
    totalRevenue: orders.reduce((sum, order) => sum + order.total, 0),
    activeOrders: orders.filter(o => o.status !== "completed" && o.status !== "cancelled").length,
    pendingCount: orders.filter(o => o.status === "pending").length,
    preparingCount: orders.filter(o => o.status === "preparing").length,
    readyCount: orders.filter(o => o.status === "ready").length,
    cancelledCount: orders.filter(o => o.status === "cancelled").length,
    completedCount: orders.filter(o => o.status === "completed").length,
  };

  // Filter orders
  const filteredOrders = orders.filter((order) => {
    const statusMatch = filter === "all" || order.status === filter;
    const searchLower = searchQuery.toLowerCase();
    const searchMatch = !searchQuery ||
      order.orderId.toLowerCase().includes(searchLower) ||
      order.name.toLowerCase().includes(searchLower) ||
      order.phone.includes(searchQuery) ||
      order.email?.toLowerCase().includes(searchLower);

    return statusMatch && searchMatch;
  });

  const getOrderAge = (createdAt: string) => {
    const minutes = Math.floor((Date.now() - new Date(createdAt).getTime()) / 60000);
    if (minutes < 1) return "Just now";
    if (minutes === 1) return "1 min ago";
    return `${minutes} mins ago`;
  };

  const isOrderLate = (createdAt: string, status: string) => {
    // Only show late indicator for pending orders (not yet being prepared)
    if (status !== 'pending') return false;
    const minutes = Math.floor((Date.now() - new Date(createdAt).getTime()) / 60000);
    return minutes > 15; // 15 minutes for pending orders
  };

  // Status badge variants
  const getStatusBadgeVariant = (status: string): "pending" | "preparing" | "ready" | "completed" | "danger" => {
    if (status === "cancelled") return "danger";
    return status as "pending" | "preparing" | "ready" | "completed";
  };

  const statusIcons: Record<string, typeof Clock> = {
    pending: Clock,
    preparing: ChefHat,
    ready: ShoppingBag,
    completed: CheckCircle2,
    cancelled: XCircle,
  };

  // Loading state
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <div className={cn(
            "h-12 w-12 rounded-full border-2 animate-spin mx-auto",
            "border-primary/30 border-t-primary"
          )} />
          <p className="mt-4 text-muted-foreground">Loading orders...</p>
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
          <h3 className="text-lg font-semibold mb-2">Failed to Load Orders</h3>
          <p className="text-muted-foreground mb-4">{error}</p>
          <NeonButton onClick={() => window.location.reload()}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Reload Page
          </NeonButton>
        </GlassCard>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Revenue Card */}
        <GlassCard glowColor="accent" gradient="green" className="p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Today's Revenue</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCurrency value={stats.totalRevenue} />
              </h3>
              <p className="text-xs text-accent dark:text-neon-green mt-1 flex items-center gap-1">
                <TrendingUp className="h-3 w-3" />
                +12% from yesterday
              </p>
            </div>
            <div className={cn(
              "h-12 w-12 rounded-2xl flex items-center justify-center",
              "bg-gradient-to-br from-ios-green/20 to-ios-teal/10 text-ios-green",
              "dark:from-neon-green/20 dark:to-neon-cyan/10 dark:text-neon-green",
              "shadow-[0_4px_15px_rgba(52,199,89,0.2)] dark:shadow-[0_4px_20px_rgba(0,255,136,0.3)]"
            )}>
              <DollarSign className="h-6 w-6" />
            </div>
          </div>
        </GlassCard>

        {/* Active Orders Card */}
        <GlassCard glowColor="cyan" gradient="blue" className="p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Active Orders</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={stats.activeOrders} />
              </h3>
              <p className="text-xs text-ios-blue dark:text-neon-cyan mt-1 flex items-center gap-1">
                <ShoppingBag className="h-3 w-3" />
                {stats.pendingCount} pending
              </p>
            </div>
            <div className={cn(
              "h-12 w-12 rounded-2xl flex items-center justify-center",
              "bg-gradient-to-br from-ios-blue/20 to-ios-teal/10 text-ios-blue",
              "dark:from-neon-cyan/20 dark:to-neon-blue/10 dark:text-neon-cyan",
              "shadow-[0_4px_15px_rgba(0,122,255,0.2)] dark:shadow-[0_4px_20px_rgba(0,255,255,0.3)]"
            )}>
              <ShoppingBag className="h-6 w-6" />
            </div>
          </div>
        </GlassCard>

        {/* Ready for Pickup Card */}
        <GlassCard glowColor="purple" gradient="purple" className="p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Ready for Pickup</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={stats.readyCount} />
              </h3>
              <p className="text-xs text-ios-purple dark:text-neon-purple mt-1 flex items-center gap-1">
                <Users className="h-3 w-3" />
                Awaiting customers
              </p>
            </div>
            <div className={cn(
              "h-12 w-12 rounded-2xl flex items-center justify-center",
              "bg-gradient-to-br from-ios-purple/20 to-ios-pink/10 text-ios-purple",
              "dark:from-neon-purple/20 dark:to-neon-pink/10 dark:text-neon-purple",
              "shadow-[0_4px_15px_rgba(175,82,222,0.2)] dark:shadow-[0_4px_20px_rgba(168,85,247,0.3)]"
            )}>
              <CheckCircle2 className="h-6 w-6" />
            </div>
          </div>
        </GlassCard>
      </div>

      {/* Header with Search */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-semibold text-foreground">Order Management</h2>
          <p className="text-muted-foreground mt-1">
            {filteredOrders.length} {filter === "all" ? "active" : filter} order{filteredOrders.length !== 1 ? "s" : ""}
          </p>
        </div>
        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-64">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search orders..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className={cn(
                "pl-10",
                "bg-secondary/50 border-border/50",
                "dark:bg-card/50 dark:border-primary/10",
                "focus:ring-2 focus:ring-primary/20"
              )}
            />
          </div>
          <NeonButton variant="secondary" onClick={() => window.location.reload()}>
            <RefreshCw className="h-4 w-4" />
          </NeonButton>
        </div>
      </div>

      {/* Filter Tabs */}
      <GlassCard className="p-1.5" gradient="blue" intensity="subtle">
        <Tabs value={filter} onValueChange={(v) => setFilter(v as typeof filter)}>
          <TabsList className="grid w-full grid-cols-6 bg-transparent h-auto">
            <TabsTrigger
              value="all"
              className={cn(
                "py-3 rounded-lg transition-all duration-200",
                "data-[state=active]:bg-secondary data-[state=active]:shadow-soft",
                "dark:data-[state=active]:bg-white/5 dark:data-[state=active]:shadow-glow-subtle"
              )}
            >
              <div className="flex items-center gap-2">
                <ShoppingBag className="h-4 w-4" />
                <span className="font-medium">All ({orders.length})</span>
              </div>
            </TabsTrigger>
            <TabsTrigger
              value="pending"
              className={cn(
                "py-3 rounded-lg transition-all duration-200 relative",
                "data-[state=active]:bg-ios-orange/10 data-[state=active]:text-ios-orange",
                "dark:data-[state=active]:bg-neon-orange/10 dark:data-[state=active]:text-neon-orange",
                "dark:data-[state=active]:shadow-[0_0_15px_hsla(24,100%,55%,0.3)]"
              )}
            >
              <div className="flex items-center gap-2">
                <Clock className="h-4 w-4" />
                <span className="font-medium">Pending ({stats.pendingCount})</span>
              </div>
              {newOrderIds.size > 0 && (
                <span className={cn(
                  "absolute -top-1 -right-1 h-5 w-5 text-xs font-bold rounded-full",
                  "flex items-center justify-center",
                  "bg-accent text-accent-foreground",
                  "dark:bg-neon-green dark:shadow-glow-accent"
                )}>
                  {newOrderIds.size}
                </span>
              )}
            </TabsTrigger>
            <TabsTrigger
              value="preparing"
              className={cn(
                "py-3 rounded-lg transition-all duration-200",
                "data-[state=active]:bg-primary/10 data-[state=active]:text-primary",
                "dark:data-[state=active]:shadow-glow-primary"
              )}
            >
              <div className="flex items-center gap-2">
                <ChefHat className="h-4 w-4" />
                <span className="font-medium">Preparing ({stats.preparingCount})</span>
              </div>
            </TabsTrigger>
            <TabsTrigger
              value="ready"
              className={cn(
                "py-3 rounded-lg transition-all duration-200",
                "data-[state=active]:bg-accent/10 data-[state=active]:text-accent",
                "dark:data-[state=active]:bg-neon-green/10 dark:data-[state=active]:text-neon-green",
                "dark:data-[state=active]:shadow-glow-accent"
              )}
            >
              <div className="flex items-center gap-2">
                <ShoppingBag className="h-4 w-4" />
                <span className="font-medium">Ready ({stats.readyCount})</span>
              </div>
            </TabsTrigger>
            <TabsTrigger
              value="completed"
              className={cn(
                "py-3 rounded-lg transition-all duration-200",
                "data-[state=active]:bg-gray-500/10 data-[state=active]:text-gray-500"
              )}
            >
              <div className="flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4" />
                <span className="font-medium">Done ({stats.completedCount})</span>
              </div>
            </TabsTrigger>
            <TabsTrigger
              value="cancelled"
              className={cn(
                "py-3 rounded-lg transition-all duration-200",
                "data-[state=active]:bg-destructive/10 data-[state=active]:text-destructive"
              )}
            >
              <div className="flex items-center gap-2">
                <XCircle className="h-4 w-4" />
                <span className="font-medium">Cancelled ({stats.cancelledCount})</span>
              </div>
            </TabsTrigger>
          </TabsList>
        </Tabs>
      </GlassCard>

      {/* Orders Grid */}
      {filteredOrders.length === 0 ? (
        <GlassCard className="py-12 text-center">
          <AlertCircle className="h-12 w-12 text-muted-foreground mx-auto mb-3 opacity-50" />
          <p className="text-lg font-medium mb-1">No {filter !== "all" ? filter : ""} orders</p>
          <p className="text-sm text-muted-foreground">
            New orders will appear here automatically
          </p>
        </GlassCard>
      ) : (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredOrders.map((order) => {
            const StatusIcon = statusIcons[order.status];
            const priority = order.priority || "normal";
            const isLate = isOrderLate(order.createdAt, order.status);
            const isNew = newOrderIds.has(order.id);

            return (
              <GlassCard
                key={order.orderId}
                hoverable
                glowColor={
                  isNew ? "accent" :
                  priority === "vip" ? "purple" :
                  priority === "express" ? "primary" :
                  "none"
                }
                className={cn(
                  "animate-fade-in flex flex-col h-[480px]",
                  isNew && "ring-2 ring-accent dark:ring-neon-green",
                  isLate && "ring-2 ring-amber-500 dark:ring-amber-400"
                )}
              >
                {/* Card Header */}
                <div className="p-4 pb-3">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1.5">
                        <h3 className="text-base font-semibold">
                          Order #{order.orderId.split("-")[1]}
                        </h3>
                        {isNew && (
                          <GlowingBadge variant="success" pulse size="sm">
                            <Sparkles className="h-3 w-3" />
                            NEW
                          </GlowingBadge>
                        )}
                        {order.isRepeatCustomer && (
                          <GlowingBadge variant="info" size="sm">
                            <Star className="h-3 w-3" />
                            Repeat
                          </GlowingBadge>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-sm text-muted-foreground">
                          {getOrderAge(order.createdAt)}
                        </span>
                        {isLate && (
                          <GlowingBadge variant="warning" pulse size="sm">
                            <AlertCircle className="h-3 w-3" />
                            WAITING
                          </GlowingBadge>
                        )}
                      </div>
                    </div>
                    <div className="flex flex-col gap-2 items-end">
                      <GlowingBadge
                        variant={getStatusBadgeVariant(order.status)}
                        pulse={order.status === "ready"}
                      >
                        <StatusIcon className="h-3 w-3" />
                        {order.status.toUpperCase()}
                      </GlowingBadge>
                      {priority === "vip" && (
                        <GlowingBadge variant="vip" pulse>
                          <Crown className="h-3 w-3" />
                          VIP
                        </GlowingBadge>
                      )}
                      {priority === "express" && (
                        <GlowingBadge variant="warning">
                          <Flame className="h-3 w-3" />
                          EXPRESS
                        </GlowingBadge>
                      )}
                    </div>
                  </div>
                </div>

                {/* Card Content - Scrollable middle section */}
                <div className="px-4 flex-1 overflow-y-auto">
                  {/* Customer Info */}
                  <div className="space-y-1.5">
                    <p className="font-medium text-sm">{order.name}</p>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <Phone className="h-3 w-3" />
                      {order.phone}
                    </div>
                    {order.email && (
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Mail className="h-3 w-3" />
                        {order.email}
                      </div>
                    )}
                  </div>

                  <Separator className="my-3 dark:bg-primary/10" />

                  {/* Order Items */}
                  <div className="space-y-2">
                    {order.items.map((item, idx) => (
                      <div key={idx} className="space-y-1">
                        <div className="flex justify-between text-sm">
                          <span className="text-muted-foreground">
                            {item.quantity}x {item.item_name}
                          </span>
                          <span className="font-medium">
                            ${item.subtotal ? item.subtotal.toFixed(2) : (item.item_price * item.quantity).toFixed(2)}
                          </span>
                        </div>
                        {/* Show customizations */}
                        {item.customizations && item.customizations.length > 0 && (
                          <div className="ml-4 text-xs text-muted-foreground space-y-0.5">
                            {item.customizations.map((custom: string, cIdx: number) => (
                              <div key={cIdx} className="flex items-center gap-1">
                                <span className="text-primary">•</span>
                                <span>{custom}</span>
                              </div>
                            ))}
                          </div>
                        )}
                        {/* Show item notes */}
                        {item.notes && (
                          <div className="ml-4 text-xs bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-200 px-2 py-1 rounded">
                            Note: {item.notes}
                          </div>
                        )}
                      </div>
                    ))}
                  </div>

                  {/* Special Instructions */}
                  {order.specialInstructions && (
                    <>
                      <Separator className="my-3 dark:bg-primary/10" />
                      <div className={cn(
                        "rounded-lg p-3",
                        "bg-ios-yellow/10 border border-ios-yellow/20",
                        "dark:bg-neon-orange/5 dark:border-neon-orange/20"
                      )}>
                        <div className="flex items-start gap-2">
                          <Sparkles className="h-4 w-4 text-ios-yellow dark:text-neon-orange mt-0.5 shrink-0" />
                          <div>
                            <p className="text-xs font-semibold text-ios-yellow dark:text-neon-orange mb-1">
                              Special Instructions
                            </p>
                            <p className="text-xs text-foreground/80">
                              {order.specialInstructions}
                            </p>
                          </div>
                        </div>
                      </div>
                    </>
                  )}
                </div>

                {/* Fixed Footer - Total & Buttons */}
                <div className="px-4 pb-4 pt-3 mt-auto border-t border-border/50 bg-muted/30">
                  {/* Total & Print */}
                  <div className="flex justify-between items-center font-semibold mb-3">
                    <span>Total</span>
                    <div className="flex items-center gap-2">
                      <span className="text-lg text-primary">${order.total.toFixed(2)}</span>
                      <button
                        onClick={() => {
                          const supabaseOrder = supabaseOrders.find(o => o.id === order.id);
                          handlePrintOrder(order, supabaseOrder?.store_id);
                        }}
                        className="p-2 rounded-lg bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 transition-colors"
                        title="Print Order"
                      >
                        <Printer className="h-4 w-4" />
                      </button>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="grid grid-cols-2 gap-2">
                    {order.status === "pending" && (
                      <>
                        <button
                          onClick={() => updateOrderStatus(order.id, "preparing")}
                          className="flex items-center justify-center gap-2 py-3 px-4 rounded-xl font-semibold text-white bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 transition-all duration-200 shadow-lg shadow-blue-500/30 hover:shadow-blue-500/50 hover:scale-[1.02] active:scale-[0.98]"
                        >
                          <CheckCircle2 className="h-5 w-5" />
                          Accept
                        </button>
                        <button
                          onClick={() => handleRejectOrder(order.id)}
                          className="flex items-center justify-center gap-2 py-3 px-4 rounded-xl font-semibold text-white bg-gradient-to-r from-red-500 to-red-600 hover:from-red-600 hover:to-red-700 transition-all duration-200 shadow-lg shadow-red-500/30 hover:shadow-red-500/50 hover:scale-[1.02] active:scale-[0.98]"
                        >
                          <XCircle className="h-5 w-5" />
                          Reject
                        </button>
                      </>
                    )}

                    {order.status === "preparing" && (
                      <button
                        onClick={() => updateOrderStatus(order.id, "ready")}
                        className="col-span-2 flex items-center justify-center gap-2 py-3 px-4 rounded-xl font-semibold text-white bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 transition-all duration-200 shadow-lg shadow-green-500/30 hover:shadow-green-500/50 hover:scale-[1.02] active:scale-[0.98]"
                      >
                        <ShoppingBag className="h-5 w-5" />
                        Mark as Ready
                      </button>
                    )}

                    {order.status === "ready" && (
                      <button
                        onClick={() => updateOrderStatus(order.id, "completed")}
                        className="col-span-2 flex items-center justify-center gap-2 py-3 px-4 rounded-xl font-semibold text-white bg-gradient-to-r from-blue-500 to-cyan-500 hover:from-blue-600 hover:to-cyan-600 transition-all duration-200 shadow-lg shadow-blue-500/30 hover:shadow-blue-500/50 hover:scale-[1.02] active:scale-[0.98]"
                      >
                        <CheckCircle2 className="h-5 w-5" />
                        Complete Order
                      </button>
                    )}
                  </div>
                </div>
              </GlassCard>
            );
          })}
        </div>
      )}
    </div>
  );
};
