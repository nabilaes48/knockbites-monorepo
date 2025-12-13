//
//  SettingsView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import Supabase

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var newOrderAlerts = true
    @State private var statusUpdateAlerts = true
    @State private var autoAcceptOrders = false
    @State private var defaultPrepTime = 20
    @State private var showStoreInfo = false
    @State private var showOperatingHours = false

    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.brandPrimary)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(authManager.userProfile?.fullName ?? "")
                                    .font(AppFonts.headline)

                                Text(authManager.userProfile?.role.displayName ?? "")
                                    .font(AppFonts.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(authManager.userProfile?.role.badgeColor.opacity(0.2) ?? Color.gray.opacity(0.2))
                                    .foregroundColor(authManager.userProfile?.role.badgeColor ?? .gray)
                                    .cornerRadius(4)
                            }

                            if let phone = authManager.userProfile?.phone {
                                Text(phone)
                                    .font(AppFonts.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            Text(authManager.currentUser?.email ?? "")
                                .font(AppFonts.caption2)
                                .foregroundColor(.brandPrimary)
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }

                // Store Info
                if let storeId = authManager.userProfile?.storeId,
                   let store = MockDataService.shared.mockStores.first(where: { $0.id == String(storeId) }) {
                    Section(header: Text("Store")) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(store.name)
                                .font(AppFonts.headline)
                            Text(store.address)
                                .font(AppFonts.caption)
                                .foregroundColor(.textSecondary)
                            Text(store.phone)
                                .font(AppFonts.caption)
                                .foregroundColor(.brandPrimary)
                        }
                        .padding(.vertical, Spacing.sm)

                        if authManager.isManager() {
                            Button(action: { showStoreInfo = true }) {
                                HStack {
                                    Image(systemName: "building.2")
                                        .foregroundColor(.brandPrimary)
                                    Text("Manage Store Information")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Button(action: { showOperatingHours = true }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.brandPrimary)
                                    Text("Operating Hours")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                // Notifications Section
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)

                    if notificationsEnabled {
                        Toggle("Sound Alerts", isOn: $soundEnabled)
                        Toggle("New Order Alerts", isOn: $newOrderAlerts)
                        Toggle("Status Update Alerts", isOn: $statusUpdateAlerts)
                    }
                }

                // Order Settings Section
                Section(header: Text("Order Management")) {
                    Toggle("Auto-Accept Orders", isOn: $autoAcceptOrders)

                    HStack {
                        Text("Default Prep Time")
                        Spacer()
                        Stepper("\(defaultPrepTime) min", value: $defaultPrepTime, in: 5...60, step: 5)
                    }

                    // TODO: Implement OrderHistoryView and replace this placeholder
                    NavigationLink {
                        VStack(spacing: Spacing.lg) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 60))
                                .foregroundColor(.textSecondary)
                            Text("Order History")
                                .font(AppFonts.title2)
                                .fontWeight(.bold)
                            Text("Coming Soon")
                                .font(AppFonts.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .navigationTitle("Order History")
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.brandPrimary)
                            Text("View Order History")
                        }
                    }
                }

                // Kitchen Display Settings
                Section(header: Text("Kitchen Display")) {
                    HStack {
                        Text("Display Mode")
                        Spacer()
                        Text("Compact")
                            .foregroundColor(.textSecondary)
                    }

                    HStack {
                        Text("Auto-Refresh")
                        Spacer()
                        Text("30 sec")
                            .foregroundColor(.textSecondary)
                    }
                }

                // Receipt Settings
                Section(header: Text("Receipts")) {
                    NavigationLink(destination: ReceiptSettingsView()) {
                        HStack {
                            Image(systemName: "printer.fill")
                                .foregroundColor(.brandPrimary)
                            Text("Receipt Settings")
                        }
                    }
                }

                // App Section
                Section(header: Text("App")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.textSecondary)
                    }

                    Button("Privacy Policy") {
                        // Open privacy policy
                    }

                    Button("Terms of Service") {
                        // Open terms
                    }

                    Button("Help & Support") {
                        // Open support
                    }

                    NavigationLink(destination: DatabaseDiagnosticsView()) {
                        HStack {
                            Image(systemName: "externaldrive.badge.checkmark")
                                .foregroundColor(.brandPrimary)
                            Text("Database Diagnostics")
                        }
                    }
                }

                // Danger Zone
                if authManager.isAdmin() {
                    Section(header: Text("Danger Zone")) {
                        Button(action: {
                            // Clear cache
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.warning)
                                Text("Clear Cache")
                                    .foregroundColor(.warning)
                            }
                        }
                    }
                }

                // Sign Out Section
                Section {
                    Button(action: {
                        Task {
                            await authManager.signOut()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.error)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showStoreInfo) {
                StoreInformationView()
            }
            .sheet(isPresented: $showOperatingHours) {
                OperatingHoursView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
}
