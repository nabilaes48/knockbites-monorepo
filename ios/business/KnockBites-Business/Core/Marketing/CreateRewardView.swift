//
//  CreateRewardView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct CreateRewardView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateRewardViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // MARK: - Reward Details
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Reward Details", icon: "star.fill")

                        MarketingTextField(
                            label: "Reward Name",
                            placeholder: "e.g., Free Burger",
                            text: $viewModel.rewardName
                        )

                        MarketingTextEditor(
                            label: "Description",
                            placeholder: "Describe the reward...",
                            text: $viewModel.description
                        )

                        MarketingTextField(
                            label: "Points Required",
                            placeholder: "e.g., 100",
                            text: $viewModel.pointsRequired,
                            keyboardType: .numberPad
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Reward Type
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Reward Type", icon: "gift.fill")

                        Picker("Type", selection: $viewModel.rewardType) {
                            Text("Free Item").tag(RewardType.freeItem)
                            Text("Discount").tag(RewardType.discount)
                            Text("Free Delivery").tag(RewardType.freeDelivery)
                            Text("Gift Card").tag(RewardType.giftCard)
                            Text("Merchandise").tag(RewardType.merchandise)
                        }
                        .pickerStyle(.menu)

                        if viewModel.rewardType == .freeItem {
                            Text("Customer can redeem for any menu item")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        } else if viewModel.rewardType == .discount {
                            MarketingTextField(
                                label: "Discount Percentage",
                                placeholder: "e.g., 15",
                                text: $viewModel.discountValue,
                                keyboardType: .numberPad
                            )
                        } else if viewModel.rewardType == .freeDelivery {
                            Text("Free delivery on next order")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        } else if viewModel.rewardType == .giftCard {
                            MarketingTextField(
                                label: "Gift Card Value",
                                placeholder: "e.g., 25",
                                text: $viewModel.discountValue,
                                keyboardType: .numberPad
                            )
                        } else {
                            Text("Physical merchandise item")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Availability
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Availability", icon: "calendar")

                        Toggle("Limited Time Offer", isOn: $viewModel.isLimitedTime)
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.md)

                        if viewModel.isLimitedTime {
                            DatePicker(
                                "Expires On",
                                selection: $viewModel.expirationDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.md)
                        }

                        MarketingTextField(
                            label: "Total Available",
                            placeholder: "e.g., 50 (optional)",
                            text: $viewModel.totalAvailable,
                            keyboardType: .numberPad
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Image
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Reward Image", icon: "photo.fill")

                        MarketingImageUploader(selectedImage: $viewModel.selectedImage)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .navigationTitle("Create Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createReward()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
}

#Preview {
    CreateRewardView()
}
