//
//  SegmentBuilderView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct SegmentBuilderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: CustomerSegmentsViewModel

    @State private var segmentName = ""
    @State private var segmentDescription = ""
    @State private var filters: [SegmentFilter] = []
    @State private var showAddFilter = false

    var isValid: Bool {
        !segmentName.isEmpty && !filters.isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Segment Details")) {
                    TextField("Segment Name", text: $segmentName)
                        .font(AppFonts.body)

                    TextField("Description (Optional)", text: $segmentDescription)
                        .font(AppFonts.body)
                }

                Section(header: HStack {
                    Text("Filters")
                    Spacer()
                    Button(action: { showAddFilter = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brandPrimary)
                    }
                }) {
                    if filters.isEmpty {
                        Text("No filters added. Tap + to add a filter.")
                            .font(AppFonts.subheadline)
                            .foregroundColor(.textSecondary)
                            .padding(.vertical, Spacing.sm)
                    } else {
                        ForEach(filters) { filter in
                            FilterRow(filter: filter) {
                                removeFilter(filter)
                            }
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Preview")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)

                        if filters.isEmpty {
                            Text("Add filters to define your segment")
                                .font(AppFonts.subheadline)
                                .foregroundColor(.textSecondary)
                        } else {
                            Text(generatePreviewText())
                                .font(AppFonts.subheadline)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }
            .navigationTitle("Create Segment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSegment()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showAddFilter) {
                AddFilterView { filter in
                    filters.append(filter)
                }
            }
        }
    }

    private func removeFilter(_ filter: SegmentFilter) {
        filters.removeAll { $0.id == filter.id }
    }

    private func generatePreviewText() -> String {
        let descriptions = filters.map { filter in
            "Customers where \(filter.filterType.displayName) \(filter.condition.displayName.lowercased()) \(filter.value)"
        }
        return descriptions.joined(separator: "\nAND ")
    }

    private func saveSegment() {
        let segment = CustomerSegment(
            name: segmentName,
            description: segmentDescription.isEmpty ? nil : segmentDescription,
            filters: filters
        )
        viewModel.saveCustomSegment(segment)
        dismiss()
    }
}

// MARK: - Filter Row

struct FilterRow: View {
    let filter: SegmentFilter
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Image(systemName: filter.filterType.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.brandPrimary)

                    Text(filter.filterType.displayName)
                        .font(AppFonts.subheadline)
                        .fontWeight(.semibold)
                }

                Text("\(filter.condition.displayName): \(filter.value)")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.error)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Add Filter View

struct AddFilterView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (SegmentFilter) -> Void

    @State private var selectedFilterType: SegmentFilterType = .totalOrders
    @State private var selectedCondition: SegmentCondition = .greaterThan
    @State private var value1 = ""
    @State private var value2 = "" // For "between" condition

    var isValid: Bool {
        if selectedCondition == .between {
            return !value1.isEmpty && !value2.isEmpty
        } else {
            return !value1.isEmpty
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Filter Type")) {
                    Picker("Type", selection: $selectedFilterType) {
                        ForEach(SegmentFilterType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .onChange(of: selectedFilterType) { newType in
                        // Reset condition if not available for new type
                        if !newType.availableConditions.contains(selectedCondition) {
                            selectedCondition = newType.availableConditions.first ?? .equals
                        }
                    }
                }

                Section(header: Text("Condition")) {
                    Picker("Condition", selection: $selectedCondition) {
                        ForEach(selectedFilterType.availableConditions, id: \.self) { condition in
                            Text(condition.displayName).tag(condition)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Value")) {
                    if selectedCondition == .between {
                        TextField("Minimum Value", text: $value1)
                            .keyboardType(getKeyboardType())

                        TextField("Maximum Value", text: $value2)
                            .keyboardType(getKeyboardType())
                    } else {
                        TextField("Value", text: $value1)
                            .keyboardType(getKeyboardType())
                    }
                }

                Section {
                    Text(getHintText())
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .navigationTitle("Add Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveFilter()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func getKeyboardType() -> UIKeyboardType {
        switch selectedFilterType {
        case .totalOrders, .lastOrderDays, .loyaltyPoints:
            return .numberPad
        case .totalSpent, .avgOrderValue:
            return .decimalPad
        case .loyaltyTier:
            return .default
        }
    }

    private func getHintText() -> String {
        switch selectedFilterType {
        case .totalOrders:
            return "Example: 5 (customers with 5 or more orders)"
        case .totalSpent:
            return "Example: 500 (customers who spent $500 or more)"
        case .lastOrderDays:
            return "Example: 30 (customers who ordered within last 30 days)"
        case .loyaltyPoints:
            return "Example: 500 (customers with 500+ points)"
        case .avgOrderValue:
            return "Example: 50 (customers with avg order of $50+)"
        case .loyaltyTier:
            return "Example: Gold, Silver, Bronze, Platinum"
        }
    }

    private func saveFilter() {
        let filterValue = selectedCondition == .between ? "\(value1)-\(value2)" : value1

        let filter = SegmentFilter(
            filterType: selectedFilterType,
            condition: selectedCondition,
            value: filterValue
        )

        onSave(filter)
        dismiss()
    }
}

#Preview {
    SegmentBuilderView(viewModel: CustomerSegmentsViewModel())
}
