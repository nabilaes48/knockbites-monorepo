//
//  PortionSelector.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//  Portion selector UI components matching web app design
//

import SwiftUI

// MARK: - Portion Selector Button

/// Individual portion level button (○ ◔ ◑ ●)
struct PortionSelectorButton: View {
    let portion: PortionLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(portion.emoji)
                    .font(.system(size: 24))

                Text(portion.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.brandPrimary : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected ? Color.brandPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(portion.displayName) portion")
        .accessibilityHint(portion.description)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Portion Selector Row

/// Row of 4 portion buttons (None, Light, Regular, Extra)
struct PortionSelectorRow: View {
    @Binding var selectedPortion: PortionLevel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(PortionLevel.allCases, id: \.self) { portion in
                PortionSelectorButton(
                    portion: portion,
                    isSelected: selectedPortion == portion,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPortion = portion
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("Portion Buttons") {
    VStack(spacing: 20) {
        Text("Portion Selector Demo")
            .font(.headline)

        PortionSelectorRow(selectedPortion: .constant(.none))
        PortionSelectorRow(selectedPortion: .constant(.light))
        PortionSelectorRow(selectedPortion: .constant(.regular))
        PortionSelectorRow(selectedPortion: .constant(.extra))
    }
    .padding()
}

#Preview("Interactive") {
    struct InteractivePreview: View {
        @State private var selection: PortionLevel = .regular

        var body: some View {
            VStack(spacing: 20) {
                Text("Selected: \(selection.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)

                PortionSelectorRow(selectedPortion: $selection)

                Text(selection.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    return InteractivePreview()
}
