/**
 * Compatibility Aliases — KnockBites Business App
 *
 * Type aliases that map legacy model names to the new SharedModels.
 * This allows gradual migration without breaking existing code.
 *
 * Usage: Import SharedModels and use the aliases, or use Shared* types directly.
 */

import Foundation

// MARK: - Order Compatibility

/// Type alias for backwards compatibility
typealias OrderFromSupabase = SharedOrder
typealias OrderItemFromSupabase = SharedOrderItem

/// Extension to provide legacy computed properties
extension SharedOrder {
    /// Legacy property name - notes is defined in the model
    var notes: String? { specialInstructions }

    /// Convert to display-friendly status string
    var statusDisplayName: String { status.displayName }
}

extension SharedOrderStatus {
    /// Map from legacy status strings
    static func fromLegacy(_ string: String) -> SharedOrderStatus {
        switch string.lowercased() {
        case "pending": return .pending
        case "received": return .received
        case "acknowledged": return .acknowledged
        case "preparing", "in_progress": return .preparing
        case "ready", "ready_for_pickup": return .ready
        case "completed", "delivered": return .completed
        case "cancelled", "canceled": return .cancelled
        case "scheduled": return .scheduled
        default: return .pending  // Default fallback
        }
    }
}

// MARK: - Menu Compatibility

typealias MenuItemFromSupabase = SharedMenuItem
typealias MenuCategoryFromSupabase = SharedMenuCategory

extension SharedMenuItem {
    /// Legacy property for base price
    var basePrice: Double { price }

    /// Legacy property for preparation time
    var preparationTime: Int? { prepTime }
}

// MARK: - Customer Compatibility

typealias CustomerFromSupabase = SharedCustomer

// Note: SharedCustomer already has computed `phone` property that resolves both field names

// MARK: - Store Compatibility

typealias StoreFromSupabase = SharedStore

// MARK: - Loyalty Compatibility

typealias LoyaltyProgramFromSupabase = SharedLoyaltyProgram
typealias CustomerLoyaltyFromSupabase = SharedCustomerLoyalty
typealias LoyaltyTransactionFromSupabase = SharedLoyaltyTransaction

// MARK: - Marketing Compatibility

typealias CouponFromSupabase = SharedCoupon
typealias AutomatedCampaignFromSupabase = SharedAutomatedCampaign

// Note: SharedAutomatedCampaign already has computed properties:
// - notificationMessage (maps to notificationBody)
// - timesTriggered (maps to totalTriggered)

// MARK: - Referral Compatibility

typealias ReferralProgramFromSupabase = SharedReferralProgram
typealias ReferralFromSupabase = SharedReferral

// MARK: - Analytics Compatibility

typealias AnalyticsSummaryFromSupabase = SharedAnalyticsSummary
typealias DailyStatsFromSupabase = SharedDailyStats
typealias HourlyStatsFromSupabase = SharedHourlyStats
typealias PopularItemFromSupabase = SharedPopularItem
