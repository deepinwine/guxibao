//
//  StockSearchView.swift
//  DividendTreasure
//
//  股票搜索页面 - 根据名称或代码搜索股票并自动获取股息率
//

import SwiftUI
import SwiftData

struct StockSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [StockSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage = ""
    @State private var showError = false

    let onSelect: (StockSearchResult, StockData?) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(
                    text: $searchText,
                    isSearching: $isSearching,
                    onSearch: performSearch
                )

                // 搜索结果
                if isSearching {
                    ProgressView("正在搜索...")
                        .frame(maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView(
                        "未找到股票",
                        systemImage: "magnifyingglass",
                        description: Text("请检查输入的股票名称或代码")
                    )
                } else if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("输入股票名称或代码开始搜索")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("例如：招商银行 或 600036")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(searchResults) { result in
                        StockSearchResultRow(
                            result: result,
                            onSelect: { selectedResult in
                                selectStock(selectedResult)
                            }
                        )
                    }
                }
            }
            .navigationTitle("股票搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("搜索失败", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        isSearching = true
        errorMessage = ""

        StockDataService.shared.searchStock(keyword: searchText) { result in
            DispatchQueue.main.async {
                isSearching = false

                switch result {
                case .success(let stocks):
                    searchResults = stocks
                case .failure(let error):
                    errorMessage = error.errorDescription ?? "未知错误"
                    showError = true
                }
            }
        }
    }

    private func selectStock(_ result: StockSearchResult) {
        // 获取股票详情数据
        StockDataService.shared.fetchStockData(symbol: result.symbol, marketCode: result.marketCode) { stockDataResult in
            DispatchQueue.main.async {
                let stockData: StockData?
                if case .success(let data) = stockDataResult {
                    stockData = data
                } else {
                    stockData = nil
                }

                onSelect(result, stockData)
                dismiss()
            }
        }
    }
}

// MARK: - 搜索栏组件

struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    let onSearch: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("输入股票名称或代码", text: $text)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        onSearch()
                    }

                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)

            Button("搜索") {
                onSearch()
            }
            .disabled(text.isEmpty)
        }
        .padding()
    }
}

// MARK: - 搜索结果行

struct StockSearchResultRow: View {
    let result: StockSearchResult
    let onSelect: (StockSearchResult) -> Void

    var body: some View {
        Button(action: { onSelect(result) }) {
            HStack(spacing: 12) {
                // 市场标识
                Circle()
                    .fill(marketColor)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text(marketBadge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }

                // 股票信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text(result.symbol)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(result.market)
                            .font(.caption)
                            .padding(4)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(4)
                    }
                }

                Spacer()

                // 选择提示
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var marketColor: Color {
        switch result.market {
        case "A股":
            return .red
        case "港股":
            return .orange
        case "美股":
            return .blue
        default:
            return .gray
        }
    }

    private var marketBadge: String {
        switch result.market {
        case "A股":
            return "A"
        case "港股":
            return "H"
        case "美股":
            return "U"
        default:
            return "?"
        }
    }
}

#Preview {
    StockSearchView { result, data in
        print("Selected: \(result.symbol) - \(result.name)")
    }
}