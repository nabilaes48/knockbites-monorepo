//
//  Marketing.swift
//  KnockBites Connect — Shared Models
//
//  Canonical marketing models shared across Business iOS, Customer iOS, and Website.
//  Includes coupons and automated campaigns.
//

import Foundation

// MARK: - Discount Type

/// Canonical discount type values.
public enum SharedDiscountType: String, Codable, CaseIterable {
    case percentage = "percentage"
    case fixed = "fixed"

    public var displayName: String {
        switch self {
        case .percentage: return "Percentage"
        case .fixed: return "Fixed Amount"
        }
    }
}

// MARK: - Shared Coupon

/// Canonical coupon model matching the Supabase `coupons` table.
public struct SharedCoupon: Codable, Identifiable {
    public let id: Int
    public let storeId: Int?
    public let code: String
    public let name: String
    public let description: String?
    public let discountType: SharedDiscountType
    public let discountValue: Double
    public let minOrderValue: Double?
    public let maxDiscountAmount: Double?
    public let firstOrderOnly: Bool?
    public let maxUsesTotal: Int?
    public let maxUsesPerCustomer: Int
    public let currentUses: Int?
    public let startDate: Date
    public let endDate: Date?
    public let isActive: Bool
    public let isFeatured: Bool?
    public let activeDaysOfWeek: [Int]?
    public let activeHoursStart: String?
    public let activeHoursEnd: String?
    public let targetSegment: String?
    public let minimumTierId: Int?
    public let applicableOrderTypes: [String]?
    public let applicableMenuCategories: [Int]?
    public let createdAt: Date?
    public let createdBy: String?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case code, name, description
        case discountType = "discount_type"
        case discountValue = "discount_value"
        case minOrderValue = "min_order_value"
        case maxDiscountAmount = "max_discount_amount"
        case firstOrderOnly = "first_order_only"
        case maxUsesTotal = "max_uses_total"
        case maxUsesPerCustomer = "max_uses_per_customer"
        case currentUses = "current_uses"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case isFeatured = "is_featured"
        case activeDaysOfWeek = "active_days_of_week"
        case activeHoursStart = "active_hours_start"
        case activeHoursEnd = "active_hours_end"
        case targetSegment = "target_segment"
        case minimumTierId = "minimum_tier_id"
        case applicableOrderTypes = "applicable_order_types"
        case applicableMenuCategories = "applicable_menu_categories"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        storeId = try container.decodeIfPresent(Int.self, forKey: .storeId)
        code = try container.decode(String.self, forKey: .code)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        discountType = try container.decode(SharedDiscountType.self, forKey: .discountType)
        discountValue = try container.decode(Double.self, forKey: .discountValue)
        minOrderValue = try container.decodeIfPresent(Double.self, forKey: .minOrderValue)
        maxDiscountAmount = try container.decodeIfPresent(Double.self, forKey: .maxDiscountAmount)
        firstOrderOnly = try container.decodeIfPresent(Bool.self, forKey: .firstOrderOnly)
        maxUsesTotal = try container.decodeIfPresent(Int.self, forKey: .maxUsesTotal)
        maxUsesPerCustomer = try container.decode(Int.self, forKey: .maxUsesPerCustomer)
        currentUses = try container.decodeIfPresent(Int.self, forKey: .currentUses)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured)
        activeDaysOfWeek = try container.decodeIfPresent([Int].self, forKey: .activeDaysOfWeek)
        activeHoursStart = try container.decodeIfPresent(String.self, forKey: .activeHoursStart)
        activeHoursEnd = try container.decodeIfPresent(String.self, forKey: .activeHoursEnd)
        targetSegment = try container.decodeIfPresent(String.self, forKey: .targetSegment)
        minimumTierId = try container.decodeIfPresent(Int.self, forKey: .minimumTierId)
        applicableOrderTypes = try container.decodeIfPresent([String].self, forKey: .applicableOrderTypes)
        applicableMenuCategories = try container.decodeIfPresent([Int].self, forKey: .applicableMenuCategories)
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)

        // Date parsing
        if let startStr = try container.decodeIfPresent(String.self, forKey: .startDate) {
            startDate = SharedDateFormatting.parseISO8601(startStr) ?? Date()
        } else {
            startDate = Date()
        }

        if let endStr = try container.decodeIfPresent(String.self, forKey: .endDate) {
            endDate = SharedDateFormatting.parseISO8601(endStr)
        } else {
            endDate = nil
        }

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

// MARK: - Shared Automated Campaign

/// Canonical automated campaign model matching the Supabase `automated_campaigns` table.
/// Supports both Business app field names and Website field names.
public struct SharedAutomatedCampaign: Codable, Identifiable {
    public let id: Int
    public let storeId: Int?
    public let campaignType: String?
    public let name: String
    public let description: String?
    public let triggerCondition: TriggerConditionValue?
    public let triggerEvent: String?
    public let triggerDelayHours: Int?
    public let notificationTitle: String?
    public let notificationBody: String?
    public let couponId: Int?
    public let isActive: Bool?
    public let totalTriggered: Int?
    public let totalConverted: Int?
    public let createdAt: Date?
    public let updatedAt: Date?

    // Computed properties for backwards compatibility with Business app
    public var notificationMessage: String { notificationBody ?? "" }
    public var timesTriggered: Int { totalTriggered ?? 0 }
    public var conversionCount: Int { totalConverted ?? 0 }

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case campaignType = "campaign_type"
        case name, description
        case triggerCondition = "trigger_condition"
        case triggerEvent = "trigger_event"
        case triggerDelayHours = "trigger_delay_hours"
        case notificationTitle = "notification_title"
        case notificationBody = "notification_body"
        case couponId = "coupon_id"
        case isActive = "is_active"
        case totalTriggered = "total_triggered"
        case totalConverted = "total_converted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Flexible Trigger Condition Type

    public enum TriggerConditionValue: Codable {
        case string(String)
        case json([String: AnyCodableValue])

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let json = try? container.decode([String: AnyCodableValue].self) {
                self = .json(json)
            } else {
                self = .string("")
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .json(let dict):
                try container.encode(dict)
            }
        }

        public var stringValue: String {
            switch self {
            case .string(let s): return s
            case .json: return "custom"
            }
        }
    }

    // Helper for encoding any JSON values
    public enum AnyCodableValue: Codable {
        case int(Int)
        case double(Double)
        case bool(Bool)
        case string(String)
        case null

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let int = try? container.decode(Int.self) {
                self = .int(int)
            } else if let double = try? container.decode(Double.self) {
                self = .double(double)
            } else if let bool = try? container.decode(Bool.self) {
                self = .bool(bool)
            } else if let string = try? container.decode(String.self) {
                self = .string(string)
            } else {
                self = .null
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .int(let value): try container.encode(value)
            case .double(let value): try container.encode(value)
            case .bool(let value): try container.encode(value)
            case .string(let value): try container.encode(value)
            case .null: try container.encodeNil()
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        storeId = try container.decodeIfPresent(Int.self, forKey: .storeId)
        campaignType = try container.decodeIfPresent(String.self, forKey: .campaignType)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        triggerCondition = try container.decodeIfPresent(TriggerConditionValue.self, forKey: .triggerCondition)
        triggerEvent = try container.decodeIfPresent(String.self, forKey: .triggerEvent)
        triggerDelayHours = try container.decodeIfPresent(Int.self, forKey: .triggerDelayHours)
        notificationTitle = try container.decodeIfPresent(String.self, forKey: .notificationTitle)
        notificationBody = try container.decodeIfPresent(String.self, forKey: .notificationBody)
        couponId = try container.decodeIfPresent(Int.self, forKey: .couponId)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        totalTriggered = try container.decodeIfPresent(Int.self, forKey: .totalTriggered)
        totalConverted = try container.decodeIfPresent(Int.self, forKey: .totalConverted)

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
