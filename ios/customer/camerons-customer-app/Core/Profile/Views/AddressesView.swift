//
//  AddressesView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/19/25.
//

import SwiftUI

struct AddressesView: View {
    @StateObject var viewModel = AddressViewModel()
    @State private var showAddAddress = false
    @State private var editingAddress: Address?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.addresses.isEmpty {
                    LoadingView(message: "Loading addresses...")
                } else if viewModel.addresses.isEmpty {
                    // Empty State
                    VStack(spacing: Spacing.xl) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.3))

                        VStack(spacing: Spacing.md) {
                            Text("No Addresses Saved")
                                .font(AppFonts.title2)
                                .foregroundColor(.textPrimary)

                            Text("Add a delivery address to make ordering easier")
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.xl)
                        }

                        CustomButton(
                            title: "Add Address",
                            action: { showAddAddress = true },
                            icon: "plus.circle.fill"
                        )
                        .padding(.horizontal, Spacing.xl)
                    }
                } else {
                    // Addresses List
                    ScrollView {
                        VStack(spacing: Spacing.md) {
                            ForEach(viewModel.addresses) { address in
                                AddressCard(
                                    address: address,
                                    onEdit: {
                                        editingAddress = address
                                    },
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteAddress(address)
                                        }
                                    },
                                    onSetDefault: {
                                        Task {
                                            await viewModel.setDefaultAddress(address)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.fetchAddresses()
                    }
                }
            }
            .navigationTitle("Addresses")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !viewModel.addresses.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showAddAddress = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddAddress) {
                AddAddressView(viewModel: viewModel)
            }
            .sheet(item: $editingAddress) { address in
                EditAddressView(viewModel: viewModel, address: address)
            }
            .task {
                // Fetch addresses when view appears
                await viewModel.fetchAddresses()
            }
        }
    }
}

// MARK: - Address Card
struct AddressCard: View {
    let address: Address
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetDefault: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header: Label and Default Badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.brandPrimary)

                        Text(address.label)
                            .font(AppFonts.headline)
                            .foregroundColor(.textPrimary)
                    }

                    if address.isDefault {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("Default")
                                .font(AppFonts.caption)
                        }
                        .foregroundColor(.green)
                    }
                }

                Spacer()

                Menu {
                    if !address.isDefault {
                        Button(action: onSetDefault) {
                            Label("Set as Default", systemImage: "checkmark.circle")
                        }
                    }

                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.textSecondary)
                }
            }

            Divider()

            // Address Details
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top) {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .frame(width: 20)

                    Text(address.fullAddress)
                        .font(AppFonts.body)
                        .foregroundColor(.textPrimary)
                }

                if let phone = address.phoneNumber, !phone.isEmpty {
                    HStack {
                        Image(systemName: "phone")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .frame(width: 20)

                        Text(phone)
                            .font(AppFonts.body)
                            .foregroundColor(.textPrimary)
                    }
                }

                if let instructions = address.deliveryInstructions, !instructions.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .frame(width: 20)

                        Text(instructions)
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
    AddressesView()
}
