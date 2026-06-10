//
//  StrategyTemplate.swift
//  DividendTreasure
//
//  策略模板枚举
//

import Foundation

// MARK: - 策略模板

enum StrategyTemplate: String, CaseIterable, Identifiable {
    case dividendYieldGrid = "股息率网格"
    case costPriceLevel = "成本价档位"
    case dynamicRebalance = "动态再平衡"
    case custom = "自定义"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .dividendYieldGrid:
            return "高股息率买入，低股息率卖出"
        case .costPriceLevel:
            return "基于成本价设置上下档位"
        case .dynamicRebalance:
            return "维持目标股息率区间"
        case .custom:
            return "完全自定义档位参数"
        }
    }

    var icon: String {
        switch self {
        case .dividendYieldGrid: return "chart.xyaxis.line"
        case .costPriceLevel: return "dollarsign.circle"
        case .dynamicRebalance: return "arrow.left.arrow.right"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - 策略参数

struct StrategyParameters {
    // 股息率网格参数
    var targetBuyYield: Double = 0.06
    var targetSellYield: Double = 0.04
    var yieldStep: Double = 0.005
    var levelCount: Int = 3

    // 成本价档位参数
    var costPrice: Double = 0
    var percentStep: Double = 0.05

    // 动态再平衡参数
    var targetYieldLow: Double = 0.04
    var targetYieldHigh: Double = 0.06
}

// MARK: - 档位生成参数

struct GridLevelParams {
    var price: Double
    var direction: String
    var quantity: Double
}
