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
    @AppStorage("annualPassiveIncomeGoal") private var annualPassiveIncomeGoal: Double = 50000

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 被动收入目标卡片
                    PassiveIncomeCard(
                        targetAmount: annualPassiveIncomeGoal,
                        currentAmount: totalAnnualDividend
                    )

                    // 资产透视卡片
                    AssetOverviewCard(
                        totalMarketValue: totalMarketValue,
                        totalAnnualDividend: totalAnnualDividend,
                        portfolioYield: portfolioYield,
                        holdingsCount: totalHoldingsCount,
                        portfoliosCount: portfolios.count
                    )

                    // 快速操作
                    QuickActionsSection()

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("股息宝")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    // MARK: - 计算属性

    private var totalMarketValue: Double {
        portfolios.reduce(0) { $0 + CalculationService.portfolioMarketValue(holdings: $1.holdings) }
    }

    private var totalAnnualDividend: Double {
        portfolios.reduce(0) { $0 + CalculationService.portfolioAnnualDividend(holdings: $1.holdings) }
    }

    private var portfolioYield: Double {
        CalculationService.portfolioDividendYield(holdings: allHoldings)
    }

    private var totalHoldingsCount: Int {
        portfolios.reduce(0) { $0 + $1.holdings.count }
    }

    private var allHoldings: [Holding] {
        portfolios.flatMap { $0.holdings }
    }
}

// MARK: - 快速操作区域

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("快速操作", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                QuickActionButton(
                    title: "添加持仓",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    // TODO: 阶段 5 实现 OCR 导入
                }

                QuickActionButton(
                    title: "查看排行",
                    icon: "chart.bar.fill",
                    color: .orange
                ) {
                    // TODO: 阶段 6 实现排行榜
                }

                QuickActionButton(
                    title: "设置目标",
                    icon: "target",
                    color: .green
                ) {
                    // 跳转到设置页
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 快速操作按钮

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}
