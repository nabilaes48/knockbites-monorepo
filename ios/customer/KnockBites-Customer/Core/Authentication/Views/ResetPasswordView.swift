//
//  ResetPasswordView.swift
//  KnockBites-Customer
//
//  Created by Claude Code on 12/13/25.
//

import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 80))
                                .foregroundColor(.brandPrimary)

                            Text("Reset Password")
                                .font(AppFonts.largeTitle)
                                .foregroundColor(.textPrimary)

                            Text("Enter your new password below")
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, Spacing.xxl)

                        if showSuccess {
                            // Success Message
                            VStack(spacing: Spacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.success)

                                VStack(spacing: Spacing.sm) {
                                    Text("Password Updated!")
                                        .font(AppFonts.title2)
                                        .foregroundColor(.textPrimary)

                                    Text("Your password has been successfully reset. You can now sign in with your new password.")
                                        .font(AppFonts.body)
                                        .foregroundColor(.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(Spacing.xl)
                            .background(Color.success.opacity(0.1))
                            .cornerRadius(CornerRadius.lg)
                            .padding(.horizontal, Spacing.xl)

                            CustomButton(
                                title: "Sign In",
                                action: { dismiss() },
                                style: .primary
                            )
                            .padding(.horizontal, Spacing.xl)
                        } else {
                            // Password Form
                            VStack(spacing: Spacing.lg) {
                                // New Password Field
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("New Password")
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(.textSecondary)

                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.textSecondary)

                                        if showPassword {
                                            TextField("Enter new password", text: $newPassword)
                                        } else {
                                            SecureField("Enter new password", text: $newPassword)
                                        }

                                        Button(action: { showPassword.toggle() }) {
                                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(.textSecondary)
                                        }
                                    }
                                    .padding()
                                    .background(Color.surface)
                                    .cornerRadius(CornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .stroke(Color.border, lineWidth: 1)
                                    )
                                }

                                // Confirm Password Field
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("Confirm Password")
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(.textSecondary)

                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.textSecondary)

                                        if showPassword {
                                            TextField("Confirm new password", text: $confirmPassword)
                                        } else {
                                            SecureField("Confirm new password", text: $confirmPassword)
                                        }
                                    }
                                    .padding()
                                    .background(Color.surface)
                                    .cornerRadius(CornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .stroke(passwordsMatch ? Color.border : Color.error, lineWidth: 1)
                                    )

                                    if !confirmPassword.isEmpty && !passwordsMatch {
                                        Text("Passwords do not match")
                                            .font(AppFonts.caption)
                                            .foregroundColor(.error)
                                    }
                                }

                                // Password Requirements
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Password must:")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.textSecondary)

                                    PasswordRequirement(
                                        text: "Be at least 6 characters",
                                        isMet: newPassword.count >= 6
                                    )
                                }
                                .padding(.top, Spacing.sm)
                            }
                            .padding(.horizontal, Spacing.xl)

                            // Error Message
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(AppFonts.subheadline)
                                    .foregroundColor(.error)
                                    .padding(.horizontal, Spacing.xl)
                            }

                            // Reset Password Button
                            CustomButton(
                                title: "Update Password",
                                action: { Task { await handlePasswordUpdate() } },
                                style: .primary,
                                isLoading: isLoading,
                                isDisabled: !isFormValid,
                                icon: "checkmark.shield.fill"
                            )
                            .padding(.horizontal, Spacing.xl)

                            // Cancel Button
                            Button("Cancel") {
                                dismiss()
                            }
                            .font(AppFonts.body)
                            .foregroundColor(.textSecondary)
                        }

                        Spacer()
                    }
                }
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    var passwordsMatch: Bool {
        confirmPassword.isEmpty || newPassword == confirmPassword
    }

    var isFormValid: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    func handlePasswordUpdate() async {
        guard isFormValid else {
            errorMessage = "Please fix the errors above"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authManager.updatePassword(newPassword: newPassword)
            withAnimation {
                showSuccess = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Password Requirement Row
struct PasswordRequirement: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundColor(isMet ? .success : .textSecondary)

            Text(text)
                .font(AppFonts.caption)
                .foregroundColor(isMet ? .success : .textSecondary)
        }
    }
}

#Preview {
    ResetPasswordView()
}
