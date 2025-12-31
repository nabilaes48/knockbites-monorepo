import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { supabase } from "@/lib/supabase";
import { Salad, Droplet, Plus, Sparkles } from "lucide-react";
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";

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
  vegetables: {
    label: "Fresh Vegetables",
    icon: Salad,
    color: "text-green-500",
    bgColor: "bg-green-950/50",
    borderColor: "border-green-700",
  },
  sauces: {
    label: "Signature Sauces",
    icon: Droplet,
    color: "text-amber-500",
    bgColor: "bg-amber-950/50",
    borderColor: "border-amber-700",
  },
  extras: {
    label: "Premium Extras",
    icon: Sparkles,
    color: "text-purple-500",
    bgColor: "bg-purple-950/50",
    borderColor: "border-purple-700",
  },
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

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <Label className="text-base font-semibold">Quick Add Ingredients</Label>
        <Badge variant="outline" className="text-xs">
          {selectedTemplates.length} selected
        </Badge>
      </div>

      <Accordion type="multiple" className="w-full space-y-2">
        {Object.entries(groupedTemplates).map(([category, categoryTemplates]) => {
          const config = categoryConfig[category as keyof typeof categoryConfig];
          if (!config) return null;

          const Icon = config.icon;
          const selectedInCategory = categoryTemplates.filter((t) =>
            selectedTemplates.includes(t.id)
          ).length;

          return (
            <AccordionItem
              key={category}
              value={category}
              className={`border-2 ${config.borderColor} ${config.bgColor} rounded-lg overflow-hidden`}
            >
              <AccordionTrigger className="px-4 hover:no-underline">
                <div className="flex items-center gap-3 flex-1">
                  <Icon className={`h-5 w-5 ${config.color}`} />
                  <span className="font-semibold">{config.label}</span>
                  <Badge variant="secondary" className="ml-auto mr-2">
                    {selectedInCategory}/{categoryTemplates.length}
                  </Badge>
                </div>
              </AccordionTrigger>
              <AccordionContent className="px-4 pb-4">
                <div className="grid grid-cols-2 gap-2 pt-2">
                  {categoryTemplates.map((template) => {
                    const isSelected = selectedTemplates.includes(template.id);
                    const hasPricing = Object.values(template.portion_pricing).some(
                      (price) => price > 0
                    );

                    return (
                      <div
                        key={template.id}
                        className="flex items-center space-x-2 p-2 border rounded hover:bg-muted/50 transition-colors"
                      >
                        <Checkbox
                          id={`template-${template.id}`}
                          checked={isSelected}
                          onCheckedChange={() => onToggleTemplate(template.id, template)}
                        />
                        <Label
                          htmlFor={`template-${template.id}`}
                          className="flex-1 cursor-pointer text-sm"
                        >
                          <div className="flex items-center gap-2">
                            <span>{template.name}</span>
                            {hasPricing && (
                              <Badge variant="outline" className="text-xs">
                                $$
                              </Badge>
                            )}
                          </div>
                        </Label>
                      </div>
                    );
                  })}
                </div>
              </AccordionContent>
            </AccordionItem>
          );
        })}
      </Accordion>

      {Object.keys(groupedTemplates).length === 0 && (
        <div className="text-center py-8 text-sm text-muted-foreground">
          No ingredient templates available. Contact your administrator.
        </div>
      )}
    </div>
  );
};
