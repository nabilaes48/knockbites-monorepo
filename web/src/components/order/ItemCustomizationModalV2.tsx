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
import { Plus, Minus, ShoppingCart, Salad, Droplet, Sparkles } from "lucide-react";
import { PortionSelectorRow, PortionLevel } from "@/components/ui/PortionSelector";
import { supabase } from "@/lib/supabase";

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

interface IngredientCustomization {
  id: number;
  name: string;
  category: string;
  portion_pricing: {
    none: number;
    light: number;
    regular: number;
    extra: number;
  };
  default_portion: string;
}

interface ItemCustomizationModalV2Props {
  item: MenuItem | null;
  isOpen: boolean;
  onClose: () => void;
  onAddToCart: (item: MenuItem, customization: any) => void;
}

const categoryConfig = {
  vegetables: {
    label: "Fresh Vegetables",
    icon: Salad,
    color: "text-green-500",
  },
  sauces: {
    label: "Signature Sauces",
    icon: Droplet,
    color: "text-amber-500",
  },
  extras: {
    label: "Premium Extras",
    icon: Sparkles,
    color: "text-purple-500",
  },
};

export const ItemCustomizationModalV2 = ({
  item,
  isOpen,
  onClose,
  onAddToCart,
}: ItemCustomizationModalV2Props) => {
  const [ingredients, setIngredients] = useState<IngredientCustomization[]>([]);
  const [selections, setSelections] = useState<Record<number, PortionLevel>>({});
  const [specialInstructions, setSpecialInstructions] = useState("");
  const [quantity, setQuantity] = useState(1);
  const [loading, setLoading] = useState(false);

  // Fetch ingredients for this item
  useEffect(() => {
    if (isOpen && item) {
      fetchIngredients();
      setQuantity(1);
      setSpecialInstructions("");
    }
  }, [isOpen, item]);

  const fetchIngredients = async () => {
    if (!item) return;

    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('menu_item_customizations')
        .select('*')
        .eq('menu_item_id', item.id)
        .eq('supports_portions', true)
        .order('category')
        .order('display_order');

      if (error) throw error;

      const loadedIngredients = (data || []).map((ing: any) => ({
        id: ing.id,
        name: ing.name,
        category: ing.category || 'extras',
        portion_pricing: ing.portion_pricing,
        default_portion: ing.default_portion || 'regular',
      }));

      setIngredients(loadedIngredients);

      // Set default selections
      const defaultSelections: Record<number, PortionLevel> = {};
      loadedIngredients.forEach((ing: IngredientCustomization) => {
        defaultSelections[ing.id] = ing.default_portion as PortionLevel;
      });
      setSelections(defaultSelections);
    } catch (err) {
      console.error('Error fetching ingredients:', err);
    } finally {
      setLoading(false);
    }
  };

  const handlePortionChange = (ingredientId: number, portion: PortionLevel) => {
    setSelections({ ...selections, [ingredientId]: portion });
  };

  const calculateTotal = () => {
    if (!item) return 0;

    let total = item.price;

    // Add ingredient pricing
    ingredients.forEach((ing) => {
      const selectedPortion = selections[ing.id] || 'none';
      total += ing.portion_pricing[selectedPortion] || 0;
    });

    return total * quantity;
  };

  const getCustomizationSummary = () => {
    const customizations: string[] = [];

    ingredients.forEach((ing) => {
      const portion = selections[ing.id];
      if (portion && portion !== 'none') {
        const portionLabel = portion.charAt(0).toUpperCase() + portion.slice(1);
        customizations.push(`${portionLabel} ${ing.name}`);
      }
    });

    return customizations;
  };

  const handleAddToCart = () => {
    if (!item) return;

    const customization = {
      ingredients: getCustomizationSummary(),
      specialInstructions,
      quantity,
      totalPrice: calculateTotal(),
    };

    onAddToCart(item, customization);
    onClose();
  };

  const incrementQuantity = () => setQuantity((prev) => Math.min(prev + 1, 99));
  const decrementQuantity = () => setQuantity((prev) => Math.max(prev - 1, 1));

  // Group ingredients by category
  const groupedIngredients = ingredients.reduce((acc, ing) => {
    if (!acc[ing.category]) {
      acc[ing.category] = [];
    }
    acc[ing.category].push(ing);
    return acc;
  }, {} as Record<string, IngredientCustomization[]>);

  if (!item) return null;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl">{item.name}</DialogTitle>
          <DialogDescription>{item.description}</DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Item Image */}
          <div className="relative h-48 overflow-hidden rounded-lg">
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

          {/* Base Price */}
          <div className="flex items-center justify-between">
            <span className="text-2xl font-bold text-primary">Base: ${item.price.toFixed(2)}</span>
            {item.calories && (
              <span className="text-sm text-muted-foreground">{item.calories} cal</span>
            )}
          </div>

          {/* Ingredients by Category */}
          {loading ? (
            <div className="text-center py-8 text-muted-foreground">
              Loading customization options...
            </div>
          ) : Object.keys(groupedIngredients).length > 0 ? (
            <div className="space-y-6">
              {Object.entries(groupedIngredients).map(([category, categoryIngredients]) => {
                const config = categoryConfig[category as keyof typeof categoryConfig];
                if (!config) return null;

                const Icon = config.icon;

                return (
                  <div key={category} className="space-y-3">
                    <div className="flex items-center gap-2 border-b pb-2">
                      <Icon className={`h-5 w-5 ${config.color}`} />
                      <Label className="text-base font-semibold">{config.label}</Label>
                    </div>
                    <div className="space-y-2">
                      {categoryIngredients.map((ing) => (
                        <PortionSelectorRow
                          key={ing.id}
                          ingredientName={ing.name}
                          value={selections[ing.id] || 'none'}
                          onChange={(portion) => handlePortionChange(ing.id, portion)}
                          pricing={ing.portion_pricing}
                          showPrices={true}
                        />
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="text-center py-8 text-muted-foreground">
              <p>No customization options available for this item.</p>
              <p className="text-sm">Enjoy it as-is!</p>
            </div>
          )}

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
          <Button
            onClick={handleAddToCart}
            className="min-w-[200px] bg-gradient-to-r from-[#FBBF24] to-[#F59E0B] hover:from-[#D97706] hover:to-[#B45309] text-white font-semibold shadow-md hover:shadow-lg transition-all"
          >
            <ShoppingCart className="h-4 w-4 mr-2" />
            Add to Cart - ${calculateTotal().toFixed(2)}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
