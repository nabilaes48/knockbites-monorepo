//
//  Store.swift
//  KnockBites Connect — Shared Models
//
//  Canonical store model shared across Business iOS, Customer iOS, and Website.
//

import Foundation

// MARK: - Shared Store

/// Canonical store model matching the Supabase `stores` table.
public struct SharedStore: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let address: String?
    public let city: String?
    public let state: String?
    public let zip: String?
    public let phoneNumber: String?
    public let latitude: Double?
    public let longitude: Double?
    public let hoursOpen: String?
    public let hoursClose: String?
    public let isOpen: Bool?
    public let storeCode: String?
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, address, city, state, zip
        case phoneNumber = "phone_number"
        case latitude, longitude
        case hoursOpen = "hours_open"
        case hoursClose = "hours_close"
        case isOpen = "is_open"
        case storeCode = "store_code"
        case createdAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        zip = try container.decodeIfPresent(String.self, forKey: .zip)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        hoursOpen = try container.decodeIfPresent(String.self, forKey: .hoursOpen)
        hoursClose = try container.decodeIfPresent(String.self, forKey: .hoursClose)
        isOpen = try container.decodeIfPresent(Bool.self, forKey: .isOpen)
        storeCode = try container.decodeIfPresent(String.self, forKey: .storeCode)

        if let createdStr = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = SharedDateFormatting.parseISO8601(createdStr)
        } else {
            createdAt = nil
        }
    }

    public init(
        id: Int,
        name: String,
        address: String?,
        city: String?,
        state: String?,
        zip: String?,
        phoneNumber: String?,
        latitude: Double?,
        longitude: Double?,
        hoursOpen: String?,
        hoursClose: String?,
        isOpen: Bool?,
        storeCode: String?,
        createdAt: Date?
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zip = zip
        self.phoneNumber = phoneNumber
        self.latitude = latitude
        self.longitude = longitude
        self.hoursOpen = hoursOpen
        self.hoursClose = hoursClose
        self.isOpen = isOpen
        self.storeCode = storeCode
        self.createdAt = createdAt
    }

    /// Formatted full address
    public var formattedAddress: String? {
        guard let address = address else { return nil }
        var parts = [address]
        if let city = city {
            parts.append(city)
        }
        if let state = state, let zip = zip {
            parts.append("\(state) \(zip)")
        }
        return parts.joined(separator: ", ")
    }

    /// Check if store has valid coordinates for mapping
    public var hasValidCoordinates: Bool {
        guard let lat = latitude, let lon = longitude else { return false }
        return lat != 0 && lon != 0
    }
}
