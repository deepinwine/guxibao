//
//  GridTradingLevel.swift
//  DividendTreasure
//
//  网格交易档位模型
//

import Foundation
import SwiftData

@Model
final class GridTradingLevel {
    @Attribute(.unique) var id: UUID
    var holding: Holding?
    var price: Double
    var direction: String  // "买入" 或 "卖出"
    var quantity: Double
    var note: String
    var isExecuted: Bool
    var createdAt: Date
    var updatedAt: Date

    // 计算属性：股息率
    var yieldRate: Double {
        guard let holding = holding,
              holding.annualDividendPerShare > 0,
              price > 0 else { return 0 }
        return holding.annualDividendPerShare / price
    }

    init(
        id: UUID = UUID(),
        price: Double,
        direction: String = "买入",
        quantity: Double = 0,
        note: String = "",
        isExecuted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.price = price
        self.direction = direction
        self.quantity = quantity
        self.note = note
        self.isExecuted = isExecuted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}