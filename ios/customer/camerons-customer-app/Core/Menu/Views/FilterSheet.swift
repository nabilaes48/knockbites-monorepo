//
//  FilterSheet.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MenuViewModel

    // Local state for filters
    @State private var priceRange: ClosedRange<Double>
    @State private var selectedDietaryTags: Set<DietaryTag>
    @State private var sortOption: SortOption

    init(viewModel: MenuViewModel) {
        self.viewModel = viewModel
        _priceRange = State(initialValue: viewModel.priceRange)
        _selectedDietaryTags = State(initialValue: viewModel.selectedDietaryTags)
        _sortOption = State(initialValue: viewModel.sortOption)
    }

    var body: some View {
        NavigationView {
            List {
                // Price Range Section
                Section {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Price Range")
                                .font(AppFonts.headline)
                            Spacer()
                            Text("$\(Int(priceRange.lowerBound)) - $\(Int(priceRange.upperBound))")
                                .font(AppFonts.body)
                                .foregroundColor(.brandPrimary)
                        }

                        RangeSlider(
                            range: $priceRange,
                            bounds: 0...50,
                            step: 1
                        )
                    }
                    .padding(.vertical, Spacing.sm)
                } header: {
                    Text("Price")
                }

                // Dietary Preferences Section
                Section {
                    ForEach(DietaryTag.allCases, id: \.self) { tag in
                        Button(action: {
                            toggleDietaryTag(tag)
                        }) {
                            HStack {
                                Image(systemName: tag.icon)
                                    .foregroundColor(colorForTag(tag))

                                Text(tag.rawValue)
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                if selectedDietaryTags.contains(tag) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.brandPrimary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Dietary Preferences")
                }

                // Sort By Section
                Section {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: {
                            sortOption = option
                        }) {
                            HStack {
                                Text(option.rawValue)
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                if sortOption == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.brandPrimary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Sort By")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func toggleDietaryTag(_ tag: DietaryTag) {
        if selectedDietaryTags.contains(tag) {
            selectedDietaryTags.remove(tag)
        } else {
            selectedDietaryTags.insert(tag)
        }
    }

    private func applyFilters() {
        viewModel.priceRange = priceRange
        viewModel.selectedDietaryTags = selectedDietaryTags
        viewModel.sortOption = sortOption
    }

    private func resetFilters() {
        withAnimation {
            priceRange = 0...50
            selectedDietaryTags.removeAll()
            sortOption = .none
        }
    }

    private func colorForTag(_ tag: DietaryTag) -> Color {
        switch tag {
        case .vegetarian, .vegan: return .green
        case .glutenFree: return .orange
        case .dairyFree: return .blue
        case .nutFree: return .brown
        case .spicy: return .red
        case .keto: return .purple
        }
    }
}

// MARK: - Range Slider
struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Slider(
                    value: Binding(
                        get: { range.lowerBound },
                        set: { newValue in
                            range = newValue...min(range.upperBound, bounds.upperBound)
                        }
                    ),
                    in: bounds,
                    step: step
                )
                .accentColor(.brandPrimary)
            }

            HStack {
                Text("Min: $\(Int(range.lowerBound))")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("Max: $\(Int(range.upperBound))")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            Slider(
                value: Binding(
                    get: { range.upperBound },
                    set: { newValue in
                        range = max(range.lowerBound, bounds.lowerBound)...newValue
                    }
                ),
                in: bounds,
                step: step
            )
            .accentColor(.brandPrimary)
        }
    }
}

#Preview {
    FilterSheet(viewModel: MenuViewModel())
}
