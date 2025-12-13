//
//  ErrorView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let icon: String
    var retryAction: (() -> Void)?
    var dismissAction: (() -> Void)?

    init(
        title: String = "Something Went Wrong",
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.retryAction = retryAction
        self.dismissAction = dismissAction
    }

    // Convenience initializer for simple error messages
    init(error: String, retryAction: (() -> Void)? = nil) {
        self.title = "Something Went Wrong"
        self.message = error
        self.icon = "exclamationmark.triangle.fill"
        self.retryAction = retryAction
        self.dismissAction = nil
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.error)
                .symbolEffect(.bounce, value: title)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(AppFonts.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text(message)
                    .font(AppFonts.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            VStack(spacing: Spacing.sm) {
                if let retryAction = retryAction {
                    CustomButton(
                        title: "Try Again",
                        action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                retryAction()
                            }
                        },
                        style: .primary,
                        icon: "arrow.clockwise"
                    )
                    .padding(.horizontal, Spacing.xl)
                }

                if let dismissAction = dismissAction {
                    Button(action: dismissAction) {
                        Text("Dismiss")
                            .font(AppFonts.body)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ErrorView(
        error: "Something went wrong. Please try again.",
        retryAction: {}
    )
}
