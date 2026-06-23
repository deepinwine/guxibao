//
//  GridLevelFormView.swift
//  DividendTreasure
//
//  手动添加档位表单
//

import SwiftUI

struct GridLevelFormView: View {
    let holding: Holding
    let onComplete: (GridTradingLevel) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var price: String = ""
    @State private var quantity: String = ""
    @State private var direction: String = "买入"
    @State private var note: String = ""

    // 价格与数量必须为正数
    private var isInputValid: Bool {
        guard let p = Double(price), let q = Double(quantity) else { return false }
        return p > 0 && q > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("档位信息") {
                    Picker("方向", selection: $direction) {
                        Text("买入").tag("买入")
                        Text("卖出").tag("卖出")
                    }

                    TextField("价格", text: $price)
                        .keyboardType(.decimalPad)

                    TextField("数量", text: $quantity)
                        .keyboardType(.numberPad)
                }

                Section("备注") {
                    TextField("备注（可选）", text: $note)
                }
            }
            .navigationTitle("添加档位")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let priceValue = Double(price),
                           let quantityValue = Double(quantity) {
                            let level = GridTradingLevel(
                                price: priceValue,
                                direction: direction,
                                quantity: quantityValue,
                                note: note
                            )
                            onComplete(level)
                            dismiss()
                        }
                    }
                    // 价格与数量必须为正数，避免 0/负数破坏后续股息率计算
                    .disabled(!isInputValid)
                }
            }
        }
    }
}

#Preview {
    GridLevelFormView(
        holding: Holding(symbol: "601398", name: "工商银行")
    ) { _ in }
}
