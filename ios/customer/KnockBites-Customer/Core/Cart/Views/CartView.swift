//
//  CartView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct CartView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var showCheckout = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                if cartViewModel.isEmpty {
                    EmptyStateView(
                        icon: "cart",
                        title: "Your Cart is Empty",
                        message: "Add some delicious items to get started!",
                        actionTitle: "Browse Menu",
                        action: { dismiss() }
                    )
                } else {
                    VStack(spacing: 0) {
                        // Cart Items
                        ScrollView {
                            VStack(spacing: Spacing.md) {
                                ForEach(cartViewModel.items) { item in
                                    CartItemRow(item: item)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                                            removal: .move(edge: .trailing).combined(with: .opacity)
                                        ))
                                }
                            }
                            .padding()
                            .padding(.bottom, 220) // Space for summary
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: cartViewModel.items.count)
                        }

                        Spacer()

                        // Order Summary
                        VStack(spacing: 0) {
                            Divider()

                            VStack(spacing: Spacing.md) {
                                HStack {
                                    Text("Subtotal")
                                        .font(AppFonts.body)
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    Text(cartViewModel.formattedSubtotal)
                                        .font(AppFonts.body)
                                        .foregroundColor(.textPrimary)
                                }

                                HStack {
                                    Text("Tax (8%)")
                                        .font(AppFonts.body)
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    Text(cartViewModel.formattedTax)
                                        .font(AppFonts.body)
                                        .foregroundColor(.textPrimary)
                                }

                                Divider()

                                HStack {
                                    Text("Total")
                                        .font(AppFonts.title3)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Text(cartViewModel.formattedTotal)
                                        .font(AppFonts.title3)
                                        .foregroundColor(.brandPrimary)
                                }
                            }
                            .padding()
                            .background(Color.surface)

                            // Checkout Button
                            CustomButton(
                                title: "Proceed to Checkout",
                                action: { showCheckout = true },
                                style: .primary,
                                isDisabled: cartViewModel.selectedStore == nil
                            )
                            .padding()
                            .background(Color.surface)

                            if cartViewModel.selectedStore == nil {
                                Text("Please select a store to continue")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.error)
                                    .padding(.bottom, Spacing.sm)
                            }
                        }
                        .background(Color.surface.shadow(color: Color.black.opacity(0.1), radius: 8, y: -4))
                    }
                }
            }
            .navigationTitle("Cart (\(cartViewModel.itemCount))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                if !cartViewModel.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            cartViewModel.clearCart()
                        }
                        .foregroundColor(.error)
                    }
                }
            }
            .sheet(isPresented: $showCheckout) {
                CheckoutView()
            }
        }
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    let item: CartItem
    @EnvironmentObject var cartViewModel: CartViewModel

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Image
            AsyncImage(url: URL(string: item.menuItem.imageURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    // Gradient placeholder
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: gradientColorsFor(item.menuItem)),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Text(String(item.menuItem.name.prefix(1)).uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(CornerRadius.sm)
            .clipped()

            // Content
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Name
                Text(item.menuItem.name)
                    .font(AppFonts.headline)
                    .foregroundColor(.textPrimary)

                // Customizations
                if !item.selectedOptions.isEmpty {
                    ForEach(Array(item.selectedOptions.keys), id: \.self) { groupId in
                        if let group = item.menuItem.customizationGroups.first(where: { $0.id == groupId }),
                           let optionIds = item.selectedOptions[groupId] {
                            let options = group.options.filter { optionIds.contains($0.id) }
                            Text(options.map { $0.name }.joined(separator: ", "))
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }

                // Special Instructions
                if let instructions = item.specialInstructions, !instructions.isEmpty {
                    Text("Note: \(instructions)")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                        .italic()
                        .lineLimit(2)
                }

                Spacer()

                // Quantity and Price
                HStack {
                    // Quantity Controls
                    HStack(spacing: Spacing.sm) {
                        Button(action: { cartViewModel.updateQuantity(for: item, quantity: item.quantity - 1) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(item.quantity > 1 ? .brandPrimary : .gray)
                        }
                        .disabled(item.quantity <= 1)

                        Text("\(item.quantity)")
                            .font(AppFonts.body)
                            .foregroundColor(.textPrimary)
                            .frame(minWidth: 20)

                        Button(action: { cartViewModel.updateQuantity(for: item, quantity: item.quantity + 1) }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.brandPrimary)
                        }
                    }

                    Spacer()

                    // Price
                    Text(item.formattedTotalPrice)
                        .font(AppFonts.headline)
                        .foregroundColor(.brandPrimary)
                }
            }

            // Remove Button
            Button(action: { cartViewModel.removeItem(item) }) {
                Image(systemName: "trash")
                    .foregroundColor(.error)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }

    private func gradientColorsFor(_ item: MenuItem) -> [Color] {
        // Generate colors based on category ID for consistency
        let categoryHash = item.categoryId.hashValue
        let colorSets: [[Color]] = [
            [Color(red: 0.95, green: 0.35, blue: 0.24), Color(red: 0.96, green: 0.56, blue: 0.24)], // Red-Orange
            [Color(red: 0.35, green: 0.67, blue: 0.95), Color(red: 0.45, green: 0.82, blue: 0.95)], // Blue
            [Color(red: 0.67, green: 0.35, blue: 0.95), Color(red: 0.82, green: 0.45, blue: 0.95)], // Purple
            [Color(red: 0.35, green: 0.95, blue: 0.67), Color(red: 0.45, green: 0.95, blue: 0.82)], // Green
            [Color(red: 0.95, green: 0.67, blue: 0.35), Color(red: 0.95, green: 0.82, blue: 0.45)], // Orange-Yellow
            [Color(red: 0.95, green: 0.35, blue: 0.67), Color(red: 0.95, green: 0.45, blue: 0.82)]  // Pink
        ]

        return colorSets[abs(categoryHash) % colorSets.count]
    }
}

#Preview {
    let cartViewModel = CartViewModel()
    let mockItems = MockDataService.shared.getMenuItems()

    cartViewModel.addItem(menuItem: mockItems[3], quantity: 2)
    cartViewModel.addItem(menuItem: mockItems[0], quantity: 1)

    return CartView()
        .environmentObject(cartViewModel)
}
