//
//  DividendRecord.swift
//  DividendTreasure
//
//  股息记录模型
//

import Foundation
import SwiftData

enum DividendStatus: String, Codable {
    case estimated = "预估"
    case confirmed = "已确认"
    case received = "已到账"
}

@Model
final class DividendRecord {
    @Attribute(.unique) var id: UUID
    var symbol: String
    var name: String
    var exDividendDate: Date
    var paymentDate: Date
    var dividendPerShare: Double
    var quantity: Double
    var amount: Double
    var currency: String
    var status: String

    var holding: Holding?

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        exDividendDate: Date,
        paymentDate: Date,
        dividendPerShare: Double,
        quantity: Double,
        amount: Double,
        currency: String = "CNY",
        status: String = "预估"
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.exDividendDate = exDividendDate
        self.paymentDate = paymentDate
        self.dividendPerShare = dividendPerShare
        self.quantity = quantity
        self.amount = amount
        self.currency = currency
        self.status = status
    }
}
