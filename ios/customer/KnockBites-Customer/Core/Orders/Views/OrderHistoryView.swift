//
//  OrderHistoryView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct OrderHistoryView: View {
    @StateObject private var viewModel = OrderViewModel()
    @EnvironmentObject var cartViewModel: CartViewModel
    @Environment(\.selectedTab) private var selectedTab
    @State private var selectedOrder: Order?
    @State private var showOrderDetail = false
    @State private var showStoreSelector = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: Spacing.xl) {
                        Spacer()
                        ErrorView(
                            title: "Unable to Load Orders",
                            message: errorMessage,
                            icon: "wifi.slash",
                            retryAction: {
                                Task {
                                    await viewModel.fetchOrderHistory()
                                }
                            }
                        )
                        Spacer()
                    }
                } else if viewModel.isLoading {
                    ScrollView {
                        VStack(spacing: Spacing.md) {
                            // Store Selector Skeleton
                            SkeletonView(height: 60, cornerRadius: CornerRadius.md)
                                .padding(.horizontal)
                                .padding(.top)

                            // Order Card Skeletons
                            ForEach(0..<3, id: \.self) { _ in
                                OrderCardSkeleton()
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                } else if viewModel.orders.isEmpty {
                    VStack(spacing: Spacing.xl) {
                        // Store Selector
                        StoreSelectorRow(
                            selectedStore: cartViewModel.selectedStore,
                            onTap: { showStoreSelector = true }
                        )
                        .padding(.horizontal)
                        .padding(.top)

                        Spacer()

                        EmptyStateView(
                            icon: "bag",
                            title: "No Orders Yet",
                            message: "Your order history will appear here",
                            actionTitle: "Browse Menu",
                            action: {
                                selectedTab.wrappedValue = 1 // Navigate to Menu tab
                            }
                        )

                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.md) {
                            // Store Selector
                            StoreSelectorRow(
                                selectedStore: cartViewModel.selectedStore,
                                onTap: { showStoreSelector = true }
                            )
                            .padding(.horizontal)
                            .padding(.top)

                            ForEach(viewModel.orders) { order in
                                OrderHistoryCard(order: order) {
                                    selectedOrder = order
                                    showOrderDetail = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Order History")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.fetchOrderHistory()
            }
            .refreshable {
                await viewModel.fetchOrderHistory()
            }
            .sheet(isPresented: $showOrderDetail) {
                if let order = selectedOrder {
                    OrderDetailView(order: order)
                        .environmentObject(cartViewModel)
                }
            }
            .sheet(isPresented: $showStoreSelector) {
                StoreSelectorView(selectedStore: $cartViewModel.selectedStore)
            }
        }
    }
}

// MARK: - Store Selector Row
struct StoreSelectorRow: View {
    let selectedStore: Store?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Ordering from")
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)

                    Text(selectedStore?.name ?? "Select Store")
                        .font(AppFonts.headline)
                        .foregroundColor(.brandPrimary)
                }

                Spacer()

                HStack(spacing: Spacing.xs) {
                    Text("Change")
                        .font(AppFonts.subheadline)
                        .foregroundColor(.brandPrimary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.brandPrimary)
                }
            }
            .padding()
            .background(Color.brandPrimary.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Order History Card
struct OrderHistoryCard: View {
    let order: Order
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Order #\(order.orderNumber)")
                            .font(AppFonts.headline)
                            .foregroundColor(.textPrimary)

                        Text(order.createdAt, style: .date)
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    // Status Badge
                    OrderStatusBadge(status: order.status)
                }

                Divider()

                // Items Summary
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(order.items.prefix(2)) { item in
                        HStack {
                            Text("\(item.quantity)×")
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                                .frame(width: 25, alignment: .leading)

                            Text(item.menuItem.name)
                                .font(AppFonts.body)
                                .foregroundColor(.textPrimary)

                            Spacer()

                            Text(item.formattedTotalPrice)
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    if order.items.count > 2 {
                        Text("+ \(order.items.count - 2) more items")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                            .padding(.leading, 25)
                    }
                }

                Divider()

                // Footer
                HStack {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: order.orderType.icon)
                            .font(.caption)
                        Text(order.orderType.rawValue)
                            .font(AppFonts.caption)
                    }
                    .foregroundColor(.textSecondary)

                    Spacer()

                    Text(order.formattedTotal)
                        .font(AppFonts.headline)
                        .foregroundColor(.brandPrimary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Order Status Badge
struct OrderStatusBadge: View {
    let status: OrderStatus

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: status.icon)
                .font(.system(size: 11))

            Text(status.rawValue)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(colorForStatus)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 4)
        .background(colorForStatus.opacity(0.15))
        .cornerRadius(CornerRadius.sm)
    }

    private var colorForStatus: Color {
        switch status {
        case .scheduled: return .purple
        case .received: return .blue
        case .preparing: return .orange
        case .ready: return .green
        case .completed: return .gray
        case .cancelled: return .red
        case .unknown: return .gray
        }
    }
}

#Preview {
    let viewModel = OrderViewModel()

    // Create mock orders
    let mockOrder1 = Order(
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
        createdAt: Date().addingTimeInterval(-3600),
        estimatedReadyTime: Date().addingTimeInterval(600),
        orderNumber: "123456",
        scheduledFor: nil
    )

    viewModel.orders = [mockOrder1]

    return OrderHistoryView()
        .environmentObject(CartViewModel())
        .onAppear {
            viewModel.saveOrder(mockOrder1)
        }
}
