//
//  StrategyTemplateView.swift
//  DividendTreasure
//
//  策略模板选择页
//

import SwiftUI

struct StrategyTemplateView: View {
    let holding: Holding
    let onComplete: ([GridTradingLevel]) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("策略模板")
                    .font(.headline)
                Text("功能开发中...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("策略模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    StrategyTemplateView(
        holding: Holding(symbol: "601398", name: "工商银行")
    ) { _ in }
}
