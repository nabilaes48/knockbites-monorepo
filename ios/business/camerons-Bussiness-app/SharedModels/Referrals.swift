//
//  Referrals.swift
//  KnockBites Connect — Shared Models
//
//  Canonical referral models shared across Business iOS, Customer iOS, and Website.
//

import Foundation

// MARK: - Referral Status

/// Canonical referral status values.
public enum SharedReferralStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case completed = "completed"
    case expired = "expired"
    case cancelled = "cancelled"

    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Reward Type

/// Canonical reward type values for referrals.
public enum SharedRewardType: String, Codable, CaseIterable {
    case points = "points"
    case discount = "discount"
    case freeItem = "free_item"
    case credit = "credit"

    public var displayName: String {
        switch self {
        case .points: return "Points"
        case .discount: return "Discount"
        case .freeItem: return "Free Item"
        case .credit: return "Credit"
        }
    }
}

// MARK: - Shared Referral Program

/// Canonical referral program model matching the Supabase `referral_program` table.
public struct SharedReferralProgram: Codable, Identifiable {
    public let id: Int
    public let storeId: Int?
    public let referrerRewardType: String?
    public let referrerRewardValue: Double?
    public let refereeRewardType: String?
    public let refereeRewardValue: Double?
    public let minOrderValue: Double?
    public let maxReferralsPerCustomer: Int?
    public let isActive: Bool?
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case referrerRewardType = "referrer_reward_type"
        case referrerRewardValue = "referrer_reward_value"
        case refereeRewardType = "referee_reward_type"
        case refereeRewardValue = "referee_reward_value"
        case minOrderValue = "min_order_value"
        case maxReferralsPerCustomer = "max_referrals_per_customer"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        storeId = try container.decodeIfPresent(Int.self, forKey: .storeId)
        referrerRewardType = try container.decodeIfPresent(String.self, forKey: .referrerRewardType)
        referrerRewardValue = try container.decodeIfPresent(Double.self, forKey: .referrerRewardValue)
        refereeRewardType = try container.decodeIfPresent(String.self, forKey: .refereeRewardType)
        refereeRewardValue = try container.decodeIfPresent(Double.self, forKey: .refereeRewardValue)
        minOrderValue = try container.decodeIfPresent(Double.self, forKey: .minOrderValue)
        maxReferralsPerCustomer = try container.decodeIfPresent(Int.self, forKey: .maxReferralsPerCustomer)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)

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
        storeId: Int?,
        referrerRewardType: String?,
        referrerRewardValue: Double?,
        refereeRewardType: String?,
        refereeRewardValue: Double?,
        minOrderValue: Double?,
        maxReferralsPerCustomer: Int?,
        isActive: Bool?,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.storeId = storeId
        self.referrerRewardType = referrerRewardType
        self.referrerRewardValue = referrerRewardValue
        self.refereeRewardType = refereeRewardType
        self.refereeRewardValue = refereeRewardValue
        self.minOrderValue = minOrderValue
        self.maxReferralsPerCustomer = maxReferralsPerCustomer
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Shared Referral

/// Canonical referral model matching the Supabase `referrals` table.
public struct SharedReferral: Codable, Identifiable {
    public let id: Int
    public let programId: Int?
    public let referralCode: String
    public let referrerCustomerId: Int?
    public let refereeCustomerId: Int?
    public let status: SharedReferralStatus?
    public let referrerRewarded: Bool?
    public let refereeRewarded: Bool?
    public let refereeFirstOrderId: String?
    public let referrerRewardOrderId: String?
    public let createdAt: Date?
    public let completedAt: Date?
    public let rewardedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case referralCode = "referral_code"
        case referrerCustomerId = "referrer_customer_id"
        case refereeCustomerId = "referee_customer_id"
        case status
        case referrerRewarded = "referrer_rewarded"
        case refereeRewarded = "referee_rewarded"
        case refereeFirstOrderId = "referee_first_order_id"
        case referrerRewardOrderId = "referrer_reward_order_id"
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case rewardedAt = "rewarded_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        programId = try container.decodeIfPresent(Int.self, forKey: .programId)
        referralCode = try container.decode(String.self, forKey: .referralCode)
        referrerCustomerId = try container.decodeIfPresent(Int.self, forKey: .referrerCustomerId)
        refereeCustomerId = try container.decodeIfPresent(Int.self, forKey: .refereeCustomerId)
        status = try container.decodeIfPresent(SharedReferralStatus.self, forKey: .status)
        referrerRewarded = try container.decodeIfPresent(Bool.self, forKey: .referrerRewarded)
        refereeRewarded = try container.decodeIfPresent(Bool.self, forKey: .refereeRewarded)
        refereeFirstOrderId = try container.decodeIfPresent(String.self, forKey: .refereeFirstOrderId)
        referrerRewardOrderId = try container.decodeIfPresent(String.self, forKey: .referrerRewardOrderId)

        if let createdStr = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = SharedDateFormatting.parseISO8601(createdStr)
        } else {
            createdAt = nil
        }

        if let completedStr = try container.decodeIfPresent(String.self, forKey: .completedAt) {
            completedAt = SharedDateFormatting.parseISO8601(completedStr)
        } else {
            completedAt = nil
        }

        if let rewardedStr = try container.decodeIfPresent(String.self, forKey: .rewardedAt) {
            rewardedAt = SharedDateFormatting.parseISO8601(rewardedStr)
        } else {
            rewardedAt = nil
        }
    }

    public init(
        id: Int,
        programId: Int?,
        referralCode: String,
        referrerCustomerId: Int?,
        refereeCustomerId: Int?,
        status: SharedReferralStatus?,
        referrerRewarded: Bool?,
        refereeRewarded: Bool?,
        refereeFirstOrderId: String?,
        referrerRewardOrderId: String?,
        createdAt: Date?,
        completedAt: Date?,
        rewardedAt: Date?
    ) {
        self.id = id
        self.programId = programId
        self.referralCode = referralCode
        self.referrerCustomerId = referrerCustomerId
        self.refereeCustomerId = refereeCustomerId
        self.status = status
        self.referrerRewarded = referrerRewarded
        self.refereeRewarded = refereeRewarded
        self.refereeFirstOrderId = refereeFirstOrderId
        self.referrerRewardOrderId = referrerRewardOrderId
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.rewardedAt = rewardedAt
    }
}
