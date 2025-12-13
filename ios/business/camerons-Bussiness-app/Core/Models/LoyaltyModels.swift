//
//  LoyaltyModels.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 4 cleanup - shared loyalty DTOs
//

import Foundation

// MARK: - Loyalty Program Models

struct LoyaltyProgramDTO: Codable, Identifiable {
    let id: Int
    let storeId: Int
    let name: String
    let pointsPerDollar: Double
    let welcomeBonusPoints: Int
    let referralBonusPoints: Int
    let isActive: Bool
    let createdAt: String
    let updatedAt: String

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
}

struct UpdateLoyaltyProgramDTO: Encodable {
    let name: String?
    let pointsPerDollar: Double?
    let welcomeBonusPoints: Int?
    let referralBonusPoints: Int?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case pointsPerDollar = "points_per_dollar"
        case welcomeBonusPoints = "welcome_bonus_points"
        case referralBonusPoints = "referral_bonus_points"
        case isActive = "is_active"
    }
}

// MARK: - Loyalty Tier Models

struct LoyaltyTierDTO: Codable, Identifiable {
    let id: Int
    let programId: Int
    let name: String
    let minPoints: Int
    let discountPercentage: Double
    let freeDelivery: Bool
    let prioritySupport: Bool
    let earlyAccessPromos: Bool
    let birthdayRewardPoints: Int
    let tierColor: String?
    let sortOrder: Int
    let createdAt: String

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
}

struct CreateLoyaltyTierDTO: Encodable {
    let programId: Int
    let name: String
    let minPoints: Int
    let discountPercentage: Double
    let freeDelivery: Bool
    let prioritySupport: Bool
    let earlyAccessPromos: Bool
    let birthdayRewardPoints: Int
    let tierColor: String?
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
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
    }
}

struct UpdateLoyaltyTierDTO: Encodable {
    let name: String?
    let minPoints: Int?
    let discountPercentage: Double?
    let freeDelivery: Bool?
    let prioritySupport: Bool?
    let earlyAccessPromos: Bool?
    let birthdayRewardPoints: Int?
    let tierColor: String?
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case minPoints = "min_points"
        case discountPercentage = "discount_percentage"
        case freeDelivery = "free_delivery"
        case prioritySupport = "priority_support"
        case earlyAccessPromos = "early_access_promos"
        case birthdayRewardPoints = "birthday_reward_points"
        case tierColor = "tier_color"
        case sortOrder = "sort_order"
    }
}

// MARK: - Customer Loyalty Models

struct CustomerLoyaltyDTO: Codable, Identifiable {
    let id: Int
    let customerId: Int
    let programId: Int
    let currentTierId: Int?
    let totalPoints: Int
    let lifetimePoints: Int
    let totalOrders: Int
    let totalSpent: Double
    let joinedAt: String
    let lastOrderAt: String?
    let updatedAt: String

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
}

struct LoyaltyTransactionDTO: Codable, Identifiable {
    let id: Int
    let customerLoyaltyId: Int
    let orderId: String?
    let transactionType: String
    let points: Int
    let reason: String?
    let balanceAfter: Int
    let createdAt: String

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
}

// MARK: - Loyalty Reward Models

struct LoyaltyRewardDTO: Codable, Identifiable {
    let id: Int
    let programId: Int
    let name: String
    let description: String?
    let pointsCost: Int
    let rewardType: String
    let rewardValue: String
    let imageUrl: String?
    let isActive: Bool
    let stockQuantity: Int?
    let redemptionCount: Int
    let sortOrder: Int
    let createdAt: String
    let updatedAt: String

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
}

struct CreateLoyaltyRewardDTO: Encodable {
    let programId: Int
    let name: String
    let description: String?
    let pointsCost: Int
    let rewardType: String
    let rewardValue: String
    let imageUrl: String?
    let isActive: Bool
    let stockQuantity: Int?
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case programId = "program_id"
        case name, description
        case pointsCost = "points_cost"
        case rewardType = "reward_type"
        case rewardValue = "reward_value"
        case imageUrl = "image_url"
        case isActive = "is_active"
        case stockQuantity = "stock_quantity"
        case sortOrder = "sort_order"
    }
}

// MARK: - Referral Models

struct ReferralProgramDTO: Codable, Identifiable {
    let id: Int
    let storeId: Int
    let referrerRewardType: String
    let referrerRewardValue: Double
    let refereeRewardType: String
    let refereeRewardValue: Double
    let minOrderValue: Double
    let maxReferralsPerCustomer: Int?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String

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
}

struct ReferralDTO: Codable, Identifiable {
    let id: Int
    let programId: Int
    let referralCode: String
    let referrerCustomerId: Int
    let refereeCustomerId: Int?
    let status: String
    let referrerRewarded: Bool
    let refereeRewarded: Bool
    let createdAt: String
    let completedAt: String?
    let rewardedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case referralCode = "referral_code"
        case referrerCustomerId = "referrer_customer_id"
        case refereeCustomerId = "referee_customer_id"
        case status
        case referrerRewarded = "referrer_rewarded"
        case refereeRewarded = "referee_rewarded"
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case rewardedAt = "rewarded_at"
    }
}
