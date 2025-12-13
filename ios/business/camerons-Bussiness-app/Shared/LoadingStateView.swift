//
//  LoadingStateView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code - Shared Loading State Component
//

import SwiftUI

/// A reusable loading state view for consistent loading indicators.
/// Use this throughout the app for consistent loading UX.
struct LoadingStateView: View {
    var message: String? = nil
    var style: LoadingStyle = .fullScreen

    enum LoadingStyle {
        case fullScreen
        case inline
        case overlay
    }

    var body: some View {
        switch style {
        case .fullScreen:
            fullScreenView
        case .inline:
            inlineView
        case .overlay:
            overlayView
        }
    }

    private var fullScreenView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))
                .scaleEffect(1.2)

            if let message = message {
                Text(message)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var inlineView: some View {
        HStack(spacing: Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))

            if let message = message {
                Text(message)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
    }

    private var overlayView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                if let message = message {
                    Text(message)
                        .font(AppFonts.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding(Spacing.xl)
            .background(Color.black.opacity(0.7))
            .cornerRadius(CornerRadius.lg)
        }
    }
}

#Preview("Full Screen") {
    LoadingStateView(message: "Loading orders...")
}

#Preview("Inline") {
    VStack {
        LoadingStateView(message: "Loading...", style: .inline)
        Spacer()
    }
}

#Preview("Overlay") {
    ZStack {
        Color.blue
        LoadingStateView(message: "Processing...", style: .overlay)
    }
}
