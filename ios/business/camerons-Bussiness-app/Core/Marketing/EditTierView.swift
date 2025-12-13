//
//  EditTierView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct EditTierView: View {
    @Environment(\.dismiss) var dismiss
    let programId: Int
    let tier: LoyaltyTier?  // nil for create mode
    let onSaved: () -> Void

    @State private var tierName: String
    @State private var minPoints: String
    @State private var discountPercentage: String
    @State private var freeDelivery: Bool
    @State private var prioritySupport: Bool
    @State private var earlyAccessPromos: Bool
    @State private var birthdayRewardPoints: String
    @State private var selectedColor: TierColorOption
    @State private var sortOrder: String

    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var isEditMode: Bool { tier != nil }

    var isValid: Bool {
        !tierName.isEmpty &&
        Int(minPoints) != nil &&
        Double(discountPercentage) != nil &&
        Int(birthdayRewardPoints) != nil &&
        Int(sortOrder) != nil
    }

    init(programId: Int, tier: LoyaltyTier? = nil, onSaved: @escaping () -> Void) {
        self.programId = programId
        self.tier = tier
        self.onSaved = onSaved

        _tierName = State(initialValue: tier?.name ?? "")
        _minPoints = State(initialValue: tier != nil ? "\(tier!.minPoints)" : "0")
        _discountPercentage = State(initialValue: tier != nil ? String(format: "%.1f", tier!.discountPercentage) : "0")
        _freeDelivery = State(initialValue: tier?.freeDelivery ?? false)
        _prioritySupport = State(initialValue: tier?.prioritySupport ?? false)
        _earlyAccessPromos = State(initialValue: tier?.earlyAccessPromos ?? false)
        _birthdayRewardPoints = State(initialValue: tier != nil ? "\(tier!.birthdayRewardPoints)" : "0")
        _sortOrder = State(initialValue: tier != nil ? "\(tier!.sortOrder)" : "1")

        // Find matching color or default to first
        if let tier = tier, let tierColor = tier.tierColor {
            _selectedColor = State(initialValue: TierColorOption.allCases.first(where: { $0.hex == tierColor }) ?? .blue)
        } else {
            _selectedColor = State(initialValue: .blue)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tier Information")) {
                    HStack {
                        Text("Tier Name")
                        Spacer()
                        TextField("e.g., Gold", text: $tierName)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Minimum Points")
                            Text("Points required to reach this tier")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        TextField("500", text: $minPoints)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
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

                Section(header: Text("Tier Color")) {
                    LazyVGrid(columns: [GridItem(), GridItem(), GridItem(), GridItem()], spacing: Spacing.md) {
                        ForEach(TierColorOption.allCases, id: \.self) { colorOption in
                            Button(action: {
                                selectedColor = colorOption
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: colorOption.hex) ?? .gray)
                                        .frame(width: 44, height: 44)

                                    if selectedColor == colorOption {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }

                Section(header: Text("Benefits")) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Discount Percentage")
                            Text("% off all orders")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        TextField("10", text: $discountPercentage)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                            .foregroundColor(.textSecondary)
                    }

                    Toggle("Free Delivery", isOn: $freeDelivery)

                    Toggle("Priority Support", isOn: $prioritySupport)

                    Toggle("Early Access to Promotions", isOn: $earlyAccessPromos)

                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Birthday Reward")
                            Text("Bonus points on customer's birthday")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        TextField("100", text: $birthdayRewardPoints)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("pts")
                            .foregroundColor(.textSecondary)
                    }
                }

                Section(header: Text("Preview")) {
                    TierPreviewCard(
                        name: tierName.isEmpty ? "Tier Name" : tierName,
                        minPoints: Int(minPoints) ?? 0,
                        discountPercentage: Double(discountPercentage) ?? 0,
                        freeDelivery: freeDelivery,
                        prioritySupport: prioritySupport,
                        earlyAccessPromos: earlyAccessPromos,
                        birthdayRewardPoints: Int(birthdayRewardPoints) ?? 0,
                        tierColor: selectedColor.hex
                    )
                }
            }
            .navigationTitle(isEditMode ? "Edit Tier" : "Create Tier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Save" : "Create") {
                        saveTier()
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

    func saveTier() {
        guard let minPts = Int(minPoints),
              let discount = Double(discountPercentage),
              let birthdayPts = Int(birthdayRewardPoints),
              let order = Int(sortOrder) else {
            errorMessage = "Please enter valid numbers for all fields"
            showError = true
            return
        }

        isProcessing = true

        Task {
            do {
                if let existingTier = tier {
                    // Update existing tier
                    _ = try await SupabaseManager.shared.updateLoyaltyTier(
                        tierId: existingTier.id,
                        name: tierName != existingTier.name ? tierName : nil,
                        minPoints: minPts != existingTier.minPoints ? minPts : nil,
                        discountPercentage: discount != existingTier.discountPercentage ? discount : nil,
                        freeDelivery: freeDelivery != existingTier.freeDelivery ? freeDelivery : nil,
                        prioritySupport: prioritySupport != existingTier.prioritySupport ? prioritySupport : nil,
                        earlyAccessPromos: earlyAccessPromos != existingTier.earlyAccessPromos ? earlyAccessPromos : nil,
                        birthdayRewardPoints: birthdayPts != existingTier.birthdayRewardPoints ? birthdayPts : nil,
                        tierColor: selectedColor.hex != existingTier.tierColor ? selectedColor.hex : nil,
                        sortOrder: order != existingTier.sortOrder ? order : nil
                    )
                } else {
                    // Create new tier
                    _ = try await SupabaseManager.shared.createLoyaltyTier(
                        programId: programId,
                        name: tierName,
                        minPoints: minPts,
                        discountPercentage: discount,
                        freeDelivery: freeDelivery,
                        prioritySupport: prioritySupport,
                        earlyAccessPromos: earlyAccessPromos,
                        birthdayRewardPoints: birthdayPts,
                        tierColor: selectedColor.hex,
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

// MARK: - Tier Color Options

enum TierColorOption: String, CaseIterable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case blue = "Blue"
    case purple = "Purple"
    case green = "Green"
    case red = "Red"

    var hex: String {
        switch self {
        case .bronze: return "#CD7F32"
        case .silver: return "#C0C0C0"
        case .gold: return "#FFD700"
        case .platinum: return "#E5E4E2"
        case .blue: return "#007AFF"
        case .purple: return "#AF52DE"
        case .green: return "#34C759"
        case .red: return "#FF3B30"
        }
    }
}

// MARK: - Tier Preview Card

struct TierPreviewCard: View {
    let name: String
    let minPoints: Int
    let discountPercentage: Double
    let freeDelivery: Bool
    let prioritySupport: Bool
    let earlyAccessPromos: Bool
    let birthdayRewardPoints: Int
    let tierColor: String

    var color: Color {
        Color(hex: tierColor) ?? .brandPrimary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Tier Header
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "star.fill")
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(name)
                        .font(AppFonts.headline)
                        .fontWeight(.bold)

                    Text("\(minPoints)+ points")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()
            }

            Divider()

            // Benefits
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if discountPercentage > 0 {
                    BenefitPreviewRow(
                        icon: "percent",
                        text: "\(Int(discountPercentage))% off all orders"
                    )
                }

                BenefitPreviewRow(
                    icon: "shippingbox.fill",
                    text: "Free delivery",
                    isEnabled: freeDelivery
                )

                BenefitPreviewRow(
                    icon: "headphones",
                    text: "Priority support",
                    isEnabled: prioritySupport
                )

                BenefitPreviewRow(
                    icon: "star.fill",
                    text: "Early access to promos",
                    isEnabled: earlyAccessPromos
                )

                if birthdayRewardPoints > 0 {
                    BenefitPreviewRow(
                        icon: "gift.fill",
                        text: "\(birthdayRewardPoints) birthday bonus points"
                    )
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
    }
}

struct BenefitPreviewRow: View {
    let icon: String
    let text: String
    var isEnabled: Bool = true

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .success : .textSecondary)
                .frame(width: 16)
                .font(.caption)

            Text(text)
                .font(AppFonts.caption)
                .foregroundColor(isEnabled ? .textPrimary : .textSecondary)
                .strikethrough(!isEnabled)
        }
    }
}

#Preview {
    EditTierView(programId: 1, onSaved: {})
}
