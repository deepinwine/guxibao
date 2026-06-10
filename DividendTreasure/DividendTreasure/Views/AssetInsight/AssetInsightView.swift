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

    @State private var selectedDimension: Dimension = .assetType
    @State private var displayMode: DisplayMode = .amount
    @State private var isDetailMode: Bool = false

    enum Dimension: String, CaseIterable {
        case assetType = "资产类型"
        case industry = "行业分布"
        case market = "市场分布"
    }

    enum DisplayMode: String, CaseIterable {
        case amount = "金额"
        case percentage = "占比"
    }

    private var allHoldings: [Holding] {
        portfolios.flatMap { $0.holdings }
    }

    private var breakdownData: [AssetBreakdown] {
        switch selectedDimension {
        case .assetType:
            return isDetailMode ?
                AssetInsightService.breakdownByAssetTypeDetail(holdings: allHoldings) :
                AssetInsightService.breakdownByAssetType(holdings: allHoldings)
        case .industry:
            return AssetInsightService.breakdownByIndustry(holdings: allHoldings)
        case .market:
            return AssetInsightService.breakdownByMarket(holdings: allHoldings)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 维度选择器
                Picker("维度", selection: $selectedDimension) {
                    ForEach(Dimension.allCases, id: \.rawValue) { dim in
                        Text(dim.rawValue).tag(dim)
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
                    if selectedDimension == .assetType {
                        Toggle(isOn: $isDetailMode) {
                            Text("细分")
                                .font(.caption)
                        }
                        .toggleStyle(.button)
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
                                displayMode: displayMode
                            )
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("资产透视")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
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
                    HStack(spacing: 12) {
                        // 颜色标识
                        Circle()
                            .fill(item.getColor().color)
                            .frame(width: 12, height: 12)

                        // 分类名称
                        Text(item.category)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        // 数值显示
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(displayMode == .amount ?
                                 item.displayAmount : item.displayPercentage)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            // 持仓数量
                            Text("\(item.holdings.count) 持仓")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    // 进度条
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    AssetInsightView()
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}
