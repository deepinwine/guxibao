//
//  Holding.swift
//  DividendTreasure
//
//  持仓模型
//

import Foundation
import SwiftData

enum Market: String, Codable, CaseIterable {
    case aShare = "A股"
    case hongKong = "港股"
    case usStock = "美股"
    case japan = "日股"
    case other = "其他"
}

enum AssetType: String, Codable, CaseIterable {
    case stock = "股票"
    case etf = "ETF"
    case reit = "REITs"
    case indexFund = "指数基金"
    case bond = "债券"
    case moneyFund = "货币基金"
    case cash = "现金"
    case other = "其他"
}

enum Industry: String, Codable, CaseIterable {
    case bank = "银行"
    case insurance = "保险"
    case energy = "能源"
    case utility = "公用事业"
    case consumer = "消费"
    case healthcare = "医药"
    case technology = "科技"
    case realEstate = "地产"
    case telecommunication = "通信"
    case other = "其他"
}

@Model
final class Holding {
    @Attribute(.unique) var id: UUID
    var symbol: String
    var name: String
    var market: String
    var assetType: String
    var industry: String
    var quantity: Double
    var averageCost: Double
    var currentPrice: Double
    var annualDividendPerShare: Double
    var expectedDividendMonths: String  // 逗号分隔的月份数字，如 "3,6,9,12"
    var createdAt: Date
    var updatedAt: Date

    var portfolio: Portfolio?

    // 反向关系：股息记录（CloudKit 要求双向关系）
    @Relationship(deleteRule: .nullify, inverse: \DividendRecord.holding)
    var dividendRecords: [DividendRecord] = []

    // 计算属性：市值
    var marketValue: Double {
        quantity * currentPrice
    }

    // 计算属性：年度股息
    var annualDividend: Double {
        quantity * annualDividendPerShare
    }

    // 计算属性：股息率
    var dividendYield: Double {
        guard currentPrice > 0 else { return 0 }
        return annualDividendPerShare / currentPrice
    }

    // 计算属性：浮盈浮亏
    var profitLoss: Double {
        (currentPrice - averageCost) * quantity
    }

    // 计算属性：浮盈浮亏百分比
    var profitLossPercent: Double {
        guard averageCost > 0 else { return 0 }
        return (currentPrice - averageCost) / averageCost
    }

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        market: String = "A股",
        assetType: String = "股票",
        industry: String = "其他",
        quantity: Double = 0,
        averageCost: Double = 0,
        currentPrice: Double = 0,
        annualDividendPerShare: Double = 0,
        expectedDividendMonths: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.market = market
        self.assetType = assetType
        self.industry = industry
        self.quantity = quantity
        self.averageCost = averageCost
        self.currentPrice = currentPrice
        self.annualDividendPerShare = annualDividendPerShare
        self.expectedDividendMonths = expectedDividendMonths
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
