//
//  AddMenuItemView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import PhotosUI
import Combine

struct AddMenuItemView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddMenuItemViewModel
    let itemToEdit: MenuItem?
    let onSave: (MenuItem) -> Void

    init(itemToEdit: MenuItem? = nil, onSave: @escaping (MenuItem) -> Void) {
        self.itemToEdit = itemToEdit
        self.onSave = onSave
        _viewModel = StateObject(wrappedValue: AddMenuItemViewModel(item: itemToEdit))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Image Upload
                    ImageUploadSection(selectedImage: $viewModel.selectedImage)

                    // Basic Information
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "Basic Information")

                        CustomTextField(
                            label: "Item Name",
                            placeholder: "e.g., Classic Cheeseburger",
                            text: $viewModel.itemName,
                            isRequired: true
                        )

                        CustomTextEditor(
                            label: "Description",
                            placeholder: "Describe your dish...",
                            text: $viewModel.description,
                            isRequired: true
                        )

                        HStack(spacing: Spacing.md) {
                            CustomTextField(
                                label: "Price",
                                placeholder: "$0.00",
                                text: $viewModel.price,
                                keyboardType: .decimalPad,
                                isRequired: true
                            )

                            CustomPicker(
                                label: "Category",
                                selection: $viewModel.selectedCategory,
                                options: viewModel.categories,
                                isRequired: true
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Preparation Details
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "Preparation Details")

                        HStack(spacing: Spacing.md) {
                            CustomTextField(
                                label: "Prep Time (min)",
                                placeholder: "15",
                                text: $viewModel.prepTime,
                                keyboardType: .numberPad
                            )

                            CustomTextField(
                                label: "Calories",
                                placeholder: "720",
                                text: $viewModel.calories,
                                keyboardType: .numberPad
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Availability
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "Availability")

                        ToggleRow(
                            title: "Available for Ordering",
                            icon: "checkmark.circle.fill",
                            isOn: $viewModel.isAvailable
                        )

                        ToggleRow(
                            title: "Featured Item",
                            icon: "star.fill",
                            isOn: $viewModel.isFeatured
                        )
                    }
                    .padding(.horizontal)

                    // Dietary Information
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "Dietary Tags")

                        DietaryTagsSection(selectedTags: $viewModel.dietaryTags)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .navigationTitle(itemToEdit == nil ? "Add Menu Item" : "Edit Menu Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(itemToEdit == nil ? "Save" : "Update") {
                        if let menuItem = viewModel.createMenuItem() {
                            onSave(menuItem)
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
}

// MARK: - Components

struct ImageUploadSection: View {
    @Binding var selectedImage: UIImage?
    @State private var showImagePicker = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(CornerRadius.lg)
            } else {
                Button(action: { showImagePicker = true }) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("Add Photo")
                            .font(AppFonts.headline)

                        Text("Tap to upload image")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.surfaceSecondary)
                    .cornerRadius(CornerRadius.lg)
                }
            }

            if selectedImage != nil {
                Button(action: { showImagePicker = true }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Change Photo")
                    }
                    .font(AppFonts.subheadline)
                    .foregroundColor(.brandPrimary)
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
}

struct CustomTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isRequired: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(label)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)

                if isRequired {
                    Text("*")
                        .foregroundColor(.error)
                }

                Spacer()
            }

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(Color.surfaceSecondary)
                .cornerRadius(CornerRadius.md)
        }
    }
}

struct CustomTextEditor: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(label)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)

                if isRequired {
                    Text("*")
                        .foregroundColor(.error)
                }

                Spacer()
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $text)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color.surfaceSecondary)
                    .cornerRadius(CornerRadius.md)
            }
        }
    }
}

struct CustomPicker: View {
    let label: String
    @Binding var selection: String
    let options: [String]
    var isRequired: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(label)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)

                if isRequired {
                    Text("*")
                        .foregroundColor(.error)
                }

                Spacer()
            }

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.surfaceSecondary)
                .cornerRadius(CornerRadius.md)
            }
        }
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppFonts.title3)
            .fontWeight(.bold)
    }
}

struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isOn ? .success : .secondary)
                .frame(width: 24)

            Text(title)
                .font(AppFonts.body)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppShadow.sm, radius: 2, y: 1)
    }
}

struct DietaryTagsSection: View {
    @Binding var selectedTags: Set<String>

    let tags = ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Nut-Free", "Spicy", "Keto"]

    var body: some View {
        FlowLayout(spacing: Spacing.sm) {
            ForEach(tags, id: \.self) { tag in
                TagButton(
                    title: tag,
                    isSelected: selectedTags.contains(tag)
                ) {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        selectedTags.insert(tag)
                    }
                }
            }
        }
    }
}

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.subheadline)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.success : Color.surfaceSecondary)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.height }.reduce(0, +) + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var point = bounds.origin
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)

        for row in rows {
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: point.x + item.x, y: point.y),
                    proposal: ProposedViewSize(width: item.width, height: row.height)
                )
            }
            point.y += row.height + spacing
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && !currentRow.items.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                x = 0
            }

            currentRow.items.append(RowItem(index: index, x: x, width: size.width))
            currentRow.height = max(currentRow.height, size.height)
            x += size.width + spacing
        }

        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    struct Row {
        var items: [RowItem] = []
        var height: CGFloat = 0
    }

    struct RowItem {
        let index: Int
        let x: CGFloat
        let width: CGFloat
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
    }
}

#Preview {
    AddMenuItemView(onSave: { _ in })
}
