//
//  DashboardView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTab = 0
    @State private var appError: AppError?

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    LoadingStateView(message: "Loading orders...")
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Stats Cards
                            OrderStatsView(viewModel: viewModel)
                                .padding(.horizontal)

                            // Tab Selector
                            Picker("Order Status", selection: $selectedTab) {
                                Text("Active (\(viewModel.activeOrders.count))").tag(0)
                                Text("Completed (\(viewModel.completedOrders.count))").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            // Orders List
                            if selectedTab == 0 {
                                ActiveOrdersSection(viewModel: viewModel)
                            } else {
                                CompletedOrdersSection(viewModel: viewModel)
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        // Pull-to-refresh functionality
                        let storeIdString: String
                        if let storeId = authManager.userProfile?.storeId {
                            storeIdString = String(storeId)
                        } else {
                            storeIdString = String(SupabaseConfig.storeId)
                        }
                        await viewModel.refreshAsync(storeId: storeIdString)
                    }
                }
            }
            .navigationTitle("Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authManager.userProfile?.fullName ?? "")
                            .font(AppFonts.caption)
                        Text(authManager.userProfile?.role.displayName ?? "")
                            .font(AppFonts.caption2)
                            .foregroundColor(.textSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let storeIdString: String
                        if let storeId = authManager.userProfile?.storeId {
                            storeIdString = String(storeId)
                        } else {
                            storeIdString = String(SupabaseConfig.storeId)
                        }
                        viewModel.refresh(storeId: storeIdString)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showOrderDetail) {
                if let order = viewModel.selectedOrder {
                    OrderDetailView(order: order, viewModel: viewModel)
                }
            }
            .appErrorAlert(error: $appError) {
                let storeIdString = authManager.userProfile?.storeId.map { String($0) } ?? String(SupabaseConfig.storeId)
                viewModel.refresh(storeId: storeIdString)
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if let message = newValue {
                    appError = AppError.from(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
                    viewModel.errorMessage = nil
                }
            }
        }
        .onAppear {
            // Get store ID from user profile, or default to Jay's Deli (store 1)
            let storeIdString: String
            if let storeId = authManager.userProfile?.storeId {
                storeIdString = String(storeId)
            } else {
                // Super admins or users without assigned stores default to store 1
                storeIdString = String(SupabaseConfig.storeId)
                print("ℹ️ No store assigned to user, defaulting to store \(storeIdString)")
            }

            // Load initial orders
            viewModel.loadOrders(storeId: storeIdString)

            // Start real-time updates (THE MAGIC! 🎉)
            viewModel.startRealtimeUpdates(storeId: storeIdString)

            print("🔔 Real-time order updates ACTIVE - new orders will appear instantly!")
        }
        .onDisappear {
            // Stop real-time updates when view disappears to save resources
            viewModel.stopRealtimeUpdates()
        }
    }
}

// MARK: - Order Stats View
struct OrderStatsView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        HStack(spacing: Spacing.md) {
            StatCard(
                title: "Received",
                count: viewModel.receivedOrders.count,
                color: .blue,
                icon: "tray.fill"
            )

            StatCard(
                title: "Preparing",
                count: viewModel.preparingOrders.count,
                color: .orange,
                icon: "flame.fill"
            )

            StatCard(
                title: "Ready",
                count: viewModel.readyOrders.count,
                color: .green,
                icon: "checkmark.circle.fill"
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }

            Text("\(count)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(.textSecondary)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(
            LinearGradient(
                colors: [
                    color.opacity(0.08),
                    color.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(CornerRadius.lg)
        .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Active Orders Section
struct ActiveOrdersSection: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if viewModel.activeOrders.isEmpty {
                EmptyStateView(
                    icon: "tray.fill",
                    title: "No Active Orders",
                    message: "New orders will appear here automatically",
                    showBackground: false
                )
                .padding(.vertical, Spacing.xl)
            } else {
                ForEach(viewModel.activeOrders) { order in
                    OrderCard(order: order, viewModel: viewModel)
                        .padding(.horizontal)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.activeOrders.count)
    }
}

// MARK: - Completed Orders Section
struct CompletedOrdersSection: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if viewModel.completedOrders.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No Completed Orders",
                    message: "Completed orders will appear here",
                    showBackground: false
                )
                .padding(.vertical, Spacing.xl)
            } else {
                ForEach(viewModel.completedOrders) { order in
                    CompletedOrderCard(order: order, viewModel: viewModel)
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Order Card
struct OrderCard: View {
    let order: Order
    @ObservedObject var viewModel: DashboardViewModel

    private var statusColor: Color {
        switch order.status {
        case .received: return .blue
        case .preparing: return .orange
        case .ready: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Colorful Status Banner
            HStack {
                Image(systemName: order.status.icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(order.status.displayName.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1)
                Spacer()
                Text(order.timeElapsedString)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(
                LinearGradient(
                    colors: [statusColor, statusColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Order #\(order.orderNumber)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.textPrimary)

                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                            Text(order.customerName)
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Text(order.formattedTotal)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(statusColor)
                }

                // Items Count Badge
                if !order.items.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 12))
                        Text("\(order.items.count) item\(order.items.count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(statusColor)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
                }

                // Items Preview (first 3 items)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(Array(order.items.prefix(3).enumerated()), id: \.1.id) { index, item in
                        HStack(spacing: Spacing.sm) {
                            Text("\(item.quantity)×")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(statusColor)
                                .frame(width: 32)

                            Text(item.menuItem.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            if !item.specialInstructions.isEmpty {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.warning)
                            }
                        }

                        if index < min(2, order.items.count - 1) {
                            Divider()
                        }
                    }

                    if order.items.count > 3 {
                        Text("+ \(order.items.count - 3) more item\(order.items.count - 3 == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .padding(.leading, 40)
                    }
                }

                // Action Buttons
                HStack(spacing: Spacing.md) {
                    if let nextStatus = order.status.nextStatus,
                       let buttonTitle = order.status.actionButtonTitle {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.updateOrderStatus(order, newStatus: nextStatus)
                            }
                        }) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: nextStatusIcon(for: nextStatus))
                                    .font(.system(size: 16, weight: .semibold))
                                Text(buttonTitle)
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(
                                LinearGradient(
                                    colors: [nextStatusColor(for: nextStatus), nextStatusColor(for: nextStatus).opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(CornerRadius.md)
                            .shadow(color: nextStatusColor(for: nextStatus).opacity(0.3), radius: 4, y: 2)
                        }
                    }

                    Button(action: {
                        viewModel.selectOrder(order)
                    }) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                            Text("Details")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.surfaceSecondary)
                        .foregroundColor(.brandPrimary)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: statusColor.opacity(0.2), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(statusColor.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Order \(order.orderNumber) for \(order.customerName), \(order.status.displayName), \(order.formattedTotal)")
        .accessibilityHint("Double tap to view details")
    }

    private func nextStatusColor(for status: OrderStatus) -> Color {
        switch status {
        case .received: return .blue
        case .preparing: return .orange
        case .ready: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }

    private func nextStatusIcon(for status: OrderStatus) -> String {
        switch status {
        case .received: return "bell.badge.fill"
        case .preparing: return "flame.fill"
        case .ready: return "checkmark.seal.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Completed Order Card
struct CompletedOrderCard: View {
    let order: Order
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        Button(action: {
            viewModel.selectOrder(order)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Order #\(order.orderNumber)")
                        .font(AppFonts.headline)
                        .foregroundColor(.textPrimary)

                    Text(order.customerName)
                        .font(AppFonts.subheadline)
                        .foregroundColor(.textSecondary)

                    Text(order.createdAt, style: .time)
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    StatusBadge(status: order.status)

                    Text(order.formattedTotal)
                        .font(AppFonts.headline)
                        .foregroundColor(.textPrimary)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.surfaceSecondary)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: OrderStatus

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.rawValue)
                .font(AppFonts.caption2)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 4)
        .background(badgeColor)
        .foregroundColor(.white)
        .cornerRadius(CornerRadius.sm)
    }

    private var badgeColor: Color {
        switch status {
        case .received: return .blue
        case .preparing: return .orange
        case .ready: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
}
