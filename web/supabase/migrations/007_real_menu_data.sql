-- ============================================
-- REAL MENU DATA - Highland Mills Snack Shop Inc
-- Extracted from Cross River.pdf
-- ============================================

-- Clear existing sample menu items
DELETE FROM menu_items;
DELETE FROM menu_categories;

-- ============================================
-- INSERT REAL MENU CATEGORIES
-- ============================================
INSERT INTO menu_categories (id, name, description, display_order, is_active) VALUES
(1, 'Breakfast', 'Start your day right with fresh breakfast options', 1, true),
(2, 'Signature Sandwiches', 'Our famous signature creations', 2, true),
(3, 'Classic Sandwiches', 'Traditional favorites done right', 3, true),
(4, 'Burgers', '8oz Fresh Ground Angus Beef', 4, true),
(5, 'Munchies', 'Wings, sides, and snacks', 5, true);

-- Reset the sequence for menu_categories
SELECT setval('menu_categories_id_seq', (SELECT MAX(id) FROM menu_categories));

-- ============================================
-- BREAKFAST ITEMS
-- ============================================
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags, image_url) VALUES
(1, 'Two Eggs with Cheese', 'Two fresh eggs with your choice of cheese', 4.99, true, false, 6, ARRAY['breakfast', 'quick'], '/images/menu/page-0.png'),
(1, 'Two Eggs with Choice of Meat & Cheese', 'Two eggs with bacon, sausage, or ham and cheese', 5.99, true, false, 8, ARRAY['breakfast', 'protein'], '/images/menu/page-0.png'),
(1, 'Three Egg Omelette with Meat & Cheese', 'Hearty three-egg omelette with your choice of meat and cheese', 7.99, true, false, 10, ARRAY['breakfast', 'omelette'], '/images/menu/page-0.png'),
(1, 'Bacon, Egg & Cheese on a Bagel', 'Classic breakfast sandwich on a fresh bagel', 6.49, true, true, 8, ARRAY['breakfast', 'popular', 'bagel'], '/images/menu/page-0.png'),
(1, 'Bacon, Egg & Cheese w/ Hash Brown on a Fresh Croissant', 'Indulgent breakfast with crispy hash brown on buttery croissant', 8.99, true, true, 10, ARRAY['breakfast', 'premium', 'croissant'], '/images/menu/page-0.png'),
(1, 'Shack Attack AKA Jimmy', 'Bacon, Egg & Cheese Topped with a Chicken Cutlet and Hash Browns with Hot Sauce', 11.99, true, true, 12, ARRAY['breakfast', 'signature', 'spicy', 'hearty'], '/images/menu/page-0.png'),
(1, 'Grilled Cheese', 'Classic grilled cheese sandwich', 5.99, true, false, 6, ARRAY['breakfast', 'vegetarian', 'classic'], '/images/menu/page-0.png'),
(1, 'BLT', 'Crispy bacon, lettuce, and tomato', 6.99, true, false, 6, ARRAY['breakfast', 'classic'], '/images/menu/page-0.png'),
(1, 'Hash Browns', 'Golden crispy hash browns', 1.99, true, false, 5, ARRAY['breakfast', 'side'], '/images/menu/page-0.png'),
(1, 'French Toast Sticks (8pc)', 'Eight pieces of golden French toast sticks', 7.99, true, false, 10, ARRAY['breakfast', 'sweet'], '/images/menu/page-0.png'),
(1, 'Western Omelet', 'Ham, Peppers & Red Onions', 7.99, true, false, 10, ARRAY['breakfast', 'omelette', 'protein'], '/images/menu/page-0.png');

-- ============================================
-- SIGNATURE SANDWICHES (Roll/Wrap: $9.99, Wedge: +$2.49)
-- ============================================
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags, image_url) VALUES
(2, 'Cluck''en Russian®', 'Chicken Cutlet, Bacon, Melted Muenster Cheese & Russian Dressing on a Toasted Roll', 9.99, true, true, 10, ARRAY['signature', 'chicken', 'popular'], '/images/menu/page-1.png'),
(2, 'Cluck''en Ranch®', 'Chicken Cutlet, Bacon, Melted Cheddar Cheese & Ranch Dressing on a Toasted Roll', 9.99, true, false, 10, ARRAY['signature', 'chicken'], '/images/menu/page-1.png'),
(2, 'Cluck''en Club®', 'Blazing Buffalo® Chicken, Bacon, Pepper Jack, Lettuce, Tomato & Honey Dijon Stacked on Three Slices of Whole Wheat Toast', 9.99, true, true, 12, ARRAY['signature', 'chicken', 'spicy', 'club'], '/images/menu/page-1.png'),
(2, 'No Way Jose', 'Chicken Cutlet, Melted Cheddar Cheese, Lettuce, Hot or Sweet Peppers & Salsa on a Toasted Roll', 9.99, true, false, 10, ARRAY['signature', 'chicken', 'mexican'], '/images/menu/page-1.png'),
(2, 'Buffalo Blu', 'Chicken Cutlet, Melted Mozzarella, Deluxe Ham, Bleu Cheese & Buffalo Sauce on a Toasted Roll', 9.99, true, false, 10, ARRAY['signature', 'chicken', 'spicy'], '/images/menu/page-1.png'),
(2, 'Sicilian Supreme', 'Chicken Cutlet, Pepperoni, Melted Mozzarella Cheese & Roasted Peppers on a Toasted Roll', 9.99, true, false, 10, ARRAY['signature', 'chicken', 'italian'], '/images/menu/page-1.png'),
(2, 'Cam''s Spicy Chicken', 'Spicy Breaded Chicken Cutlet, Pepper Jack Cheese, Lettuce, Tomato, Pickles & Mayo on a Brioche Bun', 9.99, true, true, 10, ARRAY['signature', 'chicken', 'spicy', 'popular'], '/images/menu/page-2.png'),
(2, 'Texas Ranger', 'Breaded Chicken Cutlet with Melted Cheddar Cheese, Bacon & BBQ Sauce on a Toasted Roll', 9.99, true, false, 10, ARRAY['signature', 'chicken', 'bbq'], '/images/menu/page-2.png'),
(2, 'Chopped Cheese', 'Grilled Ground Beef & Cheese with Lettuce, Tomato & Onions', 9.99, true, true, 8, ARRAY['signature', 'beef', 'popular'], '/images/menu/page-2.png'),
(2, 'Tuscany', 'Breaded Chicken Cutlet, Prosciutto, Melted Mozzarella, Oil & Vinegar on a Toasted Roll', 9.99, true, false, 10, ARRAY['signature', 'chicken', 'italian'], '/images/menu/page-2.png'),
(2, 'Mrs. I', 'Grilled Pastrami, Melted Swiss Cheese, Onions & Mustard or Mayo on Rye Toast', 9.99, true, false, 10, ARRAY['signature', 'deli', 'grilled'], '/images/menu/page-2.png'),
(2, 'Beef Eater', 'Veal Cutlet, Melted Provolone Cheese, Bacon, Lettuce, Tomato & Mayo on a Toasted Roll', 9.99, true, false, 12, ARRAY['signature', 'veal'], '/images/menu/page-2.png'),
(2, 'Healthy Bird', 'Ovengold® Turkey, Gold Label Imported Swiss Cheese, Fresh Spinach & Honey Dijon on Whole Wheat Bread', 9.99, true, false, 8, ARRAY['signature', 'turkey', 'healthy'], '/images/menu/page-3.png'),
(2, 'Turkey Dijon', 'Maple Honey Turkey, Cracked Pepper Mill Turkey, Lettuce & Honey Dijon on Whole Wheat Bread', 9.99, true, false, 8, ARRAY['signature', 'turkey'], '/images/menu/page-3.png'),
(2, 'Chicken Stack', 'Chicken Salad, Bacon, Lettuce & Tomato Stacked on Three Slices of Toasted Whole Wheat Bread', 9.99, true, false, 10, ARRAY['signature', 'chicken', 'club'], '/images/menu/page-3.png'),
(2, 'Wild Turkey', 'Mesquite Wood Smoked Turkey, Mozzarella, Portabello Mushrooms, Roasted Red Peppers & Choice of Dressing', 9.99, true, false, 10, ARRAY['signature', 'turkey', 'gourmet'], '/images/menu/page-3.png'),
(2, 'The Roma Wrap', 'Grilled Chicken, Romaine Lettuce, Parmesan, Croutons & Caesar Dressing on a Tomato Wrap', 9.99, true, true, 10, ARRAY['signature', 'wrap', 'chicken', 'caesar'], '/images/menu/page-3.png'),
(2, 'Slim Chicken Wrap', 'Grilled Chicken, Onions, Peppers, Balsamic Vinegar & Oil on a Whole Wheat Wrap', 9.99, true, false, 10, ARRAY['signature', 'wrap', 'chicken', 'healthy'], '/images/menu/page-3.png'),
(2, 'Yankee Peddler', 'Rare Roast Beef, Vermont Cheddar Cheese, Cole Slaw & Russian Dressing on a Roll', 9.99, true, false, 8, ARRAY['signature', 'beef'], '/images/menu/page-4.png'),
(2, 'Mama Rosa', 'Fresh Mozzarella Cheese, Roasted Red Peppers, Lettuce, Oil & Vinegar, Salt & Pepper on a Roll', 9.99, true, false, 8, ARRAY['signature', 'vegetarian', 'italian'], '/images/menu/page-4.png'),
(2, 'Portobello Grove', 'Grilled Portobello Mushrooms, Fresh Mozzarella, Roasted Peppers, Oil & Vinegar', 9.99, true, false, 10, ARRAY['signature', 'vegetarian', 'mushroom'], '/images/menu/page-4.png'),
(2, 'Cajun Horse', 'Roast Beef and Swiss Cheese w/ Lettuce, Tomato and Horseradish Sauce', 9.99, true, false, 8, ARRAY['signature', 'beef', 'spicy'], '/images/menu/page-4.png'),
(2, 'Eggplanter', 'Breaded Eggplant Cutlets, Melted Muenster, Roasted Red Peppers, Lettuce & Russian Dressing on a Toasted Roll', 9.99, true, false, 10, ARRAY['signature', 'vegetarian', 'eggplant'], '/images/menu/page-4.png'),
(2, 'Miss Virginia', 'Grilled Virginia Ham & Melted Muenster Cheese on a Croissant', 9.99, true, false, 8, ARRAY['signature', 'ham', 'croissant'], '/images/menu/page-4.png');

-- ============================================
-- CLASSIC SANDWICHES
-- ============================================
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags, image_url) VALUES
(3, 'Chicken Cutlet', 'With Choice Of Cheese Lettuce & Tomato And Mayo', 9.99, true, true, 10, ARRAY['classic', 'chicken', 'popular'], '/images/menu/page-5.png'),
(3, 'Reuben', 'Boar''s Head Corned Beef or Pastrami Grilled W/ Swiss Cheese And Sauerkraut And Russian Dressing On Rye Bread', 11.99, true, false, 12, ARRAY['classic', 'deli', 'grilled'], '/images/menu/page-5.png'),
(3, 'Philly Cheesesteak', 'Thinly Sliced Steak, Peppers, Onions And Cheese', 11.99, true, true, 12, ARRAY['classic', 'beef', 'popular'], '/images/menu/page-5.png'),
(3, 'Meatball Parmesan', 'Meatballs Topped With Melted Mozzarella Cheese', 10.99, true, false, 10, ARRAY['classic', 'italian'], '/images/menu/page-5.png'),
(3, 'Captain Tuna', 'Fresh Tuna Salad, Melted American Cheese On A Roll', 9.99, true, false, 8, ARRAY['classic', 'tuna'], '/images/menu/page-5.png'),
(3, 'Chicken Parmesan', 'Breaded Chicken Cutlet Topped With Melted Mozzarella Cheese', 9.99, true, true, 10, ARRAY['classic', 'chicken', 'italian', 'popular'], '/images/menu/page-5.png'),
(3, 'The Cross River Club', 'Ovengold® Turkey, Vermont Cheddar, Bacon, Lettuce, Tomato And Pepperhouse Gourmaise Dressing', 10.99, true, true, 10, ARRAY['classic', 'turkey', 'club', 'featured'], '/images/menu/page-6.png'),
(3, 'Italian Combo', 'Cappy Ham, Genoa Salami, Pepperoni, Prosciutto, Provolone Cheese, Lettuce, Tomato, Choice of Peppers and Oil & Vinegar', 10.99, true, false, 10, ARRAY['classic', 'italian', 'combo'], '/images/menu/page-6.png'),
(3, 'American Combo', 'Deluxe Ham, Ovengold® Turkey, Bologna, American Cheese, Lettuce & Tomato', 10.99, true, false, 8, ARRAY['classic', 'combo'], '/images/menu/page-6.png'),
(3, 'Buffalo Chicken Wrap', 'Grilled or Breaded Chicken, Cheddar Cheese, Hot Sauce, Lettuce, Tomato & Bleu Cheese Dressing on Choice of Wrap', 10.99, true, true, 10, ARRAY['classic', 'wrap', 'chicken', 'spicy'], '/images/menu/page-6.png'),
(3, 'All American', 'Ovengold® Turkey and Deluxe Ham, Swiss, Cole Slaw & Russian Dressing on a Roll', 9.99, true, false, 8, ARRAY['classic', 'turkey', 'ham'], '/images/menu/page-6.png'),
(3, 'Cheese Burger', '8oz. Fresh Ground Angus Beef Served On A Brioche Bun w/ Lettuce, Tomato & Onions', 10.99, true, true, 12, ARRAY['classic', 'burger', 'popular'], '/images/menu/page-6.png');

-- ============================================
-- BURGERS
-- ============================================
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags, image_url) VALUES
(4, 'Cheeseburger', '8oz Fresh Ground Angus Beef Served on a Brioche Bun with Lettuce, Tomato & Onions', 10.99, true, true, 12, ARRAY['burger', 'beef', 'popular'], '/images/menu/page-7.png'),
(4, 'Cheeseburger Deluxe', '8oz Fresh Ground Angus Beef with Pickle Chips, Cole Slaw & a Side of Fries', 12.99, true, true, 15, ARRAY['burger', 'beef', 'deluxe'], '/images/menu/page-7.png'),
(4, 'Garden Burger', 'Veggie patty with Lettuce, Tomato, Onions & Salsa', 9.99, true, false, 10, ARRAY['burger', 'vegetarian'], '/images/menu/page-7.png');

-- ============================================
-- MUNCHIES
-- ============================================
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags, image_url) VALUES
(5, 'Wings (6pc)', 'Buffalo, BBQ, Garlic Parm, Mango Habanero - With Blue Cheese', 7.99, true, true, 15, ARRAY['munchies', 'chicken', 'wings', 'popular'], '/images/menu/page-7.png'),
(5, 'Wings (12pc)', 'Buffalo, BBQ, Garlic Parm, Mango Habanero - With Blue Cheese', 14.99, true, true, 18, ARRAY['munchies', 'chicken', 'wings', 'popular'], '/images/menu/page-7.png'),
(5, 'Chicken Tenders (5pc)', 'With BBQ Sauce or Honey Mustard', 7.99, true, true, 12, ARRAY['munchies', 'chicken', 'popular'], '/images/menu/page-7.png'),
(5, 'Chicken Tenders with Fries', '5pc Chicken Tenders with a side of fries', 9.99, true, true, 15, ARRAY['munchies', 'chicken', 'combo'], '/images/menu/page-7.png'),
(5, 'Mozzarella Sticks', 'With Marinara Sauce', 6.99, true, false, 10, ARRAY['munchies', 'appetizer', 'cheese'], '/images/menu/page-7.png'),
(5, 'French Fries or Curly Fries', 'Golden crispy fries', 4.99, true, true, 8, ARRAY['munchies', 'side', 'popular'], '/images/menu/page-7.png'),
(5, 'Onion Rings', 'Crispy beer-battered onion rings', 6.99, true, false, 10, ARRAY['munchies', 'side'], '/images/menu/page-7.png'),
(5, 'Jalapeño Poppers (6pc)', 'With Side of Sour Cream', 7.99, true, false, 10, ARRAY['munchies', 'spicy', 'appetizer'], '/images/menu/page-7.png'),
(5, 'Mac & Cheese Bites (8pc)', 'Crispy mac and cheese bites', 6.99, true, false, 10, ARRAY['munchies', 'cheese'], '/images/menu/page-7.png'),
(5, 'Hot Soups - Small', 'Made Fresh Daily', 5.99, true, false, 5, ARRAY['munchies', 'soup', 'hot'], '/images/menu/page-7.png'),
(5, 'Hot Soups - Large', 'Made Fresh Daily', 7.99, true, false, 5, ARRAY['munchies', 'soup', 'hot'], '/images/menu/page-7.png');

-- ============================================
-- LINK ALL ITEMS TO HIGHLAND MILLS STORE
-- ============================================
INSERT INTO store_menu_items (store_id, menu_item_id, is_available, custom_price)
SELECT 1, id, true, NULL
FROM menu_items;

-- Verify setup
SELECT
  'Menu Setup Complete' as status,
  (SELECT COUNT(*) FROM menu_categories) as categories,
  (SELECT COUNT(*) FROM menu_items) as menu_items,
  (SELECT COUNT(*) FROM store_menu_items WHERE store_id = 1) as highland_mills_items;
