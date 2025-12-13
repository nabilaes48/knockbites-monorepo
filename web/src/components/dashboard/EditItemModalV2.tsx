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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { X, Plus, Save } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/lib/supabase";
import { IngredientTemplateSelector } from "./IngredientTemplateSelector";

interface MenuItem {
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

interface IngredientCustomization {
  id?: number;
  menu_item_id?: number;
  template_id?: number;
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
}

interface Category {
  id: number;
  name: string;
}

interface EditItemModalV2Props {
  item: MenuItem | null;
  isOpen: boolean;
  onClose: () => void;
  onSave: () => void;
  categories: Category[];
}

export const EditItemModalV2 = ({ item, isOpen, onClose, onSave, categories }: EditItemModalV2Props) => {
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    base_price: 0,
    category_id: 0,
    is_available: true,
    is_featured: false,
    image_url: "",
    tags: [] as string[],
  });
  const [ingredients, setIngredients] = useState<IngredientCustomization[]>([]);
  const [selectedTemplateIds, setSelectedTemplateIds] = useState<number[]>([]);
  const [newTag, setNewTag] = useState("");

  // Load item data and customizations
  useEffect(() => {
    if (item && isOpen) {
      setFormData({
        name: item.name,
        description: item.description,
        base_price: item.price,
        category_id: item.category_id,
        is_available: item.available,
        is_featured: item.featured,
        image_url: item.image_url,
        tags: item.tags || [],
      });
      fetchIngredients(item.id);
    }
  }, [item, isOpen]);

  const fetchIngredients = async (itemId: number) => {
    try {
      const { data, error } = await supabase
        .from('menu_item_customizations')
        .select('*')
        .eq('menu_item_id', itemId)
        .eq('supports_portions', true)
        .order('display_order');

      if (error) throw error;

      const loadedIngredients = (data || []).map((dbItem) => ({
        id: dbItem.id,
        menu_item_id: dbItem.menu_item_id,
        template_id: dbItem.template_id,
        name: dbItem.name,
        category: dbItem.category || 'extras',
        supports_portions: dbItem.supports_portions,
        portion_pricing: dbItem.portion_pricing || { none: 0, light: 0, regular: 0, extra: 0 },
        default_portion: dbItem.default_portion || 'regular',
        display_order: dbItem.display_order,
      }));

      setIngredients(loadedIngredients);
      setSelectedTemplateIds(loadedIngredients.filter((i) => i.template_id).map((i) => i.template_id as number));
    } catch (err) {
      console.error('Error fetching ingredients:', err);
    }
  };

  const handleAddTag = () => {
    if (newTag.trim() && !formData.tags.includes(newTag.trim())) {
      setFormData({ ...formData, tags: [...formData.tags, newTag.trim()] });
      setNewTag("");
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setFormData({ ...formData, tags: formData.tags.filter(tag => tag !== tagToRemove) });
  };

  const handleToggleTemplate = (templateId: number, template: { name: string; category: string; supports_portions: boolean; portion_pricing: { none: number; light: number; regular: number; extra: number }; default_portion: string }) => {
    const isSelected = selectedTemplateIds.includes(templateId);

    if (isSelected) {
      // Remove template
      setSelectedTemplateIds(selectedTemplateIds.filter(id => id !== templateId));
      setIngredients(ingredients.filter(ing => ing.template_id !== templateId));
    } else {
      // Add template
      setSelectedTemplateIds([...selectedTemplateIds, templateId]);
      const newIngredient: IngredientCustomization = {
        template_id: templateId,
        name: template.name,
        category: template.category,
        supports_portions: template.supports_portions,
        portion_pricing: template.portion_pricing,
        default_portion: template.default_portion,
        display_order: ingredients.length,
      };
      setIngredients([...ingredients, newIngredient]);
    }
  };

  const handleSave = async () => {
    if (!item) return;

    setLoading(true);
    try {
      // Update menu item
      const { error: itemError } = await supabase
        .from('menu_items')
        .update({
          name: formData.name,
          description: formData.description,
          base_price: formData.base_price,
          category_id: formData.category_id,
          is_available: formData.is_available,
          is_featured: formData.is_featured,
          image_url: formData.image_url,
          tags: formData.tags,
        })
        .eq('id', item.id);

      if (itemError) throw itemError;

      // Delete existing portion-based customizations
      const { error: deleteError } = await supabase
        .from('menu_item_customizations')
        .delete()
        .eq('menu_item_id', item.id)
        .eq('supports_portions', true);

      if (deleteError) throw deleteError;

      // Insert new ingredient customizations
      if (ingredients.length > 0) {
        const ingredientsToInsert = ingredients.map((ing, index) => ({
          menu_item_id: item.id,
          template_id: ing.template_id,
          name: ing.name,
          type: 'multiple', // Portions use multiple type
          category: ing.category,
          supports_portions: true,
          portion_pricing: ing.portion_pricing,
          default_portion: ing.default_portion,
          is_required: false,
          display_order: index,
          options: [], // Empty options for portion-based
        }));

        const { error: insertError } = await supabase
          .from('menu_item_customizations')
          .insert(ingredientsToInsert);

        if (insertError) throw insertError;
      }

      toast({
        title: "Success",
        description: "Menu item updated successfully",
      });

      onSave();
      onClose();
    } catch (err) {
      console.error('Error saving item:', err);
      toast({
        title: "Error",
        description: err instanceof Error ? err.message : "Failed to save menu item",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  if (!item) return null;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl">Edit Menu Item</DialogTitle>
          <DialogDescription>Update item details and customize ingredients</DialogDescription>
        </DialogHeader>

        <Tabs defaultValue="details" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="details">Item Details</TabsTrigger>
            <TabsTrigger value="ingredients">
              Ingredients
              {ingredients.length > 0 && (
                <Badge variant="secondary" className="ml-2">
                  {ingredients.length}
                </Badge>
              )}
            </TabsTrigger>
          </TabsList>

          <TabsContent value="details" className="space-y-6 mt-6">
            {/* Basic Information */}
            <div className="grid md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="name">Item Name *</Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g., Bacon, Egg & Cheese on a Bagel"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="price">Base Price *</Label>
                <Input
                  id="price"
                  type="number"
                  step="0.01"
                  min="0"
                  value={formData.base_price}
                  onChange={(e) => setFormData({ ...formData, base_price: parseFloat(e.target.value) })}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                rows={3}
                placeholder="Describe your item..."
              />
            </div>

            <div className="grid md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="category">Category *</Label>
                <Select
                  value={formData.category_id.toString()}
                  onValueChange={(value) => setFormData({ ...formData, category_id: parseInt(value) })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {categories.map((cat) => (
                      <SelectItem key={cat.id} value={cat.id.toString()}>
                        {cat.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="image_url">Image URL</Label>
                <Input
                  id="image_url"
                  value={formData.image_url}
                  onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
                  placeholder="https://..."
                />
              </div>
            </div>

            {/* Availability Switches */}
            <div className="flex gap-6">
              <div className="flex items-center gap-2">
                <Switch
                  id="available"
                  checked={formData.is_available}
                  onCheckedChange={(checked) => setFormData({ ...formData, is_available: checked })}
                />
                <Label htmlFor="available">Available</Label>
              </div>
              <div className="flex items-center gap-2">
                <Switch
                  id="featured"
                  checked={formData.is_featured}
                  onCheckedChange={(checked) => setFormData({ ...formData, is_featured: checked })}
                />
                <Label htmlFor="featured">Featured</Label>
              </div>
            </div>

            {/* Tags */}
            <div className="space-y-2">
              <Label>Tags</Label>
              <div className="flex gap-2 flex-wrap mb-2">
                {formData.tags.map((tag) => (
                  <Badge
                    key={tag}
                    variant="secondary"
                    className="cursor-pointer hover:bg-destructive hover:text-destructive-foreground transition-colors"
                    onClick={() => handleRemoveTag(tag)}
                  >
                    {tag}
                    <X className="h-3 w-3 ml-1" />
                  </Badge>
                ))}
              </div>
              <div className="flex gap-2">
                <Input
                  value={newTag}
                  onChange={(e) => setNewTag(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddTag())}
                  placeholder="Type tag and press Enter"
                />
                <Button type="button" variant="outline" size="sm" onClick={handleAddTag}>
                  <Plus className="h-4 w-4 mr-1" />
                  Add
                </Button>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="ingredients" className="space-y-6 mt-6">
            <IngredientTemplateSelector
              selectedTemplates={selectedTemplateIds}
              onToggleTemplate={handleToggleTemplate}
            />

            {ingredients.length > 0 && (
              <div className="mt-6 p-4 bg-muted/30 rounded-lg">
                <p className="text-sm font-semibold mb-2">Active Ingredients ({ingredients.length}):</p>
                <div className="flex gap-2 flex-wrap">
                  {ingredients.map((ing, idx) => (
                    <Badge key={idx} variant="outline">
                      {ing.name}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
          </TabsContent>
        </Tabs>

        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={loading}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={loading}>
            <Save className="h-4 w-4 mr-2" />
            {loading ? "Saving..." : "Save Changes"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
