import { ShoppingCart, Trash2, Plus, Minus, Clock } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import { OptimizedImage } from "@/components/OptimizedImage";

interface CartItem {
  id: number;
  cartId: number;
  name: string;
  price: number;
  quantity: number;
  customizations?: string[]; // Human-readable: ["Cheese: Extra Cheese"]
  selectedOptions?: Record<string, string[]>; // Raw data: {"group_cheese": ["extra_cheese"]}
  image: string;
}

interface CartProps {
  items: CartItem[];
  onUpdateItems: (items: CartItem[]) => void;
  onCheckout: () => void;
  compact?: boolean;
}

export const Cart = ({ items, onUpdateItems, onCheckout, compact = false }: CartProps) => {
  const updateQuantity = (cartId: number, newQuantity: number) => {
    if (newQuantity === 0) {
      removeItem(cartId);
      return;
    }

    const updatedItems = items.map((item) =>
      item.cartId === cartId ? { ...item, quantity: newQuantity } : item
    );
    onUpdateItems(updatedItems);
  };

  const removeItem = (cartId: number) => {
    const updatedItems = items.filter((item) => item.cartId !== cartId);
    onUpdateItems(updatedItems);
  };

  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const tax = subtotal * 0.08; // 8% tax
  const total = subtotal + tax;

  const canCheckout = items.length > 0;

  return (
    <Card className="sticky top-24">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <ShoppingCart className="h-5 w-5" />
          Your Cart ({items.length})
        </CardTitle>
      </CardHeader>
      <CardContent>
        {items.length === 0 ? (
          <div className="text-center py-8">
            <ShoppingCart className="h-12 w-12 text-muted-foreground mx-auto mb-3" />
            <p className="text-muted-foreground">Your cart is empty</p>
            <p className="text-sm text-muted-foreground mt-1">
              Add items from the menu to get started
            </p>
          </div>
        ) : (
          <>
            {/* Cart Items */}
            <div className="space-y-4 mb-4 max-h-96 overflow-y-auto">
              {items.map((item) => (
                <div key={item.cartId} className="flex gap-3 pb-4 border-b last:border-0">
                  <OptimizedImage
                    src={item.image}
                    alt={item.name}
                    wrapperClassName="w-16 h-16 rounded flex-shrink-0"
                    className="w-full h-full object-cover rounded"
                  />
                  <div className="flex-1 min-w-0">
                    <h4 className="font-semibold text-sm mb-1 truncate">{item.name}</h4>
                    <p className="text-sm font-bold text-primary mb-2">
                      ${item.price.toFixed(2)}
                    </p>

                    {/* Quantity Controls */}
                    <div className="flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="icon"
                        className="h-7 w-7"
                        onClick={() => updateQuantity(item.cartId, item.quantity - 1)}
                        aria-label="Decrease quantity"
                      >
                        <Minus className="h-3 w-3" />
                      </Button>
                      <span className="w-8 text-center font-semibold">{item.quantity}</span>
                      <Button
                        variant="outline"
                        size="icon"
                        className="h-7 w-7"
                        onClick={() => updateQuantity(item.cartId, item.quantity + 1)}
                        aria-label="Increase quantity"
                      >
                        <Plus className="h-3 w-3" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-7 w-7 ml-auto text-destructive"
                        onClick={() => removeItem(item.cartId)}
                        aria-label="Remove item from cart"
                      >
                        <Trash2 className="h-3 w-3" />
                      </Button>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <Separator className="my-4" />

            {/* Pickup Time */}
            <div className="mb-4">
              <label className="text-sm font-semibold mb-2 block">Pickup Time</label>
              <select className="w-full border border-border rounded-md px-3 py-2 text-sm">
                <option value="asap">ASAP (15-20 min)</option>
                <option value="30">30 minutes</option>
                <option value="60">1 hour</option>
                <option value="90">1.5 hours</option>
                <option value="120">2 hours</option>
              </select>
            </div>

            <Separator className="my-4" />

            {/* Order Summary */}
            <div className="space-y-2 mb-4">
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Subtotal</span>
                <span className="font-semibold">${subtotal.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Tax (8%)</span>
                <span className="font-semibold">${tax.toFixed(2)}</span>
              </div>
              <Separator />
              <div className="flex justify-between text-lg font-bold">
                <span>Total</span>
                <span className="text-primary">${total.toFixed(2)}</span>
              </div>
            </div>

            {/* Checkout Button */}
            <Button
              size="lg"
              className="w-full bg-gradient-to-r from-[#FBBF24] to-[#F59E0B] hover:from-[#D97706] hover:to-[#B45309] text-white font-semibold shadow-md hover:shadow-lg transition-all"
              disabled={!canCheckout}
              onClick={onCheckout}
            >
              Proceed to Checkout
            </Button>

            <p className="text-xs text-center text-muted-foreground mt-3">
              <Clock className="h-3 w-3 inline mr-1" />
              Estimated ready time: 15-20 minutes
            </p>
          </>
        )}
      </CardContent>
    </Card>
  );
};
