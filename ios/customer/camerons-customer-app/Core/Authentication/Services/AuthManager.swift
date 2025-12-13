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

        try await supabase.auth.resetPasswordForEmail(email)
        print("✅ Password reset email sent to: \(email)")
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
