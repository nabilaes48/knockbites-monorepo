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

        do {
            let session = try await supabase.auth.session
            isAuthenticated = true
            print("✅ Active session found for user: \(session.user.email ?? "unknown")")
        } catch {
            isAuthenticated = false
            print("ℹ️ No active session found")
        }
    }

    private func observeAuthStateChanges() {
        authStateTask = Task {
            for await state in supabase.auth.authStateChanges {
                switch state.event {
                case .signedIn:
                    self.isAuthenticated = true
                    print("✅ User signed in: \(state.session?.user.email ?? "unknown")")

                case .signedOut:
                    self.isAuthenticated = false
                    self.currentUser = nil
                    print("ℹ️ User signed out")

                case .initialSession:
                    if state.session != nil {
                        self.isAuthenticated = true
                        print("✅ Initial session loaded")
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

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }

        do {
            // Step 1: Create auth user in Supabase Auth
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )

            print("✅ Auth user created for: \(email)")

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
                    print("✅ Customer profile created in customers table")
                } catch {
                    print("⚠️ Auth user created but customer profile failed: \(error)")
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
            print("❌ Sign up error: \(error)")
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

        do {
            _ = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            isAuthenticated = true
            print("✅ Sign in successful for: \(email)")
            return true
        } catch {
            errorMessage = "Invalid email or password"
            print("❌ Sign in error: \(error)")
            return false
        }
    }

    // MARK: - Password Reset

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
        print("✅ Password reset email sent to: \(email)")
    }

    // MARK: - Update Password

    func updatePassword(newPassword: String) async throws {
        guard newPassword.count >= 6 else {
            throw NSError(domain: "AuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters"])
        }

        do {
            try await supabase.auth.update(user: .init(password: newPassword))
            print("✅ Password updated successfully")
        } catch {
            print("❌ Password update error: \(error)")
            throw NSError(domain: "AuthManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to update password. Please try again."])
        }
    }

    // MARK: - Handle Deep Link

    func handleDeepLink(url: URL) async -> Bool {
        print("🔗 Handling deep link: \(url)")

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

        print("   Access token: \(accessToken != nil ? "found" : "not found")")
        print("   Refresh token: \(refreshToken != nil ? "found" : "not found")")

        // If we have tokens, set the session manually
        if let accessToken = accessToken {
            do {
                try await supabase.auth.setSession(accessToken: accessToken, refreshToken: refreshToken ?? "")
                print("✅ Session set from tokens")
                isAuthenticated = true
                return true
            } catch {
                print("❌ Failed to set session: \(error)")
            }
        }

        // Fallback: try Supabase's built-in URL handling
        do {
            _ = try await supabase.auth.session(from: url)
            print("✅ Session restored from deep link URL")
            return true
        } catch {
            print("❌ Deep link handling error: \(error)")
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
            print("✅ User signed out successfully")
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            print("❌ Sign out error: \(error)")
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
