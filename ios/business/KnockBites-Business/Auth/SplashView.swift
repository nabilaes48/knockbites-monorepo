//
//  SplashView.swift
//  KnockBites-Business
//
//  Created by Claude Code
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient matching login screen
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.brandPrimary.opacity(0.1),
                    Color.surface
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Image("KnockBitesLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                VStack(spacing: Spacing.sm) {
                    Text("KnockBites")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .opacity(logoOpacity)

                    Text("Business Portal")
                        .font(AppFonts.title3)
                        .foregroundColor(.textSecondary)
                        .opacity(logoOpacity)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Fade in and zoom animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // Wait then fade out and zoom out
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                logoScale = 1.2
                logoOpacity = 0
            }

            // Complete after fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onComplete()
            }
        }
    }
}

#Preview {
    SplashView {
        print("Animation complete")
    }
}
