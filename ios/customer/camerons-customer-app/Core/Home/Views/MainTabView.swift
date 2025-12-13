//
//  MainTabView.swift
//  knockbites-customer-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

// MARK: - Environment Key for Tab Selection
private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var selectedTab: Binding<Int> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var cartViewModel: CartViewModel
    @StateObject private var menuViewModel = MenuViewModel()
    @State private var selectedTab = 0
    @State private var showCart = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .environmentObject(menuViewModel)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                MenuView()
                    .environmentObject(menuViewModel)
                    .tabItem {
                        Label("Menu", systemImage: "fork.knife")
                    }
                    .tag(1)

                OrdersTabView()
                    .environment(\.selectedTab, $selectedTab)
                    .tabItem {
                        Label("Orders", systemImage: "bag.fill")
                    }
                    .tag(2)

                RewardsTabView()
                    .tabItem {
                        Label("Rewards", systemImage: "star.fill")
                    }
                    .tag(3)

                ProfileTabView()
                    .environment(\.selectedTab, $selectedTab)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(4)
            }
            .accentColor(.brandPrimary)

            // Floating Cart Button
            if cartViewModel.itemCount > 0 {
                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        Button(action: { showCart = true }) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "cart.fill")
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(cartViewModel.itemCount) items")
                                        .font(AppFonts.caption)
                                    Text(cartViewModel.formattedTotal)
                                        .font(AppFonts.headline)
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)
                            .background(Color.brandPrimary)
                            .cornerRadius(CornerRadius.xl)
                            .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                        }
                        .padding()
                        .padding(.bottom, 50) // Above tab bar
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: cartViewModel.itemCount)
            }
        }
        .sheet(isPresented: $showCart) {
            CartView()
        }
        .onAppear {
            cartViewModel.loadCart()
        }
    }
}

// MARK: - Tab Views

struct OrdersTabView: View {
    var body: some View {
        OrderHistoryView()
    }
}

struct RewardsTabView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.warning)

                    VStack(spacing: Spacing.md) {
                        Text("0")
                            .font(AppFonts.largeTitle)
                            .foregroundColor(.textPrimary)

                        Text("Rewards Points")
                            .font(AppFonts.body)
                            .foregroundColor(.textSecondary)
                    }

                    Text("Rewards features coming soon")
                        .font(AppFonts.body)
                        .foregroundColor(.textSecondary)
                }
            }
            .navigationTitle("Rewards")
        }
    }
}

struct ProfileTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.selectedTab) private var selectedTab
    @State private var showSettings = false
    @State private var showAllergens = false
    @State private var showNotifications = false
    @State private var showHelp = false
    @State private var showFavorites = false
    @State private var showPaymentMethods = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Profile Header
                        VStack(spacing: Spacing.md) {
                            Circle()
                                .fill(Color.brandPrimary.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.brandPrimary)
                                )

                            VStack(spacing: Spacing.xs) {
                                Text("Profile")
                                    .font(AppFonts.title2)
                                    .foregroundColor(.textPrimary)

                                Text("Authenticated User")
                                    .font(AppFonts.body)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.top, Spacing.xl)

                        // Profile Options
                        VStack(spacing: Spacing.md) {
                            ProfileOption(icon: "bag.fill", title: "Order History") {
                                selectedTab.wrappedValue = 2 // Navigate to Orders tab
                            }
                            ProfileOption(icon: "heart.fill", title: "Favorites") {
                                showFavorites = true
                            }
                            ProfileOption(icon: "mappin.circle.fill", title: "Addresses") {
                                // TODO: Navigate to addresses
                            }
                            ProfileOption(icon: "creditcard.fill", title: "Payment Methods") {
                                showPaymentMethods = true
                            }
                            ProfileOption(icon: "leaf.fill", title: "Dietary Preferences") {
                                showAllergens = true
                            }
                            ProfileOption(icon: "bell.fill", title: "Notifications") {
                                showNotifications = true
                            }
                            ProfileOption(icon: "gearshape.fill", title: "Settings") {
                                showSettings = true
                            }
                            ProfileOption(icon: "questionmark.circle.fill", title: "Help & Support") {
                                showHelp = true
                            }

                            Divider()

                            Button(action: {
                                Task {
                                    await authManager.signOut()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(.error)
                                    Text("Sign Out")
                                        .foregroundColor(.error)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.surface)
                                .cornerRadius(CornerRadius.md)
                            }
                        }
                        .padding(.horizontal, Spacing.xl)
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showAllergens) {
                DietaryPreferencesView()
            }
            .sheet(isPresented: $showNotifications) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showHelp) {
                HelpSupportView()
            }
            .sheet(isPresented: $showFavorites) {
                FavoritesView()
            }
            .sheet(isPresented: $showPaymentMethods) {
                PaymentMethodsView()
            }
        }
    }
}

// MARK: - Supporting Components

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.brandPrimary)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(AppFonts.headline)
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(AppFonts.subheadline)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

struct ProfileOption: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.brandPrimary)
                    .frame(width: 30)

                Text(title)
                    .font(AppFonts.body)
                    .foregroundColor(.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var appSettings = AppSettings.shared

    var body: some View {
        NavigationView {
            List {
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $appSettings.isDarkMode)
                    Toggle("Compact View", isOn: $appSettings.isCompactView)
                }

                Section("Account") {
                    Button("Change Password") {
                        // TODO: Implement password change
                    }
                    .foregroundColor(.brandPrimary)

                    Button("Update Email") {
                        // TODO: Implement email update
                    }
                    .foregroundColor(.brandPrimary)
                }

                Section("Privacy") {
                    Toggle("Share Usage Data", isOn: $appSettings.shareUsageData)
                    Toggle("Personalized Ads", isOn: $appSettings.personalizedAds)
                }
            }
            .navigationTitle("Settings")
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

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var orderUpdates = true
    @State private var promotions = false
    @State private var newMenuItems = true

    var body: some View {
        NavigationView {
            List {
                Section("Order Notifications") {
                    Toggle("Order Updates", isOn: $orderUpdates)
                    Toggle("Ready for Pickup", isOn: $orderUpdates)
                }

                Section("Marketing") {
                    Toggle("Promotions & Offers", isOn: $promotions)
                    Toggle("New Menu Items", isOn: $newMenuItems)
                }
            }
            .navigationTitle("Notifications")
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

// MARK: - Help & Support View
struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("FAQs") {
                    NavigationLink("How do I place an order?") {
                        Text("FAQ Answer")
                    }
                    NavigationLink("How do I track my order?") {
                        Text("FAQ Answer")
                    }
                    NavigationLink("Can I cancel my order?") {
                        Text("FAQ Answer")
                    }
                }

                Section("Contact Us") {
                    Button("Call Support") {
                        if let url = URL(string: "tel://5551234567") {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Email Support") {
                        if let url = URL(string: "mailto:support@knockbites.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            .navigationTitle("Help & Support")
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

#Preview {
    MainTabView()
        .environmentObject(AuthManager.shared)
        .environmentObject(CartViewModel())
}
