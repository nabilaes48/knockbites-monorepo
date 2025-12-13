# Portion-Based Customization System

## 🎯 Overview

A modern, intuitive ingredient customization system that allows customers to choose portion levels (None, Light, Regular, Extra) for ingredients like vegetables, sauces, and premium extras.

## ✨ Key Features

### For Customers
- **Visual Portion Selectors**: Easy-to-use buttons with icons (○ ◔ ◑ ●)
- **Organized Categories**:
  - 🥗 Fresh Vegetables (Lettuce, Tomato, Onion, Pickles)
  - 🥫 Signature Sauces (Chipotle Mayo, Mayo, Russian Dressing, Ketchup, Mustard, Hot Sauce)
  - ✨ Premium Extras (Extra Cheese, Bacon, Avocado) - with pricing
- **Real-time Price Updates**: See total cost update as you customize
- **Smart Defaults**: Common ingredients pre-selected at "Regular" level

### For Admin/Staff
- **Quick Template System**: Apply common ingredients with one click
- **Category-Based Organization**: Templates grouped by type
- **Flexible Pricing**: Set different prices for different portion levels
- **Batch Apply**: Add all vegetables or all sauces at once

## 📁 File Structure

```
src/
├── components/
│   ├── ui/
│   │   └── PortionSelector.tsx          # Portion level picker (None/Light/Regular/Extra)
│   ├── dashboard/
│   │   ├── EditItemModalV2.tsx          # Modern admin edit modal with tabs
│   │   └── IngredientTemplateSelector.tsx # Quick-apply ingredient templates
│   └── order/
│       └── ItemCustomizationModalV2.tsx # Customer-facing customization

supabase/migrations/
└── 042_portion_based_customizations.sql # Database schema
```

## 🗄️ Database Schema

### New Table: `ingredient_templates`
Stores reusable ingredient templates (e.g., Lettuce, Mayo, Bacon).

```sql
- id: Unique identifier
- name: Ingredient name (e.g., "Lettuce")
- category: Type ('vegetables', 'sauces', 'extras')
- supports_portions: Boolean (always true for ingredients)
- portion_pricing: JSONB {"none": 0, "light": 0, "regular": 0, "extra": 0.50}
- default_portion: Default selection ('none', 'light', 'regular', 'extra')
- display_order: Sort order within category
- is_active: Can be used/shown
```

### Enhanced: `menu_item_customizations`
Added new columns for portion support:

```sql
- supports_portions: Boolean flag
- portion_pricing: JSONB price per level
- default_portion: Default selection
- category: Ingredient category
```

## 🚀 How to Use

### Step 1: Run the Migration

Execute the migration in Supabase SQL Editor:
```bash
supabase/migrations/042_portion_based_customizations.sql
```

This will:
- Add new columns to `menu_item_customizations`
- Create `ingredient_templates` table
- Insert 13 default ingredients (vegetables, sauces, extras)
- Set up RLS policies

### Step 2: Admin - Add Ingredients to Menu Items

1. Go to Dashboard → Menu Management
2. Click Edit on any menu item
3. Click "Ingredients" tab
4. Expand categories (Fresh Vegetables, Signature Sauces, Premium Extras)
5. Check ingredients to add them
6. Click "Save Changes"

**Example**: For a sandwich, you might select:
- ✅ All Fresh Vegetables (Lettuce, Tomato, Onion, Pickles)
- ✅ Chipotle Mayo, Mayo, Mustard
- ✅ Extra Cheese, Bacon (premium)

### Step 3: Customer - Order with Customizations

1. Browse menu and click an item
2. Customization modal opens automatically if item has ingredients
3. See ingredients grouped by category
4. For each ingredient, select portion: ○ None | ◔ Light | ◑ Regular | ● Extra
5. Premium extras show pricing: "Extra Cheese +$1.00"
6. Total price updates in real-time
7. Click "Add to Cart"

## 💡 Portion Levels Explained

| Level | Icon | Meaning | Typical Use |
|-------|------|---------|-------------|
| None | ○ | Exclude completely | Don't want this ingredient |
| Light | ◔ | Small amount (25%) | Just a little bit |
| Regular | ◑ | Standard amount (50%) | Normal serving |
| Extra | ● | Generous amount (100%) | Extra serving (may cost more) |

## 💰 Pricing Examples

### Free Ingredients (Vegetables & Sauces)
```json
{
  "none": 0,
  "light": 0,
  "regular": 0,
  "extra": 0
}
```

### Premium Extras (Charged)
```json
// Extra Cheese
{
  "none": 0,
  "light": 0.75,
  "regular": 1.00,
  "extra": 1.50
}

// Bacon
{
  "none": 0,
  "light": 1.00,
  "regular": 1.50,
  "extra": 2.00
}
```

## 📋 Default Ingredient Templates

### 🥗 Fresh Vegetables (Free)
1. Lettuce
2. Tomato
3. Onion
4. Pickles

### 🥫 Signature Sauces (Free)
1. Chipotle Mayo
2. Mayo
3. Russian Dressing
4. Ketchup
5. Mustard
6. Hot Sauce

### ✨ Premium Extras (Charged)
1. Extra Cheese ($0.75 - $1.50)
2. Bacon ($1.00 - $2.00)
3. Avocado ($1.50 - $2.50)

## 🎨 UI/UX Design

### Customer Modal Layout
```
┌─────────────────────────────────────┐
│ Bacon, Egg & Cheese Sandwich        │
│ Fresh breakfast sandwich on a roll  │
│ [Image]                              │
│ Base: $6.49                          │
├─────────────────────────────────────┤
│ 🥗 Fresh Vegetables                  │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│ Lettuce                              │
│ ○ None  ◔ Light  ◑ Regular  ● Extra │
│                                      │
│ Tomato                               │
│ ○ None  ◔ Light  ◑ Regular  ● Extra │
├─────────────────────────────────────┤
│ 🥫 Signature Sauces                  │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│ Chipotle Mayo                        │
│ ○ None  ◔ Light  ◑ Regular  ● Extra │
├─────────────────────────────────────┤
│ ✨ Premium Extras                    │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│ Extra Cheese          +$1.00         │
│ ○ None  ◔ Light  ◑ Regular  ● Extra │
├─────────────────────────────────────┤
│ Special Instructions                 │
│ [Text area]                          │
├─────────────────────────────────────┤
│ Quantity: [-] 1 [+]                  │
├─────────────────────────────────────┤
│ [Cancel] [Add to Cart - $7.49] 🛒    │
└─────────────────────────────────────┘
```

### Admin Modal Layout
```
┌─────────────────────────────────────┐
│ Edit Menu Item                       │
│ ┌───────────────────────────────┐   │
│ │ [Item Details] [Ingredients]  │   │
│ └───────────────────────────────┘   │
│                                      │
│ INGREDIENTS TAB:                     │
│                                      │
│ Quick Add Ingredients    [3 selected]│
│                                      │
│ ▼ 🥗 Fresh Vegetables        [4/4]  │
│   ☑ Lettuce    ☑ Tomato              │
│   ☑ Onion      ☑ Pickles             │
│                                      │
│ ▼ 🥫 Signature Sauces        [2/6]  │
│   ☑ Chipotle Mayo  ☐ Mayo            │
│   ☐ Russian        ☐ Ketchup         │
│                                      │
│ ▼ ✨ Premium Extras         [1/3] $$ │
│   ☑ Extra Cheese   ☐ Bacon           │
│   ☐ Avocado                          │
│                                      │
│ Active Ingredients (7):              │
│ [Lettuce] [Tomato] [Onion]...        │
│                                      │
│ [Cancel] [💾 Save Changes]           │
└─────────────────────────────────────┘
```

## 🔧 Customization & Extension

### Adding New Ingredient Templates

```sql
INSERT INTO ingredient_templates
  (name, category, portion_pricing, display_order)
VALUES
  ('Jalapeños', 'vegetables',
   '{"none": 0, "light": 0, "regular": 0, "extra": 0}'::jsonb,
   5);
```

### Creating Custom Pricing

```sql
-- Premium Guacamole with tiered pricing
INSERT INTO ingredient_templates
  (name, category, portion_pricing, display_order)
VALUES
  ('Guacamole', 'extras',
   '{"none": 0, "light": 1.50, "regular": 2.50, "extra": 3.50}'::jsonb,
   25);
```

## 🎯 Benefits

### For Customers
- **Precision Control**: Exact portion preferences
- **Clear Pricing**: See costs before ordering
- **Flexibility**: Customize every ingredient
- **Speed**: Quick selection with visual buttons

### For Business
- **Upsell Opportunities**: Premium extras with pricing
- **Reduced Waste**: Accurate portion control
- **Customer Satisfaction**: Get exactly what they want
- **Operational Efficiency**: Standardized portions

## 🔐 Security

- RLS (Row Level Security) enabled on all tables
- Public can view active templates
- Only authenticated staff can manage templates
- Super admins, admins, and managers have full access

## 📊 Analytics Potential

Track popular customizations:
- Most requested portion levels
- Popular ingredient combinations
- Premium extra conversion rates
- Regional preferences

## 🚀 Next Steps

1. **Run Migration**: Execute `042_portion_based_customizations.sql`
2. **Test Admin Flow**: Add ingredients to a few menu items
3. **Test Customer Flow**: Order items with customizations
4. **Adjust Pricing**: Modify portion prices based on costs
5. **Add More Templates**: Create location-specific ingredients

## 📝 Notes

- This system replaces the old "Add-ons" approach with a more flexible portion-based model
- Old customization groups (non-portion) still work alongside this system
- Ingredients with `supports_portions = true` use the new UI
- Traditional customizations (sizes, etc.) use `supports_portions = false`

## 🎉 Result

A modern, professional ingredient customization system that rivals major food delivery platforms while giving you complete control over offerings and pricing!
