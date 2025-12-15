import { useState } from "react";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { StoreSelection } from "@/components/order/StoreSelection";
import { MenuBrowse } from "@/components/order/MenuBrowse";
import { Checkout } from "@/components/order/Checkout";
import { ShoppingCart, ChevronUp, Minus, Plus, Trash2, MapPin } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger, SheetDescription } from "@/components/ui/sheet";
import { useAuth } from "@/contexts/AuthContext";

export type OrderStep = "store" | "menu" | "checkout";

const Order = () => {
  const { user, profile, isCustomer } = useAuth();
  const [currentStep, setCurrentStep] = useState<OrderStep>("store");
  const [selectedStore, setSelectedStore] = useState<number | null>(null);
  const [selectedStoreName, setSelectedStoreName] = useState<string>("");
  const [cartItems, setCartItems] = useState<any[]>([]);
  const [isCartOpen, setIsCartOpen] = useState(false);

  // Get user's first name for personalization
  const firstName = profile?.full_name?.split(' ')[0] || '';
  const isLoggedIn = user && profile;

  const cartItemCount = cartItems.reduce((sum, item) => sum + (item.quantity || 1), 0);
  const subtotal = cartItems.reduce((sum, item) => sum + item.price * (item.quantity || 1), 0);
  const tax = subtotal * 0.08;
  const total = subtotal + tax;

  const handleStoreSelect = (storeId: number, storeName?: string) => {
    setSelectedStore(storeId);
    setSelectedStoreName(storeName || `Store #${storeId}`);
    setCurrentStep("menu");
  };

  const handleAddToCart = (item: any) => {
    setCartItems([...cartItems, item]);
  };

  const updateQuantity = (cartId: number, newQuantity: number) => {
    if (newQuantity === 0) {
      setCartItems(cartItems.filter((item) => item.cartId !== cartId));
      return;
    }
    setCartItems(cartItems.map((item) =>
      item.cartId === cartId ? { ...item, quantity: newQuantity } : item
    ));
  };

  const removeItem = (cartId: number) => {
    setCartItems(cartItems.filter((item) => item.cartId !== cartId));
  };

  // Get time-based greeting
  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <Navbar />

      <main className="flex-1 pt-16">
        {/* Store Selection */}
        {currentStep === "store" && (
          <div className="container mx-auto px-4 py-6">
            {/* Personalized Welcome */}
            {isLoggedIn && firstName && (
              <div className="max-w-4xl mx-auto mb-6 text-center">
                <h1 className="text-3xl font-bold mb-2">
                  {getGreeting()}, {firstName}! 👋
                </h1>
                <p className="text-muted-foreground">
                  Where would you like to pick up your order today?
                </p>
              </div>
            )}
            <StoreSelection onSelectStore={handleStoreSelect} />
          </div>
        )}

        {/* Menu Browse */}
        {currentStep === "menu" && selectedStore && (
          <div className="container mx-auto px-4 py-6 pb-32">
            {/* Personalized Header */}
            <div className="max-w-4xl mx-auto mb-6">
              {isLoggedIn && firstName ? (
                <div className="text-center mb-4">
                  <h1 className="text-2xl font-bold mb-1">
                    What are you craving today, {firstName}?
                  </h1>
                  <p className="text-muted-foreground flex items-center justify-center gap-1">
                    <MapPin className="h-4 w-4" />
                    Ordering from {selectedStoreName}
                  </p>
                </div>
              ) : (
                <div className="text-center mb-4">
                  <h1 className="text-2xl font-bold mb-1">Browse Our Menu</h1>
                  <p className="text-muted-foreground flex items-center justify-center gap-1">
                    <MapPin className="h-4 w-4" />
                    Ordering from {selectedStoreName}
                  </p>
                </div>
              )}
            </div>
            <MenuBrowse onAddToCart={handleAddToCart} />
          </div>
        )}

        {/* Checkout */}
        {currentStep === "checkout" && (
          <div className="container mx-auto px-4 py-6">
            <Checkout items={cartItems} storeId={selectedStore} storeName={selectedStoreName} />
          </div>
        )}
      </main>

      {/* Bottom Cart Bar - Only show on menu step */}
      {currentStep === "menu" && (
        <Sheet open={isCartOpen} onOpenChange={setIsCartOpen}>
          <div className="fixed bottom-0 left-0 right-0 bg-background border-t shadow-lg z-50">
            <SheetTrigger asChild>
              <button className="w-full p-4 flex items-center justify-between hover:bg-muted/50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="relative">
                    <ShoppingCart className="h-6 w-6" />
                    {cartItemCount > 0 && (
                      <span className="absolute -top-2 -right-2 bg-primary text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center">
                        {cartItemCount}
                      </span>
                    )}
                  </div>
                  <span className="font-medium">
                    {cartItemCount === 0
                      ? (isLoggedIn && firstName ? `${firstName}, your cart is empty` : "Your cart is empty")
                      : `${cartItemCount} item${cartItemCount > 1 ? 's' : ''} in cart`
                    }
                  </span>
                </div>
                <div className="flex items-center gap-3">
                  {cartItemCount > 0 && (
                    <span className="font-bold text-lg">${total.toFixed(2)}</span>
                  )}
                  <ChevronUp className="h-5 w-5 text-muted-foreground" />
                </div>
              </button>
            </SheetTrigger>
          </div>

          <SheetContent side="bottom" className="h-[80vh] rounded-t-xl">
            <SheetHeader>
              <SheetTitle className="flex items-center gap-2">
                <ShoppingCart className="h-5 w-5" />
                {isLoggedIn && firstName ? `${firstName}'s Cart` : "Your Cart"} ({cartItemCount})
              </SheetTitle>
              <SheetDescription>
                {cartItemCount > 0
                  ? "Looking great! Ready to checkout?"
                  : "Add some delicious items from our menu"
                }
              </SheetDescription>
            </SheetHeader>

            <div className="mt-4 flex flex-col h-[calc(100%-80px)]">
              {cartItems.length === 0 ? (
                <div className="flex-1 flex flex-col items-center justify-center text-muted-foreground">
                  <ShoppingCart className="h-16 w-16 mb-4 opacity-50" />
                  <p className="text-lg">Your cart is empty</p>
                  <p className="text-sm">
                    {isLoggedIn && firstName
                      ? `${firstName}, add some items from the menu to get started!`
                      : "Add items from the menu to get started"
                    }
                  </p>
                </div>
              ) : (
                <>
                  {/* Cart Items */}
                  <div className="flex-1 overflow-y-auto space-y-3 pr-2">
                    {cartItems.map((item) => (
                      <div key={item.cartId} className="flex items-center gap-3 p-3 bg-muted/30 rounded-lg">
                        <div className="flex-1">
                          <h4 className="font-semibold">{item.name}</h4>
                          <p className="text-sm text-primary font-medium">${item.price.toFixed(2)}</p>
                        </div>
                        <div className="flex items-center gap-2">
                          <Button
                            variant="outline"
                            size="icon"
                            className="h-8 w-8"
                            onClick={() => updateQuantity(item.cartId, (item.quantity || 1) - 1)}
                          >
                            <Minus className="h-3 w-3" />
                          </Button>
                          <span className="w-8 text-center font-semibold">{item.quantity || 1}</span>
                          <Button
                            variant="outline"
                            size="icon"
                            className="h-8 w-8"
                            onClick={() => updateQuantity(item.cartId, (item.quantity || 1) + 1)}
                          >
                            <Plus className="h-3 w-3" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 text-destructive"
                            onClick={() => removeItem(item.cartId)}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>

                  {/* Cart Summary */}
                  <div className="border-t pt-4 mt-4 space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-muted-foreground">Subtotal</span>
                      <span>${subtotal.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-muted-foreground">Tax (8%)</span>
                      <span>${tax.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between text-lg font-bold">
                      <span>Total</span>
                      <span className="text-primary">${total.toFixed(2)}</span>
                    </div>
                    <Button
                      size="lg"
                      className="w-full mt-4 bg-gradient-to-r from-[#FBBF24] to-[#F59E0B] hover:from-[#D97706] hover:to-[#B45309] text-white font-semibold"
                      onClick={() => {
                        setIsCartOpen(false);
                        setCurrentStep("checkout");
                      }}
                    >
                      Checkout - ${total.toFixed(2)}
                    </Button>
                  </div>
                </>
              )}
            </div>
          </SheetContent>
        </Sheet>
      )}

      {currentStep !== "menu" && <Footer />}
    </div>
  );
};

export default Order;
