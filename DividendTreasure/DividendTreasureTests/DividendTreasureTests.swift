//
//  DividendTreasureTests.swift
//  DividendTreasureTests
//

import CoreGraphics
import Foundation
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
    func assetInsightOverviewIncludesMarketAndAssetTypeSummaries() {
        let holdings = [
            Holding(symbol: "600036", name: "招商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 1000, averageCost: 30, currentPrice: 40, annualDividendPerShare: 1.9),
            Holding(symbol: "510300", name: "沪深300ETF", market: "A股", assetType: "ETF", industry: "其他", quantity: 100, averageCost: 4, currentPrice: 4.2, annualDividendPerShare: 0.1),
            Holding(symbol: "00700", name: "腾讯控股", market: "港股", assetType: "股票", industry: "科技", quantity: 100, averageCost: 300, currentPrice: 380, annualDividendPerShare: 2.4),
            Holding(symbol: "000651", name: "格力电器", market: "A股", assetType: "股票", industry: "消费", quantity: 500, averageCost: 45, currentPrice: 50, annualDividendPerShare: 2.0)
        ]

        let overview = AssetInsightService.overview(for: holdings)

        #expect(overview.totalValue == 103_420)
        #expect(overview.totalDividend == 3_150)
        #expect(overview.avgYield == 3_150.0 / 103_420.0)

        #expect(overview.topIndustries.map(\.category) == ["银行", "科技", "消费"])
        #expect(overview.topIndustries.map(\.percentage) == [
            40_000.0 / 103_420.0,
            38_000.0 / 103_420.0,
            25_000.0 / 103_420.0
        ])

        #expect(overview.marketSummary.map(\.category) == ["A股", "港股"])
        #expect(overview.marketSummary.map(\.percentage) == [
            65_420.0 / 103_420.0,
            38_000.0 / 103_420.0
        ])

        #expect(overview.assetTypeSummary.map(\.category) == ["股票", "基金"])
        #expect(overview.assetTypeSummary.map(\.percentage) == [
            103_000.0 / 103_420.0,
            420.0 / 103_420.0
        ])

        #expect(overview.largestHolding?.symbol == "600036")
        #expect(overview.topThreeConcentration == 103_000.0 / 103_420.0)
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
    func assetInsightDrilldownSortsByMarketValueDescending() {
        let holdings = [
            Holding(symbol: "600036", name: "招商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 1000, averageCost: 30, currentPrice: 40),
            Holding(symbol: "601398", name: "工商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 800, averageCost: 5, currentPrice: 6)
        ]

        let drilldown = AssetInsightService.drilldown(for: .industry, category: "银行", holdings: holdings)

        #expect(drilldown.first?.holding.symbol == "600036")
        #expect(drilldown.first?.percentageWithinCategory == 40_000.0 / 44_800.0)
    }

    @Test
    func assetInsightDrilldownRespectsDetailedAssetTypeGrouping() {
        let holdings = [
            Holding(symbol: "510300", name: "沪深300ETF", market: "A股", assetType: "ETF", industry: "其他", quantity: 100, averageCost: 4, currentPrice: 4.2),
            Holding(symbol: "159915", name: "创业板ETF", market: "A股", assetType: "ETF", industry: "其他", quantity: 200, averageCost: 2, currentPrice: 2.2),
            Holding(symbol: "600036", name: "招商银行", market: "A股", assetType: "股票", industry: "银行", quantity: 1000, averageCost: 30, currentPrice: 40)
        ]

        let drilldown = AssetInsightService.drilldown(
            for: .assetType,
            category: "ETF",
            holdings: holdings,
            assetTypeGrouping: .detail
        )

        #expect(drilldown.map(\.holding.symbol) == ["159915", "510300"])
        #expect(drilldown.allSatisfy { $0.category == "ETF" })
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

    @Test
    func holdingClassificationResolvesMarketAndMarketCodeFromSymbol() {
        let aShare = HoldingClassificationService.resolve(symbol: "600036", name: "招商银行")
        let hongKong = HoldingClassificationService.resolve(symbol: "00700", name: "腾讯控股")
        let usWithLetters = HoldingClassificationService.resolve(symbol: "GOOGL", name: "Alphabet")
        let usWithDot = HoldingClassificationService.resolve(symbol: "BRK.B", name: "Berkshire Hathaway")

        #expect(aShare.market == "A股")
        #expect(aShare.marketCode == "1")
        #expect(hongKong.market == "港股")
        #expect(hongKong.marketCode == "0")
        #expect(usWithLetters.market == "美股")
        #expect(usWithLetters.marketCode == "105")
        #expect(usWithDot.market == "美股")
        #expect(usWithDot.marketCode == "105")
    }

    @Test
    func parserUsesHeaderColumnsToSeparateQuantityAndMarketValue() {
        let parser = OCRHoldingTableParser(symbolResolver: { _ in nil })

        let rows = [
            row(y: 0.92, cells: [
                ("名称", 0.12),
                ("代码", 0.28),
                ("持仓数量", 0.56),
                ("持仓市值", 0.82)
            ]),
            row(y: 0.82, cells: [
                ("贵州茅台", 0.12),
                ("600519", 0.28),
                ("100", 0.56),
                ("146800", 0.82)
            ]),
            row(y: 0.72, cells: [
                ("中国平安", 0.12),
                ("601318", 0.28),
                ("6900", 0.56),
                ("372669", 0.82)
            ])
        ]

        let result = parser.parse(observations: rows.flatMap { $0 })

        #expect(result.count == 2)
        #expect(result[0].symbol == "600519")
        #expect(result[0].quantity == 100)
        #expect(result[0].marketValue == 146800)
        #expect(result[1].symbol == "601318")
        #expect(result[1].quantity == 6900)
        #expect(result[1].marketValue == 372669)
    }

    @Test
    func parserKeepsNumbersInsideEachRecordBlock() {
        let parser = OCRHoldingTableParser(symbolResolver: { _ in nil })

        let rows = [
            row(y: 0.92, cells: [
                ("名称", 0.12),
                ("代码", 0.28),
                ("现价", 0.44),
                ("持仓数量", 0.60),
                ("持仓市值", 0.82)
            ]),
            row(y: 0.84, cells: [
                ("迈瑞医疗", 0.12),
                ("300760", 0.28)
            ]),
            row(y: 0.79, cells: [
                ("246.80", 0.44),
                ("300", 0.60),
                ("74040", 0.82)
            ]),
            row(y: 0.69, cells: [
                ("招商银行", 0.12),
                ("600036", 0.28)
            ]),
            row(y: 0.64, cells: [
                ("43.21", 0.44),
                ("1200", 0.60),
                ("51852", 0.82)
            ])
        ]

        let result = parser.parse(observations: rows.flatMap { $0 })

        #expect(result.count == 2)
        #expect(result[0].symbol == "300760")
        #expect(result[0].quantity == 300)
        #expect(result[0].marketValue == 74040)
        #expect(result[1].symbol == "600036")
        #expect(result[1].quantity == 1200)
        #expect(result[1].marketValue == 51852)
    }

    @Test
    func stockSearchParserDecodesSinaSuggestResponse() throws {
        let parser = StockSearchResponseParser()
        let response = #"var suggestvalue="招商银行,11,600036,sh600036,招商银行,,招商银行,99,1,ESG,,;中国平安,11,601318,sh601318,中国平安,,中国平安,99,1,ESG,,";"#
        let encoding = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            )
        )
        let data = try #require(response.data(using: encoding))

        let results = try #require(parser.parseSinaSuggestResult(data))

        #expect(results.count == 2)
        #expect(results[0].symbol == "600036")
        #expect(results[0].name == "招商银行")
        #expect(results[0].market == "A股")
        #expect(results[0].marketCode == "1")
        #expect(results[1].symbol == "601318")
    }

    @Test
    func stockSearchParserReadsCurrentEastMoneyPayload() throws {
        let parser = StockSearchResponseParser()
        let response = #"({"QuotationCodeTable":{"Data":[{"Code":"600036","Name":"招商银行","MktNum":"1"}],"Status":0,"Message":"成功"}})"#
        let data = try #require(response.data(using: .utf8))

        let results = try #require(parser.parseEastMoneyResult(data))

        #expect(results.count == 1)
        #expect(results[0].symbol == "600036")
        #expect(results[0].name == "招商银行")
        #expect(results[0].marketCode == "1")
    }

    @Test
    func parserNormalizesCommonOcrMistakesInStockSymbol() {
        let parser = OCRHoldingTableParser(symbolResolver: { _ in nil })

        let rows = [
            row(y: 0.92, cells: [
                ("名称", 0.12),
                ("代码", 0.28),
                ("持仓数量", 0.56),
                ("持仓市值", 0.82)
            ]),
            row(y: 0.82, cells: [
                ("招商银行", 0.12),
                ("6O0O3G", 0.28),
                ("1200", 0.56),
                ("51852", 0.82)
            ])
        ]

        let result = parser.parse(observations: rows.flatMap { $0 })

        #expect(result.count == 1)
        #expect(result[0].symbol == "600036")
    }

    @Test
    func parserUsesResolvedSymbolWhenNormalizedCodeStillConflictsWithName() {
        let parser = OCRHoldingTableParser(symbolResolver: { name in
            guard name == "招商银行" else { return nil }
            return StockSearchResult(symbol: "600036", name: "招商银行", market: "A股", marketCode: "1")
        })

        let rows = [
            row(y: 0.92, cells: [
                ("名称", 0.12),
                ("代码", 0.28),
                ("持仓数量", 0.56),
                ("持仓市值", 0.82)
            ]),
            row(y: 0.82, cells: [
                ("招商银行", 0.12),
                ("6OOO3B", 0.28),
                ("1200", 0.56),
                ("51852", 0.82)
            ])
        ]

        let result = parser.parse(observations: rows.flatMap { $0 })

        #expect(result.count == 1)
        #expect(result[0].symbol == "600036")
        #expect(result[0].name == "招商银行")
    }

    private func row(y: CGFloat, cells: [(String, CGFloat)]) -> [OCRTextObservation] {
        cells.map { text, x in
            OCRTextObservation(
                text: text,
                boundingBox: CGRect(x: x, y: y, width: 0.12, height: 0.04)
            )
        }
    }
}

// MARK: - 股价/股息解析测试（基于真实接口返回数据）

/// 用东财 push2 真实返回的 JSON 验证解析：
/// - f43 价格除数必须是 100（曾误用 1000 导致股价缩小到 1/10）
/// - 解出的股价应与真实价位吻合
struct StockDataParsingTests {
    private let service = StockDataService.shared

    /// 招行 600036：真实股价约 36 元，f43=3600
    @Test func eastMoneyPriceDivisorIsHundred() throws {
        // 2026-06-23 实际抓取的真实返回
        let json = """
        {"rc":0,"rt":4,"data":{"f43":3600,"f58":"招商银行","f162":600,"f173":3.37}}
        """.data(using: .utf8)!

        let stock = try #require(service.parseEastMoneyStockData(json, symbol: "600036", marketCode: "1"))

        // f43=3600, ÷100=36.00（而非旧的÷1000=3.6）
        #expect(abs(stock.currentPrice - 36.00) < 0.01, "招行股价应约36元，验证f43除数为100")
        #expect(stock.name == "招商银行")
        #expect(stock.market == "A股")
    }

    /// 多只不同价位股票交叉验证除数 100
    @Test func priceDivisorAcrossPriceLevels() throws {
        // 茅台 f43=116863 → 1168.63；工行 f43=715 → 7.15；平安 f43=1023 → 10.23
        let cases: [(code: String, f43: Int, expectedPrice: Double)] = [
            ("600519", 116863, 1168.63),  // 茅台
            ("601398", 715, 7.15),        // 工行
            ("000001", 1023, 10.23),      // 平安
        ]
        for c in cases {
            let json = "{\"data\":{\"f43\":\(c.f43),\"f58\":\"x\",\"f162\":0,\"f173\":0}}".data(using: .utf8)!
            let stock = try #require(service.parseEastMoneyStockData(json, symbol: c.code, marketCode: "1"))
            #expect(abs(stock.currentPrice - c.expectedPrice) < 0.01,
                    "\(c.code) f43=\(c.f43) 应为 \(c.expectedPrice)")
        }
    }

    /// 验证 push2 不再返回不可靠的 f173 股息（应留空由 datacenter 补充）
    @Test func push2DoesNotReturnUnreliableDividend() throws {
        let json = """
        {"data":{"f43":3600,"f58":"招商银行","f162":600,"f173":3.37}}
        """.data(using: .utf8)!
        let stock = try #require(service.parseEastMoneyStockData(json, symbol: "600036", marketCode: "1"))
        // push2 的 f173=3.37 不可靠，不应作为股息返回；latestDividend 应为 0（由 datacenter 单独取）
        #expect(stock.latestDividend == 0, "push2 股息不可靠，应留空由 datacenter 补充")
    }

    /// 验证美股 secid 路径也能解析价格
    @Test func usStockPriceParsing() throws {
        let json = """
        {"data":{"f43":296420,"f58":"苹果","f162":0,"f173":0}}
        """.data(using: .utf8)!
        let stock = try #require(service.parseEastMoneyStockData(json, symbol: "AAPL", marketCode: "105"))
        #expect(abs(stock.currentPrice - 2964.20) < 0.01, "AAPL 股价应约296美元")
        #expect(stock.market == "美股")
    }
}
