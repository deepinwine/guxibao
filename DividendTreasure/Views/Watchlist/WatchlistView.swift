//
//  WatchlistView.swift
//  DividendTreasure
//
//  收藏视图（占位）
//

import SwiftUI

struct WatchlistView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "我的收藏",
                systemImage: "star",
                description: Text("阶段 7 实现")
            )
            .navigationTitle("收藏")
        }
    }
}

#Preview {
    WatchlistView()
}
