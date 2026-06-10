//
//  CashflowView.swift
//  DividendTreasure
//
//  现金流报表页面 - 显示股息收入统计和预测
//

import SwiftUI
import SwiftData
import Charts

struct CashflowView: View {
    @Query private var portfolios: [Portfolio]
    @State private var selectedView: CashflowSubview = .monthly

    enum CashflowSubview: String, CaseIterable {
        case monthly = "月度统计"
        case forecast = "未来预测"
        case ranking = "股息排行"
    }

    private var allHoldings: [Holding] {
        portfolios.flatMap { $0.holdings }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 视图选择器
                Picker("视图", selection: $selectedView) {
                    ForEach(CashflowSubview.allCases, id: \.rawValue) { view in
                        Text(view.rawValue).tag(view)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // 内容区域
                if allHoldings.isEmpty {
                    ContentUnavailableView(
                        "暂无持仓数据",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("请先添加持仓信息")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedView {
                            case .monthly:
                                MonthlyCashflowSection(holdings: allHoldings)
                                AnnualSummaryCard(holdings: allHoldings)

                            case .forecast:
                                ForecastSection(holdings: allHoldings)

                            case .ranking:
                                RankingSection(holdings: allHoldings)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("现金流")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - 月度统计区域

struct MonthlyCashflowSection: View {
    let holdings: [Holding]

    private var monthlyData: [MonthlyDividend] {
        CashflowService.getAnnualDividendSummary(holdings: holdings).monthly
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月度股息收入")
                .font(.headline)
                .foregroundStyle(.secondary)

            Chart(monthlyData) { item in
                BarMark(
                    x: .value("月份", item.shortName),
                    y: .value("金额", item.amount)
                )
                .foregroundStyle(.green.gradient)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 年度汇总卡片

struct AnnualSummaryCard: View {
    let holdings: [Holding]
    @AppStorage("annualPassiveIncomeGoal") private var annualPassiveIncomeGoal: Double = 50000

    private var totalDividend: Double {
        holdings.reduce(0) { $0 + $1.annualDividend }
    }

    private var progress: Double {
        guard annualPassiveIncomeGoal > 0 else { return 0 }
        return min(totalDividend / annualPassiveIncomeGoal, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("年度汇总")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("年度股息")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatCompact(totalDividend))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("目标金额")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatCompact(annualPassiveIncomeGoal))
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text("完成进度")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(progress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(progress >= 1.0 ? .green : .orange)
                }
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * progress, height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 未来预测区域

struct ForecastSection: View {
    let holdings: [Holding]

    private var forecasts: [DividendForecast] {
        CashflowService.forecastNextThreeMonths(holdings: holdings)
    }

    private var totalForecast: Double {
        forecasts.reduce(0) { $0 + $1.expectedAmount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("未来三个月股息预测")
                .font(.headline)
                .foregroundStyle(.secondary)

            if forecasts.isEmpty {
                Text("暂无预测数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(forecasts) { forecast in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(forecast.symbol)
                                .font(.headline)
                            Text(forecast.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(forecast.monthName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(CurrencyFormatter.formatCompact(forecast.expectedAmount))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Divider()

                HStack {
                    Text("预计合计")
                        .fontWeight(.medium)
                    Spacer()
                    Text(CurrencyFormatter.formatCompact(totalForecast))
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 排行榜区域

struct RankingSection: View {
    let holdings: [Holding]

    private var rankings: [DividendRanking] {
        CashflowService.getDividendRanking(holdings: holdings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("股息贡献排行榜")
                .font(.headline)
                .foregroundStyle(.secondary)

            if rankings.isEmpty {
                Text("暂无排名数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(rankings.enumerated()), id: \.element.id) { index, ranking in
                    HStack(spacing: 12) {
                        // 排名
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundStyle(index < 3 ? .orange : .secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(ranking.symbol)
                                .font(.headline)
                            Text(ranking.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(ranking.displayAmount)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)

                            Text("\(PercentFormatter.format(ranking.dividendYield))")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 8)
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
    CashflowView()
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}
