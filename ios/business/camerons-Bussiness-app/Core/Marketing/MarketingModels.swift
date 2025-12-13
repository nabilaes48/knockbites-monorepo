//
//  MarketingModels.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import Foundation

// MARK: - Campaign Models

struct Campaign: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let type: CampaignType
    let status: CampaignStatus
    let sentCount: Int
    let openRate: Int
    let expiresAt: Date?
}

enum CampaignType {
    case promotion
    case announcement
    case reminder

    var icon: String {
        switch self {
        case .promotion: return "tag.fill"
        case .announcement: return "megaphone.fill"
        case .reminder: return "bell.fill"
        }
    }

    var color: Color {
        switch self {
        case .promotion: return .success
        case .announcement: return .brandPrimary
        case .reminder: return .warning
        }
    }
}

enum CampaignStatus: String {
    case active = "Active"
    case scheduled = "Scheduled"
    case completed = "Completed"
    case draft = "Draft"

    var color: Color {
        switch self {
        case .active: return .success
        case .scheduled: return .brandPrimary
        case .completed: return .textSecondary
        case .draft: return .warning
        }
    }
}

struct CampaignStats {
    let sentToday: Int
    let opened: Int
    let clicked: Int
    let converted: Int
}

// MARK: - Audience Types

enum AudienceType: String, CaseIterable {
    case allCustomers = "All Customers"
    case activeCustomers = "Active Customers"
    case inactiveCustomers = "Inactive Customers"
    case newCustomers = "New Customers"
    case vipCustomers = "VIP Customers"

    var title: String {
        rawValue
    }

    var description: String {
        switch self {
        case .allCustomers:
            return "Send to all registered customers"
        case .activeCustomers:
            return "Customers who ordered in last 30 days"
        case .inactiveCustomers:
            return "Customers who haven't ordered in 30+ days"
        case .newCustomers:
            return "Customers who joined in last 7 days"
        case .vipCustomers:
            return "Customers with 500+ loyalty points"
        }
    }
}

// MARK: - CTA Types

enum CTAType: String, CaseIterable {
    case openApp = "Open App"
    case viewMenu = "View Menu"
    case viewRewards = "View Rewards"
    case custom = "Custom Link"

    var title: String {
        rawValue
    }

    var description: String {
        switch self {
        case .openApp:
            return "Opens the main app screen"
        case .viewMenu:
            return "Opens directly to menu"
        case .viewRewards:
            return "Opens rewards/loyalty screen"
        case .custom:
            return "Specify a custom deep link"
        }
    }
}

// MARK: - Discount Types

enum DiscountType: String {
    case percentage = "Percentage"
    case fixed = "Fixed Amount"
    case freeItem = "Free Item"
}

// MARK: - Data Transfer Objects

struct NotificationData {
    let title: String
    let message: String
    let audience: AudienceType
    let cta: CTAType
    let customLink: String
    let sendNow: Bool
    let scheduledDate: Date
    let imageData: Data?
}

struct CouponData {
    let code: String
    let title: String
    let description: String
    let discountType: DiscountType
    let discountValue: Double
    let minOrderAmount: Double?
    let maxUses: Int?
    let onePerCustomer: Bool
    let startDate: Date
    let endDate: Date
}

struct RewardData {
    let name: String
    let description: String
    let pointsRequired: Int
    let type: RewardType
    let discountValue: Double?
    let bonusPoints: Int?
    let isLimitedTime: Bool
    let expirationDate: Date?
    let totalAvailable: Int?
    let imageData: Data?
}

// MARK: - List Items

struct NotificationItem: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let sentAt: Date
    let sentCount: Int
    let openRate: Int
    let dbId: Int?
    let status: String

    init(id: UUID = UUID(), title: String, message: String, sentAt: Date, sentCount: Int, openRate: Int, dbId: Int? = nil, status: String = "draft") {
        self.id = id
        self.title = title
        self.message = message
        self.sentAt = sentAt
        self.sentCount = sentCount
        self.openRate = openRate
        self.dbId = dbId
        self.status = status
    }
}

// MARK: - Loyalty Models

struct LoyaltyProgram {
    let id: Int
    let storeId: Int
    let name: String
    let pointsPerDollar: Double
    let welcomeBonusPoints: Int
    let referralBonusPoints: Int
    let isActive: Bool
}

struct LoyaltyTier: Identifiable {
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
}

struct TierDistribution: Identifiable {
    let id: String
    let tierName: String
    let tierColor: String?
    let memberCount: Int
    let percentage: Double
}

struct CustomerLoyalty {
    let id: Int
    let customerId: Int
    let programId: Int
    let currentTierId: Int?
    let totalPoints: Int
    let lifetimePoints: Int
    let totalOrders: Int
    let totalSpent: Double
    let joinedAt: Date
    let lastOrderAt: Date?
}

struct LoyaltyTransaction: Identifiable {
    let id: Int
    let customerLoyaltyId: Int
    let orderId: String?
    let transactionType: String
    let points: Int
    let reason: String?
    let balanceAfter: Int
    let createdAt: Date
}

struct LoyaltyReward: Identifiable {
    let id: Int
    let programId: Int
    let name: String
    let description: String?
    let pointsCost: Int
    let rewardType: RewardType
    let rewardValue: String
    let imageUrl: String?
    let isActive: Bool
    let stockQuantity: Int?
    let redemptionCount: Int
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
}

enum RewardType: String, CaseIterable, Codable {
    case discount = "discount"          // % or $ off order
    case freeItem = "free_item"        // Free menu item
    case freeDelivery = "free_delivery" // Free delivery on order
    case giftCard = "gift_card"        // Store credit/gift card
    case merchandise = "merchandise"    // Physical items

    var displayName: String {
        switch self {
        case .discount: return "Discount"
        case .freeItem: return "Free Item"
        case .freeDelivery: return "Free Delivery"
        case .giftCard: return "Gift Card"
        case .merchandise: return "Merchandise"
        }
    }

    var icon: String {
        switch self {
        case .discount: return "percent"
        case .freeItem: return "gift.fill"
        case .freeDelivery: return "shippingbox.fill"
        case .giftCard: return "creditcard.fill"
        case .merchandise: return "tshirt.fill"
        }
    }

    var color: Color {
        switch self {
        case .discount: return .success
        case .freeItem: return .warning
        case .freeDelivery: return .info
        case .giftCard: return .brandPrimary
        case .merchandise: return .purple
        }
    }
}

// MARK: - Referral Models

struct ReferralProgram {
    let id: Int
    let storeId: Int
    let referrerRewardType: String
    let referrerRewardValue: Double
    let refereeRewardType: String
    let refereeRewardValue: Double
    let minOrderValue: Double
    let maxReferralsPerCustomer: Int?
    let isActive: Bool
}

struct ReferralItem: Identifiable {
    let id: Int
    let programId: Int
    let referralCode: String
    let referrerName: String
    let refereeName: String?
    let status: String
    let referrerRewarded: Bool
    let refereeRewarded: Bool
    let createdAt: Date
    let completedAt: Date?
}

// MARK: - Analytics Models

struct TopCoupon: Identifiable {
    let id: Int
    let code: String
    let name: String
    let uses: Int
    let revenue: Double
}

struct CustomerLoyaltyListItem: Identifiable {
    let id: Int
    let name: String
    let email: String?
    let phone: String?
    let points: Int
    let tierName: String

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else {
            return String(name.prefix(2))
        }
    }
}

struct Coupon: Identifiable {
    let id: UUID
    let code: String
    let title: String
    let discount: String
    let usedCount: Int
    let totalUses: Int?
    let expiresAt: Date
    let dbId: Int?
    let isActive: Bool

    init(id: UUID = UUID(), code: String, title: String, discount: String, usedCount: Int, totalUses: Int?, expiresAt: Date, dbId: Int? = nil, isActive: Bool = true) {
        self.id = id
        self.code = code
        self.title = title
        self.discount = discount
        self.usedCount = usedCount
        self.totalUses = totalUses
        self.expiresAt = expiresAt
        self.dbId = dbId
        self.isActive = isActive
    }
}

// MARK: - Automated Campaign Models

struct AutomatedCampaign: Identifiable {
    let id: Int
    let storeId: Int
    let campaignType: CampaignTypeEnum
    let name: String
    let description: String?
    let triggerCondition: String
    let triggerValue: Int?
    let notificationTitle: String
    let notificationMessage: String
    let ctaType: String?
    let ctaValue: String?
    let targetAudience: String
    let isActive: Bool
    let timesTriggered: Int
    let conversionCount: Int
    let revenueGenerated: Double
    let createdAt: Date
    let updatedAt: Date
}

enum CampaignTypeEnum: String {
    case welcomeSeries = "welcome_series"
    case winBack = "win_back"
    case birthdayReward = "birthday_reward"
    case orderReminder = "order_reminder"
    case abandonedCart = "abandoned_cart"

    var displayName: String {
        switch self {
        case .welcomeSeries: return "Welcome Series"
        case .winBack: return "Win-Back"
        case .birthdayReward: return "Birthday Reward"
        case .orderReminder: return "Order Reminder"
        case .abandonedCart: return "Abandoned Cart"
        }
    }

    var icon: String {
        switch self {
        case .welcomeSeries: return "hand.wave.fill"
        case .winBack: return "arrow.uturn.left.circle.fill"
        case .birthdayReward: return "gift.fill"
        case .orderReminder: return "bell.fill"
        case .abandonedCart: return "cart.fill.badge.minus"
        }
    }

    var color: Color {
        switch self {
        case .welcomeSeries: return .brandPrimary
        case .winBack: return .warning
        case .birthdayReward: return .success
        case .orderReminder: return .info
        case .abandonedCart: return .error
        }
    }
}

// MARK: - Customer Segment Models

struct CustomerSegment: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let filters: [SegmentFilter]
    let createdAt: Date
    var customerCount: Int?
    var avgOrderValue: Double?
    var avgOrderFrequency: Double?
    var lifetimeValue: Double?

    init(id: UUID = UUID(), name: String, description: String? = nil, filters: [SegmentFilter], createdAt: Date = Date(), customerCount: Int? = nil, avgOrderValue: Double? = nil, avgOrderFrequency: Double? = nil, lifetimeValue: Double? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.filters = filters
        self.createdAt = createdAt
        self.customerCount = customerCount
        self.avgOrderValue = avgOrderValue
        self.avgOrderFrequency = avgOrderFrequency
        self.lifetimeValue = lifetimeValue
    }
}

struct SegmentFilter: Identifiable, Codable {
    let id: UUID
    let filterType: SegmentFilterType
    let condition: SegmentCondition
    let value: String

    init(id: UUID = UUID(), filterType: SegmentFilterType, condition: SegmentCondition, value: String) {
        self.id = id
        self.filterType = filterType
        self.condition = condition
        self.value = value
    }
}

enum SegmentFilterType: String, CaseIterable, Codable {
    case totalOrders = "total_orders"
    case totalSpent = "total_spent"
    case lastOrderDays = "last_order_days"
    case loyaltyPoints = "loyalty_points"
    case avgOrderValue = "avg_order_value"
    case loyaltyTier = "loyalty_tier"

    var displayName: String {
        switch self {
        case .totalOrders: return "Total Orders"
        case .totalSpent: return "Total Spent"
        case .lastOrderDays: return "Last Order (Days Ago)"
        case .loyaltyPoints: return "Loyalty Points"
        case .avgOrderValue: return "Avg Order Value"
        case .loyaltyTier: return "Loyalty Tier"
        }
    }

    var icon: String {
        switch self {
        case .totalOrders: return "cart.fill"
        case .totalSpent: return "dollarsign.circle.fill"
        case .lastOrderDays: return "clock.fill"
        case .loyaltyPoints: return "star.fill"
        case .avgOrderValue: return "chart.bar.fill"
        case .loyaltyTier: return "crown.fill"
        }
    }

    var availableConditions: [SegmentCondition] {
        switch self {
        case .loyaltyTier:
            return [.equals]
        default:
            return [.equals, .greaterThan, .lessThan, .between]
        }
    }
}

enum SegmentCondition: String, CaseIterable, Codable {
    case equals = "equals"
    case greaterThan = "greater_than"
    case lessThan = "less_than"
    case between = "between"

    var displayName: String {
        switch self {
        case .equals: return "Equals"
        case .greaterThan: return "Greater Than"
        case .lessThan: return "Less Than"
        case .between: return "Between"
        }
    }

    var symbol: String {
        switch self {
        case .equals: return "="
        case .greaterThan: return ">"
        case .lessThan: return "<"
        case .between: return "↔"
        }
    }
}

// MARK: - Predefined Segments

extension CustomerSegment {
    static let predefinedSegments: [CustomerSegment] = [
        CustomerSegment(
            name: "All Customers",
            description: "All registered customers",
            filters: []
        ),
        CustomerSegment(
            name: "Active Customers",
            description: "Ordered in last 30 days",
            filters: [
                SegmentFilter(
                    filterType: .lastOrderDays,
                    condition: .lessThan,
                    value: "30"
                )
            ]
        ),
        CustomerSegment(
            name: "Inactive Customers",
            description: "No orders in 30+ days",
            filters: [
                SegmentFilter(
                    filterType: .lastOrderDays,
                    condition: .greaterThan,
                    value: "30"
                )
            ]
        ),
        CustomerSegment(
            name: "New Customers",
            description: "First order in last 7 days",
            filters: [
                SegmentFilter(
                    filterType: .totalOrders,
                    condition: .equals,
                    value: "1"
                )
            ]
        ),
        CustomerSegment(
            name: "VIP Customers",
            description: "500+ loyalty points",
            filters: [
                SegmentFilter(
                    filterType: .loyaltyPoints,
                    condition: .greaterThan,
                    value: "500"
                )
            ]
        ),
        CustomerSegment(
            name: "High Value",
            description: "Spent $500+",
            filters: [
                SegmentFilter(
                    filterType: .totalSpent,
                    condition: .greaterThan,
                    value: "500"
                )
            ]
        )
    ]
}
