//
//  DesignSystem.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//  Updated Phase 9 - Added button styles, animation durations, and standardized tokens
//

import SwiftUI

// MARK: - Colors
extension Color {
    static let brandPrimary = Color.blue // Can be customized in Assets catalog
    static let brandSecondary = Color.orange

    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let surface = Color(.systemBackground)
    static let surfaceSecondary = Color(.secondarySystemBackground)
    static let surfaceTertiary = Color(.tertiarySystemBackground)

    // Status colors for orders
    static let statusReceived = Color.blue
    static let statusPreparing = Color.orange
    static let statusReady = Color.green
    static let statusCompleted = Color.gray
    static let statusCancelled = Color.red
}

// MARK: - Typography
struct AppFonts {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.semibold)
    static let headline = Font.headline
    static let subheadline = Font.subheadline
    static let body = Font.body
    static let callout = Font.callout
    static let caption = Font.caption
    static let caption2 = Font.caption2

    // Numeric displays
    static let metric = Font.system(size: 32, weight: .bold, design: .rounded)
    static let metricSmall = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let orderNumber = Font.system(size: 18, weight: .bold, design: .monospaced)
}

// MARK: - Spacing
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius
struct CornerRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 24
    static let full: CGFloat = 9999 // For pill shapes
}

// MARK: - Shadow
struct AppShadow {
    static let sm = Color.black.opacity(0.05)
    static let md = Color.black.opacity(0.1)
    static let lg = Color.black.opacity(0.15)

    // Shadow configurations
    static func card(color: Color = .black) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (color.opacity(0.1), 8, 0, 4)
    }

    static func elevated(color: Color = .black) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (color.opacity(0.15), 12, 0, 6)
    }
}

// MARK: - Animation Durations
struct AnimationDuration {
    static let fast: Double = 0.15
    static let normal: Double = 0.25
    static let slow: Double = 0.35
}

// MARK: - Icon Sizes
struct IconSize {
    static let sm: CGFloat = 16
    static let md: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Color.brandPrimary)
            .cornerRadius(CornerRadius.lg)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.fast), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.headline)
            .foregroundColor(.brandPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Color.surfaceSecondary)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.fast), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Color.error)
            .cornerRadius(CornerRadius.lg)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.fast), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == DestructiveButtonStyle {
    static var destructive: DestructiveButtonStyle { DestructiveButtonStyle() }
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var padding: CGFloat = Spacing.lg
    var cornerRadius: CGFloat = CornerRadius.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.surface)
            .cornerRadius(cornerRadius)
            .shadow(color: AppShadow.sm, radius: 8, x: 0, y: 4)
    }
}

extension View {
    func cardStyle(padding: CGFloat = Spacing.lg, cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        modifier(CardStyle(padding: padding, cornerRadius: cornerRadius))
    }
}
