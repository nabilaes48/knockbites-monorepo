-- ============================================
-- SEED DATA - STORES AND INITIAL MENU
-- ============================================

-- ============================================
-- INSERT 29 CAMERON'S CONNECT STORES
-- ============================================
INSERT INTO stores (id, name, address, city, state, zip, phone, hours, is_open, latitude, longitude, store_type) VALUES
(1, '35 Vassar Road Snack Shop', '35 Vassar Rd', 'Poughkeepsie', 'NY', '12603', '(845) 849-3980', 'Open 24/7', true, 41.7003, -73.9209, 'snack_shop'),
(2, '446 Dix Ave Fuel', '446 Dix Ave', 'Queensbury', 'NY', '12804', 'N/A', 'Open 24/7', true, 43.3417, -73.6562, 'fuel'),
(3, '486 Main Snack Shop', '486 N Main St', 'Brewster', 'NY', '10509', '(845) 302-4131', 'Open 24/7', true, 41.3973, -73.6168, 'snack_shop'),
(4, '5W Snack Shop', '5465 Rte 9W', 'Newburgh', 'NY', '12550', '(845) 391-9112', 'Open 24/7', true, 41.5034, -74.0104, 'snack_shop'),
(5, 'BeMain Snack Shop', '1831 New Hackensack Rd', 'Poughkeepsie', 'NY', '12603', '(845) 226-1555', 'Open 24/7', true, 41.6612, -73.8701, 'snack_shop'),
(6, 'Bedford Snack Shop', '193 Pound Ridge Rd', 'Bedford', 'NY', '10506', '(914) 234-7851', 'Open 24/7', true, 41.2043, -73.6440, 'snack_shop'),
(7, 'Brewster Fuel Mart', '2241 U.S-6', 'Brewster', 'NY', '10509', '(845) 302-2972', 'Open 24/7', true, 41.3948, -73.6012, 'fuel'),
(8, 'Brewster Snack Shop', '978 NY-22', 'Brewster', 'NY', '10509', '(845) 282-0721', 'Open 24/7', true, 41.4289, -73.5823, 'snack_shop'),
(9, 'Bridge Snack Shop', '5001 Rte 9W', 'Newburgh', 'NY', '12550', '(845) 245-4178', 'Open 24/7', true, 41.5045, -74.0115, 'snack_shop'),
(10, 'Burnt Hills Snack Shop', '804 Saratoga Rd', 'Burnt Hills', 'NY', '12027', 'N/A', 'Open 24/7', true, 42.9142, -73.8579, 'snack_shop'),
(11, 'Cortlandt Snack Shop', '2051 E. Main St', 'Cortlandt Manor', 'NY', '10567', '(914) 293-7045', 'Open 24/7', true, 41.2923, -73.8776, 'snack_shop'),
(12, 'Crayvillas Snack Shop', '1371 NY-23', 'Craryville', 'NY', '12521', '(518) 851-2419', 'Open 24/7', true, 42.1656, -73.6290, 'snack_shop'),
(13, 'Cross River Food Market', '890 NY-35', 'Cross River', 'NY', '10518', '(914) 763-3354', 'Open 24/7', true, 41.2662, -73.6023, 'deli'),
(14, 'Highland Mtns Snack Shop', '534 NY-32', 'Highland Mills', 'NY', '10930', '(845) 928-2803', 'Open 24/7', true, 41.3501, -74.1243, 'snack_shop'),
(15, 'Hyde Park Snack Shop', '4299 Albany Post Rd', 'Hyde Park', 'NY', '12538', '(845) 233-5928', 'Open 24/7', true, 41.7845, -73.9334, 'snack_shop'),
(16, 'Kingston Snack Shop', '555 NY-28', 'Kingston', 'NY', '12401', '(845) 853-7111', 'Open 24/7', true, 41.9270, -74.0823, 'snack_shop'),
(17, 'Leeds Snack Shop', '375 Co Rd 23B', 'Leeds', 'NY', '12451', '(518) 943-2203', 'Open 24/7', true, 42.3023, -73.9512, 'snack_shop'),
(18, 'Manorpac Snack Shop', '254 U.S-6', 'Mahopac', 'NY', '10541', '(845) 621-1100', 'Open 24/7', true, 41.3656, -73.7351, 'snack_shop'),
(19, 'Montrose Snack Shop', '2148 Albany Post Rd', 'Montrose', 'NY', '10548', '(914) 930-7438', 'Open 24/7', true, 41.2445, -73.9401, 'snack_shop'),
(20, 'New Paltz Snack Shop', '160 Main St', 'New Paltz', 'NY', '12561', '(845) 255-5104', 'Open 24/7', true, 41.7476, -74.0865, 'snack_shop'),
(21, 'Ossining Snack Shop', '32 State Ave', 'Ossining', 'NY', '10562', '(914) 432-7446', 'Open 24/7', true, 41.1629, -73.8640, 'snack_shop'),
(22, 'Route 376 Snack Shop', '1592 NY-376', 'Wappingers Falls', 'NY', '12590', '(845) 463-1658', 'Open 24/7', true, 41.5967, -73.9101, 'snack_shop'),
(23, 'SM Snack Shop', '2225 Crompond Rd', 'Cortlandt', 'NY', '10567', '(914) 930-1937', 'Open 24/7', true, 41.2845, -73.8634, 'snack_shop'),
(24, 'Saugerties Snack Shop', '2781 NY-32', 'Saugerties', 'NY', '12477', '(845) 217-5735', 'Open 24/7', true, 42.0778, -73.9523, 'snack_shop'),
(25, 'Sauro''s Deli Corp', '1072 NY-311', 'Patterson', 'NY', '12563', '(845) 878-9704', 'Open 24/7', true, 41.4989, -73.6001, 'deli'),
(26, 'Smoke Shop', '50 Maple St', 'Croton On Hudson', 'NY', '10520', '(914) 862-4486', 'Open 24/7', true, 41.2084, -73.8943, 'cigar_shop'),
(27, 'Town Square Pizza Cafe', '1072 NY-311', 'Patterson', 'NY', '12563', '(845) 319-6363', 'Open 24/7', true, 41.4989, -73.6001, 'pizza'),
(28, 'Valley Cottage Cigar Shop', '114 North St', 'Goldens Bridge', 'NY', '10526', '(914) 401-9013', 'Open 24/7', true, 41.2945, -73.6779, 'cigar_shop'),
(29, 'White Plains Cigar Shop', '78 Virginia Rd', 'White Plains', 'NY', '10603', '(914) 358-9280', 'Open 24/7', true, 41.0334, -73.7629, 'cigar_shop');

-- ============================================
-- INSERT MENU CATEGORIES
-- ============================================
INSERT INTO menu_categories (name, description, display_order, is_active) VALUES
('Breakfast', 'Start your day right with fresh breakfast options', 1, true),
('Sandwiches & Wraps', 'Fresh made-to-order sandwiches and wraps', 2, true),
('Hot Entrees', 'Warm and satisfying meals', 3, true),
('Salads', 'Fresh and healthy salad options', 4, true),
('Snacks', 'Quick bites and snacks', 5, true),
('Beverages', 'Hot and cold drinks', 6, true),
('Desserts', 'Sweet treats and desserts', 7, true);

-- ============================================
-- INSERT SAMPLE MENU ITEMS
-- ============================================

-- Breakfast Items
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags) VALUES
(1, 'Bacon, Egg & Cheese', 'Classic breakfast sandwich with crispy bacon, fresh egg, and melted cheese', 5.99, true, true, 10, ARRAY['popular', 'breakfast']),
(1, 'Sausage, Egg & Cheese', 'Savory sausage with egg and cheese on your choice of bread', 5.99, true, false, 10, ARRAY['breakfast']),
(1, 'Veggie Omelette Wrap', 'Fresh vegetables, eggs, and cheese in a soft wrap', 6.49, true, false, 12, ARRAY['vegetarian', 'breakfast']),
(1, 'Pancake Breakfast', 'Stack of fluffy pancakes with syrup', 6.99, true, false, 15, ARRAY['breakfast', 'sweet']);

-- Sandwiches & Wraps
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags) VALUES
(2, 'Italian Sub', 'Ham, salami, pepperoni, provolone, lettuce, tomato, onion, oil & vinegar', 8.99, true, true, 8, ARRAY['popular', 'lunch']),
(2, 'Turkey Club', 'Fresh turkey, bacon, lettuce, tomato, and mayo on toasted bread', 8.49, true, false, 8, ARRAY['lunch']),
(2, 'Chicken Caesar Wrap', 'Grilled chicken, romaine, parmesan, caesar dressing', 7.99, true, true, 10, ARRAY['lunch', 'wrap']),
(2, 'BLT', 'Crispy bacon, fresh lettuce, and tomato with mayo', 6.99, true, false, 6, ARRAY['classic', 'lunch']),
(2, 'Philly Cheesesteak', 'Thinly sliced steak with grilled onions and melted cheese', 9.99, true, true, 12, ARRAY['hot', 'popular']);

-- Hot Entrees
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags) VALUES
(3, 'Cheeseburger', 'Juicy beef patty with cheese, lettuce, tomato, and pickles', 7.99, true, true, 12, ARRAY['hot', 'popular']),
(3, 'Chicken Tenders', '5 crispy chicken tenders with your choice of sauce', 8.99, true, false, 15, ARRAY['hot', 'chicken']),
(3, 'Buffalo Wings', '10 wings tossed in buffalo sauce', 10.99, true, false, 18, ARRAY['hot', 'spicy']),
(3, 'Grilled Chicken Sandwich', 'Seasoned grilled chicken breast with lettuce and tomato', 8.49, true, false, 12, ARRAY['hot', 'chicken']);

-- Salads
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags) VALUES
(4, 'Caesar Salad', 'Romaine lettuce, parmesan, croutons, caesar dressing', 6.99, true, false, 8, ARRAY['healthy', 'vegetarian']),
(4, 'Garden Salad', 'Mixed greens, tomatoes, cucumbers, carrots, choice of dressing', 5.99, true, false, 6, ARRAY['healthy', 'vegetarian']),
(4, 'Chef Salad', 'Ham, turkey, cheese, hard-boiled egg on mixed greens', 8.99, true, false, 10, ARRAY['healthy', 'protein']);

-- Snacks
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags) VALUES
(5, 'French Fries', 'Crispy golden fries', 3.49, true, false, 8, ARRAY['side', 'popular']),
(5, 'Mozzarella Sticks', '6 breaded mozzarella sticks with marinara', 5.99, true, false, 10, ARRAY['appetizer']),
(5, 'Onion Rings', 'Crispy beer-battered onion rings', 4.49, true, false, 10, ARRAY['side']),
(5, 'Nachos', 'Tortilla chips with cheese, jalapeños, and salsa', 6.49, true, false, 8, ARRAY['snack', 'shareable']);

-- Beverages
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags) VALUES
(6, 'Coffee', 'Fresh brewed coffee', 1.99, true, false, 2, ARRAY['hot', 'caffeine']),
(6, 'Iced Coffee', 'Cold brewed coffee over ice', 2.49, true, false, 3, ARRAY['cold', 'caffeine']),
(6, 'Fountain Soda', 'Choice of Coke, Pepsi, Sprite, etc.', 1.99, true, false, 1, ARRAY['cold']),
(6, 'Bottled Water', 'Refreshing bottled water', 1.49, true, false, 1, ARRAY['cold', 'healthy']);

-- Desserts
INSERT INTO menu_items (category_id, name, description, base_price, is_available, is_featured, preparation_time, tags) VALUES
(7, 'Chocolate Chip Cookie', 'Fresh baked chocolate chip cookie', 1.99, true, false, 2, ARRAY['sweet', 'baked']),
(7, 'Brownie', 'Rich chocolate brownie', 2.99, true, false, 2, ARRAY['sweet', 'chocolate']),
(7, 'Ice Cream Cup', 'Creamy ice cream - ask for flavors', 3.49, true, false, 3, ARRAY['sweet', 'cold']);

-- ============================================
-- SAMPLE CUSTOMIZATIONS
-- ============================================

-- Bread choices for sandwiches
INSERT INTO menu_item_customizations (menu_item_id, name, type, options, is_required, display_order)
SELECT id, 'Bread Choice', 'single',
  '[
    {"label": "White Roll", "price": 0},
    {"label": "Wheat Roll", "price": 0},
    {"label": "Hero", "price": 1.00},
    {"label": "Wrap", "price": 0.50}
  ]'::jsonb,
  true, 1
FROM menu_items
WHERE category_id = 2;

-- Size options for beverages
INSERT INTO menu_item_customizations (menu_item_id, name, type, options, is_required, display_order)
SELECT id, 'Size', 'single',
  '[
    {"label": "Small", "price": 0},
    {"label": "Medium", "price": 0.50},
    {"label": "Large", "price": 1.00}
  ]'::jsonb,
  true, 1
FROM menu_items
WHERE category_id = 6;

-- Add-ons for burgers
INSERT INTO menu_item_customizations (menu_item_id, name, type, options, is_required, display_order)
SELECT id, 'Add-ons', 'multiple',
  '[
    {"label": "Extra Cheese", "price": 1.00},
    {"label": "Bacon", "price": 1.50},
    {"label": "Avocado", "price": 1.50},
    {"label": "Fried Egg", "price": 1.00}
  ]'::jsonb,
  false, 2
FROM menu_items
WHERE name LIKE '%burger%' OR name LIKE '%Burger%';

-- Sauce choices
INSERT INTO menu_item_customizations (menu_item_id, name, type, options, is_required, display_order)
SELECT id, 'Sauce', 'single',
  '[
    {"label": "BBQ", "price": 0},
    {"label": "Honey Mustard", "price": 0},
    {"label": "Ranch", "price": 0},
    {"label": "Buffalo", "price": 0}
  ]'::jsonb,
  false, 3
FROM menu_items
WHERE name = 'Chicken Tenders';

-- ============================================
-- MAKE ALL MENU ITEMS AVAILABLE AT ALL STORES
-- ============================================
INSERT INTO store_menu_items (store_id, menu_item_id, is_available)
SELECT s.id, m.id, true
FROM stores s
CROSS JOIN menu_items m;

-- Note: You can customize per-store availability and pricing later
