//
//  CashflowView.swift
//  DividendTreasure
//
//  现金流视图（占位）
//

import SwiftUI

struct CashflowView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "现金流报表",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("阶段 6 实现")
            )
            .navigationTitle("现金流")
        }
    }
}

#Preview {
    CashflowView()
}
