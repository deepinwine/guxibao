//
//  AssetOverviewCard.swift
//  DividendTreasure
//
//  首页资产透视概览卡
//

import SwiftUI

struct AssetOverviewCard: View {
    let overview: AssetInsightOverview
    let portfoliosCount: Int

    private let metricColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationLink(destination: AssetInsightView()) {
            VStack(alignment: .leading, spacing: 16) {
                header
                overviewMetrics
                industryInsight
                concentrationInsight
                summaryChips
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("资产透视", systemImage: "eye.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Text("查看详情")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }

    private var overviewMetrics: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: metricColumns, spacing: 12) {
                metricTile(
                    title: "总市值",
                    value: CurrencyFormatter.formatCompact(overview.totalValue),
                    icon: "dollarsign.circle.fill",
                    color: .blue
                )

                metricTile(
                    title: "年度股息",
                    value: CurrencyFormatter.formatCompact(overview.totalDividend),
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
            }

            HStack(spacing: 12) {
                Label("组合股息率", systemImage: "percent")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(PercentFormatter.format(overview.avgYield))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private var industryInsight: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("行业占比")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(overview.topIndustry == "-" ? "暂无主导行业" : "主导行业 \(overview.topIndustry)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if overview.topIndustries.isEmpty {
                emptyInsight(text: "暂无持仓，添加资产后可查看行业分布。")
            } else {
                ForEach(overview.topIndustries) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.getColor().color)
                                    .frame(width: 10, height: 10)
                                Text(item.category)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            Text(item.displayPercentage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.tertiarySystemFill))

                                Capsule()
                                    .fill(item.getColor().color.gradient)
                                    .frame(width: industryBarWidth(for: item.percentage, totalWidth: proxy.size.width))
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var concentrationInsight: some View {
        HStack(spacing: 12) {
            insightTile(
                title: "集中度",
                value: PercentFormatter.format(overview.topThreeConcentration),
                detail: "前 3 大持仓占比",
                icon: "scope",
                color: .orange
            )

            insightTile(
                title: "最大持仓",
                value: overview.largestHolding?.name ?? "-",
                detail: largestHoldingDetail,
                icon: "building.columns.fill",
                color: .indigo
            )
        }
    }

    private var summaryChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            summarySection(title: "市场分布", items: overview.marketSummary)
            summarySection(title: "资产类型", items: overview.assetTypeSummary)
        }
    }

    private var headerSubtitle: String {
        if overview.holdingsCount == 0 {
            return "覆盖 \(portfoliosCount) 个投资组合，当前暂无持仓数据"
        }

        return "\(overview.holdingsCount) 项持仓，覆盖 \(portfoliosCount) 个投资组合"
    }

    private var largestHoldingDetail: String {
        guard let largestHolding = overview.largestHolding else {
            return "暂无持仓数据"
        }

        return "\(largestHolding.symbol) · \(CurrencyFormatter.formatCompact(largestHolding.marketValue))"
    }

    @ViewBuilder
    private func metricTile(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.18))
                .frame(width: 34, height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func insightTile(
        title: String,
        value: String,
        detail: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func summarySection(title: String, items: [AssetBreakdown]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if items.isEmpty {
                emptyInsight(text: "暂无摘要数据")
            } else {
                FlexibleChipLayout(spacing: 8, rowSpacing: 8) {
                    ForEach(Array(items.prefix(3))) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.getColor().color)
                                .frame(width: 8, height: 8)

                            Text(item.category)
                                .font(.caption)
                                .foregroundStyle(.primary)

                            Text(item.displayPercentage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .overlay {
                            Capsule()
                                .stroke(item.getColor().color.opacity(0.18), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func emptyInsight(text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func industryBarWidth(for percentage: Double, totalWidth: CGFloat) -> CGFloat {
        guard percentage > 0 else {
            return 0
        }

        return min(max(totalWidth * percentage, 10), totalWidth)
    }
}

private struct FlexibleChipLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX > 0, currentX + size.width > maxWidth {
                currentX = 0
                currentY += rowHeight + rowSpacing
                rowHeight = 0
            }

            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(
            width: proposal.width ?? currentX,
            height: currentY + rowHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX > bounds.minX, currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + rowSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    AssetOverviewCard(
        overview: AssetInsightOverview(
            totalValue: 125_800,
            totalDividend: 6_500,
            avgYield: 0.0517,
            holdingsCount: 5,
            topAssetType: "股票",
            topIndustry: "银行",
            topMarket: "A股",
            topIndustries: [
                AssetBreakdown(category: "银行", amount: 54_000, percentage: 0.43, holdings: []),
                AssetBreakdown(category: "科技", amount: 38_000, percentage: 0.30, holdings: []),
                AssetBreakdown(category: "其他", amount: 22_000, percentage: 0.17, holdings: [])
            ],
            marketSummary: [
                AssetBreakdown(category: "A股", amount: 82_000, percentage: 0.65, holdings: []),
                AssetBreakdown(category: "港股", amount: 43_800, percentage: 0.35, holdings: [])
            ],
            assetTypeSummary: [
                AssetBreakdown(category: "股票", amount: 95_000, percentage: 0.76, holdings: []),
                AssetBreakdown(category: "基金", amount: 20_800, percentage: 0.17, holdings: []),
                AssetBreakdown(category: "现金", amount: 10_000, percentage: 0.07, holdings: [])
            ],
            topThreeConcentration: 0.78,
            largestHolding: Holding(
                symbol: "600036",
                name: "招商银行",
                market: "A股",
                assetType: "股票",
                industry: "银行",
                quantity: 1_000,
                averageCost: 30,
                currentPrice: 40
            )
        ),
        portfoliosCount: 2
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
