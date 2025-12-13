//
//  StoreSelectorView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct StoreSelectorView: View {
    @Binding var selectedStore: Store?
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = StoreViewModel()
    let autoSelectIfOne: Bool

    init(selectedStore: Binding<Store?>, autoSelectIfOne: Bool = true) {
        self._selectedStore = selectedStore
        self.autoSelectIfOne = autoSelectIfOne
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                if viewModel.isLoading {
                    VStack(spacing: Spacing.lg) {
                        ProgressView()
                        Text("Finding nearby stores...")
                            .font(AppFonts.body)
                            .foregroundColor(.textSecondary)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(
                        title: "Unable to Load Stores",
                        message: errorMessage,
                        icon: "exclamationmark.triangle",
                        retryAction: {
                            Task {
                                await loadStoresAndAutoSelect()
                            }
                        }
                    )
                } else if viewModel.stores.isEmpty {
                    EmptyStateView(
                        icon: "storefront",
                        title: "No Stores Available",
                        message: "We don't have any stores in your area yet. Check back soon!"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.sm) {
                            // Location hint
                            if viewModel.userLocation != nil {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(.brandPrimary)
                                    Text("Sorted by distance")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.horizontal)
                                .padding(.top, Spacing.sm)
                            }

                            ForEach(viewModel.stores) { store in
                                StoreCard(
                                    store: store,
                                    isSelected: selectedStore?.id == store.id,
                                    distance: viewModel.formattedDistance(store)
                                ) {
                                    selectedStore = store
                                    // Save to UserDefaults
                                    UserDefaults.standard.set(store.id, forKey: "selectedStoreId")
                                    dismiss()
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedStore != nil {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .task {
                await loadStoresAndAutoSelect()
            }
        }
    }

    private func loadStoresAndAutoSelect() async {
        // Request location first
        viewModel.requestLocation()

        // Small delay to try to get location
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Load stores (will be sorted by proximity if location available)
        await viewModel.loadStores()

        // Auto-select if only one store
        if autoSelectIfOne && viewModel.stores.count == 1, selectedStore == nil {
            if let onlyStore = viewModel.stores.first {
                selectedStore = onlyStore
                UserDefaults.standard.set(onlyStore.id, forKey: "selectedStoreId")
                print("✅ Auto-selected only store: \(onlyStore.name)")
                dismiss()
            }
        }
    }
}

// MARK: - Store Card
struct StoreCard: View {
    let store: Store
    let isSelected: Bool
    let distance: String?
    let action: () -> Void

    init(store: Store, isSelected: Bool, distance: String? = nil, action: @escaping () -> Void) {
        self.store = store
        self.isSelected = isSelected
        self.distance = distance
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(store.name)
                            .font(AppFonts.headline)
                            .foregroundColor(.textPrimary)

                        HStack(spacing: Spacing.xs) {
                            Circle()
                                .fill(store.isOpen ? Color.success : Color.error)
                                .frame(width: 8, height: 8)

                            Text(store.isOpen ? "Open" : "Closed")
                                .font(AppFonts.caption)
                                .foregroundColor(store.isOpen ? .success : .error)

                            // Distance badge
                            if let distance = distance {
                                Text("•")
                                    .foregroundColor(.textSecondary)
                                Text(distance)
                                    .font(AppFonts.caption)
                                    .foregroundColor(.brandPrimary)
                            }
                        }
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.brandPrimary)
                    }
                }

                // Address
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.brandPrimary)
                    Text(store.address)
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }

                // Phone
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.brandPrimary)
                    Text(store.phoneNumber)
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                // Hours
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.brandPrimary)
                    Text("\(store.hours.openTime) - \(store.hours.closeTime)")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Store Selector Button (for use in other views)
struct StoreSelectorButton: View {
    @Binding var selectedStore: Store?
    @State private var showingStorePicker = false

    var body: some View {
        Button(action: { showingStorePicker = true }) {
            HStack {
                Image(systemName: "storefront.fill")
                    .foregroundColor(.brandPrimary)

                if let store = selectedStore {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.name)
                            .font(AppFonts.body)
                            .foregroundColor(.textPrimary)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(store.isOpen ? Color.success : Color.error)
                                .frame(width: 6, height: 6)
                            Text(store.isOpen ? "Open" : "Closed")
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                        }
                    }
                } else {
                    Text("Select a store")
                        .font(AppFonts.body)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.border, lineWidth: 1)
            )
        }
        .sheet(isPresented: $showingStorePicker) {
            StoreSelectorView(selectedStore: $selectedStore)
        }
    }
}

#Preview {
    StoreSelectorView(selectedStore: .constant(nil))
}
