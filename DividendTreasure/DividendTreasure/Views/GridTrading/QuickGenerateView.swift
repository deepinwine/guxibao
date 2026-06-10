//
//  QuickGenerateView.swift
//  DividendTreasure
//
//  快速生成档位弹窗
//

import SwiftUI

struct QuickGenerateView: View {
    let holding: Holding
    let onComplete: ([GridTradingLevel]) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("快速生成档位")
                    .font(.headline)
                Text("功能开发中...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("快速生成")
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
    QuickGenerateView(
        holding: Holding(symbol: "601398", name: "工商银行")
    ) { _ in }
}
