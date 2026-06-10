//
//  HoldingFormView.swift
//  DividendTreasure
//
//  持仓添加/编辑表单
//

import SwiftUI
import SwiftData

struct HoldingFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // 编辑模式：传入现有持仓
    let holding: Holding?
    let portfolio: Portfolio

    // 表单字段
    @State private var symbol: String = ""
    @State private var name: String = ""
    @State private var market: String = "A股"
    @State private var assetType: String = "股票"
    @State private var industry: String = "其他"
    @State private var quantity: String = ""
    @State private var averageCost: String = ""
    @State private var currentPrice: String = ""
    @State private var annualDividendPerShare: String = ""
    @State private var expectedDividendMonths: String = ""

    // 验证
    @State private var showError = false
    @State private var errorMessage = ""

    // 股票搜索
    @State private var showStockSearch = false
    @State private var isFetchingData = false

    init(portfolio: Portfolio, holding: Holding? = nil) {
        self.portfolio = portfolio
        self.holding = holding

        // 如果是编辑模式，初始化表单字段
        if let holding = holding {
            _symbol = State(initialValue: holding.symbol)
            _name = State(initialValue: holding.name)
            _market = State(initialValue: holding.market)
            _assetType = State(initialValue: holding.assetType)
            _industry = State(initialValue: holding.industry)
            _quantity = State(initialValue: String(holding.quantity))
            _averageCost = State(initialValue: String(holding.averageCost))
            _currentPrice = State(initialValue: String(holding.currentPrice))
            _annualDividendPerShare = State(initialValue: String(holding.annualDividendPerShare))
            _expectedDividendMonths = State(initialValue: holding.expectedDividendMonths)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section("基本信息") {
                    // 股票搜索按钮
                    Button(action: { showStockSearch = true }) {
                        HStack {
                            Label("搜索股票", systemImage: "magnifyingglass")
                                .foregroundStyle(.blue)
                            Spacer()
                            if isFetchingData {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // 或手动输入
                    Text("或手动输入：")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    TextField("股票代码", text: $symbol)
                        .textContentType(.name)

                    TextField("股票名称", text: $name)
                        .textContentType(.name)

                    Picker("市场", selection: $market) {
                        ForEach(Market.allCases, id: \.rawValue) { market in
                            Text(market.rawValue).tag(market.rawValue)
                        }
                    }

                    Picker("资产类型", selection: $assetType) {
                        ForEach(AssetType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue).tag(type.rawValue)
                        }
                    }

                    Picker("行业", selection: $industry) {
                        ForEach(Industry.allCases, id: \.rawValue) { industry in
                            Text(industry.rawValue).tag(industry.rawValue)
                        }
                    }
                }

                // 持仓数据
                Section("持仓数据") {
                    TextField("持仓数量", text: $quantity)
                        .keyboardType(.decimalPad)

                    TextField("成本价", text: $averageCost)
                        .keyboardType(.decimalPad)

                    TextField("当前价", text: $currentPrice)
                        .keyboardType(.decimalPad)
                }

                // 股息信息
                Section("股息信息") {
                    TextField("年度每股股息", text: $annualDividendPerShare)
                        .keyboardType(.decimalPad)

                    TextField("预计派息月份（例如：6,7）", text: $expectedDividendMonths)
                }

                // 计算预览（仅当数据完整时显示）
                if let qty = Double(quantity),
                   let cost = Double(averageCost),
                   let price = Double(currentPrice),
                   let dividend = Double(annualDividendPerShare) {

                    Section("计算预览") {
                        HStack {
                            Text("市值")
                            Spacer()
                            Text(CurrencyFormatter.formatCompact(qty * price))
                                .foregroundStyle(.blue)
                        }

                        HStack {
                            Text("年度股息")
                            Spacer()
                            Text(CurrencyFormatter.formatCompact(qty * dividend))
                                .foregroundStyle(.green)
                        }

                        HStack {
                            Text("股息率")
                            Spacer()
                            Text(PercentFormatter.format(dividend / price))
                                .foregroundStyle(.orange)
                        }

                        HStack {
                            Text("浮盈浮亏")
                            Spacer()
                            let profit = (price - cost) * qty
                            if profit >= 0 {
                                Text(CurrencyFormatter.format(profit))
                                    .foregroundStyle(.green)
                            } else {
                                Text(CurrencyFormatter.format(profit))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle(holding == nil ? "添加持仓" : "编辑持仓")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(holding == nil ? "添加" : "保存") {
                        saveHolding()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showStockSearch) {
                StockSearchView { result, stockData in
                    // 自动填充股票信息
                    symbol = result.symbol
                    name = result.name
                    market = result.market

                    // 如果有股息数据，自动填充
                    if let data = stockData {
                        if data.currentPrice > 0 {
                            currentPrice = String(format: "%.2f", data.currentPrice)
                        }
                        if data.latestDividend > 0 {
                            annualDividendPerShare = String(format: "%.4f", data.latestDividend)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 验证和保存

    private var isValid: Bool {
        !symbol.isEmpty && !name.isEmpty
    }

    private func saveHolding() {
        // 验证数量
        let qty = Double(quantity) ?? 0
        let cost = Double(averageCost) ?? 0
        let price = Double(currentPrice) ?? 0
        let dividend = Double(annualDividendPerShare) ?? 0

        if qty <= 0 {
            errorMessage = "持仓数量必须大于 0"
            showError = true
            return
        }

        if price <= 0 {
            errorMessage = "当前价格必须大于 0"
            showError = true
            return
        }

        if holding != nil {
            // 编辑模式：更新现有持仓
            holding!.symbol = symbol
            holding!.name = name
            holding!.market = market
            holding!.assetType = assetType
            holding!.industry = industry
            holding!.quantity = qty
            holding!.averageCost = cost
            holding!.currentPrice = price
            holding!.annualDividendPerShare = dividend
            holding!.expectedDividendMonths = expectedDividendMonths
            holding!.updatedAt = Date()
        } else {
            // 添加模式：创建新持仓
            let newHolding = Holding(
                symbol: symbol,
                name: name,
                market: market,
                assetType: assetType,
                industry: industry,
                quantity: qty,
                averageCost: cost,
                currentPrice: price,
                annualDividendPerShare: dividend,
                expectedDividendMonths: expectedDividendMonths
            )
            newHolding.portfolio = portfolio
            modelContext.insert(newHolding)
        }

        dismiss()
    }
}

#Preview("添加持仓") {
    HoldingFormView(portfolio: Portfolio(name: "主账户"))
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}

#Preview("编辑持仓") {
    let portfolio = Portfolio(name: "主账户")
    let holding = Holding(
        symbol: "601398",
        name: "工商银行",
        market: "A股",
        assetType: "股票",
        industry: "银行",
        quantity: 10000,
        averageCost: 4.50,
        currentPrice: 5.20,
        annualDividendPerShare: 0.293,
        expectedDividendMonths: "6,7"
    )
    holding.portfolio = portfolio

    return HoldingFormView(portfolio: portfolio, holding: holding)
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}