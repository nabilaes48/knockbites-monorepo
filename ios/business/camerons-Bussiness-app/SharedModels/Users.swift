//
//  Users.swift
//  KnockBites Connect — Shared Models
//
//  Canonical user/customer models shared across Business iOS, Customer iOS, and Website.
//  Supports field aliases (phone/phone_number, full_name/first_name+last_name).
//

import Foundation

// MARK: - Shared Customer

/// Canonical customer model matching the Supabase `customers` table.
/// Supports multiple naming conventions for backwards compatibility.
public struct SharedCustomer: Codable, Identifiable {
    public let id: String
    public let authUserId: String?
    public let email: String?
    public let fullName: String?
    public let firstName: String?
    public let lastName: String?
    public let avatarUrl: String?
    public let dietaryPreferences: [String]?
    public let allergens: [String]?
    public let spicyTolerance: String?
    public let defaultStoreId: Int?
    public let preferredOrderType: String?
    public let createdAt: Date?
    public let updatedAt: Date?

    // Phone fields - support both naming conventions
    private let _phone: String?
    private let _phoneNumber: String?

    /// Resolved phone from available fields
    public var phone: String? {
        _phone ?? _phoneNumber
    }

    /// Computed display name from available fields
    public var displayName: String {
        if let fullName = fullName, !fullName.isEmpty {
            return fullName
        }
        if let first = firstName, let last = lastName {
            return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        }
        if let first = firstName, !first.isEmpty {
            return first
        }
        if let email = email, !email.isEmpty {
            return email.components(separatedBy: "@").first ?? email
        }
        return "Customer"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case email
        case fullName = "full_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case _phone = "phone"
        case _phoneNumber = "phone_number"
        case avatarUrl = "avatar_url"
        case dietaryPreferences = "dietary_preferences"
        case allergens
        case spicyTolerance = "spicy_tolerance"
        case defaultStoreId = "default_store_id"
        case preferredOrderType = "preferred_order_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        authUserId = try container.decodeIfPresent(String.self, forKey: .authUserId)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        _phone = try container.decodeIfPresent(String.self, forKey: ._phone)
        _phoneNumber = try container.decodeIfPresent(String.self, forKey: ._phoneNumber)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        dietaryPreferences = try container.decodeIfPresent([String].self, forKey: .dietaryPreferences)
        allergens = try container.decodeIfPresent([String].self, forKey: .allergens)
        spicyTolerance = try container.decodeIfPresent(String.self, forKey: .spicyTolerance)
        defaultStoreId = try container.decodeIfPresent(Int.self, forKey: .defaultStoreId)
        preferredOrderType = try container.decodeIfPresent(String.self, forKey: .preferredOrderType)

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
        id: String,
        authUserId: String?,
        email: String?,
        fullName: String?,
        firstName: String?,
        lastName: String?,
        phone: String?,
        avatarUrl: String?,
        dietaryPreferences: [String]?,
        allergens: [String]?,
        spicyTolerance: String?,
        defaultStoreId: Int?,
        preferredOrderType: String?,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.authUserId = authUserId
        self.email = email
        self.fullName = fullName
        self.firstName = firstName
        self.lastName = lastName
        self._phone = phone
        self._phoneNumber = nil
        self.avatarUrl = avatarUrl
        self.dietaryPreferences = dietaryPreferences
        self.allergens = allergens
        self.spicyTolerance = spicyTolerance
        self.defaultStoreId = defaultStoreId
        self.preferredOrderType = preferredOrderType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Shared Customer Address

/// Canonical customer address model matching the Supabase `customer_addresses` table.
public struct SharedCustomerAddress: Codable, Identifiable {
    public let id: Int
    public let customerId: String
    public let label: String?
    public let streetAddress: String
    public let apartment: String?
    public let city: String
    public let state: String
    public let zipCode: String
    public let phoneNumber: String?
    public let deliveryInstructions: String?
    public let isDefault: Bool?
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case customerId = "customer_id"
        case label
        case streetAddress = "street_address"
        case apartment
        case city, state
        case zipCode = "zip_code"
        case phoneNumber = "phone_number"
        case deliveryInstructions = "delivery_instructions"
        case isDefault = "is_default"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        customerId = try container.decode(String.self, forKey: .customerId)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        streetAddress = try container.decode(String.self, forKey: .streetAddress)
        apartment = try container.decodeIfPresent(String.self, forKey: .apartment)
        city = try container.decode(String.self, forKey: .city)
        state = try container.decode(String.self, forKey: .state)
        zipCode = try container.decode(String.self, forKey: .zipCode)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        deliveryInstructions = try container.decodeIfPresent(String.self, forKey: .deliveryInstructions)
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault)

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

    /// Formatted full address
    public var formattedAddress: String {
        var parts = [streetAddress]
        if let apt = apartment, !apt.isEmpty {
            parts.append("Apt \(apt)")
        }
        parts.append("\(city), \(state) \(zipCode)")
        return parts.joined(separator: ", ")
    }
}

// MARK: - Shared Customer Favorite

/// Canonical customer favorite model matching the Supabase `customer_favorites` table.
public struct SharedCustomerFavorite: Codable, Identifiable {
    public let id: Int
    public let customerId: String
    public let menuItemId: Int
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case customerId = "customer_id"
        case menuItemId = "menu_item_id"
        case createdAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        customerId = try container.decode(String.self, forKey: .customerId)
        menuItemId = try container.decode(Int.self, forKey: .menuItemId)

        if let createdStr = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = SharedDateFormatting.parseISO8601(createdStr)
        } else {
            createdAt = nil
        }
    }
}

// MARK: - Shared User Profile (Business Staff)

/// Canonical user profile model matching the Supabase `user_profiles` table.
/// Used for Business app staff accounts.
public struct SharedUserProfile: Codable, Identifiable {
    public let id: String
    public let fullName: String?
    public let role: String?
    public let storeIds: [Int]?
    public let permissions: [String]?
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case role
        case storeIds = "store_ids"
        case permissions
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        storeIds = try container.decodeIfPresent([Int].self, forKey: .storeIds)
        permissions = try container.decodeIfPresent([String].self, forKey: .permissions)

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
        id: String,
        fullName: String?,
        role: String?,
        storeIds: [Int]?,
        permissions: [String]?,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.fullName = fullName
        self.role = role
        self.storeIds = storeIds
        self.permissions = permissions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
