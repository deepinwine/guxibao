//
//  Portfolio.swift
//  DividendTreasure
//
//  投资组合模型
//

import Foundation
import SwiftData

@Model
final class Portfolio {
    @Attribute(.unique) var id: UUID
    var name: String
    var currency: String
    var targetAnnualDividend: Double
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var holdings: [Holding] = []

    init(
        id: UUID = UUID(),
        name: String,
        currency: String = "CNY",
        targetAnnualDividend: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.currency = currency
        self.targetAnnualDividend = targetAnnualDividend
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
