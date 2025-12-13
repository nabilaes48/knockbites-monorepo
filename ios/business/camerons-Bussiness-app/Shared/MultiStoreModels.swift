//
//  MultiStoreModels.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import Foundation

// MARK: - Organization

/// Top-level entity that owns multiple restaurant locations
struct Organization: Identifiable, Codable {
    let id: Int
    let name: String
    let subdomain: String?
    let ownerId: Int?
    let subscriptionTier: String
    let logoUrl: String?
    let website: String?
    let isActive: Bool
    let settings: [String: AnyCodable]?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, subdomain
        case ownerId = "owner_id"
        case subscriptionTier = "subscription_tier"
        case logoUrl = "logo_url"
        case website
        case isActive = "is_active"
        case settings
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Store Location

/// Individual restaurant location belonging to an organization
struct StoreLocation: Identifiable, Codable {
    let id: Int
    let organizationId: Int
    let name: String
    let storeCode: String

    // Location
    let address: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?

    // Contact
    let phone: String?
    let email: String?

    // Operating info
    let timezone: String
    let currency: String
    let openingDate: Date?
    let isActive: Bool

    // Staff
    let managerId: Int?

    // Settings
    let settings: [String: AnyCodable]?

    // Timestamps
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case name
        case storeCode = "store_code"
        case address, city, state, zip, country
        case latitude, longitude
        case phone, email
        case timezone, currency
        case openingDate = "opening_date"
        case isActive = "is_active"
        case managerId = "manager_id"
        case settings
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Computed properties
    var fullAddress: String {
        var components: [String] = []
        if let address = address { components.append(address) }
        if let city = city { components.append(city) }
        if let state = state, let zip = zip {
            components.append("\(state) \(zip)")
        } else if let state = state {
            components.append(state)
        }
        return components.joined(separator: ", ")
    }

    var displayName: String {
        return name
    }
}

// MARK: - Store Location Assignment

/// Maps staff members to store locations with roles
struct StoreLocationAssignment: Identifiable, Codable {
    let id: Int
    let userId: Int
    let storeId: Int
    let role: StaffRole
    let isPrimary: Bool
    let schedule: [String: AnyCodable]?
    let assignedAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case storeId = "store_id"
        case role
        case isPrimary = "is_primary"
        case schedule
        case assignedAt = "assigned_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Staff Role

enum StaffRole: String, Codable, CaseIterable {
    case manager = "manager"
    case staff = "staff"
    case kitchen = "kitchen"
    case delivery = "delivery"

    var displayName: String {
        switch self {
        case .manager: return "Manager"
        case .staff: return "Staff"
        case .kitchen: return "Kitchen"
        case .delivery: return "Delivery"
        }
    }

    var icon: String {
        switch self {
        case .manager: return "star.fill"
        case .staff: return "person.fill"
        case .kitchen: return "flame.fill"
        case .delivery: return "shippingbox.fill"
        }
    }
}

// MARK: - User Store Access

/// Combined view of user's access to a store
struct UserStoreAccess: Identifiable {
    let id: Int  // store_id
    let storeId: Int
    let storeName: String
    let storeCode: String
    let organizationId: Int
    let organizationName: String
    let role: StaffRole
    let isPrimary: Bool
    let isActive: Bool

    var displayText: String {
        return isPrimary ? "\(storeName) (Primary)" : storeName
    }
}

// MARK: - Organization Analytics

/// Analytics data for an organization across all stores
struct OrganizationAnalytics: Identifiable {
    let id: Int  // organization_id
    let organizationId: Int
    let organizationName: String
    let totalStores: Int
    let activeStores: Int
    let totalRevenue: Double
    let totalOrders: Int
    let averageOrderValue: Double
    let topPerformingStoreId: Int?
    let topPerformingStoreName: String?
}

// MARK: - Store Performance

/// Performance metrics for a single store
struct StorePerformance: Identifiable {
    let id: Int  // store_id
    let storeId: Int
    let storeName: String
    let storeCode: String
    let ordersCount: Int
    let revenue: Double
    let revenueChangePct: Double
    let avgOrderValue: Double
    let topSellingItem: String?

    var isPerforming: Bool {
        return revenueChangePct >= 0
    }

    var performanceIndicator: String {
        if revenueChangePct > 10 {
            return "🔥 Strong"
        } else if revenueChangePct > 0 {
            return "✅ Growing"
        } else if revenueChangePct > -10 {
            return "⚠️ Declining"
        } else {
            return "🔴 Concern"
        }
    }
}

// MARK: - Store Location Details

/// Combined store location information with organization data
struct StoreLocationDetails: Identifiable {
    let id: Int  // store_id
    let storeId: Int
    let storeName: String
    let storeCode: String
    let address: String?
    let city: String?
    let state: String?
    let zip: String?
    let phone: String?
    let email: String?
    let storeActive: Bool
    let organizationId: Int
    let organizationName: String
    let subscriptionTier: String
    let organizationActive: Bool
}

// MARK: - Any Codable (Helper)

/// Helper for encoding/decoding JSON with mixed types
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Cannot encode AnyCodable"
                )
            )
        }
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, CaseIterable {
    case basic = "basic"
    case premium = "premium"
    case enterprise = "enterprise"

    var displayName: String {
        return rawValue.capitalized
    }

    var maxStores: Int {
        switch self {
        case .basic: return 1
        case .premium: return 5
        case .enterprise: return 999  // Unlimited
        }
    }

    var features: [String] {
        switch self {
        case .basic:
            return [
                "1 Store Location",
                "Basic Analytics",
                "Customer Loyalty",
                "Marketing Campaigns"
            ]
        case .premium:
            return [
                "Up to 5 Store Locations",
                "Advanced Analytics",
                "Multi-Store Reports",
                "Priority Support",
                "Custom Branding"
            ]
        case .enterprise:
            return [
                "Unlimited Stores",
                "Organization-Wide Analytics",
                "API Access",
                "Dedicated Support",
                "Custom Integrations",
                "White Label Options"
            ]
        }
    }

    var monthlyPrice: Double {
        switch self {
        case .basic: return 49.99
        case .premium: return 149.99
        case .enterprise: return 499.99
        }
    }
}
