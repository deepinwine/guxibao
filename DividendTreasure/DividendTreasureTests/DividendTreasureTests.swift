//
//  DividendTreasureTests.swift
//  DividendTreasureTests
//
//  Created by jiajia on 2026/6/10.
//

import Testing
@testable import DividendTreasure

struct DividendTreasureTests {

    @Test
    func assetInsightOverviewBuildsIndustrySummaryAndConcentration() {
        let holdings = [
            Holding(symbol: "600036", name: "招商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 1000, averageCost: 30, currentPrice: 40, annualDividendPerShare: 1.9),
            Holding(symbol: "00700", name: "腾讯控股", market: "港股", assetType: "股票", industry: "科技", quantity: 100, averageCost: 300, currentPrice: 380, annualDividendPerShare: 2.4),
            Holding(symbol: "511880", name: "银华日利", market: "A股", assetType: "货币基金", industry: "其他", quantity: 500, averageCost: 100, currentPrice: 100, annualDividendPerShare: 0)
        ]

        let overview = AssetInsightService.overview(for: holdings)

        #expect(overview.topIndustries.map(\.category) == ["其他", "银行", "科技"])
        #expect(overview.topIndustries.first?.percentage == 50_000.0 / 128_000.0)
        #expect(overview.topIndustry == "其他")
        #expect(overview.topThreeConcentration == 1.0)
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
        #expect(drilldown.map(\.percentageWithinCategory) == [40000.0 / 44800.0, 4800.0 / 44800.0])
    }

    @Test
    func assetInsightBreakdownUsesStableTieBreakOnCategory() {
        let holdings = [
            Holding(symbol: "A1", name: "并列甲", market: "A股", assetType: "股票", industry: "B行业", quantity: 100, averageCost: 10, currentPrice: 10),
            Holding(symbol: "B1", name: "并列乙", market: "A股", assetType: "股票", industry: "A行业", quantity: 100, averageCost: 10, currentPrice: 10),
            Holding(symbol: "C1", name: "非并列", market: "A股", assetType: "股票", industry: "C行业", quantity: 50, averageCost: 10, currentPrice: 10)
        ]

        let breakdown = AssetInsightService.breakdown(for: .industry, holdings: holdings, assetTypeGrouping: .summary)

        #expect(breakdown.map(\.category) == ["A行业", "B行业", "C行业"])
        #expect(breakdown.map(\.amount) == [1000.0, 1000.0, 500.0])
    }

    @Test
    func holdingClassificationResolvesBankAndTechnologyHoldings() {
        let bank = HoldingClassificationService.resolve(symbol: "600036", name: "招商银行", market: "A股")
        let tech = HoldingClassificationService.resolve(symbol: "00700", name: "腾讯控股", market: "港股")

        #expect(bank.assetType == "股票")
        #expect(bank.industry == "银行")
        #expect(tech.assetType == "股票")
        #expect(tech.industry == "科技")
    }

    @Test
    func holdingClassificationDetectsFundAndFallbacksToOtherIndustry() {
        let etf = HoldingClassificationService.resolve(symbol: "510300", name: "沪深300ETF", market: "A股")
        let unknown = HoldingClassificationService.resolve(symbol: "XYZ", name: "未知资产", market: "美股")

        #expect(etf.assetType == "ETF")
        #expect(etf.industry == "其他")
        #expect(unknown.assetType == "股票")
        #expect(unknown.industry == "其他")
    }

}
