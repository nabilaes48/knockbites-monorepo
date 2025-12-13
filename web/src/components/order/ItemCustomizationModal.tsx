import { useState, useEffect } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Plus, Minus, ShoppingCart } from "lucide-react";

interface MenuItem {
  id: number;
  name: string;
  description: string;
  price: number;
  image?: string;
  image_url?: string;
  badges?: string[];
  tags?: string[];
  calories?: number;
  category?: string;
  categoryName?: string;
}

interface AddOn {
  id: string;
  name: string;
  price: number;
}

interface SizeOption {
  id: string;
  name: string;
  priceModifier: number;
}

interface ItemCustomizationModalProps {
  item: MenuItem | null;
  isOpen: boolean;
  onClose: () => void;
  onAddToCart: (item: MenuItem, customization: any) => void;
}

const sizeOptions: SizeOption[] = [
  { id: "small", name: "Small", priceModifier: -1.5 },
  { id: "medium", name: "Medium", priceModifier: 0 },
  { id: "large", name: "Large", priceModifier: 2.0 },
];

const addOns: AddOn[] = [
  { id: "extra-cheese", name: "Extra Cheese", price: 1.0 },
  { id: "bacon", name: "Bacon", price: 1.5 },
  { id: "avocado", name: "Avocado", price: 2.0 },
  { id: "extra-patty", name: "Extra Patty", price: 3.0 },
  { id: "grilled-onions", name: "Grilled Onions", price: 0.5 },
  { id: "mushrooms", name: "Mushrooms", price: 1.0 },
];

export const ItemCustomizationModal = ({
  item,
  isOpen,
  onClose,
  onAddToCart,
}: ItemCustomizationModalProps) => {
  const [selectedSize, setSelectedSize] = useState("medium");
  const [selectedAddOns, setSelectedAddOns] = useState<string[]>([]);
  const [specialInstructions, setSpecialInstructions] = useState("");
  const [quantity, setQuantity] = useState(1);

  // Reset state when modal opens with new item
  useEffect(() => {
    if (isOpen && item) {
      setSelectedSize("medium");
      setSelectedAddOns([]);
      setSpecialInstructions("");
      setQuantity(1);
    }
  }, [isOpen, item]);

  if (!item) return null;

  const handleAddOnToggle = (addOnId: string) => {
    setSelectedAddOns((prev) =>
      prev.includes(addOnId) ? prev.filter((id) => id !== addOnId) : [...prev, addOnId]
    );
  };

  const calculateTotal = () => {
    const sizeOption = sizeOptions.find((s) => s.id === selectedSize);
    const sizePrice = sizeOption ? sizeOption.priceModifier : 0;

    const addOnsPrice = selectedAddOns.reduce((total, addOnId) => {
      const addOn = addOns.find((a) => a.id === addOnId);
      return total + (addOn ? addOn.price : 0);
    }, 0);

    return (item.price + sizePrice + addOnsPrice) * quantity;
  };

  const handleAddToCart = () => {
    const customization = {
      size: selectedSize,
      addOns: selectedAddOns.map((id) => addOns.find((a) => a.id === id)),
      specialInstructions,
      quantity,
      totalPrice: calculateTotal(),
    };

    onAddToCart(item, customization);
    onClose();
  };

  const incrementQuantity = () => setQuantity((prev) => Math.min(prev + 1, 99));
  const decrementQuantity = () => setQuantity((prev) => Math.max(prev - 1, 1));

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl">{item.name}</DialogTitle>
          <DialogDescription>{item.description}</DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Item Image */}
          <div className="relative h-64 overflow-hidden rounded-lg">
            <img
              src={item.image_url || item.image || ''}
              alt={item.name}
              className="w-full h-full object-cover"
            />
            {(item.badges || item.tags) && (item.badges?.length || item.tags?.length) ? (
              <div className="absolute top-2 right-2 flex flex-col gap-1">
                {(item.badges || item.tags || []).map((badge, index) => (
                  <Badge key={index} variant="secondary" className="bg-secondary/90 text-white">
                    {badge}
                  </Badge>
                ))}
              </div>
            ) : null}
          </div>

          {/* Base Price & Calories */}
          <div className="flex items-center justify-between">
            <span className="text-2xl font-bold text-primary">${item.price.toFixed(2)}</span>
            {item.calories && (
              <span className="text-sm text-muted-foreground">{item.calories} cal</span>
            )}
          </div>

          {/* Size Selection */}
          <div className="space-y-3">
            <Label className="text-base font-semibold">Size</Label>
            <RadioGroup value={selectedSize} onValueChange={setSelectedSize}>
              <div className="grid grid-cols-3 gap-3">
                {sizeOptions.map((size) => (
                  <div key={size.id} className="flex items-center">
                    <RadioGroupItem value={size.id} id={size.id} className="sr-only peer" />
                    <Label
                      htmlFor={size.id}
                      className="flex flex-col items-center justify-center w-full p-4 border-2 rounded-lg cursor-pointer peer-data-[state=checked]:border-primary peer-data-[state=checked]:bg-primary/5 hover:bg-muted transition-colors"
                    >
                      <span className="font-semibold">{size.name}</span>
                      <span className="text-sm text-muted-foreground">
                        {size.priceModifier > 0 && "+"}
                        {size.priceModifier !== 0 && `$${size.priceModifier.toFixed(2)}`}
                        {size.priceModifier === 0 && "Standard"}
                      </span>
                    </Label>
                  </div>
                ))}
              </div>
            </RadioGroup>
          </div>

          {/* Add-Ons */}
          <div className="space-y-3">
            <Label className="text-base font-semibold">Add-Ons</Label>
            <div className="grid md:grid-cols-2 gap-3">
              {addOns.map((addOn) => (
                <div
                  key={addOn.id}
                  className="flex items-center space-x-3 p-3 border rounded-lg hover:bg-muted transition-colors"
                >
                  <Checkbox
                    id={addOn.id}
                    checked={selectedAddOns.includes(addOn.id)}
                    onCheckedChange={() => handleAddOnToggle(addOn.id)}
                  />
                  <Label
                    htmlFor={addOn.id}
                    className="flex-1 flex items-center justify-between cursor-pointer"
                  >
                    <span>{addOn.name}</span>
                    <span className="text-sm font-semibold text-primary">
                      +${addOn.price.toFixed(2)}
                    </span>
                  </Label>
                </div>
              ))}
            </div>
          </div>

          {/* Special Instructions */}
          <div className="space-y-3">
            <Label htmlFor="instructions" className="text-base font-semibold">
              Special Instructions
            </Label>
            <Textarea
              id="instructions"
              placeholder="Any special requests? (e.g., no onions, extra pickles)"
              value={specialInstructions}
              onChange={(e) => setSpecialInstructions(e.target.value)}
              rows={3}
              className="resize-none"
            />
          </div>

          {/* Quantity Selector */}
          <div className="space-y-3">
            <Label className="text-base font-semibold">Quantity</Label>
            <div className="flex items-center gap-4">
              <Button
                variant="outline"
                size="icon"
                onClick={decrementQuantity}
                disabled={quantity <= 1}
              >
                <Minus className="h-4 w-4" />
              </Button>
              <span className="text-2xl font-bold w-12 text-center">{quantity}</span>
              <Button
                variant="outline"
                size="icon"
                onClick={incrementQuantity}
                disabled={quantity >= 99}
              >
                <Plus className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button variant="secondary" onClick={handleAddToCart} className="min-w-[200px]">
            <ShoppingCart className="h-4 w-4 mr-2" />
            Add to Cart - ${calculateTotal().toFixed(2)}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
