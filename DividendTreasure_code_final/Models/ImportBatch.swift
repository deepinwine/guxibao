//
//  ImportBatch.swift
//  DividendTreasure
//
//  导入批次模型
//

import Foundation
import SwiftData

enum ImportSourceType: String, Codable {
    case camera = "相机"
    case photo = "相册"
    case manual = "手动"
}

enum ImportBatchStatus: String, Codable {
    case pending = "待处理"
    case processing = "处理中"
    case completed = "已完成"
    case failed = "失败"
}

@Model
final class ImportBatch {
    @Attribute(.unique) var id: UUID
    var sourceType: String
    var imageFileName: String?
    var recognizedText: String?
    var createdAt: Date
    var status: String

    @Relationship(deleteRule: .cascade)
    var candidates: [ImportCandidate] = []

    init(
        id: UUID = UUID(),
        sourceType: String = "手动",
        imageFileName: String? = nil,
        recognizedText: String? = nil,
        createdAt: Date = Date(),
        status: String = "待处理"
    ) {
        self.id = id
        self.sourceType = sourceType
        self.imageFileName = imageFileName
        self.recognizedText = recognizedText
        self.createdAt = createdAt
        self.status = status
    }
}
