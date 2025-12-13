//
//  PaymentMethodsView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct PaymentMethodsView: View {
    @StateObject private var viewModel = PaymentMethodViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showAddPayment = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        // Header
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Payment Methods")
                                .font(AppFonts.largeTitle)
                                .foregroundColor(.textPrimary)

                            Text("Manage your saved payment methods")
                                .font(AppFonts.body)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Expired Cards Warning
                        if viewModel.hasExpiredCards {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.error)

                                Text("You have expired cards. Please update or remove them.")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.error)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.error.opacity(0.1))
                            .cornerRadius(CornerRadius.md)
                            .padding(.horizontal)
                        }

                        // Payment Methods List
                        if viewModel.paymentMethods.isEmpty {
                            VStack(spacing: Spacing.md) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 60))
                                    .foregroundColor(.textSecondary)

                                Text("No Payment Methods")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.textPrimary)

                                Text("Add a payment method to get started")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xxl)
                        } else {
                            VStack(spacing: Spacing.md) {
                                ForEach(viewModel.paymentMethods) { method in
                                    PaymentMethodCard(
                                        method: method,
                                        onSetDefault: {
                                            viewModel.setDefaultPaymentMethod(method)
                                        },
                                        onDelete: {
                                            viewModel.deletePaymentMethod(method)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Add Payment Button
                        CustomButton(
                            title: "Add Payment Method",
                            action: { showAddPayment = true },
                            style: .primary,
                            icon: "plus.circle"
                        )
                        .padding(.horizontal)
                        .padding(.bottom, Spacing.xl)
                    }
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
            .sheet(isPresented: $showAddPayment) {
                AddPaymentMethodView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Payment Method Card
struct PaymentMethodCard: View {
    let method: PaymentMethod
    let onSetDefault: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: method.type == .card ? (method.cardBrand?.icon ?? "creditcard.fill") : method.type.icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                }

                // Details
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Text(method.displayName)
                            .font(AppFonts.headline)
                            .foregroundColor(.textPrimary)

                        if method.isDefault {
                            Text("Default")
                                .font(AppFonts.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.brandPrimary)
                                .cornerRadius(4)
                        }

                        if method.isExpired {
                            Text("Expired")
                                .font(AppFonts.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.error)
                                .cornerRadius(4)
                        }
                    }

                    if let expiry = method.formattedExpiry {
                        Text("Expires \(expiry)")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    } else if method.type == .applePay {
                        Text("Linked to Apple Wallet")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    } else if method.type == .googlePay {
                        Text("Linked to Google Pay")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                // Menu Button
                Menu {
                    if !method.isDefault {
                        Button(action: onSetDefault) {
                            Label("Set as Default", systemImage: "checkmark.circle")
                        }
                    }

                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        .alert("Remove Payment Method?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to remove this payment method?")
        }
    }

    private var iconColor: Color {
        if method.isExpired {
            return .error
        }

        switch method.cardBrand?.color {
        case "blue": return .blue
        case "orange": return .orange
        case "green": return .green
        default: return .brandPrimary
        }
    }
}

// MARK: - Add Payment Method View
struct AddPaymentMethodView: View {
    @ObservedObject var viewModel: PaymentMethodViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedType: PaymentType = .card
    @State private var cardNumber = ""
    @State private var expiryMonth = ""
    @State private var expiryYear = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var selectedBrand: CardBrand = .visa
    @State private var setAsDefault = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        // Payment Type Selector
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Payment Type")
                                .font(AppFonts.headline)
                                .foregroundColor(.textPrimary)

                            HStack(spacing: Spacing.md) {
                                ForEach([PaymentType.card, .applePay, .googlePay], id: \.self) { type in
                                    PaymentTypeButton(
                                        type: type,
                                        isSelected: selectedType == type
                                    ) {
                                        selectedType = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        if selectedType == .card {
                            // Card Form
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Card Details")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.textPrimary)

                                // Card Brand
                                Picker("Card Type", selection: $selectedBrand) {
                                    ForEach(CardBrand.allCases, id: \.self) { brand in
                                        Text(brand.rawValue).tag(brand)
                                    }
                                }
                                .pickerStyle(.segmented)

                                // Cardholder Name
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Cardholder Name")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.textSecondary)

                                    TextField("John Doe", text: $cardholderName)
                                        .textFieldStyle(.roundedBorder)
                                }

                                // Card Number
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Card Number")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.textSecondary)

                                    TextField("1234 5678 9012 3456", text: $cardNumber)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                }

                                // Expiry & CVV
                                HStack(spacing: Spacing.md) {
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text("Expiry (MM)")
                                            .font(AppFonts.caption)
                                            .foregroundColor(.textSecondary)

                                        TextField("12", text: $expiryMonth)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.numberPad)
                                    }

                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text("Year (YYYY)")
                                            .font(AppFonts.caption)
                                            .foregroundColor(.textSecondary)

                                        TextField("2025", text: $expiryYear)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.numberPad)
                                    }

                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text("CVV")
                                            .font(AppFonts.caption)
                                            .foregroundColor(.textSecondary)

                                        SecureField("123", text: $cvv)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.numberPad)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            // Digital Wallet Info
                            VStack(spacing: Spacing.md) {
                                Image(systemName: selectedType.icon)
                                    .font(.system(size: 60))
                                    .foregroundColor(.brandPrimary)

                                Text(selectedType == .applePay ? "Apple Pay" : "Google Pay")
                                    .font(AppFonts.title2)
                                    .foregroundColor(.textPrimary)

                                Text("This is a simulated payment method for demonstration purposes")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.md)
                            .padding(.horizontal)
                        }

                        // Set as Default Toggle
                        Toggle("Set as default payment method", isOn: $setAsDefault)
                            .font(AppFonts.body)
                            .padding(.horizontal)

                        // Add Button
                        CustomButton(
                            title: "Add Payment Method",
                            action: addPaymentMethod,
                            style: .primary,
                            isDisabled: !isFormValid
                        )
                        .padding(.horizontal)
                        .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .navigationTitle("Add Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        if selectedType == .card {
            return !cardNumber.isEmpty &&
                   !expiryMonth.isEmpty &&
                   !expiryYear.isEmpty &&
                   !cvv.isEmpty &&
                   !cardholderName.isEmpty
        }
        return true
    }

    private func addPaymentMethod() {
        let lastFour: String?
        let month: Int?
        let year: Int?
        let displayName: String
        let brand: CardBrand?

        if selectedType == .card {
            lastFour = String(cardNumber.suffix(4))
            month = Int(expiryMonth)
            year = Int(expiryYear)
            displayName = "\(selectedBrand.rawValue) •••• \(lastFour ?? "")"
            brand = selectedBrand
        } else {
            lastFour = nil
            month = nil
            year = nil
            displayName = selectedType.rawValue
            brand = nil
        }

        let method = PaymentMethod(
            id: UUID().uuidString,
            type: selectedType,
            displayName: displayName,
            lastFourDigits: lastFour,
            expiryMonth: month,
            expiryYear: year,
            isDefault: setAsDefault,
            cardBrand: brand
        )

        viewModel.addPaymentMethod(method)
        dismiss()
    }
}

// MARK: - Payment Type Button
struct PaymentTypeButton: View {
    let type: PaymentType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: type.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .brandPrimary)

                Text(type.rawValue)
                    .font(AppFonts.caption)
                    .foregroundColor(isSelected ? .white : .textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.brandPrimary : Color.surface)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.clear : Color.border, lineWidth: 1)
            )
        }
    }
}

#Preview {
    PaymentMethodsView()
}
