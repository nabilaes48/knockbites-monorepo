//
//  OrderTrackingView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct OrderTrackingView: View {
    let order: Order
    @StateObject private var viewModel = OrderViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Order Number Header
                        VStack(spacing: Spacing.sm) {
                            Text("Order #\(order.orderNumber)")
                                .font(AppFonts.largeTitle)
                                .foregroundColor(.textPrimary)

                            // TODO: Inject store from Order object via ViewModel
                            if let store = order.store {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "storefront.fill")
                                        .font(.caption)
                                    Text(store.name)
                                        .font(AppFonts.body)
                                }
                                .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.top, Spacing.xl)

                        // Status Progress Indicator
                        OrderStatusProgressView(currentStatus: viewModel.currentTrackingOrder?.status ?? order.status)
                            .padding(.horizontal)

                        // Estimated Time Card
                        if let estimatedTime = order.estimatedReadyTime,
                           (viewModel.currentTrackingOrder?.status ?? order.status) != .completed {
                            VStack(spacing: Spacing.md) {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.brandPrimary)
                                    Text("Estimated Ready Time")
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(.textSecondary)
                                }

                                Text(estimatedTime, style: .time)
                                    .font(AppFonts.title1)
                                    .foregroundColor(.brandPrimary)

                                Text("We'll notify you when it's ready")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandPrimary.opacity(0.1))
                            .cornerRadius(CornerRadius.lg)
                            .padding(.horizontal)
                        }

                        // Order Items
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Order Items")
                                .font(AppFonts.headline)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal)

                            VStack(spacing: Spacing.sm) {
                                ForEach(order.items) { item in
                                    OrderTrackingItemRow(item: item)
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
                            Text("Order Summary")
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
                                        .font(AppFonts.headline)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Text(order.formattedTotal)
                                        .font(AppFonts.headline)
                                        .foregroundColor(.brandPrimary)
                                }
                            }
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(CornerRadius.md)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                            .padding(.horizontal)
                        }

                        // Store Contact
                        // TODO: Inject store from Order object via ViewModel
                        if let store = order.store {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Store Information")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal)

                                VStack(spacing: Spacing.md) {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.brandPrimary)
                                        Text(store.address)
                                            .font(AppFonts.caption)
                                            .foregroundColor(.textSecondary)
                                        Spacer()
                                    }

                                    HStack(spacing: Spacing.md) {
                                        Button(action: { callStore(store.phoneNumber) }) {
                                            HStack {
                                                Image(systemName: "phone.fill")
                                                Text("Call Store")
                                            }
                                            .font(AppFonts.subheadline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.brandPrimary)
                                            .cornerRadius(CornerRadius.md)
                                        }

                                        Button(action: { openMaps(store.coordinates) }) {
                                            HStack {
                                                Image(systemName: "map.fill")
                                                Text("Directions")
                                            }
                                            .font(AppFonts.subheadline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.brandSecondary)
                                            .cornerRadius(CornerRadius.md)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.surface)
                                .cornerRadius(CornerRadius.md)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, Spacing.xl)
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
            .onAppear {
                viewModel.startTracking(order: order)
            }
            .onDisappear {
                viewModel.stopTracking()
            }
        }
    }

    private func callStore(_ phone: String) {
        if let url = URL(string: "tel://\(phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())") {
            UIApplication.shared.open(url)
        }
    }

    private func openMaps(_ coordinates: Coordinates) {
        let url = URL(string: "maps://?q=\(coordinates.latitude),\(coordinates.longitude)")!
        UIApplication.shared.open(url)
    }
}

// MARK: - Order Status Progress View
struct OrderStatusProgressView: View {
    let currentStatus: OrderStatus

    let allStatuses: [OrderStatus] = [.received, .preparing, .ready, .completed]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(Array(allStatuses.enumerated()), id: \.element) { index, status in
                HStack(spacing: Spacing.md) {
                    // Status Icon
                    ZStack {
                        Circle()
                            .fill(isActive(status) ? statusColor(status) : Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: status.icon)
                            .font(.title3)
                            .foregroundColor(isActive(status) ? .white : .gray)
                    }

                    // Status Info
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(status.title)
                            .font(AppFonts.headline)
                            .foregroundColor(isActive(status) ? .textPrimary : .textSecondary)

                        if let subtitle = status.subtitle {
                            Text(subtitle)
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    // Checkmark
                    if isCompleted(status) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.success)
                    } else if isCurrent(status) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))
                    }
                }
                .padding()
                .background(isCurrent(status) ? Color.brandPrimary.opacity(0.05) : Color.surface)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(isCurrent(status) ? Color.brandPrimary : Color.clear, lineWidth: 2)
                )

                // Connector Line
                if index < allStatuses.count - 1 {
                    Rectangle()
                        .fill(isCompleted(status) ? Color.success : Color.gray.opacity(0.2))
                        .frame(width: 3, height: 30)
                        .padding(.leading, 23)
                }
            }
        }
    }

    private func isActive(_ status: OrderStatus) -> Bool {
        guard let currentIndex = allStatuses.firstIndex(of: currentStatus),
              let statusIndex = allStatuses.firstIndex(of: status) else {
            return false
        }
        return statusIndex <= currentIndex
    }

    private func isCompleted(_ status: OrderStatus) -> Bool {
        guard let currentIndex = allStatuses.firstIndex(of: currentStatus),
              let statusIndex = allStatuses.firstIndex(of: status) else {
            return false
        }
        return statusIndex < currentIndex
    }

    private func isCurrent(_ status: OrderStatus) -> Bool {
        status == currentStatus
    }

    private func statusColor(_ status: OrderStatus) -> Color {
        switch status {
        case .scheduled: return .purple
        case .received: return .blue
        case .preparing: return .orange
        case .ready: return .success
        case .completed: return .gray
        case .cancelled: return .error
        case .unknown: return .gray
        }
    }
}

// MARK: - Order Tracking Item Row
struct OrderTrackingItemRow: View {
    let item: CartItem

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text("\(item.quantity)×")
                .font(AppFonts.body)
                .foregroundColor(.textSecondary)
                .frame(width: 30, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.menuItem.name)
                    .font(AppFonts.body)
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
            }

            Spacer()

            Text(item.formattedTotalPrice)
                .font(AppFonts.body)
                .foregroundColor(.textPrimary)
        }
    }
}

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
                specialInstructions: nil
            )
        ],
        subtotal: 31.98,
        tax: 2.56,
        total: 34.54,
        status: .preparing,
        orderType: .pickup,
        createdAt: Date(),
        estimatedReadyTime: Date().addingTimeInterval(1200),
        orderNumber: "123456",
        scheduledFor: nil
    )

    return OrderTrackingView(order: mockOrder)
}
