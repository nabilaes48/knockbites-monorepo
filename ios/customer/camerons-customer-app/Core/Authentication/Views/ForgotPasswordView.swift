//
//  ForgotPasswordView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var showSuccessMessage = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.brandPrimary)

                            Text("Forgot Password?")
                                .font(AppFonts.largeTitle)
                                .foregroundColor(.textPrimary)

                            Text("Enter your email address and we'll send you a link to reset your password")
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.xl)
                        }
                        .padding(.top, Spacing.xxl)

                        if showSuccessMessage {
                            // Success Message
                            VStack(spacing: Spacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.success)

                                VStack(spacing: Spacing.sm) {
                                    Text("Check Your Email")
                                        .font(AppFonts.title2)
                                        .foregroundColor(.textPrimary)

                                    Text("We've sent a password reset link to \(email)")
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
                                title: "Back to Login",
                                action: { dismiss() },
                                style: .primary
                            )
                            .padding(.horizontal, Spacing.xl)
                        } else {
                            // Email Form
                            VStack(spacing: Spacing.lg) {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("Email")
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(.textSecondary)

                                    HStack {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(.textSecondary)

                                        TextField("you@example.com", text: $email)
                                            .textContentType(.emailAddress)
                                            .autocapitalization(.none)
                                            .keyboardType(.emailAddress)
                                    }
                                    .padding()
                                    .background(Color.surface)
                                    .cornerRadius(CornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .stroke(Color.border, lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal, Spacing.xl)

                            // Error Message
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(AppFonts.subheadline)
                                    .foregroundColor(.error)
                                    .padding(.horizontal, Spacing.xl)
                            }

                            // Send Reset Link Button
                            CustomButton(
                                title: "Send Reset Link",
                                action: { Task { await handlePasswordReset() } },
                                style: .primary,
                                isLoading: isLoading,
                                isDisabled: !isFormValid,
                                icon: "paperplane.fill"
                            )
                            .padding(.horizontal, Spacing.xl)

                            // Back to Login
                            Button("Back to Login") {
                                dismiss()
                            }
                            .font(AppFonts.body)
                            .foregroundColor(.brandPrimary)
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

    var isFormValid: Bool {
        !email.isEmpty
    }

    func handlePasswordReset() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authManager.sendPasswordReset(email: email)
            withAnimation {
                showSuccessMessage = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    ForgotPasswordView()
}
