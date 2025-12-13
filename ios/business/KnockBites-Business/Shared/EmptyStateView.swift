//
//  EmptyStateView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code - Shared Empty State Component
//

import SwiftUI

/// A reusable empty state view for displaying when no content is available.
/// Use this throughout the app for consistent empty state messaging.
struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil
    var showBackground: Bool = true

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.textSecondary)

            Text(title)
                .font(AppFonts.title3)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            if let message = message {
                Text(message)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl * 2)
        .frame(maxWidth: .infinity)
        .background(showBackground ? Color.surface : Color.clear)
        .cornerRadius(showBackground ? CornerRadius.md : 0)
    }
}

#Preview("With Background") {
    EmptyStateView(
        icon: "person.2.slash",
        title: "No Customers Found",
        message: "Customers will appear here once they join the loyalty program"
    )
    .padding()
    .background(Color.surfaceSecondary)
}

#Preview("Without Background") {
    EmptyStateView(
        icon: "megaphone",
        title: "No Active Campaigns",
        message: "Create your first marketing campaign",
        showBackground: false
    )
    .padding()
}
