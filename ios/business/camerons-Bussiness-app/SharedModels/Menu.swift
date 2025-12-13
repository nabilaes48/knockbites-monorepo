//
//  Menu.swift
//  KnockBites Connect — Shared Models
//
//  Canonical menu models shared across Business iOS, Customer iOS, and Website.
//  Supports field aliases for backwards compatibility (price/base_price, prep_time/preparation_time).
//

import Foundation

// MARK: - Shared Menu Item

/// Canonical menu item model matching the Supabase `menu_items` table.
/// Supports multiple price field names for backwards compatibility.
public struct SharedMenuItem: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let description: String?
    public let categoryId: Int?
    public let imageUrl: String?
    public let isAvailable: Bool
    public let isFeatured: Bool?
    public let calories: Int?
    public let allergens: [String]?
    public let tags: [String]?
    public let createdAt: Date?
    public let updatedAt: Date?

    // Price fields - support multiple naming conventions
    private let _price: Double?
    private let _basePrice: Double?
    private let _itemPrice: Double?

    // Prep time fields - support multiple naming conventions
    private let _prepTime: Int?
    private let _preparationTime: Int?

    /// Resolved price from available fields
    public var price: Double {
        _price ?? _basePrice ?? _itemPrice ?? 0.0
    }

    /// Resolved prep time from available fields
    public var prepTime: Int {
        _prepTime ?? _preparationTime ?? 15
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case categoryId = "category_id"
        case imageUrl = "image_url"
        case isAvailable = "is_available"
        case isFeatured = "is_featured"
        case calories, allergens, tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        // Price aliases
        case _price = "price"
        case _basePrice = "base_price"
        case _itemPrice = "item_price"
        // Prep time aliases
        case _prepTime = "prep_time"
        case _preparationTime = "preparation_time"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        categoryId = try container.decodeIfPresent(Int.self, forKey: .categoryId)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable) ?? true
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured)
        calories = try container.decodeIfPresent(Int.self, forKey: .calories)
        allergens = try container.decodeIfPresent([String].self, forKey: .allergens)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)

        // Price fields
        _price = try container.decodeIfPresent(Double.self, forKey: ._price)
        _basePrice = try container.decodeIfPresent(Double.self, forKey: ._basePrice)
        _itemPrice = try container.decodeIfPresent(Double.self, forKey: ._itemPrice)

        // Prep time fields
        _prepTime = try container.decodeIfPresent(Int.self, forKey: ._prepTime)
        _preparationTime = try container.decodeIfPresent(Int.self, forKey: ._preparationTime)

        // Date parsing
        if let createdStr = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = SharedDateFormatting.parseISO8601(createdStr)
        } else {
            createdAt = nil
        }

        if let updatedStr = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = SharedDateFormatting.parseISO8601(updatedStr)
        } else {
            updatedAt = nil
        }
    }

    public init(
        id: Int,
        name: String,
        description: String?,
        categoryId: Int?,
        imageUrl: String?,
        isAvailable: Bool,
        isFeatured: Bool?,
        calories: Int?,
        allergens: [String]?,
        tags: [String]?,
        price: Double,
        prepTime: Int,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.categoryId = categoryId
        self.imageUrl = imageUrl
        self.isAvailable = isAvailable
        self.isFeatured = isFeatured
        self.calories = calories
        self.allergens = allergens
        self.tags = tags
        self._price = price
        self._basePrice = nil
        self._itemPrice = nil
        self._prepTime = prepTime
        self._preparationTime = nil
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Shared Menu Category

/// Canonical menu category model matching the Supabase `menu_categories` table.
public struct SharedMenuCategory: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let icon: String?
    public let description: String?
    public let displayOrder: Int?
    public let isActive: Bool?
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, icon, description
        case displayOrder = "display_order"
        case isActive = "is_active"
        case createdAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)

        if let createdStr = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = SharedDateFormatting.parseISO8601(createdStr)
        } else {
            createdAt = nil
        }
    }

    public init(
        id: Int,
        name: String,
        icon: String?,
        description: String?,
        displayOrder: Int?,
        isActive: Bool?,
        createdAt: Date?
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.displayOrder = displayOrder
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

// MARK: - Shared Menu Item Customization

/// Canonical customization model matching the Supabase `menu_item_customizations` table.
public struct SharedMenuItemCustomization: Codable, Identifiable {
    public let id: Int
    public let menuItemId: Int?
    public let name: String
    public let category: String?
    public let type: String?
    public let options: CustomizationOptions?
    public let supportsPortions: Bool?
    public let defaultPortion: String?
    public let portionPricing: PortionPricing?
    public let displayOrder: Int?
    public let isRequired: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case menuItemId = "menu_item_id"
        case name, category, type, options
        case supportsPortions = "supports_portions"
        case defaultPortion = "default_portion"
        case portionPricing = "portion_pricing"
        case displayOrder = "display_order"
        case isRequired = "is_required"
    }

    // MARK: - Flexible Options Type

    public enum CustomizationOptions: Codable {
        case array([String])
        case object([String: OptionDetails])

        public struct OptionDetails: Codable {
            public let price: Double?
            public let isDefault: Bool?

            enum CodingKeys: String, CodingKey {
                case price
                case isDefault = "is_default"
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let array = try? container.decode([String].self) {
                self = .array(array)
            } else if let object = try? container.decode([String: OptionDetails].self) {
                self = .object(object)
            } else {
                self = .array([])
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .array(let array):
                try container.encode(array)
            case .object(let object):
                try container.encode(object)
            }
        }
    }

    // MARK: - Portion Pricing Type

    public struct PortionPricing: Codable {
        public let none: Double?
        public let light: Double?
        public let regular: Double?
        public let extra: Double?

        public init(none: Double?, light: Double?, regular: Double?, extra: Double?) {
            self.none = none
            self.light = light
            self.regular = regular
            self.extra = extra
        }
    }
}

// MARK: - Shared Ingredient Template

/// Canonical ingredient template model matching the Supabase `ingredient_templates` table.
public struct SharedIngredientTemplate: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let category: String
    public let supportsPortions: Bool?
    public let defaultPortion: String?
    public let portionPricing: SharedMenuItemCustomization.PortionPricing?
    public let displayOrder: Int?
    public let isActive: Bool
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, category
        case supportsPortions = "supports_portions"
        case defaultPortion = "default_portion"
        case portionPricing = "portion_pricing"
        case displayOrder = "display_order"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        supportsPortions = try container.decodeIfPresent(Bool.self, forKey: .supportsPortions)
        defaultPortion = try container.decodeIfPresent(String.self, forKey: .defaultPortion)
        portionPricing = try container.decodeIfPresent(SharedMenuItemCustomization.PortionPricing.self, forKey: .portionPricing)
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true

        if let createdStr = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = SharedDateFormatting.parseISO8601(createdStr)
        } else {
            createdAt = nil
        }

        if let updatedStr = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = SharedDateFormatting.parseISO8601(updatedStr)
        } else {
            updatedAt = nil
        }
    }
}
