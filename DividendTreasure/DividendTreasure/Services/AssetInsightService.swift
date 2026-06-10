//
//  AssetInsightService.swift
//  DividendTreasure
//
//  资产透视服务 - 按资产类型、行业、市场统计分布
//

import Foundation
import SwiftUI

// MARK: - 统计数据模型

struct AssetBreakdown: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
    let holdings: [Holding]

    var displayAmount: String {
        CurrencyFormatter.formatCompact(amount)
    }

    var displayPercentage: String {
        PercentFormatter.format(percentage)
    }
}

// MARK: - 资产透视服务

struct AssetInsightService {

    // MARK: - 按资产类型统计

    /// 按资产类型基础分类统计
    static func breakdownByAssetType(holdings: [Holding]) -> [AssetBreakdown] {
        let grouped = Dictionary(grouping: holdings) { holding in
            // 基础分类映射
            switch holding.assetType {
            case "股票":
                return "股票"
            case "ETF", "指数基金":
                return "基金"
            case "债券":
                return "债券"
            case "货币基金":
                return "现金"
            default:
                return "其他"
            }
        }

        let totalValue = holdings.reduce(0) { $0 + $1.marketValue }

        return grouped.map { (category, items) in
            let amount = items.reduce(0) { $0 + $1.marketValue }
            let percentage = totalValue > 0 ? amount / totalValue : 0
            return AssetBreakdown(
                category: category,
                amount: amount,
                percentage: percentage,
                holdings: items
            )
        }.sorted { $0.amount > $1.amount }
    }

    /// 按资产类型细分统计
    static func breakdownByAssetTypeDetail(holdings: [Holding]) -> [AssetBreakdown] {
        let grouped = Dictionary(grouping: holdings) { $0.assetType }

        let totalValue = holdings.reduce(0) { $0 + $1.marketValue }

        return grouped.map { (category, items) in
            let amount = items.reduce(0) { $0 + $1.marketValue }
            let percentage = totalValue > 0 ? amount / totalValue : 0
            return AssetBreakdown(
                category: category,
                amount: amount,
                percentage: percentage,
                holdings: items
            )
        }.sorted { $0.amount > $1.amount }
    }

    // MARK: - 按行业统计

    static func breakdownByIndustry(holdings: [Holding]) -> [AssetBreakdown] {
        let grouped = Dictionary(grouping: holdings) { $0.industry }

        let totalValue = holdings.reduce(0) { $0 + $1.marketValue }

        return grouped.map { (category, items) in
            let amount = items.reduce(0) { $0 + $1.marketValue }
            let percentage = totalValue > 0 ? amount / totalValue : 0
            return AssetBreakdown(
                category: category,
                amount: amount,
                percentage: percentage,
                holdings: items
            )
        }.sorted { $0.amount > $1.amount }
    }

    // MARK: - 按市场统计

    static func breakdownByMarket(holdings: [Holding]) -> [AssetBreakdown] {
        let grouped = Dictionary(grouping: holdings) { $0.market }

        let totalValue = holdings.reduce(0) { $0 + $1.marketValue }

        return grouped.map { (category, items) in
            let amount = items.reduce(0) { $0 + $1.marketValue }
            let percentage = totalValue > 0 ? amount / totalValue : 0
            return AssetBreakdown(
                category: category,
                amount: amount,
                percentage: percentage,
                holdings: items
            )
        }.sorted { $0.amount > $1.amount }
    }

    // MARK: - 统计概览

    /// 获取所有维度的统计概览
    static func getOverview(holdings: [Holding]) -> AssetInsightOverview {
        let totalValue = holdings.reduce(0) { $0 + $1.marketValue }
        let totalDividend = holdings.reduce(0) { $0 + $1.annualDividend }
        let avgYield = totalValue > 0 ? totalDividend / totalValue : 0

        return AssetInsightOverview(
            totalValue: totalValue,
            totalDividend: totalDividend,
            avgYield: avgYield,
            holdingsCount: holdings.count,
            topAssetType: breakdownByAssetType(holdings: holdings).first?.category ?? "-",
            topIndustry: breakdownByIndustry(holdings: holdings).first?.category ?? "-",
            topMarket: breakdownByMarket(holdings: holdings).first?.category ?? "-"
        )
    }
}

// MARK: - 统计概览

struct AssetInsightOverview {
    let totalValue: Double
    let totalDividend: Double
    let avgYield: Double
    let holdingsCount: Int
    let topAssetType: String
    let topIndustry: String
    let topMarket: String
}

// MARK: - 图表颜色

extension AssetBreakdown {
    /// 获取分类颜色
    func getColor() -> AssetColor {
        switch category {
        // 资产类型
        case "股票":
            return .stock
        case "基金":
            return .fund
        case "债券":
            return .bond
        case "现金":
            return .cash
        case "其他":
            return .other

        // 行业
        case "银行":
            return .bank
        case "保险":
            return .insurance
        case "能源":
            return .energy
        case "公用事业":
            return .utility
        case "消费":
            return .consumer
        case "医药":
            return .healthcare
        case "科技":
            return .technology
        case "地产":
            return .realEstate
        case "通信":
            return .telecom

        // 市场
        case "A股":
            return .aShare
        case "港股":
            return .hongKong
        case "美股":
            return .usStock

        default:
            return .other
        }
    }
}

// MARK: - 资产颜色枚举

enum AssetColor: String {
    case stock = "股票"
    case fund = "基金"
    case bond = "债券"
    case cash = "现金"
    case other = "其他"

    case bank = "银行"
    case insurance = "保险"
    case energy = "能源"
    case utility = "公用事业"
    case consumer = "消费"
    case healthcare = "医药"
    case technology = "科技"
    case realEstate = "地产"
    case telecom = "通信"

    case aShare = "A股"
    case hongKong = "港股"
    case usStock = "美股"

    var color: Color {
        switch self {
        case .stock: return .blue
        case .fund: return .purple
        case .bond: return .green
        case .cash: return .yellow
        case .other: return .gray

        case .bank: return .red
        case .insurance: return .orange
        case .energy: return .yellow
        case .utility: return .cyan
        case .consumer: return .pink
        case .healthcare: return .green
        case .technology: return .blue
        case .realEstate: return .brown
        case .telecom: return .indigo

        case .aShare: return .red
        case .hongKong: return .orange
        case .usStock: return .blue
        }
    }
}
