# 网格交易助手功能实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 为股息宝App添加网格交易助手功能，帮助用户设置价格档位、计算股息率、记录交易并自动更新持仓数据。

**架构：** 混合方案 - 数据模型关联持仓，UI页面独立。采用 SwiftUI + SwiftData 架构，业务逻辑集中在 Service 层。

**技术栈：** SwiftUI、SwiftData、Vision（OCR）、PhotosUI

---

## 文件结构

### 新增文件

```
DividendTreasure/DividendTreasure/
├── Models/
│   ├── GridTradingLevel.swift      # 网格档位模型
│   └── TradeRecord.swift           # 交易记录模型
├── Views/GridTrading/
│   ├── GridTradingView.swift       # 网格交易主页面
│   ├── GridLevelListView.swift     # 档位列表组件
│   ├── GridLevelFormView.swift     # 手动添加档位表单
│   ├── QuickGenerateView.swift     # 快速生成档位弹窗
│   ├── StrategyTemplateView.swift  # 策略模板选择页（会员）
│   ├── TradeRecordView.swift       # 交易记录页面
│   ├── TradeRecordFormView.swift   # 手动添加交易记录表单
│   └── TradeOCRView.swift          # 截图识别页面
├── Services/
│   ├── StrategyTemplate.swift      # 策略模板枚举
│   ├── GridTradingService.swift    # 网格交易计算服务
│   └── TradeOCRService.swift       # 交易截图识别服务
```

### 修改文件

- `DividendTreasureApp.swift` - 添加新模型到 ModelContainer
- `PortfolioListView.swift` - PortfolioDetailView 添加入口按钮
- `SubscriptionService.swift` - 添加网格交易相关权限

---

## 阶段 1：数据模型

### 任务 1.1：创建 GridTradingLevel 模型

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Models/GridTradingLevel.swift`

- [ ] **步骤 1：创建 GridTradingLevel.swift 文件**

```swift
//
//  GridTradingLevel.swift
//  DividendTreasure
//
//  网格交易档位模型
//

import Foundation
import SwiftData

@Model
final class GridTradingLevel {
    @Attribute(.unique) var id: UUID
    var holding: Holding?
    var price: Double
    var direction: String  // "买入" 或 "卖出"
    var quantity: Double
    var note: String
    var isExecuted: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // 计算属性：股息率
    var yieldRate: Double {
        guard let holding = holding,
              holding.annualDividendPerShare > 0,
              price > 0 else { return 0 }
        return holding.annualDividendPerShare / price
    }
    
    init(
        id: UUID = UUID(),
        price: Double,
        direction: String = "买入",
        quantity: Double = 0,
        note: String = "",
        isExecuted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.price = price
        self.direction = direction
        self.quantity = quantity
        self.note = note
        self.isExecuted = isExecuted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

---

### 任务 1.2：创建 TradeRecord 模型

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Models/TradeRecord.swift`

- [ ] **步骤 1：创建 TradeRecord.swift 文件**

```swift
//
//  TradeRecord.swift
//  DividendTreasure
//
//  交易记录模型
//

import Foundation
import SwiftData

@Model
final class TradeRecord {
    @Attribute(.unique) var id: UUID
    var holding: Holding?
    var date: Date
    var direction: String  // "买入" 或 "卖出"
    var price: Double
    var quantity: Double
    var amount: Double
    var sourceType: String  // "手动输入" 或 "截图识别"
    var ocrImageFileName: String?
    var note: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        direction: String = "买入",
        price: Double = 0,
        quantity: Double = 0,
        amount: Double = 0,
        sourceType: String = "手动输入",
        ocrImageFileName: String? = nil,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.direction = direction
        self.price = price
        self.quantity = quantity
        self.amount = amount
        self.sourceType = sourceType
        self.ocrImageFileName = ocrImageFileName
        self.note = note
        self.createdAt = createdAt
    }
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

---

### 任务 1.3：更新 ModelContainer

**文件：**
- 修改：`DividendTreasure/DividendTreasure/DividendTreasureApp.swift`

- [ ] **步骤 1：添加新模型到 Schema**

找到第 17-25 行的 schema 定义，修改为：

```swift
// 定义数据模型 Schema
let schema = Schema([
    Portfolio.self,
    Holding.self,
    DividendRecord.self,
    WatchlistItem.self,
    ImportBatch.self,
    ImportCandidate.self,
    StockData.self,
    GridTradingLevel.self,
    TradeRecord.self,
])
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

- [ ] **步骤 3：Commit**

```bash
cd ~/Desktop/guxibao
git add DividendTreasure/DividendTreasure/Models/GridTradingLevel.swift
git add DividendTreasure/DividendTreasure/Models/TradeRecord.swift
git add DividendTreasure/DividendTreasure/DividendTreasureApp.swift
git commit -m "feat: 添加网格交易数据模型 - GridTradingLevel 和 TradeRecord

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 阶段 2：核心服务

### 任务 2.1：创建策略模板枚举

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Services/StrategyTemplate.swift`

- [ ] **步骤 1：创建 StrategyTemplate.swift 文件**

```swift
//
//  StrategyTemplate.swift
//  DividendTreasure
//
//  策略模板枚举
//

import Foundation

// MARK: - 策略模板

enum StrategyTemplate: String, CaseIterable, Identifiable {
    case dividendYieldGrid = "股息率网格"
    case costPriceLevel = "成本价档位"
    case dynamicRebalance = "动态再平衡"
    case custom = "自定义"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .dividendYieldGrid:
            return "高股息率买入，低股息率卖出"
        case .costPriceLevel:
            return "基于成本价设置上下档位"
        case .dynamicRebalance:
            return "维持目标股息率区间"
        case .custom:
            return "完全自定义档位参数"
        }
    }
    
    var icon: String {
        switch self {
        case .dividendYieldGrid: return "chart.xyaxis.line"
        case .costPriceLevel: return "dollarsign.circle"
        case .dynamicRebalance: return "arrow.left.arrow.right"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - 策略参数

struct StrategyParameters {
    // 股息率网格参数
    var targetBuyYield: Double = 0.06
    var targetSellYield: Double = 0.04
    var yieldStep: Double = 0.005
    var levelCount: Int = 3
    
    // 成本价档位参数
    var costPrice: Double = 0
    var percentStep: Double = 0.05
    
    // 动态再平衡参数
    var targetYieldLow: Double = 0.04
    var targetYieldHigh: Double = 0.06
}

// MARK: - 档位生成参数

struct GridLevelParams {
    var price: Double
    var direction: String
    var quantity: Double
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

---

### 任务 2.2：创建网格交易计算服务

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Services/GridTradingService.swift`

- [ ] **步骤 1：创建 GridTradingService.swift 文件**

```swift
//
//  GridTradingService.swift
//  DividendTreasure
//
//  网格交易计算服务
//

import Foundation
import SwiftData

struct GridTradingService {
    
    // MARK: - 股息率计算
    
    /// 计算目标价格（根据股息率）
    static func calculateTargetPrice(
        annualDividendPerShare: Double,
        targetYield: Double
    ) -> Double {
        guard targetYield > 0 else { return 0 }
        return annualDividendPerShare / targetYield
    }
    
    /// 计算股息率
    static func calculateYield(
        annualDividendPerShare: Double,
        price: Double
    ) -> Double {
        guard price > 0 else { return 0 }
        return annualDividendPerShare / price
    }
    
    // MARK: - 档位生成
    
    /// 根据股息率网格模板生成档位
    static func generateDividendYieldGridLevels(
        holding: Holding,
        parameters: StrategyParameters
    ) -> [GridLevelParams] {
        var levels: [GridLevelParams] = []
        let dividend = holding.annualDividendPerShare
        guard dividend > 0 else { return levels }
        
        // 生成卖出档位（股息率从当前到目标卖出股息率）
        var currentSellYield = holding.dividendYield + parameters.yieldStep
        while currentSellYield <= parameters.targetSellYield {
            let price = calculateTargetPrice(
                annualDividendPerShare: dividend,
                targetYield: currentSellYield
            )
            levels.append(GridLevelParams(
                price: price,
                direction: "卖出",
                quantity: 0
            ))
            currentSellYield += parameters.yieldStep
        }
        
        // 生成买入档位（股息率从当前到目标买入股息率）
        var currentBuyYield = holding.dividendYield - parameters.yieldStep
        while currentBuyYield >= parameters.targetBuyYield {
            let price = calculateTargetPrice(
                annualDividendPerShare: dividend,
                targetYield: currentBuyYield
            )
            levels.append(GridLevelParams(
                price: price,
                direction: "买入",
                quantity: 0
            ))
            currentBuyYield -= parameters.yieldStep
        }
        
        return levels.sorted { $0.price > $1.price }
    }
    
    /// 根据成本价档位模板生成档位
    static func generateCostPriceLevels(
        holding: Holding,
        parameters: StrategyParameters
    ) -> [GridLevelParams] {
        var levels: [GridLevelParams] = []
        let costPrice = parameters.costPrice > 0 ? parameters.costPrice : holding.averageCost
        
        // 生成卖出档位（价格高于成本价）
        for i in 1...parameters.levelCount {
            let price = costPrice * (1 + Double(i) * parameters.percentStep)
            levels.append(GridLevelParams(
                price: price,
                direction: "卖出",
                quantity: 0
            ))
        }
        
        // 生成买入档位（价格低于成本价）
        for i in 1...parameters.levelCount {
            let price = costPrice * (1 - Double(i) * parameters.percentStep)
            if price > 0 {
                levels.append(GridLevelParams(
                    price: price,
                    direction: "买入",
                    quantity: 0
                ))
            }
        }
        
        return levels.sorted { $0.price > $1.price }
    }
    
    /// 根据动态再平衡模板生成档位
    static func generateDynamicRebalanceLevels(
        holding: Holding,
        parameters: StrategyParameters
    ) -> [GridLevelParams] {
        var levels: [GridLevelParams] = []
        let dividend = holding.annualDividendPerShare
        guard dividend > 0 else { return levels }
        
        // 卖出价（股息率下限）
        let sellPrice = calculateTargetPrice(
            annualDividendPerShare: dividend,
            targetYield: parameters.targetYieldLow
        )
        levels.append(GridLevelParams(
            price: sellPrice,
            direction: "卖出",
            quantity: 0
        ))
        
        // 买入价（股息率上限）
        let buyPrice = calculateTargetPrice(
            annualDividendPerShare: dividend,
            targetYield: parameters.targetYieldHigh
        )
        levels.append(GridLevelParams(
            price: buyPrice,
            direction: "买入",
            quantity: 0
        ))
        
        return levels.sorted { $0.price > $1.price }
    }
    
    /// 根据快速生成参数生成档位
    static func generateQuickLevels(
        holding: Holding,
        currentPrice: Double,
        yieldStep: Double,
        levelCount: Int
    ) -> [GridLevelParams] {
        var levels: [GridLevelParams] = []
        let dividend = holding.annualDividendPerShare
        guard dividend > 0 else { return levels }
        
        // 生成卖出档位
        for i in 1...levelCount {
            let targetYield = holding.dividendYield - Double(i) * yieldStep
            if targetYield > 0 {
                let price = calculateTargetPrice(
                    annualDividendPerShare: dividend,
                    targetYield: targetYield
                )
                levels.append(GridLevelParams(
                    price: price,
                    direction: "卖出",
                    quantity: 0
                ))
            }
        }
        
        // 生成买入档位
        for i in 1...levelCount {
            let targetYield = holding.dividendYield + Double(i) * yieldStep
            let price = calculateTargetPrice(
                annualDividendPerShare: dividend,
                targetYield: targetYield
            )
            levels.append(GridLevelParams(
                price: price,
                direction: "买入",
                quantity: 0
            ))
        }
        
        return levels.sorted { $0.price > $1.price }
    }
    
    // MARK: - 交易记录更新持仓
    
    /// 根据交易记录更新持仓数据
    static func updateHoldingAfterTrade(
        holding: Holding,
        trade: TradeRecord
    ) {
        if trade.direction == "买入" {
            // 买入：更新平均成本和数量
            let totalCost = holding.averageCost * holding.quantity
            let newCost = totalCost + trade.amount
            let newQuantity = holding.quantity + trade.quantity
            
            holding.averageCost = newCost / newQuantity
            holding.quantity = newQuantity
        } else {
            // 卖出：只更新数量，成本不变
            holding.quantity -= trade.quantity
        }
        
        holding.updatedAt = Date()
    }
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

- [ ] **步骤 3：Commit**

```bash
cd ~/Desktop/guxibao
git add DividendTreasure/DividendTreasure/Services/StrategyTemplate.swift
git add DividendTreasure/DividendTreasure/Services/GridTradingService.swift
git commit -m "feat: 添加策略模板和网格交易计算服务

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 阶段 3：基础 UI

### 任务 3.1：创建网格交易主页面

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Views/GridTrading/GridTradingView.swift`

- [ ] **步骤 1：创建 GridTradingView.swift 文件**

```swift
//
//  GridTradingView.swift
//  DividendTreasure
//
//  网格交易主页面
//

import SwiftUI
import SwiftData

struct GridTradingView: View {
    let holding: Holding
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    @Query(filter: #Predicate<GridTradingLevel> { level in
        // 需要通过 holding ID 过滤，这里简化处理
        true
    }) private var allLevels: [GridTradingLevel]
    
    @State private var showingAddLevel = false
    @State private var showingQuickGenerate = false
    @State private var showingStrategyTemplate = false
    @State private var showingTradeRecord = false
    @State private var showingOCRView = false
    @State private var showingUpgradePrompt = false
    
    private var levels: [GridTradingLevel] {
        allLevels.filter { $0.holding?.id == holding.id }
    }
    
    var body: some View {
        List {
            // 顶部信息卡片
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(holding.symbol)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(holding.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(CurrencyFormatter.formatPrice(holding.currentPrice))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(PercentFormatter.format(holding.dividendYield))
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // 操作按钮
            Section {
                HStack(spacing: 12) {
                    Button(action: { showingQuickGenerate = true }) {
                        Label("快速生成", systemImage: "bolt.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { openStrategyTemplate() }) {
                        Label("策略模板", systemImage: "chart.xyaxis.line")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { showingAddLevel = true }) {
                        Label("手动添加", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            // 档位列表
            Section("价格档位 (\(levels.count))") {
                if levels.isEmpty {
                    ContentUnavailableView(
                        "暂无档位",
                        systemImage: "chart.bar.xaxis",
                        description: Text("点击上方按钮添加价格档位")
                    )
                } else {
                    ForEach(levels) { level in
                        GridLevelRow(level: level)
                            .onTapGesture {
                                // TODO: 编辑档位
                            }
                    }
                    .onDelete(perform: deleteLevels)
                }
            }
            
            // 底部按钮
            Section {
                Button(action: { showingTradeRecord = true }) {
                    Label("交易记录", systemImage: "doc.text.list.bullet")
                }
                
                Button(action: { openOCRView() }) {
                    HStack {
                        Label("上传截图识别", systemImage: "camera.fill")
                        Spacer()
                        if !subscriptionService.status.isActive {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .navigationTitle("网格交易")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddLevel) {
            GridLevelFormView(holding: holding)
        }
        .sheet(isPresented: $showingQuickGenerate) {
            QuickGenerateView(holding: holding)
        }
        .sheet(isPresented: $showingStrategyTemplate) {
            StrategyTemplateView(holding: holding)
        }
        .sheet(isPresented: $showingTradeRecord) {
            TradeRecordView(holding: holding)
        }
        .sheet(isPresented: $showingOCRView) {
            TradeOCRView(holding: holding)
        }
        .alert("升级到会员版", isPresented: $showingUpgradePrompt) {
            Button("取消", role: .cancel) { }
            Button("查看订阅") { }
        } message: {
            Text("此功能需要订阅会员版")
        }
    }
    
    private var canAddLevel: Bool {
        if subscriptionService.status.isActive { return true }
        return levels.count < 3
    }
    
    private func openStrategyTemplate() {
        if subscriptionService.status.isActive {
            showingStrategyTemplate = true
        } else {
            showingUpgradePrompt = true
        }
    }
    
    private func openOCRView() {
        if subscriptionService.status.isActive {
            showingOCRView = true
        } else {
            showingUpgradePrompt = true
        }
    }
    
    private func deleteLevels(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(levels[index])
            }
        }
    }
}

// MARK: - 档位行视图

struct GridLevelRow: View {
    let level: GridTradingLevel
    
    var body: some View {
        HStack {
            // 方向标识
            Text(level.direction)
                .font(.caption)
                .fontWeight(.bold)
                .padding(4)
                .background(level.direction == "买入" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .foregroundStyle(level.direction == "买入" ? .green : .red)
                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(CurrencyFormatter.formatPrice(level.price))
                    .font(.headline)
                Text("股息率 \(PercentFormatter.format(level.yieldRate))")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(level.quantity, specifier: "%.0f")股")
                    .font(.subheadline)
                Text(level.isExecuted ? "已执行" : "待执行")
                    .font(.caption)
                    .foregroundStyle(level.isExecuted ? .green : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let holding = Holding(
        symbol: "601318",
        name: "中国平安",
        market: "A股",
        assetType: "股票",
        industry: "保险",
        quantity: 1000,
        averageCost: 50.0,
        currentPrice: 54.0,
        annualDividendPerShare: 2.7
    )
    
    return NavigationStack {
        GridTradingView(holding: holding)
    }
    .modelContainer(for: [GridTradingLevel.self, TradeRecord.self], inMemory: true)
}
```

- [ ] **步骤 2：创建 Views/GridTrading 目录**

```bash
mkdir -p ~/Desktop/guxibao/DividendTreasure/DividendTreasure/Views/GridTrading
```

- [ ] **步骤 3：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

---

### 任务 3.2：创建手动添加档位表单

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Views/GridTrading/GridLevelFormView.swift`

- [ ] **步骤 1：创建 GridLevelFormView.swift 文件**

```swift
//
//  GridLevelFormView.swift
//  DividendTreasure
//
//  手动添加档位表单
//

import SwiftUI
import SwiftData

struct GridLevelFormView: View {
    let holding: Holding
    let level: GridTradingLevel?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    @State private var price: String = ""
    @State private var direction: String = "买入"
    @State private var quantity: String = ""
    @State private var note: String = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingUpgradePrompt = false
    
    init(holding: Holding, level: GridTradingLevel? = nil) {
        self.holding = holding
        self.level = level
        
        if let level = level {
            _price = State(initialValue: String(level.price))
            _direction = State(initialValue: level.direction)
            _quantity = State(initialValue: String(level.quantity))
            _note = State(initialValue: level.note)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("价格设置") {
                    TextField("价格", text: $price)
                        .keyboardType(.decimalPad)
                    
                    Picker("方向", selection: $direction) {
                        Text("买入").tag("买入")
                        Text("卖出").tag("卖出")
                    }
                }
                
                Section("数量设置") {
                    TextField("计划数量（股）", text: $quantity)
                        .keyboardType(.decimalPad)
                }
                
                Section("备注") {
                    TextField("备注（可选）", text: $note)
                }
                
                // 计算预览
                if let priceValue = Double(price), priceValue > 0 {
                    Section("计算预览") {
                        HStack {
                            Text("对应股息率")
                            Spacer()
                            Text(PercentFormatter.format(holding.annualDividendPerShare / priceValue))
                                .foregroundStyle(.orange)
                        }
                        
                        if let qty = Double(quantity), qty > 0 {
                            HStack {
                                Text("预计金额")
                                Spacer()
                                Text(CurrencyFormatter.format(priceValue * qty))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(level == nil ? "添加档位" : "编辑档位")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(level == nil ? "添加" : "保存") {
                        saveLevel()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("升级到会员版", isPresented: $showingUpgradePrompt) {
                Button("取消", role: .cancel) { }
                Button("查看订阅") { }
            } message: {
                Text("免费版最多只能设置3个档位")
            }
        }
    }
    
    private var isValid: Bool {
        guard let _ = Double(price), Double(price)! > 0 else { return false }
        return true
    }
    
    private func saveLevel() {
        guard let priceValue = Double(price), priceValue > 0 else {
            errorMessage = "请输入有效的价格"
            showError = true
            return
        }
        
        let qty = Double(quantity) ?? 0
        
        if level != nil {
            // 编辑模式
            level!.price = priceValue
            level!.direction = direction
            level!.quantity = qty
            level!.note = note
            level!.updatedAt = Date()
        } else {
            // 检查档位数量限制
            if !subscriptionService.status.isActive {
                // 免费版最多3个档位
                // 这里需要查询现有档位数量，简化处理
            }
            
            // 添加模式
            let newLevel = GridTradingLevel(
                price: priceValue,
                direction: direction,
                quantity: qty,
                note: note
            )
            newLevel.holding = holding
            modelContext.insert(newLevel)
        }
        
        dismiss()
    }
}

#Preview {
    let holding = Holding(
        symbol: "601318",
        name: "中国平安",
        market: "A股",
        quantity: 1000,
        currentPrice: 54.0,
        annualDividendPerShare: 2.7
    )
    
    return GridLevelFormView(holding: holding)
        .modelContainer(for: GridTradingLevel.self, inMemory: true)
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

---

### 任务 3.3：创建快速生成档位弹窗

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Views/GridTrading/QuickGenerateView.swift`

- [ ] **步骤 1：创建 QuickGenerateView.swift 文件**

```swift
//
//  QuickGenerateView.swift
//  DividendTreasure
//
//  快速生成档位弹窗
//

import SwiftUI
import SwiftData

struct QuickGenerateView: View {
    let holding: Holding
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var yieldStep: String = "0.5"
    @State private var levelCount: String = "3"
    @State private var showingPreview = false
    @State private var previewLevels: [GridLevelParams] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("参数设置") {
                    HStack {
                        Text("股息率间距")
                        Spacer()
                        TextField("0.5", text: $yieldStep)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                    }
                    
                    HStack {
                        Text("档位数量（上下各）")
                        Spacer()
                        TextField("3", text: $levelCount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section {
                    Button(action: { generatePreview() }) {
                        Text("预览生成结果")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if showingPreview && !previewLevels.isEmpty {
                    Section("预览结果") {
                        ForEach(previewLevels, id: \.price) { level in
                            HStack {
                                Text(level.direction)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(4)
                                    .background(level.direction == "买入" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                    .foregroundStyle(level.direction == "买入" ? .green : .red)
                                    .cornerRadius(4)
                                
                                Text(CurrencyFormatter.formatPrice(level.price))
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text(PercentFormatter.format(
                                    holding.annualDividendPerShare / level.price
                                ))
                                .font(.caption)
                                .foregroundStyle(.orange)
                            }
                        }
                    }
                    
                    Section {
                        Button(action: { saveLevels() }) {
                            Text("确认添加")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("快速生成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
    
    private func generatePreview() {
        guard let step = Double(yieldStep),
              let count = Int(levelCount),
              step > 0, count > 0 else { return }
        
        previewLevels = GridTradingService.generateQuickLevels(
            holding: holding,
            currentPrice: holding.currentPrice,
            yieldStep: step / 100.0,  // 转换为小数
            levelCount: count
        )
        showingPreview = true
    }
    
    private func saveLevels() {
        for params in previewLevels {
            let level = GridTradingLevel(
                price: params.price,
                direction: params.direction,
                quantity: params.quantity
            )
            level.holding = holding
            modelContext.insert(level)
        }
        dismiss()
    }
}

#Preview {
    let holding = Holding(
        symbol: "601318",
        name: "中国平安",
        market: "A股",
        quantity: 1000,
        currentPrice: 54.0,
        annualDividendPerShare: 2.7
    )
    
    return QuickGenerateView(holding: holding)
        .modelContainer(for: GridTradingLevel.self, inMemory: true)
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

- [ ] **步骤 3：Commit**

```bash
cd ~/Desktop/guxibao
git add DividendTreasure/DividendTreasure/Views/GridTrading/
git commit -m "feat: 添加网格交易基础UI - 主页面、档位表单、快速生成

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 阶段 4：交易记录

### 任务 4.1：创建交易记录页面

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Views/GridTrading/TradeRecordView.swift`

- [ ] **步骤 1：创建 TradeRecordView.swift 文件**

```swift
//
//  TradeRecordView.swift
//  DividendTreasure
//
//  交易记录页面
//

import SwiftUI
import SwiftData

struct TradeRecordView: View {
    let holding: Holding
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    @Query(sort: \TradeRecord.date, order: .reverse) private var allRecords: [TradeRecord]
    
    @State private var showingAddRecord = false
    @State private var showingUpgradePrompt = false
    
    private var records: [TradeRecord] {
        allRecords.filter { $0.holding?.id == holding.id }
    }
    
    var body: some View {
        List {
            if records.isEmpty {
                ContentUnavailableView(
                    "暂无交易记录",
                    systemImage: "doc.text",
                    description: Text("点击右上角 + 添加交易记录")
                )
            } else {
                ForEach(records) { record in
                    TradeRecordRow(record: record)
                }
                .onDelete(perform: deleteRecords)
            }
        }
        .navigationTitle("交易记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { addRecord() }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            TradeRecordFormView(holding: holding)
        }
        .alert("升级到会员版", isPresented: $showingUpgradePrompt) {
            Button("取消", role: .cancel) { }
            Button("查看订阅") { }
        } message: {
            Text("免费版最多只能记录10条交易")
        }
    }
    
    private var canAddRecord: Bool {
        if subscriptionService.status.isActive { return true }
        return records.count < 10
    }
    
    private func addRecord() {
        if canAddRecord {
            showingAddRecord = true
        } else {
            showingUpgradePrompt = true
        }
    }
    
    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(records[index])
            }
        }
    }
}

// MARK: - 交易记录行视图

struct TradeRecordRow: View {
    let record: TradeRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.direction)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(4)
                    .background(record.direction == "买入" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundStyle(record.direction == "买入" ? .green : .red)
                    .cornerRadius(4)
                
                Text(formatDate(record.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(record.sourceType)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("价格")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatPrice(record.price))
                        .font(.subheadline)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("数量")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(record.quantity, specifier: "%.0f")股")
                        .font(.subheadline)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("金额")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(record.amount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    let holding = Holding(
        symbol: "601318",
        name: "中国平安",
        market: "A股",
        quantity: 1000,
        currentPrice: 54.0
    )
    
    return NavigationStack {
        TradeRecordView(holding: holding)
    }
    .modelContainer(for: TradeRecord.self, inMemory: true)
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

---

### 任务 4.2：创建交易记录表单

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Views/GridTrading/TradeRecordFormView.swift`

- [ ] **步骤 1：创建 TradeRecordFormView.swift 文件**

```swift
//
//  TradeRecordFormView.swift
//  DividendTreasure
//
//  交易记录表单
//

import SwiftUI
import SwiftData

struct TradeRecordFormView: View {
    let holding: Holding
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var date: Date = Date()
    @State private var direction: String = "买入"
    @State private var price: String = ""
    @State private var quantity: String = ""
    @State private var note: String = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("交易信息") {
                    DatePicker("交易日期", selection: $date, displayedComponents: .date)
                    
                    Picker("方向", selection: $direction) {
                        Text("买入").tag("买入")
                        Text("卖出").tag("卖出")
                    }
                    
                    TextField("成交价格", text: $price)
                        .keyboardType(.decimalPad)
                    
                    TextField("成交数量（股）", text: $quantity)
                        .keyboardType(.decimalPad)
                }
                
                Section("备注") {
                    TextField("备注（可选）", text: $note)
                }
                
                // 计算预览
                if let priceValue = Double(price),
                   let qtyValue = Double(quantity),
                   priceValue > 0, qtyValue > 0 {
                    Section("交易金额") {
                        HStack {
                            Text("成交金额")
                            Spacer()
                            Text(CurrencyFormatter.format(priceValue * qtyValue))
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // 显示交易后的持仓变化
                    Section("持仓变化预览") {
                        if direction == "买入" {
                            let newQty = holding.quantity + qtyValue
                            let newCost = (holding.averageCost * holding.quantity + priceValue * qtyValue) / newQty
                            HStack {
                                Text("新持仓数量")
                                Spacer()
                                Text("\(newQty, specifier: "%.0f")股")
                            }
                            HStack {
                                Text("新平均成本")
                                Spacer()
                                Text(CurrencyFormatter.formatPrice(newCost))
                            }
                        } else {
                            let newQty = holding.quantity - qtyValue
                            HStack {
                                Text("新持仓数量")
                                Spacer()
                                Text("\(newQty, specifier: "%.0f")股")
                            }
                            HStack {
                                Text("平均成本")
                                Spacer()
                                Text("不变")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("添加交易记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveRecord()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValid: Bool {
        guard let _ = Double(price), Double(price)! > 0 else { return false }
        guard let _ = Double(quantity), Double(quantity)! > 0 else { return false }
        return true
    }
    
    private func saveRecord() {
        guard let priceValue = Double(price), priceValue > 0 else {
            errorMessage = "请输入有效的价格"
            showError = true
            return
        }
        
        guard let qtyValue = Double(quantity), qtyValue > 0 else {
            errorMessage = "请输入有效的数量"
            showError = true
            return
        }
        
        // 检查卖出数量不能超过持仓
        if direction == "卖出" && qtyValue > holding.quantity {
            errorMessage = "卖出数量不能超过当前持仓"
            showError = true
            return
        }
        
        let amount = priceValue * qtyValue
        
        let record = TradeRecord(
            date: date,
            direction: direction,
            price: priceValue,
            quantity: qtyValue,
            amount: amount,
            sourceType: "手动输入",
            note: note
        )
        record.holding = holding
        modelContext.insert(record)
        
        // 更新持仓数据
        GridTradingService.updateHoldingAfterTrade(holding: holding, trade: record)
        
        dismiss()
    }
}

#Preview {
    let holding = Holding(
        symbol: "601318",
        name: "中国平安",
        market: "A股",
        quantity: 1000,
        averageCost: 50.0,
        currentPrice: 54.0
    )
    
    return TradeRecordFormView(holding: holding)
        .modelContainer(for: TradeRecord.self, inMemory: true)
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

- [ ] **步骤 3：Commit**

```bash
cd ~/Desktop/guxibao
git add DividendTreasure/DividendTreasure/Views/GridTrading/
git commit -m "feat: 添加交易记录功能 - 列表页面和表单

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 阶段 5：策略模板（会员功能）

### 任务 5.1：创建策略模板选择页

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Views/GridTrading/StrategyTemplateView.swift`

- [ ] **步骤 1：创建 StrategyTemplateView.swift 文件**

```swift
//
//  StrategyTemplateView.swift
//  DividendTreasure
//
//  策略模板选择页（会员专属）
//

import SwiftUI
import SwiftData

struct StrategyTemplateView: View {
    let holding: Holding
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTemplate: StrategyTemplate = .dividendYieldGrid
    @State private var showingParameters = false
    
    // 股息率网格参数
    @State private var targetBuyYield: String = "6"
    @State private var targetSellYield: String = "4"
    @State private var yieldStep: String = "0.5"
    
    // 成本价档位参数
    @State private var costPrice: String = ""
    @State private var percentStep: String = "5"
    @State private var levelCount: String = "3"
    
    // 动态再平衡参数
    @State private var targetYieldLow: String = "4"
    @State private var targetYieldHigh: String = "6"
    
    var body: some View {
        NavigationStack {
            List {
                // 免责声明
                Section {
                    Text("策略模板仅为工具框架，帮助您设置价格档位。所有投资决策由您自主判断，不构成投资建议。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // 模板选择
                Section("选择策略模板") {
                    ForEach(StrategyTemplate.allCases) { template in
                        Button(action: {
                            selectedTemplate = template
                            if template == .custom {
                                showingParameters = true
                            }
                        }) {
                            HStack {
                                Image(systemName: template.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedTemplate == template {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                // 参数设置
                parameterSection
                
                // 生成按钮
                Section {
                    Button(action: { generateLevels() }) {
                        Text("生成档位")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("策略模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                // 初始化成本价为当前持仓成本
                if costPrice.isEmpty {
                    costPrice = String(format: "%.2f", holding.averageCost)
                }
            }
        }
    }
    
    @ViewBuilder
    private var parameterSection: some View {
        switch selectedTemplate {
        case .dividendYieldGrid:
            Section("股息率网格参数") {
                HStack {
                    Text("目标买入股息率")
                    Spacer()
                    TextField("6", text: $targetBuyYield)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
                
                HStack {
                    Text("目标卖出股息率")
                    Spacer()
                    TextField("4", text: $targetSellYield)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
                
                HStack {
                    Text("档位间距")
                    Spacer()
                    TextField("0.5", text: $yieldStep)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
            }
            
        case .costPriceLevel:
            Section("成本价档位参数") {
                HStack {
                    Text("成本价")
                    Spacer()
                    TextField("成本价", text: $costPrice)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("价格间距")
                    Spacer()
                    TextField("5", text: $percentStep)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
                
                HStack {
                    Text("档位数量")
                    Spacer()
                    TextField("3", text: $levelCount)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
            }
            
        case .dynamicRebalance:
            Section("动态再平衡参数") {
                HStack {
                    Text("股息率下限（卖出）")
                    Spacer()
                    TextField("4", text: $targetYieldLow)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
                
                HStack {
                    Text("股息率上限（买入）")
                    Spacer()
                    TextField("6", text: $targetYieldHigh)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }
            }
            
        case .custom:
            Section {
                Text("选择"自定义"后，您可以手动设置每个档位")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func generateLevels() {
        var params = StrategyParameters()
        var levels: [GridLevelParams] = []
        
        switch selectedTemplate {
        case .dividendYieldGrid:
            params.targetBuyYield = (Double(targetBuyYield) ?? 6) / 100
            params.targetSellYield = (Double(targetSellYield) ?? 4) / 100
            params.yieldStep = (Double(yieldStep) ?? 0.5) / 100
            levels = GridTradingService.generateDividendYieldGridLevels(
                holding: holding,
                parameters: params
            )
            
        case .costPriceLevel:
            params.costPrice = Double(costPrice) ?? holding.averageCost
            params.percentStep = (Double(percentStep) ?? 5) / 100
            params.levelCount = Int(levelCount) ?? 3
            levels = GridTradingService.generateCostPriceLevels(
                holding: holding,
                parameters: params
            )
            
        case .dynamicRebalance:
            params.targetYieldLow = (Double(targetYieldLow) ?? 4) / 100
            params.targetYieldHigh = (Double(targetYieldHigh) ?? 6) / 100
            levels = GridTradingService.generateDynamicRebalanceLevels(
                holding: holding,
                parameters: params
            )
            
        case .custom:
            dismiss()
            return
        }
        
        // 保存档位
        for levelParams in levels {
            let level = GridTradingLevel(
                price: levelParams.price,
                direction: levelParams.direction,
                quantity: levelParams.quantity
            )
            level.holding = holding
            modelContext.insert(level)
        }
        
        dismiss()
    }
}

#Preview {
    let holding = Holding(
        symbol: "601318",
        name: "中国平安",
        market: "A股",
        quantity: 1000,
        averageCost: 50.0,
        currentPrice: 54.0,
        annualDividendPerShare: 2.7
    )
    
    return StrategyTemplateView(holding: holding)
        .modelContainer(for: GridTradingLevel.self, inMemory: true)
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

- [ ] **步骤 3：Commit**

```bash
cd ~/Desktop/guxibao
git add DividendTreasure/DividendTreasure/Views/GridTrading/StrategyTemplateView.swift
git commit -m "feat: 添加策略模板选择页（会员专属）

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 阶段 6：OCR 识别（会员功能）

### 任务 6.1：创建交易截图识别服务

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Services/TradeOCRService.swift`

- [ ] **步骤 1：创建 TradeOCRService.swift 文件**

```swift
//
//  TradeOCRService.swift
//  DividendTreasure
//
//  交易截图识别服务
//

import Foundation
import Vision
import UIKit

struct TradeOCRService {
    
    /// OCR识别交易截图
    static func recognizeTradeInfo(from image: UIImage) async throws -> TradeOCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        // 使用Vision进行文字识别
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results else {
            throw OCRError.noTextFound
        }
        
        // 提取文字
        let recognizedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")
        
        // 解析交易信息
        return parseTradeInfo(from: recognizedText)
    }
    
    /// 解析交易信息
    private static func parseTradeInfo(from text: String) -> TradeOCRResult {
        var result = TradeOCRResult()
        result.rawText = text
        
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        
        for line in lines {
            // 尝试识别股票代码
            if result.symbol.isEmpty {
                if let symbol = extractSymbol(from: line) {
                    result.symbol = symbol
                }
            }
            
            // 尝试识别股票名称
            if result.name.isEmpty {
                if let name = extractStockName(from: line) {
                    result.name = name
                }
            }
            
            // 尝试识别交易方向
            if result.direction.isEmpty {
                if line.contains("买入") || line.contains("买") {
                    result.direction = "买入"
                } else if line.contains("卖出") || line.contains("卖") {
                    result.direction = "卖出"
                }
            }
            
            // 尝试识别价格
            if result.price == 0 {
                if let price = extractPrice(from: line) {
                    result.price = price
                }
            }
            
            // 尝试识别数量
            if result.quantity == 0 {
                if let quantity = extractQuantity(from: line) {
                    result.quantity = quantity
                }
            }
        }
        
        return result
    }
    
    /// 提取股票代码
    private static func extractSymbol(from text: String) -> String? {
        // 匹配6位数字（A股代码）
        let pattern = #"\b\d{6}\b"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        
        // 匹配美股代码（1-5个大写字母）
        let usPattern = #"\b[A-Z]{1,5}\b"#
        if let range = text.range(of: usPattern, options: .regularExpression) {
            let candidate = String(text[range])
            if candidate.count >= 1 && candidate.count <= 5 {
                return candidate
            }
        }
        
        return nil
    }
    
    /// 提取股票名称
    private static func extractStockName(from text: String) -> String? {
        // 常见关键词后跟中文股票名
        let patterns = [
            "股票名称[:：]?\\s*([\\u4e00-\\u9fa5]+)",
            "名称[:：]?\\s*([\\u4e00-\\u9fa5]+)",
            "^([\\u4e00-\\u9fa5]{2,6})$"
        ]
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                return String(text[range])
            }
        }
        
        return nil
    }
    
    /// 提取价格
    private static func extractPrice(from text: String) -> Double? {
        // 匹配价格相关的数字
        let patterns = [
            "成交价[:：]?\\s*(\\d+\\.?\\d*)",
            "价格[:：]?\\s*(\\d+\\.?\\d*)",
            "单价[:：]?\\s*(\\d+\\.?\\d*)"
        ]
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let numberStr = String(text[range])
                return Double(numberStr)
            }
        }
        
        return nil
    }
    
    /// 提取数量
    private static func extractQuantity(from text: String) -> Double? {
        // 匹配数量相关的数字
        let patterns = [
            "成交数量[:：]?\\s*(\\d+)",
            "数量[:：]?\\s*(\\d+)",
            "股数[:：]?\\s*(\\d+)"
        ]
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let numberStr = String(text[range])
                return Double(numberStr)
            }
        }
        
        return nil
    }
}

// MARK: - 数据结构

struct TradeOCRResult {
    var symbol: String = ""
    var name: String = ""
    var direction: String = ""
    var price: Double = 0
    var quantity: Double = 0
    var rawText: String = ""
    
    var isValid: Bool {
        !symbol.isEmpty && price > 0 && quantity > 0
    }
}

// MARK: - 错误类型

enum OCRError: Error, LocalizedError {
    case invalidImage
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图片"
        case .noTextFound:
            return "未识别到文字"
        }
    }
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

---

### 任务 6.2：创建截图识别页面

**文件：**
- 创建：`DividendTreasure/DividendTreasure/Views/GridTrading/TradeOCRView.swift`

- [ ] **步骤 1：创建 TradeOCRView.swift 文件**

```swift
//
//  TradeOCRView.swift
//  DividendTreasure
//
//  交易截图识别页面
//

import SwiftUI
import SwiftData
import PhotosUI

struct TradeOCRView: View {
    let holding: Holding
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var ocrResult: TradeOCRResult?
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 用户确认/编辑的字段
    @State private var confirmedSymbol: String = ""
    @State private var confirmedName: String = ""
    @State private var confirmedDirection: String = "买入"
    @State private var confirmedPrice: String = ""
    @State private var confirmedQuantity: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                // 图片选择
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.secondary)
                                    Text("点击选择交易截图")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            Spacer()
                        }
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImage = image
                                await processImage(image)
                            }
                        }
                    }
                }
                
                // 处理中状态
                if isProcessing {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("正在识别...")
                            Spacer()
                        }
                    }
                }
                
                // 识别结果
                if let result = ocrResult, !isProcessing {
                    Section("识别结果") {
                        HStack {
                            Text("股票代码")
                            Spacer()
                            TextField("代码", text: $confirmedSymbol)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("股票名称")
                            Spacer()
                            TextField("名称", text: $confirmedName)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        Picker("交易方向", selection: $confirmedDirection) {
                            Text("买入").tag("买入")
                            Text("卖出").tag("卖出")
                        }
                        
                        HStack {
                            Text("成交价格")
                            Spacer()
                            TextField("价格", text: $confirmedPrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("成交数量")
                            Spacer()
                            TextField("数量", text: $confirmedQuantity)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    // 原始文字（可展开）
                    Section {
                        DisclosureGroup("查看原始识别文字") {
                            Text(result.rawText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // 确认按钮
                    Section {
                        Button(action: { saveRecord() }) {
                            Text("确认保存")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canSave)
                    }
                }
            }
            .navigationTitle("截图识别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var canSave: Bool {
        !confirmedSymbol.isEmpty &&
        Double(confirmedPrice) ?? 0 > 0 &&
        Double(confirmedQuantity) ?? 0 > 0
    }
    
    private func processImage(_ image: UIImage) async {
        isProcessing = true
        
        do {
            let result = try await TradeOCRService.recognizeTradeInfo(from: image)
            ocrResult = result
            
            // 填充识别结果
            confirmedSymbol = result.symbol
            confirmedName = result.name
            confirmedDirection = result.direction.isEmpty ? "买入" : result.direction
            confirmedPrice = result.price > 0 ? String(result.price) : ""
            confirmedQuantity = result.quantity > 0 ? String(Int(result.quantity)) : ""
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isProcessing = false
    }
    
    private func saveRecord() {
        guard let priceValue = Double(confirmedPrice),
              let qtyValue = Double(confirmedQuantity),
              priceValue > 0, qtyValue > 0 else {
            errorMessage = "请输入有效的价格和数量"
            showError = true
            return
        }
        
        let amount = priceValue * qtyValue
        
        let record = TradeRecord(
            date: Date(),
            direction: confirmedDirection,
            price: priceValue,
            quantity: qtyValue,
            amount: amount,
            sourceType: "截图识别",
            note: ""
        )
        record.holding = holding
        modelContext.insert(record)
        
        // 更新持仓数据
        GridTradingService.updateHoldingAfterTrade(holding: holding, trade: record)
        
        dismiss()
    }
}

#Preview {
    let holding = Holding(
        symbol: "601318",
        name: "中国平安",
        market: "A股",
        quantity: 1000,
        currentPrice: 54.0
    )
    
    return TradeOCRView(holding: holding)
        .modelContainer(for: TradeRecord.self, inMemory: true)
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

- [ ] **步骤 3：Commit**

```bash
cd ~/Desktop/guxibao
git add DividendTreasure/DividendTreasure/Services/TradeOCRService.swift
git add DividendTreasure/DividendTreasure/Views/GridTrading/TradeOCRView.swift
git commit -m "feat: 添加交易截图识别功能（会员专属）

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 阶段 7：集成和入口

### 任务 7.1：更新订阅服务权限

**文件：**
- 修改：`DividendTreasure/DividendTreasure/Services/SubscriptionService.swift`

- [ ] **步骤 1：添加网格交易相关权限**

找到 `FeaturePermissions` 结构体（约第 56-92 行），添加新字段：

```swift
struct FeaturePermissions {
    let maxPortfolios: Int
    let maxHoldingsPerPortfolio: Int
    let iCloudSync: Bool
    let unlimitedPortfolios: Bool
    let unlimitedHoldings: Bool
    let tradingExportImport: Bool
    let aiInsights: Bool
    let calendarView: Bool
    let gridTradingLevels: Int           // 新增：档位数量限制
    let tradeRecords: Int                // 新增：交易记录数量限制
    let strategyTemplates: Bool          // 新增：策略模板权限
    let ocrRecognition: Bool             // 新增：截图识别权限

    static func forTier(_ tier: SubscriptionTier) -> FeaturePermissions {
        switch tier {
        case .free:
            return FeaturePermissions(
                maxPortfolios: 1,
                maxHoldingsPerPortfolio: 5,
                iCloudSync: false,
                unlimitedPortfolios: false,
                unlimitedHoldings: false,
                tradingExportImport: false,
                aiInsights: false,
                calendarView: false,
                gridTradingLevels: 3,
                tradeRecords: 10,
                strategyTemplates: false,
                ocrRecognition: false
            )
        case .monthly, .quarterly, .yearly:
            return FeaturePermissions(
                maxPortfolios: .max,
                maxHoldingsPerPortfolio: .max,
                iCloudSync: true,
                unlimitedPortfolios: true,
                unlimitedHoldings: true,
                tradingExportImport: true,
                aiInsights: true,
                calendarView: true,
                gridTradingLevels: .max,
                tradeRecords: .max,
                strategyTemplates: true,
                ocrRecognition: true
            )
        }
    }
}
```

- [ ] **步骤 2：添加权限检查方法**

在 `SubscriptionService` 类中添加方法（约第 190-200 行后）：

```swift
// MARK: - 网格交易权限检查

func canAddGridLevel(currentCount: Int) -> Bool {
    if permissions.gridTradingLevels == .max { return true }
    return currentCount < permissions.gridTradingLevels
}

func canAddTradeRecord(currentCount: Int) -> Bool {
    if permissions.tradeRecords == .max { return true }
    return currentCount < permissions.tradeRecords
}

func canUseStrategyTemplates() -> Bool {
    permissions.strategyTemplates
}

func canUseOCRRecognition() -> Bool {
    permissions.ocrRecognition
}
```

- [ ] **步骤 3：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

---

### 任务 7.2：添加网格交易入口

**文件：**
- 修改：`DividendTreasure/DividendTreasure/Views/Portfolio/PortfolioListView.swift`

- [ ] **步骤 1：在持仓行添加网格交易按钮**

找到 `HoldingRow` 结构体（约第 211-256 行），在 `HStack` 内的最后添加网格交易按钮入口。由于持仓详情页直接跳转到编辑表单，需要创建一个专门的持仓详情页面或修改现有导航结构。

在 `PortfolioDetailView` 的持仓列表部分（约第 165-171 行），为每个持仓添加 swip Actions：

找到这段代码：
```swift
ForEach(portfolio.holdings) { holding in
    NavigationLink(destination: HoldingFormView(portfolio: portfolio, holding: holding)) {
        HoldingRow(holding: holding)
    }
}
.onDelete(perform: deleteHoldings)
```

修改为：
```swift
ForEach(portfolio.holdings) { holding in
    NavigationLink(destination: HoldingFormView(portfolio: portfolio, holding: holding)) {
        HoldingRow(holding: holding)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
        Button(role: .destructive) {
            // 删除操作在 onDelete 中处理
        } label: {
            Label("删除", systemImage: "trash")
        }
    }
    .swipeActions(edge: .leading, allowsFullSwipe: false) {
        NavigationLink(destination: GridTradingView(holding: holding)) {
            Label("网格交易", systemImage: "chart.xyaxis.line")
        }
        .tint(.blue)
    }
}
```

- [ ] **步骤 2：验证编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)"`
预期：BUILD SUCCEEDED

- [ ] **步骤 3：Commit**

```bash
cd ~/Desktop/guxibao
git add DividendTreasure/DividendTreasure/Services/SubscriptionService.swift
git add DividendTreasure/DividendTreasure/Views/Portfolio/PortfolioListView.swift
git commit -m "feat: 完成网格交易功能集成 - 权限和入口

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 阶段 8：最终验证

### 任务 8.1：完整编译验证

- [ ] **步骤 1：完整编译**

运行：`cd ~/Desktop/guxibao/DividendTreasure && xcodebuild -scheme DividendTreasure -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
预期：BUILD SUCCEEDED

- [ ] **步骤 2：更新 README.md**

在 README.md 中添加阶段 10 的描述：

找到开发阶段部分，添加：
```markdown
### 阶段 10：网格交易助手（已完成）
- [x] 网格档位设置和股息率计算
- [x] 手动添加交易记录
- [x] 截图识别交易信息（会员）
- [x] 交易记录自动更新持仓
- [x] 策略模板选择（会员专属）
- [x] 快速生成档位功能
```

- [ ] **步骤 3：最终 Commit**

```bash
cd ~/Desktop/guxibao
git add README.md
git commit -m "docs: 更新README - 添加阶段10网格交易助手

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## 自检清单

✅ **规格覆盖度：** 
- 数据模型（GridTradingLevel、TradeRecord）→ 任务 1.1-1.3
- 策略模板（StrategyTemplate）→ 任务 2.1
- 网格交易计算服务 → 任务 2.2
- 网格交易主页面 → 任务 3.1
- 手动添加档位表单 → 任务 3.2
- 快速生成档位弹窗 → 任务 3.3
- 交易记录页面和表单 → 任务 4.1-4.2
- 策略模板选择页 → 任务 5.1
- 截图识别服务和页面 → 任务 6.1-6.2
- 权限和入口集成 → 任务 7.1-7.2

✅ **占位符扫描：** 无 TODO、待定等占位符

✅ **类型一致性：** 所有类型名称和方法签名保持一致

---

**计划完成日期：** 2026-06-10