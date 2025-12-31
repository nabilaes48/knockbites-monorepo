import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/contexts/AuthContext";
import {
  ArrowLeft,
  Plus,
  Pencil,
  Trash2,
  DollarSign,
  Salad,
  Droplet,
  Sparkles,
  Save,
  Search,
} from "lucide-react";

interface IngredientTemplate {
  id: number;
  name: string;
  category: string;
  supports_portions: boolean;
  portion_pricing: {
    none: number;
    light: number;
    regular: number;
    extra: number;
  };
  default_portion: string;
  display_order: number;
  is_active: boolean;
}

const categoryConfig = {
  vegetables: {
    label: "Fresh Vegetables",
    icon: Salad,
    color: "text-green-600",
    bgColor: "bg-green-50",
    borderColor: "border-green-200",
  },
  sauces: {
    label: "Signature Sauces",
    icon: Droplet,
    color: "text-amber-600",
    bgColor: "bg-amber-50",
    borderColor: "border-amber-200",
  },
  extras: {
    label: "Premium Extras",
    icon: Sparkles,
    color: "text-purple-600",
    bgColor: "bg-purple-50",
    borderColor: "border-purple-200",
  },
};

const IngredientManagement = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { hasPermission } = useAuth();
  const [ingredients, setIngredients] = useState<IngredientTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState<string>("all");
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [editingIngredient, setEditingIngredient] = useState<IngredientTemplate | null>(null);
  const [formData, setFormData] = useState({
    name: "",
    category: "extras",
    is_active: true,
    portion_pricing: {
      none: 0,
      light: 0,
      regular: 0,
      extra: 0,
    },
    default_portion: "regular",
  });

  useEffect(() => {
    fetchIngredients();
  }, []);

  const fetchIngredients = async () => {
    try {
      const { data, error } = await supabase
        .from("ingredient_templates")
        .select("*")
        .order("category")
        .order("display_order")
        .order("name");

      if (error) throw error;

      // Deduplicate by name + category
      const seen = new Set<string>();
      const uniqueIngredients = (data || []).filter((ing) => {
        const key = `${ing.name}-${ing.category}`;
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      });

      setIngredients(uniqueIngredients);
    } catch (err) {
      console.error("Error fetching ingredients:", err);
      toast({
        title: "Error",
        description: "Failed to load ingredients",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (ingredient: IngredientTemplate) => {
    setEditingIngredient(ingredient);
    setFormData({
      name: ingredient.name,
      category: ingredient.category,
      is_active: ingredient.is_active,
      portion_pricing: ingredient.portion_pricing || { none: 0, light: 0, regular: 0, extra: 0 },
      default_portion: ingredient.default_portion || "regular",
    });
    setEditDialogOpen(true);
  };

  const handleCreate = () => {
    setEditingIngredient(null);
    setFormData({
      name: "",
      category: "extras",
      is_active: true,
      portion_pricing: { none: 0, light: 0, regular: 0, extra: 0 },
      default_portion: "regular",
    });
    setEditDialogOpen(true);
  };

  const handleSave = async () => {
    if (!formData.name.trim()) {
      toast({ title: "Error", description: "Name is required", variant: "destructive" });
      return;
    }

    try {
      if (editingIngredient) {
        // Update existing
        const { error } = await supabase
          .from("ingredient_templates")
          .update({
            name: formData.name,
            category: formData.category,
            is_active: formData.is_active,
            portion_pricing: formData.portion_pricing,
            default_portion: formData.default_portion,
          })
          .eq("id", editingIngredient.id);

        if (error) throw error;
        toast({ title: "Success", description: "Ingredient updated successfully" });
      } else {
        // Create new
        const maxOrder = Math.max(...ingredients.filter(i => i.category === formData.category).map(i => i.display_order || 0), 0);
        const { error } = await supabase.from("ingredient_templates").insert({
          name: formData.name,
          category: formData.category,
          is_active: formData.is_active,
          portion_pricing: formData.portion_pricing,
          default_portion: formData.default_portion,
          supports_portions: true,
          display_order: maxOrder + 1,
        });

        if (error) throw error;
        toast({ title: "Success", description: "Ingredient created successfully" });
      }

      setEditDialogOpen(false);
      fetchIngredients();
    } catch (err) {
      console.error("Error saving ingredient:", err);
      toast({
        title: "Error",
        description: err instanceof Error ? err.message : "Failed to save ingredient",
        variant: "destructive",
      });
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Are you sure you want to delete this ingredient? This cannot be undone.")) {
      return;
    }

    try {
      const { error } = await supabase.from("ingredient_templates").delete().eq("id", id);
      if (error) throw error;

      toast({ title: "Success", description: "Ingredient deleted" });
      fetchIngredients();
    } catch (err) {
      console.error("Error deleting ingredient:", err);
      toast({
        title: "Error",
        description: "Failed to delete ingredient",
        variant: "destructive",
      });
    }
  };

  const handleToggleActive = async (ingredient: IngredientTemplate) => {
    try {
      const { error } = await supabase
        .from("ingredient_templates")
        .update({ is_active: !ingredient.is_active })
        .eq("id", ingredient.id);

      if (error) throw error;
      fetchIngredients();
    } catch (err) {
      console.error("Error toggling active:", err);
    }
  };

  const formatPrice = (price: number) => {
    if (price === 0) return "Free";
    return `$${price.toFixed(2)}`;
  };

  const hasPricing = (pricing: { none: number; light: number; regular: number; extra: number }) => {
    return pricing.light > 0 || pricing.regular > 0 || pricing.extra > 0;
  };

  // Filter ingredients
  const filteredIngredients = ingredients.filter((ing) => {
    const matchesSearch = ing.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory === "all" || ing.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  // Group by category
  const groupedIngredients = filteredIngredients.reduce((acc, ing) => {
    if (!acc[ing.category]) acc[ing.category] = [];
    acc[ing.category].push(ing);
    return acc;
  }, {} as Record<string, IngredientTemplate[]>);

  if (!hasPermission("menu")) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <p className="text-muted-foreground">You don't have permission to manage ingredients.</p>
      </div>
    );
  }

  return (
    <div className="container mx-auto p-6 max-w-7xl">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" onClick={() => navigate("/dashboard")}>
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <div>
            <h1 className="text-3xl font-bold">Ingredient Management</h1>
            <p className="text-muted-foreground">Manage ingredient templates and pricing</p>
          </div>
        </div>
        <Button onClick={handleCreate} className="gap-2">
          <Plus className="h-4 w-4" />
          Add Ingredient
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Ingredients</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">{ingredients.length}</p>
          </CardContent>
        </Card>
        {Object.entries(categoryConfig).map(([key, config]) => {
          const count = ingredients.filter((i) => i.category === key).length;
          const Icon = config.icon;
          return (
            <Card key={key} className={config.bgColor}>
              <CardHeader className="pb-2">
                <CardTitle className={`text-sm font-medium flex items-center gap-2 ${config.color}`}>
                  <Icon className="h-4 w-4" />
                  {config.label}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold">{count}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Filters */}
      <div className="flex gap-4 mb-6">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search ingredients..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
        <Select value={selectedCategory} onValueChange={setSelectedCategory}>
          <SelectTrigger className="w-[200px]">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Categories</SelectItem>
            <SelectItem value="vegetables">Vegetables</SelectItem>
            <SelectItem value="sauces">Sauces</SelectItem>
            <SelectItem value="extras">Premium Extras</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Ingredients by Category */}
      {loading ? (
        <div className="text-center py-12 text-muted-foreground">Loading ingredients...</div>
      ) : (
        <div className="space-y-8">
          {Object.entries(groupedIngredients).map(([category, categoryIngredients]) => {
            const config = categoryConfig[category as keyof typeof categoryConfig];
            if (!config) return null;

            const Icon = config.icon;

            return (
              <Card key={category} className={`${config.borderColor} border-2`}>
                <CardHeader className={config.bgColor}>
                  <CardTitle className={`flex items-center gap-2 ${config.color}`}>
                    <Icon className="h-5 w-5" />
                    {config.label}
                    <Badge variant="secondary" className="ml-2">
                      {categoryIngredients.length}
                    </Badge>
                  </CardTitle>
                  <CardDescription>
                    {category === "extras"
                      ? "Charged ingredients - customers pay extra"
                      : "Standard ingredients - typically free"}
                  </CardDescription>
                </CardHeader>
                <CardContent className="p-0">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Name</TableHead>
                        <TableHead className="text-center">Light</TableHead>
                        <TableHead className="text-center">Regular</TableHead>
                        <TableHead className="text-center">Extra</TableHead>
                        <TableHead className="text-center">Active</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {categoryIngredients.map((ing) => (
                        <TableRow key={ing.id}>
                          <TableCell className="font-medium">
                            <div className="flex items-center gap-2">
                              {ing.name}
                              {hasPricing(ing.portion_pricing) && (
                                <Badge variant="outline" className="text-xs">
                                  <DollarSign className="h-3 w-3 mr-1" />
                                  Charged
                                </Badge>
                              )}
                            </div>
                          </TableCell>
                          <TableCell className="text-center">
                            <span className={ing.portion_pricing.light > 0 ? "text-green-600 font-medium" : "text-muted-foreground"}>
                              {formatPrice(ing.portion_pricing.light)}
                            </span>
                          </TableCell>
                          <TableCell className="text-center">
                            <span className={ing.portion_pricing.regular > 0 ? "text-green-600 font-medium" : "text-muted-foreground"}>
                              {formatPrice(ing.portion_pricing.regular)}
                            </span>
                          </TableCell>
                          <TableCell className="text-center">
                            <span className={ing.portion_pricing.extra > 0 ? "text-green-600 font-medium" : "text-muted-foreground"}>
                              {formatPrice(ing.portion_pricing.extra)}
                            </span>
                          </TableCell>
                          <TableCell className="text-center">
                            <Switch
                              checked={ing.is_active}
                              onCheckedChange={() => handleToggleActive(ing)}
                            />
                          </TableCell>
                          <TableCell className="text-right">
                            <div className="flex justify-end gap-2">
                              <Button variant="ghost" size="icon" onClick={() => handleEdit(ing)}>
                                <Pencil className="h-4 w-4" />
                              </Button>
                              <Button
                                variant="ghost"
                                size="icon"
                                className="text-destructive hover:text-destructive"
                                onClick={() => handleDelete(ing.id)}
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </CardContent>
              </Card>
            );
          })}

          {Object.keys(groupedIngredients).length === 0 && (
            <div className="text-center py-12 text-muted-foreground">
              No ingredients found matching your search.
            </div>
          )}
        </div>
      )}

      {/* Edit/Create Dialog */}
      <Dialog open={editDialogOpen} onOpenChange={setEditDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editingIngredient ? "Edit Ingredient" : "Add New Ingredient"}</DialogTitle>
            <DialogDescription>
              {editingIngredient
                ? "Update ingredient details and pricing"
                : "Create a new ingredient template"}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-6 py-4">
            {/* Name */}
            <div className="space-y-2">
              <Label htmlFor="name">Ingredient Name *</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="e.g., Extra Cheese, Bacon"
              />
            </div>

            {/* Category */}
            <div className="space-y-2">
              <Label>Category *</Label>
              <Select
                value={formData.category}
                onValueChange={(value) => setFormData({ ...formData, category: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="vegetables">
                    <span className="flex items-center gap-2">
                      <Salad className="h-4 w-4 text-green-600" />
                      Fresh Vegetables
                    </span>
                  </SelectItem>
                  <SelectItem value="sauces">
                    <span className="flex items-center gap-2">
                      <Droplet className="h-4 w-4 text-amber-600" />
                      Signature Sauces
                    </span>
                  </SelectItem>
                  <SelectItem value="extras">
                    <span className="flex items-center gap-2">
                      <Sparkles className="h-4 w-4 text-purple-600" />
                      Premium Extras
                    </span>
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Pricing */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label className="text-base font-semibold">Portion Pricing</Label>
                <Badge variant="outline">
                  <DollarSign className="h-3 w-3 mr-1" />
                  Set prices for each portion
                </Badge>
              </div>
              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="light-price" className="text-sm text-muted-foreground">
                    Light
                  </Label>
                  <div className="relative">
                    <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="light-price"
                      type="number"
                      step="0.25"
                      min="0"
                      value={formData.portion_pricing.light}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          portion_pricing: {
                            ...formData.portion_pricing,
                            light: parseFloat(e.target.value) || 0,
                          },
                        })
                      }
                      className="pl-8"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="regular-price" className="text-sm text-muted-foreground">
                    Regular
                  </Label>
                  <div className="relative">
                    <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="regular-price"
                      type="number"
                      step="0.25"
                      min="0"
                      value={formData.portion_pricing.regular}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          portion_pricing: {
                            ...formData.portion_pricing,
                            regular: parseFloat(e.target.value) || 0,
                          },
                        })
                      }
                      className="pl-8"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="extra-price" className="text-sm text-muted-foreground">
                    Extra
                  </Label>
                  <div className="relative">
                    <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="extra-price"
                      type="number"
                      step="0.25"
                      min="0"
                      value={formData.portion_pricing.extra}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          portion_pricing: {
                            ...formData.portion_pricing,
                            extra: parseFloat(e.target.value) || 0,
                          },
                        })
                      }
                      className="pl-8"
                    />
                  </div>
                </div>
              </div>
              <p className="text-xs text-muted-foreground">
                Set to $0.00 for free ingredients. Premium extras like cheese and bacon typically charge $1.50-$2.50.
              </p>
            </div>

            {/* Default Portion */}
            <div className="space-y-2">
              <Label>Default Portion</Label>
              <Select
                value={formData.default_portion}
                onValueChange={(value) => setFormData({ ...formData, default_portion: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">None (Not included by default)</SelectItem>
                  <SelectItem value="light">Light</SelectItem>
                  <SelectItem value="regular">Regular</SelectItem>
                  <SelectItem value="extra">Extra</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Active Toggle */}
            <div className="flex items-center justify-between">
              <div>
                <Label>Active</Label>
                <p className="text-sm text-muted-foreground">Show this ingredient in menu customization</p>
              </div>
              <Switch
                checked={formData.is_active}
                onCheckedChange={(checked) => setFormData({ ...formData, is_active: checked })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSave} className="gap-2">
              <Save className="h-4 w-4" />
              {editingIngredient ? "Save Changes" : "Create Ingredient"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default IngredientManagement;
