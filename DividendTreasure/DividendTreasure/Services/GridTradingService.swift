//
//  GridTradingService.swift
//  DividendTreasure
//
//  网格交易计算服务
//

import Foundation

// MARK: - 网格交易计算服务

class GridTradingService {

    // MARK: - 股息率计算

    /// 根据目标股息率计算目标价格
    /// - Parameters:
    ///   - annualDividendPerShare: 每股年度股息
    ///   - targetYield: 目标股息率（例如 0.06 表示 6%）
    /// - Returns: 目标价格
    func calculateTargetPrice(annualDividendPerShare: Double, targetYield: Double) -> Double {
        guard targetYield > 0 else { return 0 }
        return annualDividendPerShare / targetYield
    }

    /// 计算股息率
    /// - Parameters:
    ///   - annualDividendPerShare: 每股年度股息
    ///   - price: 当前价格
    /// - Returns: 股息率
    func calculateYield(annualDividendPerShare: Double, price: Double) -> Double {
        guard price > 0 else { return 0 }
        return annualDividendPerShare / price
    }

    // MARK: - 档位生成

    /// 根据股息率网格模板生成档位
    /// - Parameters:
    ///   - holding: 持仓信息
    ///   - parameters: 策略参数
    /// - Returns: 档位参数数组
    func generateDividendYieldGridLevels(holding: Holding, parameters: StrategyParameters) -> [GridLevelParams] {
        var levels: [GridLevelParams] = []

        guard holding.annualDividendPerShare > 0 else { return levels }

        // 生成买入档位：从目标买入股息率开始，每增加一个步长对应一个更低的买入价
        for i in 0..<parameters.levelCount {
            let yield = parameters.targetBuyYield + Double(i) * parameters.yieldStep
            let price = calculateTargetPrice(annualDividendPerShare: holding.annualDividendPerShare, targetYield: yield)
            let quantity = calculateTradeQuantity(for: holding, at: price)

            levels.append(GridLevelParams(
                price: price,
                direction: "买入",
                quantity: quantity
            ))
        }

        // 生成卖出档位：从目标卖出租息率开始，每减少一个步长对应一个更高的卖出价
        for i in 0..<parameters.levelCount {
            let yield = parameters.targetSellYield - Double(i) * parameters.yieldStep
            guard yield > 0 else { break }
            let price = calculateTargetPrice(annualDividendPerShare: holding.annualDividendPerShare, targetYield: yield)
            let quantity = calculateTradeQuantity(for: holding, at: price)

            levels.append(GridLevelParams(
                price: price,
                direction: "卖出",
                quantity: quantity
            ))
        }

        // 按价格排序
        return levels.sorted { $0.price < $1.price }
    }

    /// 根据成本价档位模板生成档位
    /// - Parameters:
    ///   - holding: 持仓信息
    ///   - parameters: 策略参数
    /// - Returns: 档位参数数组
    func generateCostPriceLevels(holding: Holding, parameters: StrategyParameters) -> [GridLevelParams] {
        var levels: [GridLevelParams] = []

        let costPrice = parameters.costPrice > 0 ? parameters.costPrice : holding.averageCost
        guard costPrice > 0, parameters.levelCount > 0 else { return levels }

        // 生成买入档位：低于成本价
        for i in 1...parameters.levelCount {
            let percentDown = Double(i) * parameters.percentStep
            let price = costPrice * (1 - percentDown)
            let quantity = calculateTradeQuantity(for: holding, at: price)

            levels.append(GridLevelParams(
                price: price,
                direction: "买入",
                quantity: quantity
            ))
        }

        // 生成卖出档位：高于成本价
        for i in 1...parameters.levelCount {
            let percentUp = Double(i) * parameters.percentStep
            let price = costPrice * (1 + percentUp)
            let quantity = calculateTradeQuantity(for: holding, at: price)

            levels.append(GridLevelParams(
                price: price,
                direction: "卖出",
                quantity: quantity
            ))
        }

        // 按价格排序
        return levels.sorted { $0.price < $1.price }
    }

    /// 根据动态再平衡模板生成档位
    /// - Parameters:
    ///   - holding: 持仓信息
    ///   - parameters: 策略参数
    /// - Returns: 档位参数数组
    func generateDynamicRebalanceLevels(holding: Holding, parameters: StrategyParameters) -> [GridLevelParams] {
        var levels: [GridLevelParams] = []

        guard holding.annualDividendPerShare > 0 else { return levels }

        // 计算当前股息率对应的价格区间边界
        let lowPrice = calculateTargetPrice(annualDividendPerShare: holding.annualDividendPerShare, targetYield: parameters.targetYieldHigh)
        let highPrice = calculateTargetPrice(annualDividendPerShare: holding.annualDividendPerShare, targetYield: parameters.targetYieldLow)

        // 在股息率过高（价格过低）时买入
        if holding.currentPrice <= lowPrice {
            let quantity = calculateTradeQuantity(for: holding, at: lowPrice)
            levels.append(GridLevelParams(
                price: lowPrice,
                direction: "买入",
                quantity: quantity
            ))
        }

        // 在股息率过低（价格过高）时卖出
        if holding.currentPrice >= highPrice {
            let quantity = calculateTradeQuantity(for: holding, at: highPrice)
            levels.append(GridLevelParams(
                price: highPrice,
                direction: "卖出",
                quantity: quantity
            ))
        }

        return levels
    }

    /// 快速生成档位
    /// - Parameters:
    ///   - holding: 持仓信息
    ///   - currentPrice: 当前价格
    ///   - yieldStep: 股息率步长
    ///   - levelCount: 档位数量
    /// - Returns: 档位参数数组
    func generateQuickLevels(holding: Holding, currentPrice: Double, yieldStep: Double, levelCount: Int) -> [GridLevelParams] {
        var levels: [GridLevelParams] = []

        guard holding.annualDividendPerShare > 0, levelCount > 0 else { return levels }

        let currentYield = calculateYield(annualDividendPerShare: holding.annualDividendPerShare, price: currentPrice)

        // 生成买入档位：股息率更高（价格更低）
        for i in 1...levelCount {
            let yield = currentYield + Double(i) * yieldStep
            let price = calculateTargetPrice(annualDividendPerShare: holding.annualDividendPerShare, targetYield: yield)
            let quantity = calculateTradeQuantity(for: holding, at: price)

            levels.append(GridLevelParams(
                price: price,
                direction: "买入",
                quantity: quantity
            ))
        }

        // 生成卖出档位：股息率更低（价格更高）
        for i in 1...levelCount {
            let yield = currentYield - Double(i) * yieldStep
            guard yield > 0 else { break }
            let price = calculateTargetPrice(annualDividendPerShare: holding.annualDividendPerShare, targetYield: yield)
            let quantity = calculateTradeQuantity(for: holding, at: price)

            levels.append(GridLevelParams(
                price: price,
                direction: "卖出",
                quantity: quantity
            ))
        }

        // 按价格排序
        return levels.sorted { $0.price < $1.price }
    }

    // MARK: - 交易记录更新持仓

    /// 根据交易记录更新持仓数据
    /// - Parameters:
    ///   - holding: 持仓信息（SwiftData @Model，引用类型）
    ///   - trade: 交易记录
    /// - Returns: 传入的同一个 holding 对象（已原地修改）
    /// - Warning: `Holding` 是 SwiftData `@Model` 类（引用类型），本方法会**原地修改**入参，
    ///   返回值与入参是同一对象。不要将其当作"返回副本"的纯函数使用。
    func updateHoldingAfterTrade(holding: Holding, trade: TradeRecord) -> Holding {
        let updatedHolding = holding

        if trade.direction == "买入" {
            // 买入时：新平均成本 = (原平均成本 × 原数量 + 买入金额) ÷ (原数量 + 买入数量)
            let originalValue = holding.averageCost * holding.quantity
            let buyValue = trade.price * trade.quantity
            let newQuantity = holding.quantity + trade.quantity

            if newQuantity > 0 {
                updatedHolding.averageCost = (originalValue + buyValue) / newQuantity
                updatedHolding.quantity = newQuantity
            }
        } else if trade.direction == "卖出" {
            // 卖出时：只更新数量，成本不变
            let newQuantity = holding.quantity - trade.quantity
            updatedHolding.quantity = max(0, newQuantity)
        }

        updatedHolding.updatedAt = Date()

        return updatedHolding
    }

    /// 按价格百分比快速生成档位
    /// - Parameters:
    ///   - holding: 持仓信息
    ///   - percentStep: 价格百分比间距（如 0.02 表示 2%）
    ///   - levelCount: 档位数量（上下各多少档）
    ///   - baseQuantity: 每档基础数量（可选，不传则自动计算）
    /// - Returns: 档位参数数组
    func generateLevelsByPercent(holding: Holding, percentStep: Double, levelCount: Int, baseQuantity: Double? = nil) -> [GridLevelParams] {
        var levels: [GridLevelParams] = []

        let currentPrice = holding.currentPrice
        guard currentPrice > 0, levelCount > 0 else { return levels }

        let quantity = baseQuantity ?? calculateTradeQuantity(for: holding, at: currentPrice)

        // 生成买入档位：价格低于当前价（每低一档，股息率更高）
        for i in 1...levelCount {
            let price = currentPrice * (1 - Double(i) * percentStep)
            guard price > 0 else { break }

            levels.append(GridLevelParams(
                price: price,
                direction: "买入",
                quantity: quantity
            ))
        }

        // 生成卖出档位：价格高于当前价（每高一档，股息率更低）
        for i in 1...levelCount {
            let price = currentPrice * (1 + Double(i) * percentStep)

            levels.append(GridLevelParams(
                price: price,
                direction: "卖出",
                quantity: quantity
            ))
        }

        // 按价格排序（从低到高）
        return levels.sorted { $0.price < $1.price }
    }

    // MARK: - 私有辅助方法

    /// 计算交易数量（简单策略：基于持仓的一定比例）
    /// - Parameters:
    ///   - holding: 持仓信息
    ///   - price: 交易价格
    /// - Returns: 建议交易数量
    private func calculateTradeQuantity(for holding: Holding, at price: Double) -> Double {
        guard price > 0, holding.quantity > 0 else { return 0 }

        // 简单策略：每次交易持仓的 10%，最少 100 股
        let baseQuantity = holding.quantity * 0.1
        return max(100, baseQuantity)
    }
}
