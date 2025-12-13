-- ============================================
-- UPDATE MENU IMAGES - Real Photos + Stock
-- Updates to use uploaded photos and Unsplash stock for missing items
-- ============================================

-- ============================================
-- BREAKFAST ITEMS - Real Photos
-- ============================================
UPDATE menu_items SET image_url = '/images/menu/items/breakfast/bacon-egg-cheese-bagel.jpg'
WHERE name = 'Bacon, Egg & Cheese on a Bagel';

UPDATE menu_items SET image_url = '/images/menu/items/breakfast/bacon-egg-cheese-croissant.jpg'
WHERE name = 'Bacon, Egg & Cheese w/ Hash Brown on a Fresh Croissant';

UPDATE menu_items SET image_url = '/images/menu/items/breakfast/shack-attack-aka-jimmy.jpg'
WHERE name = 'Shack Attack AKA Jimmy';

UPDATE menu_items SET image_url = '/images/menu/items/breakfast/french-toast-sticks.jpg'
WHERE name = 'French Toast Sticks (8pc)';

UPDATE menu_items SET image_url = '/images/menu/items/breakfast/western-omelet.jpg'
WHERE name = 'Western Omelet';

-- Breakfast - Stock Photos for items without uploads
UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800&h=600&fit=crop'
WHERE name = 'Two Eggs with Cheese';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=800&h=600&fit=crop'
WHERE name = 'Two Eggs with Choice of Meat & Cheese';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1612240498948-8e0b44a223f5?w=800&h=600&fit=crop'
WHERE name = 'Three Egg Omelette with Meat & Cheese';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=800&h=600&fit=crop'
WHERE name = 'Grilled Cheese';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1553909489-cd47e0907980?w=800&h=600&fit=crop'
WHERE name = 'BLT';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=800&h=600&fit=crop'
WHERE name = 'Hash Browns';

-- ============================================
-- SIGNATURE SANDWICHES - Real Photos (All 24)
-- ============================================
UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/clucken-russian.jpg.jpg'
WHERE name = 'Cluck''en Russian®';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/clucken-ranch.jpg'
WHERE name = 'Cluck''en Ranch®';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/clucken-club.jpg'
WHERE name = 'Cluck''en Club®';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/no-way-jose.jpg'
WHERE name = 'No Way Jose';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/buffalo-blu.jpg'
WHERE name = 'Buffalo Blu';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/sicilian-supreme.jpg'
WHERE name = 'Sicilian Supreme';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/cams-spicy-chicken.jpg'
WHERE name = 'Cam''s Spicy Chicken';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/texas-ranger.jpg'
WHERE name = 'Texas Ranger';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/chopped-cheese.jpg'
WHERE name = 'Chopped Cheese';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/tuscany.jpg'
WHERE name = 'Tuscany';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/mrs-i.jpg'
WHERE name = 'Mrs. I';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/beef_eater.jpg'
WHERE name = 'Beef Eater';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/healthy_bird.jpg'
WHERE name = 'Healthy Bird';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/turkey_dijon.jpg'
WHERE name = 'Turkey Dijon';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/chicken_stack.jpg'
WHERE name = 'Chicken Stack';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/wild_turkey\.jpg'
WHERE name = 'Wild Turkey';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/the_roma_wrap.jpg'
WHERE name = 'The Roma Wrap';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/slim_chicken_wrap.jpg'
WHERE name = 'Slim Chicken Wrap';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/yankee_peddler.jpg'
WHERE name = 'Yankee Peddler';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/mama_rose.jpg'
WHERE name = 'Mama Rosa';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/portobello_grove.jpg'
WHERE name = 'Portobello Grove';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/cajun_horse.jpg'
WHERE name = 'Cajun Horse';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/eggplanter.jpg'
WHERE name = 'Eggplanter';

UPDATE menu_items SET image_url = '/images/menu/items/signature-sandwiches/miss_virginia.jpg'
WHERE name = 'Miss Virginia';

-- ============================================
-- CLASSIC SANDWICHES - Real Photos (All 12)
-- ============================================
UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/chicken-cutlet.jpg'
WHERE name = 'Chicken Cutlet';

UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/reuben.jpg'
WHERE name = 'Reuben';

UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/philly-cheesesteak.jpg'
WHERE name = 'Philly Cheesesteak';

UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/meatball-parmesan.jpg'
WHERE name = 'Meatball Parmessan';

UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/captain-tuna.jpg'
WHERE name = 'Captain Tuna';

UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/chicken-parmesan.jpg'
WHERE name = 'Chicken Parmesan';

UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/cross-river-club.jpg'
WHERE name = 'The Cross River Club';

UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/italian-combo.jpg'
WHERE name = 'Italian Combo';

UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/american-combo.jpg'
WHERE name = 'American Combo';

UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/buffalo-chicken-wrap.jpg'
WHERE name = 'Buffalo Chicken Wrap';

UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/all_american.jpg'
WHERE name = 'All American';

UPDATE menu_items SET image_url = '/images/menu/items/classic-sandwiches/cheese-burger.jpg'
WHERE name = 'Cheese Burger';

-- ============================================
-- BURGERS - Stock Photos (No uploads yet)
-- ============================================
UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&h=600&fit=crop'
WHERE name = 'Cheeseburger' AND category_id = 4;

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=800&h=600&fit=crop'
WHERE name = 'Cheeseburger Deluxe';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1520072959219-c595dc870360?w=800&h=600&fit=crop'
WHERE name = 'Garden Burger';

-- ============================================
-- MUNCHIES - Stock Photos (No uploads yet)
-- ============================================
UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=800&h=600&fit=crop'
WHERE name = 'Wings (6pc)';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=800&h=600&fit=crop'
WHERE name = 'Wings (12pc)';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1548340748-6d2b7d7da280?w=800&h=600&fit=crop'
WHERE name = 'Mozzarella Sticks (6pc)';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1562967914-608f82629710?w=800&h=600&fit=crop'
WHERE name LIKE 'Chicken Tenders%';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1629998270451-4d3de6959a2a?w=800&h=600&fit=crop'
WHERE name LIKE 'Mac%Cheese Bites%';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1601004890684-d8cbf643f5f2?w=800&h=600&fit=crop'
WHERE name LIKE 'Jalapeno Poppers%';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=800&h=600&fit=crop'
WHERE name LIKE 'French Fries%' OR name LIKE 'Curly Fries%';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1639024471283-03518883512d?w=800&h=600&fit=crop'
WHERE name = 'Onion Rings';

UPDATE menu_items SET image_url = 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&h=600&fit=crop'
WHERE name LIKE 'Hot Soup%';

-- Verify updates
SELECT
  c.name as category,
  COUNT(*) as items,
  COUNT(CASE WHEN image_url LIKE '/images/menu/items/%' THEN 1 END) as real_photos,
  COUNT(CASE WHEN image_url LIKE 'https://images.unsplash%' THEN 1 END) as stock_photos
FROM menu_items m
JOIN menu_categories c ON m.category_id = c.id
GROUP BY c.name, c.display_order
ORDER BY c.display_order;
