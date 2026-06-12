# 持仓组合表格视图 实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 在股息宝App组合详情页添加类似Excel的表格视图，展示所有持仓股票数据并自动获取实时股价。

**架构：** 在现有 PortfolioDetailView 中添加视图切换按钮，新建 PortfolioTableView 组件使用 SwiftUI Table 实现表格，复用 StockDataService 获取实时股价。

**技术栈：** SwiftUI、SwiftData、SwiftUI Table（iOS 16+）、现有 StockDataService

---

## 文件结构

| 文件 | 操作 | 职责 |
|-----|-----|------|
| `Views/Portfolio/PortfolioListView.swift` | 修改 | PortfolioDetailView 改造，添加视图切换按钮 |
| `Views/Portfolio/PortfolioTableView.swift` | 创建 | 新表格视图组件，包含股价获取和刷新逻辑 |
| `Services/StockDataService.swift` | 修改 | 添加批量并发获取股价方法 |

---

### 任务 1：在 StockDataService 添加批量获取股价方法

**文件：**
- 修改：`Services/StockDataService.swift`

**说明：** 现有 StockDataService 已有单只股票获取方法，需要添加批量并发获取方法，提升效率。

- [ ] **步骤 1：添加批量获取方法**

在 `StockDataService.swift` 文件的 `// MARK: - 异步版本（iOS 15+）` extension 之后添加新的 extension：

```swift
// MARK: - 批量获取

extension StockDataService {
    /// 批量获取多只股票的实时价格
    /// - Parameters:
    ///   - symbols: 股票代码数组，格式为 [(symbol: String, marketCode: String)]
    ///   - timeout: 超时时间，默认10秒
    /// - Returns: 字典，key为symbol，value为价格（获取失败时为nil）
    func fetchBatchPrices(
        symbols: [(symbol: String, marketCode: String)],
        timeout: TimeInterval = 10
    ) async -> [String: Double?] {
        let startTime = Date()
        
        // 并发获取所有股票价格
        var results: [String: Double?] = [:]
        
        await withTaskGroup(of: (String, Double?).self) { group in
            for (symbol, marketCode) in symbols {
                // 检查超时
                if Date().timeIntervalSince(startTime) > timeout {
                    break
                }
                
                group.addTask {
                    do {
                        let stockData = try await self.fetchStockData(symbol: symbol, marketCode: marketCode)
                        return (symbol, stockData.currentPrice)
                    } catch {
                        return (symbol, nil)
                    }
                }
            }
            
            for await (symbol, price) in group {
                results[symbol] = price
            }
        }
        
        return results
    }
}
```

- [ ] **步骤 2：Commit**

```bash
git add Services/StockDataService.swift
git commit -m "feat: 添加批量获取股价方法"
```

---

### 任务 2：创建 PortfolioTableView 组件

**文件：**
- 创建：`Views/Portfolio/PortfolioTableView.swift`

**说明：** 新建表格视图组件，展示所有持仓数据，包含实时股价获取和下拉刷新功能。

- [ ] **步骤 1：创建 PortfolioTableView.swift 文件**

创建文件 `Views/Portfolio/PortfolioTableView.swift`，内容如下：

```swift
//
//  PortfolioTableView.swift
//  DividendTreasure
//
//  持仓表格视图 - 类似Excel的表格展示
//

import SwiftUI
import SwiftData

// MARK: - 表格行数据模型

struct HoldingTableRow: Identifiable {
    let id: UUID
    let symbol: String
    let name: String
    let averageCost: Double
    let quantity: Double
    let dividendPerShare: Double
    var currentPrice: Double?
    
    // 计算属性
    var totalDividend: Double {
        dividendPerShare * quantity
    }
    
    var currentMarketValue: Double? {
        guard let price = currentPrice else { return nil }
        return price * quantity
    }
    
    var totalCost: Double {
        averageCost * quantity
    }
    
    var costYield: Double? {
        guard averageCost > 0 else { return nil }
        return dividendPerShare / averageCost
    }
    
    var actualYield: Double? {
        guard let price = currentPrice, price > 0 else { return nil }
        return dividendPerShare / price
    }
    
    init(from holding: Holding, currentPrice: Double? = nil) {
        self.id = holding.id
        self.symbol = holding.symbol
        self.name = holding.name
        self.averageCost = holding.averageCost
        self.quantity = holding.quantity
        self.dividendPerShare = holding.annualDividendPerShare
        self.currentPrice = currentPrice ?? holding.currentPrice
    }
}

// MARK: - 表格视图

struct PortfolioTableView: View {
    let portfolio: Portfolio
    @State private var tableRows: [HoldingTableRow] = []
    @State private var isLoading = false
    @State private var isRefreshing = false
    @State private var lastUpdateTime: Date?
    @State private var errorMessage: String?
    @State private var sortOrder: TableColumnSortOrderPlacement = .forward
    @State private var sortColumn: String = "name"
    
    var body: some View {
        VStack(spacing: 0) {
            // 加载状态指示器
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在获取股价...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
            }
            
            // 错误提示
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
            }
            
            // 更新时间
            if let time = lastUpdateTime {
                Text("更新于 \(formatTime(time))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            }
            
            // 表格主体
            if tableRows.isEmpty {
                ContentUnavailableView(
                    "暂无持仓",
                    systemImage: "tablecells",
                    description: Text("请先添加持仓数据")
                )
            } else {
                Table(sortedRows) {
                    TableColumn("个股名称", value: \.name) { row in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.name)
                                .font(.headline)
                                .lineLimit(1)
                            Text(row.symbol)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .width(min: 80, max: 120)
                    
                    TableColumn("实时股价") { row in
                        Text(formatPrice(row.currentPrice))
                            .foregroundStyle(row.currentPrice != nil ? .primary : .secondary)
                    }
                    .width(min: 60, max: 80)
                    
                    TableColumn("成本") { row in
                        Text(String(format: "%.3f", row.averageCost))
                    }
                    .width(min: 60, max: 80)
                    
                    TableColumn("股数") { row in
                        Text(formatQuantity(row.quantity))
                    }
                    .width(min: 50, max: 70)
                    
                    TableColumn("股息") { row in
                        Text(String(format: "%.3f", row.dividendPerShare))
                    }
                    .width(min: 50, max: 70)
                    
                    TableColumn("总股息") { row in
                        Text(formatInt(row.totalDividend))
                            .fontWeight(.medium)
                    }
                    .width(min: 60, max: 90)
                    
                    TableColumn("目前市值") { row in
                        Text(formatValue(row.currentMarketValue))
                            .foregroundStyle(.blue)
                    }
                    .width(min: 70, max: 100)
                    
                    TableColumn("总成本") { row in
                        Text(String(format: "%.1f", row.totalCost))
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 70, max: 100)
                    
                    TableColumn("成本股息率") { row in
                        Text(formatPercent(row.costYield))
                            .foregroundStyle(.orange)
                    }
                    .width(min: 70, max: 100)
                    
                    TableColumn("实际股息率") { row in
                        Text(formatPercent(row.actualYield))
                            .foregroundStyle(.green)
                    }
                    .width(min: 70, max: 100)
                }
                .tableStyle(.inset)
                .alternatingRowBackgrounds(.enabled)
                
                // 合计行
                totalsSection
            }
        }
        .refreshable {
            await refreshPrices()
        }
        .task {
            await fetchPrices()
        }
    }
    
    // MARK: - 合计行
    
    private var totalsSection: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Text("合计")
                    .font(.headline)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 16) {
                        // 总股息
                        VStack(alignment: .trailing) {
                            Text("总股息")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(formatInt(totalDividend))
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                        
                        // 目前市值
                        VStack(alignment: .trailing) {
                            Text("目前市值")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(formatValue(totalMarketValue))
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                        }
                        
                        // 总成本
                        VStack(alignment: .trailing) {
                            Text("总成本")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f", totalCost))
                                .foregroundStyle(.secondary)
                        }
                        
                        // 成本股息率
                        VStack(alignment: .trailing) {
                            Text("成本股息率")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(formatPercent(costYieldAvg))
                                .foregroundStyle(.orange)
                        }
                        
                        // 实际股息率
                        VStack(alignment: .trailing) {
                            Text("实际股息率")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(formatPercent(actualYieldAvg))
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
        }
    }
    
    // MARK: - 计算属性
    
    private var sortedRows: [HoldingTableRow] {
        tableRows.sorted { a, b in
            switch sortColumn {
            case "name":
                return sortOrder == .forward ? a.name < b.name : a.name > b.name
            case "currentPrice":
                let aPrice = a.currentPrice ?? 0
                let bPrice = b.currentPrice ?? 0
                return sortOrder == .forward ? aPrice < bPrice : aPrice > bPrice
            case "actualYield":
                let aYield = a.actualYield ?? 0
                let bYield = b.actualYield ?? 0
                return sortOrder == .forward ? aYield < bYield : aYield > bYield
            default:
                return sortOrder == .forward ? a.name < b.name : a.name > b.name
            }
        }
    }
    
    private var totalDividend: Double {
        tableRows.reduce(0) { $0 + $1.totalDividend }
    }
    
    private var totalMarketValue: Double? {
        let values = tableRows.compactMap { $0.currentMarketValue }
        return values.isEmpty ? nil : values.reduce(0, +)
    }
    
    private var totalCost: Double {
        tableRows.reduce(0) { $0 + $1.totalCost }
    }
    
    private var costYieldAvg: Double? {
        guard totalCost > 0 else { return nil }
        return totalDividend / totalCost
    }
    
    private var actualYieldAvg: Double? {
        guard let marketValue = totalMarketValue, marketValue > 0 else { return nil }
        return totalDividend / marketValue
    }
    
    // MARK: - 数据获取
    
    private func fetchPrices() async {
        guard !portfolio.holdings.isEmpty else {
            tableRows = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 初始化表格数据（使用现有价格）
        tableRows = portfolio.holdings.map { HoldingTableRow(from: $0) }
        
        // 获取股票代码列表
        let symbols: [(symbol: String, marketCode: String)] = portfolio.holdings.map { holding in
            let marketCode: String
            switch holding.market {
            case "A股":
                marketCode = "1"
            case "港股":
                marketCode = "0"
            default:
                marketCode = "1"
            }
            return (holding.symbol, marketCode)
        }
        
        // 批量获取股价
        let prices = await StockDataService.shared.fetchBatchPrices(symbols: symbols)
        
        // 更新表格数据
        for i in 0..<tableRows.count {
            let symbol = tableRows[i].symbol
            if let price = prices[symbol] {
                tableRows[i].currentPrice = price
            }
        }
        
        lastUpdateTime = Date()
        isLoading = false
        
        // 检查是否全部失败
        let successCount = prices.values.compactMap { $0 }.count
        if successCount == 0 && !prices.isEmpty {
            errorMessage = "股价获取失败，请检查网络"
        }
    }
    
    private func refreshPrices() async {
        isRefreshing = true
        await fetchPrices()
        isRefreshing = false
    }
    
    // MARK: - 格式化方法
    
    private func formatPrice(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        return String(format: "%.2f", v)
    }
    
    private func formatQuantity(_ value: Double) -> String {
        return String(format: "%.0f", value)
    }
    
    private func formatInt(_ value: Double) -> String {
        return String(format: "%.0f", value)
    }
    
    private func formatValue(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        return CurrencyFormatter.formatCompact(v)
    }
    
    private func formatPercent(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        return PercentFormatter.format(v)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    PortfolioTableView(portfolio: Portfolio(name: "测试组合"))
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}
```

- [ ] **步骤 2：Commit**

```bash
git add Views/Portfolio/PortfolioTableView.swift
git commit -m "feat: 创建PortfolioTableView表格视图组件"
```

---

### 任务 3：修改 PortfolioDetailView 添加视图切换

**文件：**
- 修改：`Views/Portfolio/PortfolioListView.swift`（PortfolioDetailView 部分）

**说明：** 在 PortfolioDetailView 中添加表格/列表视图切换按钮，整合新表格视图。

- [ ] **步骤 1：修改 PortfolioDetailView**

将 `PortfolioDetailView` 替换为以下代码：

```swift
// MARK: - 组合详情视图

struct PortfolioDetailView: View {
    let portfolio: Portfolio
    @State private var showingAddHolding = false
    @State private var showTableView = false
    
    var body: some View {
        Group {
            if showTableView {
                // 表格视图
                PortfolioTableView(portfolio: portfolio)
            } else {
                // 列表视图
                listView
            }
        }
        .navigationTitle(portfolio.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 表格切换按钮
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { showTableView.toggle() }) {
                    Image(systemName: showTableView ? "list.bullet" : "tablecells")
                }
            }
            
            // 添加持仓按钮
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddHolding = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddHolding) {
            HoldingFormView(portfolio: portfolio)
        }
    }
    
    // MARK: - 列表视图
    
    private var listView: some View {
        List {
            // 组合统计信息
            Section("组合概览") {
                HStack {
                    Text("总市值")
                    Spacer()
                    Text(CurrencyFormatter.formatCompact(marketValue))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("年度股息")
                    Spacer()
                    Text(CurrencyFormatter.formatCompact(annualDividend))
                        .foregroundStyle(.green)
                }
                
                HStack {
                    Text("组合股息率")
                    Spacer()
                    Text(PercentFormatter.format(dividendYield))
                        .foregroundStyle(.orange)
                }
                
                HStack {
                    Text("持仓数量")
                    Spacer()
                    Text("\(portfolio.holdings.count)")
                        .foregroundStyle(.secondary)
                }
            }
            
            // 持仓列表
            Section("持仓列表") {
                if portfolio.holdings.isEmpty {
                    ContentUnavailableView(
                        "暂无持仓",
                        systemImage: "chart.bar",
                        description: Text("点击右上角 + 添加持仓")
                    )
                } else {
                    ForEach(portfolio.holdings) { holding in
                        NavigationLink(destination: HoldingFormView(portfolio: portfolio, holding: holding)) {
                            HoldingRow(holding: holding)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            NavigationLink(destination: GridTradingView(holding: holding)) {
                                Label("网格交易", systemImage: "chart.xyaxis.line")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: deleteHoldings)
                }
            }
        }
    }
    
    private var marketValue: Double {
        CalculationService.portfolioMarketValue(holdings: portfolio.holdings)
    }
    
    private var annualDividend: Double {
        CalculationService.portfolioAnnualDividend(holdings: portfolio.holdings)
    }
    
    private var dividendYield: Double {
        CalculationService.portfolioDividendYield(holdings: portfolio.holdings)
    }
    
    private func deleteHoldings(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                portfolio.holdings[index].portfolio = nil
            }
        }
    }
}
```

- [ ] **步骤 2：Commit**

```bash
git add Views/Portfolio/PortfolioListView.swift
git commit -m "feat: PortfolioDetailView添加表格视图切换功能"
```

---

### 任务 4：验证构建和功能测试

**说明：** 确保代码编译成功，功能正常运行。

- [ ] **步骤 1：构建项目**

```bash
cd ~/Desktop/guxibao/DividendTreasure
xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 15' build
```

预期：BUILD SUCCEEDED

- [ ] **步骤 2：运行模拟器测试**

在 Xcode 中运行项目：
1. 创建一个测试组合
2. 添加几只持仓股票（如：中国平安、招商银行）
3. 点击右上角表格图标按钮，验证：
   - 视图切换到表格
   - 自动开始获取股价
   - 表格显示所有列数据
   - 底部合计行显示正确
4. 下拉刷新，验证股价更新

- [ ] **步骤 3：修复发现的问题**

如果发现编译错误或功能问题，修复并重新测试。

---

### 任务 5：最终 Commit

- [ ] **步骤 1：最终 Commit**

```bash
git add -A
git commit -m "feat: 完成持仓组合表格视图功能

- 添加PortfolioTableView组件，展示类似Excel的表格
- 实现批量获取实时股价功能
- 支持表格/列表视图切换
- 支持下拉刷新更新股价
- 底部显示合计行数据
"
```

---

## 验收清单

- [ ] 点击表格按钮可切换视图
- [ ] 表格展示所有持仓股票数据（10列）
- [ ] 进入表格视图自动获取股价
- [ ] 下拉刷新可更新股价
- [ ] 底部合计行数据正确
- [ ] 单只股票获取失败显示"-"
- [ ] 项目编译成功