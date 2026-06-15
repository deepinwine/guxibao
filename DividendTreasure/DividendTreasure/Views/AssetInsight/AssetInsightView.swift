//
//  AssetInsightView.swift
//  DividendTreasure
//
//  资产透视主页面 - 按资产类型、行业、市场查看资产分布
//

import SwiftUI
import SwiftData
import Charts

struct AssetInsightView: View {
    @Query private var portfolios: [Portfolio]

    @State private var selectedDimension: AssetInsightDimension = .industry
    @State private var displayMode: DisplayMode = .amount
    @State private var assetTypeGrouping: AssetTypeGrouping = .summary
    @State private var selectedCategory: String?

    enum DisplayMode: String, CaseIterable {
        case amount = "金额"
        case percentage = "占比"
    }

    private var allHoldings: [Holding] {
        portfolios.flatMap { $0.holdings }
    }

    private var breakdownData: [AssetBreakdown] {
        AssetInsightService.breakdown(
            for: selectedDimension,
            holdings: allHoldings,
            assetTypeGrouping: assetTypeGrouping
        )
    }

    private var drilldownData: [AssetDrilldownItem] {
        guard let selectedCategory else { return [] }
        return AssetInsightService.drilldown(
            for: selectedDimension,
            category: selectedCategory,
            holdings: allHoldings,
            assetTypeGrouping: assetTypeGrouping
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 维度选择器
                Picker("维度", selection: $selectedDimension) {
                    ForEach(AssetInsightDimension.allCases, id: \.self) { dimension in
                        Text(title(for: dimension)).tag(dimension)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // 显示模式切换
                HStack(spacing: 16) {
                    // 金额/占比切换
                    Picker("显示模式", selection: $displayMode) {
                        ForEach(DisplayMode.allCases, id: \.rawValue) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 150)

                    // 基础/细分切换（仅资产类型）
                    if showsAssetTypeGrouping {
                        Picker("资产类型分组", selection: $assetTypeGrouping) {
                            Text("汇总").tag(AssetTypeGrouping.summary)
                            Text("细分").tag(AssetTypeGrouping.detail)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal)

                if allHoldings.isEmpty {
                    ContentUnavailableView(
                        "暂无持仓数据",
                        systemImage: "chart.pie",
                        description: Text("请先添加持仓信息")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 饼图
                            AssetPieChartView(
                                breakdowns: breakdownData,
                                displayMode: displayMode
                            )
                            .frame(height: 250)
                            .padding()

                            // 柱状图
                            AssetBarChartView(
                                breakdowns: breakdownData,
                                displayMode: displayMode
                            )
                            .frame(height: 200)
                            .padding()

                            // 详细列表
                            AssetBreakdownListView(
                                breakdowns: breakdownData,
                                displayMode: displayMode,
                                selectedCategory: selectedCategory,
                                onSelect: { category in
                                    selectedCategory = category
                                }
                            )

                            if let selectedCategory {
                                AssetDrilldownSection(
                                    category: selectedCategory,
                                    items: drilldownData,
                                    onClose: { self.selectedCategory = nil }
                                )
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("资产透视")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .onChange(of: selectedDimension) { _, _ in
                assetTypeGrouping = selectedDimension == .assetType ? assetTypeGrouping : .summary
                selectedCategory = nil
            }
            .onChange(of: assetTypeGrouping) { _, _ in
                selectedCategory = nil
            }
        }
    }

    private var showsAssetTypeGrouping: Bool {
        selectedDimension == .assetType
    }

    private func title(for dimension: AssetInsightDimension) -> String {
        switch dimension {
        case .assetType:
            return "资产类型"
        case .industry:
            return "行业分布"
        case .market:
            return "市场分布"
        }
    }
}

// MARK: - 饼图视图

struct AssetPieChartView: View {
    let breakdowns: [AssetBreakdown]
    let displayMode: AssetInsightView.DisplayMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("资产分布")
                .font(.headline)
                .foregroundStyle(.secondary)

            if breakdowns.isEmpty {
                Text("暂无数据")
                    .foregroundStyle(.secondary)
            } else {
                Chart(breakdowns) { item in
                    SectorMark(
                        angle: .value("金额", displayMode == .amount ? item.amount : item.percentage),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(item.getColor().color)
                }
                .frame(height: 200)

                // 图例
                HStack(spacing: 12) {
                    ForEach(breakdowns.prefix(4)) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.getColor().color)
                                .frame(width: 8, height: 8)
                            Text(item.category)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 柱状图视图

struct AssetBarChartView: View {
    let breakdowns: [AssetBreakdown]
    let displayMode: AssetInsightView.DisplayMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("资产对比")
                .font(.headline)
                .foregroundStyle(.secondary)

            if breakdowns.isEmpty {
                Text("暂无数据")
                    .foregroundStyle(.secondary)
            } else {
                Chart(breakdowns) { item in
                    BarMark(
                        x: .value("分类", item.category),
                        y: .value(
                            "数值",
                            displayMode == .amount ? item.amount : item.percentage * 100
                        )
                    )
                    .foregroundStyle(item.getColor().color)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 详细列表视图

struct AssetBreakdownListView: View {
    let breakdowns: [AssetBreakdown]
    let displayMode: AssetInsightView.DisplayMode
    let selectedCategory: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细列表")
                .font(.headline)
                .foregroundStyle(.secondary)

            if breakdowns.isEmpty {
                Text("暂无数据")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(breakdowns) { item in
                    Button {
                        onSelect(item.category)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            AssetBreakdownRow(item: item, displayMode: displayMode)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 6)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(item.getColor().color)
                                        .frame(width: geometry.size.width * item.percentage, height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                    .background(selectedCategory == item.category ? item.getColor().color.opacity(0.12) : Color(.systemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedCategory == item.category ? item.getColor().color : Color(.systemGray5), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct AssetBreakdownRow: View {
    let item: AssetBreakdown
    let displayMode: AssetInsightView.DisplayMode

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.getColor().color)
                .frame(width: 12, height: 12)

            Text(item.category)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(displayMode == .amount ? item.displayAmount : item.displayPercentage)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(item.holdings.count) 持仓")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AssetDrilldownSection: View {
    let category: String
    let items: [AssetDrilldownItem]
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(category) 持仓下钻")
                        .font(.headline)
                    Text("按市值从高到低")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("关闭", action: onClose)
                    .font(.caption)
            }

            if items.isEmpty {
                Text("暂无持仓")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    AssetDrilldownRow(item: item)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct AssetDrilldownRow: View {
    let item: AssetDrilldownItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(AssetBreakdown(
                    category: item.category,
                    amount: item.amount,
                    percentage: item.percentageWithinCategory,
                    holdings: [item.holding]
                ).getColor().color)
                .frame(width: 10, height: 10)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.holding.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(item.holding.symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.formatCompact(item.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(PercentFormatter.format(item.percentageWithinCategory))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private extension AssetInsightDimension {
    static let allCases: [AssetInsightDimension] = [.assetType, .industry, .market]
}

#Preview {
    AssetInsightView()
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}
