//
//  TableNames.swift
//  knockbites-Bussiness-app
//
//  Created during Phase 4 cleanup - centralizes all Supabase table names
//

import Foundation

/// Centralized table name constants for Supabase queries
/// Eliminates magic strings and makes table name changes easier to manage
enum TableNames {
    // MARK: - Core Tables
    static let stores = "stores"
    static let orders = "orders"
    static let orderItems = "order_items"
    static let menuItems = "menu_items"
    static let menuCategories = "menu_categories"
    static let staffProfiles = "staff_profiles"
    static let staff = "staff"

    // MARK: - Loyalty Tables
    static let loyaltyPrograms = "loyalty_programs"
    static let loyaltyTiers = "loyalty_tiers"
    static let loyaltyRewards = "loyalty_rewards"
    static let customerLoyalty = "customer_loyalty"
    static let loyaltyTransactions = "loyalty_transactions"

    // MARK: - Marketing Tables
    static let coupons = "coupons"
    static let couponUsage = "coupon_usage"
    static let pushNotifications = "push_notifications"
    static let notificationEvents = "notification_events"
    static let automatedCampaigns = "automated_campaigns"
    static let campaignExecutions = "campaign_executions"
    static let customerSegments = "customer_segments"

    // MARK: - Referral Tables
    static let referralProgram = "referral_program"
    static let referrals = "referrals"

    // MARK: - Customization Tables
    static let ingredientTemplates = "ingredient_templates"
    static let menuItemCustomizations = "menu_item_customizations"

    // MARK: - RBAC Tables
    static let roles = "roles"
    static let permissions = "permissions"
    static let rolePermissions = "role_permissions"
    static let userStoreAccess = "user_store_access"
}
