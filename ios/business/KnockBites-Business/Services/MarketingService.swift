//
//  MarketingService.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/19/25.
//  Phase 1.2: Marketing Data Integration
//

import Foundation
import Supabase

class MarketingService {
    static let shared = MarketingService()
    private let supabase = SupabaseManager.shared.client

    // MARK: - Loyalty Program

    /// Get loyalty program for a store
    func getLoyaltyProgram(storeId: Int) async throws -> LoyaltyProgramResponse? {
        do {
            let response = try await supabase
                .from("loyalty_programs")
                .select()
                .eq("store_id", value: storeId)
                .single()
                .execute()

            return try JSONDecoder().decode(LoyaltyProgramResponse.self, from: response.data)
        } catch {
            print("⚠️ getLoyaltyProgram failed: \(error)")
            return nil
        }
    }

    /// Update loyalty program settings
    func updateLoyaltyProgram(programId: Int, settings: LoyaltyProgramUpdate) async throws {
        struct ProgramUpdate: Codable {
            let points_per_dollar: Decimal?
            let welcome_bonus_points: Int?
            let referral_bonus_points: Int?
            let is_active: Bool?
        }

        let updateData = ProgramUpdate(
            points_per_dollar: settings.pointsPerDollar,
            welcome_bonus_points: settings.welcomeBonusPoints,
            referral_bonus_points: settings.referralBonusPoints,
            is_active: settings.isActive
        )

        _ = try await supabase
            .from("loyalty_programs")
            .update(updateData)
            .eq("id", value: programId)
            .execute()
    }

    // MARK: - Loyalty Tiers

    /// Get all tiers for a program
    func getLoyaltyTiers(programId: Int) async throws -> [LoyaltyTierResponse] {
        do {
            let response = try await supabase
                .from("loyalty_tiers")
                .select()
                .eq("program_id", value: programId)
                .order("sort_order")
                .execute()

            return try JSONDecoder().decode([LoyaltyTierResponse].self, from: response.data)
        } catch {
            print("⚠️ getLoyaltyTiers failed: \(error)")
            return []
        }
    }

    /// Create a new loyalty tier
    func createLoyaltyTier(programId: Int, tier: LoyaltyTierCreate) async throws -> LoyaltyTierResponse {
        struct InsertData: Codable {
            let program_id: Int
            let name: String
            let min_points: Int
            let discount_percentage: Decimal
            let free_delivery: Bool
            let priority_support: Bool
            let early_access_promos: Bool
            let birthday_reward_points: Int
            let tier_color: String
            let sort_order: Int
        }

        let insertData = InsertData(
            program_id: programId,
            name: tier.name,
            min_points: tier.minPoints,
            discount_percentage: tier.discountPercentage,
            free_delivery: tier.freeDelivery,
            priority_support: tier.prioritySupport,
            early_access_promos: tier.earlyAccessPromos,
            birthday_reward_points: tier.birthdayRewardPoints,
            tier_color: tier.tierColor,
            sort_order: tier.sortOrder
        )

        let response = try await supabase
            .from("loyalty_tiers")
            .insert(insertData)
            .select()
            .single()
            .execute()

        return try JSONDecoder().decode(LoyaltyTierResponse.self, from: response.data)
    }

    /// Update an existing loyalty tier
    func updateLoyaltyTier(tierId: Int, tier: LoyaltyTierCreate) async throws {
        struct UpdateData: Codable {
            let name: String
            let min_points: Int
            let discount_percentage: Decimal
            let free_delivery: Bool
            let priority_support: Bool
            let early_access_promos: Bool
            let birthday_reward_points: Int
            let tier_color: String
            let sort_order: Int
        }

        let updateData = UpdateData(
            name: tier.name,
            min_points: tier.minPoints,
            discount_percentage: tier.discountPercentage,
            free_delivery: tier.freeDelivery,
            priority_support: tier.prioritySupport,
            early_access_promos: tier.earlyAccessPromos,
            birthday_reward_points: tier.birthdayRewardPoints,
            tier_color: tier.tierColor,
            sort_order: tier.sortOrder
        )

        _ = try await supabase
            .from("loyalty_tiers")
            .update(updateData)
            .eq("id", value: tierId)
            .execute()
    }

    /// Delete a loyalty tier
    func deleteLoyaltyTier(tierId: Int) async throws {
        _ = try await supabase
            .from("loyalty_tiers")
            .delete()
            .eq("id", value: tierId)
            .execute()
    }

    /// Get tier distribution (count of customers in each tier)
    func getTierDistribution(programId: Int) async throws -> [TierDistributionItem] {
        do {
            // Get all tiers
            let tiers = try await getLoyaltyTiers(programId: programId)

            // Get count for each tier
            var distribution: [TierDistributionItem] = []

            for tier in tiers {
                let response = try await supabase
                    .from("customer_loyalty")
                    .select("id", head: false, count: .exact)
                    .eq("program_id", value: programId)
                    .eq("current_tier_id", value: tier.id)
                    .execute()

                distribution.append(TierDistributionItem(
                    tierName: tier.name,
                    tierColor: tier.tierColor,
                    count: response.count ?? 0
                ))
            }

            return distribution
        } catch {
            print("⚠️ getTierDistribution failed: \(error)")
            return []
        }
    }

    // MARK: - Customer Loyalty

    /// Get all loyalty customers for a program
    func getLoyaltyCustomers(programId: Int, limit: Int = 100) async throws -> [CustomerLoyaltyResponse] {
        do {
            let response = try await supabase
                .from("customer_loyalty")
                .select()
                .eq("program_id", value: programId)
                .order("total_points", ascending: false)
                .limit(limit)
                .execute()

            return try JSONDecoder().decode([CustomerLoyaltyResponse].self, from: response.data)
        } catch {
            print("⚠️ getLoyaltyCustomers failed: \(error)")
            return []
        }
    }

    /// Search loyalty customers by customer ID or email
    func searchLoyaltyCustomers(programId: Int, query: String) async throws -> [CustomerLoyaltyResponse] {
        // Note: This is simplified - in production you'd join with customers table and search by email
        do {
            let response = try await supabase
                .from("customer_loyalty")
                .select()
                .eq("program_id", value: programId)
                .limit(50)
                .execute()

            return try JSONDecoder().decode([CustomerLoyaltyResponse].self, from: response.data)
        } catch {
            print("⚠️ searchLoyaltyCustomers failed: \(error)")
            return []
        }
    }

    /// Award points to a customer
    func awardPoints(customerId: Int, programId: Int, points: Int, reason: String) async throws {
        // First, get or create customer_loyalty record
        let loyaltyResponse = try await supabase
            .from("customer_loyalty")
            .select()
            .eq("customer_id", value: customerId)
            .eq("program_id", value: programId)
            .single()
            .execute()

        let decoder = JSONDecoder()
        var customerLoyalty: CustomerLoyaltyResponse?

        if !loyaltyResponse.data.isEmpty {
            customerLoyalty = try? decoder.decode(CustomerLoyaltyResponse.self, from: loyaltyResponse.data)
        }

        if var existing = customerLoyalty {
            // Update existing
            let newTotal = existing.totalPoints + points
            let newLifetime = existing.lifetimePoints + points

            struct LoyaltyUpdate: Codable {
                let total_points: Int
                let lifetime_points: Int
                let updated_at: String
            }

            let updateData = LoyaltyUpdate(
                total_points: newTotal,
                lifetime_points: newLifetime,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )

            _ = try await supabase
                .from("customer_loyalty")
                .update(updateData)
                .eq("id", value: existing.id)
                .execute()

            // Record transaction
            struct TransactionInsert: Codable {
                let customer_loyalty_id: Int
                let transaction_type: String
                let points: Int
                let reason: String
                let balance_after: Int
            }

            let transactionData = TransactionInsert(
                customer_loyalty_id: existing.id,
                transaction_type: "award",
                points: points,
                reason: reason,
                balance_after: newTotal
            )

            _ = try await supabase
                .from("loyalty_transactions")
                .insert(transactionData)
                .execute()
        } else {
            // Create new customer_loyalty record
            struct LoyaltyInsert: Codable {
                let customer_id: Int
                let program_id: Int
                let total_points: Int
                let lifetime_points: Int
            }

            let insertData = LoyaltyInsert(
                customer_id: customerId,
                program_id: programId,
                total_points: points,
                lifetime_points: points
            )

            let response = try await supabase
                .from("customer_loyalty")
                .insert(insertData)
                .select()
                .single()
                .execute()

            let newLoyalty = try decoder.decode(CustomerLoyaltyResponse.self, from: response.data)

            // Record transaction
            struct TransactionInsert: Codable {
                let customer_loyalty_id: Int
                let transaction_type: String
                let points: Int
                let reason: String
                let balance_after: Int
            }

            let transactionData = TransactionInsert(
                customer_loyalty_id: newLoyalty.id,
                transaction_type: "award",
                points: points,
                reason: reason,
                balance_after: points
            )

            _ = try await supabase
                .from("loyalty_transactions")
                .insert(transactionData)
                .execute()
        }
    }

    // MARK: - Referral Program

    /// Get referral program settings
    func getReferralProgram(storeId: Int) async throws -> ReferralProgramResponse? {
        do {
            let response = try await supabase
                .from("referral_program")
                .select()
                .eq("store_id", value: storeId)
                .single()
                .execute()

            return try JSONDecoder().decode(ReferralProgramResponse.self, from: response.data)
        } catch {
            print("⚠️ getReferralProgram failed: \(error)")
            return nil
        }
    }

    /// Get active referrals
    func getActiveReferrals(storeId: Int) async throws -> [ReferralResponse] {
        do {
            let response = try await supabase
                .from("referrals")
                .select()
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .limit(100)
                .execute()

            return try JSONDecoder().decode([ReferralResponse].self, from: response.data)
        } catch {
            print("⚠️ getActiveReferrals failed: \(error)")
            return []
        }
    }

    /// Get referral conversion rate
    func getReferralConversionRate(storeId: Int) async throws -> Double {
        do {
            // Get total referrals
            let totalResponse = try await supabase
                .from("referrals")
                .select("id", head: false, count: .exact)
                .execute()

            // Get converted referrals
            let convertedResponse = try await supabase
                .from("referrals")
                .select("id", head: false, count: .exact)
                .eq("status", value: "converted")
                .execute()

            let total = totalResponse.count ?? 0
            let converted = convertedResponse.count ?? 0

            guard total > 0 else { return 0 }
            return (Double(converted) / Double(total)) * 100
        } catch {
            print("⚠️ getReferralConversionRate failed: \(error)")
            return 0
        }
    }

    // MARK: - Coupons

    /// Get all coupons for a store
    func getCoupons(storeId: Int, activeOnly: Bool = false) async throws -> [CouponResponse] {
        do {
            var query = supabase
                .from("coupons")
                .select()
                .eq("store_id", value: storeId)

            if activeOnly {
                query = query.eq("is_active", value: true)
            }

            let response = try await query
                .order("created_at", ascending: false)
                .execute()

            return try JSONDecoder().decode([CouponResponse].self, from: response.data)
        } catch {
            print("⚠️ getCoupons failed: \(error)")
            return []
        }
    }

    /// Get coupon redemption stats
    func getCouponRedemptions(couponId: Int) async throws -> Int {
        do {
            let response = try await supabase
                .from("coupon_usage")
                .select("id", head: false, count: .exact)
                .eq("coupon_id", value: couponId)
                .execute()

            return response.count ?? 0
        } catch {
            print("⚠️ getCouponRedemptions failed: \(error)")
            return 0
        }
    }

    // MARK: - Marketing Analytics

    /// Get total coupon redemptions for a store
    func getTotalCouponRedemptions(storeId: Int, days: Int = 30) async throws -> Int {
        do {
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let formatter = ISO8601DateFormatter()

            // Get all coupon IDs for this store
            let couponsResponse = try await supabase
                .from("coupons")
                .select("id")
                .eq("store_id", value: storeId)
                .execute()

            let coupons = try JSONDecoder().decode([CouponIdResponse].self, from: couponsResponse.data)
            let couponIds = coupons.map { $0.id }

            guard !couponIds.isEmpty else { return 0 }

            // Count redemptions for these coupons
            let response = try await supabase
                .from("coupon_usage")
                .select("id", head: false, count: .exact)
                .in("coupon_id", values: couponIds)
                .gte("used_at", value: formatter.string(from: startDate))
                .execute()

            return response.count ?? 0
        } catch {
            print("⚠️ getTotalCouponRedemptions failed: \(error)")
            return 0
        }
    }

    /// Get notification performance (delegates to NotificationsService)
    func getNotificationPerformance(storeId: Int, days: Int = 30) async throws -> (sent: Int, opened: Int, clicked: Int) {
        do {
            let notificationService = NotificationsService.shared
            let period: NotificationPeriod = days <= 7 ? .week : .month

            let sent = try await notificationService.getTotalSent(storeId: storeId, period: period)
            let funnel = try await notificationService.getEngagementFunnel(storeId: storeId, period: period)

            return (sent: sent, opened: funnel.opened, clicked: funnel.clicked)
        } catch {
            print("⚠️ getNotificationPerformance failed: \(error)")
            return (sent: 0, opened: 0, clicked: 0)
        }
    }

    // MARK: - Automated Campaigns

    /// Get all automated campaigns
    func getAutomatedCampaigns(storeId: Int) async throws -> [AutomatedCampaignResponse] {
        do {
            let response = try await supabase
                .from("automated_campaigns")
                .select()
                .eq("store_id", value: storeId)
                .order("created_at", ascending: false)
                .execute()

            return try JSONDecoder().decode([AutomatedCampaignResponse].self, from: response.data)
        } catch {
            print("⚠️ getAutomatedCampaigns failed: \(error)")
            return []
        }
    }

    /// Create automated campaign
    func createAutomatedCampaign(storeId: Int, campaign: AutomatedCampaignCreate) async throws {
        struct CampaignInsert: Codable {
            let store_id: Int
            let name: String
            let trigger_type: String
            let notification_title: String
            let notification_body: String
            let is_active: Bool
        }

        let insertData = CampaignInsert(
            store_id: storeId,
            name: campaign.name,
            trigger_type: campaign.triggerType,
            notification_title: campaign.notificationTitle,
            notification_body: campaign.notificationBody,
            is_active: campaign.isActive
        )

        _ = try await supabase
            .from("automated_campaigns")
            .insert(insertData)
            .execute()
    }

    /// Get campaign execution stats
    func getCampaignExecutions(campaignId: Int) async throws -> Int {
        do {
            let response = try await supabase
                .from("campaign_executions")
                .select("id", head: false, count: .exact)
                .eq("campaign_id", value: campaignId)
                .execute()

            return response.count ?? 0
        } catch {
            print("⚠️ getCampaignExecutions failed: \(error)")
            return 0
        }
    }

    // MARK: - Customer Segments

    /// Get customers by segment criteria
    func getCustomerSegment(storeId: Int, segment: CustomerSegmentType) async throws -> [Int] {
        do {
            let formatter = ISO8601DateFormatter()

            switch segment {
            case .allCustomers:
                // Get all customer IDs from orders
                let response = try await supabase
                    .from("orders")
                    .select("user_id")
                    .eq("store_id", value: storeId)
                    .execute()

                let orders = try JSONDecoder().decode([UserIdResponse].self, from: response.data)
                return Array(Set(orders.compactMap { Int($0.userId ?? "") }))

            case .activeCustomers:
                // Customers who ordered in last 30 days
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

                let response = try await supabase
                    .from("orders")
                    .select("user_id")
                    .eq("store_id", value: storeId)
                    .gte("created_at", value: formatter.string(from: thirtyDaysAgo))
                    .execute()

                let orders = try JSONDecoder().decode([UserIdResponse].self, from: response.data)
                return Array(Set(orders.compactMap { Int($0.userId ?? "") }))

            case .inactiveCustomers:
                // Customers who haven't ordered in 30+ days
                _ = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

                // This would require a more complex query - simplified for now
                return []

            case .highValue:
                // Customers with total spent > $500
                // Would require aggregation - simplified
                return []

            case .vipLoyalty:
                // Customers with 500+ points
                let response = try await supabase
                    .from("customer_loyalty")
                    .select("customer_id")
                    .gte("total_points", value: 500)
                    .execute()

                let loyaltyCustomers = try JSONDecoder().decode([CustomerIdResponse].self, from: response.data)
                return loyaltyCustomers.map { $0.customerId }
            }
        } catch {
            print("⚠️ getCustomerSegment failed: \(error)")
            return []
        }
    }
}

// MARK: - Response Models

struct LoyaltyProgramResponse: Codable {
    let id: Int
    let storeId: Int
    let name: String
    let pointsPerDollar: Decimal
    let welcomeBonusPoints: Int
    let referralBonusPoints: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case name
        case pointsPerDollar = "points_per_dollar"
        case welcomeBonusPoints = "welcome_bonus_points"
        case referralBonusPoints = "referral_bonus_points"
        case isActive = "is_active"
    }
}

struct LoyaltyProgramUpdate {
    let pointsPerDollar: Decimal?
    let welcomeBonusPoints: Int?
    let referralBonusPoints: Int?
    let isActive: Bool?
}

struct LoyaltyTierResponse: Codable {
    let id: Int
    let programId: Int
    let name: String
    let minPoints: Int
    let discountPercentage: Decimal
    let freeDelivery: Bool
    let prioritySupport: Bool
    let earlyAccessPromos: Bool
    let birthdayRewardPoints: Int
    let tierColor: String
    let sortOrder: Int

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
    }
}

struct LoyaltyTierCreate {
    let name: String
    let minPoints: Int
    let discountPercentage: Decimal
    let freeDelivery: Bool
    let prioritySupport: Bool
    let earlyAccessPromos: Bool
    let birthdayRewardPoints: Int
    let tierColor: String
    let sortOrder: Int
}

struct TierDistributionItem: Codable {
    let tierName: String
    let tierColor: String
    let count: Int
}

struct CustomerLoyaltyResponse: Codable {
    let id: Int
    let customerId: Int
    let programId: Int
    let currentTierId: Int?
    let totalPoints: Int
    let lifetimePoints: Int
    let totalOrders: Int
    let totalSpent: Decimal

    enum CodingKeys: String, CodingKey {
        case id
        case customerId = "customer_id"
        case programId = "program_id"
        case currentTierId = "current_tier_id"
        case totalPoints = "total_points"
        case lifetimePoints = "lifetime_points"
        case totalOrders = "total_orders"
        case totalSpent = "total_spent"
    }
}

struct ReferralProgramResponse: Codable {
    let id: Int
    let storeId: Int
    let referrerRewardType: String
    let referrerRewardValue: Decimal
    let refereeRewardType: String
    let refereeRewardValue: Decimal
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case referrerRewardType = "referrer_reward_type"
        case referrerRewardValue = "referrer_reward_value"
        case refereeRewardType = "referee_reward_type"
        case refereeRewardValue = "referee_reward_value"
        case isActive = "is_active"
    }
}

struct ReferralResponse: Codable {
    let id: Int
    let referralCode: String
    let status: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case referralCode = "referral_code"
        case status
        case createdAt = "created_at"
    }
}

struct CouponResponse: Codable {
    let id: Int
    let code: String
    let name: String
    let discountType: String
    let discountValue: Decimal
    let isActive: Bool
    let currentUses: Int

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case name
        case discountType = "discount_type"
        case discountValue = "discount_value"
        case isActive = "is_active"
        case currentUses = "current_uses"
    }
}

struct CouponIdResponse: Codable {
    let id: Int
}

struct AutomatedCampaignResponse: Codable {
    let id: Int
    let name: String
    let triggerType: String
    let isActive: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case triggerType = "trigger_type"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

struct AutomatedCampaignCreate {
    let name: String
    let triggerType: String
    let triggerConditions: [String: Any]?
    let notificationTitle: String
    let notificationBody: String
    let isActive: Bool
}

struct UserIdResponse: Codable {
    let userId: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

struct CustomerIdResponse: Codable {
    let customerId: Int

    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
    }
}

enum CustomerSegmentType {
    case allCustomers
    case activeCustomers
    case inactiveCustomers
    case highValue
    case vipLoyalty
}
