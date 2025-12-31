//
//  AuthManager.swift
//  knockbites-customer-app
//
//  Created by Claude on 11/18/25.
//

import Foundation
import Supabase
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isResettingPassword = false

    private let supabase = SupabaseManager.shared.client
    private var authStateTask: Task<Void, Never>?

    private init() {
        // Check current session on init
        Task {
            await checkSession()
            observeAuthStateChanges()
        }
    }

    // MARK: - Auth State Management

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        // Don't auto-authenticate during password reset flow
        guard !isResettingPassword else {
            DebugLogger.info("Session check skipped - password reset in progress")
            return
        }

        do {
            let session = try await supabase.auth.session
            isAuthenticated = true
            DebugLogger.success("Active session found for user: \(session.user.email ?? "unknown")")
        } catch {
            isAuthenticated = false
            DebugLogger.info("No active session found")
        }
    }

    private func observeAuthStateChanges() {
        authStateTask = Task {
            for await state in supabase.auth.authStateChanges {
                switch state.event {
                case .signedIn:
                    // Don't auto-authenticate during password reset flow
                    if !self.isResettingPassword {
                        self.isAuthenticated = true
                        DebugLogger.success("User signed in: \(state.session?.user.email ?? "unknown")")
                    } else {
                        DebugLogger.info("Sign in event ignored - password reset in progress")
                    }

                case .signedOut:
                    self.isAuthenticated = false
                    self.currentUser = nil
                    DebugLogger.info("User signed out")

                case .initialSession:
                    // Don't auto-authenticate during password reset flow
                    if state.session != nil && !self.isResettingPassword {
                        self.isAuthenticated = true
                        DebugLogger.success("Initial session loaded")
                    } else if self.isResettingPassword {
                        DebugLogger.info("Initial session ignored - password reset in progress")
                    }

                default:
                    break
                }
            }
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return false
        }

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return false
        }

        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return false
        }

        do {
            // Step 1: Create auth user in Supabase Auth
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )

            DebugLogger.success("Auth user created for: \(email)")

            // Step 2: Create customer profile in customers table
            if let session = response.session {
                let userId = session.user.id

                do {
                    try await SupabaseManager.shared.createCustomerProfile(
                        authUserId: userId,
                        email: email,
                        firstName: nil,
                        lastName: nil,
                        phoneNumber: nil
                    )
                    DebugLogger.success("Customer profile created in customers table")
                } catch {
                    DebugLogger.warning("Auth user created but customer profile failed: \(error)")
                    // Continue anyway - the user is authenticated
                    // The profile can be created later or fixed manually
                }

                isAuthenticated = true
                return true
            } else {
                errorMessage = "Please check your email to confirm your account"
                return false
            }
        } catch {
            errorMessage = "Sign up failed: \(error.localizedDescription)"
            DebugLogger.error("Sign up error", error)
            return false
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return false
        }

        // SECURITY: Check if account is locked (rate limiting)
        do {
            let lockoutResult: [LockoutCheckResponse] = try await supabase
                .rpc("check_account_lockout", params: ["p_email": email])
                .execute()
                .value

            if let lockout = lockoutResult.first, lockout.isLocked {
                if let lockoutUntil = lockout.lockoutUntil {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let lockoutDate = formatter.date(from: lockoutUntil) {
                        let minutesRemaining = Int(ceil(lockoutDate.timeIntervalSinceNow / 60))
                        if minutesRemaining > 0 {
                            errorMessage = "Account temporarily locked. Try again in \(minutesRemaining) minute\(minutesRemaining != 1 ? "s" : "")."
                            return false
                        }
                    }
                }
                errorMessage = "Account temporarily locked. Please try again later."
                return false
            }
        } catch {
            // SECURITY: Fail closed - if rate limiting check fails, block login
            DebugLogger.error("Rate limiting check failed", error)
            errorMessage = "Unable to verify account status. Please try again."
            return false
        }

        // Attempt sign in
        var signInSuccess = false
        do {
            _ = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            isAuthenticated = true
            signInSuccess = true
            DebugLogger.success("Sign in successful for: \(email)")
        } catch {
            errorMessage = "Invalid email or password"
            DebugLogger.error("Sign in error", error)
        }

        // SECURITY: Record login attempt (non-blocking)
        do {
            try await supabase
                .rpc("record_login_attempt", params: LoginAttemptParams(p_email: email, p_success: signInSuccess))
                .execute()
        } catch {
            DebugLogger.error("Failed to record login attempt", error)
        }

        return signInSuccess
    }

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
        try await supabase.auth.resetPasswordForEmail(email)
        DebugLogger.success("Password reset OTP sent to: \(email)")
    }

    /// Verify the OTP code for password reset
    /// Note: We set isResettingPassword flag to prevent auto-navigation during this flow
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
            DebugLogger.error("OTP verification error", error)
            throw NSError(domain: "AuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid or expired code"])
        }
    }

    /// Legacy method for Universal Link flow (kept for backward compatibility)
    func sendPasswordReset(email: String) async throws {
        guard !email.isEmpty else {
            throw NSError(domain: "AuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter your email address"])
        }

        guard isValidEmail(email) else {
            throw NSError(domain: "AuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address"])
        }

        // Use Universal Link to redirect back to the app via knockbites.com
        try await supabase.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "https://knockbites.com/reset-password")
        )
        DebugLogger.success("Password reset email sent to: \(email)")
    }

    // MARK: - Update Password

    func updatePassword(newPassword: String) async throws {
        guard newPassword.count >= 8 else {
            throw NSError(domain: "AuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 8 characters"])
        }

        do {
            try await supabase.auth.update(user: .init(password: newPassword))
            DebugLogger.success("Password updated successfully")

            // Clear the password reset flag
            isResettingPassword = false

            // SECURITY: Sign out after password reset so user must log in with new password
            // This matches iOS Business behavior and ensures session is properly invalidated
            try await supabase.auth.signOut()
            isAuthenticated = false
            currentUser = nil
            DebugLogger.success("Signed out after password reset - please log in with new password")
        } catch {
            isResettingPassword = false
            DebugLogger.error("Password update error", error)
            throw NSError(domain: "AuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to update password. Please try again."])
        }
    }

    // MARK: - Handle Deep Link

    func handleDeepLink(url: URL) async -> Bool {
        DebugLogger.log("DeepLink", "Handling deep link: \(url)")

        // Extract tokens from URL query parameters
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        var accessToken: String?
        var refreshToken: String?

        for item in queryItems {
            if item.name == "access_token" {
                accessToken = item.value
            } else if item.name == "refresh_token" {
                refreshToken = item.value
            }
        }

        // Also check fragment (hash) for tokens
        if let fragment = components?.fragment {
            let fragmentItems = fragment.split(separator: "&")
            for item in fragmentItems {
                let parts = item.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    let key = String(parts[0])
                    let value = String(parts[1])
                    if key == "access_token" {
                        accessToken = value
                    } else if key == "refresh_token" {
                        refreshToken = value
                    }
                }
            }
        }

        DebugLogger.log("DeepLink", "Access token: \(accessToken != nil ? "found" : "not found")")
        DebugLogger.log("DeepLink", "Refresh token: \(refreshToken != nil ? "found" : "not found")")

        // If we have tokens, set the session manually
        if let accessToken = accessToken {
            do {
                try await supabase.auth.setSession(accessToken: accessToken, refreshToken: refreshToken ?? "")
                DebugLogger.success("Session set from tokens")
                isAuthenticated = true
                return true
            } catch {
                DebugLogger.error("Failed to set session", error)
            }
        }

        // Fallback: try Supabase's built-in URL handling
        do {
            _ = try await supabase.auth.session(from: url)
            DebugLogger.success("Session restored from deep link URL")
            return true
        } catch {
            DebugLogger.error("Deep link handling error", error)
            return false
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signOut()
            isAuthenticated = false
            currentUser = nil
            DebugLogger.success("User signed out successfully")
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            DebugLogger.error("Sign out error", error)
        }
    }

    // MARK: - Helper Methods

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    deinit {
        authStateTask?.cancel()
    }
}
