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
    @State private var otpCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var currentStep: ResetStep = .email
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum ResetStep {
        case email
        case otp
        case newPassword
        case success
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        VStack(spacing: Spacing.md) {
                            Image(systemName: headerIcon)
                                .font(.system(size: 80))
                                .foregroundColor(.brandPrimary)

                            Text(headerTitle)
                                .font(AppFonts.largeTitle)
                                .foregroundColor(.textPrimary)

                            Text(headerSubtitle)
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.xl)
                        }
                        .padding(.top, Spacing.xxl)

                        switch currentStep {
                        case .email:
                            emailStepView
                        case .otp:
                            otpStepView
                        case .newPassword:
                            newPasswordStepView
                        case .success:
                            successView
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

    // MARK: - Header Properties

    var headerIcon: String {
        switch currentStep {
        case .email: return "key.fill"
        case .otp: return "number.circle.fill"
        case .newPassword: return "lock.rotation"
        case .success: return "checkmark.circle.fill"
        }
    }

    var headerTitle: String {
        switch currentStep {
        case .email: return "Forgot Password?"
        case .otp: return "Enter Code"
        case .newPassword: return "New Password"
        case .success: return "Success!"
        }
    }

    var headerSubtitle: String {
        switch currentStep {
        case .email: return "Enter your email address and we'll send you a code to reset your password"
        case .otp: return "Enter the 6-digit code we sent to \(email)"
        case .newPassword: return "Create a new password for your account"
        case .success: return "Your password has been reset successfully"
        }
    }

    // MARK: - Step Views

    var emailStepView: some View {
        VStack(spacing: Spacing.lg) {
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

            // Send Code Button
            CustomButton(
                title: "Send Reset Code",
                action: { Task { await handleSendCode() } },
                style: .primary,
                isLoading: isLoading,
                isDisabled: email.isEmpty,
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
    }

    var otpStepView: some View {
        VStack(spacing: Spacing.lg) {
            // OTP Input
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Verification Code")
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)

                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.textSecondary)

                    TextField("000000", text: $otpCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .onChange(of: otpCode) { _, newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                otpCode = String(newValue.prefix(6))
                            }
                            // Only allow numbers
                            otpCode = newValue.filter { $0.isNumber }
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
            .padding(.horizontal, Spacing.xl)

            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.error)
                    .padding(.horizontal, Spacing.xl)
            }

            // Verify Button
            CustomButton(
                title: "Verify Code",
                action: { Task { await handleVerifyOTP() } },
                style: .primary,
                isLoading: isLoading,
                isDisabled: otpCode.count != 6,
                icon: "checkmark.shield.fill"
            )
            .padding(.horizontal, Spacing.xl)

            // Resend Code
            Button("Didn't receive a code? Send again") {
                Task { await handleSendCode() }
            }
            .font(AppFonts.subheadline)
            .foregroundColor(.brandPrimary)

            // Back Button
            Button("Use different email") {
                withAnimation {
                    currentStep = .email
                    otpCode = ""
                    errorMessage = nil
                }
            }
            .font(AppFonts.body)
            .foregroundColor(.textSecondary)
        }
    }

    var newPasswordStepView: some View {
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
            .padding(.horizontal, Spacing.xl)

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
            .padding(.horizontal, Spacing.xl)

            // Password Requirements
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Password must:")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)

                PasswordRequirementRow(
                    text: "Be at least 8 characters",
                    isMet: newPassword.count >= 8
                )
            }
            .padding(.horizontal, Spacing.xl)

            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.error)
                    .padding(.horizontal, Spacing.xl)
            }

            // Update Password Button
            CustomButton(
                title: "Update Password",
                action: { Task { await handleUpdatePassword() } },
                style: .primary,
                isLoading: isLoading,
                isDisabled: !isPasswordFormValid,
                icon: "checkmark.shield.fill"
            )
            .padding(.horizontal, Spacing.xl)
        }
    }

    var successView: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.success)

                VStack(spacing: Spacing.sm) {
                    Text("Password Updated!")
                        .font(AppFonts.title2)
                        .foregroundColor(.textPrimary)

                    Text("You can now sign in with your new password.")
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
        }
    }

    // MARK: - Computed Properties

    var passwordsMatch: Bool {
        confirmPassword.isEmpty || newPassword == confirmPassword
    }

    var isPasswordFormValid: Bool {
        newPassword.count >= 8 && newPassword == confirmPassword
    }

    // MARK: - Actions

    func handleSendCode() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authManager.sendPasswordResetOTP(email: email)
            withAnimation {
                currentStep = .otp
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func handleVerifyOTP() async {
        guard otpCode.count == 6 else {
            errorMessage = "Please enter the 6-digit code"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authManager.verifyPasswordResetOTP(email: email, token: otpCode)
            withAnimation {
                currentStep = .newPassword
            }
        } catch {
            errorMessage = "Invalid or expired code. Please try again."
        }

        isLoading = false
    }

    func handleUpdatePassword() async {
        guard isPasswordFormValid else {
            errorMessage = "Please fix the errors above"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authManager.updatePassword(newPassword: newPassword)
            withAnimation {
                currentStep = .success
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Password Requirement Row
struct PasswordRequirementRow: View {
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
    ForgotPasswordView()
}
