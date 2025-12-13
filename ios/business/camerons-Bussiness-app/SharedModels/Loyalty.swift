//
//  Loyalty.swift
//  KnockBites Connect — Shared Models
//
//  Canonical loyalty models shared across Business iOS, Customer iOS, and Website.
//  Includes loyalty programs, tiers, customer loyalty, and transactions.
//

import Foundation

// MARK: - Shared Loyalty Program

/// Canonical loyalty program model matching the Supabase `loyalty_programs` table.
public struct SharedLoyaltyProgram: Codable, Identifiable {
    public let id: Int
    public let storeId: Int?
    public let name: String
    public let pointsPerDollar: Double?
    public let welcomeBonusPoints: Int?
    public let referralBonusPoints: Int?
    public let isActive: Bool
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case name
        case pointsPerDollar = "points_per_dollar"
        case welcomeBonusPoints = "welcome_bonus_points"
        case referralBonusPoints = "referral_bonus_points"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        storeId = try container.decodeIfPresent(Int.self, forKey: .storeId)
        name = try container.decode(String.self, forKey: .name)
        pointsPerDollar = try container.decodeIfPresent(Double.self, forKey: .pointsPerDollar)
        welcomeBonusPoints = try container.decodeIfPresent(Int.self, forKey: .welcomeBonusPoints)
        referralBonusPoints = try container.decodeIfPresent(Int.self, forKey: .referralBonusPoints)
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

    public init(
        id: Int,
        storeId: Int?,
        name: String,
        pointsPerDollar: Double?,
        welcomeBonusPoints: Int?,
        referralBonusPoints: Int?,
        isActive: Bool,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.storeId = storeId
        self.name = name
        self.pointsPerDollar = pointsPerDollar
        self.welcomeBonusPoints = welcomeBonusPoints
        self.referralBonusPoints = referralBonusPoints
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Shared Loyalty Tier

/// Canonical loyalty tier model matching the Supabase `loyalty_tiers` table.
public struct SharedLoyaltyTier: Codable, Identifiable {
    public let id: Int
    public let programId: Int?
    public let name: String
    public let minPoints: Int
    public let discountPercentage: Double?
    public let freeDelivery: Bool?
    public let prioritySupport: Bool?
    public let earlyAccessPromos: Bool?
    public let birthdayRewardPoints: Int?
    public let tierColor: String?
    public let sortOrder: Int
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case name
        case minPoints = "min_points"
        case discountPercentage = "discount_percentage"
        case freeDelivery = "free_delivery"
        case prioritySupport = "priority_support"
        case earlyAccessPromos = "early_access_promos"
        case birthdayRewardPoints = "birthday_reward_points"
        case tierColor = "tier_color"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        programId = try container.decodeIfPresent(Int.self, forKey: .programId)
        name = try container.decode(String.self, forKey: .name)
        minPoints = try container.decode(Int.self, forKey: .minPoints)
        discountPercentage = try container.decodeIfPresent(Double.self, forKey: .discountPercentage)
        freeDelivery = try container.decodeIfPresent(Bool.self, forKey: .freeDelivery)
        prioritySupport = try container.decodeIfPresent(Bool.self, forKey: .prioritySupport)
        earlyAccessPromos = try container.decodeIfPresent(Bool.self, forKey: .earlyAccessPromos)
        birthdayRewardPoints = try container.decodeIfPresent(Int.self, forKey: .birthdayRewardPoints)
        tierColor = try container.decodeIfPresent(String.self, forKey: .tierColor)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)

        if let createdStr = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = SharedDateFormatting.parseISO8601(createdStr)
        } else {
            createdAt = nil
        }
    }

    public init(
        id: Int,
        programId: Int?,
        name: String,
        minPoints: Int,
        discountPercentage: Double?,
        freeDelivery: Bool?,
        prioritySupport: Bool?,
        earlyAccessPromos: Bool?,
        birthdayRewardPoints: Int?,
        tierColor: String?,
        sortOrder: Int,
        createdAt: Date?
    ) {
        self.id = id
        self.programId = programId
        self.name = name
        self.minPoints = minPoints
        self.discountPercentage = discountPercentage
        self.freeDelivery = freeDelivery
        self.prioritySupport = prioritySupport
        self.earlyAccessPromos = earlyAccessPromos
        self.birthdayRewardPoints = birthdayRewardPoints
        self.tierColor = tierColor
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}

// MARK: - Shared Customer Loyalty

/// Canonical customer loyalty model matching the Supabase `customer_loyalty` table.
public struct SharedCustomerLoyalty: Codable, Identifiable {
    public let id: Int
    public let customerId: Int?
    public let programId: Int?
    public let currentTierId: Int?
    public let totalPoints: Int?
    public let lifetimePoints: Int?
    public let totalOrders: Int?
    public let totalSpent: Double?
    public let joinedAt: Date?
    public let lastOrderAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case customerId = "customer_id"
        case programId = "program_id"
        case currentTierId = "current_tier_id"
        case totalPoints = "total_points"
        case lifetimePoints = "lifetime_points"
        case totalOrders = "total_orders"
        case totalSpent = "total_spent"
        case joinedAt = "joined_at"
        case lastOrderAt = "last_order_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        customerId = try container.decodeIfPresent(Int.self, forKey: .customerId)
        programId = try container.decodeIfPresent(Int.self, forKey: .programId)
        currentTierId = try container.decodeIfPresent(Int.self, forKey: .currentTierId)
        totalPoints = try container.decodeIfPresent(Int.self, forKey: .totalPoints)
        lifetimePoints = try container.decodeIfPresent(Int.self, forKey: .lifetimePoints)
        totalOrders = try container.decodeIfPresent(Int.self, forKey: .totalOrders)
        totalSpent = try container.decodeIfPresent(Double.self, forKey: .totalSpent)

        if let joinedStr = try container.decodeIfPresent(String.self, forKey: .joinedAt) {
            joinedAt = SharedDateFormatting.parseISO8601(joinedStr)
        } else {
            joinedAt = nil
        }

        if let lastOrderStr = try container.decodeIfPresent(String.self, forKey: .lastOrderAt) {
            lastOrderAt = SharedDateFormatting.parseISO8601(lastOrderStr)
        } else {
            lastOrderAt = nil
        }

        if let updatedStr = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = SharedDateFormatting.parseISO8601(updatedStr)
        } else {
            updatedAt = nil
        }
    }

    public init(
        id: Int,
        customerId: Int?,
        programId: Int?,
        currentTierId: Int?,
        totalPoints: Int?,
        lifetimePoints: Int?,
        totalOrders: Int?,
        totalSpent: Double?,
        joinedAt: Date?,
        lastOrderAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.customerId = customerId
        self.programId = programId
        self.currentTierId = currentTierId
        self.totalPoints = totalPoints
        self.lifetimePoints = lifetimePoints
        self.totalOrders = totalOrders
        self.totalSpent = totalSpent
        self.joinedAt = joinedAt
        self.lastOrderAt = lastOrderAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Shared Loyalty Transaction

/// Transaction type for loyalty points.
public enum SharedTransactionType: String, Codable, CaseIterable {
    case earn = "earn"
    case redeem = "redeem"
    case bonus = "bonus"
    case adjustment = "adjustment"

    public var displayName: String {
        switch self {
        case .earn: return "Earned"
        case .redeem: return "Redeemed"
        case .bonus: return "Bonus"
        case .adjustment: return "Adjustment"
        }
    }
}

/// Canonical loyalty transaction model matching the Supabase `loyalty_transactions` table.
public struct SharedLoyaltyTransaction: Codable, Identifiable {
    public let id: Int
    public let customerLoyaltyId: Int?
    public let orderId: String?
    public let transactionType: SharedTransactionType
    public let points: Int
    public let reason: String?
    public let balanceAfter: Int
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case customerLoyaltyId = "customer_loyalty_id"
        case orderId = "order_id"
        case transactionType = "transaction_type"
        case points
        case reason
        case balanceAfter = "balance_after"
        case createdAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        customerLoyaltyId = try container.decodeIfPresent(Int.self, forKey: .customerLoyaltyId)
        orderId = try container.decodeIfPresent(String.self, forKey: .orderId)
        transactionType = try container.decode(SharedTransactionType.self, forKey: .transactionType)
        points = try container.decode(Int.self, forKey: .points)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        balanceAfter = try container.decode(Int.self, forKey: .balanceAfter)

        if let createdStr = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = SharedDateFormatting.parseISO8601(createdStr)
        } else {
            createdAt = nil
        }
    }

    public init(
        id: Int,
        customerLoyaltyId: Int?,
        orderId: String?,
        transactionType: SharedTransactionType,
        points: Int,
        reason: String?,
        balanceAfter: Int,
        createdAt: Date?
    ) {
        self.id = id
        self.customerLoyaltyId = customerLoyaltyId
        self.orderId = orderId
        self.transactionType = transactionType
        self.points = points
        self.reason = reason
        self.balanceAfter = balanceAfter
        self.createdAt = createdAt
    }
}

// MARK: - Shared Loyalty Reward

/// Canonical loyalty reward model matching the Supabase `loyalty_rewards` table.
public struct SharedLoyaltyReward: Codable, Identifiable {
    public let id: Int
    public let programId: Int?
    public let name: String
    public let description: String?
    public let pointsCost: Int
    public let rewardType: String
    public let rewardValue: String
    public let imageUrl: String?
    public let isActive: Bool
    public let stockQuantity: Int?
    public let redemptionCount: Int?
    public let sortOrder: Int?
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case name, description
        case pointsCost = "points_cost"
        case rewardType = "reward_type"
        case rewardValue = "reward_value"
        case imageUrl = "image_url"
        case isActive = "is_active"
        case stockQuantity = "stock_quantity"
        case redemptionCount = "redemption_count"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        programId = try container.decodeIfPresent(Int.self, forKey: .programId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        pointsCost = try container.decode(Int.self, forKey: .pointsCost)
        rewardType = try container.decode(String.self, forKey: .rewardType)
        rewardValue = try container.decode(String.self, forKey: .rewardValue)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        stockQuantity = try container.decodeIfPresent(Int.self, forKey: .stockQuantity)
        redemptionCount = try container.decodeIfPresent(Int.self, forKey: .redemptionCount)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)

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
