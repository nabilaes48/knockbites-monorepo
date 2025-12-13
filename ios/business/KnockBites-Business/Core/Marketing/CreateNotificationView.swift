//
//  CreateNotificationView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct CreateNotificationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateNotificationViewModel()
    let onNotificationSent: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // MARK: - Target Audience
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Target Audience", icon: "person.3.fill")

                        TargetAudienceSelector(
                            selectedAudience: $viewModel.selectedAudience,
                            estimatedReach: viewModel.estimatedReach
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Message Content
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Message Content", icon: "text.bubble.fill")

                        MarketingTextField(
                            label: "Title",
                            placeholder: "e.g., Weekend Special!",
                            text: $viewModel.title,
                            characterLimit: 50
                        )

                        MarketingTextEditor(
                            label: "Message",
                            placeholder: "Write your notification message...",
                            text: $viewModel.message,
                            characterLimit: 150
                        )

                        // Message Preview
                        NotificationPreview(
                            title: viewModel.title,
                            message: viewModel.message
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Call to Action
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Call to Action", icon: "hand.tap.fill")

                        CTASelector(
                            selectedCTA: $viewModel.selectedCTA,
                            customLink: $viewModel.customLink
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Timing
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Timing", icon: "clock.fill")

                        TimingSelector(
                            sendNow: $viewModel.sendNow,
                            scheduledDate: $viewModel.scheduledDate
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Add Image (Optional)
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        MarketingSectionHeader(title: "Image (Optional)", icon: "photo.fill")

                        MarketingImageUploader(selectedImage: $viewModel.selectedImage)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .navigationTitle("Send Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.sendNow ? "Send" : "Schedule") {
                        viewModel.sendNotification {
                            onNotificationSent()
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(!viewModel.isValid || viewModel.isSending)
                }
            }
        }
    }
}

// MARK: - Target Audience Selector

struct TargetAudienceSelector: View {
    @Binding var selectedAudience: AudienceType
    let estimatedReach: Int

    var body: some View {
        VStack(spacing: Spacing.md) {
            ForEach(AudienceType.allCases, id: \.self) { audience in
                AudienceOptionCard(
                    audience: audience,
                    isSelected: selectedAudience == audience
                ) {
                    selectedAudience = audience
                }
            }

            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.brandPrimary)
                Text("Estimated reach: \(estimatedReach) customers")
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.brandPrimary.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
    }
}

struct AudienceOptionCard: View {
    let audience: AudienceType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(audience.title)
                        .font(AppFonts.headline)
                        .foregroundColor(.textPrimary)

                    Text(audience.description)
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                        .font(AppFonts.title3)
                }
            }
            .padding()
            .background(isSelected ? Color.success.opacity(0.1) : Color.surface)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.success : Color.textSecondary.opacity(0.2), lineWidth: 2)
            )
        }
    }
}

// MARK: - Notification Preview

struct NotificationPreview: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Preview")
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "bag.circle.fill")
                        .font(AppFonts.title3)
                        .foregroundColor(.warning)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("KnockBites Business")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)

                        Text("now")
                            .font(AppFonts.caption2)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()
                }

                if !title.isEmpty {
                    Text(title)
                        .font(AppFonts.subheadline)
                        .fontWeight(.semibold)
                }

                if !message.isEmpty {
                    Text(message)
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(3)
                }
            }
            .padding()
            .background(Color.textSecondary.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - CTA Selector

struct CTASelector: View {
    @Binding var selectedCTA: CTAType
    @Binding var customLink: String

    var body: some View {
        VStack(spacing: Spacing.md) {
            Picker("Action", selection: $selectedCTA) {
                ForEach(CTAType.allCases, id: \.self) { cta in
                    Text(cta.title).tag(cta)
                }
            }
            .pickerStyle(.segmented)

            if selectedCTA == .custom {
                MarketingTextField(
                    label: "Custom Link",
                    placeholder: "Enter URL or deep link",
                    text: $customLink
                )
            }

            Text(selectedCTA.description)
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Timing Selector

struct TimingSelector: View {
    @Binding var sendNow: Bool
    @Binding var scheduledDate: Date

    var body: some View {
        VStack(spacing: Spacing.md) {
            Toggle("Send Immediately", isOn: $sendNow)
                .padding()
                .background(Color.surface)
                .cornerRadius(CornerRadius.md)

            if !sendNow {
                DatePicker(
                    "Schedule for",
                    selection: $scheduledDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .padding()
                .background(Color.surface)
                .cornerRadius(CornerRadius.md)
            }
        }
    }
}

#Preview {
    CreateNotificationView(onNotificationSent: {})
}
