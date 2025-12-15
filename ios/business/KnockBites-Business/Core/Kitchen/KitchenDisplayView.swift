//
//  KitchenDisplayView.swift
//  knockbites-Bussiness-app
//
//  Redesigned by Claude Code
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Kitchen Display View

struct KitchenDisplayView: View {
    @StateObject private var viewModel = KitchenViewModel()
    @State private var selectedStatus: KitchenOrderStatus = .received
    @State private var selectedFilter: OrderType? = nil
    @State private var showFilters = false
    @State private var appError: AppError?

    var body: some View {
        NavigationView {
            ZStack {
            VStack(spacing: 0) {
                // Modern Pill-Style Tab Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach([
                            (KitchenOrderStatus.received, "New", Color.orange),
                            (.acknowledged, "Queued", Color.yellow),
                            (.preparing, "Cooking", Color.blue),
                            (.ready, "Ready", Color.green),
                            (.pickedUp, "Out", Color.purple),
                            (.completed, "Done", Color.gray)
                        ], id: \.0) { status, title, color in
                            ModernStatusPill(
                                title: title,
                                count: viewModel.filteredOrders(for: status).count,
                                color: color,
                                isSelected: selectedStatus == status
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedStatus = status
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(
                    LinearGradient(
                        colors: [Color.surfaceSecondary.opacity(0.8), Color.surface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Order List with Animation
                if viewModel.isLoading {
                    LoadingStateView(message: "Loading orders...")
                } else if viewModel.filteredOrders(for: selectedStatus).isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "No Orders",
                        message: "No orders in this status",
                        showBackground: false
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.lg) {
                            ForEach(viewModel.filteredOrders(for: selectedStatus)) { order in
                                ModernKitchenOrderCard(order: order, viewModel: viewModel)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                    .onDrag {
                                        viewModel.draggedOrder = order
                                        return NSItemProvider(object: order.id as NSString)
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.surface.ignoresSafeArea())
            }
            .navigationTitle("Kitchen Display")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Live")
                            .font(AppFonts.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: Spacing.md) {
                        Button(action: { showFilters.toggle() }) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.title3)
                                .foregroundColor(.brandPrimary)
                        }

                        Button(action: { viewModel.refreshOrders() }) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title3)
                                .foregroundColor(.brandPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(selectedFilter: $viewModel.filterType)
            }
            .appErrorAlert(error: $appError) {
                viewModel.refreshOrders()
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if let message = newValue {
                    appError = AppError.from(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
                    viewModel.errorMessage = nil
                }
            }
        }
        .onAppear {
            // Load initial orders
            viewModel.loadOrders()

            // Start real-time updates for Jay's Deli
            viewModel.startRealtimeUpdates()

            print("🔔 Kitchen real-time order updates ACTIVE - new orders will appear instantly!")
        }
        .onDisappear {
            // Stop real-time updates when view disappears to save resources
            viewModel.stopRealtimeUpdates()
        }
    }
}

// MARK: - Modern Status Pill

struct ModernStatusPill: View {
    let title: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(title)
                    .font(AppFonts.subheadline)
                    .fontWeight(isSelected ? .bold : .semibold)
                    .foregroundColor(isSelected ? .white : .textPrimary)

                if count > 0 {
                    Text("\(count)")
                        .font(AppFonts.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? color : .white)
                        .frame(minWidth: 24, minHeight: 24)
                        .background(isSelected ? Color.white.opacity(0.3) : color)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.surfaceSecondary
                    }
                }
            )
            .cornerRadius(CornerRadius.xl)
            .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Modern Kitchen Order Card

struct ModernKitchenOrderCard: View {
    let order: KitchenOrder
    @ObservedObject var viewModel: KitchenViewModel
    @State private var showDetails = false

    var isUrgent: Bool {
        order.minutesWaiting > 20
    }

    var urgencyColor: Color {
        if order.minutesWaiting > 20 { return .red }
        if order.minutesWaiting > 15 { return .orange }
        return .gray
    }

    private func printOrder(_ order: KitchenOrder) {
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

        // Convert KitchenOrder items to CartItems
        let cartItems = order.items.map { item in
            // Create a simple MenuItem for each item
            let menuItem = MenuItem(
                id: UUID().uuidString,
                name: item.name,
                description: "",
                price: 0.0, // Price not available in KitchenOrder
                categoryId: "",
                imageURL: "",
                isAvailable: true,
                dietaryInfo: [],
                customizationGroups: [],
                calories: nil,
                prepTime: order.estimatedPrepTime
            )

            return CartItem(
                id: UUID().uuidString,
                menuItem: menuItem,
                quantity: item.quantity,
                selectedOptions: [:],
                specialInstructions: item.customizations.joined(separator: ", ")
            )
        }

        // Calculate totals (estimates since we don't have actual prices)
        let subtotal = 0.0 // Price not available in KitchenOrder
        let tax = subtotal * 0.08
        let total = subtotal + tax

        // Convert KitchenOrder to Order for receipt service
        let convertedOrder = Order(
            id: order.id,
            orderNumber: order.orderNumber,
            userId: "", // Not available in KitchenOrder
            customerName: order.customerName,
            storeId: "1",
            items: cartItems,
            subtotal: subtotal,
            tax: tax,
            total: total,
            status: convertOrderStatus(order.status),
            orderType: order.type,
            createdAt: order.placedAt,
            estimatedReadyTime: order.estimatedReadyTime,
            completedAt: nil
        )

        // Print using our custom receipt service
        ReceiptService.printReceipt(order: convertedOrder, store: store, settings: settings)
        print("🖨️ Receipt printed for kitchen order \(order.orderNumber)")
    }

    private func convertOrderStatus(_ kitchenStatus: KitchenOrderStatus) -> OrderStatus {
        switch kitchenStatus {
        case .received, .acknowledged:
            return .received
        case .preparing:
            return .preparing
        case .ready, .pickedUp:
            return .ready
        case .completed:
            return .completed
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Gradient
            ZStack {
                LinearGradient(
                    colors: [
                        order.type == .delivery ? Color.blue.opacity(0.15) : Color.green.opacity(0.15),
                        Color.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: Spacing.md) {
                    // Top Row: Order Number and Time
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(order.orderNumber)
                                .font(AppFonts.title2)
                                .fontWeight(.black)
                                .foregroundColor(.textPrimary)

                            // Order Type Badge
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: order.type.icon)
                                    .font(.caption)
                                Text(order.type.rawValue.capitalized)
                                    .font(AppFonts.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 4)
                            .background(order.type == .delivery ? Color.blue : Color.green)
                            .cornerRadius(CornerRadius.sm)
                        }

                        Spacer()

                        // Time and Urgency
                        VStack(alignment: .trailing, spacing: Spacing.xs) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(urgencyColor)
                                    .frame(width: 8, height: 8)

                                Text("\(order.minutesWaiting)m")
                                    .font(AppFonts.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(urgencyColor)
                            }

                            // Estimated Time
                            if let estimatedReady = order.estimatedReadyTime {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.badge.checkmark")
                                        .font(.caption2)
                                    Text("Est: \(estimatedReady, style: .time)")
                                        .font(AppFonts.caption2)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.textSecondary)
                            }

                            if isUrgent {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                    Text("URGENT")
                                        .font(AppFonts.caption2)
                                        .fontWeight(.black)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.red)
                                        .shadow(color: .red.opacity(0.5), radius: 4)
                                )
                            }
                        }
                    }

                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.2))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [urgencyColor, urgencyColor.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * min(CGFloat(order.minutesWaiting) / 30.0, 1.0))
                        }
                    }
                    .frame(height: 6)
                }
                .padding()
            }
            .frame(height: 120)

            // Items Section
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(order.items.prefix(3), id: \.name) { item in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(alignment: .top, spacing: Spacing.md) {
                            // Quantity Badge
                            Text("\(item.quantity)")
                                .font(AppFonts.body)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.brandPrimary)
                                )

                            // Item Name
                            Text(item.name)
                                .font(AppFonts.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)

                            Spacer()

                            // Checkmark placeholder
                            Circle()
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 24, height: 24)
                        }

                        // Customizations on separate lines
                        if !item.customizations.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(item.customizations, id: \.self) { customization in
                                    HStack(spacing: 4) {
                                        Text("•")
                                            .foregroundColor(.brandPrimary)
                                        Text(customization)
                                            .font(AppFonts.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                            }
                            .padding(.leading, 44) // Align with item name
                        }
                    }
                }

                if order.items.count > 3 {
                    HStack {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundColor(.brandPrimary)
                        Text("+\(order.items.count - 3) more items")
                            .font(AppFonts.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.brandPrimary)
                    }
                    .padding(.leading, 44)
                }
            }
            .padding()
            .background(Color.surface)

            // Special Instructions Banner
            if let instructions = order.specialInstructions, !instructions.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Special Request")
                            .font(AppFonts.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Text(instructions)
                            .font(AppFonts.subheadline)
                            .foregroundColor(.textPrimary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }

            // Footer
            HStack {
                // Customer Name
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.textSecondary)
                    Text(order.customerName)
                        .font(AppFonts.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Print Button
                Button(action: {
                    printOrder(order)
                }) {
                    Image(systemName: "printer.fill")
                        .font(.title3)
                        .foregroundColor(.brandPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.surface)
                        .cornerRadius(CornerRadius.sm)
                }

                // Details Button
                Button(action: { showDetails.toggle() }) {
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(AppFonts.subheadline)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
            .padding()
            .background(Color.surfaceSecondary.opacity(0.5))

            // Action Button
            if let nextStatus = order.status.nextStatus {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.updateOrderStatus(order, to: nextStatus)
                    }
                }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: nextStatus.icon)
                            .font(.title3)

                        Text(nextStatus.actionButtonTitle(for: order.type))
                            .font(AppFonts.headline)
                            .fontWeight(.bold)

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [nextStatus.buttonColor, nextStatus.buttonColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .strokeBorder(
                    isUrgent ?
                        LinearGradient(
                            colors: [Color.red, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                    lineWidth: isUrgent ? 3 : 1.5
                )
        )
        .sheet(isPresented: $showDetails) {
            OrderDetailSheet(order: order, viewModel: viewModel)
        }
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    KitchenDisplayView()
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var selectedFilter: OrderType?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedFilter = nil
                    dismiss()
                }) {
                    HStack {
                        Text("All Orders")
                        Spacer()
                        if selectedFilter == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.brandPrimary)
                        }
                    }
                }

                ForEach(OrderType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedFilter = type
                        dismiss()
                    }) {
                        HStack {
                            Label(type.rawValue, systemImage: type.icon)
                            Spacer()
                            if let selected = selectedFilter, selected == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.brandPrimary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Orders")
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
}

// MARK: - Order Detail Sheet

struct OrderDetailSheet: View {
    let order: KitchenOrder
    @ObservedObject var viewModel: KitchenViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Order Header
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(order.orderNumber)
                            .font(AppFonts.title2)
                            .fontWeight(.bold)

                        HStack {
                            Label(order.type.rawValue.capitalized, systemImage: order.type.icon)
                            Spacer()
                            Label("\(order.minutesWaiting) min", systemImage: "clock.fill")
                                .foregroundColor(order.minutesWaiting > 20 ? .error : .textSecondary)
                        }
                        .font(AppFonts.subheadline)
                    }
                    .padding()
                    .background(Color.surfaceSecondary)
                    .cornerRadius(CornerRadius.md)

                    // Customer Info
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Customer")
                            .font(AppFonts.headline)
                            .fontWeight(.bold)

                        Text(order.customerName)
                            .font(AppFonts.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.md)

                    // Items
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Order Items")
                            .font(AppFonts.headline)
                            .fontWeight(.bold)

                        ForEach(order.items, id: \.name) { item in
                            HStack(alignment: .top) {
                                Text("\(item.quantity)x")
                                    .font(AppFonts.body)
                                    .fontWeight(.semibold)
                                    .frame(width: 40, alignment: .leading)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(AppFonts.body)

                                    if !item.customizations.isEmpty {
                                        Text(item.customizations.joined(separator: ", "))
                                            .font(AppFonts.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.vertical, Spacing.sm)

                            if item.name != order.items.last?.name {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.md)

                    // Special Instructions
                    if let instructions = order.specialInstructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Label("Special Instructions", systemImage: "exclamationmark.circle.fill")
                                .font(AppFonts.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.warning)

                            Text(instructions)
                                .font(AppFonts.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.warning.opacity(0.1))
                        .cornerRadius(CornerRadius.md)
                    }

                    // Quick Actions
                    VStack(spacing: Spacing.md) {
                        Text("Quick Actions")
                            .font(AppFonts.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Primary Action (Next Status)
                        if let nextStatus = order.status.nextStatus {
                            Button(action: {
                                viewModel.updateOrderStatus(order, to: nextStatus)
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: nextStatus.icon)
                                    Text(nextStatus.actionButtonTitle(for: order.type))
                                    Spacer()
                                }
                                .font(AppFonts.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding()
                                .background(nextStatus.buttonColor)
                                .cornerRadius(CornerRadius.md)
                            }
                        }

                        // Secondary Actions (Other statuses)
                        ForEach(KitchenOrderStatus.allCases, id: \.self) { status in
                            if status != order.status && status != order.status.nextStatus {
                                Button(action: {
                                    viewModel.updateOrderStatus(order, to: status)
                                    dismiss()
                                }) {
                                    HStack {
                                        Image(systemName: status.icon)
                                        Text("Mark as \(status.displayName)")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(AppFonts.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                    .padding()
                                    .background(Color.surfaceSecondary)
                                    .cornerRadius(CornerRadius.md)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Order Details")
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
}

// MARK: - Drop Delegate

struct OrderDropDelegate: DropDelegate {
    let status: KitchenOrderStatus
    let viewModel: KitchenViewModel

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedOrder = viewModel.draggedOrder else { return false }
        viewModel.updateOrderStatus(draggedOrder, to: status)
        viewModel.draggedOrder = nil
        return true
    }
}
