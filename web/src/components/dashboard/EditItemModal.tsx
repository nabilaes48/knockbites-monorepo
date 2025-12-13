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
import { X, Plus, Trash2, Package, DollarSign, Tag, Image, Sparkles, Check, Loader2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/lib/supabase";
import { cn } from "@/lib/utils";

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

interface CustomizationOption {
  label: string;
  price: number;
}

interface CustomizationGroup {
  id?: number;
  name: string;
  type: 'single' | 'multiple';
  options: CustomizationOption[];
  is_required: boolean;
  display_order: number;
}

interface Category {
  id: number;
  name: string;
}

interface EditItemModalProps {
  item: MenuItem | null;
  isOpen: boolean;
  onClose: () => void;
  onSave: () => void;
  categories: Category[];
}

export const EditItemModal = ({ item, isOpen, onClose, onSave, categories }: EditItemModalProps) => {
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
  const [customizations, setCustomizations] = useState<CustomizationGroup[]>([]);
  const [newTag, setNewTag] = useState("");
  const [newOptionInput, setNewOptionInput] = useState<{ [key: number]: string }>({});
  const [newOptionPrice, setNewOptionPrice] = useState<{ [key: number]: string }>({});

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
      fetchCustomizations(item.id);
    }
  }, [item, isOpen]);

  const fetchCustomizations = async (itemId: number) => {
    try {
      const { data, error } = await supabase
        .from('menu_item_customizations')
        .select('*')
        .eq('menu_item_id', itemId)
        .order('display_order');

      if (error) throw error;
      setCustomizations(data || []);
    } catch (err) {
      console.error('Error fetching customizations:', err);
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

  const handleAddCustomizationGroup = () => {
    const newGroup: CustomizationGroup = {
      name: "New Group",
      type: 'single',
      options: [],
      is_required: false,
      display_order: customizations.length,
    };
    setCustomizations([...customizations, newGroup]);
  };

  const handleRemoveCustomizationGroup = async (index: number) => {
    const group = customizations[index];

    // If it has an ID, delete from database
    if (group.id) {
      try {
        const { error } = await supabase
          .from('menu_item_customizations')
          .delete()
          .eq('id', group.id);

        if (error) throw error;
      } catch (err) {
        toast({
          title: "Error",
          description: "Failed to delete customization group",
          variant: "destructive",
        });
        return;
      }
    }

    setCustomizations(customizations.filter((_, i) => i !== index));
  };

  const handleUpdateCustomizationGroup = (index: number, field: string, value: string | boolean) => {
    const updated = [...customizations];
    updated[index] = { ...updated[index], [field]: value };
    setCustomizations(updated);
  };

  const handleAddOption = (groupIndex: number) => {
    const optionName = newOptionInput[groupIndex]?.trim();
    const optionPrice = parseFloat(newOptionPrice[groupIndex] || "0");

    if (!optionName) return;

    const updated = [...customizations];
    updated[groupIndex].options.push({
      label: optionName,
      price: isNaN(optionPrice) ? 0 : optionPrice,
    });
    setCustomizations(updated);

    // Clear inputs
    setNewOptionInput({ ...newOptionInput, [groupIndex]: "" });
    setNewOptionPrice({ ...newOptionPrice, [groupIndex]: "" });
  };

  const handleRemoveOption = (groupIndex: number, optionIndex: number) => {
    const updated = [...customizations];
    updated[groupIndex].options = updated[groupIndex].options.filter((_, i) => i !== optionIndex);
    setCustomizations(updated);
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

      // Save customizations
      for (const customization of customizations) {
        if (customization.id) {
          // Update existing
          const { error } = await supabase
            .from('menu_item_customizations')
            .update({
              name: customization.name,
              type: customization.type,
              options: customization.options,
              is_required: customization.is_required,
              display_order: customization.display_order,
            })
            .eq('id', customization.id);

          if (error) throw error;
        } else {
          // Insert new
          const { error } = await supabase
            .from('menu_item_customizations')
            .insert({
              menu_item_id: item.id,
              name: customization.name,
              type: customization.type,
              options: customization.options,
              is_required: customization.is_required,
              display_order: customization.display_order,
            });

          if (error) throw error;
        }
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
        description: "Failed to save menu item",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  if (!item) return null;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className={cn(
        "max-w-4xl max-h-[90vh] overflow-y-auto",
        // Light mode - Apple clean
        "bg-white/95 border-gray-200/80",
        // Dark mode - Glassmorphism
        "dark:bg-card/80 dark:backdrop-blur-xl dark:border-white/10",
        "dark:shadow-[0_0_50px_rgba(0,0,0,0.5)]"
      )}>
        {/* Header with gradient accent */}
        <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-ios-blue via-ios-purple to-ios-pink dark:from-neon-cyan dark:via-neon-purple dark:to-neon-pink" />

        <DialogHeader className="pt-2">
          <DialogTitle className={cn(
            "text-2xl font-semibold flex items-center gap-3",
            "text-gray-900 dark:text-white"
          )}>
            <div className={cn(
              "p-2 rounded-xl",
              "bg-ios-blue/10 text-ios-blue",
              "dark:bg-neon-cyan/20 dark:text-neon-cyan"
            )}>
              <Package className="h-5 w-5" />
            </div>
            Edit Menu Item
          </DialogTitle>
          <DialogDescription className="text-muted-foreground">
            Update item details and customization options
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6 py-4">
          {/* Basic Information Section */}
          <div className={cn(
            "p-4 rounded-xl",
            "bg-gray-50 border border-gray-200",
            "dark:bg-white/5 dark:border-white/10"
          )}>
            <h3 className="text-sm font-medium text-muted-foreground mb-4 flex items-center gap-2">
              <Package className="h-4 w-4" />
              Basic Information
            </h3>

            <div className="grid md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="name" className="text-foreground">Item Name *</Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g., Bacon, Egg & Cheese on a Bagel"
                  className={cn(
                    "bg-white border-gray-300",
                    "dark:bg-white/5 dark:border-white/20 dark:focus:border-neon-cyan"
                  )}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="price" className="text-foreground flex items-center gap-2">
                  <DollarSign className="h-3 w-3" />
                  Price *
                </Label>
                <Input
                  id="price"
                  type="number"
                  step="0.01"
                  min="0"
                  value={formData.base_price}
                  onChange={(e) => setFormData({ ...formData, base_price: parseFloat(e.target.value) })}
                  className={cn(
                    "bg-white border-gray-300",
                    "dark:bg-white/5 dark:border-white/20 dark:focus:border-neon-cyan"
                  )}
                />
              </div>
            </div>

            <div className="space-y-2 mt-4">
              <Label htmlFor="description" className="text-foreground">Description</Label>
              <Textarea
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                rows={3}
                placeholder="Describe your item..."
                className={cn(
                  "bg-white border-gray-300 resize-none",
                  "dark:bg-white/5 dark:border-white/20 dark:focus:border-neon-cyan"
                )}
              />
            </div>

            <div className="grid md:grid-cols-2 gap-4 mt-4">
              <div className="space-y-2">
                <Label htmlFor="category" className="text-foreground">Category *</Label>
                <Select
                  value={formData.category_id.toString()}
                  onValueChange={(value) => setFormData({ ...formData, category_id: parseInt(value) })}
                >
                  <SelectTrigger className={cn(
                    "bg-white border-gray-300",
                    "dark:bg-white/5 dark:border-white/20"
                  )}>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent className="dark:bg-card dark:border-white/10">
                    {categories.map((cat) => (
                      <SelectItem key={cat.id} value={cat.id.toString()}>
                        {cat.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="image_url" className="text-foreground flex items-center gap-2">
                  <Image className="h-3 w-3" />
                  Image URL
                </Label>
                <Input
                  id="image_url"
                  value={formData.image_url}
                  onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
                  placeholder="https://..."
                  className={cn(
                    "bg-white border-gray-300",
                    "dark:bg-white/5 dark:border-white/20 dark:focus:border-neon-cyan"
                  )}
                />
              </div>
            </div>
          </div>

          {/* Availability Switches */}
          <div className={cn(
            "flex gap-6 p-4 rounded-xl",
            "bg-gray-50 border border-gray-200",
            "dark:bg-white/5 dark:border-white/10"
          )}>
            <div className="flex items-center gap-3">
              <Switch
                id="available"
                checked={formData.is_available}
                onCheckedChange={(checked) => setFormData({ ...formData, is_available: checked })}
                className={cn(
                  "data-[state=checked]:bg-ios-green",
                  "dark:data-[state=checked]:bg-neon-green"
                )}
              />
              <Label htmlFor="available" className="text-foreground flex items-center gap-2">
                <Check className="h-4 w-4" />
                Available
              </Label>
            </div>
            <div className="flex items-center gap-3">
              <Switch
                id="featured"
                checked={formData.is_featured}
                onCheckedChange={(checked) => setFormData({ ...formData, is_featured: checked })}
                className={cn(
                  "data-[state=checked]:bg-ios-orange",
                  "dark:data-[state=checked]:bg-neon-orange"
                )}
              />
              <Label htmlFor="featured" className="text-foreground flex items-center gap-2">
                <Sparkles className="h-4 w-4" />
                Featured
              </Label>
            </div>
          </div>

          {/* Tags Section */}
          <div className={cn(
            "p-4 rounded-xl",
            "bg-gray-50 border border-gray-200",
            "dark:bg-white/5 dark:border-white/10"
          )}>
            <Label className="text-foreground flex items-center gap-2 mb-3">
              <Tag className="h-4 w-4" />
              Tags
            </Label>
            <div className="flex gap-2 flex-wrap mb-3">
              {formData.tags.map((tag) => (
                <Badge
                  key={tag}
                  variant="secondary"
                  className={cn(
                    "cursor-pointer transition-all",
                    "bg-ios-blue/10 text-ios-blue hover:bg-destructive hover:text-destructive-foreground",
                    "dark:bg-neon-cyan/20 dark:text-neon-cyan dark:hover:bg-destructive/80"
                  )}
                  onClick={() => handleRemoveTag(tag)}
                >
                  {tag}
                  <X className="h-3 w-3 ml-1" />
                </Badge>
              ))}
              {formData.tags.length === 0 && (
                <span className="text-sm text-muted-foreground">No tags added</span>
              )}
            </div>
            <div className="flex gap-2">
              <Input
                value={newTag}
                onChange={(e) => setNewTag(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddTag())}
                placeholder="Type tag and press Enter"
                className={cn(
                  "bg-white border-gray-300",
                  "dark:bg-white/5 dark:border-white/20"
                )}
              />
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={handleAddTag}
                className={cn(
                  "border-gray-300 hover:bg-ios-blue/10 hover:text-ios-blue hover:border-ios-blue",
                  "dark:border-white/20 dark:hover:bg-neon-cyan/20 dark:hover:text-neon-cyan dark:hover:border-neon-cyan"
                )}
              >
                <Plus className="h-4 w-4 mr-1" />
                Add
              </Button>
            </div>
          </div>

          {/* Customization Groups */}
          <div className={cn(
            "p-4 rounded-xl",
            "bg-gray-50 border border-gray-200",
            "dark:bg-white/5 dark:border-white/10"
          )}>
            <div className="flex items-center justify-between mb-4">
              <Label className="text-lg font-semibold text-foreground">Customization Options</Label>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={handleAddCustomizationGroup}
                className={cn(
                  "border-gray-300 hover:bg-ios-purple/10 hover:text-ios-purple hover:border-ios-purple",
                  "dark:border-white/20 dark:hover:bg-neon-purple/20 dark:hover:text-neon-purple dark:hover:border-neon-purple"
                )}
              >
                <Plus className="h-4 w-4 mr-1" />
                Add Group
              </Button>
            </div>

            <div className="space-y-4">
              {customizations.map((group, groupIndex) => (
                <div
                  key={groupIndex}
                  className={cn(
                    "rounded-xl p-4 space-y-3",
                    "bg-white border border-gray-200",
                    "dark:bg-white/5 dark:border-white/10"
                  )}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 grid md:grid-cols-3 gap-3">
                      <Input
                        value={group.name}
                        onChange={(e) => handleUpdateCustomizationGroup(groupIndex, 'name', e.target.value)}
                        placeholder="Group name (e.g., Bread, Size)"
                        className={cn(
                          "bg-gray-50 border-gray-300",
                          "dark:bg-white/5 dark:border-white/20"
                        )}
                      />
                      <Select
                        value={group.type}
                        onValueChange={(value) => handleUpdateCustomizationGroup(groupIndex, 'type', value)}
                      >
                        <SelectTrigger className={cn(
                          "bg-gray-50 border-gray-300",
                          "dark:bg-white/5 dark:border-white/20"
                        )}>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent className="dark:bg-card dark:border-white/10">
                          <SelectItem value="single">Single Choice</SelectItem>
                          <SelectItem value="multiple">Multiple Choice</SelectItem>
                        </SelectContent>
                      </Select>
                      <div className="flex items-center gap-2">
                        <Switch
                          checked={group.is_required}
                          onCheckedChange={(checked) => handleUpdateCustomizationGroup(groupIndex, 'is_required', checked)}
                          className="data-[state=checked]:bg-ios-orange dark:data-[state=checked]:bg-neon-orange"
                        />
                        <Label className="text-sm text-foreground">Required</Label>
                      </div>
                    </div>
                    <Button
                      type="button"
                      variant="outline"
                      size="icon"
                      className={cn(
                        "text-destructive hover:bg-destructive/10 hover:border-destructive",
                        "dark:hover:bg-destructive/20"
                      )}
                      onClick={() => handleRemoveCustomizationGroup(groupIndex)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>

                  {/* Options */}
                  <div className="space-y-2 pl-4 border-l-2 border-gray-200 dark:border-white/10">
                    <Label className="text-sm font-medium text-muted-foreground">Options:</Label>
                    <div className="flex gap-2 flex-wrap mb-2">
                      {group.options.map((option, optionIndex) => (
                        <Badge
                          key={optionIndex}
                          variant="outline"
                          className={cn(
                            "cursor-pointer transition-all",
                            "border-gray-300 hover:bg-destructive hover:text-destructive-foreground hover:border-destructive",
                            "dark:border-white/20 dark:hover:bg-destructive/80"
                          )}
                          onClick={() => handleRemoveOption(groupIndex, optionIndex)}
                        >
                          {option.label} {option.price > 0 && `+$${option.price.toFixed(2)}`}
                          <X className="h-3 w-3 ml-1" />
                        </Badge>
                      ))}
                      {group.options.length === 0 && (
                        <span className="text-sm text-muted-foreground">No options added</span>
                      )}
                    </div>
                    <div className="flex gap-2">
                      <Input
                        value={newOptionInput[groupIndex] || ""}
                        onChange={(e) => setNewOptionInput({ ...newOptionInput, [groupIndex]: e.target.value })}
                        onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddOption(groupIndex))}
                        placeholder="Option name"
                        className={cn(
                          "flex-1 bg-gray-50 border-gray-300",
                          "dark:bg-white/5 dark:border-white/20"
                        )}
                      />
                      <Input
                        type="number"
                        step="0.01"
                        min="0"
                        value={newOptionPrice[groupIndex] || ""}
                        onChange={(e) => setNewOptionPrice({ ...newOptionPrice, [groupIndex]: e.target.value })}
                        onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddOption(groupIndex))}
                        placeholder="Price"
                        className={cn(
                          "w-24 bg-gray-50 border-gray-300",
                          "dark:bg-white/5 dark:border-white/20"
                        )}
                      />
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => handleAddOption(groupIndex)}
                        className={cn(
                          "border-gray-300 hover:bg-ios-green/10 hover:text-ios-green hover:border-ios-green",
                          "dark:border-white/20 dark:hover:bg-neon-green/20 dark:hover:text-neon-green dark:hover:border-neon-green"
                        )}
                      >
                        <Plus className="h-4 w-4 mr-1" />
                        Add
                      </Button>
                    </div>
                  </div>
                </div>
              ))}

              {customizations.length === 0 && (
                <div className={cn(
                  "text-center py-8 rounded-xl border-2 border-dashed",
                  "border-gray-300 text-muted-foreground",
                  "dark:border-white/20"
                )}>
                  <Package className="h-8 w-8 mx-auto mb-2 opacity-50" />
                  <p className="text-sm">No customization options yet.</p>
                  <p className="text-xs">Click "Add Group" to create one.</p>
                </div>
              )}
            </div>
          </div>
        </div>

        <DialogFooter className="gap-2 pt-4 border-t border-gray-200 dark:border-white/10">
          <Button
            variant="outline"
            onClick={onClose}
            disabled={loading}
            className={cn(
              "border-gray-300 hover:bg-gray-100",
              "dark:border-white/20 dark:hover:bg-white/10"
            )}
          >
            Cancel
          </Button>
          <Button
            onClick={handleSave}
            disabled={loading}
            className={cn(
              "bg-ios-blue hover:bg-ios-blue/90 text-white",
              "dark:bg-gradient-to-r dark:from-neon-cyan dark:to-neon-blue dark:hover:opacity-90",
              "dark:shadow-[0_0_20px_rgba(0,255,255,0.3)]"
            )}
          >
            {loading ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Saving...
              </>
            ) : (
              <>
                <Check className="h-4 w-4 mr-2" />
                Save Changes
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
