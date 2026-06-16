# 股息宝 DividendTreasure

一款专注于高股息策略的 iOS 股票持仓管理 App，帮助用户追踪持仓股息、构建网格交易计划、管理分红日历与现金流预测。

> 技术栈：SwiftUI + SwiftData + Vision（OCR）+ StoreKit 2

---

## 功能概览

| 模块 | 说明 | 状态 |
| --- | --- | --- |
| 持仓管理 | 多组合、增删改查、批量更新行情 | ✅ 已实现 |
| OCR 导入 | 拍照/截图识别持仓表（代码、名称、数量、成本、现价） | ✅ 已实现 |
| 行情数据 | 东方财富（主）+ 新浪财经（备）双数据源 | ✅ 已实现 |
| 资产洞察 | 按资产类型 / 行业 / 市场分布、总览 | ✅ 已实现 |
| 分红日历 | 按月展示预计派息、年度汇总 | ✅ 已实现 |
| 现金流预测 | 未来三月股息预测、年度目标进度 | ✅ 已实现 |
| 网格交易 | 快速生成网格档位（按百分比 / 股息率） | ✅ 已实现 |
| 数据导入导出 | CSV / JSON 导出，JSON 导入（含去重） | ✅ 已实现 |
| 本地通知 | 股息率达标 / 价格提醒 | ✅ 已实现 |
| StoreKit 订阅 | 免费版 + 订阅版功能门控 | ✅ 已实现 |

---

## 项目结构

```
guxibao/
├── DividendTreasure/                  # 主工程（开发版，含 .xcodeproj）
│   ├── DividendTreasureApp.swift      # App 入口
│   ├── Models/                        # SwiftData 模型（Holding / Portfolio / WatchlistItem / TradeRecord）
│   ├── Services/                      # 业务服务
│   │   ├── StockDataService.swift     # 行情数据（东财+新浪，双源、带缓存）
│   │   ├── OCRService.swift           # Vision OCR 服务
│   │   ├── OCRHoldingTableParser.swift# OCR 表格解析（表头分列、代码归一化）
│   │   ├── StockSearchResponseParser.swift # 搜索响应解析（东财 JSONP + 新浪 suggest）
│   │   ├── HoldingClassificationService.swift # 市场/资产类型推断
│   │   ├── CashflowService.swift      # 现金流 / 预测
│   │   ├── CalculationService.swift   # 收益 / 股息率 / 排行计算
│   │   ├── AssetInsightService.swift  # 资产分布洞察
│   │   ├── GridTradingService.swift   # 网格档位生成
│   │   ├── StrategyTemplate.swift     # 网格策略模板
│   │   ├── DataExportService.swift    # 导入导出
│   │   ├── NotificationService.swift  # 本地通知
│   │   ├── SubscriptionService.swift  # StoreKit 订阅
│   │   ├── StockUpdateService.swift   # 批量行情更新
│   │   └── MockDataService.swift      # 演示数据
│   ├── Views/                         # SwiftUI 视图
│   │   ├── Portfolio/, Watchlist/, AssetInsight/, Cashflow/
│   │   ├── Calendar/, GridTrading/, Import/, Settings/
│   ├── Utilities/                     # 格式化工具 + 统一日志 (AppLogger)
│   └── DividendTreasureTests/         # 单元测试
│
└── DividendTreasure_code_final/       # ⚠️ 早期代码快照（仅供参考，未被工程引用）
```

> **关于 `DividendTreasure_code_final/`**：这是开发早期的一个代码子集快照，
> 不含 `.xcodeproj`，也未被主工程引用，与 `DividendTreasure/` 存在重复。
> **以 `DividendTreasure/` 为准**。若确认无需参考，可执行
> `git rm -r DividendTreasure_code_final/` 移除。

---

## 日志

App 使用 `os.Logger`（`Utilities/AppLogger.swift`）统一输出日志，
subsystem 为 `com.guxibao.DividendTreasure`。可在 Xcode 控制台或
Console.app 按 category（`network` / `ocr` / `data` / `notification` / `subscription`）过滤。

---

## 开发说明

- 行情接口为东方财富 / 新浪的公开接口，仅供学习参考，**不保证稳定性**。
- SwiftData 模型与 `ModelContext` 的访问须在主线程完成（见 `StockUpdateService` 的 `@MainActor` 约束）。
- `StockDataService` 的内存缓存通过 `NSLock` 保护并发访问。

## 构建

用 Xcode 打开 `DividendTreasure/DividendTreasure.xcodeproj`，选择 iOS 模拟器或真机即可编译运行。
