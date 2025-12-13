//
//  LoadingView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))
                    .scaleEffect(1.5)

                Text(message)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding(Spacing.xl)
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(radius: 10)
        }
    }
}

#Preview {
    LoadingView()
}
