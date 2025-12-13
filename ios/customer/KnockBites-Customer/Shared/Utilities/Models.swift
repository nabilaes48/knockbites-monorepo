//
//  Models.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import Foundation
import CoreLocation

// MARK: - Store
struct Store: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let address: String
    let phoneNumber: String
    let coordinates: Coordinates
    let hours: StoreHours
    let imageURL: String?
    var isOpen: Bool {
        hours.isCurrentlyOpen
    }
}

struct Coordinates: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct StoreHours: Codable, Hashable {
    let openTime: String // "08:00"
    let closeTime: String // "22:00"
    let daysOpen: [Int] // 0-6 (Sunday-Saturday)

    var isCurrentlyOpen: Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now) - 1 // Convert to 0-6

        guard daysOpen.contains(weekday) else { return false }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let openDate = formatter.date(from: openTime),
              let closeDate = formatter.date(from: closeTime) else {
            return false
        }

        let currentTime = formatter.string(from: now)
        guard let currentDate = formatter.date(from: currentTime) else { return false }

        return currentDate >= openDate && currentDate <= closeDate
    }

    static let allDay = StoreHours(
        openTime: "08:00",
        closeTime: "22:00",
        daysOpen: [0, 1, 2, 3, 4, 5, 6]
    )
}

// MARK: - Category
struct Category: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let icon: String
    let sortOrder: Int

    static let appetizers = Category(id: "cat_1", name: "Appetizers", icon: "🥗", sortOrder: 1)
    static let entrees = Category(id: "cat_2", name: "Entrees", icon: "🍽️", sortOrder: 2)
    static let burgers = Category(id: "cat_3", name: "Burgers", icon: "🍔", sortOrder: 3)
    static let sandwiches = Category(id: "cat_4", name: "Sandwiches", icon: "🥪", sortOrder: 4)
    static let salads = Category(id: "cat_5", name: "Salads", icon: "🥗", sortOrder: 5)
    static let desserts = Category(id: "cat_6", name: "Desserts", icon: "🍰", sortOrder: 6)
    static let beverages = Category(id: "cat_7", name: "Beverages", icon: "🥤", sortOrder: 7)

    static let all = [appetizers, entrees, burgers, sandwiches, salads, desserts, beverages]
}

// MARK: - MenuItem
struct MenuItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let categoryId: String
    let imageURL: String
    let isAvailable: Bool
    let dietaryInfo: [DietaryTag]

    // Legacy customization groups (keep for backward compatibility)
    let customizationGroups: [CustomizationGroup]

    // NEW: Portion-based customizations
    var portionCustomizations: [MenuItemCustomization]?

    let calories: Int?
    let prepTime: Int // minutes

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    var hasPortionCustomizations: Bool {
        portionCustomizations?.contains { $0.supportsPortions } ?? false
    }
}

enum DietaryTag: String, Codable, Hashable, CaseIterable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten Free"
    case dairyFree = "Dairy Free"
    case nutFree = "Nut Free"
    case spicy = "Spicy"
    case keto = "Keto"

    var icon: String {
        switch self {
        case .vegetarian: return "leaf.fill"
        case .vegan: return "leaf.circle.fill"
        case .glutenFree: return "g.circle.fill"
        case .dairyFree: return "drop.fill"
        case .nutFree: return "n.circle.fill"
        case .spicy: return "flame.fill"
        case .keto: return "k.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .vegetarian, .vegan: return "green"
        case .glutenFree: return "orange"
        case .dairyFree: return "blue"
        case .nutFree: return "brown"
        case .spicy: return "red"
        case .keto: return "purple"
        }
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    var dietaryPreferences: Set<DietaryTag>
    var allergens: Set<DietaryTag>
    var spicyTolerance: SpicyTolerance

    init(dietaryPreferences: Set<DietaryTag> = [],
         allergens: Set<DietaryTag> = [],
         spicyTolerance: SpicyTolerance = .medium) {
        self.dietaryPreferences = dietaryPreferences
        self.allergens = allergens
        self.spicyTolerance = spicyTolerance
    }
}

// MARK: - Address
struct Address: Identifiable, Codable {
    let id: String
    let userId: String
    var label: String  // "Home", "Work", "Mom's House"
    var streetAddress: String
    var apartment: String?
    var city: String
    var state: String
    var zipCode: String
    var phoneNumber: String?
    var deliveryInstructions: String?
    var isDefault: Bool
    let createdAt: Date
    let updatedAt: Date

    init(id: String = UUID().uuidString,
         userId: String = "",
         label: String = "",
         streetAddress: String = "",
         apartment: String? = nil,
         city: String = "",
         state: String = "",
         zipCode: String = "",
         phoneNumber: String? = nil,
         deliveryInstructions: String? = nil,
         isDefault: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.label = label
        self.streetAddress = streetAddress
        self.apartment = apartment
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.phoneNumber = phoneNumber
        self.deliveryInstructions = deliveryInstructions
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var fullAddress: String {
        var parts = [streetAddress]
        if let apt = apartment, !apt.isEmpty {
            parts.append("Apt \(apt)")
        }
        parts.append("\(city), \(state) \(zipCode)")
        return parts.joined(separator: ", ")
    }

    var isValid: Bool {
        !label.isEmpty &&
        !streetAddress.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !zipCode.isEmpty
    }
}

// MARK: - Payment Methods
struct PaymentMethod: Identifiable, Codable {
    let id: String
    let type: PaymentType
    let displayName: String
    let lastFourDigits: String?
    let expiryMonth: Int?
    let expiryYear: Int?
    let isDefault: Bool
    let cardBrand: CardBrand?

    var formattedExpiry: String? {
        guard let month = expiryMonth, let year = expiryYear else { return nil }
        return String(format: "%02d/%02d", month, year % 100)
    }

    var isExpired: Bool {
        guard let month = expiryMonth, let year = expiryYear else { return false }
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        if year < currentYear {
            return true
        } else if year == currentYear && month < currentMonth {
            return true
        }
        return false
    }
}

enum PaymentType: String, Codable {
    case card = "Card"
    case applePay = "Apple Pay"
    case googlePay = "Google Pay"

    var icon: String {
        switch self {
        case .card: return "creditcard.fill"
        case .applePay: return "applelogo"
        case .googlePay: return "g.circle.fill"
        }
    }
}

enum CardBrand: String, Codable, CaseIterable {
    case visa = "Visa"
    case mastercard = "Mastercard"
    case amex = "American Express"
    case discover = "Discover"
    case other = "Other"

    var icon: String {
        switch self {
        case .visa: return "v.square.fill"
        case .mastercard: return "m.square.fill"
        case .amex: return "a.square.fill"
        case .discover: return "d.square.fill"
        case .other: return "creditcard.fill"
        }
    }

    var color: String {
        switch self {
        case .visa: return "blue"
        case .mastercard: return "orange"
        case .amex: return "green"
        case .discover: return "orange"
        case .other: return "gray"
        }
    }
}

enum SpicyTolerance: String, Codable, CaseIterable {
    case none = "No Spicy"
    case mild = "Mild"
    case medium = "Medium"
    case hot = "Hot"
    case extraHot = "Extra Hot"

    var icon: String {
        switch self {
        case .none: return "xmark.circle"
        case .mild: return "flame"
        case .medium: return "flame.fill"
        case .hot: return "flame.fill"
        case .extraHot: return "flame.fill"
        }
    }
}

// MARK: - Customization (Legacy)
struct CustomizationGroup: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let isRequired: Bool
    let allowMultiple: Bool
    let options: [CustomizationOption]
}

struct CustomizationOption: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let priceModifier: Double // 0 for no change, positive for upcharge
    let isDefault: Bool

    var formattedPrice: String {
        if priceModifier == 0 {
            return "No charge"
        } else if priceModifier > 0 {
            return String(format: "+$%.2f", priceModifier)
        } else {
            return String(format: "-$%.2f", abs(priceModifier))
        }
    }
}

// MARK: - Portion-Based Customizations

enum PortionLevel: String, Codable, CaseIterable {
    case none = "none"
    case light = "light"
    case regular = "regular"
    case extra = "extra"

    var emoji: String {
        switch self {
        case .none: return "○"
        case .light: return "◔"
        case .regular: return "◑"
        case .extra: return "●"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

struct PortionPricing: Codable, Hashable {
    let none: Double
    let light: Double
    let regular: Double
    let extra: Double

    init(none: Double = 0, light: Double = 0, regular: Double = 0, extra: Double = 0) {
        self.none = none
        self.light = light
        self.regular = regular
        self.extra = extra
    }

    subscript(level: PortionLevel) -> Double {
        switch level {
        case .none: return none
        case .light: return light
        case .regular: return regular
        case .extra: return extra
        }
    }
}

enum IngredientCategory: String, Codable, CaseIterable {
    case vegetables
    case sauces
    case extras

    var displayName: String {
        switch self {
        case .vegetables: return "Fresh Vegetables"
        case .sauces: return "Signature Sauces"
        case .extras: return "Premium Extras"
        }
    }

    var icon: String {
        switch self {
        case .vegetables: return "leaf.fill"
        case .sauces: return "drop.fill"
        case .extras: return "sparkles"
        }
    }

    var displayOrder: Int {
        switch self {
        case .vegetables: return 1
        case .sauces: return 2
        case .extras: return 3
        }
    }
}

struct IngredientTemplate: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let category: IngredientCategory
    let supportsPortions: Bool
    let portionPricing: PortionPricing
    let defaultPortion: PortionLevel
    let displayOrder: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, category
        case supportsPortions = "supports_portions"
        case portionPricing = "portion_pricing"
        case defaultPortion = "default_portion"
        case displayOrder = "display_order"
        case isActive = "is_active"
    }
}

struct MenuItemCustomization: Codable, Identifiable, Hashable {
    let id: Int
    let menuItemId: Int
    let name: String
    let type: String
    let category: String?
    let supportsPortions: Bool
    let portionPricing: PortionPricing?
    let defaultPortion: PortionLevel?
    let isRequired: Bool
    let displayOrder: Int

    // For legacy customization groups
    let options: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, type, category, options
        case menuItemId = "menu_item_id"
        case supportsPortions = "supports_portions"
        case portionPricing = "portion_pricing"
        case defaultPortion = "default_portion"
        case isRequired = "is_required"
        case displayOrder = "display_order"
    }

    var ingredientCategory: IngredientCategory? {
        guard let cat = category else { return nil }
        return IngredientCategory(rawValue: cat)
    }
}

// MARK: - Cart
struct CartItem: Identifiable, Codable {
    let id: String
    let menuItem: MenuItem
    var quantity: Int

    // Legacy format (keep for backward compatibility)
    let selectedOptions: [String: [String]] // groupId: [optionIds]

    // NEW: Portion selections
    var portionSelections: [Int: PortionLevel]? // customizationId: portionLevel

    let specialInstructions: String?

    var totalPrice: Double {
        var price = menuItem.price * Double(quantity)

        // Add legacy customization costs
        for (groupId, optionIds) in selectedOptions {
            if let group = menuItem.customizationGroups.first(where: { $0.id == groupId }) {
                for optionId in optionIds {
                    if let option = group.options.first(where: { $0.id == optionId }) {
                        price += option.priceModifier * Double(quantity)
                    }
                }
            }
        }

        // Add portion-based customization costs
        if let portions = portionSelections,
           let customizations = menuItem.portionCustomizations {
            for (customizationId, portion) in portions {
                if let customization = customizations.first(where: { $0.id == customizationId }),
                   let pricing = customization.portionPricing {
                    price += pricing[portion] * Double(quantity)
                }
            }
        }

        return price
    }

    // Generate human-readable customization list for order submission
    var customizationsList: [String] {
        var list: [String] = []

        // Legacy customizations
        for (groupId, optionIds) in selectedOptions {
            if let group = menuItem.customizationGroups.first(where: { $0.id == groupId }) {
                let selectedNames = optionIds.compactMap { optionId in
                    group.options.first(where: { $0.id == optionId })?.name
                }
                list.append(contentsOf: selectedNames.map { "\(group.name): \($0)" })
            }
        }

        // Portion-based customizations
        if let portions = portionSelections,
           let customizations = menuItem.portionCustomizations {
            for (customizationId, portion) in portions where portion != .none {
                if let customization = customizations.first(where: { $0.id == customizationId }) {
                    list.append("\(portion.displayName) \(customization.name)")
                }
            }
        }

        return list
    }

    var formattedTotalPrice: String {
        String(format: "$%.2f", totalPrice)
    }
}

// MARK: - Order
struct Order: Identifiable, Codable {
    let id: String
    let userId: String
    let storeId: String
    var items: [CartItem]
    let subtotal: Double
    let tax: Double
    let total: Double
    var status: OrderStatus
    let orderType: OrderType
    let createdAt: Date
    var estimatedReadyTime: Date?
    let orderNumber: String
    let scheduledFor: Date? // TODO: scheduledFor is unused - consider removing
    var store: Store?   // populated via storeId lookup

    var formattedSubtotal: String {
        String(format: "$%.2f", subtotal)
    }

    var formattedTax: String {
        String(format: "$%.2f", tax)
    }

    var formattedTotal: String {
        String(format: "$%.2f", total)
    }

    var isScheduled: Bool {
        guard let scheduledDate = scheduledFor else { return false }
        return scheduledDate > Date()
    }

    var formattedScheduledTime: String? {
        guard let scheduledDate = scheduledFor else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDate)
    }
}

enum OrderStatus: Codable, Equatable, Hashable {
    case scheduled
    case received
    case preparing
    case ready
    case completed
    case cancelled
    case unknown(String)

    var rawValue: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .received: return "Received"
        case .preparing: return "Preparing"
        case .ready: return "Ready"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .unknown(let value): return value
        }
    }

    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "scheduled": self = .scheduled
        case "received", "pending": self = .received
        case "preparing": self = .preparing
        case "ready": self = .ready
        case "completed": self = .completed
        case "cancelled": self = .cancelled
        default: self = .unknown(rawValue)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = OrderStatus(rawValue: rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var icon: String {
        switch self {
        case .scheduled: return "clock.fill"
        case .received: return "checkmark.circle.fill"
        case .preparing: return "flame.fill"
        case .ready: return "bag.fill"
        case .completed: return "hand.thumbsup.fill"
        case .cancelled: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .scheduled: return "purple"
        case .received: return "blue"
        case .preparing: return "orange"
        case .ready: return "green"
        case .completed: return "gray"
        case .cancelled: return "red"
        case .unknown: return "gray"
        }
    }

    var title: String { rawValue }

    var subtitle: String? {
        switch self {
        case .scheduled: return "Order scheduled for later"
        case .received: return "We've got your order"
        case .preparing: return "Cooking with care"
        case .ready: return "Ready for pickup"
        case .completed: return "Thanks for ordering"
        case .cancelled: return nil
        case .unknown: return nil
        }
    }
}

enum OrderType: Codable, Equatable, Hashable {
    case pickup
    case delivery
    case dineIn
    case unknown(String)

    var rawValue: String {
        switch self {
        case .pickup: return "Pickup"
        case .delivery: return "Delivery"
        case .dineIn: return "Dine In"
        case .unknown(let value): return value
        }
    }

    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "pickup": self = .pickup
        case "delivery": self = .delivery
        case "dine-in", "dine_in", "dine in", "dinein": self = .dineIn
        default: self = .unknown(rawValue)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = OrderType(rawValue: rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var icon: String {
        switch self {
        case .pickup: return "bag.fill"
        case .delivery: return "car.fill"
        case .dineIn: return "fork.knife"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Order DTO Conversion
extension Order {
    static func from(dto: OrderDTO, items: [OrderItemDTO]) -> Order {
        var order = Order(
            id: dto.id,
            userId: dto.user_id ?? "",
            storeId: String(dto.store_id),
            items: items.map { CartItem.from(dto: $0) },
            subtotal: dto.subtotal,
            tax: dto.tax,
            total: dto.total,
            status: OrderStatus(rawValue: dto.status),
            orderType: OrderType(rawValue: dto.order_type),
            createdAt: ISO8601DateFormatter().date(from: dto.created_at) ?? Date(),
            estimatedReadyTime: dto.estimated_ready_at.flatMap {
                ISO8601DateFormatter().date(from: $0)
            },
            orderNumber: dto.order_number,
            scheduledFor: nil
        )
        return order
    }
}

// MARK: - CartItem DTO Conversion
extension CartItem {
    static func from(dto: OrderItemDTO) -> CartItem {
        CartItem(
            id: String(dto.id),
            menuItem: MenuItem(
                id: String(dto.menu_item_id),
                name: dto.item_name,
                description: "",
                price: dto.item_price,
                categoryId: "",
                imageURL: "",
                isAvailable: true,
                dietaryInfo: [],
                customizationGroups: [],
                portionCustomizations: nil,
                calories: nil,
                prepTime: 15
            ),
            quantity: dto.quantity,
            selectedOptions: dto.selected_options ?? [:],
            portionSelections: nil,
            specialInstructions: dto.special_instructions
        )
    }
}
