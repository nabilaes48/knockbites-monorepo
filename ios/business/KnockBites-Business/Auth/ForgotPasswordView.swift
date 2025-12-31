//
//  ForgotPasswordView.swift
//  KnockBites-Business
//
//  Created by Claude Code on 12/31/25.
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

    // Rate limiting for resend button
    @State private var resendCooldownSeconds: Int = 0
    @State private var resendAttempts: Int = 0
    @State private var resendTimer: Timer? = nil

    enum ResetStep {
        case email
        case otp
        case newPassword
        case success
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient (matching StaffLoginView)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.brandPrimary.opacity(0.1),
                        Color.surface
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onDisappear {
                // If user closes without completing password reset, clean up
                if authManager.isResettingPassword {
                    authManager.isResettingPassword = false
                    // Sign out to clear the session created during OTP verification
                    Task {
                        await authManager.signOut()
                        DebugLogger.info("Signed out - password reset was not completed")
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
        case .otp: return "Enter the 8-digit code we sent to \(email)"
        case .newPassword: return "Create a new password for your account"
        case .success: return "Your password has been reset successfully"
        }
    }

    // MARK: - Step Views

    var emailStepView: some View {
        VStack(spacing: Spacing.lg) {
            // Email Form
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Email")
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.textSecondary)
                        .frame(width: 20)

                    TextField("you@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                .padding()
                .background(Color.surfaceSecondary)
                .cornerRadius(CornerRadius.md)
            }
            .padding(.horizontal, Spacing.xl)

            // Error Message
            if let errorMessage = errorMessage {
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
                .padding(.horizontal, Spacing.xl)
            }

            // Send Code Button
            Button(action: { Task { await handleSendCode() } }) {
                HStack(spacing: Spacing.sm) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Send Reset Code")
                    }
                }
                .font(AppFonts.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(email.isEmpty ? Color.textSecondary.opacity(0.5) : Color.brandPrimary)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(email.isEmpty || isLoading)
            .padding(.horizontal, Spacing.xl)

            // I already have a code
            Button("I already have a code") {
                guard !email.isEmpty else {
                    errorMessage = "Please enter your email first"
                    return
                }
                withAnimation {
                    currentStep = .otp
                    errorMessage = nil
                }
            }
            .font(AppFonts.subheadline)
            .foregroundColor(.brandPrimary)

            // Back to Login
            Button("Back to Login") {
                dismiss()
            }
            .font(AppFonts.body)
            .foregroundColor(.textSecondary)
        }
    }

    var otpStepView: some View {
        VStack(spacing: Spacing.lg) {
            // OTP Input
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Verification Code")
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)

                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.textSecondary)
                        .frame(width: 20)

                    TextField("00000000", text: $otpCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .onChange(of: otpCode) { _, newValue in
                            // Limit to 8 digits
                            if newValue.count > 8 {
                                otpCode = String(newValue.prefix(8))
                            }
                            // Only allow numbers
                            otpCode = newValue.filter { $0.isNumber }
                        }
                }
                .padding()
                .background(Color.surfaceSecondary)
                .cornerRadius(CornerRadius.md)
            }
            .padding(.horizontal, Spacing.xl)

            // Error Message
            if let errorMessage = errorMessage {
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
                .padding(.horizontal, Spacing.xl)
            }

            // Verify Button
            Button(action: { Task { await handleVerifyOTP() } }) {
                HStack(spacing: Spacing.sm) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Verify Code")
                    }
                }
                .font(AppFonts.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(otpCode.count != 8 ? Color.textSecondary.opacity(0.5) : Color.brandPrimary)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(otpCode.count != 8 || isLoading)
            .padding(.horizontal, Spacing.xl)

            // Resend Code with rate limiting
            if resendCooldownSeconds > 0 {
                Text("Resend available in \(resendCooldownSeconds)s")
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            } else {
                Button("Didn't receive a code? Send again") {
                    Task { await handleResendCode() }
                }
                .font(AppFonts.subheadline)
                .foregroundColor(.brandPrimary)
            }

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
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.textSecondary)
                        .frame(width: 20)

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
                .background(Color.surfaceSecondary)
                .cornerRadius(CornerRadius.md)
            }
            .padding(.horizontal, Spacing.xl)

            // Confirm Password Field
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Confirm Password")
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.textSecondary)
                        .frame(width: 20)

                    if showPassword {
                        TextField("Confirm new password", text: $confirmPassword)
                    } else {
                        SecureField("Confirm new password", text: $confirmPassword)
                    }
                }
                .padding()
                .background(Color.surfaceSecondary)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(!confirmPassword.isEmpty && !passwordsMatch ? Color.error : Color.clear, lineWidth: 1)
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

                HStack(spacing: Spacing.sm) {
                    Image(systemName: newPassword.count >= 8 ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                        .foregroundColor(newPassword.count >= 8 ? .success : .textSecondary)

                    Text("Be at least 8 characters")
                        .font(AppFonts.caption)
                        .foregroundColor(newPassword.count >= 8 ? .success : .textSecondary)
                }
            }
            .padding(.horizontal, Spacing.xl)

            // Error Message
            if let errorMessage = errorMessage {
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
                .padding(.horizontal, Spacing.xl)
            }

            // Update Password Button
            Button(action: { Task { await handleUpdatePassword() } }) {
                HStack(spacing: Spacing.sm) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Update Password")
                    }
                }
                .font(AppFonts.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(!isPasswordFormValid ? Color.textSecondary.opacity(0.5) : Color.brandPrimary)
                .cornerRadius(CornerRadius.md)
            }
            .disabled(!isPasswordFormValid || isLoading)
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

            Button(action: { dismiss() }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "person.badge.key.fill")
                    Text("Back to Login")
                }
                .font(AppFonts.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.brandPrimary)
                .cornerRadius(CornerRadius.md)
            }
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

    func handleResendCode() async {
        // Send the code
        await handleSendCode()

        // Only start cooldown if the send was successful (no error)
        if errorMessage == nil {
            resendAttempts += 1

            // Exponential backoff: 30s, 60s, 120s, max 300s (5 min)
            let baseCooldown = 30
            let cooldown = min(baseCooldown * (1 << (resendAttempts - 1)), 300)
            resendCooldownSeconds = cooldown

            // Start countdown timer
            resendTimer?.invalidate()
            resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if resendCooldownSeconds > 0 {
                    resendCooldownSeconds -= 1
                } else {
                    timer.invalidate()
                    resendTimer = nil
                }
            }
        }
    }

    func handleVerifyOTP() async {
        guard otpCode.count == 8 else {
            errorMessage = "Please enter the 8-digit code"
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

#Preview {
    ForgotPasswordView()
}
