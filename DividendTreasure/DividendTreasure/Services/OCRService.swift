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
    let marketValue: Double?
    let confidence: Double

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

            // 提取识别的文本
            let recognizedTexts = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            let fullText = recognizedTexts.joined(separator: "\n")

            // 解析股票信息
            let candidates = self.parseStockInfo(from: recognizedTexts)

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

    /// 解析股票信息
    private func parseStockInfo(from texts: [String]) -> [OCRStockCandidate] {
        var candidates: [OCRStockCandidate] = []

        // 逐行分析文本
        for (index, text) in texts.enumerated() {
            let cleanText = text.trimmingCharacters(in: .whitespaces)

            // 尝试提取股票名称
            if let stockName = extractStockName(from: cleanText) {
                // 使用StockDataService搜索股票
                let searchResults = StockDataService.shared.searchStockSync(keyword: stockName)

                if let firstResult = searchResults.first {
                    // 找到匹配的股票
                    let symbol = firstResult.symbol
                    let quantity = extractQuantity(from: texts, at: index)
                    let price = extractPrice(from: texts, at: index)
                    let marketValue = extractMarketValue(from: texts, at: index)

                    candidates.append(OCRStockCandidate(
                        name: stockName,
                        symbol: symbol,
                        quantity: quantity,
                        currentPrice: price,
                        marketValue: marketValue,
                        confidence: 0.9
                    ))
                } else {
                    // 没找到匹配，使用原始名称
                    candidates.append(OCRStockCandidate(
                        name: stockName,
                        symbol: nil,
                        quantity: extractQuantity(from: texts, at: index),
                        currentPrice: extractPrice(from: texts, at: index),
                        marketValue: extractMarketValue(from: texts, at: index),
                        confidence: 0.5
                    ))
                }
            }

            // 尝试提取股票代码（6位数字）
            if let symbol = extractStockSymbol(from: cleanText) {
                // 检查是否已经添加过
                if !candidates.contains(where: { $0.symbol == symbol }) {
                    candidates.append(OCRStockCandidate(
                        name: nil,
                        symbol: symbol,
                        quantity: extractQuantity(from: texts, at: index),
                        currentPrice: extractPrice(from: texts, at: index),
                        marketValue: extractMarketValue(from: texts, at: index),
                        confidence: 0.7
                    ))
                }
            }
        }

        return candidates
    }

    /// 提取股票名称（中文）
    private func extractStockName(from text: String) -> String? {
        // 匹配2-10个中文字符
        let pattern = "[\\u4e00-\\u9fa5]{2,10}"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }

        let name = String(text[range])

        // 过滤常见的非股票名称
        let blackList = ["持仓", "市值", "成本", "盈亏", "可用", "冻结", "总计", "合计", "股票", "代码", "名称", "数量", "价格", "成本价", "现价", "市值"]
        if blackList.contains(name) {
            return nil
        }

        return name
    }

    /// 提取股票代码（6位数字）
    private func extractStockSymbol(from text: String) -> String? {
        // 匹配6位数字
        let pattern = "\\d{6}"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }

        return String(text[range])
    }

    /// 提取数量
    private func extractQuantity(from texts: [String], at index: Int) -> Double? {
        // 查找附近的数字
        let searchRange = max(0, index - 2)...min(texts.count - 1, index + 2)
        for i in searchRange {
            let text = texts[i]
            // 匹配整数或小数
            if let number = extractNumber(from: text) {
                // 通常数量是整数
                if number.truncatingRemainder(dividingBy: 1) == 0 && number >= 100 {
                    return number
                }
            }
        }
        return nil
    }

    /// 提取价格
    private func extractPrice(from texts: [String], at index: Int) -> Double? {
        // 查找附近的数字
        let searchRange = max(0, index - 2)...min(texts.count - 1, index + 2)
        for i in searchRange {
            let text = texts[i]
            if let number = extractNumber(from: text) {
                // 通常价格是小数且小于1000
                if number < 1000 && number > 0.1 {
                    return number
                }
            }
        }
        return nil
    }

    /// 提取市值
    private func extractMarketValue(from texts: [String], at index: Int) -> Double? {
        // 查找附近的数字（通常市值较大）
        let searchRange = max(0, index - 2)...min(texts.count - 1, index + 2)
        for i in searchRange {
            let text = texts[i]
            // 匹配"万"或"亿"
            if text.contains("万") {
                if let number = extractNumber(from: text) {
                    return number * 10000
                }
            } else if text.contains("亿") {
                if let number = extractNumber(from: text) {
                    return number * 100000000
                }
            }
        }
        return nil
    }

    /// 从文本中提取数字
    private func extractNumber(from text: String) -> Double? {
        let pattern = "\\d+\\.?\\d*"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }

        let numberStr = String(text[range])
        return Double(numberStr)
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
