//
//  OCRService.swift
//  DividendTreasure
//
//  OCR识别服务 - 使用Vision框架识别持仓截图
//

import Foundation
import Vision
import UIKit

// MARK: - OCR识别结果

struct OCRResult {
    let recognizedText: String
    let candidates: [OCRStockCandidate]
}

struct OCRStockCandidate: Identifiable {
    let id = UUID()
    let name: String?
    let symbol: String?
    let quantity: Double?
    let currentPrice: Double?
    let costPrice: Double?
    let marketValue: Double?
    let confidence: Double

    init(
        name: String?,
        symbol: String?,
        quantity: Double?,
        currentPrice: Double?,
        costPrice: Double? = nil,
        marketValue: Double?,
        confidence: Double
    ) {
        self.name = name
        self.symbol = symbol
        self.quantity = quantity
        self.currentPrice = currentPrice
        self.costPrice = costPrice
        self.marketValue = marketValue
        self.confidence = confidence
    }

    var displayName: String {
        if let name = name, let symbol = symbol {
            return "\(name) (\(symbol))"
        } else if let name = name {
            return name
        } else if let symbol = symbol {
            return symbol
        }
        return "未知股票"
    }
}

// MARK: - OCR服务

class OCRService {

    static let shared = OCRService()
    private let parser = OCRHoldingTableParser { keyword in
        StockDataService.shared.searchStockSync(keyword: keyword).first
    }

    private init() {}

    /// 识别图片中的股票信息
    /// - Parameter image: 要识别的图片
    /// - Returns: OCR识别结果
    func recognizeStocks(from image: UIImage, completion: @escaping (Result<OCRResult, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }

        // 创建文本识别请求
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRError.noTextFound))
                return
            }

            let textObservations = observations.compactMap { observation -> OCRTextObservation? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                return OCRTextObservation(
                    text: candidate.string,
                    boundingBox: observation.boundingBox
                )
            }

            let orderedTexts = self.parser.orderedTexts(from: textObservations)
            let fullText = orderedTexts.joined(separator: "\n")
            let candidates = self.parser.parse(observations: textObservations)

            let result = OCRResult(
                recognizedText: fullText,
                candidates: candidates
            )

            completion(.success(result))
        }

        // 配置识别语言和准确度
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        // 执行识别
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - 错误类型

enum OCRError: Error, LocalizedError {
    case invalidImage
    case noTextFound
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "图片无效"
        case .noTextFound:
            return "未识别到文本"
        case .parseError:
            return "解析失败"
        }
    }
}
