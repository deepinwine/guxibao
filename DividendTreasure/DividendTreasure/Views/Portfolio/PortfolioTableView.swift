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

        // 更新表格数据（创建新数组避免并发安全问题）
        var updatedRows = tableRows
        for i in 0..<updatedRows.count {
            let symbol = updatedRows[i].symbol
            if let price = prices[symbol] {
                updatedRows[i].currentPrice = price
            }
        }
        tableRows = updatedRows

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
