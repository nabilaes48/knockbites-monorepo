//
//  MainTabView.swift
//  knockbites-Bussiness-app
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Orders", systemImage: "bag.fill")
                }
                .tag(0)

            KitchenDisplayView()
                .tabItem {
                    Label("Kitchen", systemImage: "flame.fill")
                }
                .tag(1)

            MenuManagementView()
                .tabItem {
                    Label("Menu", systemImage: "fork.knife")
                }
                .tag(2)

            MarketingDashboardView()
                .tabItem {
                    Label("Marketing", systemImage: "megaphone.fill")
                }
                .tag(3)

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)
        }
        .accentColor(.brandPrimary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager.shared)
}
