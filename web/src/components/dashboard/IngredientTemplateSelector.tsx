import { useState, useEffect } from "react";
import { Badge } from "@/components/ui/badge";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { supabase } from "@/lib/supabase";
import { Salad, Droplet, Sparkles, DollarSign } from "lucide-react";

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
}

interface IngredientTemplateSelectorProps {
  selectedTemplates: number[];
  onToggleTemplate: (templateId: number, template: IngredientTemplate) => void;
}

const categoryConfig = {
  extras: {
    label: "Premium Extras",
    icon: Sparkles,
    color: "text-purple-600 dark:text-purple-400",
    bgColor: "bg-purple-50 dark:bg-purple-950/30",
    borderColor: "border-purple-200 dark:border-purple-800",
    description: "Charged ingredients - customers pay extra",
  },
  sauces: {
    label: "Signature Sauces",
    icon: Droplet,
    color: "text-amber-600 dark:text-amber-400",
    bgColor: "bg-amber-50 dark:bg-amber-950/30",
    borderColor: "border-amber-200 dark:border-amber-800",
    description: "Standard ingredients - typically free",
  },
  vegetables: {
    label: "Fresh Vegetables",
    icon: Salad,
    color: "text-green-600 dark:text-green-400",
    bgColor: "bg-green-50 dark:bg-green-950/30",
    borderColor: "border-green-200 dark:border-green-800",
    description: "Standard ingredients - typically free",
  },
};

const formatPrice = (price: number) => {
  if (price === 0) return "Free";
  return `$${price.toFixed(2)}`;
};

const hasPricing = (pricing: { none: number; light: number; regular: number; extra: number }) => {
  return pricing.light > 0 || pricing.regular > 0 || pricing.extra > 0;
};

export const IngredientTemplateSelector = ({
  selectedTemplates,
  onToggleTemplate,
}: IngredientTemplateSelectorProps) => {
  const [templates, setTemplates] = useState<IngredientTemplate[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchTemplates();
  }, []);

  const fetchTemplates = async () => {
    try {
      const { data, error } = await supabase
        .from('ingredient_templates')
        .select('*')
        .eq('is_active', true)
        .order('category')
        .order('display_order');

      if (error) throw error;

      // Deduplicate templates by name and category (keep first occurrence)
      const seen = new Set<string>();
      const uniqueTemplates = (data || []).filter((template) => {
        const key = `${template.name}-${template.category}`;
        if (seen.has(key)) {
          return false;
        }
        seen.add(key);
        return true;
      });

      setTemplates(uniqueTemplates);
    } catch (err) {
      console.error('Error fetching templates:', err);
    } finally {
      setLoading(false);
    }
  };

  const groupedTemplates = templates.reduce((acc, template) => {
    if (!acc[template.category]) {
      acc[template.category] = [];
    }
    acc[template.category].push(template);
    return acc;
  }, {} as Record<string, IngredientTemplate[]>);

  if (loading) {
    return (
      <div className="text-sm text-muted-foreground py-4">
        Loading ingredient templates...
      </div>
    );
  }

  // Order categories: extras first, then sauces, then vegetables
  const categoryOrder = ["extras", "sauces", "vegetables"];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <Label className="text-base font-semibold">Quick Add Ingredients</Label>
        <Badge variant="outline" className="text-xs">
          {selectedTemplates.length} selected
        </Badge>
      </div>

      <div className="space-y-4 max-h-[400px] overflow-y-auto pr-2">
        {categoryOrder.map((category) => {
          const categoryTemplates = groupedTemplates[category];
          if (!categoryTemplates?.length) return null;

          const config = categoryConfig[category as keyof typeof categoryConfig];
          if (!config) return null;

          const Icon = config.icon;
          const selectedInCategory = categoryTemplates.filter((t) =>
            selectedTemplates.includes(t.id)
          ).length;

          return (
            <Card key={category} className={`border-2 ${config.borderColor} ${config.bgColor}`}>
              <CardHeader className="py-3 px-4">
                <CardTitle className="flex items-center gap-2 text-base">
                  <Icon className={`h-5 w-5 ${config.color}`} />
                  <span className={config.color}>{config.label}</span>
                  <Badge variant="secondary" className="ml-auto">
                    {selectedInCategory}/{categoryTemplates.length}
                  </Badge>
                </CardTitle>
                <CardDescription className="text-xs">
                  {config.description}
                </CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                <Table>
                  <TableHeader>
                    <TableRow className="hover:bg-transparent">
                      <TableHead className="w-8"></TableHead>
                      <TableHead>Name</TableHead>
                      <TableHead className="text-center w-16">Light</TableHead>
                      <TableHead className="text-center w-16">Regular</TableHead>
                      <TableHead className="text-center w-16">Extra</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {categoryTemplates.map((template) => {
                      const isSelected = selectedTemplates.includes(template.id);
                      const isPremium = hasPricing(template.portion_pricing);

                      return (
                        <TableRow
                          key={template.id}
                          className={`cursor-pointer hover:bg-muted/50 ${isSelected ? "bg-primary/5" : ""}`}
                          onClick={() => onToggleTemplate(template.id, template)}
                        >
                          <TableCell className="py-2">
                            <Checkbox
                              checked={isSelected}
                              onCheckedChange={() => onToggleTemplate(template.id, template)}
                            />
                          </TableCell>
                          <TableCell className="py-2 font-medium">
                            <div className="flex items-center gap-2">
                              {template.name}
                              {isPremium && (
                                <Badge variant="outline" className="text-xs py-0">
                                  <DollarSign className="h-3 w-3 mr-0.5" />
                                  Charged
                                </Badge>
                              )}
                            </div>
                          </TableCell>
                          <TableCell className="text-center py-2">
                            <span className={template.portion_pricing.light > 0 ? "text-green-600 dark:text-green-400 font-medium" : "text-muted-foreground text-xs"}>
                              {formatPrice(template.portion_pricing.light)}
                            </span>
                          </TableCell>
                          <TableCell className="text-center py-2">
                            <span className={template.portion_pricing.regular > 0 ? "text-green-600 dark:text-green-400 font-medium" : "text-muted-foreground text-xs"}>
                              {formatPrice(template.portion_pricing.regular)}
                            </span>
                          </TableCell>
                          <TableCell className="text-center py-2">
                            <span className={template.portion_pricing.extra > 0 ? "text-green-600 dark:text-green-400 font-medium" : "text-muted-foreground text-xs"}>
                              {formatPrice(template.portion_pricing.extra)}
                            </span>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {Object.keys(groupedTemplates).length === 0 && (
        <div className="text-center py-8 text-sm text-muted-foreground">
          No ingredient templates available. Contact your administrator.
        </div>
      )}
    </div>
  );
};
