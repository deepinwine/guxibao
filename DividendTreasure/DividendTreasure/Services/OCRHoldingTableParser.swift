//
//  OCRHoldingTableParser.swift
//  DividendTreasure
//
//  基于 OCR 文本框坐标解析持仓表格，避免数量和市值串列/串行。
//

import CoreGraphics
import Foundation

struct OCRTextObservation {
    let text: String
    let boundingBox: CGRect

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var centerX: CGFloat {
        boundingBox.midX
    }

    var centerY: CGFloat {
        boundingBox.midY
    }
}

final class OCRHoldingTableParser {
    typealias SymbolResolver = (String) -> StockSearchResult?

    private let symbolResolver: SymbolResolver

    init(symbolResolver: @escaping SymbolResolver) {
        self.symbolResolver = symbolResolver
    }

    func orderedTexts(from observations: [OCRTextObservation]) -> [String] {
        groupIntoRows(observations).map { row in
            row.items.map(\.trimmedText).joined(separator: " ")
        }
    }

    func parse(observations: [OCRTextObservation]) -> [OCRStockCandidate] {
        let rows = groupIntoRows(observations)
        guard !rows.isEmpty else { return [] }

        let headerIndex = detectHeaderRowIndex(in: rows)
        let dataRows = rows.enumerated().compactMap { index, row in
            index == headerIndex ? nil : row
        }

        let headerColumns = headerIndex.map { inferHeaderColumns(from: rows[$0]) } ?? []
        let recordBlocks = buildRecordBlocks(from: dataRows)

        return recordBlocks.compactMap { parseRecordBlock($0, headerColumns: headerColumns) }
    }

    private struct OCRRow {
        var items: [OCRTextObservation]

        var centerY: CGFloat {
            guard !items.isEmpty else { return 0 }
            return items.map(\.centerY).reduce(0, +) / CGFloat(items.count)
        }

        var averageHeight: CGFloat {
            guard !items.isEmpty else { return 0 }
            return items.map(\.boundingBox.height).reduce(0, +) / CGFloat(items.count)
        }
    }

    private struct OCRRecordBlock {
        let rows: [OCRRow]
    }

    private struct HeaderColumn {
        let kind: ColumnKind
        let centerX: CGFloat
    }

    private struct NumericCell {
        let value: Double
        let centerX: CGFloat
        let columnKind: ColumnKind?
        let isDecimal: Bool
        let explicitMarketValue: Bool
    }

    private struct StockSymbolMatch {
        let symbol: String
        let wasNormalized: Bool
    }

    private enum ColumnKind: CaseIterable {
        case name
        case symbol
        case price
        case cost
        case quantity
        case marketValue
    }

    private func groupIntoRows(_ observations: [OCRTextObservation]) -> [OCRRow] {
        let sorted = observations
            .filter { !$0.trimmedText.isEmpty }
            .sorted {
                if abs($0.centerY - $1.centerY) > 0.0001 {
                    return $0.centerY > $1.centerY
                }
                return $0.centerX < $1.centerX
            }

        var rows: [OCRRow] = []

        for observation in sorted {
            guard var lastRow = rows.last else {
                rows.append(OCRRow(items: [observation]))
                continue
            }

            let rowTolerance = max(lastRow.averageHeight * 0.8, 0.025)
            if abs(observation.centerY - lastRow.centerY) <= rowTolerance {
                lastRow.items.append(observation)
                lastRow.items.sort { $0.centerX < $1.centerX }
                rows[rows.count - 1] = lastRow
            } else {
                rows.append(OCRRow(items: [observation]))
            }
        }

        return rows
    }

    private func detectHeaderRowIndex(in rows: [OCRRow]) -> Int? {
        var bestMatch: (index: Int, score: Int)?

        for (index, row) in rows.enumerated() {
            let kinds = Set(row.items.compactMap { classifyHeader(in: $0.trimmedText) })
            guard kinds.count >= 2 else { continue }

            if bestMatch == nil || kinds.count > bestMatch!.score {
                bestMatch = (index, kinds.count)
            }
        }

        return bestMatch?.index
    }

    private func inferHeaderColumns(from row: OCRRow) -> [HeaderColumn] {
        row.items.compactMap { item in
            guard let kind = classifyHeader(in: item.trimmedText) else { return nil }
            return HeaderColumn(kind: kind, centerX: item.centerX)
        }
    }

    private func buildRecordBlocks(from rows: [OCRRow]) -> [OCRRecordBlock] {
        var blocks: [OCRRecordBlock] = []
        var currentRows: [OCRRow] = []

        for row in rows {
            if rowContainsIdentifier(row) {
                if !currentRows.isEmpty {
                    blocks.append(OCRRecordBlock(rows: currentRows))
                }
                currentRows = [row]
                continue
            }

            guard let previous = currentRows.last else { continue }

            let verticalGap = previous.centerY - row.centerY
            let maxGap = max(previous.averageHeight * 4.0, 0.12)

            if verticalGap <= maxGap {
                currentRows.append(row)
            } else if !currentRows.isEmpty {
                blocks.append(OCRRecordBlock(rows: currentRows))
                currentRows = []
            }
        }

        if !currentRows.isEmpty {
            blocks.append(OCRRecordBlock(rows: currentRows))
        }

        return blocks
    }

    private func parseRecordBlock(_ block: OCRRecordBlock, headerColumns: [HeaderColumn]) -> OCRStockCandidate? {
        let items = block.rows.flatMap(\.items)

        guard let identity = extractIdentity(from: items) else { return nil }

        var name = identity.name
        var symbol = identity.symbol
        var confidence = identity.symbol != nil ? (identity.symbolWasNormalized ? 0.82 : 0.9) : 0.75

        if let name, let resolved = symbolResolver(name) {
            if symbol == nil {
                symbol = resolved.symbol
                confidence = 0.88
            } else if identity.symbolWasNormalized, symbol != resolved.symbol {
                symbol = resolved.symbol
                confidence = 0.86
            }
        }

        let numericCells = items.compactMap { item in
            makeNumericCell(from: item, name: name, symbol: symbol, headerColumns: headerColumns)
        }

        let quantity = resolveQuantity(from: numericCells)
        var currentPrice = resolvePrice(from: numericCells)
        let costPrice = resolveCost(from: numericCells)
        var marketValue = resolveMarketValue(from: numericCells)

        if marketValue == nil, let currentPrice, let quantity {
            marketValue = currentPrice * quantity
        }

        if currentPrice == nil, let marketValue, let quantity, quantity > 0 {
            currentPrice = marketValue / quantity
        }

        if quantity == nil || quantity == 0 {
            return nil
        }

        if name == nil, let symbol {
            name = symbol
        }

        return OCRStockCandidate(
            name: name,
            symbol: symbol,
            quantity: quantity,
            currentPrice: currentPrice,
            costPrice: costPrice,
            marketValue: marketValue,
            confidence: confidence
        )
    }

    private func extractIdentity(from items: [OCRTextObservation]) -> (name: String?, symbol: String?, symbolWasNormalized: Bool)? {
        let sortedItems = items.sorted { $0.centerX < $1.centerX }

        let symbolMatch = sortedItems.compactMap { extractStockSymbol(from: $0.trimmedText) }.first
        let name = sortedItems.compactMap { extractStockName(from: $0.trimmedText) }.first

        if name == nil && symbolMatch == nil {
            return nil
        }

        return (name, symbolMatch?.symbol, symbolMatch?.wasNormalized ?? false)
    }

    private func makeNumericCell(
        from item: OCRTextObservation,
        name: String?,
        symbol: String?,
        headerColumns: [HeaderColumn]
    ) -> NumericCell? {
        let text = item.trimmedText
        if text.isEmpty { return nil }
        if let name, text == name { return nil }
        if let symbol, text == symbol { return nil }

        let explicitMarketValue = text.contains("万") || text.contains("亿")
        guard let value = extractNumber(from: text) else { return nil }

        let columnKind = nearestHeaderKind(to: item.centerX, headerColumns: headerColumns)
        let isDecimal = text.contains(".")

        return NumericCell(
            value: explicitMarketValue ? scaleMarketValue(value, rawText: text) : value,
            centerX: item.centerX,
            columnKind: columnKind,
            isDecimal: isDecimal,
            explicitMarketValue: explicitMarketValue
        )
    }

    private func resolveQuantity(from cells: [NumericCell]) -> Double? {
        let headerMatched = cells.filter {
            $0.columnKind == .quantity && isLikelyQuantity($0.value)
        }
        if let best = selectLeftmost(from: headerMatched) {
            return best.value
        }

        let heuristics = cells.filter {
            ($0.columnKind == nil || $0.columnKind == .quantity) && isLikelyQuantity($0.value)
        }
        return selectLeftmost(from: heuristics)?.value
    }

    private func resolvePrice(from cells: [NumericCell]) -> Double? {
        let headerMatched = cells.filter {
            $0.columnKind == .price && isLikelyPrice($0.value)
        }
        if let best = selectLeftmost(from: headerMatched) {
            return best.value
        }

        let heuristics = cells.filter {
            ($0.columnKind == nil || $0.columnKind == .price) && isLikelyPrice($0.value)
        }
        return selectLeftmost(from: heuristics)?.value
    }

    private func resolveCost(from cells: [NumericCell]) -> Double? {
        let headerMatched = cells.filter {
            $0.columnKind == .cost && isLikelyPrice($0.value)
        }
        return selectLeftmost(from: headerMatched)?.value
    }

    private func resolveMarketValue(from cells: [NumericCell]) -> Double? {
        if let best = cells
            .filter({ $0.explicitMarketValue })
            .max(by: { $0.value < $1.value }) {
            return best.value
        }

        let headerMatched = cells.filter {
            $0.columnKind == .marketValue && isLikelyMarketValue($0.value)
        }
        if let best = selectRightmost(from: headerMatched) {
            return best.value
        }

        let heuristics = cells.filter {
            ($0.columnKind == nil || $0.columnKind == .marketValue) && isLikelyMarketValue($0.value)
        }
        return selectRightmost(from: heuristics)?.value
    }

    private func nearestHeaderKind(to x: CGFloat, headerColumns: [HeaderColumn]) -> ColumnKind? {
        guard let closest = headerColumns.min(by: {
            abs($0.centerX - x) < abs($1.centerX - x)
        }) else {
            return nil
        }

        return abs(closest.centerX - x) <= 0.15 ? closest.kind : nil
    }

    private func rowContainsIdentifier(_ row: OCRRow) -> Bool {
        row.items.contains { item in
            extractStockName(from: item.trimmedText) != nil || extractStockSymbol(from: item.trimmedText) != nil
        }
    }

    private func classifyHeader(in text: String) -> ColumnKind? {
        if ["股票名称", "名称", "证券名称"].contains(where: text.contains) {
            return .name
        }
        if ["股票代码", "代码", "证券代码"].contains(where: text.contains) {
            return .symbol
        }
        if ["持仓数量", "持有数量", "持仓股数", "持仓量", "数量", "股数", "可用数量", "可用股数"].contains(where: text.contains) {
            return .quantity
        }
        if ["持仓市值", "持有市值", "参考市值", "最新市值", "市值"].contains(where: text.contains) {
            return .marketValue
        }
        if ["现价", "最新价", "当前价", "市价"].contains(where: text.contains) {
            return .price
        }
        if ["成本价", "买入价", "持仓成本", "均价", "成本"].contains(where: text.contains) {
            return .cost
        }
        return nil
    }

    private func extractStockName(from text: String) -> String? {
        let pattern = "[\\u4e00-\\u9fa5]{2,10}"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }

        let name = String(text[range])
        let blackList = [
            "持仓", "市值", "成本", "盈亏", "可用", "冻结", "总计", "合计",
            "股票", "代码", "名称", "数量", "价格", "成本价", "现价", "证券",
            "账户", "资金", "日期", "时间", "账号", "今日", "昨日", "收益"
        ]

        if blackList.contains(name) {
            return nil
        }

        return name
    }

    private func extractStockSymbol(from text: String) -> StockSymbolMatch? {
        if let exact = extractExactSixDigitSymbol(from: text) {
            return StockSymbolMatch(symbol: exact, wasNormalized: false)
        }

        let normalized = normalizePotentialStockCode(in: text)
        let pattern = "\\d{6}"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
              let range = Range(match.range, in: normalized) else {
            return nil
        }

        return StockSymbolMatch(symbol: String(normalized[range]), wasNormalized: true)
    }

    private func extractExactSixDigitSymbol(from text: String) -> String? {
        let pattern = "\\b\\d{6}\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }

        return String(text[range])
    }

    private func normalizePotentialStockCode(in text: String) -> String {
        let mapping: [Character: Character] = [
            "O": "0", "o": "0", "Q": "0", "D": "0",
            "I": "1", "l": "1", "|": "1", "L": "1",
            "Z": "2", "z": "2",
            "S": "5", "s": "5",
            "G": "6", "b": "6",
            "B": "8"
        ]

        return text.compactMap { character in
            if character.isWholeNumber {
                return character
            }
            if let mapped = mapping[character] {
                return mapped
            }
            return nil
        }.reduce(into: "") { partialResult, character in
            partialResult.append(character)
        }
    }

    private func extractNumber(from text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: "")
        let pattern = "\\d+(?:\\.\\d+)?"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
              let range = Range(match.range, in: normalized) else {
            return nil
        }

        return Double(normalized[range])
    }

    private func scaleMarketValue(_ value: Double, rawText: String) -> Double {
        if rawText.contains("亿") {
            return value * 100000000
        }
        if rawText.contains("万") {
            return value * 10000
        }
        return value
    }

    private func isLikelyQuantity(_ value: Double) -> Bool {
        guard value >= 1, value <= 10_000_000 else { return false }

        if value >= 100 && value.truncatingRemainder(dividingBy: 100) == 0 {
            return true
        }

        if value >= 10 && value < 100_000 && value.truncatingRemainder(dividingBy: 10) == 0 {
            return true
        }

        return value.rounded() == value && value < 10_000
    }

    private func isLikelyPrice(_ value: Double) -> Bool {
        value > 0.01 && value < 10000
    }

    private func isLikelyMarketValue(_ value: Double) -> Bool {
        value >= 1000
    }

    private func selectLeftmost(from cells: [NumericCell]) -> NumericCell? {
        cells.min(by: { $0.centerX < $1.centerX })
    }

    private func selectRightmost(from cells: [NumericCell]) -> NumericCell? {
        cells.max(by: { $0.centerX < $1.centerX })
    }
}
