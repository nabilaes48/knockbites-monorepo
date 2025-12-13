//
//  CheckoutView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct CheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cartViewModel: CartViewModel
    @StateObject private var orderViewModel = OrderViewModel()

    @State private var orderType: OrderType = .pickup
    @State private var isPlacingOrder = false
    @State private var showOrderConfirmation = false
    @State private var placedOrder: Order?
    @State private var errorMessage: String?

    // Scheduling
    @State private var isScheduled = false
    @State private var scheduledDate = Date().addingTimeInterval(3600) // Default 1 hour from now

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Store Info
                        if let store = cartViewModel.selectedStore {
                            StoreInfoSection(store: store)
                        }

                        // Order Type
                        OrderTypeSelector(selectedType: $orderType)

                        // Scheduling Section
                        SchedulingSection(
                            isScheduled: $isScheduled,
                            scheduledDate: $scheduledDate,
                            store: cartViewModel.selectedStore
                        )

                        // Order Items Summary
                        OrderItemsSection(items: cartViewModel.items)

                        // Order Summary
                        OrderSummarySection(
                            subtotal: cartViewModel.formattedSubtotal,
                            tax: cartViewModel.formattedTax,
                            total: cartViewModel.formattedTotal
                        )

                        // Payment Info (Mock)
                        PaymentSection()

                        // Place Order Button
                        CustomButton(
                            title: "Place Order",
                            action: { Task { await placeOrder() } },
                            style: .primary,
                            isLoading: isPlacingOrder,
                            icon: "checkmark.circle.fill"
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .fullScreenCover(isPresented: $showOrderConfirmation) {
                if let order = placedOrder {
                    OrderConfirmationView(order: order)
                }
            }
        }
    }

    private func placeOrder() async {
        // Validate store selection
        guard let store = cartViewModel.selectedStore else {
            errorMessage = "Please select a store before placing your order"
            return
        }

        // Validate cart is not empty
        guard !cartViewModel.items.isEmpty else {
            errorMessage = "Your cart is empty"
            return
        }

        // Validate scheduled time
        if isScheduled {
            if scheduledDate < Date() {
                errorMessage = "Scheduled time must be in the future"
                return
            }

            // Validate against store hours
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: scheduledDate) - 1

            if !store.hours.daysOpen.contains(weekday) {
                errorMessage = "Store is closed on selected day"
                return
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let scheduledTime = formatter.string(from: scheduledDate)

            guard let schedTime = formatter.date(from: scheduledTime),
                  let openTime = formatter.date(from: store.hours.openTime),
                  let closeTime = formatter.date(from: store.hours.closeTime) else {
                errorMessage = "Invalid time format"
                return
            }

            if schedTime < openTime || schedTime > closeTime {
                errorMessage = "Scheduled time must be during store hours (\(store.hours.openTime) - \(store.hours.closeTime))"
                return
            }
        }

        isPlacingOrder = true
        cartViewModel.orderType = orderType
        cartViewModel.scheduledFor = isScheduled ? scheduledDate : nil

        do {
            // Submit order through OrderViewModel (MVVM pattern)
            let (orderId, orderNumber) = try await orderViewModel.submitOrder(
                items: cartViewModel.items,
                storeId: store.id,
                orderType: orderType,
                subtotal: cartViewModel.subtotal,
                tax: cartViewModel.tax,
                total: cartViewModel.total
            )

            print("✅ Order submitted successfully!")
            print("   📋 Order ID: \(orderId)")
            print("   🔢 Order Number: \(orderNumber)")

            // Get user ID from session
            let userId = UserDefaults.standard.string(forKey: "currentUserId") ?? "guest"

            // Calculate estimated ready time
            let estimatedReadyTime: Date?
            if isScheduled, let scheduled = cartViewModel.scheduledFor {
                estimatedReadyTime = scheduled
            } else {
                estimatedReadyTime = Date().addingTimeInterval(20 * 60) // 20 minutes for ASAP orders
            }

            // Create Order object from Supabase response
            let order = Order(
                id: orderId,
                userId: userId,
                storeId: store.id,
                items: cartViewModel.items,
                subtotal: cartViewModel.subtotal,
                tax: cartViewModel.tax,
                total: cartViewModel.total,
                status: isScheduled ? .scheduled : .received,
                orderType: orderType,
                createdAt: Date(),
                estimatedReadyTime: estimatedReadyTime,
                orderNumber: orderNumber,  // Use REAL order number from database
                scheduledFor: isScheduled ? scheduledDate : nil
            )

            // Save order to history
            orderViewModel.saveOrder(order)

            // Clear cart after successful order
            cartViewModel.clearCart()

            placedOrder = order
            showOrderConfirmation = true

            // Show success toast
            ToastManager.shared.show(
                "Order placed successfully!",
                icon: "checkmark.circle.fill",
                type: .success
            )
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to place order: \(error)")
            ToastManager.shared.show(
                "Failed to place order",
                icon: "exclamationmark.triangle",
                type: .error
            )
        }

        isPlacingOrder = false
    }
}

// MARK: - Store Info Section
struct StoreInfoSection: View {
    let store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Pickup Location")
                .font(AppFonts.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: Spacing.md) {
                Image(systemName: "storefront.fill")
                    .font(.title2)
                    .foregroundColor(.brandPrimary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(AppFonts.body)
                        .foregroundColor(.textPrimary)

                    Text(store.address)
                        .font(AppFonts.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Order Type Selector
struct OrderTypeSelector: View {
    @Binding var selectedType: OrderType

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Order Type")
                .font(AppFonts.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: Spacing.md) {
                ForEach([OrderType.pickup, .dineIn], id: \.self) { type in
                    Button(action: { selectedType = type }) {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: type.icon)
                                .font(.title2)
                            Text(type.rawValue)
                                .font(AppFonts.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedType == type ? Color.brandPrimary : Color.surface)
                        .foregroundColor(selectedType == type ? .white : .textPrimary)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(selectedType == type ? Color.clear : Color.border, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Scheduling Section
struct SchedulingSection: View {
    @Binding var isScheduled: Bool
    @Binding var scheduledDate: Date
    let store: Store?

    private var minimumDate: Date {
        Date().addingTimeInterval(1800) // 30 minutes from now
    }

    private var maximumDate: Date {
        Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("When")
                    .font(AppFonts.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                Toggle("", isOn: $isScheduled)
                    .labelsHidden()
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: isScheduled ? "clock.fill" : "bolt.fill")
                        .foregroundColor(.brandPrimary)
                    Text(isScheduled ? "Scheduled for later" : "ASAP")
                        .font(AppFonts.body)
                        .foregroundColor(.textPrimary)
                    Spacer()
                }

                if isScheduled {
                    Divider()

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Select Date & Time")
                            .font(AppFonts.subheadline)
                            .foregroundColor(.textSecondary)

                        DatePicker(
                            "Pickup Time",
                            selection: $scheduledDate,
                            in: minimumDate...maximumDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()

                        if let store = store {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                Text("Store hours: \(store.hours.openTime) - \(store.hours.closeTime)")
                                    .font(AppFonts.caption)
                            }
                            .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Order Items Section
struct OrderItemsSection: View {
    let items: [CartItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Order Items (\(items.count))")
                .font(AppFonts.headline)
                .foregroundColor(.textPrimary)

            VStack(spacing: Spacing.sm) {
                ForEach(items) { item in
                    HStack(alignment: .top) {
                        Text("\(item.quantity)×")
                            .font(AppFonts.body)
                            .foregroundColor(.textSecondary)
                            .frame(width: 30, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.menuItem.name)
                                .font(AppFonts.body)
                                .foregroundColor(.textPrimary)

                            if !item.selectedOptions.isEmpty {
                                ForEach(Array(item.selectedOptions.keys), id: \.self) { groupId in
                                    if let group = item.menuItem.customizationGroups.first(where: { $0.id == groupId }),
                                       let optionIds = item.selectedOptions[groupId] {
                                        let options = group.options.filter { optionIds.contains($0.id) }
                                        Text(options.map { $0.name }.joined(separator: ", "))
                                            .font(AppFonts.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                            }
                        }

                        Spacer()

                        Text(item.formattedTotalPrice)
                            .font(AppFonts.body)
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.vertical, Spacing.xs)

                    if item.id != items.last?.id {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Order Summary Section
struct OrderSummarySection: View {
    let subtotal: String
    let tax: String
    let total: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Order Summary")
                .font(AppFonts.headline)
                .foregroundColor(.textPrimary)

            VStack(spacing: Spacing.sm) {
                HStack {
                    Text("Subtotal")
                        .font(AppFonts.body)
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text(subtotal)
                        .font(AppFonts.body)
                        .foregroundColor(.textPrimary)
                }

                HStack {
                    Text("Tax")
                        .font(AppFonts.body)
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text(tax)
                        .font(AppFonts.body)
                        .foregroundColor(.textPrimary)
                }

                Divider()

                HStack {
                    Text("Total")
                        .font(AppFonts.title3)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(total)
                        .font(AppFonts.title3)
                        .foregroundColor(.brandPrimary)
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Payment Section
struct PaymentSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Payment")
                .font(AppFonts.headline)
                .foregroundColor(.textPrimary)

            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.brandPrimary)

                Text("Pay at pickup")
                    .font(AppFonts.body)
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("Cash or Card")
                    .font(AppFonts.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Order Confirmation View
struct OrderConfirmationView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    @State private var showOrderTracking = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Success Icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.success)
                            .padding(.top, Spacing.xxl)

                        // Title
                        VStack(spacing: Spacing.sm) {
                            Text("Order Placed!")
                                .font(AppFonts.largeTitle)
                                .foregroundColor(.textPrimary)

                            Text("Order #\(order.orderNumber)")
                                .font(AppFonts.title3)
                                .foregroundColor(.textSecondary)
                        }

                        // Estimated Time or Scheduled Time
                        if order.isScheduled, let scheduledTime = order.scheduledFor {
                            VStack(spacing: Spacing.sm) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.purple)

                                Text("Scheduled For")
                                    .font(AppFonts.subheadline)
                                    .foregroundColor(.textSecondary)

                                Text(scheduledTime, style: .date)
                                    .font(AppFonts.title2)
                                    .foregroundColor(.textPrimary)

                                Text(scheduledTime, style: .time)
                                    .font(AppFonts.title1)
                                    .foregroundColor(.purple)

                                Text("We'll start preparing your order at the scheduled time")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(CornerRadius.lg)
                        } else if let estimatedTime = order.estimatedReadyTime {
                            VStack(spacing: Spacing.sm) {
                                Text("Estimated Ready Time")
                                    .font(AppFonts.subheadline)
                                    .foregroundColor(.textSecondary)

                                Text(estimatedTime, style: .time)
                                    .font(AppFonts.title1)
                                    .foregroundColor(.brandPrimary)

                                Text("We'll notify you when it's ready")
                                    .font(AppFonts.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            .padding()
                            .background(Color.brandPrimary.opacity(0.1))
                            .cornerRadius(CornerRadius.lg)
                        }

                        // Order Summary
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Order Summary")
                                .font(AppFonts.headline)
                                .foregroundColor(.textPrimary)

                            ForEach(order.items) { item in
                                HStack {
                                    Text("\(item.quantity)× \(item.menuItem.name)")
                                        .font(AppFonts.body)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Text(item.formattedTotalPrice)
                                        .font(AppFonts.body)
                                        .foregroundColor(.textSecondary)
                                }
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

                        // Actions
                        VStack(spacing: Spacing.md) {
                            CustomButton(
                                title: "Track Order",
                                action: { showOrderTracking = true },
                                style: .primary,
                                icon: "location.fill"
                            )

                            CustomButton(
                                title: "Back to Home",
                                action: { dismiss() },
                                style: .outline
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showOrderTracking) {
                OrderTrackingView(order: order)
            }
        }
    }
}

#Preview {
    let cartViewModel = CartViewModel()
    let mockItems = MockDataService.shared.getMenuItems()

    // TODO: Use dynamic store fetched from Supabase
    let _ = {
        cartViewModel.addItem(menuItem: mockItems[3], quantity: 2)
        cartViewModel.addItem(menuItem: mockItems[0], quantity: 1)
        // TODO: Use mock StoreViewModel with one fake store
    }()

    return CheckoutView()
        .environmentObject(cartViewModel)
}
