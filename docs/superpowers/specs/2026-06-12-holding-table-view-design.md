# 持仓组合表格视图设计

## 背景

用户希望在股息宝App的组合详情页中，添加一个类似Excel的表格视图，展示所有持仓股票的数据，并自动获取实时股价。

## 需求

1. 在组合详情页添加表格视图，与列表视图可切换
2. 表格展示所有持仓股票的关键数据
3. 自动获取实时股价并计算相关指标
4. 底部显示合计行

## 设计方案

### 1. UI层

**位置**：组合详情页（PortfolioDetailView）

**视图切换**：
- 右上角工具栏新增表格图标按钮
- 点击切换：列表视图 ⇄ 表格视图
- 状态使用 `@State private var showTableView = false` 记忆

**表格视图结构**：

| 列名 | 数据来源 | 格式 |
|-----|---------|------|
| 个股名称 | Holding.name | 文本 |
| 实时股价 | 网络获取 | 价格格式，2位小数 |
| 成本 | Holding.averageCost | 价格格式，3位小数 |
| 股数 | Holding.quantity | 整数 |
| 股息 | Holding.annualDividendPerShare | 价格格式，3位小数 |
| 总股息 | 股息 × 股数 | 整数 |
| 目前市值 | 实时股价 × 股数 | 整数 |
| 总成本 | 成本 × 股数 | 整数，1位小数 |
| 成本股息率 | 股息 / 成本 | 百分比，2位小数 |
| 实际股息率 | 股息 / 实时股价 | 百分比，2位小数 |

**底部合计行**：
- 总股息：所有持仓总股息之和
- 目前市值：所有持仓市值之和
- 总成本：所有持仓成本之和
- 成本股息率：总股息 / 总成本
- 实际股息率：总股息 / 总市值

**交互**：
- 进入表格视图时自动获取股价
- 下拉刷新重新获取股价
- 列可排序（点击列标题）

### 2. 数据层

**模型**：复用现有 `Holding` 模型，无需新增模型

**股价获取**：
- 使用已有的 `StockDataService`
- 批量获取所有持仓股票的实时股价
- 获取成功后更新 `Holding.currentPrice`

**获取策略**：
- A股：东方财富 API（主）
- 失败回退：新浪财经 API（备）
- 并发获取，提升效率

### 3. 错误处理

- 单只股票获取失败：显示"-"
- 全部失败：提示网络错误，可手动刷新
- 超时：10秒超时限制

## 实现要点

### 文件改动

1. `Views/Portfolio/PortfolioListView.swift`
   - 修改 `PortfolioDetailView`
   - 新增表格视图切换按钮
   - 新增 `PortfolioTableView` 子视图

2. 新建 `Views/Portfolio/PortfolioTableView.swift`
   - 表格视图主体
   - 股价获取逻辑
   - 下拉刷新逻辑

3. `Services/StockDataService.swift`（可选优化）
   - 添加批量获取方法

### 代码结构

```swift
// PortfolioDetailView 改造
struct PortfolioDetailView: View {
    @State private var showTableView = false
    @State private var isRefreshing = false
    
    var body: some View {
        // ...
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showTableView.toggle() }) {
                    Image(systemName: showTableView ? "list.bullet" : "tablecells")
                }
            }
            // 原有的添加按钮
        }
        
        // 视图切换
        if showTableView {
            PortfolioTableView(portfolio: portfolio)
        } else {
            // 原有列表视图
        }
    }
}
```

## 验收标准

1. 点击表格按钮可切换视图
2. 表格展示所有持仓股票数据
3. 进入表格视图自动获取股价
4. 下拉刷新可更新股价
5. 底部合计行数据正确
6. 列排序功能正常（可选）
7. 单只股票获取失败不影响其他股票