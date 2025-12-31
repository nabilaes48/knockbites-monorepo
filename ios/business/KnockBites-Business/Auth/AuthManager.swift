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
    @Published var isResettingPassword: Bool = false

    private let supabase = SupabaseManager.shared.client
    private var authStateTask: Task<Void, Never>?

    private init() {
        // Check for existing session on init
        Task {
            await checkAuthStatus()
            observeAuthStateChanges()
        }
    }

    // MARK: - Auth State Observer

    private func observeAuthStateChanges() {
        authStateTask = Task {
            for await state in supabase.auth.authStateChanges {
                switch state.event {
                case .signedIn:
                    // Don't auto-authenticate during password reset flow
                    if !self.isResettingPassword {
                        // Only set authenticated if we have a valid profile
                        // (business app requires staff profile)
                        DebugLogger.success("User signed in: \(state.session?.user.email ?? "unknown")")
                    } else {
                        DebugLogger.info("Sign in event ignored - password reset in progress")
                    }

                case .signedOut:
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.userProfile = nil
                    DebugLogger.info("User signed out")

                case .initialSession:
                    // Don't auto-authenticate during password reset flow
                    if state.session != nil && !self.isResettingPassword {
                        DebugLogger.info("Initial session detected")
                    } else if self.isResettingPassword {
                        DebugLogger.info("Initial session ignored - password reset in progress")
                    }

                default:
                    break
                }
            }
        }
    }

    // MARK: - Authentication

    // Helper struct for lockout check response
    private struct LockoutCheckResponse: Codable {
        let isLocked: Bool
        let lockoutUntil: String?

        enum CodingKeys: String, CodingKey {
            case isLocked = "is_locked"
            case lockoutUntil = "lockout_until"
        }
    }

    // Helper struct for login attempt recording (nonisolated for Sendable)
    private nonisolated struct LoginAttemptParams: Encodable, Sendable {
        let p_email: String
        let p_success: Bool
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        // SECURITY: Check if account is locked (rate limiting) - optional feature
        do {
            let lockoutResult: [LockoutCheckResponse] = try await supabase
                .rpc("check_account_lockout", params: ["p_email": email])
                .execute()
                .value

            if let lockout = lockoutResult.first, lockout.isLocked {
                isLoading = false
                if let lockoutUntil = lockout.lockoutUntil {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let lockoutDate = formatter.date(from: lockoutUntil) {
                        let minutesRemaining = Int(ceil(lockoutDate.timeIntervalSinceNow / 60))
                        if minutesRemaining > 0 {
                            errorMessage = "Account temporarily locked. Try again in \(minutesRemaining) minute\(minutesRemaining != 1 ? "s" : "")."
                            throw NSError(domain: "AuthManager", code: 429, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? "Account locked"])
                        }
                    }
                }
                errorMessage = "Account temporarily locked. Please try again later."
                throw NSError(domain: "AuthManager", code: 429, userInfo: [NSLocalizedDescriptionKey: "Account locked"])
            }
        } catch let error as NSError where error.code == 429 {
            throw error
        } catch {
            // Rate limiting function not available - continue with login
            // This allows login to work before the database migration is applied
            DebugLogger.info("Rate limiting check skipped (function not available)")
        }

        var signInSuccess = false
        do {
            DebugLogger.log("🔐 Attempting sign in for: \(email)")
            print("📡 Supabase URL: \(SecureSupabaseConfig.url)")
            print("🔑 Supabase Key prefix: \(SecureSupabaseConfig.anonKey.prefix(30))...")
            print("📧 Email being used: '\(email)' (length: \(email.count))")
            print("🔒 Password length: \(password.count)")

            // Sign in with Supabase Auth
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            DebugLogger.success("Auth sign in successful")
            DebugLogger.log("   User ID: \(session.user.id.uuidString)")
            DebugLogger.log("   Email: \(session.user.email ?? "No email")")

            currentUser = session.user

            // Fetch user profile from database
            try await fetchUserProfile(userId: session.user.id.uuidString)

            isAuthenticated = true
            isLoading = false
            signInSuccess = true

            DebugLogger.success("Sign in complete: \(userProfile?.fullName ?? "Unknown")")
        } catch {
            isLoading = false
            currentUser = nil
            userProfile = nil
            isAuthenticated = false

            // Log the full error for debugging
            DebugLogger.error("Sign in failed: \(error)")
            DebugLogger.log("   Error type: \(type(of: error))")
            DebugLogger.log("   Error description: \(error.localizedDescription)")
            print("❌ FULL AUTH ERROR: \(error)")

            // Provide more user-friendly error messages
            let errorDesc = error.localizedDescription.lowercased()
            if errorDesc.contains("missing") || errorDesc.contains("no rows") {
                errorMessage = "User profile not found. Please contact your administrator."
            } else if errorDesc.contains("invalid login") || errorDesc.contains("invalid email") || errorDesc.contains("credentials") {
                errorMessage = "Invalid email or password."
            } else {
                // Show actual error for debugging
                errorMessage = "Login failed: \(error.localizedDescription)"
            }

            // Record failed attempt before throwing
            do {
                try await supabase
                    .rpc("record_login_attempt", params: LoginAttemptParams(p_email: email, p_success: false))
                    .execute()
            } catch {
                DebugLogger.error("Failed to record login attempt", error)
            }

            throw error
        }

        // SECURITY: Record successful login attempt
        if signInSuccess {
            do {
                try await supabase
                    .rpc("record_login_attempt", params: LoginAttemptParams(p_email: email, p_success: true))
                    .execute()
            } catch {
                DebugLogger.error("Failed to record login attempt", error)
            }
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

            DebugLogger.success("Sign out successful")
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            DebugLogger.error("Sign out failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func checkAuthStatus() async {
        isLoading = true

        // Don't auto-authenticate during password reset flow
        guard !isResettingPassword else {
            DebugLogger.info("Auth status check skipped - password reset in progress")
            isLoading = false
            return
        }

        do {
            // Check if there's a valid session
            let session = try await supabase.auth.session

            currentUser = session.user

            // Fetch user profile
            try await fetchUserProfile(userId: session.user.id.uuidString)

            isAuthenticated = true
            DebugLogger.success("Session restored: \(userProfile?.fullName ?? "Unknown")")
        } catch {
            // No valid session
            currentUser = nil
            userProfile = nil
            isAuthenticated = false
            DebugLogger.info("No active session")
        }

        isLoading = false
    }

    // MARK: - User Profile

    private func fetchUserProfile(userId: String) async throws {
        DebugLogger.log("🔍 Fetching user profile for ID: \(userId)")

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
            // Fetch the raw response from user_profiles (matches web app)
            let data: Data = try await supabase
                .from("user_profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .data

            DebugLogger.log("📦 Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")

            // Decode the response
            let response = try JSONDecoder().decode(UserProfileResponse.self, from: data)

            DebugLogger.success("Decoded profile response:")
            DebugLogger.log("   ID: \(response.id)")
            DebugLogger.log("   Role: \(response.role)")
            DebugLogger.log("   Name: \(response.full_name)")
            DebugLogger.log("   Phone: \(response.phone ?? "nil")")
            DebugLogger.log("   Store ID: \(response.store_id?.description ?? "nil")")
            DebugLogger.log("   Permissions: \(response.permissions.joined(separator: ", "))")
            DebugLogger.log("   Active: \(response.is_active?.description ?? "nil")")
            DebugLogger.log("   RBAC Fields:")
            DebugLogger.log("   - Assigned Stores: \(response.assigned_stores?.map(String.init).joined(separator: ", ") ?? "none")")
            DebugLogger.log("   - Is System Admin: \(response.is_system_admin?.description ?? "false")")
            DebugLogger.log("   - Can Hire Roles: \(response.can_hire_roles?.joined(separator: ", ") ?? "none")")
            DebugLogger.log("   - Detailed Permissions: \(response.detailed_permissions?.keys.joined(separator: ", ") ?? "none")")

            // Convert to UserProfile
            let profileData = try JSONEncoder().encode(response)
            let profile = try JSONDecoder().decode(UserProfile.self, from: profileData)

            userProfile = profile

            DebugLogger.success("User profile loaded: \(profile.role.displayName)")
            DebugLogger.log("   Permissions: \(profile.permissions.map { $0.rawValue }.joined(separator: ", "))")
        } catch let decodingError as DecodingError {
            DebugLogger.error("Decoding error:")
            switch decodingError {
            case .keyNotFound(let key, let context):
                DebugLogger.log("   Missing key: \(key.stringValue)")
                DebugLogger.log("   Context: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                DebugLogger.log("   Type mismatch for type: \(type)")
                DebugLogger.log("   Context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                DebugLogger.log("   Value not found for type: \(type)")
                DebugLogger.log("   Context: \(context.debugDescription)")
            case .dataCorrupted(let context):
                DebugLogger.log("   Data corrupted: \(context.debugDescription)")
            @unknown default:
                DebugLogger.log("   Unknown decoding error: \(decodingError.localizedDescription)")
            }
            throw decodingError
        } catch {
            DebugLogger.error("Profile fetch error: \(error)")
            DebugLogger.log("   Error type: \(type(of: error))")
            DebugLogger.log("   Error description: \(error.localizedDescription)")
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

    // MARK: - Password Reset (OTP Flow)

    /// Send password reset OTP code to email
    func sendPasswordResetOTP(email: String) async throws {
        guard !email.isEmpty else {
            throw NSError(domain: "AuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter your email address"])
        }

        guard isValidEmail(email) else {
            throw NSError(domain: "AuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address"])
        }

        // Send OTP code for password recovery (no redirect URL = OTP mode)
        // When no redirectTo is provided, Supabase sends a 6-digit OTP code instead of a link
        try await supabase.auth.resetPasswordForEmail(email)
        DebugLogger.success("Password reset OTP sent to: \(email)")
    }

    /// Verify the OTP code for password reset
    func verifyPasswordResetOTP(email: String, token: String) async throws {
        // Set flag to prevent auth state listener from navigating away
        isResettingPassword = true

        do {
            try await supabase.auth.verifyOTP(
                email: email,
                token: token,
                type: .recovery
            )
            DebugLogger.success("OTP verified successfully - proceeding to password reset")
        } catch {
            isResettingPassword = false
            DebugLogger.error("OTP verification error: \(error)")
            throw NSError(domain: "AuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid or expired code"])
        }
    }

    /// Update password after OTP verification
    func updatePassword(newPassword: String) async throws {
        guard newPassword.count >= 8 else {
            throw NSError(domain: "AuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 8 characters"])
        }

        do {
            try await supabase.auth.update(user: .init(password: newPassword))
            DebugLogger.success("Password updated successfully")

            // Clear the password reset flag
            isResettingPassword = false

            // Sign out after password update so user can log in with new password
            // (Business app requires staff profile verification on login)
            try await supabase.auth.signOut()
            isAuthenticated = false
            currentUser = nil
            userProfile = nil
            DebugLogger.success("Signed out after password reset - please log in with new password")
        } catch {
            isResettingPassword = false
            DebugLogger.error("Password update error: \(error)")
            throw NSError(domain: "AuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to update password. Please try again."])
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    deinit {
        authStateTask?.cancel()
    }
}
