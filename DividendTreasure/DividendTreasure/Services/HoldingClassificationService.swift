//
//  HoldingClassificationService.swift
//  DividendTreasure
//
//  持仓自动归类服务
//

import Foundation

struct HoldingClassification {
    let assetType: String
    let industry: String
}

struct HoldingResolution {
    let market: String
    let marketCode: String
    let assetType: String
    let industry: String
}

enum HoldingClassificationService {
    private static let exactIndustryByName: [String: String] = [
        "招商银行": "银行",
        "工商银行": "银行",
        "农业银行": "银行",
        "腾讯控股": "科技",
        "中国移动": "通信",
        "Verizon": "通信"
    ]

    static func resolve(symbol: String, name: String, market: String) -> HoldingClassification {
        if name.contains("ETF") {
            return HoldingClassification(assetType: "ETF", industry: "其他")
        }

        if let industry = exactIndustryByName[name] {
            return HoldingClassification(assetType: "股票", industry: industry)
        }

        let assetType = ["A股", "港股", "美股"].contains(market) ? "股票" : "其他"
        return HoldingClassification(assetType: assetType, industry: "其他")
    }

    static func resolve(symbol: String?, name: String) -> HoldingResolution {
        let normalizedSymbol = normalizeSymbol(symbol)
        let market = inferMarket(for: normalizedSymbol)
        let classification = resolve(symbol: normalizedSymbol, name: name, market: market)

        return HoldingResolution(
            market: market,
            marketCode: marketCode(for: market),
            assetType: classification.assetType,
            industry: classification.industry
        )
    }

    static func marketCode(for market: String) -> String {
        switch market {
        case "美股":
            return "105"
        case "港股":
            return "0"
        case "A股":
            return "1"
        default:
            return "1"
        }
    }

    private static func normalizeSymbol(_ symbol: String?) -> String {
        symbol?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() ?? ""
    }

    private static func inferMarket(for symbol: String) -> String {
        guard !symbol.isEmpty else {
            return "A股"
        }

        if symbol.contains(".") || symbol.contains("-") || symbol.contains("/") {
            return "美股"
        }

        if symbol.allSatisfy(\.isNumber) {
            if symbol.count == 5 {
                return "港股"
            }

            return "A股"
        }

        if symbol.allSatisfy({ $0.isLetter || $0.isNumber }) {
            return "美股"
        }

        return "A股"
    }
}
