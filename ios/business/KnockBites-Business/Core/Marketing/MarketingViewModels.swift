//
//  MarketingViewModels.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import Combine

// MARK: - Marketing Dashboard ViewModel

@MainActor
class MarketingViewModel: ObservableObject {
    @Published var campaignStats = CampaignStats(
        sentToday: 234,
        opened: 68,
        clicked: 42,
        converted: 18
    )

    @Published var activeCampaigns: [Campaign] = [
        Campaign(
            id: UUID(),
            title: "Weekend Special",
            message: "Get 20% off all orders this weekend!",
            type: .promotion,
            status: .active,
            sentCount: 450,
            openRate: 72,
            expiresAt: Date().addingTimeInterval(86400 * 2)
        ),
        Campaign(
            id: UUID(),
            title: "New Menu Items",
            message: "Try our new gourmet burger selection!",
            type: .announcement,
            status: .active,
            sentCount: 380,
            openRate: 65,
            expiresAt: nil
        )
    ]

    @Published var recentNotifications: [NotificationItem] = []
    @Published var activeCoupons: [Coupon] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadNotifications() {
        Task {
            do {
                let notificationResponses = try await SupabaseManager.shared.fetchNotifications(
                    storeId: SecureSupabaseConfig.storeId
                )

                // Convert to UI model
                recentNotifications = notificationResponses.map { response in
                    let dateFormatter = ISO8601DateFormatter()
                    let sentAt = response.sent_at.flatMap { dateFormatter.date(from: $0) } ??
                                 dateFormatter.date(from: response.created_at) ?? Date()

                    let openRate = response.recipients_count > 0 ?
                                   Int((Double(response.opened_count) / Double(response.recipients_count)) * 100) : 0

                    return NotificationItem(
                        id: UUID(),
                        title: response.title,
                        message: response.body,
                        sentAt: sentAt,
                        sentCount: response.recipients_count,
                        openRate: openRate,
                        dbId: response.id,
                        status: response.status
                    )
                }
            } catch {
                print("❌ Error loading notifications: \(error)")
            }
        }
    }

    func deleteNotification(_ notification: NotificationItem) {
        Task {
            do {
                guard let dbId = notification.dbId else { return }
                try await SupabaseManager.shared.deleteNotification(id: dbId)
                loadNotifications() // Reload to get updated data
            } catch {
                errorMessage = "Failed to delete notification: \(error.localizedDescription)"
                print("❌ Error deleting notification: \(error)")
            }
        }
    }

    func loadCoupons() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let couponResponses = try await SupabaseManager.shared.fetchCoupons(
                    storeId: SecureSupabaseConfig.storeId
                )

                // Convert to UI model
                activeCoupons = couponResponses.map { response in
                    let dateFormatter = ISO8601DateFormatter()
                    let expiresAt = response.end_date.flatMap { dateFormatter.date(from: $0) } ?? Date()

                    let discountText: String
                    if response.discount_type == "percentage" {
                        discountText = "\(Int(response.discount_value))% OFF"
                    } else if response.discount_type == "fixed_amount" {
                        discountText = "$\(Int(response.discount_value)) OFF"
                    } else {
                        discountText = "Special Offer"
                    }

                    return Coupon(
                        id: UUID(),
                        code: response.code,
                        title: response.name,
                        discount: discountText,
                        usedCount: response.current_uses,
                        totalUses: response.max_uses_total,
                        expiresAt: expiresAt,
                        dbId: response.id,
                        isActive: response.is_active
                    )
                }

                isLoading = false
            } catch {
                errorMessage = "Failed to load coupons: \(error.localizedDescription)"
                isLoading = false
                print("❌ Error loading coupons: \(error)")
            }
        }
    }

    func toggleCouponActive(coupon: Coupon) {
        Task {
            do {
                guard let dbId = coupon.dbId else { return }
                try await SupabaseManager.shared.updateCoupon(id: dbId, isActive: !coupon.isActive)
                loadCoupons() // Reload to get updated data
            } catch {
                errorMessage = "Failed to update coupon: \(error.localizedDescription)"
                print("❌ Error updating coupon: \(error)")
            }
        }
    }

    func deleteCoupon(_ coupon: Coupon) {
        Task {
            do {
                guard let dbId = coupon.dbId else { return }
                try await SupabaseManager.shared.deleteCoupon(id: dbId)
                loadCoupons() // Reload to get updated data
            } catch {
                errorMessage = "Failed to delete coupon: \(error.localizedDescription)"
                print("❌ Error deleting coupon: \(error)")
            }
        }
    }
}

// MARK: - Create Notification ViewModel

@MainActor
class CreateNotificationViewModel: ObservableObject {
    @Published var selectedAudience: AudienceType = .allCustomers
    @Published var title = ""
    @Published var message = ""
    @Published var selectedCTA: CTAType = .openApp
    @Published var customLink = ""
    @Published var sendNow = true
    @Published var scheduledDate = Date()
    @Published var selectedImage: UIImage?
    @Published var isSending = false
    @Published var errorMessage: String?

    var estimatedReach: Int {
        switch selectedAudience {
        case .allCustomers:
            return 1250
        case .activeCustomers:
            return 840
        case .inactiveCustomers:
            return 410
        case .newCustomers:
            return 125
        case .vipCustomers:
            return 68
        }
    }

    var isValid: Bool {
        !title.isEmpty && !message.isEmpty
    }

    func sendNotification(completion: @escaping () -> Void) {
        isSending = true
        errorMessage = nil

        Task {
            do {
                let dateFormatter = ISO8601DateFormatter()

                // Convert audience type to database segment
                let targetSegment: String
                switch selectedAudience {
                case .allCustomers:
                    targetSegment = "all"
                case .activeCustomers:
                    targetSegment = "active"
                case .inactiveCustomers:
                    targetSegment = "inactive"
                case .newCustomers:
                    targetSegment = "new_customers"
                case .vipCustomers:
                    targetSegment = "vip"
                }

                // Convert CTA to action URL
                let actionUrl: String?
                switch selectedCTA {
                case .openApp:
                    actionUrl = "app://home"
                case .viewMenu:
                    actionUrl = "app://menu"
                case .viewRewards:
                    actionUrl = "app://rewards"
                case .custom:
                    actionUrl = customLink.isEmpty ? nil : customLink
                }

                let request = SupabaseManager.CreateNotificationRequest(
                    store_id: SecureSupabaseConfig.storeId,
                    title: title,
                    body: message,
                    image_url: nil, // TODO: Upload image if needed
                    action_url: actionUrl,
                    target_segment: targetSegment,
                    send_immediately: sendNow,
                    scheduled_for: sendNow ? nil : dateFormatter.string(from: scheduledDate),
                    status: sendNow ? "sent" : "scheduled"
                )

                _ = try await SupabaseManager.shared.createNotification(notification: request)

                isSending = false
                completion()
            } catch {
                errorMessage = "Failed to send notification: \(error.localizedDescription)"
                isSending = false
                print("❌ Error sending notification: \(error)")
            }
        }
    }
}

// MARK: - Create Coupon ViewModel

@MainActor
class CreateCouponViewModel: ObservableObject {
    @Published var couponCode = ""
    @Published var title = ""
    @Published var description = ""
    @Published var discountType: DiscountType = .percentage
    @Published var discountValue = ""
    @Published var minOrderAmount = ""
    @Published var maxUses = ""
    @Published var onePerCustomer = false
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(86400 * 7)
    @Published var isCreating = false
    @Published var errorMessage: String?

    var isValid: Bool {
        !couponCode.isEmpty && !title.isEmpty && !discountValue.isEmpty
    }

    func createCoupon(completion: @escaping () -> Void) {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                let dateFormatter = ISO8601DateFormatter()

                let discountTypeString: String
                switch discountType {
                case .percentage:
                    discountTypeString = "percentage"
                case .fixed:
                    discountTypeString = "fixed_amount"
                case .freeItem:
                    discountTypeString = "free_item"
                }

                let request = SupabaseManager.CreateCouponRequest(
                    store_id: SecureSupabaseConfig.storeId,
                    code: couponCode.uppercased(),
                    name: title,
                    description: description.isEmpty ? nil : description,
                    discount_type: discountTypeString,
                    discount_value: Double(discountValue) ?? 0,
                    min_order_value: minOrderAmount.isEmpty ? nil : Double(minOrderAmount),
                    max_uses_total: maxUses.isEmpty ? nil : Int(maxUses),
                    max_uses_per_customer: onePerCustomer ? 1 : 999,
                    first_order_only: false,
                    start_date: dateFormatter.string(from: startDate),
                    end_date: dateFormatter.string(from: endDate),
                    is_active: true,
                    is_featured: false
                )

                _ = try await SupabaseManager.shared.createCoupon(coupon: request)

                isCreating = false
                completion()
            } catch {
                errorMessage = "Failed to create coupon: \(error.localizedDescription)"
                isCreating = false
                print("❌ Error creating coupon: \(error)")
            }
        }
    }
}

// MARK: - Loyalty Program ViewModel

@MainActor
class LoyaltyProgramViewModel: ObservableObject {
    @Published var loyaltyProgram: LoyaltyProgram?
    @Published var loyaltyTiers: [LoyaltyTier] = []
    @Published var tierDistribution: [TierDistribution] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalMembers = 0
    @Published var activeMembersPercent = 85

    func loadLoyaltyProgram() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let marketingService = MarketingService.shared
                let storeId = SecureSupabaseConfig.storeId

                // Fetch loyalty program
                guard let programResponse = try await marketingService.getLoyaltyProgram(storeId: storeId) else {
                    errorMessage = "No loyalty program found for this store"
                    isLoading = false
                    return
                }

                await MainActor.run {
                    loyaltyProgram = LoyaltyProgram(
                        id: programResponse.id,
                        storeId: programResponse.storeId,
                        name: programResponse.name,
                        pointsPerDollar: Double(programResponse.pointsPerDollar.description) ?? 1.0,
                        welcomeBonusPoints: programResponse.welcomeBonusPoints,
                        referralBonusPoints: programResponse.referralBonusPoints,
                        isActive: programResponse.isActive
                    )
                }

                // Fetch loyalty tiers
                let tiersResponse = try await marketingService.getLoyaltyTiers(programId: programResponse.id)

                await MainActor.run {
                    loyaltyTiers = tiersResponse.map { response in
                        LoyaltyTier(
                            id: response.id,
                            programId: response.programId,
                            name: response.name,
                            minPoints: response.minPoints,
                            discountPercentage: Double(response.discountPercentage.description) ?? 0,
                            freeDelivery: response.freeDelivery,
                            prioritySupport: response.prioritySupport,
                            earlyAccessPromos: response.earlyAccessPromos,
                            birthdayRewardPoints: response.birthdayRewardPoints,
                            tierColor: response.tierColor,
                            sortOrder: response.sortOrder
                        )
                    }
                }

                // Fetch real tier distribution from database
                let distribution = try await marketingService.getTierDistribution(programId: programResponse.id)

                await MainActor.run {
                    // Calculate total members from distribution
                    totalMembers = distribution.reduce(0) { $0 + $1.count }

                    // Map to TierDistribution model
                    tierDistribution = distribution.map { item in
                        let percentage = totalMembers > 0 ? (Double(item.count) / Double(totalMembers)) * 100 : 0
                        return TierDistribution(
                            id: item.tierName,
                            tierName: item.tierName,
                            tierColor: item.tierColor,
                            memberCount: item.count,
                            percentage: percentage
                        )
                    }

                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load loyalty program: \(error.localizedDescription)"
                    isLoading = false
                }
                print("❌ Error loading loyalty program: \(error)")
            }
        }
    }

    private func calculateTierDistribution(tiers: [LoyaltyTier], totalMembers: Int) -> [TierDistribution] {
        // Mock distribution - in production this would query the database
        guard !tiers.isEmpty, totalMembers > 0 else { return [] }

        let distribution: [Double]
        switch tiers.count {
        case 1:
            distribution = [1.0]
        case 2:
            distribution = [0.65, 0.35]
        case 3:
            distribution = [0.50, 0.35, 0.15]
        case 4:
            distribution = [0.45, 0.30, 0.18, 0.07]
        default:
            // For 5+ tiers, distribute with decreasing percentages
            let percentages = (0..<tiers.count).map { index in
                max(0.05, 0.50 - Double(index) * 0.10)
            }
            let total = percentages.reduce(0, +)
            distribution = percentages.map { $0 / total }
        }

        return zip(tiers.sorted(by: { $0.sortOrder < $1.sortOrder }), distribution).map { tier, percentage in
            let count = Int(Double(totalMembers) * percentage)
            return TierDistribution(
                id: "\(tier.id)",
                tierName: tier.name,
                tierColor: tier.tierColor,
                memberCount: count,
                percentage: percentage * 100
            )
        }
    }
}

// MARK: - Customer Loyalty ViewModel

@MainActor
class CustomerLoyaltyViewModel: ObservableObject {
    @Published var customers: [CustomerLoyaltyListItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadCustomers() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let marketingService = MarketingService.shared

                // Get loyalty program first
                guard let program = try await marketingService.getLoyaltyProgram(storeId: SecureSupabaseConfig.storeId) else {
                    await MainActor.run {
                        customers = []
                        isLoading = false
                    }
                    return
                }

                // Fetch loyalty customers
                let loyaltyCustomers = try await marketingService.getLoyaltyCustomers(programId: program.id, limit: 100)

                await MainActor.run {
                    customers = loyaltyCustomers.map { customer in
                        CustomerLoyaltyListItem(
                            id: customer.id,
                            name: "Customer #\(customer.customerId)", // TODO: Join with customers table for real name
                            email: nil, // TODO: Join with customers table
                            phone: nil, // TODO: Join with customers table
                            points: customer.totalPoints,
                            tierName: "Unknown" // TODO: Join with loyalty_tiers table
                        )
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load customers: \(error.localizedDescription)"
                    isLoading = false
                }
                print("❌ Error loading customers: \(error)")
            }
        }
    }

    func filteredCustomers(searchText: String) -> [CustomerLoyaltyListItem] {
        if searchText.isEmpty {
            return customers
        }

        return customers.filter { customer in
            customer.name.localizedCaseInsensitiveContains(searchText) ||
            customer.email?.localizedCaseInsensitiveContains(searchText) == true ||
            customer.phone?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
}

// MARK: - Customer Loyalty Detail ViewModel

@MainActor
class CustomerLoyaltyDetailViewModel: ObservableObject {
    @Published var customerLoyalty: CustomerLoyalty?
    @Published var currentTier: LoyaltyTier?
    @Published var transactions: [LoyaltyTransaction] = []
    @Published var isLoading = false
    @Published var isLoadingTransactions = false
    @Published var errorMessage: String?

    func loadCustomerLoyalty(customerId: Int) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Fetch customer loyalty data
                let loyaltyResponse = try await SupabaseManager.shared.fetchCustomerLoyalty(
                    customerId: customerId
                )

                let dateFormatter = ISO8601DateFormatter()

                customerLoyalty = CustomerLoyalty(
                    id: loyaltyResponse.id,
                    customerId: loyaltyResponse.customer_id,
                    programId: loyaltyResponse.program_id,
                    currentTierId: loyaltyResponse.current_tier_id,
                    totalPoints: loyaltyResponse.total_points,
                    lifetimePoints: loyaltyResponse.lifetime_points,
                    totalOrders: loyaltyResponse.total_orders,
                    totalSpent: loyaltyResponse.total_spent,
                    joinedAt: dateFormatter.date(from: loyaltyResponse.joined_at) ?? Date(),
                    lastOrderAt: loyaltyResponse.last_order_at.flatMap { dateFormatter.date(from: $0) }
                )

                // Fetch current tier
                if let tierId = loyaltyResponse.current_tier_id {
                    let tiersResponse = try await SupabaseManager.shared.fetchLoyaltyTiers(
                        programId: loyaltyResponse.program_id
                    )

                    if let tierResponse = tiersResponse.first(where: { $0.id == tierId }) {
                        currentTier = LoyaltyTier(
                            id: tierResponse.id,
                            programId: tierResponse.program_id,
                            name: tierResponse.name,
                            minPoints: tierResponse.min_points,
                            discountPercentage: tierResponse.discount_percentage,
                            freeDelivery: tierResponse.free_delivery,
                            prioritySupport: tierResponse.priority_support,
                            earlyAccessPromos: tierResponse.early_access_promos,
                            birthdayRewardPoints: tierResponse.birthday_reward_points,
                            tierColor: tierResponse.tier_color,
                            sortOrder: tierResponse.sort_order
                        )
                    }
                }

                isLoading = false

                // Load transactions
                loadTransactions(loyaltyId: loyaltyResponse.id)
            } catch {
                errorMessage = "Failed to load customer loyalty: \(error.localizedDescription)"
                isLoading = false
                print("❌ Error loading customer loyalty: \(error)")
            }
        }
    }

    func loadTransactions(loyaltyId: Int) {
        isLoadingTransactions = true

        Task {
            do {
                let transactionsResponse = try await SupabaseManager.shared.fetchLoyaltyTransactions(
                    customerLoyaltyId: loyaltyId,
                    limit: 20
                )

                let dateFormatter = ISO8601DateFormatter()

                transactions = transactionsResponse.map { response in
                    LoyaltyTransaction(
                        id: response.id,
                        customerLoyaltyId: response.customer_loyalty_id,
                        orderId: response.order_id,
                        transactionType: response.transaction_type,
                        points: response.points,
                        reason: response.reason,
                        balanceAfter: response.balance_after,
                        createdAt: dateFormatter.date(from: response.created_at) ?? Date()
                    )
                }

                isLoadingTransactions = false
            } catch {
                print("❌ Error loading transactions: \(error)")
                isLoadingTransactions = false
            }
        }
    }
}

// MARK: - Referral Program ViewModel

@MainActor
class ReferralProgramViewModel: ObservableObject {
    @Published var referralProgram: ReferralProgram?
    @Published var referrals: [ReferralItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalReferrals = 0
    @Published var completedReferrals = 0
    @Published var rewardsPaid: Double = 0.0

    func loadReferralProgram() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Fetch referral program
                let programResponse = try await SupabaseManager.shared.fetchReferralProgram(
                    storeId: SecureSupabaseConfig.storeId
                )

                referralProgram = ReferralProgram(
                    id: programResponse.id,
                    storeId: programResponse.store_id,
                    referrerRewardType: programResponse.referrer_reward_type,
                    referrerRewardValue: programResponse.referrer_reward_value,
                    refereeRewardType: programResponse.referee_reward_type,
                    refereeRewardValue: programResponse.referee_reward_value,
                    minOrderValue: programResponse.min_order_value,
                    maxReferralsPerCustomer: programResponse.max_referrals_per_customer,
                    isActive: programResponse.is_active
                )

                // Fetch referrals
                let referralsResponse = try await SupabaseManager.shared.fetchReferrals(
                    programId: programResponse.id,
                    limit: 50
                )

                let dateFormatter = ISO8601DateFormatter()

                referrals = referralsResponse.map { response in
                    ReferralItem(
                        id: response.id,
                        programId: response.program_id,
                        referralCode: response.referral_code,
                        referrerName: "Customer #\(response.referrer_customer_id)", // TODO: Fetch actual name
                        refereeName: response.referee_customer_id != nil ? "Customer #\(response.referee_customer_id!)" : nil,
                        status: response.status,
                        referrerRewarded: response.referrer_rewarded,
                        refereeRewarded: response.referee_rewarded,
                        createdAt: dateFormatter.date(from: response.created_at) ?? Date(),
                        completedAt: response.completed_at.flatMap { dateFormatter.date(from: $0) }
                    )
                }

                // Calculate stats
                totalReferrals = referrals.count
                completedReferrals = referrals.filter { $0.status == "completed" || $0.status == "rewarded" }.count

                // Calculate total rewards paid
                let rewardedReferrals = referrals.filter { $0.status == "rewarded" }
                rewardsPaid = Double(rewardedReferrals.count) * (programResponse.referrer_reward_value + programResponse.referee_reward_value)

                isLoading = false
            } catch {
                errorMessage = "Failed to load referral program: \(error.localizedDescription)"
                isLoading = false
                print("❌ Error loading referral program: \(error)")
            }
        }
    }
}

// MARK: - Marketing Analytics ViewModel

@MainActor
class MarketingAnalyticsViewModel: ObservableObject {
    // Marketing ROI
    @Published var totalRevenue: Double = 0
    @Published var totalSpent: Double = 0
    @Published var roi: Double = 0

    // Notifications
    @Published var notificationsSent: Int = 0
    @Published var notificationDeliveryRate: Double = 0
    @Published var notificationOpenRate: Double = 0
    @Published var notificationConversionRate: Double = 0

    // Coupons
    @Published var totalActiveCoupons: Int = 0
    @Published var couponRedemptionRate: Double = 0
    @Published var avgOrderValueWithCoupon: Double = 0
    @Published var totalDiscountGiven: Double = 0
    @Published var topCoupons: [TopCoupon] = []

    // Loyalty
    @Published var activeLoyaltyMembers: Int = 0
    @Published var avgPointsBalance: Int = 0
    @Published var tierDistribution: [String: Int] = [:]

    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadAnalytics(period: AnalyticsPeriod) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Calculate date range
                let endDate = Date()
                let startDate: Date
                switch period {
                case .week:
                    startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
                case .month:
                    startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
                case .all:
                    startDate = Calendar.current.date(byAdding: .year, value: -10, to: endDate)!
                }

                // Fetch notifications
                let notifications = try await SupabaseManager.shared.fetchNotifications(
                    storeId: SecureSupabaseConfig.storeId
                )

                // Filter by period
                let dateFormatter = ISO8601DateFormatter()
                let filteredNotifications = notifications.filter { notification in
                    if let createdAt = dateFormatter.date(from: notification.created_at) {
                        return createdAt >= startDate && createdAt <= endDate
                    }
                    return false
                }

                // Calculate notification metrics
                notificationsSent = filteredNotifications.reduce(0) { $0 + $1.recipients_count }
                let totalDelivered = filteredNotifications.reduce(0) { $0 + $1.delivered_count }
                let totalOpened = filteredNotifications.reduce(0) { $0 + $1.opened_count }

                notificationDeliveryRate = notificationsSent > 0 ? (Double(totalDelivered) / Double(notificationsSent)) * 100 : 0
                notificationOpenRate = totalDelivered > 0 ? (Double(totalOpened) / Double(totalDelivered)) * 100 : 0
                notificationConversionRate = 15.0 // Placeholder - would need order tracking

                // Fetch coupons
                let coupons = try await SupabaseManager.shared.fetchCoupons(
                    storeId: SecureSupabaseConfig.storeId
                )

                totalActiveCoupons = coupons.filter { $0.is_active }.count

                // Calculate coupon metrics (using placeholder data)
                couponRedemptionRate = 25.0
                avgOrderValueWithCoupon = 45.00
                totalDiscountGiven = Double(coupons.reduce(0) { $0 + $1.current_uses }) * 7.5

                // Top performing coupons
                topCoupons = coupons.sorted { $0.current_uses > $1.current_uses }.prefix(3).map { coupon in
                    TopCoupon(
                        id: coupon.id,
                        code: coupon.code,
                        name: coupon.name,
                        uses: coupon.current_uses,
                        revenue: Double(coupon.current_uses) * 35.0 // Estimated revenue per use
                    )
                }

                // Loyalty metrics (placeholder)
                activeLoyaltyMembers = 248
                avgPointsBalance = 875
                tierDistribution = [
                    "Bronze": 120,
                    "Silver": 85,
                    "Gold": 32,
                    "Platinum": 11
                ]

                // Calculate overall ROI
                totalRevenue = Double(coupons.reduce(0) { $0 + $1.current_uses }) * 35.0
                totalSpent = totalDiscountGiven
                roi = totalSpent > 0 ? ((totalRevenue - totalSpent) / totalSpent) * 100 : 0

                isLoading = false
            } catch {
                errorMessage = "Failed to load analytics: \(error.localizedDescription)"
                isLoading = false
                print("❌ Error loading analytics: \(error)")
            }
        }
    }
}

// MARK: - Create Reward ViewModel

class CreateRewardViewModel: ObservableObject {
    @Published var rewardName = ""
    @Published var description = ""
    @Published var pointsRequired = ""
    @Published var rewardType: RewardType = .freeItem
    @Published var discountValue = ""
    @Published var bonusPoints = ""
    @Published var isLimitedTime = false
    @Published var expirationDate = Date().addingTimeInterval(86400 * 30)
    @Published var totalAvailable = ""
    @Published var selectedImage: UIImage?

    var isValid: Bool {
        !rewardName.isEmpty && !pointsRequired.isEmpty
    }

    func createReward() {
        // TODO: Implement API call
        let reward = RewardData(
            name: rewardName,
            description: description,
            pointsRequired: Int(pointsRequired) ?? 0,
            type: rewardType,
            discountValue: Double(discountValue) ?? nil,
            bonusPoints: Int(bonusPoints) ?? nil,
            isLimitedTime: isLimitedTime,
            expirationDate: isLimitedTime ? expirationDate : nil,
            totalAvailable: Int(totalAvailable) ?? nil,
            imageData: selectedImage?.jpegData(compressionQuality: 0.8)
        )

        print("Creating reward: \(reward)")
    }
}

// MARK: - Automated Campaigns ViewModel

@MainActor
class AutomatedCampaignsViewModel: ObservableObject {
    @Published var campaigns: [AutomatedCampaign] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storeId = 1 // TODO: Get from auth context

    func loadCampaigns() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let responses = try await SupabaseManager.shared.fetchAutomatedCampaigns(storeId: storeId)

                campaigns = responses.map { response in
                    let campaignType = CampaignTypeEnum(rawValue: response.campaign_type) ?? .welcomeSeries

                    let dateFormatter = ISO8601DateFormatter()
                    let createdAt = dateFormatter.date(from: response.created_at) ?? Date()
                    let updatedAt = dateFormatter.date(from: response.updated_at) ?? Date()

                    return AutomatedCampaign(
                        id: response.id,
                        storeId: response.store_id,
                        campaignType: campaignType,
                        name: response.name,
                        description: response.description,
                        triggerCondition: response.trigger_condition,
                        triggerValue: response.trigger_value,
                        notificationTitle: response.notification_title,
                        notificationMessage: response.notification_message,
                        ctaType: response.cta_type,
                        ctaValue: response.cta_value,
                        targetAudience: response.target_audience,
                        isActive: response.is_active,
                        timesTriggered: response.times_triggered,
                        conversionCount: response.conversion_count,
                        revenueGenerated: response.revenue_generated,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                }

                isLoading = false
            } catch {
                errorMessage = "Failed to load campaigns: \(error.localizedDescription)"
                isLoading = false
                print("❌ Error loading campaigns: \(error)")
            }
        }
    }

    func toggleCampaign(campaign: AutomatedCampaign) {
        Task {
            do {
                try await SupabaseManager.shared.toggleCampaignStatus(
                    campaignId: campaign.id,
                    isActive: !campaign.isActive
                )

                // Reload campaigns after toggle
                loadCampaigns()
            } catch {
                errorMessage = "Failed to update campaign: \(error.localizedDescription)"
                print("❌ Error toggling campaign: \(error)")
            }
        }
    }

    func deleteCampaign(campaign: AutomatedCampaign) {
        Task {
            do {
                try await SupabaseManager.shared.deleteAutomatedCampaign(id: campaign.id)

                // Reload campaigns after deletion
                loadCampaigns()
            } catch {
                errorMessage = "Failed to delete campaign: \(error.localizedDescription)"
                print("❌ Error deleting campaign: \(error)")
            }
        }
    }

    var activeCampaigns: [AutomatedCampaign] {
        campaigns.filter { $0.isActive }
    }

    var inactiveCampaigns: [AutomatedCampaign] {
        campaigns.filter { !$0.isActive }
    }

    var totalTriggered: Int {
        campaigns.reduce(0) { $0 + $1.timesTriggered }
    }

    var totalConversions: Int {
        campaigns.reduce(0) { $0 + $1.conversionCount }
    }

    var totalRevenue: Double {
        campaigns.reduce(0.0) { $0 + $1.revenueGenerated }
    }

    var conversionRate: Double {
        totalTriggered > 0 ? (Double(totalConversions) / Double(totalTriggered)) * 100 : 0
    }
}

// MARK: - Customer Segments ViewModel

@MainActor
class CustomerSegmentsViewModel: ObservableObject {
    @Published var predefinedSegments: [CustomerSegment] = []
    @Published var customSegments: [CustomerSegment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userDefaultsKey = "custom_customer_segments"

    init() {
        loadSegments()
    }

    func loadSegments() {
        // Load predefined segments
        predefinedSegments = CustomerSegment.predefinedSegments

        // Load custom segments from UserDefaults
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([CustomerSegment].self, from: savedData) {
            customSegments = decoded
        }

        // Calculate analytics for all segments
        calculateSegmentAnalytics()
    }

    func saveCustomSegment(_ segment: CustomerSegment) {
        customSegments.append(segment)
        saveToUserDefaults()
        calculateSegmentAnalytics()
    }

    func deleteCustomSegment(_ segment: CustomerSegment) {
        customSegments.removeAll { $0.id == segment.id }
        saveToUserDefaults()
    }

    func updateCustomSegment(_ segment: CustomerSegment) {
        if let index = customSegments.firstIndex(where: { $0.id == segment.id }) {
            customSegments[index] = segment
            saveToUserDefaults()
            calculateSegmentAnalytics()
        }
    }

    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(customSegments) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    var allSegments: [CustomerSegment] {
        predefinedSegments + customSegments
    }

    // Calculate mock analytics for segments
    // In production, this would query the database
    private func calculateSegmentAnalytics() {
        // Mock data for demonstration
        predefinedSegments = predefinedSegments.map { segment in
            var updated = segment
            switch segment.name {
            case "All Customers":
                updated.customerCount = 1250
                updated.avgOrderValue = 35.50
                updated.avgOrderFrequency = 2.5
                updated.lifetimeValue = 425.0
            case "Active Customers":
                updated.customerCount = 680
                updated.avgOrderValue = 42.00
                updated.avgOrderFrequency = 4.2
                updated.lifetimeValue = 520.0
            case "Inactive Customers":
                updated.customerCount = 570
                updated.avgOrderValue = 28.00
                updated.avgOrderFrequency = 1.5
                updated.lifetimeValue = 310.0
            case "New Customers":
                updated.customerCount = 145
                updated.avgOrderValue = 32.00
                updated.avgOrderFrequency = 1.0
                updated.lifetimeValue = 32.0
            case "VIP Customers":
                updated.customerCount = 85
                updated.avgOrderValue = 68.00
                updated.avgOrderFrequency = 8.5
                updated.lifetimeValue = 1250.0
            case "High Value":
                updated.customerCount = 215
                updated.avgOrderValue = 55.00
                updated.avgOrderFrequency = 6.0
                updated.lifetimeValue = 850.0
            default:
                updated.customerCount = 0
                updated.avgOrderValue = 0
                updated.avgOrderFrequency = 0
                updated.lifetimeValue = 0
            }
            return updated
        }

        // Calculate for custom segments (simplified mock calculation)
        customSegments = customSegments.map { segment in
            var updated = segment
            // Simplified calculation based on filters
            let estimatedSize = Int.random(in: 50...500)
            updated.customerCount = estimatedSize
            updated.avgOrderValue = Double.random(in: 25...75)
            updated.avgOrderFrequency = Double.random(in: 1.5...8.0)
            updated.lifetimeValue = Double.random(in: 200...1000)
            return updated
        }
    }

    func getSegmentDescription(_ segment: CustomerSegment) -> String {
        if segment.filters.isEmpty {
            return "All customers"
        }

        let descriptions = segment.filters.map { filter in
            "\(filter.filterType.displayName) \(filter.condition.symbol) \(filter.value)"
        }

        return descriptions.joined(separator: " AND ")
    }
}

// MARK: - Loyalty Rewards ViewModel

@MainActor
class LoyaltyRewardsViewModel: ObservableObject {
    @Published var rewards: [LoyaltyReward] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let dateFormatter = ISO8601DateFormatter()

    func loadRewards(programId: Int) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let rewardsResponse = try await SupabaseManager.shared.fetchLoyaltyRewards(programId: programId)

                rewards = rewardsResponse.map { response in
                    LoyaltyReward(
                        id: response.id,
                        programId: response.program_id,
                        name: response.name,
                        description: response.description,
                        pointsCost: response.points_cost,
                        rewardType: RewardType(rawValue: response.reward_type) ?? .discount,
                        rewardValue: response.reward_value,
                        imageUrl: response.image_url,
                        isActive: response.is_active,
                        stockQuantity: response.stock_quantity,
                        redemptionCount: response.redemption_count,
                        sortOrder: response.sort_order,
                        createdAt: dateFormatter.date(from: response.created_at) ?? Date(),
                        updatedAt: dateFormatter.date(from: response.updated_at) ?? Date()
                    )
                }

                isLoading = false
            } catch {
                errorMessage = "Failed to load rewards: \(error.localizedDescription)"
                isLoading = false
                print("❌ Error loading rewards: \(error)")
            }
        }
    }

    func deleteReward(reward: LoyaltyReward, programId: Int) {
        Task {
            do {
                try await SupabaseManager.shared.deleteLoyaltyReward(rewardId: reward.id)
                loadRewards(programId: programId)
            } catch {
                errorMessage = "Failed to delete reward: \(error.localizedDescription)"
                print("❌ Error deleting reward: \(error)")
            }
        }
    }

    var activeRewards: [LoyaltyReward] {
        rewards.filter { $0.isActive }
    }

    var inactiveRewards: [LoyaltyReward] {
        rewards.filter { !$0.isActive }
    }

    var totalRedemptions: Int {
        rewards.reduce(0) { $0 + $1.redemptionCount }
    }
}

// MARK: - Bulk Points Award ViewModel

enum CustomerFilter {
    case all
    case bronze
    case silver
    case gold
    case platinum

    var tierName: String? {
        switch self {
        case .all: return nil
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        }
    }
}

@MainActor
class BulkPointsAwardViewModel: ObservableObject {
    @Published var customers: [CustomerLoyaltyListItem] = []
    @Published var selectedCustomers: Set<Int> = []
    @Published var selectedFilter: CustomerFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadCustomers() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // TODO: Fetch customers from database
                // For now, using placeholder data
                customers = []

                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load customers: \(error.localizedDescription)"
                    isLoading = false
                }
                print("❌ Error loading customers: \(error)")
            }
        }
    }

    func filteredCustomers(searchText: String) -> [CustomerLoyaltyListItem] {
        var filtered = customers

        // Apply tier filter
        if let tierName = selectedFilter.tierName {
            filtered = filtered.filter { $0.tierName == tierName }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { customer in
                customer.name.localizedCaseInsensitiveContains(searchText) ||
                customer.email?.localizedCaseInsensitiveContains(searchText) == true ||
                customer.phone?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return filtered
    }

    func toggleCustomerSelection(customerId: Int) {
        if selectedCustomers.contains(customerId) {
            selectedCustomers.remove(customerId)
        } else {
            selectedCustomers.insert(customerId)
        }
    }

    func awardPoints(customerIds: [Int], points: Int, reason: String) async throws {
        guard !customerIds.isEmpty, points > 0 else {
            throw NSError(domain: "BulkPointsAward", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Invalid parameters"
            ])
        }

        // Call Supabase function to award points to multiple customers
        try await SupabaseManager.shared.bulkAwardLoyaltyPoints(
            customerIds: customerIds,
            points: points,
            reason: reason
        )
    }
}

// MARK: - Advanced Analytics ViewModel

struct RevenueTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct PointsActivityData: Identifiable {
    let id = UUID()
    let date: Date
    let awarded: Int
    let redeemed: Int
}

struct TierDistributionData: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let percentage: Double
}

struct TopRewardData: Identifiable {
    let id = UUID()
    let name: String
    let redemptions: Int
}

struct CampaignPerformanceData: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let conversions: Int
    let roi: Double
}

struct EngagementTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let activeUsers: Int
}

@MainActor
class AdvancedAnalyticsViewModel: ObservableObject {
    @Published var revenueTrend: [RevenueTrendData] = []
    @Published var pointsActivity: [PointsActivityData] = []
    @Published var tierDistribution: [TierDistributionData] = []
    @Published var topRewards: [TopRewardData] = []
    @Published var campaignPerformance: [CampaignPerformanceData] = []
    @Published var engagementTrend: [EngagementTrendData] = []

    // Summary metrics
    @Published var totalRevenue: Double = 0
    @Published var activeMembers: Int = 0
    @Published var pointsAwarded: Int = 0
    @Published var totalRedemptions: Int = 0

    // Change percentages
    @Published var revenueChange: Double = 0
    @Published var memberChange: Double = 0
    @Published var pointsChange: Double = 0
    @Published var redemptionsChange: Double = 0

    var dateStride: Int {
        // Adjust date stride based on data points
        return revenueTrend.count > 14 ? 7 : 1
    }

    func loadAnalytics(period: AnalyticsPeriod) {
        // In production, fetch from database
        // For now, using mock data
        generateMockData(period: period)
    }

    private func generateMockData(period: AnalyticsPeriod) {
        let days = period == .week ? 7 : (period == .month ? 30 : 90)
        let calendar = Calendar.current

        // Revenue Trend
        revenueTrend = (0..<days).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            let baseValue = 500.0
            let variation = Double.random(in: -100...200)
            let trend = Double(days - day) * 10 // Upward trend
            return RevenueTrendData(date: date, value: baseValue + variation + trend)
        }.reversed()

        // Points Activity
        pointsActivity = (0..<days).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            return PointsActivityData(
                date: date,
                awarded: Int.random(in: 500...1500),
                redeemed: Int.random(in: 200...800)
            )
        }.reversed()

        // Tier Distribution
        tierDistribution = [
            TierDistributionData(name: "Bronze", count: 245, percentage: 45),
            TierDistributionData(name: "Silver", count: 163, percentage: 30),
            TierDistributionData(name: "Gold", count: 98, percentage: 18),
            TierDistributionData(name: "Platinum", count: 38, percentage: 7)
        ]

        // Top Rewards
        topRewards = [
            TopRewardData(name: "Free Delivery", redemptions: 421),
            TopRewardData(name: "10% Off", redemptions: 312),
            TopRewardData(name: "Free Fries", redemptions: 245),
            TopRewardData(name: "$5 Off", redemptions: 198),
            TopRewardData(name: "Free Burger", redemptions: 67)
        ]

        // Campaign Performance
        campaignPerformance = [
            CampaignPerformanceData(name: "Welcome", type: "Notification", conversions: 156, roi: 320),
            CampaignPerformanceData(name: "Holiday20", type: "Coupon", conversions: 243, roi: 450),
            CampaignPerformanceData(name: "Double Points", type: "Reward", conversions: 189, roi: 280),
            CampaignPerformanceData(name: "Win-Back", type: "Notification", conversions: 98, roi: 210)
        ]

        // Engagement Trend
        engagementTrend = (0..<days).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            let baseUsers = 300
            let variation = Int.random(in: -30...50)
            let trend = (days - day) * 2 // Growing trend
            return EngagementTrendData(date: date, activeUsers: baseUsers + variation + trend)
        }.reversed()

        // Summary Metrics
        totalRevenue = revenueTrend.reduce(0) { $0 + $1.value }
        activeMembers = tierDistribution.reduce(0) { $0 + $1.count }
        pointsAwarded = pointsActivity.reduce(0) { $0 + $1.awarded }
        totalRedemptions = topRewards.reduce(0) { $0 + $1.redemptions }

        // Change percentages (mock positive growth)
        revenueChange = Double.random(in: 5...15)
        memberChange = Double.random(in: 3...12)
        pointsChange = Double.random(in: 8...18)
        redemptionsChange = Double.random(in: 10...20)
    }
}
