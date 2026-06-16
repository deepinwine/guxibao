# 资产透视重做实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 将资产透视从“只有静态统计页”升级为“首页行业优先概览 + 详情页可下钻工作台”，并补齐手动新增、搜索选股、OCR 导入三条链路的行业 / 资产类型归类。

**架构：** 以 `AssetInsightService` 为统计中心，新增首页概览模型、集中度计算、维度统一入口和下钻结果；以独立的 `HoldingClassificationService` 处理行业 / 资产类型自动补全；首页 `AssetOverviewCard` 与详情页 `AssetInsightView` 只消费整理好的统计结果，避免把归类逻辑塞进视图层。

**技术栈：** SwiftUI、SwiftData、Charts、Swift Testing、`xcodebuild`

---

## 文件结构

### 新建文件

- `DividendTreasure/DividendTreasure/Services/HoldingClassificationService.swift`
  - 负责根据 `symbol`、`name`、`market` 推导 `industry` 和 `assetType`
  - 提供首页 / 手动新增 / OCR 导入都能复用的统一入口

### 修改文件

- `DividendTreasure/DividendTreasure/Services/AssetInsightService.swift`
  - 从“几个独立 breakdown 函数”重构为“概览 + 维度统计 + 下钻”
- `DividendTreasure/DividendTreasure/Views/Dashboard/DashboardView.swift`
  - 首页改为消费新的 `AssetInsightOverview`
- `DividendTreasure/DividendTreasure/Views/Dashboard/AssetOverviewCard.swift`
  - 重做卡片结构，展示行业主视觉、集中度、市场分布、资产类型摘要
- `DividendTreasure/DividendTreasure/Views/AssetInsight/AssetInsightView.swift`
  - 重做为工作台结构，支持维度切换、金额 / 占比切换、点击分类下钻
- `DividendTreasure/DividendTreasure/Views/Portfolio/HoldingFormView.swift`
  - 搜索选股后自动回填行业和资产类型
- `DividendTreasure/DividendTreasure/Views/Import/OCRReviewView.swift`
  - 导入确认后补齐行业 / 资产类型 / 市场
- `DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift`
  - 为统计口径、集中度、归类兜底、下钻和自动补全添加回归测试

### 不修改文件

- `DividendTreasure/DividendTreasure/Models/Holding.swift`
  - 现有 `industry` / `assetType` 字段足够，本次不做模型字段扩展
- `DividendTreasure/DividendTreasure/Models/StockData.swift`
  - 不在缓存模型里新增行业字段，避免引入持久化迁移

---

### 任务 1：用测试锁定资产透视统计口径

**文件：**
- 修改：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift`
- 修改：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Services/AssetInsightService.swift`
- 测试：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift`

- [ ] **步骤 1：编写失败的统计测试**

```swift
@Test
func assetInsightOverviewBuildsIndustrySummaryAndConcentration() {
    let holdings = [
        Holding(symbol: "600036", name: "招商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 1000, averageCost: 30, currentPrice: 40, annualDividendPerShare: 1.9),
        Holding(symbol: "00700", name: "腾讯控股", market: "港股", assetType: "股票", industry: "科技", quantity: 100, averageCost: 300, currentPrice: 380, annualDividendPerShare: 2.4),
        Holding(symbol: "511880", name: "银华日利", market: "A股", assetType: "货币基金", industry: "其他", quantity: 500, averageCost: 100, currentPrice: 100, annualDividendPerShare: 0)
    ]

    let overview = AssetInsightService.overview(for: holdings)

    #expect(overview.topIndustries.map(\.category) == ["银行", "科技", "其他"])
    #expect(overview.topIndustries.first?.percentage == 40_000 / 128_000)
    #expect(overview.topThreeConcentration > 0.99)
    #expect(overview.largestHolding?.symbol == "511880")
}

@Test
func assetInsightBreakdownNormalizesEmptyIndustryIntoOther() {
    let holdings = [
        Holding(symbol: "A", name: "空行业", market: "A股", assetType: "股票", industry: "", quantity: 100, averageCost: 10, currentPrice: 12),
        Holding(symbol: "B", name: "空白行业", market: "A股", assetType: "股票", industry: "   ", quantity: 200, averageCost: 10, currentPrice: 10)
    ]

    let breakdown = AssetInsightService.breakdown(for: .industry, holdings: holdings, assetTypeGrouping: .summary)

    #expect(breakdown.count == 1)
    #expect(breakdown.first?.category == "其他")
}

@Test
func assetInsightDrilldownReturnsHoldingsInsideSelectedCategory() {
    let holdings = [
        Holding(symbol: "600036", name: "招商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 1000, averageCost: 30, currentPrice: 40),
        Holding(symbol: "601398", name: "工商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 800, averageCost: 5, currentPrice: 6),
        Holding(symbol: "00700", name: "腾讯控股", market: "港股", assetType: "股票", industry: "科技", quantity: 100, averageCost: 300, currentPrice: 380)
    ]

    let drilldown = AssetInsightService.drilldown(for: .industry, category: "银行", holdings: holdings)

    #expect(drilldown.map(\.holding.symbol) == ["600036", "601398"])
    #expect(drilldown.allSatisfy { $0.category == "银行" })
}
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```bash
xcodebuild test -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D' -only-testing:DividendTreasureTests
```

预期：

- `DividendTreasureTests/assetInsightOverviewBuildsIndustrySummaryAndConcentration` 失败
- `DividendTreasureTests/assetInsightBreakdownNormalizesEmptyIndustryIntoOther` 失败
- `DividendTreasureTests/assetInsightDrilldownReturnsHoldingsInsideSelectedCategory` 失败
- 失败原因是 `AssetInsightService` 尚无 `overview(for:)`、统一 `breakdown(for:)` 和 `drilldown(for:)`

- [ ] **步骤 3：编写最少统计实现代码**

```swift
enum AssetInsightDimension {
    case assetType
    case industry
    case market
}

enum AssetTypeGrouping {
    case summary
    case detail
}

struct AssetInsightOverview {
    let totalValue: Double
    let totalDividend: Double
    let avgYield: Double
    let topIndustries: [AssetBreakdown]
    let marketSummary: [AssetBreakdown]
    let assetTypeSummary: [AssetBreakdown]
    let topThreeConcentration: Double
    let largestHolding: Holding?
}

struct AssetDrilldownItem: Identifiable {
    let id = UUID()
    let category: String
    let holding: Holding
    let amount: Double
    let percentageWithinCategory: Double
}
```

```swift
static func overview(for holdings: [Holding]) -> AssetInsightOverview {
    let totalValue = holdings.reduce(0) { $0 + $1.marketValue }
    let totalDividend = holdings.reduce(0) { $0 + $1.annualDividend }
    let sorted = holdings.sorted { $0.marketValue > $1.marketValue }
    let topThree = sorted.prefix(3).reduce(0) { $0 + $1.marketValue }

    return AssetInsightOverview(
        totalValue: totalValue,
        totalDividend: totalDividend,
        avgYield: totalValue > 0 ? totalDividend / totalValue : 0,
        topIndustries: Array(breakdown(for: .industry, holdings: holdings, assetTypeGrouping: .summary).prefix(3)),
        marketSummary: breakdown(for: .market, holdings: holdings, assetTypeGrouping: .summary),
        assetTypeSummary: breakdown(for: .assetType, holdings: holdings, assetTypeGrouping: .summary),
        topThreeConcentration: totalValue > 0 ? topThree / totalValue : 0,
        largestHolding: sorted.first
    )
}
```

```swift
private static func normalizedIndustry(_ holding: Holding) -> String {
    let raw = holding.industry.trimmingCharacters(in: .whitespacesAndNewlines)
    return raw.isEmpty ? "其他" : raw
}
```

- [ ] **步骤 4：运行测试验证通过**

运行：

```bash
xcodebuild test -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D' -only-testing:DividendTreasureTests
```

预期：

- 上述 3 个新测试通过
- 现有 OCR / 搜索解析测试继续通过

- [ ] **步骤 5：Commit**

```bash
git add /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Services/AssetInsightService.swift /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift
git commit -m "feat(资产透视): 增加概览统计与下钻模型"
```

### 任务 2：补齐行业 / 资产类型自动归类链路

**文件：**
- 创建：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Services/HoldingClassificationService.swift`
- 修改：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Views/Portfolio/HoldingFormView.swift`
- 修改：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Views/Import/OCRReviewView.swift`
- 修改：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift`
- 测试：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift`

- [ ] **步骤 1：编写失败的归类测试**

```swift
@Test
func holdingClassificationResolvesBankAndTechnologyHoldings() {
    let bank = HoldingClassificationService.resolve(symbol: "600036", name: "招商银行", market: "A股")
    let tech = HoldingClassificationService.resolve(symbol: "00700", name: "腾讯控股", market: "港股")

    #expect(bank.assetType == "股票")
    #expect(bank.industry == "银行")
    #expect(tech.assetType == "股票")
    #expect(tech.industry == "科技")
}

@Test
func holdingClassificationDetectsFundAndFallbacksToOtherIndustry() {
    let etf = HoldingClassificationService.resolve(symbol: "510300", name: "沪深300ETF", market: "A股")
    let unknown = HoldingClassificationService.resolve(symbol: "XYZ", name: "未知资产", market: "美股")

    #expect(etf.assetType == "ETF")
    #expect(etf.industry == "其他")
    #expect(unknown.assetType == "股票")
    #expect(unknown.industry == "其他")
}
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```bash
xcodebuild test -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D' -only-testing:DividendTreasureTests
```

预期：

- `HoldingClassificationService` 不存在
- 新增的 2 个分类测试失败

- [ ] **步骤 3：编写最少归类服务与接线代码**

```swift
struct HoldingClassification {
    let assetType: String
    let industry: String
}

enum HoldingClassificationService {
    private static let exactIndustryByName: [String: String] = [
        "招商银行": "银行",
        "工商银行": "银行",
        "农业银行": "银行",
        "腾讯控股": "科技",
        "中国移动": "通信",
        "Verizon": "通信"
    ]

    static func resolve(symbol: String, name: String, market: String) -> HoldingClassification {
        if name.contains("ETF") {
            return HoldingClassification(assetType: "ETF", industry: "其他")
        }
        if let industry = exactIndustryByName[name] {
            return HoldingClassification(assetType: "股票", industry: industry)
        }
        return HoldingClassification(assetType: market == "A股" || market == "港股" || market == "美股" ? "股票" : "其他", industry: "其他")
    }
}
```

```swift
StockSearchView { result, stockData in
    symbol = result.symbol
    name = result.name
    market = result.market

    let classification = HoldingClassificationService.resolve(
        symbol: result.symbol,
        name: result.name,
        market: result.market
    )
    assetType = classification.assetType
    industry = classification.industry

    if let data = stockData, data.currentPrice > 0 {
        currentPrice = String(format: "%.2f", data.currentPrice)
    }
}
```

```swift
let classification = HoldingClassificationService.resolve(
    symbol: item.symbol ?? "",
    name: item.name ?? "未知",
    market: inferredMarket
)

let holding = Holding(
    symbol: item.symbol ?? "",
    name: item.name ?? "未知",
    market: inferredMarket,
    assetType: classification.assetType,
    industry: classification.industry,
    quantity: item.quantity ?? 0,
    currentPrice: item.currentPrice ?? 0
)
```

- [ ] **步骤 4：运行测试验证通过**

运行：

```bash
xcodebuild test -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D' -only-testing:DividendTreasureTests
```

预期：

- 新增的 2 个归类测试通过
- 任务 1 的统计测试继续通过

- [ ] **步骤 5：Commit**

```bash
git add /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Services/HoldingClassificationService.swift /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Views/Portfolio/HoldingFormView.swift /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Views/Import/OCRReviewView.swift /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift
git commit -m "feat(持仓归类): 自动补齐行业与资产类型"
```

### 任务 3：重做首页资产透视概览卡

**文件：**
- 修改：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Views/Dashboard/DashboardView.swift`
- 修改：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Views/Dashboard/AssetOverviewCard.swift`
- 修改：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift`
- 测试：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift`

- [ ] **步骤 1：补充首页概览测试**

```swift
@Test
func assetInsightOverviewIncludesMarketAndAssetTypeSummaries() {
    let holdings = [
        Holding(symbol: "600036", name: "招商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 1000, averageCost: 30, currentPrice: 40),
        Holding(symbol: "510300", name: "沪深300ETF", market: "A股", assetType: "ETF", industry: "其他", quantity: 100, averageCost: 4, currentPrice: 4.2),
        Holding(symbol: "00700", name: "腾讯控股", market: "港股", assetType: "股票", industry: "科技", quantity: 100, averageCost: 300, currentPrice: 380)
    ]

    let overview = AssetInsightService.overview(for: holdings)

    #expect(overview.marketSummary.map(\.category) == ["A股", "港股"])
    #expect(overview.assetTypeSummary.map(\.category).contains("股票"))
    #expect(overview.assetTypeSummary.map(\.category).contains("基金"))
}
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```bash
xcodebuild test -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D' -only-testing:DividendTreasureTests
```

预期：

- 新测试失败，说明 `overview(for:)` 返回值还没稳定支撑首页摘要

- [ ] **步骤 3：编写最少首页概览 UI 代码**

```swift
private var assetInsightOverview: AssetInsightOverview {
    AssetInsightService.overview(for: allHoldings)
}
```

```swift
AssetOverviewCard(
    overview: assetInsightOverview,
    portfoliosCount: portfolios.count
)
```

```swift
struct AssetOverviewCard: View {
    let overview: AssetInsightOverview
    let portfoliosCount: Int

    var body: some View {
        NavigationLink(destination: AssetInsightView()) {
            VStack(alignment: .leading, spacing: 16) {
                overviewMetrics
                industryInsight
                concentrationInsight
                summaryChips
            }
        }
    }
}
```

- [ ] **步骤 4：运行测试并构建验证通过**

运行：

```bash
xcodebuild test -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D' -only-testing:DividendTreasureTests
xcodebuild build -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D'
```

预期：

- 单元测试通过
- 首页卡片改造后编译通过

- [ ] **步骤 5：Commit**

```bash
git add /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Views/Dashboard/DashboardView.swift /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Views/Dashboard/AssetOverviewCard.swift /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift
git commit -m "feat(资产透视首页): 增加行业与集中度概览"
```

### 任务 4：把详情页升级为可下钻工作台

**文件：**
- 修改：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Views/AssetInsight/AssetInsightView.swift`
- 修改：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Services/AssetInsightService.swift`
- 测试：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift`

- [ ] **步骤 1：补充下钻排序与百分比测试**

```swift
@Test
func assetInsightDrilldownSortsByMarketValueDescending() {
    let holdings = [
        Holding(symbol: "600036", name: "招商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 1000, averageCost: 30, currentPrice: 40),
        Holding(symbol: "601398", name: "工商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 800, averageCost: 5, currentPrice: 6)
    ]

    let drilldown = AssetInsightService.drilldown(for: .industry, category: "银行", holdings: holdings)

    #expect(drilldown.first?.holding.symbol == "600036")
    #expect(drilldown.first?.percentageWithinCategory == 40_000 / 44_800)
}
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```bash
xcodebuild test -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D' -only-testing:DividendTreasureTests
```

预期：

- `percentageWithinCategory` 尚未按分类内总额计算
- 或结果排序与断言不一致

- [ ] **步骤 3：编写最少详情页交互代码**

```swift
@State private var selectedDimension: AssetInsightDimension = .industry
@State private var displayMode: DisplayMode = .amount
@State private var assetTypeGrouping: AssetTypeGrouping = .summary
@State private var selectedCategory: String?
```

```swift
private var breakdownData: [AssetBreakdown] {
    AssetInsightService.breakdown(
        for: selectedDimension,
        holdings: allHoldings,
        assetTypeGrouping: assetTypeGrouping
    )
}

private var drilldownData: [AssetDrilldownItem] {
    guard let selectedCategory else { return [] }
    return AssetInsightService.drilldown(for: selectedDimension, category: selectedCategory, holdings: allHoldings)
}
```

```swift
ForEach(breakdownData) { item in
    Button {
        selectedCategory = item.category
    } label: {
        AssetBreakdownRow(item: item, displayMode: displayMode)
    }
}

if let selectedCategory {
    AssetDrilldownSection(
        category: selectedCategory,
        items: drilldownData,
        onClose: { self.selectedCategory = nil }
    )
}
```

- [ ] **步骤 4：运行测试并构建验证通过**

运行：

```bash
xcodebuild test -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D' -only-testing:DividendTreasureTests
xcodebuild build -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D'
```

预期：

- 下钻和排序测试通过
- 详情页工作台结构编译通过

- [ ] **步骤 5：Commit**

```bash
git add /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Views/AssetInsight/AssetInsightView.swift /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure/Services/AssetInsightService.swift /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift
git commit -m "feat(资产透视详情): 支持维度切换与分类下钻"
```

### 任务 5：全量验证与收尾

**文件：**
- 修改：无
- 测试：`/Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasureTests/DividendTreasureTests.swift`

- [ ] **步骤 1：运行完整测试**

运行：

```bash
xcodebuild test -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D' -only-testing:DividendTreasureTests
```

预期：

- `DividendTreasureTests` 全部通过
- OCR、股票搜索、资产透视新增测试同时通过

- [ ] **步骤 2：运行完整构建**

运行：

```bash
xcodebuild build -project /Users/jiajia/Desktop/guxibao/DividendTreasure/DividendTreasure.xcodeproj -scheme DividendTreasure -destination 'platform=iOS Simulator,id=3B0C3568-1FDB-4DCA-A9FE-F916C8ED3D9D'
```

预期：

- `** BUILD SUCCEEDED **`

- [ ] **步骤 3：手动回归首页与详情页**

运行：

```text
1. 打开首页，确认资产透视卡出现行业占比、集中度、市场分布、资产类型分布
2. 点击资产透视卡进入详情页
3. 在详情页切换资产类型 / 行业 / 市场
4. 点击任一分类，确认出现持仓下钻列表
5. 返回总览，确认状态恢复
6. 用搜索选股新增一只持仓，确认行业和资产类型自动回填
7. 用 OCR 导入一只持仓，确认导入后行业和资产类型不是空值
```

预期：

- 首页和详情页都符合规格
- 手动新增和 OCR 导入都能带出归类字段

- [ ] **步骤 4：整理最终提交**

```bash
git status --short
git log --oneline -5
```

预期：

- 只剩本次计划内改动
- 最近提交包含统计、归类、首页、详情页 4 次功能提交

---

## 自检结果

- 规格覆盖度：已覆盖首页概览、详情页工作台、归类补全、集中度、下钻、空值兜底、测试与验证。
- 占位符扫描：计划中没有 `TODO`、`待定`、`后续补充` 之类占位描述。
- 类型一致性：统一使用 `AssetInsightDimension`、`AssetTypeGrouping`、`AssetInsightOverview`、`AssetDrilldownItem` 四个新类型名，避免任务间命名漂移。
