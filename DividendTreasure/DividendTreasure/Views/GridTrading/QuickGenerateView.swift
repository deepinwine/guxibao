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

    // 参数
    @State private var percentStep: String = "2"        // 百分比间距，默认 2%
    @State private var levelCount: String = "3"         // 档位数量，默认上下各3档
    @State private var baseQuantity: String = ""        // 每档数量（空=自动计算）

    // 预览
    @State private var previewLevels: [GridLevelParams] = []

    private let service = GridTradingService()

    var body: some View {
        NavigationStack {
            Form {
                // 参数设置
                Section("网格参数") {
                    HStack {
                        Text("网格间距")
                        Spacer()
                        TextField("2", text: $percentStep)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("上下档位")
                        Spacer()
                        TextField("3", text: $levelCount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("档")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("每档数量")
                        Spacer()
                        TextField("自动", text: $baseQuantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("股")
                            .foregroundStyle(.secondary)
                    }
                }

                // 当前价格信息
                Section("当前价格") {
                    HStack {
                        Text("当前价")
                        Spacer()
                        Text(CurrencyFormatter.formatPrice(holding.currentPrice))
                            .fontWeight(.medium)
                    }
                    if holding.annualDividendPerShare > 0 {
                        HStack {
                            Text("当前股息率")
                            Spacer()
                            Text(PercentFormatter.format(holding.dividendYield))
                                .foregroundStyle(.green)
                        }
                    }
                }

                // 预览
                Section("生成预览") {
                    if previewLevels.isEmpty {
                        Text("设置参数后点击预览")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        // 当前价格线
                        HStack {
                            Spacer()
                            Text("← 当前价 \(CurrencyFormatter.formatPrice(holding.currentPrice)) →")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                            Spacer()
                        }
                        .padding(.vertical, 4)

                        ForEach(Array(previewLevels.enumerated()), id: \.offset) { index, level in
                            HStack {
                                // 方向标签
                                Text(level.direction)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(level.direction == "买入" ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                    .foregroundStyle(level.direction == "买入" ? .green : .red)
                                    .cornerRadius(4)

                                // 价格
                                Text(CurrencyFormatter.formatPrice(level.price))
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Spacer()

                                // 股息率
                                if holding.annualDividendPerShare > 0 {
                                    let y = holding.annualDividendPerShare / level.price
                                    Text(PercentFormatter.format(y))
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }

                                // 数量
                                Text("\(String(format: "%.0f", level.quantity))股")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("快速生成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("生成") {
                        generateAndSave()
                    }
                    .disabled(previewLevels.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: percentStep) { _, _ in updatePreview() }
            .onChange(of: levelCount) { _, _ in updatePreview() }
            .onChange(of: baseQuantity) { _, _ in updatePreview() }
            .onAppear {
                updatePreview()
            }
        }
    }

    // MARK: - Actions

    private func updatePreview() {
        let step = Double(percentStep) ?? 0
        var count = Int(levelCount) ?? 0

        guard step > 0, count > 0 else {
            previewLevels = []
            return
        }

        // 限制预览档位上限，避免输入过大值导致卡顿
        count = min(count, 50)

        let qty = Double(baseQuantity)
        previewLevels = service.generateLevelsByPercent(
            holding: holding,
            percentStep: step / 100.0,  // 用户输入2表示2%
            levelCount: count,
            baseQuantity: (qty ?? 0) > 0 ? qty : nil
        )
    }

    private func generateAndSave() {
        let levels = previewLevels.map { params in
            GridTradingLevel(
                price: params.price,
                direction: params.direction,
                quantity: params.quantity,
                note: "快速生成"
            )
        }
        onComplete(levels)
        dismiss()
    }
}

#Preview {
    QuickGenerateView(
        holding: Holding(
            symbol: "601398",
            name: "工商银行",
            quantity: 1000,
            averageCost: 4.5,
            currentPrice: 4.8,
            annualDividendPerShare: 0.3
        )
    ) { _ in }
}
