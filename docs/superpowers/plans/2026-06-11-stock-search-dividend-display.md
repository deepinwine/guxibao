# 股票搜索显示股息详情功能实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 在股票搜索结果中显示派息日期、股息金额和股息率信息。

**架构：** 搜索返回基本结果后立即显示，后台并行获取每只股票的详细信息，加载完成后追加显示在行下方。

**技术栈：** SwiftUI、SwiftDataService（现有API）

---

## 文件结构

| 文件 | 操作 | 职责 |
|------|------|------|
| `Views/Portfolio/StockSearchView.swift` | 修改 | 添加状态管理、并行加载逻辑、更新行组件显示详情 |

---

### 任务 1：添加状态管理

**文件：**
- 修改：`DividendTreasure/DividendTreasure/Views/Portfolio/StockSearchView.swift:14-17`

- [ ] **步骤 1：添加 stockDetails 和 loadingStates 状态变量**

在 `StockSearchView` 的现有状态变量后添加：

```swift
@Environment(\.dismiss) private var dismiss
@State private var searchText = ""
@State private var searchResults: [StockSearchResult] = []
@State private var isSearching = false
@State private var errorMessage = ""
@State private var showError = false

// 新增：存储每只股票的详细数据
@State private var stockDetails: [String: StockData] = [:]
// 新增：存储每只股票的加载状态
@State private var loadingStates: [String: Bool] = [:]
```

- [ ] **步骤 2：编译验证**

运行：`xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,id=DFF1978A-F292-40DD-B0E0-4FA00A126175' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`
预期：BUILD SUCCEEDED

---

### 任务 2：实现并行加载逻辑

**文件：**
- 修改：`DividendTreasure/DividendTreasure/Views/Portfolio/StockSearchView.swift:80-99`

- [ ] **步骤 1：修改 performSearch 方法，搜索成功后触发并行加载**

将现有的 `performSearch` 方法修改为：

```swift
private func performSearch() {
    guard !searchText.isEmpty else { return }

    isSearching = true
    errorMessage = ""
    stockDetails = [:]
    loadingStates = [:]

    StockDataService.shared.searchStock(keyword: searchText) { result in
        DispatchQueue.main.async {
            isSearching = false

            switch result {
            case .success(let stocks):
                searchResults = stocks
                // 并行加载每只股票的详细信息
                for stock in stocks {
                    loadStockDetail(for: stock)
                }
            case .failure(let error):
                errorMessage = error.errorDescription ?? "未知错误"
                showError = true
            }
        }
    }
}

// 新增：加载单只股票的详细信息
private func loadStockDetail(for result: StockSearchResult) {
    let symbol = result.symbol
    loadingStates[symbol] = true

    StockDataService.shared.fetchStockData(symbol: result.symbol, marketCode: result.marketCode) { stockDataResult in
        DispatchQueue.main.async {
            loadingStates[symbol] = false

            if case .success(let data) = stockDataResult {
                stockDetails[symbol] = data
            }
        }
    }
}
```

- [ ] **步骤 2：编译验证**

运行：`xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,id=DFF1978A-F292-40DD-B0E0-4FA00A126175' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`
预期：BUILD SUCCEEDED

---

### 任务 3：更新 StockSearchResultRow 组件

**文件：**
- 修改：`DividendTreasure/DividendTreasure/Views/Portfolio/StockSearchView.swift:160-234`

- [ ] **步骤 1：修改 StockSearchResultRow 结构体，添加参数**

将现有的 `StockSearchResultRow` 结构体替换为：

```swift
// MARK: - 搜索结果行

struct StockSearchResultRow: View {
    let result: StockSearchResult
    let stockData: StockData?
    let isLoading: Bool
    let onSelect: (StockSearchResult) -> Void

    var body: some View {
        Button(action: { onSelect(result) }) {
            VStack(alignment: .leading, spacing: 6) {
                // 第一行：市场标识 + 名称
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

                // 第二行：股息详情
                if isLoading {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("获取中...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 48)
                } else if let data = stockData {
                    dividendDetailRow(data: data)
                        .padding(.leading, 48)
                } else {
                    Text("暂无股息数据")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 48)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dividendDetailRow(data: StockData) -> some View {
        HStack(spacing: 8) {
            // 派息日期
            if let date = data.dividendDate {
                let formattedDate = formatDate(date)
                Text("最近派息：\(formattedDate)")
            } else {
                Text("最近派息：暂无")
            }

            Text("·")

            // 股息金额
            if data.latestDividend > 0 {
                Text(String(format: "%.3f元", data.latestDividend))
            } else {
                Text("暂无")
            }

            Text("·")

            // 股息率
            if data.dividendYield > 0 {
                Text(String(format: "%.1f%%", data.dividendYield * 100))
            } else {
                Text("暂无")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
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
```

- [ ] **步骤 2：编译验证**

运行：`xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,id=DFF1978A-F292-40DD-B0E0-4FA00A126175' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`
预期：BUILD SUCCEEDED

---

### 任务 4：更新搜索结果列表调用

**文件：**
- 修改：`DividendTreasure/DividendTreasure/Views/Portfolio/StockSearchView.swift:55-62`

- [ ] **步骤 1：更新 List 中的 StockSearchResultRow 调用**

将现有的 List 部分修改为：

```swift
} else {
    List(searchResults) { result in
        StockSearchResultRow(
            result: result,
            stockData: stockDetails[result.symbol],
            isLoading: loadingStates[result.symbol] ?? false,
            onSelect: { selectedResult in
                selectStock(selectedResult)
            }
        )
    }
}
```

- [ ] **步骤 2：编译验证**

运行：`xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,id=DFF1978A-F292-40DD-B0E0-4FA00A126175' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`
预期：BUILD SUCCEEDED

---

### 任务 5：最终验证和提交

- [ ] **步骤 1：完整编译验证**

运行：`xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,id=DFF1978A-F292-40DD-B0E0-4FA00A126175' build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)"`
预期：BUILD SUCCEEDED，无错误

- [ ] **步骤 2：提交代码**

```bash
git add -A
git commit -m "feat: 股票搜索结果显示股息详情

- 搜索后并行加载每只股票的详细信息
- 显示派息日期、股息金额、股息率
- 支持加载中、无数据等状态显示

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```
