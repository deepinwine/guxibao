//
//  OCRReviewView.swift
//  DividendTreasure
//
//  OCR识别结果确认页面 - 识别结果必须经过用户确认才能入库
//

import SwiftUI
import SwiftData

struct OCRReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let ocrResult: OCRResult
    let portfolio: Portfolio

    @State private var candidates: [OCRReviewCandidate] = []
    @State private var isImporting = false
    @State private var importSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 注意事项
                ImportNoticeBanner()
                    .padding(.horizontal)
                    .padding(.top, 8)

                // 候选持仓列表
                if candidates.isEmpty {
                    ContentUnavailableView(
                        "未识别到持仓信息",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("请尝试更清晰的截图")
                    )
                } else {
                    List {
                        Section("识别结果（请逐项确认）") {
                            ForEach($candidates) { $candidate in
                                OCRReviewRow(candidate: $candidate)
                            }
                            .onDelete(perform: deleteCandidate)
                        }

                        Section {
                            HStack {
                                Text("共识别")
                                Spacer()
                                Text("\(candidates.filter { $0.isConfirmed }.count)/\(candidates.count) 项")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("确认导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认导入") {
                        importConfirmedCandidates()
                    }
                    .disabled(candidates.filter { $0.isConfirmed }.isEmpty)
                    .disabled(isImporting)
                }
            }
            .overlay {
                if isImporting {
                    ProgressView("正在导入...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
            .alert("导入成功", isPresented: $importSuccess) {
                Button("完成") { dismiss() }
            } message: {
                Text("已成功导入 \(candidates.filter { $0.isConfirmed }.count) 个持仓")
            }
            .onAppear {
                loadCandidates()
            }
        }
    }

    // MARK: - 方法

    private func loadCandidates() {
        candidates = ocrResult.candidates.map { item in
            OCRReviewCandidate(
                id: item.id,
                name: item.name,
                symbol: item.symbol,
                quantity: item.quantity,
                currentPrice: item.currentPrice,
                marketValue: item.marketValue,
                confidence: item.confidence,
                isConfirmed: item.confidence > 0.7
            )
        }
    }

    private func deleteCandidate(offsets: IndexSet) {
        candidates.remove(atOffsets: offsets)
    }

    private func importConfirmedCandidates() {
        isImporting = true

        let confirmed = candidates.filter { $0.isConfirmed }

        for item in confirmed {
            let holding = Holding(
                symbol: item.symbol ?? "",
                name: item.name ?? "未知",
                market: "A股",
                quantity: item.quantity ?? 0,
                currentPrice: item.currentPrice ?? 0
            )
            holding.portfolio = portfolio
            modelContext.insert(holding)
        }

        // 尝试为每个持仓获取最新股息数据
        Task {
            for item in confirmed {
                if let symbol = item.symbol {
                    let marketCode = symbol.hasPrefix("6") ? "1" : "1"
                    let stockData = try? await StockDataService.shared.fetchStockData(
                        symbol: symbol,
                        marketCode: marketCode
                    )

                    if let data = stockData, data.latestDividend > 0 {
                        // 找到刚插入的持仓并更新
                        let descriptor = FetchDescriptor<Holding>(
                            predicate: #Predicate { $0.symbol == symbol }
                        )
                        if let holding = try? modelContext.fetch(descriptor).first {
                            holding.annualDividendPerShare = data.latestDividend
                            if data.currentPrice > 0 {
                                holding.currentPrice = data.currentPrice
                            }
                            holding.updatedAt = Date()
                        }
                    }
                }
            }

            await MainActor.run {
                isImporting = false
                importSuccess = true
            }
        }
    }
}

// MARK: - 确认候选模型

struct OCRReviewCandidate: Identifiable {
    let id: UUID
    var name: String?
    var symbol: String?
    var quantity: Double?
    var currentPrice: Double?
    var marketValue: Double?
    var confidence: Double
    var isConfirmed: Bool
}

// MARK: - 确认行视图

struct OCRReviewRow: View {
    @Binding var candidate: OCRReviewCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 确认开关
            HStack {
                Toggle(isOn: $candidate.isConfirmed) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(candidate.symbol ?? "未知代码")
                            .font(.headline)
                        Text(candidate.name ?? "未知名称")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // 置信度标识
                if candidate.confidence > 0.8 {
                    Text("高")
                        .font(.caption2)
                        .padding(4)
                        .background(.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .cornerRadius(4)
                } else if candidate.confidence > 0.5 {
                    Text("中")
                        .font(.caption2)
                        .padding(4)
                        .background(.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .cornerRadius(4)
                } else {
                    Text("低")
                        .font(.caption2)
                        .padding(4)
                        .background(.red.opacity(0.2))
                        .foregroundStyle(.red)
                        .cornerRadius(4)
                }
            }

            // 可编辑字段
            if candidate.isConfirmed {
                VStack(spacing: 8) {
                    HStack {
                        Text("股票代码")
                            .font(.caption)
                            .frame(width: 60, alignment: .leading)
                        TextField("代码", text: Binding(
                            get: { candidate.symbol ?? "" },
                            set: { candidate.symbol = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("股票名称")
                            .font(.caption)
                            .frame(width: 60, alignment: .leading)
                        TextField("名称", text: Binding(
                            get: { candidate.name ?? "" },
                            set: { candidate.name = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("持仓数量")
                            .font(.caption)
                            .frame(width: 60, alignment: .leading)
                        TextField("数量", value: Binding(
                            get: { candidate.quantity ?? 0 },
                            set: { candidate.quantity = $0 }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                    }

                    HStack {
                        Text("当前价格")
                            .font(.caption)
                            .frame(width: 60, alignment: .leading)
                        TextField("价格", value: Binding(
                            get: { candidate.currentPrice ?? 0 },
                            set: { candidate.currentPrice = $0 }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                    }
                }
                .padding(.leading, 52)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 导入注意事项

struct ImportNoticeBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("导入资产注意事项", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)

            Text("为提高识别准确率，请使用券商 App 的持仓列表页面截图。截图中应尽量包含以下信息：")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Label("品种代码", systemImage: "1.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Label("品种名称", systemImage: "2.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Label("持仓数量", systemImage: "3.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Label("当前价格或市值", systemImage: "4.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Label("成本价", systemImage: "5.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text("识别结果仅作为辅助录入，导入前请自行核对。")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    OCRReviewView(
        ocrResult: OCRResult(
            recognizedText: "测试",
            candidates: [
                OCRStockCandidate(name: "招商银行", symbol: "600036", quantity: 1000, currentPrice: 35.0, marketValue: 35000, confidence: 0.9),
                OCRStockCandidate(name: "工商银行", symbol: "601398", quantity: 5000, currentPrice: 5.2, marketValue: 26000, confidence: 0.5)
            ]
        ),
        portfolio: Portfolio(name: "主账户")
    )
}
