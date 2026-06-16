//
//  StockUpdateService.swift
//  DividendTreasure
//
//  股票数据更新服务 - 批量更新持仓的股息率
//
//  注意：SwiftData 的 ModelContext / @Model 对象不是 Sendable，不能跨 actor 并发访问。
//  因此整个服务标记为 @MainActor，所有对 context / holding 的读写都在主线程完成。
//  网络请求通过 await 挂起（实际 IO 在 URLSession 后台线程），await 期间不会阻塞主线程。
//

import Foundation
import Combine
import SwiftData
import os

// MARK: - 更新状态

enum UpdateStatus {
    case idle
    case updating(progress: Double)
    case completed(updatedCount: Int)
    case failed(error: Error)

    var displayText: String {
        switch self {
        case .idle:
            return "准备更新"
        case .updating(let progress):
            return "更新中... \(Int(progress * 100))%"
        case .completed(let count):
            return "已更新 \(count) 个持仓"
        case .failed(let error):
            return "更新失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - 更新服务

@MainActor
class StockUpdateService: ObservableObject {
    static let shared = StockUpdateService()

    @Published var updateStatus: UpdateStatus = .idle
    @Published var lastUpdateTime: Date?

    private let userDefaults = UserDefaults.standard
    private let lastUpdateKey = "lastStockUpdateTime"
    private let updateInterval: TimeInterval = 86400 // 24小时

    private init() {
        loadLastUpdateTime()
    }

    // MARK: - 批量更新

    /// 批量更新所有持仓的股票数据
    func updateAllHoldings(in context: ModelContext) async {
        updateStatus = .updating(progress: 0)

        // 获取所有持仓（主线程安全访问 ModelContext）
        let descriptor = FetchDescriptor<Holding>()

        let holdings: [Holding]
        do {
            holdings = try context.fetch(descriptor)
        } catch {
            updateStatus = .failed(error: error)
            return
        }

        guard !holdings.isEmpty else {
            updateStatus = .completed(updatedCount: 0)
            return
        }

        // 在主线程读取每个持仓的 symbol/market 等只读字段，构建待更新任务列表。
        // 这样网络请求阶段不再触碰 @Model 对象，避免 await 跨越时的并发风险。
        let updateTasks: [(holding: Holding, marketCode: String)] = holdings.map { holding in
            (holding, getMarketCode(for: holding.market))
        }

        let total = updateTasks.count

        for (index, task) in updateTasks.enumerated() {
            await updateHoldingData(task.holding, marketCode: task.marketCode)

            updateStatus = .updating(progress: Double(index + 1) / Double(total))

            // 添加延迟，避免请求过快
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        }

        // 保存更新时间
        saveLastUpdateTime()

        updateStatus = .completed(updatedCount: total)
    }

    /// 更新单个持仓数据
    /// - 网络请求在后台进行（StockDataService 内部），await 期间不阻塞主线程；
    /// - 对 holding 的写入在主线程完成（本类为 @MainActor）。
    private func updateHoldingData(_ holding: Holding, marketCode: String) async {
        // 在主线程读取 symbol，避免持有对 @Model 的引用跨越 await
        let symbol = holding.symbol

        let stockData: StockData
        do {
            stockData = try await StockDataService.shared.fetchStockData(
                symbol: symbol,
                marketCode: marketCode
            )
        } catch {
            AppLogger.network.error("Failed to update holding \(symbol, privacy: .public): \(String(describing: error), privacy: .public)")
            return
        }

        // 更新持仓数据（主线程，安全）
        if stockData.currentPrice > 0 {
            holding.currentPrice = stockData.currentPrice
        }

        if stockData.latestDividend > 0 {
            holding.annualDividendPerShare = stockData.latestDividend
        }

        holding.updatedAt = Date()
    }

    /// 获取市场代码
    private func getMarketCode(for market: String) -> String {
        switch market {
        case "A股":
            return "1"
        case "港股":
            return "0"
        default:
            return "105" // 美股
        }
    }

    // MARK: - 定时更新

    /// 检查是否需要更新
    func needsUpdate() -> Bool {
        guard let lastUpdate = lastUpdateTime else {
            return true
        }

        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        return timeSinceUpdate > updateInterval
    }

    /// 如果需要则自动更新
    func updateIfNeeded(in context: ModelContext) async {
        if needsUpdate() {
            await updateAllHoldings(in: context)
        }
    }

    // MARK: - 持久化

    private func loadLastUpdateTime() {
        if let time = userDefaults.object(forKey: lastUpdateKey) as? Date {
            lastUpdateTime = time
        }
    }

    private func saveLastUpdateTime() {
        let now = Date()
        lastUpdateTime = now
        userDefaults.set(now, forKey: lastUpdateKey)
    }
}
