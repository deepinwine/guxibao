# 网格交易助手功能设计规格

> **目标：** 为股息宝App添加网格交易助手功能，帮助用户设置价格档位、计算股息率、记录交易并自动更新持仓数据。

**方案：** 混合方案 - 数据关联持仓，UI独立

---

## 1. 数据模型

### 1.1 GridTradingLevel（网格档位）

```swift
@Model
final class GridTradingLevel {
    @Attribute(.unique) var id: UUID
    var holding: Holding?          // 关联持仓
    var price: Double              // 价格
    var direction: String          // 买入/卖出
    var quantity: Double           // 计划数量
    var note: String               // 备注
    var isExecuted: Bool           // 是否已执行
    var createdAt: Date
    var updatedAt: Date

    // 计算属性：股息率
    var yieldRate: Double {
        guard let holding = holding,
              holding.annualDividendPerShare > 0,
              price > 0 else { return 0 }
        return holding.annualDividendPerShare / price
    }
}
```

### 1.2 TradeRecord（交易记录）

```swift
@Model
final class TradeRecord {
    @Attribute(.unique) var id: UUID
    var holding: Holding?          // 关联持仓
    var date: Date                 // 交易日期
    var direction: String          // 买入/卖出
    var price: Double              // 成交价
    var quantity: Double           // 成交数量
    var amount: Double             // 成交金额
    var sourceType: String         // 手动输入/截图识别
    var ocrImageFileName: String?  // 截图文件名（可选）
    var note: String               // 备注
    var createdAt: Date
}
```

### 1.3 StrategyTemplate（策略模板，非持久化）

策略模板作为枚举和计算工具，不需要持久化存储：

```swift
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
    
    // 根据模板参数生成档位列表
    func generateLevels(
        holding: Holding,
        parameters: StrategyParameters
    ) -> [GridTradingLevelParams] {
        // 各模板的生成逻辑
    }
}

struct StrategyParameters {
    // 股息率网格参数
    var targetBuyYield: Double = 0.06    // 目标买入股息率
    var targetSellYield: Double = 0.04   // 目标卖出股息率
    var yieldStep: Double = 0.005        // 股息率间距
    
    // 成本价档位参数
    var costPrice: Double = 0
    var percentStep: Double = 0.05       // 价格百分比间距
    var levelCount: Int = 3              // 档位数量
    
    // 动态再平衡参数
    var targetYieldRange: ClosedRange<Double> = 0.04...0.06
}
```

---

## 2. 用户界面

### 2.1 入口

在持仓详情页添加"网格交易"按钮，点击进入网格交易主页面。

### 2.2 网格交易主页面 (GridTradingView)

顶部显示：
- 股票名称、代码
- 当前价格、当前股息率

操作按钮：
- [快速生成档位] - 根据参数自动生成档位表
- [策略模板] - 选择预设模板（会员专属）
- [手动添加档位] - 手动输入单个档位

档位列表：
- 每个档位显示价格、股息率、数量、执行状态
- 点击可编辑或标记执行

底部按钮：
- [交易记录] - 查看历史交易记录
- [上传截图识别] - OCR识别交易信息（会员专属）

### 2.3 策略模板选择（会员专属）

用户点击"策略模板"按钮后，显示模板列表：

```
┌─────────────────────────────────┐
│ 选择策略模板                     │
├─────────────────────────────────┤
│ ○ 股息率网格（推荐）             │
│   高股息率买入，低股息率卖出     │
│                                 │
│ ○ 成本价档位                     │
│   基于成本价设置上下档位         │
│                                 │
│ ○ 动态再平衡                     │
│   维持目标股息率区间             │
│                                 │
│ ○ 自定义                         │
│   完全自定义档位参数             │
└─────────────────────────────────┘
```

**模板1：股息率网格**
- 参数：目标买入股息率、目标卖出股息率、档位间距
- 自动生成：按股息率间距生成买卖档位
- 适用场景：股息率波动较大的股票

**模板2：成本价档位**
- 参数：成本价、上下浮动百分比、档位数量
- 自动生成：基于成本价的买卖档位
- 适用场景：做成本摊薄

**模板3：动态再平衡**
- 参数：目标股息率区间（如4%-6%）
- 自动生成：区间上沿卖出、下沿买入
- 适用场景：维持稳定股息率

**免责声明：**
> "策略模板仅为工具框架，帮助您设置价格档位。所有投资决策由您自主判断，不构成投资建议。"

### 2.4 快速生成档位弹窗 (QuickGenerateView)

输入参数：
- 当前价格（默认从持仓获取）
- 档位间距（如每5%一个档位）
- 档位数量（如上下各3档）

自动生成：
- 卖出档位：股息率低于当前股息率的价格
- 买入档位：股息率高于当前股息率的价格

### 2.4 交易记录页面 (TradeRecordView)

列表显示：
- 日期、方向（买入/卖出）
- 价格、数量、金额
- 来源（手动输入/截图识别）

支持：
- 手动添加交易记录
- 删除交易记录

### 2.5 截图识别页面 (TradeOCRView)

操作流程：
1. 选择相机拍照或相册图片
2. OCR提取文字
3. 解析交易信息
4. 用户确认并保存

---

## 3. 核心功能流程

### 3.1 股息率计算

```
股息率 = 年度每股股息 ÷ 价格
目标价格 = 年度每股股息 ÷ 目标股息率
```

示例：
- 年度股息 2.7 元/股
- 当前价 54 元，股息率 5%
- 目标股息率 4% → 卖出价 67.5 元
- 目标股息率 6% → 买入价 45 元

### 3.2 交易记录自动更新持仓

**买入时：**
```
新平均成本 = (原平均成本 × 原数量 + 买入金额) ÷ (原数量 + 买入数量)
新数量 = 原数量 + 买入数量
```

**卖出时：**
```
新数量 = 原数量 - 卖出数量
平均成本不变（卖出不影响成本）
```

### 3.3 OCR识别流程

1. 用户上传截图（券商App或第三方平台）
2. Vision框架OCR提取文字
3. 解析交易信息：
   - 股票代码/名称
   - 成交价格
   - 成交数量
   - 交易方向（买入/卖出）
4. 匹配现有持仓
5. 用户确认后保存交易记录
6. 自动更新持仓数据

### 3.4 档位执行流程

1. 用户点击档位的"执行"按钮
2. 弹出交易表单，预填充档位的价格和数量
3. 用户确认交易信息
4. 创建交易记录
5. 自动更新持仓数据
6. 档位标记为"已执行"

---

## 4. 文件结构

### 4.1 新增文件

```
DividendTreasure/
├── Models/
│   ├── GridTradingLevel.swift    # 网格档位模型
│   └── TradeRecord.swift         # 交易记录模型
├── Views/
│   └── GridTrading/
│       ├── GridTradingView.swift       # 网格交易主页面
│       ├── GridLevelListView.swift     # 档位列表组件
│       ├── StrategyTemplateView.swift  # 策略模板选择页（会员）
│       ├── QuickGenerateView.swift     # 快速生成档位弹窗
│       ├── GridLevelFormView.swift     # 手动添加档位表单
│       ├── TradeRecordView.swift       # 交易记录页面
│       ├── TradeRecordFormView.swift   # 手动添加交易记录表单
│       └── TradeOCRView.swift          # 截图识别页面
├── Services/
│   ├── GridTradingService.swift   # 网格交易计算服务
│   └── TradeOCRService.swift      # 交易截图识别服务
```

### 4.2 修改文件

- `DividendTreasureApp.swift`：添加 GridTradingLevel、TradeRecord 到 ModelContainer schema
- `PortfolioDetailView.swift`：添加"网格交易"入口按钮

---

## 5. 权限处理

### 5.1 订阅功能关联

网格交易助手权限分配：
| 功能 | 免费版 | 会员版 |
|------|--------|--------|
| 档位数量 | 最多3个 | 无限 |
| 截图识别 | 不支持 | 支持 |
| 策略模板 | 不支持 | 支持4种模板 |
| 交易记录 | 最多10条 | 无限 |

### 5.2 权限检查点

- 快速生成档位：检查档位数量限制
- 手动添加档位：检查档位数量限制
- 截图识别：检查截图识别权限（会员）
- 策略模板：检查策略模板权限（会员）
- 交易记录：检查交易记录数量限制

---

## 6. 成功标准

1. 用户能为任意持仓设置价格档位
2. 每个档位自动显示对应的股息率
3. 支持手动输入和快速生成两种方式
4. 截图识别能提取交易信息并创建记录（会员）
5. 交易记录自动更新持仓成本和数量
6. 档位执行后能标记状态并创建交易记录
7. 会员用户可选择策略模板生成档位
8. 免费用户看到策略模板入口但提示升级

---

## 7. 范围约束

### 7.1 本次实现范围

- 网格档位设置和股息率计算
- 手动添加交易记录
- 截图识别交易信息（会员）
- 交易记录自动更新持仓
- 策略模板选择（会员专属）
- 快速生成档位功能

### 7.2 不在本次范围

- 实时价格推送（未来可扩展）
- 自动交易执行（不接入券商API）
- 个性化策略推荐（保持合规边界）

---

## 8. 技术栈

| 技术 | 用途 |
|------|------|
| SwiftData | 持久化网格档位和交易记录 |
| SwiftUI | 用户界面 |
| Vision | OCR文字识别 |
| PhotosUI | 相机和相册访问 |

---

**设计完成日期：** 2026-06-10