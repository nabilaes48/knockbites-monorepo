//
//  AddAddressView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/19/25.
//

import SwiftUI

struct AddAddressView: View {
    @ObservedObject var viewModel: AddressViewModel
    @Environment(\.dismiss) var dismiss

    @State private var label = ""
    @State private var streetAddress = ""
    @State private var apartment = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var phoneNumber = ""
    @State private var deliveryInstructions = ""
    @State private var isDefault = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Address Label")) {
                    TextField("e.g., Home, Work, Mom's House", text: $label)
                }

                Section(header: Text("Street Address")) {
                    TextField("Street Address", text: $streetAddress)
                    TextField("Apartment/Unit (optional)", text: $apartment)
                }

                Section(header: Text("City & State")) {
                    TextField("City", text: $city)

                    HStack {
                        TextField("State", text: $state)
                            .textInputAutocapitalization(.characters)

                        TextField("ZIP Code", text: $zipCode)
                            .keyboardType(.numberPad)
                    }
                }

                Section(header: Text("Contact")) {
                    TextField("Phone Number (optional)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Section(header: Text("Delivery Instructions (optional)")) {
                    TextEditor(text: $deliveryInstructions)
                        .frame(height: 80)
                }

                Section {
                    Toggle("Set as default address", isOn: $isDefault)
                }
            }
            .navigationTitle("Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAddress()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !label.isEmpty &&
        !streetAddress.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !zipCode.isEmpty
    }

    private func saveAddress() {
        let newAddress = Address(
            userId: "", // Will be set by SupabaseManager
            label: label,
            streetAddress: streetAddress,
            apartment: apartment.isEmpty ? nil : apartment,
            city: city,
            state: state,
            zipCode: zipCode,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            deliveryInstructions: deliveryInstructions.isEmpty ? nil : deliveryInstructions,
            isDefault: isDefault
        )

        Task {
            await viewModel.addAddress(newAddress)
            dismiss()
        }
    }
}

// MARK: - Edit Address View
struct EditAddressView: View {
    @ObservedObject var viewModel: AddressViewModel
    let address: Address
    @Environment(\.dismiss) var dismiss

    @State private var label = ""
    @State private var streetAddress = ""
    @State private var apartment = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var phoneNumber = ""
    @State private var deliveryInstructions = ""
    @State private var isDefault = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Address Label")) {
                    TextField("e.g., Home, Work, Mom's House", text: $label)
                }

                Section(header: Text("Street Address")) {
                    TextField("Street Address", text: $streetAddress)
                    TextField("Apartment/Unit (optional)", text: $apartment)
                }

                Section(header: Text("City & State")) {
                    TextField("City", text: $city)

                    HStack {
                        TextField("State", text: $state)
                            .textInputAutocapitalization(.characters)

                        TextField("ZIP Code", text: $zipCode)
                            .keyboardType(.numberPad)
                    }
                }

                Section(header: Text("Contact")) {
                    TextField("Phone Number (optional)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Section(header: Text("Delivery Instructions (optional)")) {
                    TextEditor(text: $deliveryInstructions)
                        .frame(height: 80)
                }

                Section {
                    Toggle("Set as default address", isOn: $isDefault)
                }
            }
            .navigationTitle("Edit Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAddress()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadAddress()
            }
        }
    }

    private var isValid: Bool {
        !label.isEmpty &&
        !streetAddress.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !zipCode.isEmpty
    }

    private func loadAddress() {
        label = address.label
        streetAddress = address.streetAddress
        apartment = address.apartment ?? ""
        city = address.city
        state = address.state
        zipCode = address.zipCode
        phoneNumber = address.phoneNumber ?? ""
        deliveryInstructions = address.deliveryInstructions ?? ""
        isDefault = address.isDefault
    }

    private func saveAddress() {
        let updatedAddress = Address(
            id: address.id,
            userId: address.userId,
            label: label,
            streetAddress: streetAddress,
            apartment: apartment.isEmpty ? nil : apartment,
            city: city,
            state: state,
            zipCode: zipCode,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            deliveryInstructions: deliveryInstructions.isEmpty ? nil : deliveryInstructions,
            isDefault: isDefault,
            createdAt: address.createdAt,
            updatedAt: Date()
        )

        Task {
            await viewModel.updateAddress(updatedAddress)
            dismiss()
        }
    }
}

#Preview {
    AddAddressView(viewModel: AddressViewModel())
}
