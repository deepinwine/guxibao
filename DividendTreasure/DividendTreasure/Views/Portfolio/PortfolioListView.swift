//
//  PortfolioListView.swift
//  DividendTreasure
//
//  组合列表视图
//

import SwiftUI
import SwiftData

struct PortfolioListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Portfolio.createdAt, order: .reverse) private var portfolios: [Portfolio]
    @State private var showingAddPortfolio = false

    var body: some View {
        NavigationStack {
            Group {
                if portfolios.isEmpty {
                    ContentUnavailableView(
                        "暂无组合",
                        systemImage: "briefcase",
                        description: Text("点击右上角 + 创建你的第一个投资组合")
                    )
                } else {
                    List {
                        ForEach(portfolios) { portfolio in
                            NavigationLink(destination: PortfolioDetailView(portfolio: portfolio)) {
                                PortfolioRow(portfolio: portfolio)
                            }
                        }
                        .onDelete(perform: deletePortfolios)
                    }
                }
            }
            .navigationTitle("投资组合")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddPortfolio = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPortfolio) {
                AddPortfolioView()
            }
        }
    }

    private func deletePortfolios(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(portfolios[index])
            }
        }
    }
}

// MARK: - 组合行视图

struct PortfolioRow: View {
    let portfolio: Portfolio

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(portfolio.name)
                    .font(.headline)
                Spacer()
                Text(CurrencyFormatter.formatCompact(marketValue))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label("\(portfolio.holdings.count) 持仓", systemImage: "number")
                Label("\(PercentFormatter.format(dividendYield))", systemImage: "percent")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var marketValue: Double {
        portfolio.holdings.reduce(0) { $0 + $1.marketValue }
    }

    private var annualDividend: Double {
        portfolio.holdings.reduce(0) { $0 + $1.annualDividend }
    }

    private var dividendYield: Double {
        guard marketValue > 0 else { return 0 }
        return annualDividend / marketValue
    }
}

// MARK: - 组合详情视图

struct PortfolioDetailView: View {
    let portfolio: Portfolio
    @State private var showingAddHolding = false

    var body: some View {
        List {
            // 组合统计信息
            Section("组合概览") {
                HStack {
                    Text("总市值")
                    Spacer()
                    Text(CurrencyFormatter.formatCompact(marketValue))
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("年度股息")
                    Spacer()
                    Text(CurrencyFormatter.formatCompact(annualDividend))
                        .foregroundStyle(.green)
                }

                HStack {
                    Text("组合股息率")
                    Spacer()
                    Text(PercentFormatter.format(dividendYield))
                        .foregroundStyle(.orange)
                }

                HStack {
                    Text("持仓数量")
                    Spacer()
                    Text("\(portfolio.holdings.count)")
                        .foregroundStyle(.secondary)
                }
            }

            // 持仓列表
            Section("持仓列表") {
                if portfolio.holdings.isEmpty {
                    ContentUnavailableView(
                        "暂无持仓",
                        systemImage: "chart.bar",
                        description: Text("点击右上角 + 添加持仓")
                    )
                } else {
                    ForEach(portfolio.holdings) { holding in
                        NavigationLink(destination: HoldingFormView(portfolio: portfolio, holding: holding)) {
                            HoldingRow(holding: holding)
                        }
                    }
                    .onDelete(perform: deleteHoldings)
                }
            }
        }
        .navigationTitle(portfolio.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddHolding = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddHolding) {
            HoldingFormView(portfolio: portfolio)
        }
    }

    private var marketValue: Double {
        CalculationService.portfolioMarketValue(holdings: portfolio.holdings)
    }

    private var annualDividend: Double {
        CalculationService.portfolioAnnualDividend(holdings: portfolio.holdings)
    }

    private var dividendYield: Double {
        CalculationService.portfolioDividendYield(holdings: portfolio.holdings)
    }

    private func deleteHoldings(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                portfolio.holdings[index].portfolio = nil
            }
        }
    }
}

// MARK: - 仓行视图

struct HoldingRow: View {
    let holding: Holding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(holding.symbol)
                        .font(.headline)
                    Text(holding.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(CurrencyFormatter.formatCompact(holding.marketValue))
                        .fontWeight(.semibold)
                    HStack(spacing: 8) {
                        Text(PercentFormatter.format(holding.dividendYield))
                            .foregroundStyle(.orange)
                        if holding.profitLoss >= 0 {
                            Text(PercentFormatter.formatWithSign(holding.profitLossPercent))
                                .foregroundStyle(.green)
                        } else {
                            Text(PercentFormatter.formatWithSign(holding.profitLossPercent))
                                .foregroundStyle(.red)
                        }
                    }
                    .font(.caption)
                }
            }

            // 详情行
            HStack(spacing: 16) {
                Label("数量: \(holding.quantity, specifier: "%.0f")", systemImage: "number")
                Label("成本: \(CurrencyFormatter.formatPrice(holding.averageCost))", systemImage: "dollarsign")
                Label("现价: \(CurrencyFormatter.formatPrice(holding.currentPrice))", systemImage: "chart.line.uptrend.xyaxis")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 添加组合视图

struct AddPortfolioView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("组合名称") {
                    TextField("例如：主账户", text: $name)
                }
            }
            .navigationTitle("新建组合")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        let portfolio = Portfolio(name: name)
                        modelContext.insert(portfolio)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    PortfolioListView()
        .modelContainer(for: Portfolio.self, inMemory: true)
}
