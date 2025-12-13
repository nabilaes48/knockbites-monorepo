//
//  MockDataService.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import Foundation

class MockDataService {
    static let shared = MockDataService()

    private init() {}

    // MARK: - Stores
    let mockStores: [Store] = [
        Store(
            id: "store_1",
            name: "35 Vassar Road Snack Shop Inc",
            address: "35 Vassar Rd, Poughkeepsie, NY 12603",
            phone: "(845) 849-3980",
            latitude: 41.7004,
            longitude: -73.9210,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_2",
            name: "446 Dix Ave Fuel Inc",
            address: "446 Dix Ave, Queensbury, NY 12804",
            phone: "--",
            latitude: 43.3418,
            longitude: -73.6649,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_3",
            name: "486 Main Snack Shop Inc",
            address: "486 N Main St, Brewster, NY 10509",
            phone: "(845) 302-4131",
            latitude: 41.3976,
            longitude: -73.6151,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_4",
            name: "5W Snack Shop Inc",
            address: "5465 Rte 9W, Newburgh, NY 12550",
            phone: "(845) 391-8112",
            latitude: 41.5034,
            longitude: -74.0104,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_5",
            name: "Bedford Sunoco Inc",
            address: "1831 New Hackensack Rd, Poughkeepsie, NY 12603",
            phone: "(845) 226-1555",
            latitude: 41.6654,
            longitude: -73.8987,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_6",
            name: "Bedford Snack Shop Inc",
            address: "193 Pound Ridge Rd, Bedford, NY 10506",
            phone: "(914) 234-7851",
            latitude: 41.2042,
            longitude: -73.6437,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_7",
            name: "Brewster Fuel Mart Inc",
            address: "2241 U.S-6, Brewster, NY 10509",
            phone: "(845) 302-2972",
            latitude: 41.4276,
            longitude: -73.6151,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_8",
            name: "Brewster Snack Shop Inc",
            address: "978 NY-22, Brewster, NY 10509",
            phone: "(845) 282-0721",
            latitude: 41.3976,
            longitude: -73.6120,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_9",
            name: "Bridge Snack Shop Inc",
            address: "5001 Rte 9W, Newburgh, NY 12550",
            phone: "(845) 245-4178",
            latitude: 41.5034,
            longitude: -74.0154,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_10",
            name: "Burnt Hills Snack Shop Inc",
            address: "804 Saratoga Rd, Burnt Hills, NY 12027",
            phone: "MISSING",
            latitude: 42.9143,
            longitude: -73.8596,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_11",
            name: "Cortland Snack Shop Inc",
            address: "2051 E. Main St, Cortland Manor, NY 10567",
            phone: "(914) 293-7045",
            latitude: 41.3012,
            longitude: -73.8915,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_12",
            name: "Craryville Snack Shop Inc",
            address: "1371 NY-23, Craryville, NY 12521",
            phone: "(518) 851-2419",
            latitude: 42.1787,
            longitude: -73.6248,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_13",
            name: "Cross River Food Market Inc",
            address: "890 NY-35, Cross River, NY 10518",
            phone: "(914) 763-3354",
            latitude: 41.2637,
            longitude: -73.5993,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_14",
            name: "Highland Mills Snack Shop Inc",
            address: "334 NY-32, Highland Mills, NY 10930",
            phone: "(845) 928-2803",
            latitude: 41.3526,
            longitude: -74.1265,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_15",
            name: "Hyat Fuel Depot Inc",
            address: "4299 Albany Post Rd, Hyde Park, NY 12538",
            phone: "(845) 233-5928",
            latitude: 41.7848,
            longitude: -73.9329,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_16",
            name: "Kingston Snack Shop Inc",
            address: "555 NY-28, Kingston, NY 12401",
            phone: "(845) 853-7111",
            latitude: 41.9270,
            longitude: -74.0165,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_17",
            name: "Leeds Fuel Shop Inc",
            address: "375 Co Rd 23B, Leeds, NY 12451",
            phone: "(518) 943-2203",
            latitude: 42.2987,
            longitude: -73.9493,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_18",
            name: "Manorpac Snack Shop Inc",
            address: "254 U.S-6, Manorpac, NY 10541",
            phone: "(845) 621-1100",
            latitude: 41.3526,
            longitude: -73.9043,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_19",
            name: "Montrose Snack Shop Inc",
            address: "2148 Albany Post Rd, Montrose, NY 10548",
            phone: "(914) 930-7438",
            latitude: 41.2476,
            longitude: -73.9387,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_20",
            name: "New Paltz Snack Shop Inc",
            address: "160 Main St, New Paltz, NY 12561",
            phone: "(845) 255-5104",
            latitude: 41.7470,
            longitude: -74.0865,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_21",
            name: "Ossining Snack Shop Inc",
            address: "32 State Ave, Ossining, NY 10562",
            phone: "(914) 432-7446",
            latitude: 41.1626,
            longitude: -73.8637,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_22",
            name: "Route 376 Snack Shop Inc",
            address: "1592 NY-376, Wappingers Falls, NY 12590",
            phone: "(845) 463-1658",
            latitude: 41.5965,
            longitude: -73.8904,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_23",
            name: "S&I Snack Shop Inc",
            address: "2225 Crompond Rd, Cortlandt, NY 10567",
            phone: "(914) 930-1937",
            latitude: 41.2876,
            longitude: -73.8715,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_24",
            name: "Saugerties Snack Shop Inc",
            address: "2781 NY-32, Saugerties, NY 12477",
            phone: "(845) 217-5735",
            latitude: 42.0776,
            longitude: -73.9543,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_25",
            name: "Sauro's Deli Corp",
            address: "1072 NY-311, Patterson, NY 12563",
            phone: "(845) 878-9704",
            latitude: 41.5101,
            longitude: -73.6043,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_26",
            name: "Colton C-Store & Deli",
            address: "50 Maple St, Colton, NY 13625",
            phone: "(914) 862-4366",
            latitude: 44.5387,
            longitude: -74.9365,
            openTime: "06:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_27",
            name: "Town Square Pizza Cafe Corp",
            address: "1072 NY-311, Patterson, NY 12563",
            phone: "(845) 319-6363",
            latitude: 41.5101,
            longitude: -73.6043,
            openTime: "11:00",
            closeTime: "22:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_28",
            name: "Valley Cottage Cigar Shop Inc",
            address: "114 North St, Goldens Bridge, NY 10526",
            phone: "(914) 401-9013",
            latitude: 41.2943,
            longitude: -73.6776,
            openTime: "09:00",
            closeTime: "21:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        ),
        Store(
            id: "store_29",
            name: "White Plains Cigar Shop Inc",
            address: "78 Virginia Rd, White Plains, NY 10603",
            phone: "(914) 358-9240",
            latitude: 41.0343,
            longitude: -73.7629,
            openTime: "09:00",
            closeTime: "21:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        )
    ]

    // MARK: - Business Users
    let mockBusinessUsers: [BusinessUser] = [
        BusinessUser(
            id: "user_1",
            email: "admin@knockbites.com",
            fullName: "Admin User",
            role: .admin,
            storeId: "store_1"
        ),
        BusinessUser(
            id: "user_2",
            email: "manager@knockbites.com",
            fullName: "Store Manager",
            role: .manager,
            storeId: "store_1"
        ),
        BusinessUser(
            id: "user_3",
            email: "staff@knockbites.com",
            fullName: "Kitchen Staff",
            role: .staff,
            storeId: "store_1"
        )
    ]

    // MARK: - Categories
    let mockCategories: [Category] = [
        Category(id: "cat_1", name: "Appetizers", icon: "🥗", sortOrder: 1),
        Category(id: "cat_2", name: "Entrees", icon: "🍽️", sortOrder: 2),
        Category(id: "cat_3", name: "Burgers", icon: "🍔", sortOrder: 3),
        Category(id: "cat_4", name: "Sandwiches", icon: "🥪", sortOrder: 4),
        Category(id: "cat_5", name: "Salads", icon: "🥗", sortOrder: 5),
        Category(id: "cat_6", name: "Desserts", icon: "🍰", sortOrder: 6),
        Category(id: "cat_7", name: "Beverages", icon: "🥤", sortOrder: 7)
    ]

    // MARK: - Menu Items
    func getMockMenuItems() -> [MenuItem] {
        [
            MenuItem(
                id: "item_1",
                name: "Classic Cheeseburger",
                description: "Angus beef patty with cheddar, lettuce, tomato, and special sauce",
                price: 15.99,
                categoryId: "cat_3",
                imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400",
                isAvailable: true,
                dietaryInfo: [],
                customizationGroups: [],
                calories: 720,
                prepTime: 18
            ),
            MenuItem(
                id: "item_2",
                name: "Bacon BBQ Burger",
                description: "Double patty with bacon, BBQ sauce, onion rings, and cheddar",
                price: 17.99,
                categoryId: "cat_3",
                imageURL: "https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400",
                isAvailable: true,
                dietaryInfo: [],
                customizationGroups: [],
                calories: 950,
                prepTime: 20
            ),
            MenuItem(
                id: "item_3",
                name: "Buffalo Wings",
                description: "Classic buffalo wings with celery and blue cheese",
                price: 14.99,
                categoryId: "cat_1",
                imageURL: "https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=400",
                isAvailable: true,
                dietaryInfo: [.spicy, .glutenFree],
                customizationGroups: [],
                calories: 550,
                prepTime: 20
            ),
            MenuItem(
                id: "item_4",
                name: "Caesar Salad",
                description: "Romaine lettuce, parmesan, croutons, and Caesar dressing",
                price: 12.99,
                categoryId: "cat_5",
                imageURL: "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400",
                isAvailable: true,
                dietaryInfo: [.vegetarian],
                customizationGroups: [],
                calories: 350,
                prepTime: 10
            ),
            MenuItem(
                id: "item_5",
                name: "Chocolate Lava Cake",
                description: "Warm chocolate cake with molten center, served with ice cream",
                price: 8.99,
                categoryId: "cat_6",
                imageURL: "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400",
                isAvailable: true,
                dietaryInfo: [.vegetarian],
                customizationGroups: [],
                calories: 520,
                prepTime: 12
            )
        ]
    }

    // MARK: - Orders
    func generateMockOrders(storeId: String) -> [Order] {
        let menuItems = getMockMenuItems()

        return [
            // New order - just received
            Order(
                id: "order_1",
                orderNumber: "ORD-20251112-0001",
                userId: "customer_1",
                customerName: "John Smith",
                storeId: storeId,
                items: [
                    CartItem(
                        id: "item_1",
                        menuItem: menuItems[0],
                        quantity: 2,
                        selectedOptions: [:],
                        specialInstructions: "No onions please"
                    ),
                    CartItem(
                        id: "item_2",
                        menuItem: menuItems[2],
                        quantity: 1,
                        selectedOptions: [:],
                        specialInstructions: ""
                    )
                ],
                subtotal: 46.97,
                tax: 4.23,
                total: 51.20,
                status: .received,
                orderType: .pickup,
                createdAt: Date().addingTimeInterval(-120), // 2 min ago
                estimatedReadyTime: Date().addingTimeInterval(18 * 60) // 18 min from now
            ),

            // Order in preparation
            Order(
                id: "order_2",
                orderNumber: "ORD-20251112-0002",
                userId: "customer_2",
                customerName: "Sarah Johnson",
                storeId: storeId,
                items: [
                    CartItem(
                        id: "item_3",
                        menuItem: menuItems[1],
                        quantity: 1,
                        selectedOptions: [:],
                        specialInstructions: "Extra BBQ sauce"
                    ),
                    CartItem(
                        id: "item_4",
                        menuItem: menuItems[3],
                        quantity: 1,
                        selectedOptions: [:],
                        specialInstructions: ""
                    )
                ],
                subtotal: 30.98,
                tax: 2.79,
                total: 33.77,
                status: .preparing,
                orderType: .pickup,
                createdAt: Date().addingTimeInterval(-480), // 8 min ago
                estimatedReadyTime: Date().addingTimeInterval(12 * 60)
            ),

            // Order ready for pickup
            Order(
                id: "order_3",
                orderNumber: "ORD-20251112-0003",
                userId: "customer_3",
                customerName: "Michael Brown",
                storeId: storeId,
                items: [
                    CartItem(
                        id: "item_5",
                        menuItem: menuItems[0],
                        quantity: 1,
                        selectedOptions: [:],
                        specialInstructions: ""
                    ),
                    CartItem(
                        id: "item_6",
                        menuItem: menuItems[4],
                        quantity: 2,
                        selectedOptions: [:],
                        specialInstructions: ""
                    )
                ],
                subtotal: 33.97,
                tax: 3.06,
                total: 37.03,
                status: .ready,
                orderType: .pickup,
                createdAt: Date().addingTimeInterval(-900), // 15 min ago
                estimatedReadyTime: Date()
            ),

            // Completed order
            Order(
                id: "order_4",
                orderNumber: "ORD-20251112-0004",
                userId: "customer_4",
                customerName: "Emily Davis",
                storeId: storeId,
                items: [
                    CartItem(
                        id: "item_7",
                        menuItem: menuItems[2],
                        quantity: 2,
                        selectedOptions: [:],
                        specialInstructions: "Extra spicy"
                    )
                ],
                subtotal: 29.98,
                tax: 2.70,
                total: 32.68,
                status: .completed,
                orderType: .pickup,
                createdAt: Date().addingTimeInterval(-1800), // 30 min ago
                estimatedReadyTime: Date().addingTimeInterval(-600),
                completedAt: Date().addingTimeInterval(-300) // 5 min ago
            )
        ]
    }

    // MARK: - Analytics
    func generateMockDailySales() -> [DailySales] {
        let calendar = Calendar.current
        var sales: [DailySales] = []

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let orderCount = Int.random(in: 20...50)
            let revenue = Double.random(in: 800...2000)

            sales.append(
                DailySales(
                    id: "sale_\(i)",
                    date: date,
                    totalOrders: orderCount,
                    totalRevenue: revenue,
                    averageOrderValue: revenue / Double(orderCount)
                )
            )
        }

        return sales.reversed()
    }

    func generatePopularItems() -> [PopularItem] {
        let menuItems = getMockMenuItems()

        return [
            PopularItem(
                id: "pop_1",
                menuItem: menuItems[0],
                orderCount: 45,
                revenue: 719.55
            ),
            PopularItem(
                id: "pop_2",
                menuItem: menuItems[1],
                orderCount: 38,
                revenue: 683.62
            ),
            PopularItem(
                id: "pop_3",
                menuItem: menuItems[2],
                orderCount: 32,
                revenue: 479.68
            )
        ]
    }
}
