//
//  CashflowService.swift
//  DividendTreasure
//
//  现金流服务 - 股息现金流统计和预测
//

import Foundation

// MARK: - 月度股息数据

struct MonthlyDividend: Identifiable {
    let id = UUID()
    let month: Int
    let year: Int
    let amount: Double
    let records: [DividendRecord]

    var monthName: String {
        "\(year)年\(month)月"
    }

    var shortName: String {
        "\(month)月"
    }
}

// MARK: - 股息预测数据

struct DividendForecast: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let expectedDate: Date
    let expectedAmount: Double
    let confidence: Double // 0-1，置信度

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return formatter.string(from: expectedDate)
    }
}

// MARK: - 股息排行数据

struct DividendRanking: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let annualDividend: Double
    let dividendYield: Double
    let marketValue: Double
    let holding: Holding

    var displayAmount: String {
        CurrencyFormatter.formatCompact(annualDividend)
    }
}

// MARK: - 现金流服务

struct CashflowService {

    // MARK: - 年度股息统计

    /// 获取年度股息统计
    static func getAnnualDividendSummary(holdings: [Holding]) -> (total: Double, monthly: [MonthlyDividend]) {
        let total = holdings.reduce(0) { $0 + $1.annualDividend }

        // 按月统计（根据预计派息月份）
        var monthlyData: [Int: Double] = [:]
        for month in 1...12 {
            monthlyData[month] = 0
        }

        for holding in holdings {
            let months = parseDividendMonths(holding.expectedDividendMonths)
            let dividendPerMonth = months.isEmpty ? 0 : holding.annualDividend / Double(months.count)

            for month in months {
                monthlyData[month, default: 0] += dividendPerMonth
            }
        }

        let currentYear = Calendar.current.component(.year, from: Date())
        let monthly = monthlyData.map { (month, amount) -> MonthlyDividend in
            MonthlyDividend(month: month, year: currentYear, amount: amount, records: [])
        }.sorted { $0.month < $1.month }

        return (total, monthly)
    }

    // MARK: - 未来三个月股息预测

    /// 预测未来三个月的股息
    static func forecastNextThreeMonths(holdings: [Holding]) -> [DividendForecast] {
        let calendar = Calendar.current
        let now = Date()
        var forecasts: [DividendForecast] = []

        // 获取未来三个月
        for monthOffset in 0..<3 {
            guard let futureDate = calendar.date(byAdding: .month, value: monthOffset, to: now) else {
                continue
            }

            let targetMonth = calendar.component(.month, from: futureDate)
            let targetYear = calendar.component(.year, from: futureDate)

            for holding in holdings {
                let months = parseDividendMonths(holding.expectedDividendMonths)

                if months.contains(targetMonth) {
                    // 预计派息日期（月中）
                    var components = DateComponents()
                    components.year = targetYear
                    components.month = targetMonth
                    components.day = 15

                    if let expectedDate = calendar.date(from: components) {
                        let forecast = DividendForecast(
                            symbol: holding.symbol,
                            name: holding.name,
                            expectedDate: expectedDate,
                            expectedAmount: holding.annualDividend,
                            confidence: holding.currentPrice > 0 ? 0.8 : 0.5
                        )
                        forecasts.append(forecast)
                    }
                }
            }
        }

        return forecasts.sorted { $0.expectedDate < $1.expectedDate }
    }

    // MARK: - 股息排行榜

    /// 按年度股息贡献排行
    static func getDividendRanking(holdings: [Holding]) -> [DividendRanking] {
        return holdings
            .filter { $0.annualDividend > 0 }
            .map { holding in
                DividendRanking(
                    symbol: holding.symbol,
                    name: holding.name,
                    annualDividend: holding.annualDividend,
                    dividendYield: holding.dividendYield,
                    marketValue: holding.marketValue,
                    holding: holding
                )
            }
            .sorted { $0.annualDividend > $1.annualDividend }
    }

    /// 按组合维度统计股息
    static func getDividendByPortfolio(portfolios: [Portfolio]) -> [(name: String, amount: Double)] {
        return portfolios
            .map { ($0.name, $0.holdings.reduce(0) { $0 + $1.annualDividend }) }
            .sorted { $0.1 > $1.1 }
    }

    /// 按市场维度统计股息
    static func getDividendByMarket(holdings: [Holding]) -> [(market: String, amount: Double)] {
        let grouped = Dictionary(grouping: holdings) { $0.market }
        return grouped
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.annualDividend }) }
            .sorted { $0.1 > $1.1 }
    }

    // MARK: - 辅助方法

    /// 解析派息月份字符串
    private static func parseDividendMonths(_ monthsString: String) -> [Int] {
        guard !monthsString.isEmpty else { return [] }

        let components = monthsString.components(separatedBy: ",")
        return components.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    // MARK: - 年度目标进度

    /// 计算年度目标完成进度
    static func getGoalProgress(holdings: [Holding], target: Double) -> (current: Double, target: Double, percentage: Double) {
        let current = holdings.reduce(0) { $0 + $1.annualDividend }
        let percentage = target > 0 ? current / target : 0
        return (current, target, percentage)
    }
}
