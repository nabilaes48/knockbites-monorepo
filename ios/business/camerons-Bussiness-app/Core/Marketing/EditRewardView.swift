//
//  EditRewardView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct EditRewardView: View {
    @Environment(\.dismiss) var dismiss
    let programId: Int
    let reward: LoyaltyReward?
    let onSaved: () -> Void

    @State private var rewardName: String
    @State private var rewardDescription: String
    @State private var pointsCost: String
    @State private var selectedRewardType: RewardType
    @State private var rewardValue: String
    @State private var isActive: Bool
    @State private var hasStock: Bool
    @State private var stockQuantity: String
    @State private var sortOrder: String

    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var isEditMode: Bool { reward != nil }

    var isValid: Bool {
        !rewardName.isEmpty &&
        Int(pointsCost) != nil &&
        !rewardValue.isEmpty &&
        Int(sortOrder) != nil &&
        (!hasStock || Int(stockQuantity) != nil)
    }

    init(programId: Int, reward: LoyaltyReward?, onSaved: @escaping () -> Void) {
        self.programId = programId
        self.reward = reward
        self.onSaved = onSaved

        _rewardName = State(initialValue: reward?.name ?? "")
        _rewardDescription = State(initialValue: reward?.description ?? "")
        _pointsCost = State(initialValue: reward != nil ? "\(reward!.pointsCost)" : "")
        _selectedRewardType = State(initialValue: reward?.rewardType ?? .discount)
        _rewardValue = State(initialValue: reward?.rewardValue ?? "")
        _isActive = State(initialValue: reward?.isActive ?? true)
        _hasStock = State(initialValue: reward?.stockQuantity != nil)
        _stockQuantity = State(initialValue: reward?.stockQuantity != nil ? "\(reward!.stockQuantity!)" : "")
        _sortOrder = State(initialValue: reward != nil ? "\(reward!.sortOrder)" : "1")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    HStack {
                        Text("Reward Name")
                        Spacer()
                        TextField("e.g., Free Burger", text: $rewardName)
                            .multilineTextAlignment(.trailing)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Description (Optional)")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)

                        TextField("What customers get...", text: $rewardDescription)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Points Cost")
                            Text("Points required to redeem")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        TextField("500", text: $pointsCost)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section(header: Text("Reward Type")) {
                    Picker("Type", selection: $selectedRewardType) {
                        ForEach(RewardType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .onChange(of: selectedRewardType) { _ in
                        // Update placeholder text based on type
                        if rewardValue.isEmpty {
                            rewardValue = getPlaceholderValue()
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Reward Value")
                            Text(getValueHintText())
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        TextField(getPlaceholderValue(), text: $rewardValue)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                }

                Section(header: Text("Availability")) {
                    Toggle(isOn: $isActive) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Active")
                            Text(isActive ? "Customers can redeem this reward" : "Hidden from customers")
                                .font(AppFonts.caption)
                                .foregroundColor(isActive ? .success : .textSecondary)
                        }
                    }

                    Toggle(isOn: $hasStock) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Limited Stock")
                            Text("Track inventory for this reward")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    if hasStock {
                        HStack {
                            Text("Stock Quantity")
                            Spacer()
                            TextField("100", text: $stockQuantity)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }

                    HStack {
                        Text("Sort Order")
                        Spacer()
                        TextField("1", text: $sortOrder)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section(header: Text("Preview")) {
                    RewardPreviewCard(
                        name: rewardName.isEmpty ? "Reward Name" : rewardName,
                        description: rewardDescription.isEmpty ? nil : rewardDescription,
                        pointsCost: Int(pointsCost) ?? 0,
                        rewardType: selectedRewardType,
                        rewardValue: rewardValue.isEmpty ? getPlaceholderValue() : rewardValue,
                        stockQuantity: hasStock ? (Int(stockQuantity) ?? 0) : nil
                    )
                }
            }
            .navigationTitle(isEditMode ? "Edit Reward" : "Create Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Save" : "Create") {
                        saveReward()
                    }
                    .fontWeight(.bold)
                    .disabled(!isValid || isProcessing)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    func getPlaceholderValue() -> String {
        switch selectedRewardType {
        case .discount: return "10% or $5"
        case .freeItem: return "Burger"
        case .freeDelivery: return "Free Delivery"
        case .giftCard: return "$25"
        case .merchandise: return "T-Shirt"
        }
    }

    func getValueHintText() -> String {
        switch selectedRewardType {
        case .discount: return "e.g., '10%' or '$5 off'"
        case .freeItem: return "e.g., 'Large Fries' or 'Dessert'"
        case .freeDelivery: return "Usually just 'Free Delivery'"
        case .giftCard: return "e.g., '$10' or '$25'"
        case .merchandise: return "e.g., 'T-Shirt' or 'Mug'"
        }
    }

    func saveReward() {
        guard let points = Int(pointsCost),
              let order = Int(sortOrder) else {
            errorMessage = "Please enter valid numbers for points and sort order"
            showError = true
            return
        }

        let stock = hasStock ? Int(stockQuantity) : nil
        if hasStock && stock == nil {
            errorMessage = "Please enter a valid stock quantity"
            showError = true
            return
        }

        isProcessing = true

        Task {
            do {
                if let existingReward = reward {
                    _ = try await SupabaseManager.shared.updateLoyaltyReward(
                        rewardId: existingReward.id,
                        name: rewardName != existingReward.name ? rewardName : nil,
                        description: rewardDescription != (existingReward.description ?? "") ? rewardDescription : nil,
                        pointsCost: points != existingReward.pointsCost ? points : nil,
                        rewardType: selectedRewardType.rawValue != existingReward.rewardType.rawValue ? selectedRewardType.rawValue : nil,
                        rewardValue: rewardValue != existingReward.rewardValue ? rewardValue : nil,
                        isActive: isActive != existingReward.isActive ? isActive : nil,
                        stockQuantity: stock != existingReward.stockQuantity ? stock : nil,
                        sortOrder: order != existingReward.sortOrder ? order : nil
                    )
                } else {
                    _ = try await SupabaseManager.shared.createLoyaltyReward(
                        programId: programId,
                        name: rewardName,
                        description: rewardDescription.isEmpty ? nil : rewardDescription,
                        pointsCost: points,
                        rewardType: selectedRewardType.rawValue,
                        rewardValue: rewardValue,
                        imageUrl: nil,
                        isActive: isActive,
                        stockQuantity: stock,
                        sortOrder: order
                    )
                }

                await MainActor.run {
                    isProcessing = false
                    onSaved()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Reward Preview Card

struct RewardPreviewCard: View {
    let name: String
    let description: String?
    let pointsCost: Int
    let rewardType: RewardType
    let rewardValue: String
    let stockQuantity: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                ZStack {
                    Circle()
                        .fill(rewardType.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: rewardType.icon)
                        .foregroundColor(rewardType.color)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(name)
                        .font(AppFonts.headline)
                        .fontWeight(.bold)

                    Text(rewardType.displayName)
                        .font(AppFonts.caption)
                        .foregroundColor(rewardType.color)
                }

                Spacer()

                VStack(spacing: Spacing.xs) {
                    Text("\(pointsCost)")
                        .font(AppFonts.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.warning)

                    Text("points")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            if let description = description {
                Text(description)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Value")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)

                    Text(rewardValue)
                        .font(AppFonts.subheadline)
                        .fontWeight(.semibold)
                }

                if let stock = stockQuantity {
                    Spacer()

                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        Text("Stock")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)

                        Text("\(stock)")
                            .font(AppFonts.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(rewardType.color.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    EditRewardView(programId: 1, reward: nil, onSaved: {})
}
