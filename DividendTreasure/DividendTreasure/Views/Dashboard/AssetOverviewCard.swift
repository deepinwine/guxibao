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
    let topHoldings: [(symbol: String, name: String, yield: Double)]
    let portfoliosCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            Label("资产透视", systemImage: "eye.fill")
                .font(.headline)
                .foregroundStyle(.secondary)

            // 主要指标网格
            HStack(spacing: 12) {
                // 总市值
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(.blue)
                        Text("总市值")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(CurrencyFormatter.formatCompact(totalMarketValue))
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

                // 年度股息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.green)
                        Text("年度股息")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(CurrencyFormatter.formatCompact(totalAnnualDividend))
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }

            // 组合股息率
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "percent")
                        .foregroundStyle(.orange)
                    Text("组合股息率")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(PercentFormatter.format(portfolioYield))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)

            // 股息率Top3
            if !topHoldings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.red)
                        Text("股息率 Top 3")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(topHoldings, id: \.symbol) { holding in
                        HStack {
                            Text(holding.symbol)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(holding.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(PercentFormatter.format(holding.yield))
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }

            // 组合数量
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundStyle(.secondary)
                Text("共 \(portfoliosCount) 个投资组合")
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

#Preview {
    AssetOverviewCard(
        totalMarketValue: 125800,
        totalAnnualDividend: 6500,
        portfolioYield: 0.0517,
        topHoldings: [
            ("VZ", "Verizon", 0.063),
            ("00941", "中国移动", 0.060),
            ("601398", "工商银行", 0.056)
        ],
        portfoliosCount: 2
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
