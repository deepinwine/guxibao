//
//  CurrencyFormatter.swift
//  DividendTreasure
//
//  货币格式化工具
//

import Foundation

struct CurrencyFormatter {
    /// 格式化货币金额
    /// - Parameters:
    ///   - value: 金额数值
    ///   - currency: 货币代码，默认 CNY
    /// - Returns: 格式化后的字符串
    static func format(_ value: Double, currency: String = "CNY") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// 格式化货币金额（紧凑格式）
    /// - Parameters:
    ///   - value: 金额数值
    ///   - currency: 货币代码，默认 CNY
    /// - Returns: 格式化后的紧凑字符串（如：1.23万、2.45亿）
    static func formatCompact(_ value: Double, currency: String = "CNY") -> String {
        if value >= 100000000 {
            // 超过 1 亿
            return String(format: "%.2f亿", value / 100000000)
        } else if value >= 10000 {
            // 超过 1 万
            return String(format: "%.2f万", value / 10000)
        } else {
            return format(value, currency: currency)
        }
    }

    /// 格式化股价
    /// - Parameter value: 价格数值
    /// - Returns: 格式化后的字符串
    static func formatPrice(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }
}
