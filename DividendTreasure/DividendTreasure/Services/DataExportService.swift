//
//  DataExportService.swift
//  DividendTreasure
//
//  数据导出服务 - 导出持仓数据为CSV/JSON
//

import Foundation
import SwiftData

struct DataExportService {

    // MARK: - 导出CSV

    /// 导出持仓数据为CSV格式
    static func exportHoldingsToCSV(_ holdings: [Holding]) -> URL? {
        var csv = "代码,名称,市场,资产类型,行业,数量,成本价,现价,年度每股股息,预计派息月份,市值,年度股息,股息率\n"

        for holding in holdings {
            let row = [
                holding.symbol,
                holding.name,
                holding.market,
                holding.assetType,
                holding.industry,
                String(format: "%.0f", holding.quantity),
                String(format: "%.2f", holding.averageCost),
                String(format: "%.2f", holding.currentPrice),
                String(format: "%.4f", holding.annualDividendPerShare),
                holding.expectedDividendMonths,
                String(format: "%.2f", holding.marketValue),
                String(format: "%.2f", holding.annualDividend),
                String(format: "%.4f", holding.dividendYield)
            ]
            csv += row.joined(separator: ",") + "\n"
        }

        // 保存文件
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("持仓数据_\(DateFormatter.fileNameDate.string(from: Date())).csv")

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export CSV: \(error)")
            return nil
        }
    }

    // MARK: - 导出JSON

    /// 导出持仓数据为JSON格式
    static func exportHoldingsToJSON(_ holdings: [Holding]) -> URL? {
        struct HoldingExport: Codable {
            let symbol: String
            let name: String
            let market: String
            let assetType: String
            let industry: String
            let quantity: Double
            let averageCost: Double
            let currentPrice: Double
            let annualDividendPerShare: Double
            let expectedDividendMonths: String
        }

        let exportData = holdings.map { holding in
            HoldingExport(
                symbol: holding.symbol,
                name: holding.name,
                market: holding.market,
                assetType: holding.assetType,
                industry: holding.industry,
                quantity: holding.quantity,
                averageCost: holding.averageCost,
                currentPrice: holding.currentPrice,
                annualDividendPerShare: holding.annualDividendPerShare,
                expectedDividendMonths: holding.expectedDividendMonths
            )
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(exportData)

            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("持仓数据_\(DateFormatter.fileNameDate.string(from: Date())).json")

            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to export JSON: \(error)")
            return nil
        }
    }

    // MARK: - 导入

    /// 从JSON导入持仓数据
    static func importHoldingsFromJSON(from url: URL, to portfolio: Portfolio, in context: ModelContext) -> Int {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            struct HoldingImport: Codable {
                let symbol: String
                let name: String
                let market: String
                let assetType: String
                let industry: String
                let quantity: Double
                let averageCost: Double
                let currentPrice: Double
                let annualDividendPerShare: Double
                let expectedDividendMonths: String
            }

            let importedHoldings = try decoder.decode([HoldingImport].self, from: data)

            for importData in importedHoldings {
                let holding = Holding(
                    symbol: importData.symbol,
                    name: importData.name,
                    market: importData.market,
                    assetType: importData.assetType,
                    industry: importData.industry,
                    quantity: importData.quantity,
                    averageCost: importData.averageCost,
                    currentPrice: importData.currentPrice,
                    annualDividendPerShare: importData.annualDividendPerShare,
                    expectedDividendMonths: importData.expectedDividendMonths
                )
                holding.portfolio = portfolio
                context.insert(holding)
            }

            return importedHoldings.count
        } catch {
            print("Failed to import holdings: \(error)")
            return 0
        }
    }
}

// MARK: - DateFormatter扩展

extension DateFormatter {
    static let fileNameDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}
