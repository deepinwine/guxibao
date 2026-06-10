//
//  PercentFormatter.swift
//  DividendTreasure
//
//  百分比格式化工具
//

import Foundation

struct PercentFormatter {
    /// 格式化百分比
    /// - Parameters:
    ///   - value: 小数形式的百分比（如 0.05 表示 5%）
    ///   - decimalPlaces: 小数位数，默认 2 位
    /// - Returns: 格式化后的字符串（如：5.00%）
    static func format(_ value: Double, decimalPlaces: Int = 2) -> String {
        let percentage = value * 100
        return String(format: "%.\(decimalPlaces)f%%", percentage)
    }

    /// 格式化百分比（带正负号）
    /// - Parameters:
    ///   - value: 小数形式的百分比
    ///   - decimalPlaces: 小数位数，默认 2 位
    /// - Returns: 格式化后的字符串（如：+5.00% 或 -5.00%）
    static func formatWithSign(_ value: Double, decimalPlaces: Int = 2) -> String {
        let percentage = value * 100
        let sign = percentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.\(decimalPlaces)f%%", percentage))"
    }

    /// 格式化股息率（特殊格式，4 位小数）
    /// - Parameter value: 小数形式的股息率
    /// - Returns: 格式化后的字符串
    static func formatDividendYield(_ value: Double) -> String {
        let percentage = value * 100
        return String(format: "%.4f%%", percentage)
    }
}
