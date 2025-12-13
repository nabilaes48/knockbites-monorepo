//
//  EditProgramSettingsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code
//

import SwiftUI

struct EditProgramSettingsView: View {
    @Environment(\.dismiss) var dismiss
    let program: LoyaltyProgram
    let onSaved: () -> Void

    @State private var programName: String
    @State private var pointsPerDollar: String
    @State private var welcomeBonus: String
    @State private var referralBonus: String
    @State private var isActive: Bool
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(program: LoyaltyProgram, onSaved: @escaping () -> Void) {
        self.program = program
        self.onSaved = onSaved
        _programName = State(initialValue: program.name)
        _pointsPerDollar = State(initialValue: String(format: "%.1f", program.pointsPerDollar))
        _welcomeBonus = State(initialValue: "\(program.welcomeBonusPoints)")
        _referralBonus = State(initialValue: "\(program.referralBonusPoints)")
        _isActive = State(initialValue: program.isActive)
    }

    var isValid: Bool {
        !programName.isEmpty &&
        Double(pointsPerDollar) != nil &&
        Int(welcomeBonus) != nil &&
        Int(referralBonus) != nil
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Program Information")) {
                    HStack {
                        Text("Program Name")
                            .font(AppFonts.body)
                        Spacer()
                        TextField("Name", text: $programName)
                            .font(AppFonts.body)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("Points Configuration")) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Points Per Dollar")
                                .font(AppFonts.body)
                            Text("How many points customers earn per $1 spent")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        TextField("1.0", text: $pointsPerDollar)
                            .font(AppFonts.body)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Welcome Bonus")
                                .font(AppFonts.body)
                            Text("Points awarded when joining the program")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        TextField("100", text: $welcomeBonus)
                            .font(AppFonts.body)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Referral Bonus")
                                .font(AppFonts.body)
                            Text("Points awarded for successful referrals")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        TextField("200", text: $referralBonus)
                            .font(AppFonts.body)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                    }
                }

                Section(header: Text("Program Status")) {
                    Toggle(isOn: $isActive) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Active Program")
                                .font(AppFonts.body)
                            Text(isActive ? "Customers can earn and redeem points" : "Program is temporarily disabled")
                                .font(AppFonts.caption)
                                .foregroundColor(isActive ? .success : .textSecondary)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.info)
                            Text("Preview")
                                .font(AppFonts.subheadline)
                                .fontWeight(.semibold)
                        }

                        if let ppd = Double(pointsPerDollar) {
                            Text("• Customer spends $100 → Earns \(Int(ppd * 100)) points")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }

                        if let welcome = Int(welcomeBonus) {
                            Text("• New member → Receives \(welcome) welcome points")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }

                        if let referral = Int(referralBonus) {
                            Text("• Successful referral → Earns \(referral) bonus points")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("Program Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
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

    func saveSettings() {
        guard let ppd = Double(pointsPerDollar),
              let welcome = Int(welcomeBonus),
              let referral = Int(referralBonus) else {
            errorMessage = "Please enter valid numbers for all fields"
            showError = true
            return
        }

        isProcessing = true

        Task {
            do {
                _ = try await SupabaseManager.shared.updateLoyaltyProgram(
                    programId: program.id,
                    name: programName != program.name ? programName : nil,
                    pointsPerDollar: ppd != program.pointsPerDollar ? ppd : nil,
                    welcomeBonusPoints: welcome != program.welcomeBonusPoints ? welcome : nil,
                    referralBonusPoints: referral != program.referralBonusPoints ? referral : nil,
                    isActive: isActive != program.isActive ? isActive : nil
                )

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

#Preview {
    EditProgramSettingsView(
        program: LoyaltyProgram(
            id: 1,
            storeId: 1,
            name: "KnockBites Rewards",
            pointsPerDollar: 1.0,
            welcomeBonusPoints: 100,
            referralBonusPoints: 200,
            isActive: true
        ),
        onSaved: {}
    )
}
