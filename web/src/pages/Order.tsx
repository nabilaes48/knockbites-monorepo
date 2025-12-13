import { useState } from "react";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { StoreSelection } from "@/components/order/StoreSelection";
import { MenuBrowse } from "@/components/order/MenuBrowse";
import { Cart } from "@/components/order/Cart";
import { Checkout } from "@/components/order/Checkout";

export type OrderStep = "store" | "menu" | "cart" | "checkout";

type StepStatus = "current" | "completed" | "upcoming";

const Order = () => {
  const [currentStep, setCurrentStep] = useState<OrderStep>("store");
  const [selectedStore, setSelectedStore] = useState<number | null>(null);
  const [cartItems, setCartItems] = useState<any[]>([]);

  const handleStoreSelect = (storeId: number) => {
    setSelectedStore(storeId);
    setCurrentStep("menu");
  };

  const handleAddToCart = (item: any) => {
    setCartItems([...cartItems, item]);
  };

  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      <main className="pt-20 pb-16">
        <div className="container mx-auto px-4">
          {/* Progress Indicator */}
          <div className="max-w-4xl mx-auto mb-8">
            <div className="flex items-center justify-between">
              <div className={`flex items-center ${currentStep === "store" ? "text-primary" : (currentStep === "menu" || currentStep === "cart" || currentStep === "checkout") ? "text-accent" : "text-muted-foreground"}`}>
                <div className={`w-10 h-10 rounded-full flex items-center justify-center ${currentStep === "store" ? "bg-primary text-white" : (currentStep === "menu" || currentStep === "cart" || currentStep === "checkout") ? "bg-accent text-white" : "bg-muted"}`}>
                  1
                </div>
                <span className="ml-2 font-semibold hidden sm:inline">Select Store</span>
              </div>

              <div className="flex-1 h-1 mx-4 bg-muted">
                <div className={`h-full transition-all ${(currentStep === "menu" || currentStep === "cart" || currentStep === "checkout") ? "bg-accent" : "bg-muted"}`} style={{ width: (currentStep === "menu" || currentStep === "cart" || currentStep === "checkout") ? "100%" : "0%" }} />
              </div>

              <div className={`flex items-center ${currentStep === "menu" ? "text-primary" : currentStep === "cart" || currentStep === "checkout" ? "text-accent" : "text-muted-foreground"}`}>
                <div className={`w-10 h-10 rounded-full flex items-center justify-center ${currentStep === "menu" ? "bg-primary text-white" : currentStep === "cart" || currentStep === "checkout" ? "bg-accent text-white" : "bg-muted"}`}>
                  2
                </div>
                <span className="ml-2 font-semibold hidden sm:inline">Order Food</span>
              </div>

              <div className="flex-1 h-1 mx-4 bg-muted">
                <div className={`h-full transition-all ${currentStep === "cart" || currentStep === "checkout" ? "bg-accent" : "bg-muted"}`} style={{ width: currentStep === "cart" || currentStep === "checkout" ? "100%" : "0%" }} />
              </div>

              <div className={`flex items-center ${currentStep === "checkout" ? "text-primary" : "text-muted-foreground"}`}>
                <div className={`w-10 h-10 rounded-full flex items-center justify-center ${currentStep === "checkout" ? "bg-primary text-white" : "bg-muted"}`}>
                  3
                </div>
                <span className="ml-2 font-semibold hidden sm:inline">Checkout</span>
              </div>
            </div>
          </div>

          {/* Content */}
          {currentStep === "store" && (
            <StoreSelection onSelectStore={handleStoreSelect} />
          )}

          {currentStep === "menu" && selectedStore && (
            <div className="grid lg:grid-cols-3 gap-6">
              <div className="lg:col-span-2">
                <MenuBrowse onAddToCart={handleAddToCart} />
              </div>
              <div className="lg:col-span-1">
                <Cart
                  items={cartItems}
                  onUpdateItems={setCartItems}
                  onCheckout={() => setCurrentStep("checkout")}
                />
              </div>
            </div>
          )}

          {currentStep === "checkout" && (
            <Checkout items={cartItems} storeId={selectedStore} />
          )}
        </div>
      </main>

      <Footer />
    </div>
  );
};

export default Order;
