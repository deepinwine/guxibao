//
//  DataExportService.swift
//  DividendTreasure
//
//  数据导出服务 - 导出持仓数据为CSV/JSON
//

import Foundation
import os
import SwiftData

struct DataExportService {

    // MARK: - 导出CSV

    /// 导出持仓数据为CSV格式
    static func exportHoldingsToCSV(_ holdings: [Holding]) -> URL? {
        var csv = "代码,名称,市场,资产类型,行业,数量,成本价,现价,年度每股股息,预计派息月份,市值,年度股息,股息率\n"

        for holding in holdings {
            // 按 RFC 4180 转义每个字段：含逗号/引号/换行的字段需用双引号包裹，
            // 内部双引号用两个双引号转义，否则会破坏 CSV 列对齐。
            let row = [
                escapeCSVField(holding.symbol),
                escapeCSVField(holding.name),
                escapeCSVField(holding.market),
                escapeCSVField(holding.assetType),
                escapeCSVField(holding.industry),
                String(format: "%.0f", holding.quantity),
                String(format: "%.2f", holding.averageCost),
                String(format: "%.2f", holding.currentPrice),
                String(format: "%.4f", holding.annualDividendPerShare),
                escapeCSVField(holding.expectedDividendMonths),
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
            AppLogger.data.error("Failed to export CSV: \(String(describing: error), privacy: .public)")
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
            AppLogger.data.error("Failed to export JSON: \(String(describing: error), privacy: .public)")
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

            // 收集该组合下已存在的 symbol，避免重复导入产生重复持仓。
            var existingSymbols = Set(portfolio.holdings.map { $0.symbol })
            var insertedCount = 0

            for importData in importedHoldings {
                // 跳过该组合下已存在的相同 symbol，防止重复导入
                guard !existingSymbols.contains(importData.symbol) else { continue }

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
                existingSymbols.insert(importData.symbol)
                insertedCount += 1
            }

            return insertedCount
        } catch {
            AppLogger.data.error("Failed to import holdings: \(String(describing: error), privacy: .public)")
            return 0
        }
    }

    // MARK: - CSV 辅助

    /// 按 RFC 4180 转义 CSV 字段：含逗号 / 引号 / 换行符的字段需用双引号包裹，
    /// 内部的双引号用两个连续双引号转义。
    private static func escapeCSVField(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")
        guard needsQuoting else { return field }
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

// MARK: - DateFormatter扩展

extension DateFormatter {
    static let fileNameDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        // 固定 locale/timeZone，避免在非公历日历的设备上生成意外的文件名
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}
