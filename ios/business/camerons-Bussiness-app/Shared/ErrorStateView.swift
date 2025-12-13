//
//  ErrorStateView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code - Shared Error State Component
//

import SwiftUI

/// A reusable error state view for displaying error messages.
/// Supports both full-screen and inline banner styles.
struct ErrorStateView: View {
    let message: String
    var title: String = "Error"
    var style: ErrorStyle = .fullScreen
    var onRetry: (() -> Void)? = nil

    enum ErrorStyle {
        case fullScreen
        case banner
    }

    var body: some View {
        switch style {
        case .fullScreen:
            fullScreenView
        case .banner:
            bannerView
        }
    }

    private var fullScreenView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.error)

            Text(title)
                .font(AppFonts.title3)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text(message)
                .font(AppFonts.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            if let onRetry = onRetry {
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(AppFonts.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.brandPrimary)
                    .cornerRadius(CornerRadius.md)
                }
                .padding(.top, Spacing.md)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bannerView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.error)

            Text(message)
                .font(AppFonts.subheadline)
                .foregroundColor(.error)

            Spacer()

            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.error)
                }
            }
        }
        .padding()
        .background(Color.error.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}

#Preview("Full Screen Error") {
    ErrorStateView(
        message: "Failed to load data. Please check your connection.",
        onRetry: { print("Retry tapped") }
    )
}

#Preview("Banner Error") {
    VStack {
        ErrorStateView(
            message: "Failed to load campaigns",
            style: .banner,
            onRetry: { print("Retry tapped") }
        )
        .padding()

        Spacer()
    }
}
