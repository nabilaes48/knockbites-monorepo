import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Plus, Package, DollarSign, Image, Flame, Check, X } from "lucide-react";
import { cn } from "@/lib/utils";

interface MenuItem {
  id: number;
  name: string;
  description: string;
  price: number;
  category: string;
  calories: number;
  image: string;
  available: boolean;
  badges: string[];
}

interface AddItemModalProps {
  isOpen: boolean;
  onClose: () => void;
  onAddItem: (item: MenuItem) => void;
}

export const AddItemModal = ({ isOpen, onClose, onAddItem }: AddItemModalProps) => {
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    price: "",
    category: "burgers",
    calories: "",
    image: "",
    available: true,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const newItem = {
      id: Date.now(),
      name: formData.name,
      description: formData.description,
      price: parseFloat(formData.price),
      category: formData.category,
      calories: parseInt(formData.calories) || 0,
      image:
        formData.image ||
        "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=300&fit=crop",
      available: formData.available,
      badges: [],
    };

    onAddItem(newItem);
    handleClose();
  };

  const handleClose = () => {
    setFormData({
      name: "",
      description: "",
      price: "",
      category: "burgers",
      calories: "",
      image: "",
      available: true,
    });
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className={cn(
        "max-w-2xl max-h-[90vh] overflow-y-auto",
        // Light mode - Apple clean
        "bg-white/95 border-gray-200/80",
        // Dark mode - Glassmorphism
        "dark:bg-card/80 dark:backdrop-blur-xl dark:border-white/10",
        "dark:shadow-[0_0_50px_rgba(0,0,0,0.5)]"
      )}>
        {/* Header with gradient accent */}
        <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-ios-green via-ios-teal to-ios-blue dark:from-neon-green dark:via-neon-cyan dark:to-neon-blue" />

        <DialogHeader className="pt-2">
          <DialogTitle className={cn(
            "text-2xl font-semibold flex items-center gap-3",
            "text-gray-900 dark:text-white"
          )}>
            <div className={cn(
              "p-2 rounded-xl",
              "bg-ios-green/10 text-ios-green",
              "dark:bg-neon-green/20 dark:text-neon-green"
            )}>
              <Plus className="h-5 w-5" />
            </div>
            Add Menu Item
          </DialogTitle>
          <DialogDescription className="text-muted-foreground">
            Add a new item to your menu
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-5 py-4">
          {/* Basic Information Section */}
          <div className={cn(
            "p-4 rounded-xl",
            "bg-gray-50 border border-gray-200",
            "dark:bg-white/5 dark:border-white/10"
          )}>
            <h3 className="text-sm font-medium text-muted-foreground mb-4 flex items-center gap-2">
              <Package className="h-4 w-4" />
              Item Details
            </h3>

            {/* Item Name */}
            <div className="space-y-2">
              <Label htmlFor="name" className="text-foreground">Item Name *</Label>
              <Input
                id="name"
                placeholder="e.g., Classic Cheeseburger"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
                className={cn(
                  "bg-white border-gray-300",
                  "dark:bg-white/5 dark:border-white/20 dark:focus:border-neon-cyan"
                )}
              />
            </div>

            {/* Description */}
            <div className="space-y-2 mt-4">
              <Label htmlFor="description" className="text-foreground">Description *</Label>
              <Textarea
                id="description"
                placeholder="Describe your menu item..."
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                rows={3}
                required
                className={cn(
                  "bg-white border-gray-300 resize-none",
                  "dark:bg-white/5 dark:border-white/20 dark:focus:border-neon-cyan"
                )}
              />
            </div>
          </div>

          {/* Pricing Section */}
          <div className={cn(
            "p-4 rounded-xl",
            "bg-gray-50 border border-gray-200",
            "dark:bg-white/5 dark:border-white/10"
          )}>
            <h3 className="text-sm font-medium text-muted-foreground mb-4 flex items-center gap-2">
              <DollarSign className="h-4 w-4" />
              Pricing & Nutrition
            </h3>

            <div className="grid md:grid-cols-2 gap-4">
              {/* Price */}
              <div className="space-y-2">
                <Label htmlFor="price" className="text-foreground">Price ($) *</Label>
                <div className="relative">
                  <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="price"
                    type="number"
                    step="0.01"
                    min="0"
                    placeholder="8.99"
                    value={formData.price}
                    onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                    required
                    className={cn(
                      "pl-10 bg-white border-gray-300",
                      "dark:bg-white/5 dark:border-white/20 dark:focus:border-neon-cyan"
                    )}
                  />
                </div>
              </div>

              {/* Calories */}
              <div className="space-y-2">
                <Label htmlFor="calories" className="text-foreground flex items-center gap-2">
                  <Flame className="h-3 w-3" />
                  Calories
                </Label>
                <Input
                  id="calories"
                  type="number"
                  min="0"
                  placeholder="680"
                  value={formData.calories}
                  onChange={(e) => setFormData({ ...formData, calories: e.target.value })}
                  className={cn(
                    "bg-white border-gray-300",
                    "dark:bg-white/5 dark:border-white/20 dark:focus:border-neon-cyan"
                  )}
                />
              </div>
            </div>
          </div>

          {/* Category & Image Section */}
          <div className={cn(
            "p-4 rounded-xl",
            "bg-gray-50 border border-gray-200",
            "dark:bg-white/5 dark:border-white/10"
          )}>
            <h3 className="text-sm font-medium text-muted-foreground mb-4 flex items-center gap-2">
              <Image className="h-4 w-4" />
              Category & Media
            </h3>

            {/* Category */}
            <div className="space-y-2">
              <Label htmlFor="category" className="text-foreground">Category *</Label>
              <Select
                value={formData.category}
                onValueChange={(value) => setFormData({ ...formData, category: value })}
              >
                <SelectTrigger className={cn(
                  "bg-white border-gray-300",
                  "dark:bg-white/5 dark:border-white/20"
                )}>
                  <SelectValue placeholder="Select a category" />
                </SelectTrigger>
                <SelectContent className="dark:bg-card dark:border-white/10">
                  <SelectItem value="burgers">Burgers</SelectItem>
                  <SelectItem value="sandwiches">Sandwiches</SelectItem>
                  <SelectItem value="salads">Salads</SelectItem>
                  <SelectItem value="sides">Sides</SelectItem>
                  <SelectItem value="desserts">Desserts</SelectItem>
                  <SelectItem value="beverages">Beverages</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Image URL */}
            <div className="space-y-2 mt-4">
              <Label htmlFor="image" className="text-foreground">Image URL</Label>
              <Input
                id="image"
                type="url"
                placeholder="https://images.unsplash.com/..."
                value={formData.image}
                onChange={(e) => setFormData({ ...formData, image: e.target.value })}
                className={cn(
                  "bg-white border-gray-300",
                  "dark:bg-white/5 dark:border-white/20 dark:focus:border-neon-cyan"
                )}
              />
              <p className="text-xs text-muted-foreground">
                Optional: Leave blank for default image
              </p>
            </div>
          </div>

          {/* Available Toggle */}
          <div className={cn(
            "flex items-center justify-between p-4 rounded-xl",
            "bg-gray-50 border border-gray-200",
            "dark:bg-white/5 dark:border-white/10"
          )}>
            <div>
              <Label htmlFor="available" className="text-base font-semibold text-foreground flex items-center gap-2">
                <Check className="h-4 w-4" />
                Available Now
              </Label>
              <p className="text-sm text-muted-foreground">
                Item will be visible to customers
              </p>
            </div>
            <Switch
              id="available"
              checked={formData.available}
              onCheckedChange={(checked) => setFormData({ ...formData, available: checked })}
              className={cn(
                "data-[state=checked]:bg-ios-green",
                "dark:data-[state=checked]:bg-neon-green"
              )}
            />
          </div>

          <DialogFooter className="gap-2 pt-4 border-t border-gray-200 dark:border-white/10">
            <Button
              type="button"
              variant="outline"
              onClick={handleClose}
              className={cn(
                "border-gray-300 hover:bg-gray-100",
                "dark:border-white/20 dark:hover:bg-white/10"
              )}
            >
              <X className="h-4 w-4 mr-2" />
              Cancel
            </Button>
            <Button
              type="submit"
              className={cn(
                "bg-ios-green hover:bg-ios-green/90 text-white",
                "dark:bg-gradient-to-r dark:from-neon-green dark:to-neon-cyan dark:hover:opacity-90",
                "dark:shadow-[0_0_20px_rgba(0,255,136,0.3)]"
              )}
            >
              <Plus className="h-4 w-4 mr-2" />
              Add Item
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};
