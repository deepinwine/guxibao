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

    @State private var showAddPortfolio = false
    @State private var navigateToRanking = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    // 被动收入目标卡片（可点击）
                    ClickablePassiveIncomeCard(
                        targetAmount: annualPassiveIncomeGoal,
                        currentAmount: totalAnnualDividend
                    )

                    // 资产透视卡片
                    AssetOverviewCard(
                        totalMarketValue: totalMarketValue,
                        totalAnnualDividend: totalAnnualDividend,
                        portfolioYield: portfolioYield,
                        topHoldings: topHoldings,
                        portfoliosCount: portfolios.count
                    )

                    // 快速操作
                    QuickActionsSection(
                        showAddPortfolio: $showAddPortfolio,
                        navigateToRanking: $navigateToRanking
                    )
                }
                .padding()
                .padding(.bottom, 20)
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
            .sheet(isPresented: $showAddPortfolio) {
                AddPortfolioView()
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

    private var allHoldings: [Holding] {
        portfolios.flatMap { $0.holdings }
    }

    private var topHoldings: [(symbol: String, name: String, yield: Double)] {
        let sorted = CalculationService.holdingsByYield(holdings: allHoldings)
        return sorted.prefix(3).map { ($0.symbol, $0.name, $0.dividendYield) }
    }
}

// MARK: - 快速操作区域

struct QuickActionsSection: View {
    @Binding var showAddPortfolio: Bool
    @Binding var navigateToRanking: Bool

    @State private var showImportAsset = false
    @State private var showComingSoon = false
    @State private var comingSoonFeature = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("快速操作", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                // 导入资产（OCR）
                Button(action: { showImportAsset = true }) {
                    ActionButton(
                        title: "导入资产",
                        icon: "camera.fill",
                        color: .blue
                    )
                }

                // 添加持仓（手动）
                Button(action: { showAddPortfolio = true }) {
                    ActionButton(
                        title: "添加持仓",
                        icon: "plus.circle.fill",
                        color: .green
                    )
                }

                // 查看排行（暂时提示）
                Button(action: {
                    comingSoonFeature = "排行榜"
                    showComingSoon = true
                }) {
                    ActionButton(
                        title: "查看排行",
                        icon: "chart.bar.fill",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .alert("即将推出", isPresented: $showComingSoon) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text("\(comingSoonFeature)功能将在后续版本推出")
        }
        .sheet(isPresented: $showImportAsset) {
            ImportAssetView()
        }
    }
}

// MARK: - 操作按钮

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
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
}

#Preview {
    DashboardView()
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}
