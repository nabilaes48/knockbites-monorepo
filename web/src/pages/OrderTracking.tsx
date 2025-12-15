import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import {
  CheckCircle2,
  Clock,
  MapPin,
  Phone,
  Mail,
  Package,
  ChefHat,
  ShoppingBag,
  Loader2,
} from "lucide-react";
import { supabase } from "@/lib/supabase";
import { locations } from "@/data/locations";

interface OrderItem {
  id: number;
  item_name: string;
  item_price: number;
  quantity: number;
  customizations: string[];
  subtotal: number;
}

interface OrderData {
  id: string;
  order_number: string;
  customer_name: string;
  customer_phone: string;
  customer_email: string | null;
  store_id: number;
  status: "pending" | "confirmed" | "preparing" | "ready" | "completed" | "cancelled";
  subtotal: number;
  tax: number;
  total: number;
  estimated_ready_at: string | null;
  special_instructions: string | null;
  created_at: string;
  order_items: OrderItem[];
}

const statusSteps = [
  { id: "pending", label: "Order Received", icon: CheckCircle2, color: "text-blue-500" },
  { id: "confirmed", label: "Confirmed", icon: CheckCircle2, color: "text-green-500" },
  { id: "preparing", label: "Being Prepared", icon: ChefHat, color: "text-orange-500" },
  { id: "ready", label: "Ready for Pickup", icon: ShoppingBag, color: "text-purple-500" },
  { id: "completed", label: "Completed", icon: Package, color: "text-accent" },
];

const OrderTracking = () => {
  const { orderId } = useParams<{ orderId: string }>();
  const [orderData, setOrderData] = useState<OrderData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!orderId) {
      setError("Order ID not provided");
      setLoading(false);
      return;
    }

    // Fetch order from Supabase - works for both authenticated and anonymous users
    const fetchOrder = async () => {
      try {
        // Query orders table directly (RLS policies allow public to view orders)
        const { data: orderData, error: fetchError } = await supabase
          .from('orders')
          .select(`
            *,
            order_items (*)
          `)
          .eq('id', orderId)
          .single();

        if (fetchError) {
          console.error('Error fetching order:', fetchError);
          setError("Order not found");
          setLoading(false);
          return;
        }

        if (!orderData) {
          setError("Order not found");
          setLoading(false);
          return;
        }

        setOrderData(orderData as OrderData);
        setLoading(false);
      } catch (err) {
        console.error('Error:', err);
        setError("Failed to load order");
        setLoading(false);
      }
    };

    fetchOrder();

    // Subscribe to real-time order updates
    const channel = supabase
      .channel(`order-tracking-${orderId}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'orders',
          filter: `id=eq.${orderId}`,
        },
        async (payload) => {
          console.log('Order updated:', payload);
          // Refetch order with items
          const { data: updatedOrder } = await supabase
            .from('orders')
            .select(`
              *,
              order_items (*)
            `)
            .eq('id', payload.new.id)
            .single();

          if (updatedOrder) {
            setOrderData(updatedOrder as OrderData);
          }
        }
      )
      .subscribe();

    // Auto-refresh fallback every 15 seconds (in case realtime fails)
    const refreshInterval = setInterval(() => {
      fetchOrder();
    }, 15000);

    return () => {
      supabase.removeChannel(channel);
      clearInterval(refreshInterval);
    };
  }, [orderId]);

  if (loading) {
    return (
      <div className="min-h-screen bg-background">
        <Navbar />
        <main className="pt-20 pb-16">
          <div className="container mx-auto px-4">
            <Card className="max-w-md mx-auto">
              <CardContent className="py-12 text-center">
                <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4 text-primary" />
                <p className="text-muted-foreground">Loading order...</p>
              </CardContent>
            </Card>
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  if (error || !orderData) {
    return (
      <div className="min-h-screen bg-background">
        <Navbar />
        <main className="pt-20 pb-16">
          <div className="container mx-auto px-4">
            <Card className="max-w-md mx-auto">
              <CardContent className="py-12 text-center">
                <p className="text-muted-foreground mb-4">{error || "Order not found"}</p>
                <Link to="/order">
                  <Button variant="outline">
                    Place New Order
                  </Button>
                </Link>
              </CardContent>
            </Card>
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  // Map "confirmed" to "pending" for display
  const displayStatus = orderData.status === 'confirmed' ? 'pending' : orderData.status;
  const currentStepIndex = statusSteps.findIndex((step) => step.id === displayStatus);

  const estimatedTime = orderData.estimated_ready_at
    ? new Date(orderData.estimated_ready_at)
    : new Date(Date.now() + 20 * 60000);
  const minutesUntilReady = Math.max(
    0,
    Math.floor((estimatedTime.getTime() - Date.now()) / 60000)
  );

  // Get store information
  const store = locations.find(loc => loc.id === orderData.store_id);

  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      <main className="pt-20 pb-16">
        <div className="container mx-auto px-4 max-w-4xl">
          {/* Success Header - Personalized with customer's first name */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-accent/20 mb-4">
              <CheckCircle2 className="h-8 w-8 text-accent" />
            </div>
            <h1 className="text-3xl md:text-4xl font-bold mb-2">
              Thank you, {orderData.customer_name.split(' ')[0]}!
            </h1>
            <p className="text-lg text-muted-foreground">
              Order #{orderData.order_number || orderData.id.split('-')[0].toUpperCase()} is confirmed
            </p>
            <p className="text-sm text-muted-foreground mt-1">
              We're preparing your order with care
            </p>
          </div>

          {/* Order Status Timeline */}
          <Card className="mb-6">
            <CardHeader>
              <CardTitle>Order Status</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="relative">
                {/* Progress Line */}
                <div className="absolute left-6 top-0 bottom-0 w-0.5 bg-border" />
                <div
                  className="absolute left-6 top-0 w-0.5 bg-accent transition-all duration-500"
                  style={{
                    height: `${(currentStepIndex / (statusSteps.length - 1)) * 100}%`,
                  }}
                />

                {/* Status Steps */}
                <div className="space-y-8">
                  {statusSteps.map((step, index) => {
                    const isCompleted = index <= currentStepIndex;
                    const isCurrent = index === currentStepIndex;
                    const StepIcon = step.icon;

                    return (
                      <div key={step.id} className="relative flex items-center gap-4">
                        <div
                          className={`relative z-10 w-12 h-12 rounded-full flex items-center justify-center ${
                            isCompleted
                              ? "bg-accent text-white"
                              : "bg-muted text-muted-foreground"
                          } transition-all`}
                        >
                          <StepIcon className="h-6 w-6" />
                        </div>
                        <div className="flex-1">
                          <p
                            className={`font-semibold ${
                              isCompleted ? "text-foreground" : "text-muted-foreground"
                            }`}
                          >
                            {step.label}
                          </p>
                          {isCurrent && (
                            <p className="text-sm text-muted-foreground">In progress...</p>
                          )}
                        </div>
                        {isCurrent && (
                          <Badge variant="default" className="bg-accent">
                            Current
                          </Badge>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>

              {orderData.status !== "completed" && orderData.status !== "cancelled" && (
                <div className="mt-6 p-4 bg-accent/10 border border-accent rounded-lg">
                  <div className="flex items-center gap-2 text-accent font-semibold">
                    <Clock className="h-5 w-5" />
                    <span>
                      {minutesUntilReady > 0
                        ? `Ready in approximately ${minutesUntilReady} minutes`
                        : "Your order is ready for pickup!"}
                    </span>
                  </div>
                </div>
              )}

              {orderData.status === "cancelled" && (
                <div className="mt-6 p-4 bg-destructive/10 border border-destructive rounded-lg">
                  <p className="text-destructive font-semibold">This order has been cancelled</p>
                </div>
              )}
            </CardContent>
          </Card>

          <div className="grid md:grid-cols-2 gap-6">
            {/* Order Details */}
            <Card>
              <CardHeader>
                <CardTitle>Order Details</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-3">
                  {orderData.order_items && orderData.order_items.length > 0 ? (
                    orderData.order_items.map((item) => (
                      <div key={item.id} className="space-y-1">
                        <div className="flex justify-between text-sm">
                          <span>
                            {item.quantity}x {item.item_name}
                          </span>
                          <span className="font-semibold">
                            ${item.subtotal.toFixed(2)}
                          </span>
                        </div>
                        {item.customizations && item.customizations.length > 0 && (
                          <p className="text-xs text-muted-foreground ml-4">
                            {item.customizations.join(', ')}
                          </p>
                        )}
                      </div>
                    ))
                  ) : (
                    <p className="text-sm text-muted-foreground">No items</p>
                  )}
                </div>

                <Separator />

                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Subtotal</span>
                    <span className="font-semibold">${orderData.subtotal.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Tax</span>
                    <span className="font-semibold">${orderData.tax.toFixed(2)}</span>
                  </div>
                  <Separator />
                  <div className="flex justify-between text-lg font-bold">
                    <span>Total</span>
                    <span className="text-primary">${orderData.total.toFixed(2)}</span>
                  </div>
                </div>

                {orderData.special_instructions && (
                  <>
                    <Separator />
                    <div>
                      <p className="text-sm font-semibold mb-1">Special Instructions</p>
                      <p className="text-sm text-muted-foreground">
                        {orderData.special_instructions}
                      </p>
                    </div>
                  </>
                )}
              </CardContent>
            </Card>

            {/* Customer & Pickup Info */}
            <Card>
              <CardHeader>
                <CardTitle>Pickup Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <p className="text-sm font-semibold mb-2">Customer</p>
                  <div className="space-y-2 text-sm">
                    <p className="font-medium">{orderData.customer_name}</p>
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Phone className="h-4 w-4" />
                      {orderData.customer_phone}
                    </div>
                    {orderData.customer_email && (
                      <div className="flex items-center gap-2 text-muted-foreground">
                        <Mail className="h-4 w-4" />
                        {orderData.customer_email}
                      </div>
                    )}
                  </div>
                </div>

                <Separator />

                <div>
                  <p className="text-sm font-semibold mb-2">Pickup Location</p>
                  {store ? (
                    <div className="flex items-start gap-2 text-sm text-muted-foreground">
                      <MapPin className="h-4 w-4 mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="font-medium text-foreground">{store.name}</p>
                        <p>{store.address}</p>
                        <p>{store.city}, {store.state} {store.zip}</p>
                        <p className="mt-1">{store.phone}</p>
                      </div>
                    </div>
                  ) : (
                    <p className="text-sm text-muted-foreground">Store #{orderData.store_id}</p>
                  )}
                </div>

                <Separator />

                <div>
                  <p className="text-sm font-semibold mb-2">Payment</p>
                  <Badge variant="outline">Pay at Store</Badge>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Actions */}
          <div className="mt-6 flex flex-col sm:flex-row gap-4 justify-center">
            <Link to="/order">
              <Button variant="outline" size="lg">
                Order Again
              </Button>
            </Link>
            <Link to="/">
              <Button variant="secondary" size="lg">
                Back to Home
              </Button>
            </Link>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
};

export default OrderTracking;
