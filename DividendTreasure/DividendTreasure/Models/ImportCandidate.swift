//
//  ImportCandidate.swift
//  DividendTreasure
//
//  导入候选持仓模型
//

import Foundation
import SwiftData

enum ImportCandidateStatus: String, Codable {
    case pending = "待确认"
    case confirmed = "已确认"
    case ignored = "已忽略"
}

@Model
final class ImportCandidate {
    @Attribute(.unique) var id: UUID
    var symbol: String?
    var name: String?
    var quantity: Double?
    var currentPrice: Double?
    var marketValue: Double?
    var confidence: Double
    var status: String

    var importBatch: ImportBatch?

    init(
        id: UUID = UUID(),
        symbol: String? = nil,
        name: String? = nil,
        quantity: Double? = nil,
        currentPrice: Double? = nil,
        marketValue: Double? = nil,
        confidence: Double = 0,
        status: String = "待确认"
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.quantity = quantity
        self.currentPrice = currentPrice
        self.marketValue = marketValue
        self.confidence = confidence
        self.status = status
    }
}
