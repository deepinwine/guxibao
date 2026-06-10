//
//  MockDataService.swift
//  DividendTreasure
//
//  Mock 数据服务 - 用于生成示例数据
//

import Foundation
import SwiftData

class MockDataService {
    static func createSampleData(in context: ModelContext) {
        // 创建示例组合
        let mainPortfolio = Portfolio(
            name: "主账户",
            currency: "CNY",
            targetAnnualDividend: 50000
        )

        let dividendPortfolio = Portfolio(
            name: "股息账户",
            currency: "CNY",
            targetAnnualDividend: 30000
        )

        // 创建示例持仓 - 主账户
        let holding1 = Holding(
            symbol: "601398",
            name: "工商银行",
            market: "A股",
            assetType: "股票",
            industry: "银行",
            quantity: 10000,
            averageCost: 4.50,
            currentPrice: 5.20,
            annualDividendPerShare: 0.293,
            expectedDividendMonths: "6,7"
        )
        holding1.portfolio = mainPortfolio

        let holding2 = Holding(
            symbol: "601288",
            name: "农业银行",
            market: "A股",
            assetType: "股票",
            industry: "银行",
            quantity: 15000,
            averageCost: 2.80,
            currentPrice: 3.50,
            annualDividendPerShare: 0.222,
            expectedDividendMonths: "6,7"
        )
        holding2.portfolio = mainPortfolio

        let holding3 = Holding(
            symbol: "00700",
            name: "腾讯控股",
            market: "港股",
            assetType: "股票",
            industry: "科技",
            quantity: 200,
            averageCost: 320.0,
            currentPrice: 380.0,
            annualDividendPerShare: 2.4,
            expectedDividendMonths: "5,9"
        )
        holding3.portfolio = mainPortfolio

        // 创建示例持仓 - 股息账户
        let holding4 = Holding(
            symbol: "00941",
            name: "中国移动",
            market: "港股",
            assetType: "股票",
            industry: "通信",
            quantity: 500,
            averageCost: 65.0,
            currentPrice: 72.0,
            annualDividendPerShare: 4.35,
            expectedDividendMonths: "6,9"
        )
        holding4.portfolio = dividendPortfolio

        let holding5 = Holding(
            symbol: "VZ",
            name: "Verizon",
            market: "美股",
            assetType: "股票",
            industry: "通信",
            quantity: 50,
            averageCost: 35.0,
            currentPrice: 42.0,
            annualDividendPerShare: 2.66,
            expectedDividendMonths: "2,5,8,11"
        )
        holding5.portfolio = dividendPortfolio

        // 插入数据
        context.insert(mainPortfolio)
        context.insert(dividendPortfolio)

        do {
            try context.save()
            print("✅ Mock data created successfully")
            print("   - 2 portfolios created")
            print("   - 5 holdings created")
        } catch {
            print("❌ Failed to create mock data: \(error)")
        }
    }
}
