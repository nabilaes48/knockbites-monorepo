//
//  MarketingRepository.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 5 cleanup - consolidated marketing data access
//  Replaces marketing methods from SupabaseManager
//  Updated Phase 9 - Added caching layer
//

import Foundation
import Supabase

/// Repository for all marketing-related data operations
/// Handles coupons, push notifications, loyalty programs, referrals, and automated campaigns
class MarketingRepository {
    static let shared = MarketingRepository()

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    // MARK: - Caching
    private let couponsCache = DataCache<[CouponResponse]>(defaultTTL: CacheTTL.short)

    private init() {}

    /// Invalidate all marketing caches
    func invalidateAllCaches() async {
        await couponsCache.clear()
    }

    // MARK: - Coupons

    struct CouponResponse: Codable {
        let id: Int
        let storeId: Int
        let code: String
        let name: String
        let description: String?
        let discountType: String
        let discountValue: Double
        let minOrderValue: Double?
        let maxDiscountAmount: Double?
        let applicableOrderTypes: [String]?
        let applicableMenuCategories: [Int]?
        let firstOrderOnly: Bool
        let maxUsesTotal: Int?
        let maxUsesPerCustomer: Int
        let currentUses: Int
        let startDate: String
        let endDate: String?
        let activeDaysOfWeek: [Int]?
        let activeHoursStart: String?
        let activeHoursEnd: String?
        let targetSegment: String?
        let minimumTierId: Int?
        let isActive: Bool
        let isFeatured: Bool
        let createdAt: String
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case id
            case storeId = "store_id"
            case code, name, description
            case discountType = "discount_type"
            case discountValue = "discount_value"
            case minOrderValue = "min_order_value"
            case maxDiscountAmount = "max_discount_amount"
            case applicableOrderTypes = "applicable_order_types"
            case applicableMenuCategories = "applicable_menu_categories"
            case firstOrderOnly = "first_order_only"
            case maxUsesTotal = "max_uses_total"
            case maxUsesPerCustomer = "max_uses_per_customer"
            case currentUses = "current_uses"
            case startDate = "start_date"
            case endDate = "end_date"
            case activeDaysOfWeek = "active_days_of_week"
            case activeHoursStart = "active_hours_start"
            case activeHoursEnd = "active_hours_end"
            case targetSegment = "target_segment"
            case minimumTierId = "minimum_tier_id"
            case isActive = "is_active"
            case isFeatured = "is_featured"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    struct CreateCouponRequest: Encodable {
        let storeId: Int
        let code: String
        let name: String
        let description: String?
        let discountType: String
        let discountValue: Double
        let minOrderValue: Double?
        let maxUsesTotal: Int?
        let maxUsesPerCustomer: Int
        let firstOrderOnly: Bool
        let startDate: String
        let endDate: String?
        let isActive: Bool
        let isFeatured: Bool

        enum CodingKeys: String, CodingKey {
            case storeId = "store_id"
            case code, name, description
            case discountType = "discount_type"
            case discountValue = "discount_value"
            case minOrderValue = "min_order_value"
            case maxUsesTotal = "max_uses_total"
            case maxUsesPerCustomer = "max_uses_per_customer"
            case firstOrderOnly = "first_order_only"
            case startDate = "start_date"
            case endDate = "end_date"
            case isActive = "is_active"
            case isFeatured = "is_featured"
        }
    }

    func fetchCoupons(storeId: Int, forceRefresh: Bool = false) async throws -> [CouponResponse] {
        let cacheKey = CacheKeys.coupons(storeId: storeId)

        // Check cache first
        if !forceRefresh, let cached = await couponsCache.get(cacheKey) {
            print("📦 Returning cached coupons (\(cached.count) items)")
            return cached
        }

        print("🔄 Fetching coupons for store \(storeId)...")

        let coupons: [CouponResponse] = try await client
            .from(TableNames.coupons)
            .select()
            .eq("store_id", value: storeId)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value

        // Cache the result
        await couponsCache.set(cacheKey, value: coupons)

        print("✅ Fetched \(coupons.count) coupons")
        return coupons
    }

    func invalidateCouponsCache(storeId: Int) async {
        await couponsCache.invalidate(CacheKeys.coupons(storeId: storeId))
    }

    func createCoupon(_ request: CreateCouponRequest) async throws -> CouponResponse {
        print("🔄 Creating coupon: \(request.code)...")

        let response: CouponResponse = try await client
            .from(TableNames.coupons)
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        print("✅ Coupon created: \(response.code)")
        return response
    }

    func updateCoupon(id: Int, isActive: Bool) async throws {
        print("🔄 Updating coupon \(id) active status to: \(isActive)...")

        try await client
            .from(TableNames.coupons)
            .update(["is_active": isActive])
            .eq("id", value: id)
            .execute()

        print("✅ Coupon updated successfully")
    }

    func deleteCoupon(id: Int) async throws {
        print("🔄 Deleting coupon \(id)...")

        try await client
            .from(TableNames.coupons)
            .delete()
            .eq("id", value: id)
            .execute()

        print("✅ Coupon deleted successfully")
    }

    // MARK: - Push Notifications

    struct PushNotificationResponse: Codable {
        let id: Int
        let storeId: Int
        let title: String
        let body: String
        let imageUrl: String?
        let actionUrl: String?
        let targetSegment: String?
        let targetCustomerIds: [Int]?
        let targetTierIds: [Int]?
        let scheduledFor: String?
        let sendImmediately: Bool
        let status: String
        let sentAt: String?
        let recipientsCount: Int
        let deliveredCount: Int
        let openedCount: Int
        let clickedCount: Int
        let createdAt: String
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case id
            case storeId = "store_id"
            case title, body
            case imageUrl = "image_url"
            case actionUrl = "action_url"
            case targetSegment = "target_segment"
            case targetCustomerIds = "target_customer_ids"
            case targetTierIds = "target_tier_ids"
            case scheduledFor = "scheduled_for"
            case sendImmediately = "send_immediately"
            case status
            case sentAt = "sent_at"
            case recipientsCount = "recipients_count"
            case deliveredCount = "delivered_count"
            case openedCount = "opened_count"
            case clickedCount = "clicked_count"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    struct CreateNotificationRequest: Encodable {
        let storeId: Int
        let title: String
        let body: String
        let imageUrl: String?
        let actionUrl: String?
        let targetSegment: String
        let sendImmediately: Bool
        let scheduledFor: String?
        let status: String

        enum CodingKeys: String, CodingKey {
            case storeId = "store_id"
            case title, body
            case imageUrl = "image_url"
            case actionUrl = "action_url"
            case targetSegment = "target_segment"
            case sendImmediately = "send_immediately"
            case scheduledFor = "scheduled_for"
            case status
        }
    }

    func fetchNotifications(storeId: Int) async throws -> [PushNotificationResponse] {
        print("🔄 Fetching push notifications for store \(storeId)...")

        let notifications: [PushNotificationResponse] = try await client
            .from(TableNames.pushNotifications)
            .select()
            .eq("store_id", value: storeId)
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
            .value

        print("✅ Fetched \(notifications.count) notifications")
        return notifications
    }

    func createNotification(_ request: CreateNotificationRequest) async throws -> PushNotificationResponse {
        print("🔄 Creating notification: \(request.title)...")

        let response: PushNotificationResponse = try await client
            .from(TableNames.pushNotifications)
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        print("✅ Notification created: \(response.title)")
        return response
    }

    func deleteNotification(id: Int) async throws {
        print("🔄 Deleting notification \(id)...")

        try await client
            .from(TableNames.pushNotifications)
            .delete()
            .eq("id", value: id)
            .execute()

        print("✅ Notification deleted successfully")
    }

    // MARK: - Loyalty Program

    struct LoyaltyProgramResponse: Codable {
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

    struct UpdateLoyaltyProgramRequest: Encodable {
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

    func fetchLoyaltyProgram(storeId: Int) async throws -> LoyaltyProgramResponse {
        print("🔄 Fetching loyalty program for store \(storeId)...")

        let programs: [LoyaltyProgramResponse] = try await client
            .from(TableNames.loyaltyPrograms)
            .select()
            .eq("store_id", value: storeId)
            .limit(1)
            .execute()
            .value

        guard let program = programs.first else {
            throw NSError(domain: "MarketingRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "No loyalty program found"])
        }

        print("✅ Fetched loyalty program: \(program.name)")
        return program
    }

    func updateLoyaltyProgram(programId: Int, request: UpdateLoyaltyProgramRequest) async throws -> LoyaltyProgramResponse {
        print("🔄 Updating loyalty program \(programId)...")

        let updated: LoyaltyProgramResponse = try await client
            .from(TableNames.loyaltyPrograms)
            .update(request)
            .eq("id", value: programId)
            .single()
            .execute()
            .value

        print("✅ Updated loyalty program: \(updated.name)")
        return updated
    }

    // MARK: - Loyalty Tiers

    struct LoyaltyTierResponse: Codable {
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

    struct CreateLoyaltyTierRequest: Encodable {
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

    struct UpdateLoyaltyTierRequest: Encodable {
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

    func fetchLoyaltyTiers(programId: Int) async throws -> [LoyaltyTierResponse] {
        print("🔄 Fetching loyalty tiers for program \(programId)...")

        let tiers: [LoyaltyTierResponse] = try await client
            .from(TableNames.loyaltyTiers)
            .select()
            .eq("program_id", value: programId)
            .order("sort_order", ascending: true)
            .execute()
            .value

        print("✅ Fetched \(tiers.count) loyalty tiers")
        return tiers
    }

    func createLoyaltyTier(_ request: CreateLoyaltyTierRequest) async throws -> LoyaltyTierResponse {
        print("🔄 Creating loyalty tier: \(request.name)...")

        let created: LoyaltyTierResponse = try await client
            .from(TableNames.loyaltyTiers)
            .insert(request)
            .single()
            .execute()
            .value

        print("✅ Created loyalty tier: \(created.name)")
        return created
    }

    func updateLoyaltyTier(tierId: Int, request: UpdateLoyaltyTierRequest) async throws -> LoyaltyTierResponse {
        print("🔄 Updating loyalty tier \(tierId)...")

        let updated: LoyaltyTierResponse = try await client
            .from(TableNames.loyaltyTiers)
            .update(request)
            .eq("id", value: tierId)
            .single()
            .execute()
            .value

        print("✅ Updated loyalty tier: \(updated.name)")
        return updated
    }

    func deleteLoyaltyTier(tierId: Int) async throws {
        print("🔄 Deleting loyalty tier \(tierId)...")

        try await client
            .from(TableNames.loyaltyTiers)
            .delete()
            .eq("id", value: tierId)
            .execute()

        print("✅ Deleted loyalty tier")
    }

    // MARK: - Loyalty Rewards

    struct LoyaltyRewardResponse: Codable {
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

    struct CreateLoyaltyRewardRequest: Encodable {
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

    struct UpdateLoyaltyRewardRequest: Encodable {
        let name: String?
        let description: String?
        let pointsCost: Int?
        let rewardType: String?
        let rewardValue: String?
        let imageUrl: String?
        let isActive: Bool?
        let stockQuantity: Int?
        let sortOrder: Int?

        enum CodingKeys: String, CodingKey {
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

    func fetchLoyaltyRewards(programId: Int) async throws -> [LoyaltyRewardResponse] {
        print("🔄 Fetching loyalty rewards for program \(programId)...")

        let rewards: [LoyaltyRewardResponse] = try await client
            .from(TableNames.loyaltyRewards)
            .select()
            .eq("program_id", value: programId)
            .order("sort_order", ascending: true)
            .execute()
            .value

        print("✅ Fetched \(rewards.count) loyalty rewards")
        return rewards
    }

    func createLoyaltyReward(_ request: CreateLoyaltyRewardRequest) async throws -> LoyaltyRewardResponse {
        print("🔄 Creating loyalty reward: \(request.name)...")

        let created: LoyaltyRewardResponse = try await client
            .from(TableNames.loyaltyRewards)
            .insert(request)
            .single()
            .execute()
            .value

        print("✅ Created loyalty reward: \(created.name)")
        return created
    }

    func updateLoyaltyReward(rewardId: Int, request: UpdateLoyaltyRewardRequest) async throws -> LoyaltyRewardResponse {
        print("🔄 Updating loyalty reward \(rewardId)...")

        let updated: LoyaltyRewardResponse = try await client
            .from(TableNames.loyaltyRewards)
            .update(request)
            .eq("id", value: rewardId)
            .single()
            .execute()
            .value

        print("✅ Updated loyalty reward: \(updated.name)")
        return updated
    }

    func deleteLoyaltyReward(rewardId: Int) async throws {
        print("🔄 Deleting loyalty reward \(rewardId)...")

        try await client
            .from(TableNames.loyaltyRewards)
            .delete()
            .eq("id", value: rewardId)
            .execute()

        print("✅ Deleted loyalty reward")
    }

    // MARK: - Customer Loyalty

    struct CustomerLoyaltyResponse: Codable {
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

    struct LoyaltyTransactionResponse: Codable {
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

    func fetchCustomerLoyalty(customerId: Int) async throws -> CustomerLoyaltyResponse {
        print("🔄 Fetching customer loyalty for customer \(customerId)...")

        let loyalty: [CustomerLoyaltyResponse] = try await client
            .from(TableNames.customerLoyalty)
            .select()
            .eq("customer_id", value: customerId)
            .limit(1)
            .execute()
            .value

        guard let customerLoyalty = loyalty.first else {
            throw NSError(domain: "MarketingRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "No loyalty data found"])
        }

        print("✅ Fetched customer loyalty: \(customerLoyalty.totalPoints) points")
        return customerLoyalty
    }

    func fetchLoyaltyTransactions(customerLoyaltyId: Int, limit: Int = 20) async throws -> [LoyaltyTransactionResponse] {
        print("🔄 Fetching loyalty transactions...")

        let transactions: [LoyaltyTransactionResponse] = try await client
            .from(TableNames.loyaltyTransactions)
            .select()
            .eq("customer_loyalty_id", value: customerLoyaltyId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        print("✅ Fetched \(transactions.count) transactions")
        return transactions
    }

    func addLoyaltyPoints(customerLoyaltyId: Int, points: Int, reason: String) async throws {
        print("🔄 Adding \(points) loyalty points...")

        // First, get current balance
        struct PointsBalance: Codable {
            let totalPoints: Int
            let lifetimePoints: Int

            enum CodingKeys: String, CodingKey {
                case totalPoints = "total_points"
                case lifetimePoints = "lifetime_points"
            }
        }

        let balances: [PointsBalance] = try await client
            .from(TableNames.customerLoyalty)
            .select("total_points, lifetime_points")
            .eq("id", value: customerLoyaltyId)
            .limit(1)
            .execute()
            .value

        guard let currentBalance = balances.first else {
            throw NSError(domain: "MarketingRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Customer loyalty record not found"])
        }

        let newBalance = currentBalance.totalPoints + points
        let newLifetime = currentBalance.lifetimePoints + (points > 0 ? points : 0)

        // Create transaction record
        struct TransactionInsert: Encodable {
            let customerLoyaltyId: Int
            let transactionType: String
            let points: Int
            let reason: String
            let balanceAfter: Int

            enum CodingKeys: String, CodingKey {
                case customerLoyaltyId = "customer_loyalty_id"
                case transactionType = "transaction_type"
                case points
                case reason
                case balanceAfter = "balance_after"
            }
        }

        try await client
            .from(TableNames.loyaltyTransactions)
            .insert(TransactionInsert(
                customerLoyaltyId: customerLoyaltyId,
                transactionType: points > 0 ? "bonus" : "adjustment",
                points: points,
                reason: reason,
                balanceAfter: newBalance
            ))
            .execute()

        // Update customer loyalty balance
        struct BalanceUpdate: Encodable {
            let totalPoints: Int
            let lifetimePoints: Int

            enum CodingKeys: String, CodingKey {
                case totalPoints = "total_points"
                case lifetimePoints = "lifetime_points"
            }
        }

        try await client
            .from(TableNames.customerLoyalty)
            .update(BalanceUpdate(totalPoints: newBalance, lifetimePoints: newLifetime))
            .eq("id", value: customerLoyaltyId)
            .execute()

        print("✅ Added \(points) points successfully")
    }

    func bulkAwardLoyaltyPoints(customerIds: [Int], points: Int, reason: String) async throws {
        print("🔄 Bulk awarding \(points) points to \(customerIds.count) customers...")

        var successCount = 0
        var errors: [Error] = []

        for customerId in customerIds {
            do {
                let loyalty: [CustomerLoyaltyResponse] = try await client
                    .from(TableNames.customerLoyalty)
                    .select()
                    .eq("customer_id", value: customerId)
                    .limit(1)
                    .execute()
                    .value

                guard let customerLoyalty = loyalty.first else {
                    print("⚠️ No loyalty record found for customer \(customerId)")
                    continue
                }

                let newBalance = customerLoyalty.totalPoints + points
                let newLifetimePoints = customerLoyalty.lifetimePoints + points

                struct UpdateBalance: Encodable {
                    let totalPoints: Int
                    let lifetimePoints: Int

                    enum CodingKeys: String, CodingKey {
                        case totalPoints = "total_points"
                        case lifetimePoints = "lifetime_points"
                    }
                }

                try await client
                    .from(TableNames.customerLoyalty)
                    .update(UpdateBalance(totalPoints: newBalance, lifetimePoints: newLifetimePoints))
                    .eq("id", value: customerLoyalty.id)
                    .execute()

                struct TransactionInsert: Encodable {
                    let customerLoyaltyId: Int
                    let transactionType: String
                    let points: Int
                    let reason: String
                    let balanceAfter: Int

                    enum CodingKeys: String, CodingKey {
                        case customerLoyaltyId = "customer_loyalty_id"
                        case transactionType = "transaction_type"
                        case points
                        case reason
                        case balanceAfter = "balance_after"
                    }
                }

                try await client
                    .from(TableNames.loyaltyTransactions)
                    .insert(TransactionInsert(
                        customerLoyaltyId: customerLoyalty.id,
                        transactionType: "manual_award",
                        points: points,
                        reason: reason,
                        balanceAfter: newBalance
                    ))
                    .execute()

                successCount += 1
                print("  ✓ Awarded \(points) points to customer \(customerId)")

            } catch {
                print("  ✗ Failed to award points to customer \(customerId): \(error)")
                errors.append(error)
            }
        }

        print("✅ Bulk award completed: \(successCount)/\(customerIds.count) successful")

        if !errors.isEmpty && successCount == 0 {
            throw NSError(domain: "MarketingRepository", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to award points to any customers"
            ])
        }
    }

    // MARK: - Referral Program

    struct ReferralProgramResponse: Codable {
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

    struct ReferralResponse: Codable {
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

    func fetchReferralProgram(storeId: Int) async throws -> ReferralProgramResponse {
        print("🔄 Fetching referral program for store \(storeId)...")

        let programs: [ReferralProgramResponse] = try await client
            .from(TableNames.referralProgram)
            .select()
            .eq("store_id", value: storeId)
            .limit(1)
            .execute()
            .value

        guard let program = programs.first else {
            throw NSError(domain: "MarketingRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "No referral program found"])
        }

        print("✅ Fetched referral program")
        return program
    }

    func fetchReferrals(programId: Int, limit: Int = 20) async throws -> [ReferralResponse] {
        print("🔄 Fetching referrals for program \(programId)...")

        let referrals: [ReferralResponse] = try await client
            .from(TableNames.referrals)
            .select()
            .eq("program_id", value: programId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        print("✅ Fetched \(referrals.count) referrals")
        return referrals
    }

    // MARK: - Automated Campaigns

    struct AutomatedCampaignResponse: Codable {
        let id: Int
        let storeId: Int?
        let campaignType: String?
        let name: String
        let description: String?
        // Trigger fields - support both Business and Website formats
        let triggerCondition: TriggerCondition?
        let triggerValue: Int?
        let triggerEvent: String?
        let triggerDelayHours: Int?
        // Notification fields - support both naming conventions
        let notificationTitle: String?
        let notificationBody: String?  // Website uses this
        // CTA fields (Business-specific)
        let ctaType: String?
        let ctaValue: String?
        let couponId: Int?  // Website uses this
        let targetAudience: String?
        let isActive: Bool?
        // Metrics - support both naming conventions
        let totalTriggered: Int?  // Website naming
        let totalConverted: Int?  // Website naming
        let createdAt: String?
        let updatedAt: String?

        // Computed properties for backwards compatibility
        var notificationMessage: String { notificationBody ?? "" }
        var timesTriggered: Int { totalTriggered ?? 0 }
        var conversionCount: Int { totalConverted ?? 0 }
        var revenueGenerated: Double { 0.0 }  // Not in Website schema

        enum CodingKeys: String, CodingKey {
            case id
            case storeId = "store_id"
            case campaignType = "campaign_type"
            case name, description
            case triggerCondition = "trigger_condition"
            case triggerValue = "trigger_value"
            case triggerEvent = "trigger_event"
            case triggerDelayHours = "trigger_delay_hours"
            case notificationTitle = "notification_title"
            case notificationBody = "notification_body"
            case ctaType = "cta_type"
            case ctaValue = "cta_value"
            case couponId = "coupon_id"
            case targetAudience = "target_audience"
            case isActive = "is_active"
            case totalTriggered = "total_triggered"
            case totalConverted = "total_converted"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }

        // Flexible trigger condition that handles both string and JSON
        enum TriggerCondition: Codable {
            case string(String)
            case json([String: Any])

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let stringValue = try? container.decode(String.self) {
                    self = .string(stringValue)
                } else if let data = try? container.decode([String: AnyCodable].self) {
                    self = .json(data.mapValues { $0.value })
                } else {
                    self = .string("")
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .string(let value):
                    try container.encode(value)
                case .json(let dict):
                    try container.encode(dict.mapValues { AnyCodable($0) })
                }
            }

            var stringValue: String {
                switch self {
                case .string(let s): return s
                case .json: return "custom"
                }
            }
        }

        // Helper for encoding Any values
        struct AnyCodable: Codable {
            let value: Any

            init(_ value: Any) {
                self.value = value
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let int = try? container.decode(Int.self) {
                    value = int
                } else if let double = try? container.decode(Double.self) {
                    value = double
                } else if let bool = try? container.decode(Bool.self) {
                    value = bool
                } else if let string = try? container.decode(String.self) {
                    value = string
                } else {
                    value = ""
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                if let int = value as? Int {
                    try container.encode(int)
                } else if let double = value as? Double {
                    try container.encode(double)
                } else if let bool = value as? Bool {
                    try container.encode(bool)
                } else if let string = value as? String {
                    try container.encode(string)
                }
            }
        }
    }

    struct CreateAutomatedCampaignRequest: Encodable {
        let storeId: Int
        let campaignType: String?
        let name: String
        let description: String?
        let triggerCondition: String?
        let triggerValue: Int?
        let triggerEvent: String?
        let triggerDelayHours: Int?
        let notificationTitle: String
        let notificationBody: String  // Fixed: DB column is notification_body
        let ctaType: String?
        let ctaValue: String?
        let couponId: Int?
        let targetAudience: String?
        let isActive: Bool

        enum CodingKeys: String, CodingKey {
            case storeId = "store_id"
            case campaignType = "campaign_type"
            case name, description
            case triggerCondition = "trigger_condition"
            case triggerValue = "trigger_value"
            case triggerEvent = "trigger_event"
            case triggerDelayHours = "trigger_delay_hours"
            case notificationTitle = "notification_title"
            case notificationBody = "notification_body"
            case ctaType = "cta_type"
            case ctaValue = "cta_value"
            case couponId = "coupon_id"
            case targetAudience = "target_audience"
            case isActive = "is_active"
        }
    }

    func fetchAutomatedCampaigns(storeId: Int) async throws -> [AutomatedCampaignResponse] {
        print("🔄 Fetching automated campaigns for store \(storeId)...")

        let campaigns: [AutomatedCampaignResponse] = try await client
            .from(TableNames.automatedCampaigns)
            .select()
            .eq("store_id", value: storeId)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ Fetched \(campaigns.count) automated campaigns")
        return campaigns
    }

    func toggleCampaignStatus(campaignId: Int, isActive: Bool) async throws {
        print("🔄 Toggling campaign \(campaignId) to \(isActive ? "active" : "inactive")...")

        try await client
            .from(TableNames.automatedCampaigns)
            .update(["is_active": isActive])
            .eq("id", value: campaignId)
            .execute()

        print("✅ Campaign status updated successfully")
    }

    func createAutomatedCampaign(_ request: CreateAutomatedCampaignRequest) async throws -> AutomatedCampaignResponse {
        print("🔄 Creating automated campaign: \(request.name)...")

        let response: AutomatedCampaignResponse = try await client
            .from(TableNames.automatedCampaigns)
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        print("✅ Automated campaign created: \(response.name)")
        return response
    }

    func deleteAutomatedCampaign(id: Int) async throws {
        print("🔄 Deleting automated campaign \(id)...")

        try await client
            .from(TableNames.automatedCampaigns)
            .delete()
            .eq("id", value: id)
            .execute()

        print("✅ Automated campaign deleted successfully")
    }
}
