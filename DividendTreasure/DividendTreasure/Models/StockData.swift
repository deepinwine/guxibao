//
//  StockData.swift
//  DividendTreasure
//
//  股票数据缓存模型 - 用于存储从API获取的股票信息
//

import Foundation
import SwiftData

@Model
final class StockData {
    @Attribute(.unique) var id: UUID
    var symbol: String           // 股票代码（如：600036）
    var name: String             // 股票名称（如：招商银行）
    var market: String           // 市场（A股/港股/美股）
    var marketCode: String       // 市场代码（如：1=A股, 0=港股）
    var currentPrice: Double     // 当前价格
    var latestDividend: Double   // 最新每股分红（年度）
    var dividendDate: Date?      // 最新分红日期
    var dividendYield: Double    // 真实股息率（latestDividend / currentPrice）
    var lastUpdated: Date        // 最后更新时间

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        market: String = "A股",
        marketCode: String = "1",
        currentPrice: Double = 0,
        latestDividend: Double = 0,
        dividendDate: Date? = nil,
        dividendYield: Double = 0,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.market = market
        self.marketCode = marketCode
        self.currentPrice = currentPrice
        self.latestDividend = latestDividend
        self.dividendDate = dividendDate
        self.dividendYield = dividendYield
        self.lastUpdated = lastUpdated
    }

    // 计算真实股息率
    func calculateRealYield() -> Double {
        guard currentPrice > 0 else { return 0 }
        return latestDividend / currentPrice
    }
}
