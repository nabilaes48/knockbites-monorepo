//
//  OrderDetailView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @EnvironmentObject var cartViewModel: CartViewModel
    @StateObject private var viewModel = OrderViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showReorderAlert = false
    @State private var showCancelAlert = false
    @State private var isCancelling = false
    @State private var remainingTime: TimeInterval?
    @State private var timer: Timer?

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Order Header
                        VStack(spacing: Spacing.md) {
                            Text("Order #\(order.orderNumber)")
                                .font(AppFonts.largeTitle)
                                .foregroundColor(.textPrimary)

                            OrderStatusBadge(status: order.status)

                            VStack(spacing: Spacing.xs) {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                    Text("Placed on")
                                        .font(AppFonts.caption)
                                    Text(order.createdAt, style: .date)
                                        .font(AppFonts.caption)
                                }
                                .foregroundColor(.textSecondary)

                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                    Text("at")
                                        .font(AppFonts.caption)
                                    Text(order.createdAt, style: .time)
                                        .font(AppFonts.caption)
                                }
                                .foregroundColor(.textSecondary)
                            }

                            if let estimatedTime = order.estimatedReadyTime {
                                VStack(spacing: Spacing.xs) {
                                    Text("Estimated Ready Time")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.textSecondary)
                                    Text(estimatedTime, style: .time)
                                        .font(AppFonts.headline)
                                        .foregroundColor(.brandPrimary)
                                }
                                .padding(.top, Spacing.sm)
                            }
                        }
                        .padding(.top, Spacing.xl)

                        // Cancellation Warning
                        if viewModel.canCancelOrder(order) {
                            VStack(spacing: Spacing.md) {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.warning)
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text("Cancellation Window")
                                            .font(AppFonts.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.textPrimary)

                                        if let remaining = remainingTime {
                                            Text("You can cancel this order for \(formatTime(remaining)) more")
                                                .font(AppFonts.caption)
                                                .foregroundColor(.textSecondary)
                                        }
                                    }
                                    Spacer()
                                }

                                CustomButton(
                                    title: isCancelling ? "Cancelling..." : "Cancel Order",
                                    action: { showCancelAlert = true },
                                    style: .danger,
                                    isDisabled: isCancelling,
                                    icon: "xmark.circle"
                                )
                            }
                            .padding()
                            .background(Color.warning.opacity(0.1))
                            .cornerRadius(CornerRadius.md)
                            .padding(.horizontal)
                        }

                        // Store Information
                        // TODO: Store must come from StoreViewModel or order.storeId
                        if let store = order.store {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Store Location")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal)

                                VStack(spacing: Spacing.md) {
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "storefront.fill")
                                            .foregroundColor(.brandPrimary)
                                        Text(store.name)
                                            .font(AppFonts.body)
                                            .foregroundColor(.textPrimary)
                                        Spacer()
                                    }

                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.brandPrimary)
                                        Text(store.address)
                                            .font(AppFonts.caption)
                                            .foregroundColor(.textSecondary)
                                        Spacer()
                                    }

                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(.brandPrimary)
                                        Text(store.phoneNumber)
                                            .font(AppFonts.caption)
                                            .foregroundColor(.textSecondary)
                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(Color.surface)
                                .cornerRadius(CornerRadius.md)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                                .padding(.horizontal)
                            }
                        }

                        // Order Type
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Order Type")
                                .font(AppFonts.headline)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal)

                            HStack(spacing: Spacing.sm) {
                                Image(systemName: order.orderType.icon)
                                    .foregroundColor(.brandPrimary)
                                Text(order.orderType.rawValue)
                                    .font(AppFonts.body)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.md)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                            .padding(.horizontal)
                        }

                        // Order Items
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Order Items")
                                .font(AppFonts.headline)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal)

                            VStack(spacing: Spacing.md) {
                                ForEach(order.items) { item in
                                    OrderDetailItemRow(item: item)
                                }
                            }
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.md)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                            .padding(.horizontal)
                        }

                        // Order Summary
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Payment Summary")
                                .font(AppFonts.headline)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal)

                            VStack(spacing: Spacing.sm) {
                                HStack {
                                    Text("Subtotal")
                                        .font(AppFonts.body)
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    Text(order.formattedSubtotal)
                                        .font(AppFonts.body)
                                        .foregroundColor(.textPrimary)
                                }

                                HStack {
                                    Text("Tax")
                                        .font(AppFonts.body)
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    Text(order.formattedTax)
                                        .font(AppFonts.body)
                                        .foregroundColor(.textPrimary)
                                }

                                Divider()

                                HStack {
                                    Text("Total")
                                        .font(AppFonts.title2)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Text(order.formattedTotal)
                                        .font(AppFonts.title2)
                                        .foregroundColor(.brandPrimary)
                                }
                            }
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.md)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                            .padding(.horizontal)
                        }

                        // Reorder Button
                        CustomButton(
                            title: "Reorder",
                            action: { showReorderAlert = true },
                            style: .primary,
                            icon: "arrow.clockwise"
                        )
                        .padding(.horizontal)
                        .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Reorder Items?", isPresented: $showReorderAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Add to Cart") {
                    reorderItems()
                }
            } message: {
                Text("This will add all items from this order to your cart.")
            }
            .alert("Cancel Order?", isPresented: $showCancelAlert) {
                Button("No, Keep Order", role: .cancel) {}
                Button("Yes, Cancel", role: .destructive) {
                    cancelOrder()
                }
            } message: {
                Text("Are you sure you want to cancel this order? You will receive a full refund.")
            }
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    private func reorderItems() {
        let items = viewModel.reorder(order)
        for item in items {
            cartViewModel.addItem(
                menuItem: item.menuItem,
                quantity: item.quantity,
                selectedOptions: item.selectedOptions,
                specialInstructions: item.specialInstructions
            )
        }
        dismiss()
    }

    private func cancelOrder() {
        isCancelling = true
        Task {
            do {
                try await viewModel.cancelOrder(order)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCancelling = false
                    ToastManager.shared.show(
                        "Failed to cancel order",
                        icon: "wifi.slash",
                        type: .error
                    )
                }
            }
        }
    }

    private func startTimer() {
        guard viewModel.canCancelOrder(order) else { return }

        // Initial update
        remainingTime = viewModel.remainingCancellationTime(order)

        // Update every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let remaining = viewModel.remainingCancellationTime(order), remaining > 0 {
                remainingTime = remaining
            } else {
                remainingTime = nil
                stopTimer()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Order Detail Item Row
struct OrderDetailItemRow: View {
    let item: CartItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Text("\(item.quantity)×")
                    .font(AppFonts.headline)
                    .foregroundColor(.textSecondary)
                    .frame(width: 35, alignment: .leading)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(item.menuItem.name)
                        .font(AppFonts.headline)
                        .foregroundColor(.textPrimary)

                    // Customizations (each on separate line)
                    if !item.customizationsList.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(item.customizationsList, id: \.self) { customization in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.brandPrimary)
                                        .frame(width: 4, height: 4)
                                    Text(customization)
                                        .font(AppFonts.caption)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                    }

                    // Special instructions
                    if let instructions = item.specialInstructions, !instructions.isEmpty {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "note.text")
                                .font(.caption)
                            Text(instructions)
                                .font(AppFonts.caption)
                        }
                        .foregroundColor(.textSecondary)
                        .padding(.top, 2)
                    }
                }

                Spacer()

                Text(item.formattedTotalPrice)
                    .font(AppFonts.headline)
                    .foregroundColor(.brandPrimary)
            }

            Divider()
                .padding(.top, Spacing.sm)
        }
    }
}

#if DEBUG
#Preview {
    let mockOrder = Order(
        id: "order_1",
        userId: "user_123",
        storeId: "store_1",
        items: [
            CartItem(
                id: "item_1",
                menuItem: MockDataService.shared.getMenuItems()[3],
                quantity: 2,
                selectedOptions: [:],
                specialInstructions: "Extra spicy please"
            ),
            CartItem(
                id: "item_2",
                menuItem: MockDataService.shared.getMenuItems()[5],
                quantity: 1,
                selectedOptions: [:],
                specialInstructions: nil
            )
        ],
        subtotal: 47.97,
        tax: 3.84,
        total: 51.81,
        status: .completed,
        orderType: .pickup,
        createdAt: Date().addingTimeInterval(-7200),
        estimatedReadyTime: Date().addingTimeInterval(-6000),
        orderNumber: "123456",
        scheduledFor: nil
    )

    return OrderDetailView(order: mockOrder)
        .environmentObject(CartViewModel())
}
#endif
