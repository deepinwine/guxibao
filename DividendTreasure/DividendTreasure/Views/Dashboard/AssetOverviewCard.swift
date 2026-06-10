//
//  AssetOverviewCard.swift
//  DividendTreasure
//
//  资产透视卡片 - 显示市值、股息、股息率概览
//

import SwiftUI

struct AssetOverviewCard: View {
    let totalMarketValue: Double
    let totalAnnualDividend: Double
    let portfolioYield: Double
    let holdingsCount: Int
    let portfoliosCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            Label("资产透视", systemImage: "eye.fill")
                .font(.headline)
                .foregroundStyle(.secondary)

            // 主要指标网格
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // 总市值
                MetricItem(
                    title: "总市值",
                    value: CurrencyFormatter.formatCompact(totalMarketValue),
                    icon: "dollarsign.circle.fill",
                    color: .blue
                )

                // 年度股息
                MetricItem(
                    title: "年度股息",
                    value: CurrencyFormatter.formatCompact(totalAnnualDividend),
                    icon: "arrow.down.circle.fill",
                    color: .green
                )

                // 组合股息率
                MetricItem(
                    title: "组合股息率",
                    value: PercentFormatter.format(portfolioYield),
                    icon: "percent",
                    color: .orange
                )

                // 持仓数量
                MetricItem(
                    title: "持仓数量",
                    value: "\(holdingsCount)",
                    icon: "number",
                    color: .purple
                )
            }

            // 组合数量
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundStyle(.secondary)
                Text("共 \(portfoliosCount) 个组合")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 指标项组件

struct MetricItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    AssetOverviewCard(
        totalMarketValue: 125800,
        totalAnnualDividend: 6500,
        portfolioYield: 0.0517,
        holdingsCount: 5,
        portfoliosCount: 2
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
