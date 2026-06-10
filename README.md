# DividendTreasure

<div align="center">

**股息宝** - 专业的个人财务数据管理 iOS App

[![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

</div>

---

## 📱 功能特性

- 📊 **投资组合管理** - 创建多个投资组合，管理持仓数据
- 💰 **股息收入追踪** - 自动计算年度股息、股息率
- 📈 **资产透视分析** - 按资产类型、行业、市场分布查看资产结构
- 📷 **OCR 截图导入** - 拍照识别券商持仓截图，自动录入数据
- 🔔 **股息率价格提醒** - 设置目标股息率，价格达到时触发提醒
- ☁️ **iCloud 数据同步** - 自动同步到 iCloud，多设备无缝衔接

---

## 🛠 技术栈

| 技术 | 用途 |
|------|------|
| **SwiftUI** | UI 框架 |
| **SwiftData** | 本地数据持久化 |
| **CloudKit** | 云端数据同步 |
| **Vision** | OCR 文字识别 |
| **Swift Charts** | 图表展示 |
| **UserNotifications** | 本地提醒 |

---

## 📦 项目结构

```
DividendTreasure/
├── DividendTreasureApp.swift          # App 入口
├── Models/                            # 数据模型
│   ├── Portfolio.swift                # 组合模型
│   ├── Holding.swift                  # 持仓模型
│   ├── DividendRecord.swift           # 股息记录模型
│   ├── WatchlistItem.swift            # 收藏模型
│   ├── ImportBatch.swift              # 导入批次模型
│   └── ImportCandidate.swift          # 导入候选模型
├── Views/                             # 视图层
│   ├── RootTabView.swift              # Tab 根视图
│   ├── Dashboard/                     # 首页
│   ├── Portfolio/                     # 组合管理
│   ├── AssetInsight/                  # 资产透视
│   ├── Import/                        # 导入功能
│   ├── Cashflow/                      # 现金流
│   ├── Watchlist/                     # 收藏
│   └── Settings/                      # 设置
├── Services/                          # 业务逻辑层
│   ├── MockDataService.swift          # Mock 数据服务
│   ├── CalculationService.swift       # 计算服务（阶段 2）
│   ├── OCRService.swift               # OCR 服务（阶段 5）
│   ├── ImportParser.swift             # 导入解析（阶段 5）
│   └── NotificationService.swift      # 提醒服务（阶段 7）
├── Utilities/                         # 工具类
│   ├── CurrencyFormatter.swift        # 货币格式化
│   └── PercentFormatter.swift         # 百分比格式化
└── Resources/                         # 资源文件
```

---

## 🚀 开发阶段

### ✅ 阶段 1：项目骨架（已完成）
- [x] SwiftUI + SwiftData + CloudKit 项目骨架
- [x] 数据模型定义（6 个 Model）
- [x] 基础 UI 框架（5 个 Tab）
- [x] Mock 数据服务
- [x] 格式化工具

### 🔨 阶段 2：组合和持仓管理（待开发）
- [ ] PortfolioListView 完整实现
- [ ] PortfolioDetailView
- [ ] HoldingFormView
- [ ] CalculationService

### 📋 后续阶段
- 阶段 3：首页总览和被动收入目标卡片
- 阶段 4：资产透视图表
- 阶段 5：OCR 导入功能
- 阶段 6：现金流报表
- 阶段 7：收藏和股息率价格提醒
- 阶段 8：完善 UI 和深色模式

---

## 🔨 如何运行

### 环境要求

- Xcode 15+
- iOS 17+
- Swift 5.9+

### 运行步骤

1. **克隆仓库**

```bash
git clone https://github.com/deepinwine/guxibao.git
cd guxibao
```

2. **打开项目**

```bash
# 如果有 .xcodeproj 文件
open DividendTreasure.xcodeproj

# 或直接在 Xcode 中打开 DividendTreasure 文件夹
```

3. **选择模拟器或真机**

- 在 Xcode 顶部工具栏选择目标设备

4. **运行项目**

- 点击运行按钮或按 `Cmd + R`

---

## 📊 数据模型

### Portfolio（组合）
- id, name, currency
- targetAnnualDividend（年度股息目标）
- holdings（持仓列表）

### Holding（持仓）
- symbol, name, market, assetType, industry
- quantity, averageCost, currentPrice
- annualDividendPerShare, expectedDividendMonths
- 计算属性：marketValue, annualDividend, dividendYield

### WatchlistItem（收藏）
- symbol, name, market, currentPrice
- annualDividendPerShare, targetBuyYield, targetSellYield
- alertEnabled, note
- 计算属性：currentYield, targetBuyPrice, targetSellPrice

---

## ⚠️ 免责声明

本应用仅为个人财务数据管理工具，**不构成任何投资建议**。

1. 本应用不提供证券投资咨询、投资建议或推荐任何证券产品
2. 应用内的所有数据均由用户自行录入，应用不对数据的准确性、完整性做任何保证
3. 股息数据、价格数据仅供参考，实际情况请以券商或官方数据为准
4. **投资有风险，入市需谨慎**
5. 本应用不会接入任何券商账户，不会执行任何交易操作
6. 用户数据通过 iCloud 同步，数据安全由 Apple iCloud 服务保障

---

## 📝 许可证

本项目基于 [MIT License](LICENSE) 开源。

---

<div align="center">

**Made with ❤️ for dividend investors**

</div>
