//
//  CreateCouponView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct CreateCouponView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateCouponViewModel()
    let onCouponCreated: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // MARK: - Coupon Details
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Coupon Details", icon: "ticket.fill")

                        MarketingTextField(
                            label: "Coupon Code",
                            placeholder: "e.g., SAVE20",
                            text: $viewModel.couponCode
                        )

                        MarketingTextField(
                            label: "Title",
                            placeholder: "e.g., 20% Off Your Order",
                            text: $viewModel.title
                        )

                        MarketingTextEditor(
                            label: "Description",
                            placeholder: "Describe the offer...",
                            text: $viewModel.description
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Discount Type
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Discount", icon: "percent")

                        Picker("Type", selection: $viewModel.discountType) {
                            Text("Percentage").tag(DiscountType.percentage)
                            Text("Fixed Amount").tag(DiscountType.fixed)
                            Text("Free Item").tag(DiscountType.freeItem)
                        }
                        .pickerStyle(.segmented)

                        if viewModel.discountType == .percentage {
                            MarketingTextField(
                                label: "Percentage Off",
                                placeholder: "e.g., 20",
                                text: $viewModel.discountValue,
                                keyboardType: .numberPad
                            )
                        } else if viewModel.discountType == .fixed {
                            MarketingTextField(
                                label: "Amount Off",
                                placeholder: "e.g., 5.00",
                                text: $viewModel.discountValue,
                                keyboardType: .decimalPad
                            )
                        } else {
                            Text("Select free item from menu")
                                .font(AppFonts.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Conditions
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Conditions", icon: "list.bullet")

                        MarketingTextField(
                            label: "Minimum Order Amount",
                            placeholder: "e.g., 25.00 (optional)",
                            text: $viewModel.minOrderAmount,
                            keyboardType: .decimalPad
                        )

                        MarketingTextField(
                            label: "Maximum Uses",
                            placeholder: "e.g., 100 (optional)",
                            text: $viewModel.maxUses,
                            keyboardType: .numberPad
                        )

                        Toggle("One per customer", isOn: $viewModel.onePerCustomer)
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.md)
                    }
                    .padding(.horizontal)

                    // MARK: - Validity Period
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Validity Period", icon: "calendar")

                        DatePicker(
                            "Start Date",
                            selection: $viewModel.startDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .padding()
                        .background(Color.surface)
                        .cornerRadius(CornerRadius.md)

                        DatePicker(
                            "End Date",
                            selection: $viewModel.endDate,
                            in: viewModel.startDate...,
                            displayedComponents: .date
                        )
                        .padding()
                        .background(Color.surface)
                        .cornerRadius(CornerRadius.md)
                    }
                    .padding(.horizontal)

                    // MARK: - Coupon Preview
                    CouponPreview(
                        code: viewModel.couponCode,
                        title: viewModel.title,
                        description: viewModel.description,
                        discountType: viewModel.discountType,
                        discountValue: viewModel.discountValue,
                        expiresAt: viewModel.endDate
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .navigationTitle("Create Coupon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createCoupon {
                            onCouponCreated()
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(!viewModel.isValid || viewModel.isCreating)
                }
            }
        }
    }
}

// MARK: - Coupon Preview

struct CouponPreview: View {
    let code: String
    let title: String
    let description: String
    let discountType: DiscountType
    let discountValue: String
    let expiresAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Preview")
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)

            ZStack {
                // Coupon background with dashed border
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [5])
                    )
                    .foregroundColor(.warning)

                VStack(spacing: Spacing.lg) {
                    // Discount display
                    if !discountValue.isEmpty {
                        Text(discountDisplay)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.warning)
                    }

                    VStack(spacing: Spacing.sm) {
                        if !code.isEmpty {
                            Text(code)
                                .font(AppFonts.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.warning.opacity(0.1))
                                .cornerRadius(CornerRadius.sm)
                        }

                        if !title.isEmpty {
                            Text(title)
                                .font(AppFonts.headline)
                        }

                        if !description.isEmpty {
                            Text(description)
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Text("Valid until \(expiresAt, style: .date)")
                        .font(AppFonts.caption2)
                        .foregroundColor(.textSecondary)
                }
                .padding()
            }
            .frame(height: 250)
        }
    }

    var discountDisplay: String {
        switch discountType {
        case .percentage:
            return "\(discountValue)%"
        case .fixed:
            return "$\(discountValue)"
        case .freeItem:
            return "FREE"
        }
    }
}

#Preview {
    CreateCouponView(onCouponCreated: {})
}
