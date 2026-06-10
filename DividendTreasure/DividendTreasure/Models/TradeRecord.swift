//
//  TradeRecord.swift
//  DividendTreasure
//
//  交易记录模型
//

import Foundation
import SwiftData

@Model
final class TradeRecord {
    @Attribute(.unique) var id: UUID
    var holding: Holding?
    var date: Date
    var direction: String  // "买入" 或 "卖出"
    var price: Double
    var quantity: Double
    var amount: Double
    var sourceType: String  // "手动输入" 或 "截图识别"
    var ocrImageFileName: String?
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        direction: String = "买入",
        price: Double = 0,
        quantity: Double = 0,
        amount: Double = 0,
        sourceType: String = "手动输入",
        ocrImageFileName: String? = nil,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.direction = direction
        self.price = price
        self.quantity = quantity
        self.amount = amount
        self.sourceType = sourceType
        self.ocrImageFileName = ocrImageFileName
        self.note = note
        self.createdAt = createdAt
    }
}
