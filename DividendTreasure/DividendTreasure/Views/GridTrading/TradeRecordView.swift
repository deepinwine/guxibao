//
//  TradeRecordView.swift
//  DividendTreasure
//
//  交易记录页面
//

import SwiftUI

struct TradeRecordView: View {
    let holding: Holding

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("交易记录")
                    .font(.headline)
                Text("功能开发中...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("交易记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TradeRecordView(holding: Holding(symbol: "601398", name: "工商银行"))
}
