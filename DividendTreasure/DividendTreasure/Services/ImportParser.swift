//
//  ImportParser.swift
//  DividendTreasure
//
//  导入数据解析服务 - 解析OCR识别的持仓数据
//

import Foundation

// MARK: - 解析结果模型

struct ParsedHolding: Identifiable {
    let id = UUID()
    var symbol: String?
    var name: String?
    var market: String?
    var quantity: Double?
    var currentPrice: Double?
    var averageCost: Double?
    var marketValue: Double?
    var confidence: Double

    var isValid: Bool {
        (symbol != nil || name != nil) && quantity != nil && quantity! > 0
    }
}

// MARK: - ImportParser 服务

class ImportParser {

    static let shared = ImportParser()

    private init() {}

    // MARK: - 解析方法

    /// 从OCR识别的文本解析持仓信息
    func parseHoldings(from texts: [String]) -> [ParsedHolding] {
        var holdings: [ParsedHolding] = []
        var currentIndex = 0

        while currentIndex < texts.count {
            let text = texts[currentIndex].trimmingCharacters(in: .whitespaces)

            // 尝试提取股票名称
            if let stockName = extractStockName(from: text) {
                var holding = ParsedHolding(confidence: 0.5)
                holding.name = stockName

                // 从后续文本中提取其他信息
                extractAdditionalInfo(from: texts, startingAt: currentIndex, into: &holding)

                // 搜索匹配的股票代码
                if let matchedSymbol = searchSymbol(for: stockName) {
                    holding.symbol = matchedSymbol.symbol
                    holding.market = matchedSymbol.market
                    holding.confidence = matchedSymbol.confidence
                }

                if holding.isValid {
                    holdings.append(holding)
                }

                currentIndex += 1
            }

            // 尝试提取股票代码
            else if let stockSymbol = extractStockSymbol(from: text) {
                var holding = ParsedHolding(confidence: 0.7)
                holding.symbol = stockSymbol

                // 从后续文本中提取其他信息
                extractAdditionalInfo(from: texts, startingAt: currentIndex, into: &holding)

                if holding.isValid {
                    holdings.append(holding)
                }

                currentIndex += 1
            }

            else {
                currentIndex += 1
            }
        }

        return holdings
    }

    // MARK: - 提取方法

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
        let blackList = ["持仓", "市值", "成本", "盈亏", "可用", "冻结", "总计", "合计",
                        "股票", "代码", "名称", "数量", "价格", "成本价", "现价", "市值",
                        "证券", "账户", "资金", "日期", "时间", "账号"]

        if blackList.contains(name) {
            return nil
        }

        return name
    }

    /// 提取股票代码（6位数字）
    private func extractStockSymbol(from text: String) -> String? {
        let pattern = "\\d{6}"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }

        return String(text[range])
    }

    /// 从后续文本中提取附加信息
    private func extractAdditionalInfo(from texts: [String], startingAt index: Int, into holding: inout ParsedHolding) {
        let searchRange = max(0, index - 3)...min(texts.count - 1, index + 5)

        for i in searchRange {
            let text = texts[i]

            // 提取数量
            if holding.quantity == nil {
                holding.quantity = extractQuantity(from: text)
            }

            // 提取价格
            if holding.currentPrice == nil {
                holding.currentPrice = extractPrice(from: text)
            }

            // 提取成本
            if holding.averageCost == nil {
                holding.averageCost = extractCost(from: text)
            }

            // 提取市值
            if holding.marketValue == nil {
                holding.marketValue = extractMarketValue(from: text)
            }
        }
    }

    /// 提取数量（整数，通常 >= 100）
    private func extractQuantity(from text: String) -> Double? {
        // 匹配整数
        let pattern = "\\d+"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }

        let numberStr = String(text[range])
        let number = Double(numberStr) ?? 0

        // 数量通常是整数且 >= 100
        if number >= 100 && number.truncatingRemainder(dividingBy: 1) == 0 {
            return number
        }

        return nil
    }

    /// 提取价格（小数，通常 < 1000）
    private func extractPrice(from text: String) -> Double? {
        // 匹配小数或整数
        let pattern = "\\d+\\.\\d{1,2}"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }

        let numberStr = String(text[range])
        let number = Double(numberStr) ?? 0

        // 价格通常 < 1000
        if number > 0.01 && number < 1000 {
            return number
        }

        return nil
    }

    /// 提取成本价
    private func extractCost(from text: String) -> Double? {
        // 如果文本包含"成本"关键词
        if text.contains("成本") || text.contains("均价") {
            return extractPrice(from: text)
        }
        return nil
    }

    /// 提取市值（可能包含"万"或"亿"）
    private func extractMarketValue(from text: String) -> Double? {
        // 匹配"万"或"亿"
        if text.contains("万") {
            let pattern = "\\d+\\.?\\d*"
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range, in: text) else {
                return nil
            }
            let numberStr = String(text[range])
            let number = Double(numberStr) ?? 0
            return number * 10000
        }

        if text.contains("亿") {
            let pattern = "\\d+\\.?\\d*"
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range, in: text) else {
                return nil
            }
            let numberStr = String(text[range])
            let number = Double(numberStr) ?? 0
            return number * 100000000
        }

        return nil
    }

    /// 搜索匹配的股票代码
    private func searchSymbol(for name: String) -> (symbol: String, market: String, confidence: Double)? {
        let results = StockDataService.shared.searchStockSync(keyword: name)

        if let first = results.first {
            return (first.symbol, first.market, 0.9)
        }

        return nil
    }

    // MARK: - 格式化输出

    /// 格式化解析结果为可读文本
    func formatParsedHolding(_ holding: ParsedHolding) -> String {
        var parts: [String] = []

        if let name = holding.name {
            parts.append("名称: \(name)")
        }

        if let symbol = holding.symbol {
            parts.append("代码: \(symbol)")
        }

        if let market = holding.market {
            parts.append("市场: \(market)")
        }

        if let quantity = holding.quantity {
            parts.append("数量: \(quantity)")
        }

        if let price = holding.currentPrice {
            parts.append("现价: \(price)")
        }

        if let cost = holding.averageCost {
            parts.append("成本: \(cost)")
        }

        parts.append("置信度: \(Int(holding.confidence * 100))%")

        return parts.joined(separator: ", ")
    }
}