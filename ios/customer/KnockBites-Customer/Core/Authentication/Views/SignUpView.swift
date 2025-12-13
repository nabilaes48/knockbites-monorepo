//
//  SignUpView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.brandPrimary)

                            Text("Create Account")
                                .font(AppFonts.largeTitle)
                                .foregroundColor(.textPrimary)

                            Text("Join us and start ordering!")
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, Spacing.xl)

                        // Form
                        VStack(spacing: Spacing.lg) {
                            // Email
                            InputField(
                                label: "Email",
                                placeholder: "you@example.com",
                                icon: "envelope.fill",
                                text: $email,
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress
                            )

                            // Password
                            PasswordInputField(
                                label: "Password",
                                placeholder: "At least 6 characters",
                                text: $password,
                                showPassword: $showPassword
                            )

                            // Confirm Password
                            PasswordInputField(
                                label: "Confirm Password",
                                placeholder: "Re-enter your password",
                                text: $confirmPassword,
                                showPassword: $showConfirmPassword
                            )

                            // Password Match Indicator
                            if !password.isEmpty && !confirmPassword.isEmpty {
                                HStack {
                                    Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(passwordsMatch ? .success : .error)
                                    Text(passwordsMatch ? "Passwords match" : "Passwords don't match")
                                        .font(AppFonts.caption)
                                        .foregroundColor(passwordsMatch ? .success : .error)
                                }
                            }

                            // Terms and Conditions
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Button(action: { agreedToTerms.toggle() }) {
                                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                        .foregroundColor(agreedToTerms ? .brandPrimary : .textSecondary)
                                        .font(.title3)
                                }

                                Text("I agree to the Terms of Service and Privacy Policy")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, Spacing.xl)

                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(AppFonts.subheadline)
                                .foregroundColor(.error)
                                .padding(.horizontal, Spacing.xl)
                        }

                        // Sign Up Button
                        CustomButton(
                            title: "Create Account",
                            action: { Task { await handleSignUp() } },
                            style: .primary,
                            isLoading: authManager.isLoading,
                            isDisabled: !isFormValid
                        )
                        .padding(.horizontal, Spacing.xl)

                        // Sign In Link
                        HStack {
                            Text("Already have an account?")
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)

                            Button("Sign In") {
                                dismiss()
                            }
                            .font(AppFonts.headline)
                            .foregroundColor(.brandPrimary)
                        }
                        .padding(.bottom, Spacing.xl)
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
        password == confirmPassword && !password.isEmpty
    }

    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        passwordsMatch &&
        agreedToTerms &&
        password.count >= 6
    }

    func handleSignUp() async {
        let success = await authManager.signUp(email: email, password: password)
        if success {
            // Auth state will be updated automatically via authStateChanges
            print("✅ Sign up successful")
        }
    }
}

// MARK: - Input Field Component
struct InputField: View {
    let label: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(.textSecondary)

                TextField(placeholder, text: $text)
                    .textContentType(textContentType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .keyboardType(keyboardType)
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
}

// MARK: - Password Input Field Component
struct PasswordInputField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)

            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.textSecondary)

                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
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
    }
}

#Preview {
    SignUpView()
}
