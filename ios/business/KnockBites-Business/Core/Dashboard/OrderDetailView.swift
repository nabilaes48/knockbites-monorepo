//
//  OrderDetailView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct OrderDetailView: View {
    @Environment(\.dismiss) var dismiss
    let order: Order
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Order Header
                    VStack(spacing: Spacing.md) {
                        Text("Order #\(order.orderNumber)")
                            .font(AppFonts.title2)
                            .foregroundColor(.textPrimary)

                        StatusBadge(status: order.status)

                        HStack(spacing: Spacing.xl) {
                            VStack {
                                Text("Ordered")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.textSecondary)
                                Text(order.createdAt, style: .time)
                                    .font(AppFonts.subheadline)
                            }

                            if let estimatedReadyTime = order.estimatedReadyTime {
                                VStack {
                                    Text("Ready By")
                                        .font(AppFonts.caption)
                                        .foregroundColor(.textSecondary)
                                    Text(estimatedReadyTime, style: .time)
                                        .font(AppFonts.subheadline)
                                }
                            }

                            VStack {
                                Text("Elapsed")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.textSecondary)
                                Text(order.timeElapsedString)
                                    .font(AppFonts.subheadline)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.surfaceSecondary)
                    .cornerRadius(CornerRadius.lg)
                    .padding(.horizontal)

                    // Customer Info
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Customer Information")
                            .font(AppFonts.headline)
                            .foregroundColor(.textPrimary)

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InfoRow(icon: "person.fill", label: "Name", value: order.customerName)
                            InfoRow(icon: "bag.fill", label: "Order Type", value: order.orderType.rawValue)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.lg)
                    .padding(.horizontal)

                    // Order Items
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Order Items")
                            .font(AppFonts.headline)
                            .foregroundColor(.textPrimary)

                        if order.items.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.warning)
                                Text("No items found in this order")
                                    .font(AppFonts.body)
                                    .foregroundColor(.textSecondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.warning.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                        } else {
                            VStack(spacing: Spacing.md) {
                                ForEach(order.items) { item in
                                    OrderItemDetailRow(item: item)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.lg)
                    .padding(.horizontal)

                    // Order Summary
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Order Summary")
                            .font(AppFonts.headline)
                            .foregroundColor(.textPrimary)

                        VStack(spacing: Spacing.sm) {
                            HStack {
                                Text("Subtotal")
                                    .font(AppFonts.body)
                                Spacer()
                                Text(order.formattedSubtotal)
                                    .font(AppFonts.body)
                            }

                            HStack {
                                Text("Tax")
                                    .font(AppFonts.body)
                                Spacer()
                                Text(order.formattedTax)
                                    .font(AppFonts.body)
                            }

                            Divider()

                            HStack {
                                Text("Total")
                                    .font(AppFonts.headline)
                                Spacer()
                                Text(order.formattedTotal)
                                    .font(AppFonts.headline)
                                    .foregroundColor(.brandPrimary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.lg)
                    .padding(.horizontal)

                    // Action Button
                    if let nextStatus = order.status.nextStatus,
                       let buttonTitle = order.status.actionButtonTitle {
                        Button(action: {
                            viewModel.updateOrderStatus(order, newStatus: nextStatus)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: nextStatus.icon)
                                Text(buttonTitle)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(statusColor(for: nextStatus))
                            .foregroundColor(.white)
                            .cornerRadius(CornerRadius.md)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: printReceipt) {
                        Label("Print Receipt", systemImage: "printer")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .received: return .blue
        case .preparing: return .orange
        case .ready: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }

    private func printReceipt() {
        let settings = ReceiptSettings.current

        // Get store information from settings
        let store = Store(
            id: "1",
            name: settings.storeName,
            address: settings.storeAddress,
            phone: settings.storePhone,
            latitude: 40.7128,
            longitude: -74.0060,
            openTime: "09:00",
            closeTime: "21:00",
            daysOpen: [0, 1, 2, 3, 4, 5, 6],
            isActive: true,
            imageURL: nil
        )

        ReceiptService.printReceipt(order: order, store: store, settings: settings)

        // Show confirmation alert
        print("✅ Receipt sent to printer")
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.brandPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
                Text(value)
                    .font(AppFonts.body)
                    .foregroundColor(.textPrimary)
            }
        }
    }
}

// MARK: - Order Item Detail Row
struct OrderItemDetailRow: View {
    let item: CartItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                Text("\(item.quantity)x")
                    .font(AppFonts.headline)
                    .foregroundColor(.brandPrimary)
                    .frame(width: 40, alignment: .leading)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Item name and price on same row
                    HStack {
                        Text(item.menuItem.name)
                            .font(AppFonts.headline)
                            .foregroundColor(.textPrimary)

                        Spacer()

                        Text(String(format: "$%.2f", item.totalPrice))
                            .font(AppFonts.body)
                            .foregroundColor(.textPrimary)
                    }

                    // Customizations on separate lines
                    if !item.customizationSummary.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(item.customizationSummary.components(separatedBy: ", "), id: \.self) { customization in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.brandPrimary)
                                        .frame(width: 6, height: 6)
                                    Text(customization)
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                        .padding(.leading, 4)
                    }

                    // Special instructions highlighted
                    if !item.specialInstructions.isEmpty {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text(item.specialInstructions)
                                .font(AppFonts.subheadline)
                        }
                        .foregroundColor(.warning)
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.warning.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                    }
                }
            }

            Divider()
        }
    }
}

#Preview {
    OrderDetailView(
        order: MockDataService.shared.generateMockOrders(storeId: "store_1")[0],
        viewModel: DashboardViewModel()
    )
}
