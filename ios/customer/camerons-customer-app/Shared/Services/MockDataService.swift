//
//  MockDataService.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import Foundation

class MockDataService {
    static let shared = MockDataService()

    private init() {}

    // MARK: - Stores
    // TODO: Inject StoreViewModel for dynamic stores

    // MARK: - Categories
    func getCategories() -> [Category] {
        Category.all
    }

    // MARK: - Menu Items
    func getMenuItems() -> [MenuItem] {
        [
            // APPETIZERS
            MenuItem(
                id: "item_2",
                name: "Buffalo Wings",
                description: "Classic buffalo wings with celery and blue cheese",
                price: 14.99,
                categoryId: "cat_1",
                imageURL: "https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=400",
                isAvailable: true,
                dietaryInfo: [.spicy, .glutenFree],
                customizationGroups: [wingQuantityGroup],
                calories: 550,
                prepTime: 20
            ),
            MenuItem(
                id: "item_3",
                name: "Loaded Nachos",
                description: "Tortilla chips with cheese, jalapeños, sour cream, and salsa",
                price: 11.99,
                categoryId: "cat_1",
                imageURL: "https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=400",
                isAvailable: true,
                dietaryInfo: [.vegetarian],
                customizationGroups: [toppingsGroup],
                calories: 680,
                prepTime: 12
            ),

            // BURGERS
            MenuItem(
                id: "item_4",
                name: "Classic Cheeseburger",
                description: "Angus beef patty with cheddar, lettuce, tomato, and special sauce",
                price: 15.99,
                categoryId: "cat_3",
                imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400",
                isAvailable: true,
                dietaryInfo: [],
                customizationGroups: [cheeseGroup, toppingsGroup, cookTempGroup],
                calories: 720,
                prepTime: 18
            ),
            MenuItem(
                id: "item_5",
                name: "Bacon BBQ Burger",
                description: "Double patty with bacon, BBQ sauce, onion rings, and cheddar",
                price: 17.99,
                categoryId: "cat_3",
                imageURL: "https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400",
                isAvailable: true,
                dietaryInfo: [],
                customizationGroups: [cheeseGroup, toppingsGroup, cookTempGroup],
                calories: 950,
                prepTime: 20
            ),
            MenuItem(
                id: "item_6",
                name: "Veggie Burger",
                description: "House-made plant-based patty with avocado and sprouts",
                price: 14.99,
                categoryId: "cat_3",
                imageURL: "https://images.unsplash.com/photo-1520072959219-c595dc870360?w=400",
                isAvailable: true,
                dietaryInfo: [.vegetarian, .vegan],
                customizationGroups: [toppingsGroup],
                calories: 480,
                prepTime: 15
            ),

            // SANDWICHES
            MenuItem(
                id: "item_7",
                name: "Grilled Chicken Club",
                description: "Grilled chicken breast with bacon, avocado, and ranch",
                price: 13.99,
                categoryId: "cat_4",
                imageURL: "https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=400",
                isAvailable: true,
                dietaryInfo: [],
                customizationGroups: [breadTypeGroup, toppingsGroup],
                calories: 650,
                prepTime: 15
            ),
            MenuItem(
                id: "item_8",
                name: "Philly Cheesesteak",
                description: "Thinly sliced ribeye with peppers, onions, and provolone",
                price: 16.99,
                categoryId: "cat_4",
                imageURL: "https://images.unsplash.com/photo-1619740455993-557c0c98c4bc?w=400",
                isAvailable: true,
                dietaryInfo: [],
                customizationGroups: [cheeseGroup, toppingsGroup],
                calories: 780,
                prepTime: 18
            ),

            // SALADS
            MenuItem(
                id: "item_9",
                name: "Caesar Salad",
                description: "Romaine lettuce, parmesan, croutons, and Caesar dressing",
                price: 11.99,
                categoryId: "cat_5",
                imageURL: "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400",
                isAvailable: true,
                dietaryInfo: [.vegetarian],
                customizationGroups: [proteinAddGroup, dressingGroup],
                calories: 320,
                prepTime: 10
            ),
            MenuItem(
                id: "item_10",
                name: "Asian Chicken Salad",
                description: "Mixed greens, mandarin oranges, crispy wontons, sesame dressing",
                price: 13.99,
                categoryId: "cat_5",
                imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400",
                isAvailable: true,
                dietaryInfo: [],
                customizationGroups: [dressingGroup],
                calories: 420,
                prepTime: 12
            ),

            // ENTREES
            MenuItem(
                id: "item_11",
                name: "Grilled Salmon",
                description: "Atlantic salmon with lemon butter, rice, and vegetables",
                price: 22.99,
                categoryId: "cat_2",
                imageURL: "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400",
                isAvailable: true,
                dietaryInfo: [.glutenFree],
                customizationGroups: [sideOptionsGroup],
                calories: 580,
                prepTime: 25
            ),
            MenuItem(
                id: "item_12",
                name: "Ribeye Steak",
                description: "12oz ribeye with garlic mashed potatoes and asparagus",
                price: 29.99,
                categoryId: "cat_2",
                imageURL: "https://images.unsplash.com/photo-1600891964092-4316c288032e?w=400",
                isAvailable: true,
                dietaryInfo: [.glutenFree],
                customizationGroups: [cookTempGroup, sideOptionsGroup],
                calories: 850,
                prepTime: 30
            ),

            // DESSERTS
            MenuItem(
                id: "item_13",
                name: "New York Cheesecake",
                description: "Classic cheesecake with graham cracker crust",
                price: 8.99,
                categoryId: "cat_6",
                imageURL: "https://images.unsplash.com/photo-1533134486753-c833f0ed4866?w=400",
                isAvailable: true,
                dietaryInfo: [.vegetarian],
                customizationGroups: [dessertToppingGroup],
                calories: 420,
                prepTime: 5
            ),
            MenuItem(
                id: "item_14",
                name: "Chocolate Lava Cake",
                description: "Warm chocolate cake with molten center, served with ice cream",
                price: 9.99,
                categoryId: "cat_6",
                imageURL: "https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=400",
                isAvailable: true,
                dietaryInfo: [.vegetarian],
                customizationGroups: [],
                calories: 580,
                prepTime: 8
            ),

            // BEVERAGES
            MenuItem(
                id: "item_15",
                name: "Fresh Lemonade",
                description: "House-made lemonade with fresh lemons",
                price: 3.99,
                categoryId: "cat_7",
                imageURL: "https://images.unsplash.com/photo-1523677011781-c91d1bbe2f0d?w=400",
                isAvailable: true,
                dietaryInfo: [.vegan],
                customizationGroups: [beverageSizeGroup],
                calories: 120,
                prepTime: 3
            ),
            MenuItem(
                id: "item_16",
                name: "Craft Beer",
                description: "Selection of local craft beers on tap",
                price: 6.99,
                categoryId: "cat_7",
                imageURL: "https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=400",
                isAvailable: true,
                dietaryInfo: [],
                customizationGroups: [],
                calories: 180,
                prepTime: 2
            )
        ]
    }

    // MARK: - Customization Groups

    private var wingQuantityGroup: CustomizationGroup {
        CustomizationGroup(
            id: "group_wing_qty",
            name: "Wing Quantity",
            isRequired: true,
            allowMultiple: false,
            options: [
                CustomizationOption(id: "opt_6wings", name: "6 Wings", priceModifier: 0, isDefault: true),
                CustomizationOption(id: "opt_12wings", name: "12 Wings", priceModifier: 6.00, isDefault: false),
                CustomizationOption(id: "opt_18wings", name: "18 Wings", priceModifier: 11.00, isDefault: false)
            ]
        )
    }

    private var cheeseGroup: CustomizationGroup {
        CustomizationGroup(
            id: "group_cheese",
            name: "Cheese",
            isRequired: false,
            allowMultiple: false,
            options: [
                CustomizationOption(id: "opt_cheddar", name: "Cheddar", priceModifier: 0, isDefault: true),
                CustomizationOption(id: "opt_swiss", name: "Swiss", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_provolone", name: "Provolone", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_blue", name: "Blue Cheese", priceModifier: 1.50, isDefault: false),
                CustomizationOption(id: "opt_no_cheese", name: "No Cheese", priceModifier: -1.00, isDefault: false)
            ]
        )
    }

    private var cookTempGroup: CustomizationGroup {
        CustomizationGroup(
            id: "group_temp",
            name: "Cook Temperature",
            isRequired: true,
            allowMultiple: false,
            options: [
                CustomizationOption(id: "opt_rare", name: "Rare", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_medium_rare", name: "Medium Rare", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_medium", name: "Medium", priceModifier: 0, isDefault: true),
                CustomizationOption(id: "opt_medium_well", name: "Medium Well", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_well", name: "Well Done", priceModifier: 0, isDefault: false)
            ]
        )
    }

    private var toppingsGroup: CustomizationGroup {
        CustomizationGroup(
            id: "group_toppings",
            name: "Toppings",
            isRequired: false,
            allowMultiple: true,
            options: [
                CustomizationOption(id: "opt_lettuce", name: "Lettuce", priceModifier: 0, isDefault: true),
                CustomizationOption(id: "opt_tomato", name: "Tomato", priceModifier: 0, isDefault: true),
                CustomizationOption(id: "opt_onion", name: "Onion", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_pickles", name: "Pickles", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_bacon", name: "Bacon", priceModifier: 2.50, isDefault: false),
                CustomizationOption(id: "opt_avocado", name: "Avocado", priceModifier: 2.00, isDefault: false),
                CustomizationOption(id: "opt_jalapenos", name: "Jalapeños", priceModifier: 0.50, isDefault: false)
            ]
        )
    }

    private var breadTypeGroup: CustomizationGroup {
        CustomizationGroup(
            id: "group_bread",
            name: "Bread Type",
            isRequired: true,
            allowMultiple: false,
            options: [
                CustomizationOption(id: "opt_white", name: "White Bread", priceModifier: 0, isDefault: true),
                CustomizationOption(id: "opt_wheat", name: "Wheat Bread", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_sourdough", name: "Sourdough", priceModifier: 1.00, isDefault: false),
                CustomizationOption(id: "opt_ciabatta", name: "Ciabatta", priceModifier: 1.00, isDefault: false)
            ]
        )
    }

    private var proteinAddGroup: CustomizationGroup {
        CustomizationGroup(
            id: "group_protein",
            name: "Add Protein",
            isRequired: false,
            allowMultiple: false,
            options: [
                CustomizationOption(id: "opt_no_protein", name: "No Protein", priceModifier: 0, isDefault: true),
                CustomizationOption(id: "opt_grilled_chicken", name: "Grilled Chicken", priceModifier: 5.00, isDefault: false),
                CustomizationOption(id: "opt_grilled_shrimp", name: "Grilled Shrimp", priceModifier: 7.00, isDefault: false),
                CustomizationOption(id: "opt_salmon", name: "Salmon", priceModifier: 8.00, isDefault: false)
            ]
        )
    }

    private var dressingGroup: CustomizationGroup {
        CustomizationGroup(
            id: "group_dressing",
            name: "Dressing",
            isRequired: true,
            allowMultiple: false,
            options: [
                CustomizationOption(id: "opt_ranch", name: "Ranch", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_caesar", name: "Caesar", priceModifier: 0, isDefault: true),
                CustomizationOption(id: "opt_balsamic", name: "Balsamic Vinaigrette", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_honey_mustard", name: "Honey Mustard", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_on_side", name: "Dressing on Side", priceModifier: 0, isDefault: false)
            ]
        )
    }

    private var sideOptionsGroup: CustomizationGroup {
        CustomizationGroup(
            id: "group_sides",
            name: "Choose Your Side",
            isRequired: true,
            allowMultiple: false,
            options: [
                CustomizationOption(id: "opt_fries", name: "French Fries", priceModifier: 0, isDefault: true),
                CustomizationOption(id: "opt_sweet_fries", name: "Sweet Potato Fries", priceModifier: 2.00, isDefault: false),
                CustomizationOption(id: "opt_rice", name: "Rice", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_mashed", name: "Mashed Potatoes", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_veggies", name: "Steamed Vegetables", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_salad", name: "Side Salad", priceModifier: 1.00, isDefault: false)
            ]
        )
    }

    private var dessertToppingGroup: CustomizationGroup {
        CustomizationGroup(
            id: "group_dessert_topping",
            name: "Topping",
            isRequired: false,
            allowMultiple: false,
            options: [
                CustomizationOption(id: "opt_plain", name: "Plain", priceModifier: 0, isDefault: true),
                CustomizationOption(id: "opt_strawberry", name: "Strawberry Sauce", priceModifier: 1.50, isDefault: false),
                CustomizationOption(id: "opt_chocolate", name: "Chocolate Sauce", priceModifier: 1.50, isDefault: false),
                CustomizationOption(id: "opt_caramel", name: "Caramel Sauce", priceModifier: 1.50, isDefault: false)
            ]
        )
    }

    private var beverageSizeGroup: CustomizationGroup {
        CustomizationGroup(
            id: "group_beverage_size",
            name: "Size",
            isRequired: true,
            allowMultiple: false,
            options: [
                CustomizationOption(id: "opt_small", name: "Small", priceModifier: 0, isDefault: false),
                CustomizationOption(id: "opt_medium", name: "Medium", priceModifier: 1.00, isDefault: true),
                CustomizationOption(id: "opt_large", name: "Large", priceModifier: 2.00, isDefault: false)
            ]
        )
    }
}
