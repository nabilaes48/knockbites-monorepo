# Menu Item Photo Upload Guide

This guide will help you upload individual photos for all 61 menu items.

## Folder Structure

```
public/images/menu/items/
├── breakfast/
├── signature-sandwiches/
├── classic-sandwiches/
├── burgers/
└── munchies/
```

## Photo Requirements

- **Format**: JPG or PNG (JPG recommended for smaller file size)
- **Size**: 800x600px minimum, 1200x900px recommended
- **Quality**: High resolution, well-lit photos
- **Background**: Preferably clean or neutral background
- **Naming**: Use lowercase with hyphens (e.g., `shack-attack-aka-jimmy.jpg`)

## Upload Instructions

### Option 1: Upload via File Manager
1. Take high-quality photos of each menu item
2. Rename photos according to the suggested filenames below
3. Place photos in the appropriate category folder
4. Run the update script to sync with database

### Option 2: Bulk Upload
1. Place all photos in a single folder with correct names
2. I'll provide a script to organize and update the database

---

## BREAKFAST ITEMS (11 items)

| Item Name | Suggested Filename | Price |
|-----------|-------------------|-------|
| Two Eggs with Cheese | `two-eggs-with-cheese.jpg` | $4.99 |
| Two Eggs with Choice of Meat & Cheese | `two-eggs-meat-cheese.jpg` | $5.99 |
| Three Egg Omelette with Meat & Cheese | `three-egg-omelette.jpg` | $7.99 |
| Bacon, Egg & Cheese on a Bagel | `bacon-egg-cheese-bagel.jpg` | $6.49 |
| Bacon, Egg & Cheese w/ Hash Brown on a Fresh Croissant | `bacon-egg-cheese-croissant.jpg` | $8.99 |
| Shack Attack AKA Jimmy | `shack-attack-aka-jimmy.jpg` | $11.99 |
| Grilled Cheese | `grilled-cheese.jpg` | $5.99 |
| BLT | `blt.jpg` | $6.99 |
| Hash Browns | `hash-browns.jpg` | $1.99 |
| French Toast Sticks (8pc) | `french-toast-sticks.jpg` | $7.99 |
| Western Omelet | `western-omelet.jpg` | $7.99 |

## SIGNATURE SANDWICHES (24 items)

| Item Name | Suggested Filename | Price |
|-----------|-------------------|-------|
| Cluck'en Russian® | `clucken-russian.jpg` | $9.99 |
| Cluck'en Ranch® | `clucken-ranch.jpg` | $9.99 |
| Cluck'en Club® | `clucken-club.jpg` | $9.99 |
| No Way Jose | `no-way-jose.jpg` | $9.99 |
| Buffalo Blu | `buffalo-blu.jpg` | $9.99 |
| Sicilian Supreme | `sicilian-supreme.jpg` | $9.99 |
| Cam's Spicy Chicken | `cams-spicy-chicken.jpg` | $9.99 |
| Texas Ranger | `texas-ranger.jpg` | $9.99 |
| Chopped Cheese | `chopped-cheese.jpg` | $9.99 |
| Tuscany | `tuscany.jpg` | $9.99 |
| Mrs. I | `mrs-i.jpg` | $9.99 |
| Godfather | `godfather.jpg` | $9.99 |
| Rachel | `rachel.jpg` | $9.99 |
| Big Joe | `big-joe.jpg` | $9.99 |
| Pastrami Bomb | `pastrami-bomb.jpg` | $9.99 |
| Cam's Sausage & Pepper Sub | `cams-sausage-pepper-sub.jpg` | $9.99 |
| Thanksgiving | `thanksgiving.jpg` | $9.99 |
| The Rocket Man | `rocket-man.jpg` | $9.99 |
| Cajun Chicken | `cajun-chicken.jpg` | $9.99 |
| Godmother | `godmother.jpg` | $9.99 |
| Anthony's A.K.A | `anthonys-aka.jpg` | $9.99 |
| Williamsburg Cutlet | `williamsburg-cutlet.jpg` | $9.99 |
| Chicken Caesar Wrap | `chicken-caesar-wrap.jpg` | $9.99 |
| Buffalo Chicken Wrap | `buffalo-chicken-wrap.jpg` | $9.99 |

## CLASSIC SANDWICHES (12 items)

| Item Name | Suggested Filename | Price |
|-----------|-------------------|-------|
| Chicken Cutlet | `chicken-cutlet.jpg` | $9.99 |
| Reuben | `reuben.jpg` | $11.99 |
| Philly Cheesesteak | `philly-cheesesteak.jpg` | $11.99 |
| Meatball Parmessan | `meatball-parmesan.jpg` | $10.99 |
| Captain Tuna | `captain-tuna.jpg` | $9.99 |
| Chicken Parmesan | `chicken-parmesan.jpg` | $9.99 |
| The Cross River Club | `cross-river-club.jpg` | $10.99 |
| Italian Combo | `italian-combo.jpg` | $10.99 |
| Ranchero Chicken Wrap | `ranchero-chicken-wrap.jpg` | $10.99 |
| American Combo | `american-combo.jpg` | $10.99 |
| Buffalo Chicken Wrap | `buffalo-chicken-wrap-classic.jpg` | $10.99 |
| Cheese Burger | `cheese-burger-sandwich.jpg` | $10.99 |

## BURGERS (3 items)

| Item Name | Suggested Filename | Price |
|-----------|-------------------|-------|
| Cheeseburger | `cheeseburger.jpg` | $10.99 |
| Cheeseburger Deluxe | `cheeseburger-deluxe.jpg` | $12.99 |
| Garden Burger | `garden-burger.jpg` | $9.99 |

## MUNCHIES (11 items)

| Item Name | Suggested Filename | Price |
|-----------|-------------------|-------|
| Wings (6pc) | `wings-6pc.jpg` | $7.99 |
| Wings (12pc) | `wings-12pc.jpg` | $14.99 |
| Mozzarella Sticks (6pc) | `mozzarella-sticks.jpg` | $6.99 |
| Chicken Tenders (3pc) with Fries | `chicken-tenders-3pc.jpg` | $7.99 |
| Mac n Cheese Bites (6pc) | `mac-cheese-bites.jpg` | $6.99 |
| Jalapeno Poppers (6pc) | `jalapeno-poppers.jpg` | $7.99 |
| Mac & Cheese Bites (6pc) | `mac-cheese-bites-alt.jpg` | $6.99 |
| French Fries or Curly Fries | `french-fries.jpg` | $4.99 |
| Onion Rings | `onion-rings.jpg` | $5.99 |
| Hot Soup (Sm) | `hot-soup-small.jpg` | $3.99 |
| Hot Soup (Lg) | `hot-soup-large.jpg` | $7.99 |

---

## After You Upload Photos

Once you've added photos to the folders, let me know and I'll:

1. **Create an update script** to scan the folders and update image_url in the database
2. **Add fallback images** for items that don't have photos yet
3. **Optimize images** for web performance (compress, resize if needed)

## Temporary Placeholder

Until you upload photos, I can add category-specific placeholder images so the menu looks polished.

**Next Steps:**
1. Take photos of your menu items
2. Rename them according to the suggested filenames
3. Place them in the appropriate category folder
4. Let me know when ready, and I'll sync them with the database
