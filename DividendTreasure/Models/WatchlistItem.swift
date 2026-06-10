//
//  WatchlistItem.swift
//  DividendTreasure
//
//  收藏/关注股票模型
//

import Foundation
import SwiftData

@Model
final class WatchlistItem {
    @Attribute(.unique) var id: UUID
    var symbol: String
    var name: String
    var market: String
    var currentPrice: Double
    var annualDividendPerShare: Double
    var targetBuyYield: Double
    var targetSellYield: Double
    var alertEnabled: Bool
    var note: String
    var createdAt: Date
    var updatedAt: Date

    // 计算属性：当前股息率
    var currentYield: Double {
        guard currentPrice > 0 else { return 0 }
        return annualDividendPerShare / currentPrice
    }

    // 计算属性：目标买入价
    var targetBuyPrice: Double {
        guard targetBuyYield > 0 else { return 0 }
        return annualDividendPerShare / targetBuyYield
    }

    // 计算属性：目标卖出价
    var targetSellPrice: Double {
        guard targetSellYield > 0 else { return 0 }
        return annualDividendPerShare / targetSellYield
    }

    // 计算属性：是否触发买入提醒
    var shouldAlertBuy: Bool {
        guard alertEnabled && targetBuyYield > 0 && currentPrice > 0 else { return false }
        return currentYield >= targetBuyYield
    }

    // 计算属性：是否触发卖出提醒
    var shouldAlertSell: Bool {
        guard alertEnabled && targetSellYield > 0 && currentPrice > 0 else { return false }
        return currentYield <= targetSellYield
    }

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        market: String = "A股",
        currentPrice: Double = 0,
        annualDividendPerShare: Double = 0,
        targetBuyYield: Double = 0,
        targetSellYield: Double = 0,
        alertEnabled: Bool = false,
        note: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.market = market
        self.currentPrice = currentPrice
        self.annualDividendPerShare = annualDividendPerShare
        self.targetBuyYield = targetBuyYield
        self.targetSellYield = targetSellYield
        self.alertEnabled = alertEnabled
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
