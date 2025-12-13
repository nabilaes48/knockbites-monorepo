//
//  StaffLoginView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct StaffLoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showingError: Bool = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.brandPrimary.opacity(0.1),
                    Color.surface
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Logo and title
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.brandPrimary)

                    Text("KnockBites Connect")
                        .font(AppFonts.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("Business Portal")
                        .font(AppFonts.title3)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Login form
                VStack(spacing: Spacing.lg) {
                    // Email field
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Email")
                            .font(AppFonts.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.textSecondary)
                                .frame(width: 20)

                            TextField("admin@knockbitesconnect.com", text: $email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disabled(authManager.isLoading)
                        }
                        .padding()
                        .background(Color.surfaceSecondary)
                        .cornerRadius(CornerRadius.md)
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Password")
                            .font(AppFonts.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.textSecondary)
                                .frame(width: 20)

                            if showPassword {
                                TextField("Enter password", text: $password)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .disabled(authManager.isLoading)
                            } else {
                                SecureField("Enter password", text: $password)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .disabled(authManager.isLoading)
                            }

                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding()
                        .background(Color.surfaceSecondary)
                        .cornerRadius(CornerRadius.md)
                    }

                    // Sign in button
                    Button(action: handleSignIn) {
                        HStack(spacing: Spacing.sm) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "person.badge.key.fill")
                                Text("Sign In")
                            }
                        }
                        .font(AppFonts.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            canSignIn ? Color.brandPrimary : Color.textSecondary.opacity(0.5)
                        )
                        .cornerRadius(CornerRadius.md)
                    }
                    .disabled(!canSignIn || authManager.isLoading)

                    // Error message
                    if let errorMessage = authManager.errorMessage {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                                .font(AppFonts.caption)
                        }
                        .foregroundColor(.error)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.error.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                    }

                    // Role badge (shown after successful login, before navigation)
                    if authManager.isAuthenticated, let profile = authManager.userProfile {
                        VStack(spacing: Spacing.md) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.success)
                                Text("Welcome back, \(profile.fullName)!")
                                    .font(AppFonts.subheadline)
                                    .fontWeight(.medium)
                            }

                            HStack(spacing: Spacing.sm) {
                                Text(profile.role.displayName)
                                    .font(AppFonts.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .background(profile.role.badgeColor)
                                    .cornerRadius(CornerRadius.sm)

                                Text("•")
                                    .foregroundColor(.textSecondary)

                                Text("\(profile.permissions.count) permissions")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.success.opacity(0.1))
                        .cornerRadius(CornerRadius.md)
                    }
                }
                .padding(.horizontal, Spacing.xl)

                Spacer()

                // Footer
                VStack(spacing: Spacing.sm) {
                    Text("Staff accounts are managed by administrators")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("Need help? Contact your store manager")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, Spacing.xl)
            }
        }
        .onAppear {
            // Pre-fill credentials for testing
            #if DEBUG
            if email.isEmpty {
                email = "admin@knockbitesconnect.com"
                password = "admin123"
            }
            #endif
        }
    }

    // MARK: - Computed Properties

    private var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty
    }

    // MARK: - Actions

    private func handleSignIn() {
        // Clear keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        authManager.clearError()

        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                // Error is already set in authManager
                showingError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StaffLoginView()
}
