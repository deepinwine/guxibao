//
//  StockSearchResponseParser.swift
//  DividendTreasure
//
//  解析东方财富和新浪的股票搜索响应，给搜索功能提供多源降级。
//

import Foundation
import CoreFoundation

struct StockSearchResponseParser {
    private let sinaEncoding = String.Encoding(
        rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        )
    )

    func parseEastMoneyResult(_ data: Data) -> [StockSearchResult]? {
        guard let responseString = String(data: data, encoding: .utf8) else {
            return nil
        }

        let jsonString: String
        if let start = responseString.firstIndex(of: "("),
           let end = responseString.lastIndex(of: ")"),
           start < end {
            jsonString = String(responseString[responseString.index(after: start)..<end])
        } else {
            jsonString = responseString
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let quotationTable = json["QuotationCodeTable"] as? [String: Any],
              let dataArray = quotationTable["Data"] as? [[String: Any]] else {
            return nil
        }

        let results = dataArray.compactMap { item -> StockSearchResult? in
            guard let code = item["Code"] as? String,
                  let name = item["Name"] as? String else {
                return nil
            }

            let marketCode = stringValue(item["MktNum"]) ?? "1"
            return StockSearchResult(
                symbol: code,
                name: name,
                market: marketName(for: marketCode),
                marketCode: marketCode
            )
        }

        return results.isEmpty ? nil : deduplicated(results)
    }

    func parseSinaSuggestResult(_ data: Data) -> [StockSearchResult]? {
        guard let responseString = decodeSinaResponse(data) else {
            return nil
        }

        guard let firstQuote = responseString.firstIndex(of: "\""),
              let lastQuote = responseString.lastIndex(of: "\""),
              firstQuote < lastQuote else {
            return nil
        }

        let payload = String(responseString[responseString.index(after: firstQuote)..<lastQuote])
        let entries = payload
            .split(separator: ";", omittingEmptySubsequences: true)
            .map(String.init)

        let results = entries.compactMap { entry -> StockSearchResult? in
            let fields = entry.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard fields.count >= 4 else { return nil }

            let name = fields[0].trimmingCharacters(in: .whitespacesAndNewlines)
            // fields[1] 为新浪的 type 字段，可用于区分股票/基金/债券/港股/美股等
            let type = fields[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let symbol = fields[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let rawSymbol = fields[3].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            guard !name.isEmpty, !symbol.isEmpty,
                  let marketInfo = marketInfo(sinaType: type, forSinaSymbol: rawSymbol, fallbackSymbol: symbol) else {
                return nil
            }

            return StockSearchResult(
                symbol: symbol,
                name: name,
                market: marketInfo.market,
                marketCode: marketInfo.marketCode
            )
        }

        return results.isEmpty ? nil : deduplicated(results)
    }

    private func decodeSinaResponse(_ data: Data) -> String? {
        if let decoded = String(data: data, encoding: sinaEncoding), decoded.contains("var suggestvalue=") {
            return decoded
        }

        if let utf8 = String(data: data, encoding: .utf8), utf8.contains("var suggestvalue=") {
            return utf8
        }

        return nil
    }

    /// 根据新浪 suggest 的 type 字段、原始代码前缀、回退代码推断市场。
    /// 优先使用 type 字段（可区分股票/基金/债券等），避免把基金（如 510300）误判为 A 股。
    private func marketInfo(sinaType type: String, forSinaSymbol rawSymbol: String, fallbackSymbol: String) -> (market: String, marketCode: String)? {
        // 新浪 suggest type 前缀（首位）代表大类：1=A股，2=基金/债券，4=港股，7=美股
        switch type.first {
        case "1":
            return ("A股", "1")
        case "4":
            return ("港股", "0")
        case "7":
            return ("美股", "105")
        default:
            break
        }

        // type 缺失时退回前缀判断
        if rawSymbol.hasPrefix("sh") || rawSymbol.hasPrefix("sz") {
            return ("A股", "1")
        }
        if rawSymbol.hasPrefix("hk") {
            return ("港股", "0")
        }
        if rawSymbol.hasPrefix("gb_") || rawSymbol.hasPrefix("us") {
            return ("美股", "105")
        }
        // 无法确定市场时不强行归类为 A 股，避免基金/债券等被错误拉取
        return nil
    }

    private func stringValue(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        default:
            return nil
        }
    }

    private func marketName(for marketCode: String) -> String {
        switch marketCode {
        case "1":
            return "A股"
        case "0":
            return "港股"
        default:
            return "美股"
        }
    }

    private func deduplicated(_ results: [StockSearchResult]) -> [StockSearchResult] {
        var seen: Set<String> = []
        var unique: [StockSearchResult] = []

        for result in results where !seen.contains(result.symbol) {
            seen.insert(result.symbol)
            unique.append(result)
        }

        return unique
    }
}
