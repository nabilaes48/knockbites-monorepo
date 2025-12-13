//
//  CustomButton.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyleType = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String?

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Text(title)
                        .font(AppFonts.headline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(isDisabled ? Color.gray.opacity(0.3) : style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(isDisabled || isLoading)
    }
}

enum ButtonStyleType {
    case primary
    case secondary
    case outline
    case danger

    var backgroundColor: Color {
        switch self {
        case .primary: return .brandPrimary
        case .secondary: return .brandSecondary
        case .outline: return .clear
        case .danger: return .error
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary, .secondary, .danger: return .white
        case .outline: return .brandPrimary
        }
    }

    var borderColor: Color {
        switch self {
        case .outline: return .brandPrimary
        default: return .clear
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .outline: return 2
        default: return 0
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.md) {
            Text("Button Styles")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)

            CustomButton(title: "Primary Button", action: {}, style: .primary)
            CustomButton(title: "Secondary Button", action: {}, style: .secondary)
            CustomButton(title: "Outline Button", action: {}, style: .outline)
            CustomButton(title: "Danger Button", action: {}, style: .danger)
            CustomButton(title: "Loading", action: {}, isLoading: true)
            CustomButton(title: "Disabled", action: {}, isDisabled: true)
            CustomButton(title: "With Icon", action: {}, icon: "person.fill")
        }
        .padding()
    }
}
