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

// MARK: - 组合详情视图（占位）

struct PortfolioDetailView: View {
    let portfolio: Portfolio

    var body: some View {
        List {
            Section("持仓列表") {
                ForEach(portfolio.holdings) { holding in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(holding.symbol)
                                .font(.headline)
                            Text(holding.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(CurrencyFormatter.format(holding.marketValue))
                            Text("\(PercentFormatter.format(holding.dividendYield))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(portfolio.name)
        .navigationBarTitleDisplayMode(.inline)
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
