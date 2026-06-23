//
//  TradeOCRView.swift
//  DividendTreasure
//
//  截图识别页面
//

import SwiftUI

struct TradeOCRView: View {
    let holding: Holding
    let onComplete: (TradeRecord) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("截图识别")
                    .font(.headline)
                Text("功能开发中...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("上传截图识别")
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
    TradeOCRView(
        holding: Holding(symbol: "601398", name: "工商银行")
    ) { _ in }
}
