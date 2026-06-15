//
//  DividendTreasureTests.swift
//  DividendTreasureTests
//
//  Created by jiajia on 2026/6/10.
//

import Testing
@testable import DividendTreasure

struct DividendTreasureTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        // Swift Testing Documentation
        // https://developer.apple.com/documentation/testing
    }

    @Test
    func assetInsightOverviewBuildsIndustrySummaryAndConcentration() {
        let holdings = [
            Holding(symbol: "600036", name: "招商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 1000, averageCost: 30, currentPrice: 40, annualDividendPerShare: 1.9),
            Holding(symbol: "00700", name: "腾讯控股", market: "港股", assetType: "股票", industry: "科技", quantity: 100, averageCost: 300, currentPrice: 380, annualDividendPerShare: 2.4),
            Holding(symbol: "511880", name: "银华日利", market: "A股", assetType: "货币基金", industry: "其他", quantity: 500, averageCost: 100, currentPrice: 100, annualDividendPerShare: 0)
        ]

        let overview = AssetInsightService.overview(for: holdings)

        #expect(overview.topIndustries.map(\.category) == ["银行", "科技", "其他"])
        #expect(overview.topIndustries.first?.percentage == 40_000.0 / 128_000.0)
        #expect(overview.topThreeConcentration > 0.99)
        #expect(overview.largestHolding?.symbol == "511880")
    }

    @Test
    func assetInsightBreakdownNormalizesEmptyIndustryIntoOther() {
        let holdings = [
            Holding(symbol: "A", name: "空行业", market: "A股", assetType: "股票", industry: "", quantity: 100, averageCost: 10, currentPrice: 12),
            Holding(symbol: "B", name: "空白行业", market: "A股", assetType: "股票", industry: "   ", quantity: 200, averageCost: 10, currentPrice: 10)
        ]

        let breakdown = AssetInsightService.breakdown(for: .industry, holdings: holdings, assetTypeGrouping: .summary)

        #expect(breakdown.count == 1)
        #expect(breakdown.first?.category == "其他")
    }

    @Test
    func assetInsightDrilldownReturnsHoldingsInsideSelectedCategory() {
        let holdings = [
            Holding(symbol: "600036", name: "招商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 1000, averageCost: 30, currentPrice: 40),
            Holding(symbol: "601398", name: "工商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 800, averageCost: 5, currentPrice: 6),
            Holding(symbol: "00700", name: "腾讯控股", market: "港股", assetType: "股票", industry: "科技", quantity: 100, averageCost: 300, currentPrice: 380)
        ]

        let drilldown = AssetInsightService.drilldown(for: .industry, category: "银行", holdings: holdings)

        #expect(drilldown.map(\.holding.symbol) == ["600036", "601398"])
        #expect(drilldown.allSatisfy { $0.category == "银行" })
    }

}
