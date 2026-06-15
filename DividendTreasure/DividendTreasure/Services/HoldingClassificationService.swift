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
}
