//
//  CalculationService.swift
//  DividendTreasure
//
//  集中计算逻辑服务
//

import Foundation

struct CalculationService {

    // MARK: - 持仓计算

    /// 计算持仓市值
    static func marketValue(quantity: Double, currentPrice: Double) -> Double {
        return quantity * currentPrice
    }

    /// 计算持仓年度股息
    static func annualDividend(quantity: Double, dividendPerShare: Double) -> Double {
        return quantity * dividendPerShare
    }

    /// 计算持仓股息率
    static func dividendYield(dividendPerShare: Double, currentPrice: Double) -> Double {
        guard currentPrice > 0 else { return 0 }
        return dividendPerShare / currentPrice
    }

    /// 计算持仓浮盈浮亏
    static func profitLoss(quantity: Double, averageCost: Double, currentPrice: Double) -> Double {
        return (currentPrice - averageCost) * quantity
    }

    /// 计算持仓浮盈浮亏百分比
    static func profitLossPercent(averageCost: Double, currentPrice: Double) -> Double {
        guard averageCost > 0 else { return 0 }
        return (currentPrice - averageCost) / averageCost
    }

    // MARK: - 组合计算

    /// 计算组合总市值
    static func portfolioMarketValue(holdings: [Holding]) -> Double {
        return holdings.reduce(0) { $0 + $1.marketValue }
    }

    /// 计算组合年度股息
    static func portfolioAnnualDividend(holdings: [Holding]) -> Double {
        return holdings.reduce(0) { $0 + $1.annualDividend }
    }

    /// 计算组合股息率
    static func portfolioDividendYield(holdings: [Holding]) -> Double {
        let marketValue = portfolioMarketValue(holdings: holdings)
        let dividend = portfolioAnnualDividend(holdings: holdings)
        guard marketValue > 0 else { return 0 }
        return dividend / marketValue
    }

    // MARK: - 年度目标计算

    /// 计算年度目标完成率
    static func goalProgress(currentDividend: Double, targetDividend: Double) -> Double {
        guard targetDividend > 0 else { return 0 }
        return min(currentDividend / targetDividend, 1.0)
    }

    // MARK: - 收藏股息率计算

    /// 计算当前股息率（收藏）
    static func currentYield(dividendPerShare: Double, currentPrice: Double) -> Double {
        return dividendYield(dividendPerShare: dividendPerShare, currentPrice: currentPrice)
    }

    /// 计算目标买入价
    static func targetBuyPrice(dividendPerShare: Double, targetYield: Double) -> Double {
        guard targetYield > 0 else { return 0 }
        return dividendPerShare / targetYield
    }

    /// 计算目标卖出价
    static func targetSellPrice(dividendPerShare: Double, targetYield: Double) -> Double {
        guard targetYield > 0 else { return 0 }
        return dividendPerShare / targetYield
    }

    // MARK: - 排行榜计算

    /// 获取市值排行榜
    static func holdingsByMarketValue(holdings: [Holding]) -> [Holding] {
        return holdings.sorted { $0.marketValue > $1.marketValue }
    }

    /// 获取股息贡献排行榜
    static func holdingsByDividend(holdings: [Holding]) -> [Holding] {
        return holdings.sorted { $0.annualDividend > $1.annualDividend }
    }

    /// 获取股息率排行榜
    static func holdingsByYield(holdings: [Holding]) -> [Holding] {
        return holdings.sorted { $0.dividendYield > $1.dividendYield }
    }

    /// 获取浮盈排行榜
    static func holdingsByProfit(holdings: [Holding]) -> [Holding] {
        return holdings.sorted { $0.profitLoss > $1.profitLoss }
    }
}
