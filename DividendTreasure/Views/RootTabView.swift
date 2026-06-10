//
//  RootTabView.swift
//  DividendTreasure
//
//  Tab 根视图
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }

            PortfolioListView()
                .tabItem {
                    Label("组合", systemImage: "briefcase.fill")
                }

            CashflowView()
                .tabItem {
                    Label("现金流", systemImage: "chart.line.uptrend.xyaxis")
                }

            WatchlistView()
                .tabItem {
                    Label("收藏", systemImage: "star.fill")
                }

            SettingsView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}
