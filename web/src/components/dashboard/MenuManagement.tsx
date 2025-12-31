import { useState, useEffect, lazy, Suspense } from "react";
import { useNavigate } from "react-router-dom";
import { Switch } from "@/components/ui/switch";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlowingBadge } from "@/components/ui/GlowingBadge";
import { NeonButton } from "@/components/ui/NeonButton";
import { AnimatedCounter, AnimatedCurrency } from "@/components/ui/AnimatedCounter";
import {
  Edit,
  Plus,
  Trash2,
  Utensils,
  Beef,
  Sandwich,
  Salad,
  Pizza,
  Coffee,
  IceCream,
  TrendingUp,
  Package,
  Loader2,
  Check,
  X,
  RefreshCw,
  Search,
  AlertCircle,
  Settings2,
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/lib/supabase";
import { cn } from "@/lib/utils";

// Lazy load modals
const AddItemModal = lazy(() =>
  import("./AddItemModal").then((module) => ({
    default: module.AddItemModal,
  }))
);
const EditItemModalV2 = lazy(() =>
  import("./EditItemModalV2").then((module) => ({
    default: module.EditItemModalV2,
  }))
);

interface MenuItemData {
  id: number;
  name: string;
  description: string;
  price: number;
  category: string;
  category_id: number;
  available: boolean;
  featured: boolean;
  image_url: string;
  tags: string[];
}

interface CategoryData {
  id: number;
  name: string;
  display_order: number;
  is_active: boolean;
}

export const MenuManagement = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [menuItems, setMenuItems] = useState<MenuItemData[]>([]);
  const [categories, setCategories] = useState<CategoryData[]>([]);
  const [category, setCategory] = useState("all");
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<MenuItemData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingPriceId, setEditingPriceId] = useState<number | null>(null);
  const [newPrice, setNewPrice] = useState<string>("");
  const [searchQuery, setSearchQuery] = useState("");

  // Fetch menu items and categories from Supabase
  useEffect(() => {
    fetchMenuData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const fetchMenuData = async () => {
    try {
      setLoading(true);

      // Fetch categories
      const { data: categoriesData, error: categoriesError } = await supabase
        .from("menu_categories")
        .select("*")
        .eq("is_active", true)
        .order("display_order");

      if (categoriesError) throw categoriesError;
      setCategories(categoriesData || []);

      // Fetch menu items
      const { data: menuData, error: menuError } = await supabase
        .from("menu_items")
        .select(
          `
          id,
          name,
          description,
          base_price,
          category_id,
          image_url,
          is_available,
          is_featured,
          tags,
          menu_categories (id, name)
        `
        )
        .order("name");

      if (menuError) throw menuError;

      const transformedMenu = (menuData || []).map((dbItem) => ({
        id: dbItem.id,
        name: dbItem.name,
        description: dbItem.description,
        price: dbItem.base_price,
        category: (dbItem.menu_categories as { name: string } | null)?.name || "Uncategorized",
        category_id: dbItem.category_id,
        available: dbItem.is_available,
        featured: dbItem.is_featured,
        image_url: dbItem.image_url,
        tags: dbItem.tags || [],
      }));

      setMenuItems(transformedMenu);
      setError(null);
    } catch (err) {
      console.error("Error fetching menu:", err);
      setError(err instanceof Error ? err.message : "Unknown error");
      toast({
        title: "Error Loading Menu",
        description: "Failed to load menu items from database",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const toggleAvailability = async (id: number) => {
    const item = menuItems.find((i) => i.id === id);
    if (!item) return;

    try {
      const { error } = await supabase
        .from("menu_items")
        .update({ is_available: !item.available })
        .eq("id", id);

      if (error) throw error;

      setMenuItems(
        menuItems.map((item) =>
          item.id === id ? { ...item, available: !item.available } : item
        )
      );

      toast({
        title: item.available ? "Item Disabled" : "Item Enabled",
        description: `${item.name} is now ${!item.available ? "available" : "unavailable"}`,
      });
    } catch (err) {
      toast({
        title: "Error",
        description: "Failed to update item availability",
        variant: "destructive",
      });
    }
  };

  const handleAddItem = async (newItem: { name: string; description?: string; price: number; category_id?: number; image_url?: string; preparation_time?: number; tags?: string[] }) => {
    try {
      const { data, error } = await supabase
        .from("menu_items")
        .insert({
          name: newItem.name,
          description: newItem.description || "",
          base_price: newItem.price,
          category_id: newItem.category_id,
          image_url: newItem.image_url || "/images/menu/placeholder.svg",
          is_available: true,
          is_featured: false,
          preparation_time: newItem.preparation_time || 10,
          tags: newItem.tags || [],
        })
        .select()
        .single();

      if (error) throw error;

      // Refresh menu
      await fetchMenuData();

      toast({
        title: "Item Added",
        description: `${newItem.name} has been added to the menu`,
      });
    } catch (err) {
      toast({
        title: "Error",
        description: "Failed to add item to database",
        variant: "destructive",
      });
    }
  };

  const handleDeleteItem = async (id: number) => {
    const item = menuItems.find((item) => item.id === id);
    if (!item) return;

    if (!window.confirm(`Are you sure you want to delete "${item.name}"?`)) return;

    try {
      const { error } = await supabase.from("menu_items").delete().eq("id", id);

      if (error) throw error;

      setMenuItems(menuItems.filter((item) => item.id !== id));

      toast({
        title: "Item Deleted",
        description: `${item.name} has been removed from the menu`,
        variant: "destructive",
      });
    } catch (err) {
      toast({
        title: "Error",
        description: "Failed to delete item from database",
        variant: "destructive",
      });
    }
  };

  const startEditingPrice = (id: number, currentPrice: number) => {
    setEditingPriceId(id);
    setNewPrice(currentPrice.toFixed(2));
  };

  const cancelEditingPrice = () => {
    setEditingPriceId(null);
    setNewPrice("");
  };

  const saveNewPrice = async (id: number) => {
    const item = menuItems.find((i) => i.id === id);
    if (!item) return;

    const priceValue = parseFloat(newPrice);

    if (isNaN(priceValue) || priceValue <= 0) {
      toast({
        title: "Invalid Price",
        description: "Please enter a valid price greater than 0",
        variant: "destructive",
      });
      return;
    }

    try {
      const { error } = await supabase
        .from("menu_items")
        .update({ base_price: priceValue })
        .eq("id", id);

      if (error) throw error;

      setMenuItems(
        menuItems.map((item) =>
          item.id === id ? { ...item, price: priceValue } : item
        )
      );

      toast({
        title: "Price Updated",
        description: `${item.name} price updated to $${priceValue.toFixed(2)}`,
      });

      setEditingPriceId(null);
      setNewPrice("");
    } catch (err) {
      toast({
        title: "Error",
        description: "Failed to update price",
        variant: "destructive",
      });
    }
  };

  const handleEditItem = (item: MenuItemData) => {
    setEditingItem(item);
    setIsEditModalOpen(true);
  };

  const handleSaveEdit = () => {
    fetchMenuData();
  };

  // Filter items by category and search query
  const filteredItems = menuItems.filter((item) => {
    const categoryMatch = category === "all" || item.category === category;
    const searchLower = searchQuery.toLowerCase();
    const searchMatch =
      !searchQuery ||
      item.name.toLowerCase().includes(searchLower) ||
      item.category.toLowerCase().includes(searchLower);
    return categoryMatch && searchMatch;
  });

  // Calculate stats
  const stats = {
    total: menuItems.length,
    available: menuItems.filter((item) => item.available).length,
    unavailable: menuItems.filter((item) => !item.available).length,
    avgPrice:
      menuItems.length > 0
        ? menuItems.reduce((sum, item) => sum + item.price, 0) / menuItems.length
        : 0,
  };

  // Loading state
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <div
            className={cn(
              "h-12 w-12 rounded-full border-2 animate-spin mx-auto",
              "border-primary/30 border-t-primary"
            )}
          />
          <p className="mt-4 text-muted-foreground">Loading menu items...</p>
        </div>
      </div>
    );
  }

  // Error state
  if (error && !loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <GlassCard className="max-w-md p-6 text-center">
          <AlertCircle className="h-12 w-12 text-destructive mx-auto mb-4" />
          <h3 className="text-lg font-semibold mb-2">Failed to Load Menu</h3>
          <p className="text-muted-foreground mb-4">{error}</p>
          <NeonButton onClick={fetchMenuData}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Retry
          </NeonButton>
        </GlassCard>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-semibold flex items-center gap-2 text-foreground">
            <div
              className={cn(
                "p-2 rounded-lg",
                "bg-ios-orange/10 text-ios-orange",
                "dark:bg-neon-orange/10 dark:text-neon-orange"
              )}
            >
              <Utensils className="h-5 w-5" />
            </div>
            Menu Management
          </h2>
          <p className="text-muted-foreground mt-1">
            Manage items and availability across all categories
          </p>
        </div>
        <div className="flex gap-2">
          <NeonButton variant="outline" onClick={() => navigate("/ingredients")} className="gap-2">
            <Settings2 className="h-4 w-4" />
            Ingredients
          </NeonButton>
          <NeonButton onClick={() => setIsAddModalOpen(true)} className="gap-2">
            <Plus className="h-4 w-4" />
            Add Item
          </NeonButton>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <GlassCard glowColor="purple" gradient="purple" className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-muted-foreground">Total Items</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={stats.total} />
              </h3>
            </div>
            <div
              className={cn(
                "h-10 w-10 rounded-xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-purple/20 to-ios-pink/10 text-ios-purple",
                "dark:from-neon-purple/20 dark:to-neon-pink/10 dark:text-neon-purple",
                "shadow-[0_4px_12px_rgba(175,82,222,0.2)] dark:shadow-[0_4px_15px_rgba(168,85,247,0.3)]"
              )}
            >
              <Package className="h-5 w-5" />
            </div>
          </div>
        </GlassCard>

        <GlassCard glowColor="accent" gradient="green" className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-muted-foreground">Available</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={stats.available} />
              </h3>
            </div>
            <div
              className={cn(
                "h-10 w-10 rounded-xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-green/20 to-ios-teal/10 text-ios-green",
                "dark:from-neon-green/20 dark:to-neon-cyan/10 dark:text-neon-green",
                "shadow-[0_4px_12px_rgba(52,199,89,0.2)] dark:shadow-[0_4px_15px_rgba(0,255,136,0.3)]"
              )}
            >
              <TrendingUp className="h-5 w-5" />
            </div>
          </div>
        </GlassCard>

        <GlassCard gradient="pink" className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-muted-foreground">Unavailable</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={stats.unavailable} />
              </h3>
            </div>
            <div
              className={cn(
                "h-10 w-10 rounded-xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-red/20 to-ios-pink/10 text-ios-red",
                "dark:from-destructive/20 dark:to-neon-pink/10 dark:text-destructive",
                "shadow-[0_4px_12px_rgba(255,59,48,0.2)]"
              )}
            >
              <Package className="h-5 w-5" />
            </div>
          </div>
        </GlassCard>

        <GlassCard glowColor="orange" gradient="orange" className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-muted-foreground">Avg Price</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCurrency value={stats.avgPrice} />
              </h3>
            </div>
            <div
              className={cn(
                "h-10 w-10 rounded-xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-orange/20 to-ios-yellow/10 text-ios-orange",
                "dark:from-neon-orange/20 dark:to-amber-500/10 dark:text-neon-orange",
                "shadow-[0_4px_12px_rgba(255,149,0,0.2)] dark:shadow-[0_4px_15px_rgba(255,136,0,0.3)]"
              )}
            >
              <Utensils className="h-5 w-5" />
            </div>
          </div>
        </GlassCard>
      </div>

      {/* Search and Filter */}
      <div className="flex flex-col md:flex-row gap-4">
        {/* Search */}
        <div className="relative flex-1 md:max-w-xs">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search menu items..."
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

        {/* Category Filter */}
        <GlassCard className="p-1 flex-1" gradient="orange" intensity="subtle">
          <Tabs value={category} onValueChange={setCategory}>
            <TabsList className="bg-transparent h-auto flex flex-wrap gap-1">
              <TabsTrigger
                value="all"
                className={cn(
                  "py-2 px-3 rounded-lg text-sm",
                  "data-[state=active]:bg-secondary data-[state=active]:shadow-soft",
                  "dark:data-[state=active]:bg-white/5 dark:data-[state=active]:shadow-glow-subtle"
                )}
              >
                All Items
              </TabsTrigger>
              {categories.map((cat) => (
                <TabsTrigger
                  key={cat.id}
                  value={cat.name}
                  className={cn(
                    "py-2 px-3 rounded-lg text-sm",
                    "data-[state=active]:bg-secondary data-[state=active]:shadow-soft",
                    "dark:data-[state=active]:bg-white/5 dark:data-[state=active]:shadow-glow-subtle"
                  )}
                >
                  {cat.name}
                </TabsTrigger>
              ))}
            </TabsList>
          </Tabs>
        </GlassCard>
      </div>

      {/* Menu Items List */}
      <div className="space-y-3">
        {filteredItems.length === 0 ? (
          <GlassCard className="py-12 text-center">
            <Utensils className="h-12 w-12 text-muted-foreground mx-auto mb-3 opacity-50" />
            <p className="text-lg font-medium mb-1">No items found</p>
            <p className="text-sm text-muted-foreground">
              {searchQuery
                ? "Try a different search term"
                : "Add your first menu item to get started"}
            </p>
          </GlassCard>
        ) : (
          filteredItems.map((item) => (
            <GlassCard
              key={item.id}
              hoverable
              gradient={item.available ? "blue" : "none"}
              intensity="subtle"
              className={cn(
                "transition-all",
                !item.available && "opacity-60"
              )}
            >
              <div className="p-4">
                <div className="flex items-center justify-between">
                  <div className="flex-1 flex items-center gap-4">
                    {/* Category Icon */}
                    <div
                      className={cn(
                        "p-3 rounded-xl",
                        item.available
                          ? "bg-primary/10 text-primary dark:shadow-glow-subtle"
                          : "bg-muted text-muted-foreground"
                      )}
                    >
                      <Utensils className="h-5 w-5" />
                    </div>

                    {/* Item Info */}
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-1.5">
                        <h3 className="font-semibold">{item.name}</h3>
                        <GlowingBadge
                          variant={item.available ? "default" : "danger"}
                          size="sm"
                        >
                          {item.category}
                        </GlowingBadge>
                        {!item.available && (
                          <GlowingBadge variant="danger" size="sm">
                            Unavailable
                          </GlowingBadge>
                        )}
                      </div>

                      {/* Price - Editable */}
                      {editingPriceId === item.id ? (
                        <div className="flex items-center gap-2">
                          <span className="text-lg font-bold text-primary">$</span>
                          <Input
                            type="number"
                            step="0.01"
                            min="0"
                            value={newPrice}
                            onChange={(e) => setNewPrice(e.target.value)}
                            className={cn(
                              "w-24 h-8 text-lg font-bold",
                              "bg-secondary/50 border-border/50",
                              "dark:bg-card/50 dark:border-primary/10"
                            )}
                            autoFocus
                            onKeyDown={(e) => {
                              if (e.key === "Enter") {
                                saveNewPrice(item.id);
                              } else if (e.key === "Escape") {
                                cancelEditingPrice();
                              }
                            }}
                          />
                          <NeonButton
                            size="sm"
                            variant="success"
                            onClick={() => saveNewPrice(item.id)}
                            className="h-8 w-8 p-0"
                          >
                            <Check className="h-4 w-4" />
                          </NeonButton>
                          <NeonButton
                            size="sm"
                            variant="ghost"
                            onClick={cancelEditingPrice}
                            className="h-8 w-8 p-0"
                          >
                            <X className="h-4 w-4" />
                          </NeonButton>
                        </div>
                      ) : (
                        <p
                          className={cn(
                            "text-lg font-bold cursor-pointer transition-colors",
                            "text-primary hover:text-primary/80"
                          )}
                          onClick={() => startEditingPrice(item.id, item.price)}
                          title="Click to edit price"
                        >
                          ${item.price.toFixed(2)}
                        </p>
                      )}
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-4">
                    {/* Availability Toggle */}
                    <div className="flex items-center gap-2">
                      <Label
                        htmlFor={`available-${item.id}`}
                        className="text-sm text-muted-foreground"
                      >
                        Available
                      </Label>
                      <Switch
                        id={`available-${item.id}`}
                        checked={item.available}
                        onCheckedChange={() => toggleAvailability(item.id)}
                      />
                    </div>

                    {/* Action Buttons */}
                    <div className="flex gap-2">
                      <NeonButton
                        variant="secondary"
                        size="icon"
                        onClick={() => handleEditItem(item)}
                      >
                        <Edit className="h-4 w-4" />
                      </NeonButton>
                      <NeonButton
                        variant="ghost"
                        size="icon"
                        onClick={() => handleDeleteItem(item.id)}
                        className="text-destructive hover:bg-destructive/10"
                      >
                        <Trash2 className="h-4 w-4" />
                      </NeonButton>
                    </div>
                  </div>
                </div>
              </div>
            </GlassCard>
          ))
        )}
      </div>

      {/* Add Item Modal */}
      {isAddModalOpen && (
        <Suspense fallback={<div />}>
          <AddItemModal
            isOpen={isAddModalOpen}
            onClose={() => setIsAddModalOpen(false)}
            onAddItem={handleAddItem}
            categories={categories}
          />
        </Suspense>
      )}

      {/* Edit Item Modal */}
      {isEditModalOpen && (
        <Suspense fallback={<div />}>
          <EditItemModalV2
            item={editingItem}
            isOpen={isEditModalOpen}
            onClose={() => {
              setIsEditModalOpen(false);
              setEditingItem(null);
            }}
            onSave={handleSaveEdit}
            categories={categories}
          />
        </Suspense>
      )}
    </div>
  );
};
