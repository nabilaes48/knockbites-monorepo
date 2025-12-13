//
//  ReceiptSettingsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/20/25.
//

import SwiftUI

struct ReceiptSettingsView: View {
    @AppStorage("autoPrintReceipts") private var autoPrintReceipts = true
    @AppStorage("printOnStartPrep") private var printOnStartPrep = true
    @AppStorage("printOnReady") private var printOnReady = false
    @AppStorage("printOnComplete") private var printOnComplete = false

    @AppStorage("receiptStoreName") private var storeName = "KnockBites Deli"
    @AppStorage("receiptStoreAddress") private var storeAddress = "123 Main Street, Cityville, ST 12345"
    @AppStorage("receiptStorePhone") private var storePhone = "(555) 123-4567"

    @AppStorage("includeMarketingContent") private var includeMarketingContent = true
    @AppStorage("includeLoyaltyPromo") private var includeLoyaltyPromo = true
    @AppStorage("includeSocialMedia") private var includeSocialMedia = true
    @AppStorage("includeReferralPromo") private var includeReferralPromo = true
    @AppStorage("includeReviewRequest") private var includeReviewRequest = true

    @AppStorage("receiptInstagram") private var instagram = "@knockbitesdeli"
    @AppStorage("receiptFacebook") private var facebook = "/KnockBitesDeli"
    @AppStorage("receiptWebsite") private var website = "www.knockbitesdeli.com"

    @State private var showPreview = false
    @State private var isEditing = false

    var body: some View {
        NavigationView {
            List {
                // Auto-Print Settings
                Section(header: Text("Auto-Print Settings")) {
                    Toggle("Enable Auto-Print", isOn: $autoPrintReceipts)
                        .tint(.brandPrimary)

                    if autoPrintReceipts {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Toggle("Print when starting prep", isOn: $printOnStartPrep)
                                .tint(.brandPrimary)
                            Text("Automatically print receipt when clicking 'Start Prep'")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Toggle("Print when order is ready", isOn: $printOnReady)
                                .tint(.brandPrimary)
                            Text("Print receipt when order status changes to 'Ready'")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Toggle("Print when completed", isOn: $printOnComplete)
                                .tint(.brandPrimary)
                            Text("Print final receipt when order is completed")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Store Information
                Section(header: Text("Store Information"), footer: Text("This information appears at the top of every receipt")) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Store Name")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                        TextField("Store Name", text: $storeName)
                            .font(AppFonts.body)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Address")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                        TextField("Address", text: $storeAddress)
                            .font(AppFonts.body)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Phone Number")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                        TextField("Phone", text: $storePhone)
                            .font(AppFonts.body)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)
                    }
                }

                // Marketing Content
                Section(header: Text("Marketing Content"), footer: Text("Promotional content shown on receipts to drive customer engagement")) {
                    Toggle("Include Marketing Content", isOn: $includeMarketingContent)
                        .tint(.brandPrimary)

                    if includeMarketingContent {
                        Toggle("🎉 Loyalty Program Promotion", isOn: $includeLoyaltyPromo)
                            .tint(.brandPrimary)

                        Toggle("📱 Social Media Links", isOn: $includeSocialMedia)
                            .tint(.brandPrimary)

                        Toggle("💵 Referral Program", isOn: $includeReferralPromo)
                            .tint(.brandPrimary)

                        Toggle("⭐ Review Request", isOn: $includeReviewRequest)
                            .tint(.brandPrimary)
                    }
                }

                // Social Media Settings
                if includeMarketingContent && includeSocialMedia {
                    Section(header: Text("Social Media")) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Instagram Handle")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                            TextField("@username", text: $instagram)
                                .font(AppFonts.body)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Facebook Page")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                            TextField("/PageName", text: $facebook)
                                .font(AppFonts.body)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Website")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                            TextField("www.example.com", text: $website)
                                .font(AppFonts.body)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                        }
                    }
                }

                // Actions
                Section {
                    Button(action: { showPreview = true }) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.brandPrimary)
                            Text("Preview Receipt")
                                .foregroundColor(.brandPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: resetToDefaults) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.warning)
                            Text("Reset to Defaults")
                                .foregroundColor(.warning)
                        }
                    }
                }
            }
            .navigationTitle("Receipt Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPreview) {
                ReceiptPreviewView(settings: currentSettings())
            }
        }
    }

    private func resetToDefaults() {
        autoPrintReceipts = true
        printOnStartPrep = true
        printOnReady = false
        printOnComplete = false

        storeName = "KnockBites Deli"
        storeAddress = "123 Main Street, Cityville, ST 12345"
        storePhone = "(555) 123-4567"

        includeMarketingContent = true
        includeLoyaltyPromo = true
        includeSocialMedia = true
        includeReferralPromo = true
        includeReviewRequest = true

        instagram = "@knockbitesdeli"
        facebook = "/KnockBitesDeli"
        website = "www.knockbitesdeli.com"
    }

    private func currentSettings() -> ReceiptSettings {
        ReceiptSettings(
            autoPrintReceipts: autoPrintReceipts,
            printOnStartPrep: printOnStartPrep,
            printOnReady: printOnReady,
            printOnComplete: printOnComplete,
            storeName: storeName,
            storeAddress: storeAddress,
            storePhone: storePhone,
            includeMarketingContent: includeMarketingContent,
            includeLoyaltyPromo: includeLoyaltyPromo,
            includeSocialMedia: includeSocialMedia,
            includeReferralPromo: includeReferralPromo,
            includeReviewRequest: includeReviewRequest,
            instagram: instagram,
            facebook: facebook,
            website: website
        )
    }
}

// MARK: - Receipt Settings Model

struct ReceiptSettings {
    let autoPrintReceipts: Bool
    let printOnStartPrep: Bool
    let printOnReady: Bool
    let printOnComplete: Bool

    let storeName: String
    let storeAddress: String
    let storePhone: String

    let includeMarketingContent: Bool
    let includeLoyaltyPromo: Bool
    let includeSocialMedia: Bool
    let includeReferralPromo: Bool
    let includeReviewRequest: Bool

    let instagram: String
    let facebook: String
    let website: String

    static var current: ReceiptSettings {
        ReceiptSettings(
            autoPrintReceipts: UserDefaults.standard.bool(forKey: "autoPrintReceipts"),
            printOnStartPrep: UserDefaults.standard.bool(forKey: "printOnStartPrep"),
            printOnReady: UserDefaults.standard.bool(forKey: "printOnReady"),
            printOnComplete: UserDefaults.standard.bool(forKey: "printOnComplete"),
            storeName: UserDefaults.standard.string(forKey: "receiptStoreName") ?? "KnockBites Deli",
            storeAddress: UserDefaults.standard.string(forKey: "receiptStoreAddress") ?? "123 Main Street, Cityville, ST 12345",
            storePhone: UserDefaults.standard.string(forKey: "receiptStorePhone") ?? "(555) 123-4567",
            includeMarketingContent: UserDefaults.standard.bool(forKey: "includeMarketingContent"),
            includeLoyaltyPromo: UserDefaults.standard.bool(forKey: "includeLoyaltyPromo"),
            includeSocialMedia: UserDefaults.standard.bool(forKey: "includeSocialMedia"),
            includeReferralPromo: UserDefaults.standard.bool(forKey: "includeReferralPromo"),
            includeReviewRequest: UserDefaults.standard.bool(forKey: "includeReviewRequest"),
            instagram: UserDefaults.standard.string(forKey: "receiptInstagram") ?? "@knockbitesdeli",
            facebook: UserDefaults.standard.string(forKey: "receiptFacebook") ?? "/KnockBitesDeli",
            website: UserDefaults.standard.string(forKey: "receiptWebsite") ?? "www.knockbitesdeli.com"
        )
    }
}

// MARK: - Receipt Preview

struct ReceiptPreviewView: View {
    let settings: ReceiptSettings
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(receiptPreview)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                }
            }
            .background(Color(.systemGray6))
            .navigationTitle("Receipt Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var receiptPreview: String {
        var preview = ""

        // Header
        preview += centerText(settings.storeName.uppercased(), width: 48) + "\n"
        preview += centerText(settings.storeAddress, width: 48) + "\n"
        preview += centerText(settings.storePhone, width: 48) + "\n"
        preview += String(repeating: "-", count: 48) + "\n\n"

        // Order info
        preview += "Order #: ORD-SAMPLE123\n"
        preview += "Date: Nov 20, 2025\n"
        preview += "Time: 10:25 AM\n"
        preview += "Customer: Sample Customer\n"
        preview += String(repeating: "-", count: 48) + "\n\n"

        // Items
        preview += "YOUR ORDER\n\n"
        preview += "2x  Bacon, Egg & Cheese            $6.99\n"
        preview += "  • Extra bacon\n\n"
        preview += String(repeating: "-", count: 48) + "\n\n"

        // Pricing
        preview += "Subtotal:                          $13.98\n"
        preview += "Tax (8%):                           $1.12\n"
        preview += String(repeating: "=", count: 48) + "\n"
        preview += "TOTAL:                             $15.10\n"
        preview += String(repeating: "=", count: 48) + "\n\n"

        // Marketing
        if settings.includeMarketingContent {
            if settings.includeLoyaltyPromo {
                preview += centerText("🎉 JOIN OUR REWARDS PROGRAM! 🎉", width: 48) + "\n"
                preview += centerText("Earn points with every purchase!", width: 48) + "\n"
                preview += centerText("Get FREE food & exclusive offers", width: 48) + "\n"
                preview += String(repeating: "-", count: 48) + "\n\n"
            }

            if settings.includeSocialMedia {
                preview += centerText("FOLLOW US FOR DEALS!", width: 48) + "\n"
                preview += centerText("Instagram: \(settings.instagram)", width: 48) + "\n"
                preview += centerText("Facebook: \(settings.facebook)", width: 48) + "\n"
                preview += centerText("Web: \(settings.website)", width: 48) + "\n"
                preview += String(repeating: "-", count: 48) + "\n\n"
            }

            if settings.includeReferralPromo {
                preview += centerText("REFER A FRIEND!", width: 48) + "\n"
                preview += centerText("You & your friend both get", width: 48) + "\n"
                preview += centerText("$5 OFF your next order!", width: 48) + "\n"
                preview += String(repeating: "-", count: 48) + "\n\n"
            }

            if settings.includeReviewRequest {
                preview += centerText("How did we do?", width: 48) + "\n"
                preview += centerText("Leave us a review on Google!", width: 48) + "\n"
                preview += String(repeating: "-", count: 48) + "\n\n"
            }
        }

        // Thank you
        preview += centerText("THANK YOU!", width: 48) + "\n"
        preview += centerText("See you soon!", width: 48) + "\n"
        preview += centerText("Enjoy your food!", width: 48) + "\n\n"

        return preview
    }

    private func centerText(_ text: String, width: Int) -> String {
        let padding = max(0, width - text.count) / 2
        return String(repeating: " ", count: padding) + text
    }
}

#Preview {
    ReceiptSettingsView()
}
