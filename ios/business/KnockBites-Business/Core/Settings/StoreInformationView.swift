//
//  StoreInformationView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct StoreInformationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var storeName = "KnockBites Downtown"
    @State private var address = "123 Main Street, Downtown"
    @State private var city = "New York"
    @State private var state = "NY"
    @State private var zipCode = "10001"
    @State private var phone = "(555) 123-4567"
    @State private var email = "info@knockbites.com"
    @State private var website = "www.knockbites.com"
    @State private var taxRate = "8.5"
    @State private var isActive = true
    @State private var showSaveConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Basic Information
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "Basic Information")

                        CustomTextField(
                            label: "Store Name",
                            placeholder: "Enter store name",
                            text: $storeName,
                            isRequired: true
                        )

                        CustomTextField(
                            label: "Phone Number",
                            placeholder: "(555) 123-4567",
                            text: $phone,
                            keyboardType: .phonePad,
                            isRequired: true
                        )

                        CustomTextField(
                            label: "Email",
                            placeholder: "info@store.com",
                            text: $email,
                            keyboardType: .emailAddress,
                            isRequired: true
                        )

                        CustomTextField(
                            label: "Website",
                            placeholder: "www.store.com",
                            text: $website,
                            keyboardType: .URL
                        )
                    }
                    .padding(.horizontal)

                    // Address Information
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "Address")

                        CustomTextField(
                            label: "Street Address",
                            placeholder: "123 Main Street",
                            text: $address,
                            isRequired: true
                        )

                        HStack(spacing: Spacing.md) {
                            CustomTextField(
                                label: "City",
                                placeholder: "City",
                                text: $city,
                                isRequired: true
                            )

                            CustomTextField(
                                label: "State",
                                placeholder: "State",
                                text: $state,
                                isRequired: true
                            )
                        }

                        CustomTextField(
                            label: "ZIP Code",
                            placeholder: "12345",
                            text: $zipCode,
                            keyboardType: .numberPad,
                            isRequired: true
                        )
                    }
                    .padding(.horizontal)

                    // Business Settings
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "Business Settings")

                        CustomTextField(
                            label: "Tax Rate (%)",
                            placeholder: "8.5",
                            text: $taxRate,
                            keyboardType: .decimalPad,
                            isRequired: true
                        )

                        ToggleRow(
                            title: "Store is Active",
                            icon: "checkmark.circle.fill",
                            isOn: $isActive
                        )
                    }
                    .padding(.horizontal)

                    // Store Features
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "Features")

                        VStack(spacing: Spacing.sm) {
                            FeatureRow(
                                icon: "bicycle",
                                title: "Delivery Available",
                                isEnabled: true
                            )

                            FeatureRow(
                                icon: "bag.fill",
                                title: "Takeout Available",
                                isEnabled: true
                            )

                            FeatureRow(
                                icon: "fork.knife",
                                title: "Dine-In Available",
                                isEnabled: true
                            )
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .navigationTitle("Store Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        showSaveConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                }
            }
            .alert("Store Information Updated", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your store information has been successfully updated.")
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let isEnabled: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .success : .secondary)
                .frame(width: 24)

            Text(title)
                .font(AppFonts.body)

            Spacer()

            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.success)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2, y: 1)
    }
}

#Preview {
    StoreInformationView()
}
