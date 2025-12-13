//
//  AuthManager.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = SupabaseManager.shared.client

    private init() {
        // Check for existing session on init
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            print("🔐 Attempting sign in for: \(email)")

            // Sign in with Supabase Auth
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            print("✅ Auth sign in successful")
            print("   User ID: \(session.user.id.uuidString)")
            print("   Email: \(session.user.email ?? "No email")")

            currentUser = session.user

            // Fetch user profile from database
            try await fetchUserProfile(userId: session.user.id.uuidString)

            isAuthenticated = true
            isLoading = false

            print("✅ Sign in complete: \(userProfile?.fullName ?? "Unknown")")
        } catch {
            isLoading = false
            currentUser = nil
            userProfile = nil
            isAuthenticated = false

            // Provide more user-friendly error messages
            if error.localizedDescription.contains("missing") {
                errorMessage = "User profile not found. Please contact your administrator."
            } else if error.localizedDescription.contains("Invalid login") || error.localizedDescription.contains("credentials") {
                errorMessage = "Invalid email or password."
            } else {
                errorMessage = error.localizedDescription
            }

            print("❌ Sign in failed: \(error)")
            print("   Error type: \(type(of: error))")
            throw error
        }
    }

    func signOut() async {
        isLoading = true

        do {
            try await supabase.auth.signOut()

            currentUser = nil
            userProfile = nil
            isAuthenticated = false
            errorMessage = nil

            print("✅ Sign out successful")
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            print("❌ Sign out failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func checkAuthStatus() async {
        isLoading = true

        do {
            // Check if there's a valid session
            let session = try await supabase.auth.session

            currentUser = session.user

            // Fetch user profile
            try await fetchUserProfile(userId: session.user.id.uuidString)

            isAuthenticated = true
            print("✅ Session restored: \(userProfile?.fullName ?? "Unknown")")
        } catch {
            // No valid session
            currentUser = nil
            userProfile = nil
            isAuthenticated = false
            print("ℹ️ No active session")
        }

        isLoading = false
    }

    // MARK: - User Profile

    private func fetchUserProfile(userId: String) async throws {
        print("🔍 Fetching user profile for ID: \(userId)")

        struct UserProfileResponse: Codable {
            let id: String
            let role: String
            let full_name: String
            let phone: String?
            let store_id: Int?
            let permissions: [String]
            let is_active: Bool?
            let avatar_url: String?
            let created_at: String?
            let updated_at: String?

            // MARK: - Phase 2-3 RBAC Fields
            let assigned_stores: [Int]?
            let detailed_permissions: [String: [String: Bool]]?
            let is_system_admin: Bool?
            let created_by: String?
            let can_hire_roles: [String]?
        }

        do {
            // Fetch the raw response
            let data: Data = try await supabase
                .from("staff_profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .data

            print("📦 Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")

            // Decode the response
            let response = try JSONDecoder().decode(UserProfileResponse.self, from: data)

            print("✅ Decoded profile response:")
            print("   ID: \(response.id)")
            print("   Role: \(response.role)")
            print("   Name: \(response.full_name)")
            print("   Phone: \(response.phone ?? "nil")")
            print("   Store ID: \(response.store_id?.description ?? "nil")")
            print("   Permissions: \(response.permissions.joined(separator: ", "))")
            print("   Active: \(response.is_active?.description ?? "nil")")
            print("   RBAC Fields:")
            print("   - Assigned Stores: \(response.assigned_stores?.map(String.init).joined(separator: ", ") ?? "none")")
            print("   - Is System Admin: \(response.is_system_admin?.description ?? "false")")
            print("   - Can Hire Roles: \(response.can_hire_roles?.joined(separator: ", ") ?? "none")")
            print("   - Detailed Permissions: \(response.detailed_permissions?.keys.joined(separator: ", ") ?? "none")")

            // Convert to UserProfile
            let profileData = try JSONEncoder().encode(response)
            let profile = try JSONDecoder().decode(UserProfile.self, from: profileData)

            userProfile = profile

            print("✅ User profile loaded: \(profile.role.displayName)")
            print("   Permissions: \(profile.permissions.map { $0.rawValue }.joined(separator: ", "))")
        } catch let decodingError as DecodingError {
            print("❌ Decoding error:")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Missing key: \(key.stringValue)")
                print("   Context: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("   Type mismatch for type: \(type)")
                print("   Context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   Value not found for type: \(type)")
                print("   Context: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("   Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("   Unknown decoding error: \(decodingError.localizedDescription)")
            }
            throw decodingError
        } catch {
            print("❌ Profile fetch error: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Permission Checking

    // MARK: Legacy Permission Methods
    func hasPermission(_ permission: Permission) -> Bool {
        guard let profile = userProfile else { return false }
        return profile.hasPermission(permission)
    }

    func hasAnyPermission(_ permissions: [Permission]) -> Bool {
        guard let profile = userProfile else { return false }
        return profile.hasAnyPermission(permissions)
    }

    func hasAllPermissions(_ permissions: [Permission]) -> Bool {
        guard let profile = userProfile else { return false }
        return profile.hasAllPermissions(permissions)
    }

    // MARK: Role-Based Checks
    func isSuperAdmin() -> Bool {
        userProfile?.isSystemAdmin == true || userProfile?.role == .superAdmin
    }

    func isAdmin() -> Bool {
        userProfile?.role == .admin || isSuperAdmin()
    }

    func isManager() -> Bool {
        userProfile?.role == .manager || isAdmin()
    }

    // MARK: - Granular Permission Checking (Phase 2-3 RBAC)

    /// Check if user has a specific resource.action permission
    /// - Parameter permissionString: Permission in format "resource.action" (e.g., "orders.create", "menu.update")
    /// - Returns: True if user has the permission
    func hasDetailedPermission(_ permissionString: String) -> Bool {
        guard let profile = userProfile else { return false }
        return profile.hasDetailedPermission(permissionString)
    }

    /// Check if user has access to a specific store
    /// - Parameter storeId: Store ID to check
    /// - Returns: True if user has access to this store
    func hasStoreAccess(_ storeId: Int) -> Bool {
        guard let profile = userProfile else { return false }
        return profile.hasStoreAccess(storeId)
    }

    /// Get all stores the user has access to
    /// - Returns: Array of store IDs
    func getAccessibleStores() -> [Int] {
        guard let profile = userProfile else { return [] }
        return profile.getAccessibleStores()
    }

    /// Check if user can hire a specific role
    /// - Parameter role: Role string to check
    /// - Returns: True if user can hire this role
    func canHireRole(_ role: String) -> Bool {
        guard let profile = userProfile else { return false }
        return profile.canHireRole(role)
    }

    /// Check if user can manage (hire/fire/edit) another user
    /// - Parameter targetUser: The user to check against
    /// - Returns: True if current user can manage the target user
    func canManageUser(_ targetUser: UserProfile) -> Bool {
        guard let profile = userProfile else { return false }
        return profile.canManageUser(targetUser)
    }

    // MARK: - Helpers

    func clearError() {
        errorMessage = nil
    }
}
