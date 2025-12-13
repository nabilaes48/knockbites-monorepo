//
//  SplashView.swift
//  KnockBites-Customer
//
//  Created by Claude Code on 12/13/25.
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var isAnimationComplete = false

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("KnockBites")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .opacity(logoOpacity)
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
