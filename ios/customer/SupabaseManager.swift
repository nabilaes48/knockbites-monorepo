import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: SupabaseConfig.url) else {
            fatalError("Invalid Supabase URL")
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.anonKey,
            options: .init(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    func testConnection() async {
        do {
            // Test stores table
            struct DBStore: Codable {
                let id: Int
                let name: String
            }

            let stores: [DBStore] = try await client
                .from("stores")
                .select()
                .limit(5)
                .execute()
                .value

            print("✅ Supabase connection successful!")
            print("📍 Found \(stores.count) stores from database")
            for store in stores {
                print("   - Store #\(store.id): \(store.name)")
            }

            // Diagnostic: Check menu_items schema
            print("\n🔍 Checking menu_items schema...")
            do {
                let rawResponse = try await client
                    .from("menu_items")
                    .select()
                    .limit(1)
                    .execute()

                let jsonString = String(data: rawResponse.data, encoding: .utf8)
                print("📊 Sample menu_item raw JSON:")
                print(jsonString ?? "Unable to parse JSON")
            } catch {
                print("❌ Error fetching menu_items: \(error)")
            }

            // Diagnostic: Check orders schema
            print("\n🔍 Checking orders schema...")
            do {
                let rawResponse = try await client
                    .from("orders")
                    .select()
                    .limit(1)
                    .execute()

                let jsonString = String(data: rawResponse.data, encoding: .utf8)
                print("📊 Sample order raw JSON:")
                print(jsonString ?? "Unable to parse JSON")
            } catch {
                print("❌ Error fetching orders: \(error)")
            }

        } catch {
            print("❌ Supabase connection failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Customers

    /// Creates a customer profile in the customers table after user signs up
    /// - Parameters:
    ///   - authUserId: The UUID from Supabase Auth (auth.users.id)
    ///   - email: Customer's email address
    ///   - firstName: Customer's first name (optional)
    ///   - lastName: Customer's last name (optional)
    ///   - phoneNumber: Customer's phone number (optional)
    func createCustomerProfile(
        authUserId: UUID,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil,
        phoneNumber: String? = nil
    ) async throws {
        struct CustomerInsert: Codable {
            let auth_user_id: UUID
            let email: String
            let first_name: String?
            let last_name: String?
            let phone_number: String?
        }

        let customer = CustomerInsert(
            auth_user_id: authUserId,
            email: email,
            first_name: firstName,
            last_name: lastName,
            phone_number: phoneNumber
        )

        do {
            try await client
                .from("customers")
                .insert(customer)
                .execute()

            print("✅ Customer profile created for: \(email)")
        } catch {
            print("❌ Failed to create customer profile: \(error)")
            throw error
        }
    }

    // MARK: - Stores

    func fetchStores() async throws -> [Store] {
        struct DBStore: Codable {
            let id: Int
            let name: String
            let address: String
            let city: String
            let state: String
            let zip: String
            let phone_number: String?
            let latitude: Double
            let longitude: Double
            let hours_open: String?
            let hours_close: String?
            let is_open: Bool
            let created_at: String?
        }

        let dbStores: [DBStore] = try await client
            .from("stores")
            .select()
            .order("id")
            .execute()
            .value

        // Convert DB stores to app Store model
        return dbStores.map { dbStore in
            Store(
                id: String(dbStore.id),
                name: dbStore.name,
                address: "\(dbStore.address), \(dbStore.city), \(dbStore.state) \(dbStore.zip)",
                phoneNumber: dbStore.phone_number ?? "",
                coordinates: Coordinates(
                    latitude: dbStore.latitude,
                    longitude: dbStore.longitude
                ),
                hours: StoreHours.allDay, // We'll improve this later
                imageURL: nil
            )
        }
    }

    // MARK: - Menu Items

    func fetchMenuItems() async throws -> [MenuItem] {
        // Flexible struct to handle potential schema variations
        struct DBMenuItem: Codable {
            let id: Int
            let name: String
            let description: String?
            let price: Double?
            let item_price: Double?
            let base_price: Double?
            let category_id: Int?
            let category: String?
            let image_url: String?
            let is_available: Bool?
            let calories: Int?
            let prep_time_minutes: Int?
            let prep_time: Int?

            // Computed property to get price from any available field
            var actualPrice: Double {
                return price ?? item_price ?? base_price ?? 0.0
            }

            // Computed property to get category ID
            var actualCategoryId: String {
                if let catId = category_id {
                    return String(catId)
                } else if let cat = category {
                    return cat
                }
                return "1"
            }
        }

        do {
            let items: [DBMenuItem] = try await client
                .from("menu_items")
                .select()
                .eq("is_available", value: true)
                .execute()
                .value

            print("✅ Successfully fetched \(items.count) menu items from Supabase")

            // Log first item structure for debugging
            if let firstItem = items.first {
                print("📊 Sample menu item structure:")
                print("   - ID: \(firstItem.id)")
                print("   - Name: \(firstItem.name)")
                print("   - Price: \(firstItem.actualPrice)")
                print("   - Category ID: \(firstItem.actualCategoryId)")
                print("   - Image URL: \(firstItem.image_url ?? "nil")")
                print("   - Is Available: \(firstItem.is_available ?? true)")
            }

            // Log all unique image URL patterns
            let imageUrls = items.compactMap { $0.image_url }.filter { !$0.isEmpty }
            print("🖼️ Found \(imageUrls.count) image URLs")
            if let firstUrl = imageUrls.first {
                print("   Database path: \(firstUrl)")
                let fullUrl = SupabaseConfig.imageURL(from: firstUrl)
                print("   Full URL: \(fullUrl)")
                if firstUrl.starts(with: "http") {
                    print("   ✅ URL is absolute (already has protocol)")
                } else {
                    print("   🔧 URL converted from relative to absolute")
                }
            }

            // Fetch menu items with their portion customizations
            var menuItems: [MenuItem] = []

            for item in items {
                // Convert relative image path to full Supabase storage URL
                let fullImageURL = SupabaseConfig.imageURL(from: item.image_url)

                // Fetch portion customizations for this menu item
                var portionCustomizations: [MenuItemCustomization]? = nil
                do {
                    let customizations = try await fetchMenuItemCustomizations(for: item.id)
                    if !customizations.isEmpty {
                        portionCustomizations = customizations
                        print("   ✅ Loaded \(customizations.count) customizations for \(item.name)")
                    }
                } catch {
                    print("   ⚠️ No customizations for \(item.name): \(error.localizedDescription)")
                }

                let menuItem = MenuItem(
                    id: String(item.id),
                    name: item.name,
                    description: item.description ?? "",
                    price: item.actualPrice,
                    categoryId: item.actualCategoryId,
                    imageURL: fullImageURL,
                    isAvailable: item.is_available ?? true,
                    dietaryInfo: [], // TODO: Fetch from database
                    customizationGroups: [], // Legacy customizations
                    portionCustomizations: portionCustomizations,
                    calories: item.calories,
                    prepTime: item.prep_time ?? item.prep_time_minutes ?? 15
                )

                menuItems.append(menuItem)
            }

            return menuItems
        } catch {
            print("❌ Error fetching menu items: \(error)")
            print("📋 Error details: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchCategories() async throws -> [Category] {
        struct DBCategory: Codable {
            let id: Int
            let name: String
            let icon: String?
            let sort_order: Int?
            let display_order: Int?

            var actualSortOrder: Int {
                return sort_order ?? display_order ?? 0
            }
        }

        do {
            // Try with sort_order first
            let categories: [DBCategory] = try await client
                .from("categories")
                .select()
                .execute()
                .value

            print("✅ Successfully fetched \(categories.count) categories from Supabase")

            return categories.map { category in
                Category(
                    id: String(category.id),
                    name: category.name,
                    icon: category.icon ?? "🍽️",
                    sortOrder: category.actualSortOrder
                )
            }.sorted { $0.sortOrder < $1.sortOrder }
        } catch {
            print("❌ Error fetching categories: \(error)")
            throw error
        }
    }

    // MARK: - Orders

    func submitOrder(
        items: [CartItem],
        storeId: String,
        orderType: OrderType,
        subtotal: Double,
        tax: Double,
        total: Double,
        customerName: String? = nil,
        customerPhone: String? = nil
    ) async throws -> (orderId: String, orderNumber: String) {
        // Validate storeId can be converted to Int
        guard let storeIdInt = Int(storeId) else {
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid store ID: \(storeId)"])
        }

        // Validate all menu item IDs can be converted to Int
        for item in items {
            guard Int(item.menuItem.id) != nil else {
                throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid menu item ID: \(item.menuItem.id)"])
            }
        }

        struct OrderSubmission: Codable {
            let store_id: Int
            let user_id: String?
            let customer_name: String
            let customer_phone: String
            let order_type: String
            let status: String
            let subtotal: Double
            let tax: Double
            let total: Double
        }

        struct OrderItemSubmission: Codable {
            let order_id: String  // UUID string from orders table
            let menu_item_id: Int
            let item_name: String
            let item_price: Double
            let quantity: Int
            let subtotal: Double
            let special_instructions: String?
            let selected_options: [String: [String]]?  // Customizations JSON
            let customizations: [String]?  // Human-readable customizations array
        }

        struct OrderResponse: Codable {
            let id: String  // UUID returned as string from Supabase
            let order_number: String  // Auto-generated order number from database
        }

        // Get current user session
        let session = try? await client.auth.session
        let userId = session?.user.id.uuidString

        // Get customer name from parameter, user metadata, or use default
        let finalCustomerName: String
        if let providedName = customerName, !providedName.isEmpty {
            finalCustomerName = providedName
        } else if let userMetadata = session?.user.userMetadata,
                  let name = userMetadata["full_name"] as? String, !name.isEmpty {
            finalCustomerName = name
        } else if let email = session?.user.email {
            // Use email prefix as fallback (before @)
            finalCustomerName = email.components(separatedBy: "@").first ?? "Guest Customer"
        } else {
            finalCustomerName = "Guest Customer"
        }

        // Get customer phone from parameter or user metadata (required field)
        let finalCustomerPhone: String
        if let providedPhone = customerPhone, !providedPhone.isEmpty {
            finalCustomerPhone = providedPhone
        } else if let userMetadata = session?.user.userMetadata,
                  let phone = userMetadata["phone"] as? String, !phone.isEmpty {
            finalCustomerPhone = phone
        } else {
            // Default value for phone when not provided (database requires non-null)
            finalCustomerPhone = "No phone provided"
        }

        // Map order type to database format
        let dbOrderType: String = {
            switch orderType {
            case .pickup: return "pickup"
            case .delivery: return "delivery"
            case .dineIn: return "dine-in"
            case .unknown(let value): return value
            }
        }()

        // Create order
        let orderSubmission = OrderSubmission(
            store_id: storeIdInt,
            user_id: userId,
            customer_name: finalCustomerName,
            customer_phone: finalCustomerPhone,
            order_type: dbOrderType,
            status: "pending",
            subtotal: subtotal,
            tax: tax,
            total: total
        )

        print("📤 Submitting order to Supabase:")
        print("   - Store ID: \(storeIdInt)")
        print("   - Customer: \(finalCustomerName)")
        print("   - Phone: \(finalCustomerPhone)")
        print("   - Order Type: \(dbOrderType)")
        print("   - Items: \(items.count)")
        print("   - Total: $\(String(format: "%.2f", total))")

        let orderResponse: OrderResponse = try await client
            .from("orders")
            .insert(orderSubmission)
            .select("id, order_number")  // Select both id and order_number
            .single()
            .execute()
            .value

        // Create order items
        for item in items {
            let itemSubtotal = item.totalPrice  // Use CartItem's totalPrice (includes customizations)

            // Use CartItem's customizationsList which handles both legacy and portion-based customizations
            let customizationsArray = item.customizationsList

            let orderItem = OrderItemSubmission(
                order_id: orderResponse.id,
                menu_item_id: Int(item.menuItem.id)!,  // Safe: validated above
                item_name: item.menuItem.name,
                item_price: item.menuItem.price,
                quantity: item.quantity,
                subtotal: itemSubtotal,
                special_instructions: item.specialInstructions,
                selected_options: item.selectedOptions.isEmpty ? nil : item.selectedOptions,
                customizations: customizationsArray.isEmpty ? nil : customizationsArray
            )

            print("   📦 Adding item: \(item.menuItem.name) x\(item.quantity)")
            if !customizationsArray.isEmpty {
                print("      🎛️ Customizations: \(customizationsArray.joined(separator: ", "))")
            }
            if let instructions = item.specialInstructions, !instructions.isEmpty {
                print("      📝 Instructions: \(instructions)")
            }

            try await client
                .from("order_items")
                .insert(orderItem)
                .execute()
        }

        print("✅ Order submitted successfully!")
        print("   📋 Order ID: \(orderResponse.id)")
        print("   🔢 Order Number: \(orderResponse.order_number)")

        return (orderResponse.id, orderResponse.order_number)
    }

    // MARK: - Fetch User Orders

    func fetchUserOrders() async throws -> [Order] {
        // Get current user session
        guard let session = try? await client.auth.session else {
            print("⚠️ No user session found, returning empty orders")
            return []
        }

        let userId = session.user.id.uuidString
        print("🔄 Fetching orders for user: \(userId)")

        // DTO for nested order items in response
        struct OrderWithItemsDTO: Codable {
            let id: String
            let order_number: String
            let store_id: Int
            let user_id: String?
            let customer_name: String?
            let customer_phone: String?
            let order_type: String
            let status: String
            let subtotal: Double
            let tax: Double
            let total: Double
            let created_at: String
            let estimated_ready_at: String?
            let order_items: [OrderItemDTO]
        }

        // Fetch orders with order_items in a single query
        let rawResponse = try await client
            .from("orders")
            .select("""
                id,
                order_number,
                store_id,
                user_id,
                customer_name,
                customer_phone,
                order_type,
                status,
                subtotal,
                tax,
                total,
                created_at,
                estimated_ready_at,
                order_items(*)
            """)
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()

        // Debug: Print raw JSON to see what we're getting
        if let jsonString = String(data: rawResponse.data, encoding: .utf8) {
            print("📊 Raw orders JSON (first 1000 chars):")
            print(String(jsonString.prefix(1000)))
        }

        let response: [OrderWithItemsDTO]
        do {
            response = try JSONDecoder().decode([OrderWithItemsDTO].self, from: rawResponse.data)
            print("✅ Fetched \(response.count) orders from Supabase")
        } catch {
            print("ORDER DECODE ERROR:", error)
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   Missing key: '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                case .typeMismatch(let type, let context):
                    print("   Type mismatch for type: \(type)")
                    print("   At path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                case .valueNotFound(let type, let context):
                    print("   Value not found for type: \(type)")
                    print("   At path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                case .dataCorrupted(let context):
                    print("   Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                @unknown default:
                    print("   Unknown decoding error")
                }
            }
            throw error
        }

        // Convert DTOs to Order models
        let orders = response.compactMap { dto -> Order? in
            // Create OrderDTO from response
            let orderDTO = OrderDTO(
                id: dto.id,
                order_number: dto.order_number,
                store_id: dto.store_id,
                user_id: dto.user_id,
                customer_name: dto.customer_name,
                customer_phone: dto.customer_phone,
                order_type: dto.order_type,
                status: dto.status,
                subtotal: dto.subtotal,
                tax: dto.tax,
                total: dto.total,
                created_at: dto.created_at,
                estimated_ready_at: dto.estimated_ready_at
            )

            let order = Order.from(dto: orderDTO, items: dto.order_items)
            print("   📦 Order \(order.orderNumber): \(order.items.count) items, status: \(order.status.rawValue)")
            return order
        }

        return orders
    }

    // MARK: - Favorites

    /// Toggle favorite status for a menu item
    func toggleFavorite(menuItemId: String) async throws -> Bool {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        guard let itemId = Int(menuItemId) else {
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid menu item ID: \(menuItemId)"])
        }

        let userId = session.user.id

        print("🔄 Toggling favorite for item \(itemId)")

        // Manually insert/delete in customer_favorites table
        struct FavoriteCheck: Codable {
            let customer_id: String
            let menu_item_id: Int
        }

        let check: [FavoriteCheck] = try await client
            .from("customer_favorites")
            .select()
            .eq("customer_id", value: userId.uuidString)
            .eq("menu_item_id", value: itemId)
            .execute()
            .value

        let isFavorited: Bool
        if check.isEmpty {
            // Add favorite
            struct NewFavorite: Codable {
                let customer_id: String
                let menu_item_id: Int
            }
            try await client
                .from("customer_favorites")
                .insert(NewFavorite(customer_id: userId.uuidString, menu_item_id: itemId))
                .execute()
            isFavorited = true
        } else {
            // Remove favorite
            try await client
                .from("customer_favorites")
                .delete()
                .eq("customer_id", value: userId.uuidString)
                .eq("menu_item_id", value: itemId)
                .execute()
            isFavorited = false
        }

        print(isFavorited ? "   ❤️ Added to favorites" : "   💔 Removed from favorites")

        return isFavorited
    }

    /// Get user's favorite menu items
    func getUserFavorites() async throws -> [MenuItem] {
        guard let session = try? await client.auth.session else {
            print("⚠️ No session, returning empty favorites")
            return []
        }

        let userId = session.user.id.uuidString

        print("🔄 Fetching favorites for user: \(userId)")

        struct FavoriteResponse: Codable {
            let id: Int
            let menu_item_id: Int
            let created_at: String
        }

        // Get favorite IDs
        let favorites: [FavoriteResponse] = try await client
            .from("customer_favorites")
            .select()
            .eq("customer_id", value: userId)
            .execute()
            .value

        print("✅ Found \(favorites.count) favorite items")

        // Fetch full menu items for these favorites
        if favorites.isEmpty {
            return []
        }

        let favoriteIds = favorites.map { $0.menu_item_id }

        // Fetch menu items
        let menuItems = try await fetchMenuItems()
        let favoriteItems = menuItems.filter { item in
            if let itemId = Int(item.id) {
                return favoriteIds.contains(itemId)
            }
            return false
        }

        return favoriteItems
    }

    /// Check if a menu item is favorited
    func isFavorited(menuItemId: String) async throws -> Bool {
        guard let session = try? await client.auth.session else {
            return false
        }

        guard let itemId = Int(menuItemId) else {
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid menu item ID: \(menuItemId)"])
        }

        let userId = session.user.id.uuidString

        struct FavoriteCheck: Codable {
            let count: Int
        }

        let response: [FavoriteCheck] = try await client
            .from("customer_favorites")
            .select("*", head: false, count: .exact)
            .eq("customer_id", value: userId)
            .eq("menu_item_id", value: itemId)
            .execute()
            .value

        return !response.isEmpty
    }

    // MARK: - User Profile

    /// Get user profile (dietary preferences, settings, etc.)
    func getUserProfile() async throws -> UserProfile {
        guard let session = try? await client.auth.session else {
            print("⚠️ No session, returning default profile")
            return UserProfile()
        }

        let userId = session.user.id.uuidString

        print("🔄 Fetching user profile for: \(userId)")

        struct ProfileResponse: Codable {
            let auth_user_id: String
            let full_name: String?
            let phone_number: String?
            let dietary_preferences: [String]?
            let allergens: [String]?
            let spicy_tolerance: String?
            let default_store_id: Int?
            let preferred_order_type: String?
        }

        do {
            let profile: ProfileResponse = try await client
                .from("customers")
                .select()
                .eq("auth_user_id", value: userId)
                .single()
                .execute()
                .value

            print("✅ Loaded user profile from Supabase")

            // Convert to UserProfile model
            let dietaryPrefs = Set(profile.dietary_preferences?.compactMap { DietaryTag(rawValue: $0) } ?? [])
            let allergens = Set(profile.allergens?.compactMap { DietaryTag(rawValue: $0) } ?? [])
            let spicyTolerance = SpicyTolerance(rawValue: profile.spicy_tolerance ?? "mild") ?? .mild

            return UserProfile(
                dietaryPreferences: dietaryPrefs,
                allergens: allergens,
                spicyTolerance: spicyTolerance
            )
        } catch {
            print("⚠️ Profile not found, will be created on first update")
            return UserProfile()
        }
    }

    /// Update user profile
    func updateUserProfile(_ profile: UserProfile) async throws {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let userId = session.user.id.uuidString

        print("🔄 Updating user profile")

        struct ProfileUpdate: Codable {
            let auth_user_id: String
            let dietary_preferences: [String]
            let allergens: [String]
            let spicy_tolerance: String
        }

        let update = ProfileUpdate(
            auth_user_id: userId,
            dietary_preferences: profile.dietaryPreferences.map { $0.rawValue },
            allergens: profile.allergens.map { $0.rawValue },
            spicy_tolerance: profile.spicyTolerance.rawValue
        )

        // Upsert profile
        try await client
            .from("customers")
            .upsert(update)
            .execute()

        print("✅ User profile updated successfully")
    }

    // MARK: - Addresses

    /// Get user's addresses
    func getUserAddresses() async throws -> [Address] {
        guard let session = try? await client.auth.session else {
            print("⚠️ No session, returning empty addresses")
            return []
        }

        let userId = session.user.id.uuidString

        print("🔄 Fetching addresses for user: \(userId)")

        struct AddressResponse: Codable {
            let id: Int
            let customer_id: String
            let label: String?
            let street_address: String
            let apartment: String?
            let city: String
            let state: String
            let zip_code: String
            let phone_number: String?
            let delivery_instructions: String?
            let is_default: Bool
            let created_at: String
            let updated_at: String
        }

        let addresses: [AddressResponse] = try await client
            .from("customer_addresses")
            .select()
            .eq("customer_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ Found \(addresses.count) addresses")

        // Convert to Address models
        let dateFormatter = ISO8601DateFormatter()
        return addresses.map { response in
            Address(
                id: String(response.id),
                userId: response.customer_id,
                label: response.label ?? "",
                streetAddress: response.street_address,
                apartment: response.apartment,
                city: response.city,
                state: response.state,
                zipCode: response.zip_code,
                phoneNumber: response.phone_number,
                deliveryInstructions: response.delivery_instructions,
                isDefault: response.is_default,
                createdAt: dateFormatter.date(from: response.created_at) ?? Date(),
                updatedAt: dateFormatter.date(from: response.updated_at) ?? Date()
            )
        }
    }

    /// Add new address
    func addAddress(_ address: Address) async throws {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let userId = session.user.id.uuidString

        print("🔄 Adding new address: \(address.label)")

        struct NewAddress: Codable {
            let customer_id: String
            let label: String
            let street_address: String
            let apartment: String?
            let city: String
            let state: String
            let zip_code: String
            let phone_number: String?
            let delivery_instructions: String?
            let is_default: Bool
        }

        let newAddress = NewAddress(
            customer_id: userId,
            label: address.label,
            street_address: address.streetAddress,
            apartment: address.apartment,
            city: address.city,
            state: address.state,
            zip_code: address.zipCode,
            phone_number: address.phoneNumber,
            delivery_instructions: address.deliveryInstructions,
            is_default: address.isDefault
        )

        try await client
            .from("customer_addresses")
            .insert(newAddress)
            .execute()

        print("✅ Address added successfully")
    }

    /// Update existing address
    func updateAddress(_ address: Address) async throws {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        print("🔄 Updating address: \(address.label)")

        struct AddressUpdate: Codable {
            let label: String
            let street_address: String
            let apartment: String?
            let city: String
            let state: String
            let zip_code: String
            let phone_number: String?
            let delivery_instructions: String?
            let is_default: Bool
        }

        let update = AddressUpdate(
            label: address.label,
            street_address: address.streetAddress,
            apartment: address.apartment,
            city: address.city,
            state: address.state,
            zip_code: address.zipCode,
            phone_number: address.phoneNumber,
            delivery_instructions: address.deliveryInstructions,
            is_default: address.isDefault
        )

        guard let addressId = Int(address.id) else {
            throw NSError(domain: "Address", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid address ID"])
        }

        try await client
            .from("customer_addresses")
            .update(update)
            .eq("id", value: addressId)
            .execute()

        print("✅ Address updated successfully")
    }

    /// Delete address
    func deleteAddress(_ addressId: String) async throws {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        print("🔄 Deleting address: \(addressId)")

        guard let id = Int(addressId) else {
            throw NSError(domain: "Address", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid address ID"])
        }

        try await client
            .from("customer_addresses")
            .delete()
            .eq("id", value: id)
            .execute()

        print("✅ Address deleted successfully")
    }

    /// Set default address
    func setDefaultAddress(_ addressId: String) async throws {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        print("🔄 Setting default address: \(addressId)")

        guard let id = Int(addressId) else {
            throw NSError(domain: "Address", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid address ID"])
        }

        // Update the address to set is_default = true
        // The database trigger will automatically set all others to false
        struct DefaultUpdate: Codable {
            let is_default: Bool
        }

        try await client
            .from("customer_addresses")
            .update(DefaultUpdate(is_default: true))
            .eq("id", value: id)
            .execute()

        print("✅ Default address set successfully")
    }

    // MARK: - Ingredient Templates & Portion Customizations

    func fetchIngredientTemplates() async throws -> [IngredientTemplate] {
        print("🔍 Fetching ingredient templates...")

        let response = try await client
            .from("ingredient_templates")
            .select()
            .eq("is_active", value: true)
            .order("category")
            .order("display_order")
            .execute()

        let templates = try JSONDecoder().decode([IngredientTemplate].self, from: response.data)
        print("✅ Fetched \(templates.count) ingredient templates")

        // Debug: Show templates by category
        let grouped = Dictionary(grouping: templates, by: { $0.category })
        for category in IngredientCategory.allCases {
            if let items = grouped[category] {
                print("   📊 \(category.displayName): \(items.count) items")
            }
        }

        return templates
    }

    func fetchMenuItemCustomizations(for menuItemId: Int) async throws -> [MenuItemCustomization] {
        print("🔍 Fetching customizations for menu item \(menuItemId)...")

        let response = try await client
            .from("menu_item_customizations")
            .select()
            .eq("menu_item_id", value: menuItemId)
            .order("category")
            .order("display_order")
            .execute()

        let customizations = try JSONDecoder().decode([MenuItemCustomization].self, from: response.data)
        print("✅ Fetched \(customizations.count) customizations")

        // Debug: Print portion-based customizations
        let portionBased = customizations.filter { $0.supportsPortions }
        print("   📊 Portion-based: \(portionBased.count)")
        for custom in portionBased {
            print("      - \(custom.name) (\(custom.category ?? "no category"))")
        }

        return customizations
    }
}
