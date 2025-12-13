//
//  MarketingSupportingViews.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

// MARK: - Section Header

struct MarketingSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.warning)
            Text(title)
                .font(AppFonts.headline)
        }
    }
}

// MARK: - Marketing Status Badge

struct MarketingStatusBadge: View {
    let status: CampaignStatus

    var body: some View {
        Text(status.rawValue)
            .font(AppFonts.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(12)
    }
}

// MARK: - Marketing TextField

struct MarketingTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var characterLimit: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(label)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if let limit = characterLimit {
                    Text("\(text.count)/\(limit)")
                        .font(AppFonts.caption)
                        .foregroundColor(text.count > limit ? .error : .textSecondary)
                }
            }

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(Color.surface)
                .cornerRadius(CornerRadius.md)
                .shadow(color: AppShadow.sm, radius: 2)
        }
    }
}

// MARK: - Marketing TextEditor

struct MarketingTextEditor: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var characterLimit: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(label)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if let limit = characterLimit {
                    Text("\(text.count)/\(limit)")
                        .font(AppFonts.caption)
                        .foregroundColor(text.count > limit ? .error : .textSecondary)
                }
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $text)
                    .frame(height: 100)
                    .padding(4)
            }
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: AppShadow.sm, radius: 2)
        }
    }
}

// MARK: - Marketing Image Uploader

struct MarketingImageUploader: View {
    @Binding var selectedImage: UIImage?
    @State private var showImagePicker = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(CornerRadius.md)

                Button("Change Image") {
                    showImagePicker = true
                }
                .foregroundColor(.brandPrimary)
            } else {
                Button(action: { showImagePicker = true }) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(.textSecondary)

                        Text("Upload Image")
                            .font(AppFonts.subheadline)
                            .foregroundColor(.textPrimary)
                    }
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.textSecondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
}
