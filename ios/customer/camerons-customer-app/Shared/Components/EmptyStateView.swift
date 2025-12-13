//
//  EmptyStateView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.textSecondary)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(AppFonts.title2)
                    .foregroundColor(.textPrimary)

                Text(message)
                    .font(AppFonts.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            if let actionTitle = actionTitle, let action = action {
                CustomButton(title: actionTitle, action: action, style: .primary)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.md)
            }
        }
        .padding()
    }
}

#Preview {
    EmptyStateView(
        icon: "cart",
        title: "Your Cart is Empty",
        message: "Add some delicious items to get started!",
        actionTitle: "Browse Menu",
        action: {}
    )
}
