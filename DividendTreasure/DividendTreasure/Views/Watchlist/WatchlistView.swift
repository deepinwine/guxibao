//
//  WatchlistView.swift
//  DividendTreasure
//
//  我的收藏页面 - 收藏股票并设置股息率价格提醒
//

import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WatchlistItem.createdAt, order: .reverse) private var watchlistItems: [WatchlistItem]
    @State private var showingAddItem = false
    @State private var showingNotificationSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if watchlistItems.isEmpty {
                    ContentUnavailableView(
                        "暂无收藏",
                        systemImage: "star",
                        description: Text("点击右上角 + 添加收藏股票")
                    )
                } else {
                    List {
                        ForEach(watchlistItems) { item in
                            NavigationLink(destination: WatchlistDetailView(item: item)) {
                                WatchlistItemRow(item: item)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("我的收藏")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                WatchlistFormView()
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
        }
        .onAppear {
            // 检查通知权限
            NotificationService.shared.checkAuthorization()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(watchlistItems[index])
            }
        }
    }
}

// MARK: - 收藏行视图

struct WatchlistItemRow: View {
    let item: WatchlistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.symbol)
                        .font(.headline)
                    Text(item.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 提醒状态
                if item.alertEnabled {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            // 价格和股息率信息
            HStack(spacing: 16) {
                // 当前价格
                VStack(alignment: .leading, spacing: 2) {
                    Text("现价")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(CurrencyFormatter.formatPrice(item.currentPrice))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                // 当前股息率
                VStack(alignment: .leading, spacing: 2) {
                    Text("股息率")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(PercentFormatter.format(item.currentYield))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }

                Spacer()

                // 目标价格
                VStack(alignment: .trailing, spacing: 2) {
                    Text("目标买入")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(CurrencyFormatter.formatPrice(item.targetBuyPrice))
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }

            // 提醒状态指示
            if item.alertEnabled {
                HStack(spacing: 8) {
                    if item.shouldAlertBuy {
                        Text("建议买入")
                            .font(.caption2)
                            .padding(4)
                            .background(.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .cornerRadius(4)
                    }

                    if item.shouldAlertSell {
                        Text("建议卖出")
                            .font(.caption2)
                            .padding(4)
                            .background(.red.opacity(0.2))
                            .foregroundStyle(.red)
                            .cornerRadius(4)
                    }

                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 收藏表单视图

struct WatchlistFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var symbol = ""
    @State private var name = ""
    @State private var market = "A股"
    @State private var currentPrice = ""
    @State private var annualDividendPerShare = ""
    @State private var targetBuyYield = ""
    @State private var targetSellYield = ""
    @State private var alertEnabled = false
    @State private var note = ""

    @State private var showStockSearch = false

    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section("基本信息") {
                    Button(action: { showStockSearch = true }) {
                        HStack {
                            Label("搜索股票", systemImage: "magnifyingglass")
                                .foregroundStyle(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    TextField("股票代码", text: $symbol)
                    TextField("股票名称", text: $name)

                    Picker("市场", selection: $market) {
                        Text("A股").tag("A股")
                        Text("港股").tag("港股")
                        Text("美股").tag("美股")
                    }
                }

                // 价格和股息信息
                Section("价格和股息") {
                    TextField("当前价格", text: $currentPrice)
                        .keyboardType(.decimalPad)

                    TextField("年度每股股息", text: $annualDividendPerShare)
                        .keyboardType(.decimalPad)
                }

                // 目标股息率
                Section("目标股息率（小数形式，如0.06表示6%）") {
                    TextField("目标买入股息率", text: $targetBuyYield)
                        .keyboardType(.decimalPad)

                    TextField("目标卖出股息率", text: $targetSellYield)
                        .keyboardType(.decimalPad)

                    Toggle("启用提醒", isOn: $alertEnabled)
                }

                // 备注
                Section("备注") {
                    TextEditor(text: $note)
                        .frame(height: 60)
                }

                // 计算预览
                if let price = Double(currentPrice),
                   let dividend = Double(annualDividendPerShare),
                   price > 0 {
                    Section("计算预览") {
                        HStack {
                            Text("当前股息率")
                            Spacer()
                            Text(PercentFormatter.format(dividend / price))
                                .foregroundStyle(.orange)
                        }

                        if let buyYield = Double(targetBuyYield), buyYield > 0 {
                            HStack {
                                Text("目标买入价")
                                Spacer()
                                Text(CurrencyFormatter.formatPrice(dividend / buyYield))
                                    .foregroundStyle(.green)
                            }
                        }

                        if let sellYield = Double(targetSellYield), sellYield > 0 {
                            HStack {
                                Text("目标卖出价")
                                Spacer()
                                Text(CurrencyFormatter.formatPrice(dividend / sellYield))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("添加收藏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveWatchlistItem()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showStockSearch) {
                StockSearchView { result, stockData in
                    symbol = result.symbol
                    name = result.name
                    market = result.market

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

    private var isValid: Bool {
        !symbol.isEmpty && !name.isEmpty
    }

    private func saveWatchlistItem() {
        let item = WatchlistItem(
            symbol: symbol,
            name: name,
            market: market,
            currentPrice: Double(currentPrice) ?? 0,
            annualDividendPerShare: Double(annualDividendPerShare) ?? 0,
            targetBuyYield: Double(targetBuyYield) ?? 0,
            targetSellYield: Double(targetSellYield) ?? 0,
            alertEnabled: alertEnabled,
            note: note
        )

        modelContext.insert(item)
        dismiss()
    }
}

// MARK: - 收藏详情视图

struct WatchlistDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var item: WatchlistItem

    @State private var isEditing = false
    @State private var showingDeleteConfirm = false

    var body: some View {
        List {
            // 基本信息
            Section("基本信息") {
                LabeledContent("代码", value: item.symbol)
                LabeledContent("名称", value: item.name)
                LabeledContent("市场", value: item.market)
            }

            // 价格信息
            Section("价格信息") {
                LabeledContent("当前价格") {
                    Text(CurrencyFormatter.formatPrice(item.currentPrice))
                }

                LabeledContent("年度每股股息") {
                    Text(String(format: "%.4f", item.annualDividendPerShare))
                }

                LabeledContent("当前股息率") {
                    Text(PercentFormatter.format(item.currentYield))
                        .foregroundStyle(.orange)
                        .fontWeight(.semibold)
                }
            }

            // 目标价格
            Section("目标价格") {
                if item.targetBuyYield > 0 {
                    LabeledContent("目标买入股息率") {
                        Text(PercentFormatter.format(item.targetBuyYield))
                    }

                    LabeledContent("目标买入价") {
                        Text(CurrencyFormatter.formatPrice(item.targetBuyPrice))
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                }

                if item.targetSellYield > 0 {
                    LabeledContent("目标卖出股息率") {
                        Text(PercentFormatter.format(item.targetSellYield))
                    }

                    LabeledContent("目标卖出价") {
                        Text(CurrencyFormatter.formatPrice(item.targetSellPrice))
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                    }
                }
            }

            // 提醒设置
            Section("提醒设置") {
                Toggle("启用提醒", isOn: $item.alertEnabled)

                if item.alertEnabled {
                    if item.shouldAlertBuy {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("已达到买入条件")
                                .foregroundStyle(.green)
                        }
                    }

                    if item.shouldAlertSell {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("已达到卖出条件")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            // 备注
            if !item.note.isEmpty {
                Section("备注") {
                    Text(item.note)
                }
            }

            // 操作
            Section {
                Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                    HStack {
                        Spacer()
                        Text("删除收藏")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("确认删除", isPresented: $showingDeleteConfirm) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                modelContext.delete(item)
                dismiss()
            }
        } message: {
            Text("确定要删除收藏 \(item.name) 吗？")
        }
        .onChange(of: item.currentPrice) { _, _ in
            checkAndSendAlert()
        }
    }

    private func checkAndSendAlert() {
        guard item.alertEnabled else { return }

        if item.shouldAlertBuy {
            NotificationService.shared.sendPriceAlert(
                for: item.symbol,
                name: item.name,
                currentPrice: item.currentPrice,
                targetPrice: item.targetBuyPrice,
                isBuy: true
            )
        }

        if item.shouldAlertSell {
            NotificationService.shared.sendPriceAlert(
                for: item.symbol,
                name: item.name,
                currentPrice: item.currentPrice,
                targetPrice: item.targetSellPrice,
                isBuy: false
            )
        }
    }
}

// MARK: - 通知设置视图

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if NotificationService.shared.isAuthorized {
                        Label("通知权限已开启", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button(action: {
                            NotificationService.shared.requestAuthorization()
                        }) {
                            Label("开启通知权限", systemImage: "bell.badge")
                        }
                    }
                } header: {
                    Text("通知权限")
                } footer: {
                    Text("开启通知后，当股息率达到目标时会收到提醒")
                }
            }
            .navigationTitle("通知设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    WatchlistView()
        .modelContainer(for: WatchlistItem.self, inMemory: true)
}
