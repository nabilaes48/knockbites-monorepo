//
//  LoginView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showForgotPassword = false
    @State private var showSignUp = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Logo/Header
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.brandPrimary)

                            Text("Welcome Back!")
                                .font(AppFonts.largeTitle)
                                .foregroundColor(.textPrimary)

                            Text("Sign in to continue ordering")
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, Spacing.xxl)

                        // Form
                        VStack(spacing: Spacing.lg) {
                            // Email Field
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

                            // Password Field
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Password")
                                    .font(AppFonts.subheadline)
                                    .foregroundColor(.textSecondary)

                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.textSecondary)

                                    if showPassword {
                                        TextField("Enter your password", text: $password)
                                    } else {
                                        SecureField("Enter your password", text: $password)
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

                            // Forgot Password
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .font(AppFonts.subheadline)
                                .foregroundColor(.brandPrimary)
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

                        // Sign In Button
                        CustomButton(
                            title: "Sign In",
                            action: { Task { await handleSignIn() } },
                            style: .primary,
                            isLoading: authManager.isLoading,
                            isDisabled: !isFormValid
                        )
                        .padding(.horizontal, Spacing.xl)

                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)

                            Button("Sign Up") {
                                showSignUp = true
                            }
                            .font(AppFonts.headline)
                            .foregroundColor(.brandPrimary)
                        }
                        .padding(.horizontal, Spacing.xl)

                        Spacer()
                    }
                }
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }

    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    func handleSignIn() async {
        let success = await authManager.signIn(email: email, password: password)
        if success {
            // Auth state will be updated automatically via authStateChanges
            print("✅ Login successful")
        }
    }
}

#Preview {
    LoginView()
}
