//
//  RBACModels.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//  Phase 2-3 RBAC Data Models
//

import Foundation
import Supabase

// MARK: - Store Assignment

/// Represents a user's assignment to a store
struct StoreAssignment: Codable, Identifiable {
    let id: String
    let userId: String
    let storeId: Int
    let isPrimaryStore: Bool
    let assignedAt: String
    let assignedBy: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case storeId = "store_id"
        case isPrimaryStore = "is_primary_store"
        case assignedAt = "assigned_at"
        case assignedBy = "assigned_by"
    }
}

// MARK: - User Hierarchy

/// Represents reporting structure (who reports to whom)
struct UserHierarchy: Codable, Identifiable {
    let id: String
    let userId: String
    let reportsTo: String?
    let level: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case reportsTo = "reports_to"
        case level
        case createdAt = "created_at"
    }

    /// Human-readable level name
    var levelName: String {
        switch level {
        case 4: return "Executive"
        case 3: return "Administrator"
        case 2: return "Manager"
        case 1: return "Supervisor"
        case 0: return "Staff"
        default: return "Unknown"
        }
    }
}

// MARK: - Permission Change

/// Audit log for permission/role changes
struct PermissionChange: Codable, Identifiable {
    let id: String
    let targetUserId: String
    let changedBy: String
    let action: String
    let oldRole: String?
    let newRole: String?
    let oldPermissions: [String: [String: Bool]]?
    let newPermissions: [String: [String: Bool]]?
    let reason: String?
    let changedAt: String
    let ipAddress: String?
    let userAgent: String?

    enum CodingKeys: String, CodingKey {
        case id
        case targetUserId = "target_user_id"
        case changedBy = "changed_by"
        case action
        case oldRole = "old_role"
        case newRole = "new_role"
        case oldPermissions = "old_permissions"
        case newPermissions = "new_permissions"
        case reason
        case changedAt = "changed_at"
        case ipAddress = "ip_address"
        case userAgent = "user_agent"
    }

    /// Human-readable change description
    var changeDescription: String {
        switch action {
        case "role_change":
            return "Role changed from \(oldRole ?? "Unknown") to \(newRole ?? "Unknown")"
        case "permission_update":
            return "Permissions updated"
        case "store_assignment":
            return "Store assignment changed"
        case "activation":
            return "User account activated"
        case "deactivation":
            return "User account deactivated"
        default:
            return action.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    /// Formatted timestamp
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: changedAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return changedAt
    }
}

// MARK: - RBAC Service Extensions

extension StoreAssignment {
    /// Fetch all store assignments for a user
    static func fetchAssignments(for userId: String, from supabase: SupabaseClient) async throws -> [StoreAssignment] {
        let data: Data = try await supabase
            .from("store_assignments")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .data

        return try JSONDecoder().decode([StoreAssignment].self, from: data)
    }
}

extension UserHierarchy {
    /// Fetch hierarchy information for a user
    static func fetchHierarchy(for userId: String, from supabase: SupabaseClient) async throws -> UserHierarchy? {
        do {
            let data: Data = try await supabase
                .from("user_hierarchy")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .data

            return try JSONDecoder().decode(UserHierarchy.self, from: data)
        } catch {
            // No hierarchy record found
            return nil
        }
    }

    /// Fetch all direct reports for a user
    static func fetchDirectReports(for userId: String, from supabase: SupabaseClient) async throws -> [UserHierarchy] {
        let data: Data = try await supabase
            .from("user_hierarchy")
            .select()
            .eq("reports_to", value: userId)
            .execute()
            .data

        return try JSONDecoder().decode([UserHierarchy].self, from: data)
    }
}

extension PermissionChange {
    /// Fetch permission change history for a user
    static func fetchHistory(for userId: String, from supabase: SupabaseClient, limit: Int = 50) async throws -> [PermissionChange] {
        let data: Data = try await supabase
            .from("permission_changes")
            .select()
            .eq("target_user_id", value: userId)
            .order("changed_at", ascending: false)
            .limit(limit)
            .execute()
            .data

        return try JSONDecoder().decode([PermissionChange].self, from: data)
    }

    /// Create a new permission change log entry
    static func log(
        targetUserId: String,
        changedBy: String,
        action: String,
        oldRole: String? = nil,
        newRole: String? = nil,
        oldPermissions: [String: [String: Bool]]? = nil,
        newPermissions: [String: [String: Bool]]? = nil,
        reason: String? = nil,
        from supabase: SupabaseClient
    ) async throws {
        struct PermissionChangeLog: Codable {
            let target_user_id: String
            let changed_by: String
            let action: String
            let old_role: String?
            let new_role: String?
            let old_permissions: [String: [String: Bool]]?
            let new_permissions: [String: [String: Bool]]?
            let reason: String?
        }

        let log = PermissionChangeLog(
            target_user_id: targetUserId,
            changed_by: changedBy,
            action: action,
            old_role: oldRole,
            new_role: newRole,
            old_permissions: oldPermissions,
            new_permissions: newPermissions,
            reason: reason
        )

        try await supabase
            .from("permission_changes")
            .insert(log)
            .execute()
    }
}
