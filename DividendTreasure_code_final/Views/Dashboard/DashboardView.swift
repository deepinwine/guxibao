//
//  DashboardView.swift
//  DividendTreasure
//
//  首页总览视图
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var portfolios: [Portfolio]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 总览卡片
                    VStack(alignment: .leading, spacing: 12) {
                        Text("总览")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            MetricCard(
                                title: "总市值",
                                value: CurrencyFormatter.formatCompact(totalMarketValue),
                                icon: "dollarsign.circle.fill",
                                color: .blue
                            )

                            MetricCard(
                                title: "预计股息",
                                value: CurrencyFormatter.formatCompact(totalAnnualDividend),
                                icon: "arrow.down.circle.fill",
                                color: .green
                            )
                        }

                        HStack(spacing: 16) {
                            MetricCard(
                                title: "组合股息率",
                                value: PercentFormatter.format(portfolioYield),
                                icon: "percent",
                                color: .orange
                            )

                            MetricCard(
                                title: "持仓数量",
                                value: "\(totalHoldingsCount)",
                                icon: "number",
                                color: .purple
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("股息宝")
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - 计算属性

    private var totalMarketValue: Double {
        portfolios.reduce(0) { $0 + $1.holdings.reduce(0) { $0 + $1.marketValue } }
    }

    private var totalAnnualDividend: Double {
        portfolios.reduce(0) { $0 + $1.holdings.reduce(0) { $0 + $1.annualDividend } }
    }

    private var portfolioYield: Double {
        guard totalMarketValue > 0 else { return 0 }
        return totalAnnualDividend / totalMarketValue
    }

    private var totalHoldingsCount: Int {
        portfolios.reduce(0) { $0 + $1.holdings.count }
    }
}

// MARK: - 指标卡片组件

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
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
    DashboardView()
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}
