//
//  StockUpdateService.swift
//  DividendTreasure
//
//  股票数据更新服务 - 批量更新持仓的股息率
//

import Foundation
import Combine
import SwiftData

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
        await MainActor.run {
            updateStatus = .updating(progress: 0)
        }

        // 获取所有持仓
        let descriptor = FetchDescriptor<Holding>()

        do {
            let holdings = try context.fetch(descriptor)

            guard !holdings.isEmpty else {
                await MainActor.run {
                    updateStatus = .completed(updatedCount: 0)
                }
                return
            }

            var updatedCount = 0
            let total = holdings.count

            for (index, holding) in holdings.enumerated() {
                // 更新单个持仓
                await updateHoldingData(holding)

                updatedCount += 1

                // 更新进度
                let progress = Double(index + 1) / Double(total)
                await MainActor.run {
                    updateStatus = .updating(progress: progress)
                }

                // 添加延迟，避免请求过快
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            }

            // 保存更新时间
            saveLastUpdateTime()

            await MainActor.run {
                updateStatus = .completed(updatedCount: updatedCount)
            }

        } catch {
            await MainActor.run {
                updateStatus = .failed(error: error)
            }
        }
    }

    /// 更新单个持仓数据
    private func updateHoldingData(_ holding: Holding) async {
        let marketCode = getMarketCode(for: holding.market)

        do {
            let stockData = try await StockDataService.shared.fetchStockData(
                symbol: holding.symbol,
                marketCode: marketCode
            )

            await MainActor.run {
                // 更新持仓数据
                if stockData.currentPrice > 0 {
                    holding.currentPrice = stockData.currentPrice
                }

                if stockData.latestDividend > 0 {
                    holding.annualDividendPerShare = stockData.latestDividend
                }

                holding.updatedAt = Date()
            }

        } catch {
            print("Failed to update holding \(holding.symbol): \(error)")
        }
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
