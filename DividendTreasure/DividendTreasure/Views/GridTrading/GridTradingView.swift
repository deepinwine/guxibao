//
//  GridTradingView.swift
//  DividendTreasure
//
//  网格交易主页面
//

import SwiftUI
import SwiftData
import os

struct GridTradingView: View {
    // MARK: - Properties

    let holding: Holding

    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var subscriptionService = SubscriptionService.shared

    @State private var gridLevels: [GridTradingLevel] = []
    @State private var showQuickGenerate = false
    @State private var showStrategyTemplate = false
    @State private var showAddLevel = false
    @State private var showTradeRecord = false
    @State private var showOCR = false
    @State private var showPremiumPrompt = false
    @State private var premiumFeature: String = ""

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 股票信息卡片
                stockInfoCard

                // 操作按钮区域
                actionButtons

                // 档位列表
                gridLevelsSection

                // 底部按钮（交易记录 / 截图识别）
                bottomButtons
            }
            .padding()
        }
        .navigationTitle("网格交易")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showQuickGenerate) {
            QuickGenerateView(holding: holding) { levels in
                addLevels(levels)
            }
        }
        .sheet(isPresented: $showStrategyTemplate) {
            StrategyTemplateView(holding: holding) { levels in
                addLevels(levels)
            }
        }
        .sheet(isPresented: $showAddLevel) {
            GridLevelFormView(holding: holding) { level in
                addLevel(level)
            }
        }
        .sheet(isPresented: $showTradeRecord) {
            TradeRecordView(holding: holding)
        }
        .sheet(isPresented: $showOCR) {
            TradeOCRView(holding: holding) { record in
                // 处理识别结果
            }
        }
        .alert("会员功能", isPresented: $showPremiumPrompt) {
            Button("取消", role: .cancel) { }
            Button("了解会员") {
                // 跳转到订阅页面
            }
        } message: {
            Text("\(premiumFeature)是会员专属功能，升级会员后可解锁使用。")
        }
        .onAppear {
            loadGridLevels()
        }
    }

    // MARK: - Stock Info Card

    private var stockInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(holding.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(holding.symbol)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(CurrencyFormatter.formatPrice(holding.currentPrice))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(PercentFormatter.formatDividendYield(holding.dividendYield))
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }

            Divider()

            HStack(spacing: 24) {
                infoItem(title: "持仓数量", value: String(format: "%.0f", holding.quantity))
                infoItem(title: "持仓成本", value: CurrencyFormatter.formatPrice(holding.averageCost))
                infoItem(title: "浮盈浮亏", value: PercentFormatter.formatWithSign(holding.profitLossPercent))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func infoItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            actionButton(title: "快速生成", icon: "bolt.fill", color: .blue) {
                showQuickGenerate = true
            }

            actionButton(title: "策略模板", icon: "doc.text.fill", color: .orange) {
                if subscriptionService.status.isActive {
                    showStrategyTemplate = true
                } else {
                    premiumFeature = "策略模板"
                    showPremiumPrompt = true
                }
            }

            actionButton(title: "手动添加", icon: "plus.circle.fill", color: .green) {
                // 非会员档位数受限
                if subscriptionService.canAddGridLevel(currentCount: gridLevels.count) {
                    showAddLevel = true
                } else {
                    premiumFeature = "更多档位"
                    showPremiumPrompt = true
                }
            }
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .cornerRadius(12)
        }
    }

    // MARK: - Grid Levels Section

    private var gridLevelsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("档位列表")
                    .font(.headline)
                Spacer()
                Text("共 \(gridLevels.count) 档")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if gridLevels.isEmpty {
                emptyStateView
            } else {
                ForEach(gridLevels, id: \.id) { level in
                    GridLevelRow(level: level)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "grid")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("暂无档位")
                .font(.headline)
            Text("点击上方按钮添加档位")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 16) {
            Button(action: { showTradeRecord = true }) {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("交易记录")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }

            Button(action: {
                if subscriptionService.status.isActive {
                    showOCR = true
                } else {
                    premiumFeature = "截图识别"
                    showPremiumPrompt = true
                }
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("上传截图识别")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Data Operations

    private func loadGridLevels() {
        let holdingId = holding.id
        let descriptor = FetchDescriptor<GridTradingLevel>(
            predicate: #Predicate { level in
                level.holding?.id == holdingId
            }
        )
        do {
            // 存入时即按价格降序排列，避免在 body 中每次渲染都重复排序。
            gridLevels = try modelContext.fetch(descriptor).sorted { $0.price > $1.price }
        } catch {
            AppLogger.data.error("Failed to load grid levels: \(String(describing: error), privacy: .public)")
        }
    }

    private func addLevel(_ level: GridTradingLevel) {
        level.holding = holding
        modelContext.insert(level)
        try? modelContext.save()
        loadGridLevels()
    }

    private func addLevels(_ levels: [GridTradingLevel]) {
        // 非会员档位数受限：只保留权限允许的档位数，超出部分忽略
        let maxAllowed = subscriptionService.canAddGridLevel(currentCount: gridLevels.count)
            ? max(subscriptionService.permissions.gridTradingLevels - gridLevels.count, 0)
            : 0
        let freeTierLimited = subscriptionService.permissions.gridTradingLevels != Int.max
        let levelsToInsert = freeTierLimited ? Array(levels.prefix(maxAllowed)) : levels

        for level in levelsToInsert {
            level.holding = holding
            modelContext.insert(level)
        }
        try? modelContext.save()
        loadGridLevels()
    }
}

// MARK: - Grid Level Row

struct GridLevelRow: View {
    let level: GridTradingLevel

    var body: some View {
        HStack(spacing: 12) {
            // 方向指示
            Circle()
                .fill(level.direction == "买入" ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            // 价格和股息率
            VStack(alignment: .leading, spacing: 4) {
                Text("¥\(CurrencyFormatter.formatPrice(level.price))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(PercentFormatter.formatDividendYield(level.yieldRate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 数量
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.0f", level.quantity))股")
                    .font(.subheadline)
                Text(level.isExecuted ? "已执行" : "待执行")
                    .font(.caption)
                    .foregroundColor(level.isExecuted ? .green : .orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GridTradingView(holding: Holding(
            symbol: "601398",
            name: "工商银行",
            quantity: 1000,
            averageCost: 4.5,
            currentPrice: 4.8,
            annualDividendPerShare: 0.3
        ))
    }
    .modelContainer(for: [Holding.self, GridTradingLevel.self], inMemory: true)
}
