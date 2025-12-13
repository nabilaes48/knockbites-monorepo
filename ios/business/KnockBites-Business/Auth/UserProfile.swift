//
//  UserProfile.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

struct UserProfile: Codable, Identifiable {
    let id: String
    let role: UserRole
    let fullName: String
    let phone: String?
    let storeId: Int?
    let permissions: [Permission]

    // MARK: - Phase 2-3 RBAC Fields
    let assignedStores: [Int]
    let detailedPermissions: [String: [String: Bool]]
    let isSystemAdmin: Bool
    let createdBy: String?
    let canHireRoles: [String]
    let isActive: Bool
    let avatarUrl: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case fullName = "full_name"
        case phone
        case storeId = "store_id"
        case permissions
        case assignedStores = "assigned_stores"
        case detailedPermissions = "detailed_permissions"
        case isSystemAdmin = "is_system_admin"
        case createdBy = "created_by"
        case canHireRoles = "can_hire_roles"
        case isActive = "is_active"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)

        let roleString = try container.decode(String.self, forKey: .role)
        role = UserRole(rawValue: roleString) ?? .staff

        fullName = try container.decode(String.self, forKey: .fullName)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        storeId = try container.decodeIfPresent(Int.self, forKey: .storeId)

        let permissionStrings = try container.decode([String].self, forKey: .permissions)
        permissions = permissionStrings.compactMap { Permission(rawValue: $0) }

        // MARK: - Decode Phase 2-3 RBAC Fields
        assignedStores = try container.decodeIfPresent([Int].self, forKey: .assignedStores) ?? []
        detailedPermissions = try container.decodeIfPresent([String: [String: Bool]].self, forKey: .detailedPermissions) ?? [:]
        isSystemAdmin = try container.decodeIfPresent(Bool.self, forKey: .isSystemAdmin) ?? false
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        canHireRoles = try container.decodeIfPresent([String].self, forKey: .canHireRoles) ?? []
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role.rawValue, forKey: .role)
        try container.encode(fullName, forKey: .fullName)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(storeId, forKey: .storeId)
        try container.encode(permissions.map { $0.rawValue }, forKey: .permissions)

        // MARK: - Encode Phase 2-3 RBAC Fields
        try container.encode(assignedStores, forKey: .assignedStores)
        try container.encode(detailedPermissions, forKey: .detailedPermissions)
        try container.encode(isSystemAdmin, forKey: .isSystemAdmin)
        try container.encodeIfPresent(createdBy, forKey: .createdBy)
        try container.encode(canHireRoles, forKey: .canHireRoles)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

enum UserRole: String, Codable {
    case superAdmin = "super_admin"
    case admin = "admin"
    case manager = "manager"
    case staff = "staff"

    var displayName: String {
        switch self {
        case .superAdmin: return "Super Admin"
        case .admin: return "Admin"
        case .manager: return "Manager"
        case .staff: return "Staff"
        }
    }

    var badgeColor: Color {
        switch self {
        case .superAdmin: return Color.purple
        case .admin: return Color.brandPrimary
        case .manager: return Color.info
        case .staff: return Color.textSecondary
        }
    }
}

enum Permission: String, Codable {
    case orders = "orders"
    case menu = "menu"
    case analytics = "analytics"
    case settings = "settings"
    case staff = "staff"
    case kitchen = "kitchen"
    case marketing = "marketing"

    var displayName: String {
        rawValue.capitalized
    }
}

// Extension for convenient permission checking
extension UserProfile {
    // MARK: - Simple Permission Checking (Legacy)
    func hasPermission(_ permission: Permission) -> Bool {
        permissions.contains(permission)
    }

    func hasAnyPermission(_ permissions: [Permission]) -> Bool {
        !Set(self.permissions).isDisjoint(with: Set(permissions))
    }

    func hasAllPermissions(_ permissions: [Permission]) -> Bool {
        Set(permissions).isSubset(of: Set(self.permissions))
    }

    // MARK: - Granular Permission Checking (Phase 2-3 RBAC)

    /// Check if user has a specific resource.action permission
    /// - Parameter permissionString: Permission in format "resource.action" (e.g., "orders.create", "menu.update")
    /// - Returns: True if user has the permission
    func hasDetailedPermission(_ permissionString: String) -> Bool {
        // Super admins have all permissions
        if isSystemAdmin || role == .superAdmin {
            return true
        }

        // Parse permission string (e.g., "orders.create" → resource: "orders", action: "create")
        let parts = permissionString.split(separator: ".")
        guard parts.count == 2 else { return false }

        let resource = String(parts[0])
        let action = String(parts[1])

        // Check detailed_permissions
        guard let resourcePermissions = detailedPermissions[resource] else {
            return false
        }

        // Check specific action
        if let hasAction = resourcePermissions[action], hasAction {
            return true
        }

        // Check for "manage" permission (grants all actions for this resource)
        if let hasManage = resourcePermissions["manage"], hasManage {
            return true
        }

        return false
    }

    /// Check if user has access to a specific store
    /// - Parameter storeId: Store ID to check
    /// - Returns: True if user has access to this store
    func hasStoreAccess(_ storeId: Int) -> Bool {
        // Super admins have access to all stores
        if isSystemAdmin || role == .superAdmin {
            return true
        }

        // Check assigned_stores array
        return assignedStores.contains(storeId)
    }

    /// Get all stores the user has access to
    /// - Returns: Array of store IDs
    func getAccessibleStores() -> [Int] {
        // Super admins get all stores (you may want to fetch this from a config/database)
        if isSystemAdmin || role == .superAdmin {
            // Return all possible store IDs or fetch from a store service
            // For now, return assigned stores or empty array
            return assignedStores.isEmpty ? [] : assignedStores
        }

        return assignedStores
    }

    /// Check if user can hire a specific role
    /// - Parameter role: Role string to check
    /// - Returns: True if user can hire this role
    func canHireRole(_ role: String) -> Bool {
        // Super admins can hire anyone
        if isSystemAdmin || self.role == .superAdmin {
            return true
        }

        return canHireRoles.contains(role)
    }

    /// Check if user can manage (hire/fire/edit) another user
    /// - Parameter targetUser: The user to check against
    /// - Returns: True if current user can manage the target user
    func canManageUser(_ targetUser: UserProfile) -> Bool {
        // Super admins can manage everyone except other super admins
        if isSystemAdmin || role == .superAdmin {
            return !targetUser.isSystemAdmin
        }

        // Check if user can hire the target user's role
        return canHireRole(targetUser.role.rawValue)
    }
}
