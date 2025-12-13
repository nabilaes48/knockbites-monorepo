import { useState, useEffect, lazy, Suspense } from "react";
import { Search, Plus, Filter, Loader2 } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { OptimizedImage } from "@/components/OptimizedImage";
import { supabase } from "@/lib/supabase";
import { useToast } from "@/hooks/use-toast";

// Lazy load the modal (only loads when opened)
const ItemCustomizationModalV2 = lazy(() => import("./ItemCustomizationModalV2").then(module => ({
  default: module.ItemCustomizationModalV2
})));

interface MenuItem {
  id: number;
  name: string;
  description: string;
  base_price: number;
  category_id: number;
  category_name?: string;
  image_url: string | null;
  tags: string[];
  is_featured: boolean;
  is_available: boolean;
  preparation_time: number;
}

// Menu items are fetched from Supabase database

const categories = [
  { id: "all", name: "All Items" },
  { id: "burgers", name: "Burgers" },
  { id: "sandwiches", name: "Sandwiches" },
  { id: "salads", name: "Salads" },
  { id: "desserts", name: "Desserts" },
  { id: "beverages", name: "Beverages" },
];

interface MenuBrowseProps {
  onAddToCart: (item: any) => void;
}

export const MenuBrowse = ({ onAddToCart }: MenuBrowseProps) => {
  const { toast } = useToast();
  const [searchQuery, setSearchQuery] = useState("");
  const [activeCategory, setActiveCategory] = useState("all");
  const [selectedItem, setSelectedItem] = useState<any>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Real menu data from Supabase
  const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
  const [categories, setCategories] = useState<any[]>([{ id: "all", name: "All Items" }]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch menu items from Supabase
  useEffect(() => {
    const fetchMenu = async () => {
      try {
        setLoading(true);

        // Fetch categories
        const { data: categoriesData, error: categoriesError } = await supabase
          .from('menu_categories')
          .select('*')
          .eq('is_active', true)
          .order('display_order');

        if (categoriesError) throw categoriesError;

        // Fetch menu items for Highland Mills (store_id = 1)
        const { data: menuData, error: menuError } = await supabase
          .from('menu_items')
          .select(`
            id,
            name,
            description,
            base_price,
            category_id,
            image_url,
            tags,
            is_featured,
            is_available,
            preparation_time,
            menu_categories (name)
          `)
          .eq('is_available', true)
          .order('name');

        if (menuError) throw menuError;

        // Transform data
        const transformedMenu = menuData.map((item: any) => ({
          ...item,
          price: item.base_price, // Map base_price to price for compatibility
          category_name: item.menu_categories?.name || 'Uncategorized',
        }));

        setMenuItems(transformedMenu);

        // Add categories
        const transformedCategories = [
          { id: "all", name: "All Items" },
          ...(categoriesData || []).map((cat) => ({
            id: cat.id.toString(),
            name: cat.name,
          })),
        ];
        setCategories(transformedCategories);

        setError(null);
      } catch (err: any) {
        console.error('Error fetching menu:', err);
        setError(err.message);
        toast({
          title: "Error Loading Menu",
          description: "Failed to load menu from database. Please refresh the page.",
          variant: "destructive",
        });
        setMenuItems([]);
      } finally {
        setLoading(false);
      }
    };

    fetchMenu();
  }, [toast]);

  const filteredItems = menuItems.filter((item) => {
    const matchesSearch =
      item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.description?.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesCategory =
      activeCategory === "all" ||
      item.category_id?.toString() === activeCategory;

    return matchesSearch && matchesCategory && item.is_available;
  });

  const handleOpenModal = (item: any) => {
    setSelectedItem(item);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedItem(null);
  };

  const handleAddToCart = (item: any, customization: any) => {
    // Add customized item to cart
    const cartItem = {
      ...item,
      ...customization,
      cartId: Date.now(), // Unique ID for cart item
    };
    onAddToCart(cartItem);
  };

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-2xl font-bold mb-4">Browse Menu</h2>

        {/* Search Bar */}
        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
          <Input
            type="text"
            placeholder="Search menu items..."
            className="pl-10"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        {/* Category Tabs */}
        <Tabs value={activeCategory} onValueChange={setActiveCategory}>
          <TabsList className="w-full grid grid-cols-3 lg:grid-cols-6 h-auto">
            {categories.map((category) => (
              <TabsTrigger
                key={category.id}
                value={category.id}
                className="text-xs md:text-sm py-2"
              >
                {category.name}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="flex items-center justify-center py-12">
          <div className="text-center">
            <Loader2 className="h-8 w-8 animate-spin mx-auto mb-2" />
            <p className="text-muted-foreground">Loading delicious menu...</p>
          </div>
        </div>
      )}

      {/* Menu Items Grid */}
      {!loading && (
        <div className="grid gap-4">
          {filteredItems.length > 0 ? (
            filteredItems.map((item) => (
              <Card key={item.id} className="overflow-hidden hover:shadow-medium transition-all">
                <div className="flex flex-col sm:flex-row">
                  {/* Image */}
                  <OptimizedImage
                    src={item.image_url || '/images/menu/placeholder.png'}
                    alt={item.name}
                    wrapperClassName="w-full sm:w-32 h-32 flex-shrink-0"
                    className="w-full h-full object-cover"
                  />

                {/* Content */}
                <CardContent className="flex-1 p-4">
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex-1">
                      <h3 className="font-bold text-lg mb-1">{item.name}</h3>
                      <p className="text-sm text-muted-foreground line-clamp-2">
                        {item.description}
                      </p>
                    </div>
                    {item.tags && item.tags.length > 0 && (
                      <div className="ml-2 flex flex-wrap gap-1">
                        {item.is_featured && (
                          <Badge variant="default" className="text-xs">
                            Featured
                          </Badge>
                        )}
                        {item.tags.includes('popular') && (
                          <Badge variant="secondary" className="text-xs">
                            Popular
                          </Badge>
                        )}
                        {item.tags.includes('spicy') && (
                          <Badge variant="destructive" className="text-xs">
                            🌶️ Spicy
                          </Badge>
                        )}
                      </div>
                    )}
                  </div>

                  <div className="flex items-center justify-between mt-3">
                    <span className="text-xl font-bold text-primary">
                      ${item.base_price?.toFixed(2) || '0.00'}
                    </span>
                    <Button
                      variant="default"
                      size="sm"
                      onClick={() => handleOpenModal(item)}
                    >
                      <Plus className="h-4 w-4 mr-1" />
                      Add to Cart
                    </Button>
                  </div>
                </CardContent>
              </div>
            </Card>
          ))
        ) : (
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-muted-foreground">
                No items found matching "{searchQuery}"
              </p>
            </CardContent>
          </Card>
        )}
        </div>
      )}

      {/* Item Customization Modal - Lazy loaded */}
      {isModalOpen && (
        <Suspense fallback={<div />}>
          <ItemCustomizationModalV2
            item={selectedItem}
            isOpen={isModalOpen}
            onClose={handleCloseModal}
            onAddToCart={handleAddToCart}
          />
        </Suspense>
      )}
    </div>
  );
};
