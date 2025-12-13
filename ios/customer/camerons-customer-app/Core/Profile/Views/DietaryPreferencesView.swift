//
//  DietaryPreferencesView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct DietaryPreferencesView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                if profileViewModel.isLoading {
                    LoadingView(message: "Saving preferences...")
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        // Header
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Dietary Preferences")
                                .font(AppFonts.largeTitle)
                                .foregroundColor(.textPrimary)

                            Text("Customize your menu to match your dietary needs and preferences")
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Dietary Preferences Section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("My Preferences")
                                .font(AppFonts.headline)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal)

                            Text("Select your dietary preferences to highlight compatible items")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal)

                            VStack(spacing: Spacing.sm) {
                                ForEach(DietaryTag.allCases.filter { $0 != .spicy }, id: \.self) { tag in
                                    DietaryTagRow(
                                        tag: tag,
                                        isSelected: profileViewModel.profile.dietaryPreferences.contains(tag)
                                    ) {
                                        togglePreference(tag)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.md)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                            .padding(.horizontal)
                        }

                        // Allergens Section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Allergens & Restrictions")
                                .font(AppFonts.headline)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal)

                            Text("Items containing these will be marked with warnings")
                                .font(AppFonts.caption)
                                .foregroundColor(.error)
                                .padding(.horizontal)

                            VStack(spacing: Spacing.sm) {
                                ForEach(DietaryTag.allCases.filter { $0 != .spicy }, id: \.self) { tag in
                                    DietaryTagRow(
                                        tag: tag,
                                        isSelected: profileViewModel.profile.allergens.contains(tag),
                                        isAllergen: true
                                    ) {
                                        toggleAllergen(tag)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.md)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                            .padding(.horizontal)
                        }

                        // Spicy Tolerance Section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Spicy Tolerance")
                                .font(AppFonts.headline)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal)

                            Text("Set your preferred spice level")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal)

                            VStack(spacing: Spacing.sm) {
                                ForEach(SpicyTolerance.allCases, id: \.self) { tolerance in
                                    SpicyToleranceRow(
                                        tolerance: tolerance,
                                        isSelected: profileViewModel.profile.spicyTolerance == tolerance
                                    ) {
                                        Task {
                                            await profileViewModel.updateSpicyTolerance(tolerance)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.md)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                            .padding(.horizontal)
                        }

                        // Clear All Button
                        Button(action: {
                            profileViewModel.clearProfile()
                            ToastManager.shared.show("Preferences cleared", icon: "checkmark.circle.fill", type: .success)
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All Preferences")
                            }
                            .font(AppFonts.subheadline)
                            .foregroundColor(.error)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.error.opacity(0.1))
                            .cornerRadius(CornerRadius.md)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                // Fetch profile from Supabase when view appears
                await profileViewModel.fetchProfile()
            }
        }
    }

    private func togglePreference(_ tag: DietaryTag) {
        Task {
            if profileViewModel.profile.dietaryPreferences.contains(tag) {
                await profileViewModel.removeDietaryPreference(tag)
            } else {
                await profileViewModel.addDietaryPreference(tag)
                // Remove from allergens if adding as preference
                if profileViewModel.profile.allergens.contains(tag) {
                    await profileViewModel.removeAllergen(tag)
                }
            }
        }
    }

    private func toggleAllergen(_ tag: DietaryTag) {
        Task {
            if profileViewModel.profile.allergens.contains(tag) {
                await profileViewModel.removeAllergen(tag)
            } else {
                await profileViewModel.addAllergen(tag)
                // Remove from preferences if adding as allergen
                if profileViewModel.profile.dietaryPreferences.contains(tag) {
                    await profileViewModel.removeDietaryPreference(tag)
                }
            }
        }
    }
}

// MARK: - Dietary Tag Row
struct DietaryTagRow: View {
    let tag: DietaryTag
    let isSelected: Bool
    var isAllergen: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? tagColor.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: tag.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? tagColor : .textSecondary)
                }

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.rawValue)
                        .font(AppFonts.body)
                        .foregroundColor(.textPrimary)

                    if isAllergen && isSelected {
                        Text("Will show warnings")
                            .font(AppFonts.caption)
                            .foregroundColor(.error)
                    }
                }

                Spacer()

                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? tagColor : .textSecondary)
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var tagColor: Color {
        if isAllergen {
            return .error
        }

        switch tag.color {
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        case "brown": return .brown
        case "red": return .red
        case "purple": return .purple
        default: return .gray
        }
    }
}

// MARK: - Spicy Tolerance Row
struct SpicyToleranceRow: View {
    let tolerance: SpicyTolerance
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)

                    HStack(spacing: 2) {
                        ForEach(0..<spicyLevel, id: \.self) { _ in
                            Image(systemName: tolerance.icon)
                                .font(.caption2)
                                .foregroundColor(isSelected ? .orange : .textSecondary)
                        }
                    }
                }

                // Label
                Text(tolerance.rawValue)
                    .font(AppFonts.body)
                    .foregroundColor(.textPrimary)

                Spacer()

                // Radio button
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .orange : .textSecondary)
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var spicyLevel: Int {
        switch tolerance {
        case .none: return 0
        case .mild: return 1
        case .medium: return 2
        case .hot: return 3
        case .extraHot: return 4
        }
    }
}

#Preview {
    DietaryPreferencesView()
        .environmentObject(ProfileViewModel())
}
