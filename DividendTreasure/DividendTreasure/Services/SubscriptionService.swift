//
//  SubscriptionService.swift
//  DividendTreasure
//
//  订阅服务 - 管理免费版和订阅版功能
//

import Foundation
import StoreKit
import Combine
import os

// MARK: - 订阅类型

enum SubscriptionTier: String, CaseIterable {
    case free = "免费版"
    case monthly = "月度会员"
    case quarterly = "季度会员"
    case yearly = "年度会员"

    var price: String {
        switch self {
        case .free: return "免费"
        case .monthly: return "¥5/月"
        case .quarterly: return "¥12/季度"
        case .yearly: return "¥40/年"
        }
    }

    /// 折扣信息（相比月度订阅）
    var discount: String? {
        switch self {
        case .free, .monthly: return nil
        case .quarterly: return "省20%"
        case .yearly: return "省33%"
        }
    }

    /// 每月实际价格
    var monthlyEquivalent: String? {
        switch self {
        case .free, .monthly: return nil
        case .quarterly: return "¥4/月"
        case .yearly: return "¥3.3/月"
        }
    }

    var productID: String? {
        switch self {
        case .free: return nil
        case .monthly: return "com.yourcompany.dividendtreasure.monthly"
        case .quarterly: return "com.yourcompany.dividendtreasure.quarterly"
        case .yearly: return "com.yourcompany.dividendtreasure.yearly"
        }
    }
}

// MARK: - 订阅状态

enum SubscriptionStatus {
    case free
    case subscribed(SubscriptionTier)
    case expired

    var isActive: Bool {
        switch self {
        case .free: return false
        case .subscribed: return true
        case .expired: return false
        }
    }
}

// MARK: - 功能权限

struct FeaturePermissions {
    let maxPortfolios: Int
    let maxHoldingsPerPortfolio: Int
    let iCloudSync: Bool
    let unlimitedPortfolios: Bool
    let unlimitedHoldings: Bool
    let tradingExportImport: Bool
    let aiInsights: Bool
    let calendarView: Bool
    let gridTradingLevels: Int           // 档位数量限制
    let tradeRecords: Int                // 交易记录数量限制
    let strategyTemplates: Bool          // 策略模板权限
    let ocrRecognition: Bool             // 截图识别权限

    static func forTier(_ tier: SubscriptionTier) -> FeaturePermissions {
        switch tier {
        case .free:
            return FeaturePermissions(
                maxPortfolios: 1,
                maxHoldingsPerPortfolio: 5,
                iCloudSync: false,
                unlimitedPortfolios: false,
                unlimitedHoldings: false,
                tradingExportImport: false,
                aiInsights: false,
                calendarView: false,
                gridTradingLevels: 3,
                tradeRecords: 10,
                strategyTemplates: false,
                ocrRecognition: false
            )
        case .monthly, .quarterly, .yearly:
            return FeaturePermissions(
                maxPortfolios: .max,
                maxHoldingsPerPortfolio: .max,
                iCloudSync: true,
                unlimitedPortfolios: true,
                unlimitedHoldings: true,
                tradingExportImport: true,
                aiInsights: true,
                calendarView: true,
                gridTradingLevels: .max,
                tradeRecords: .max,
                strategyTemplates: true,
                ocrRecognition: true
            )
        }
    }
}

// MARK: - 订阅错误

enum SubscriptionError: Error, LocalizedError {
    case productNotFound
    case verificationFailed
    case purchasePending
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "订阅产品未配置"
        case .verificationFailed:
            return "交易验证失败"
        case .purchasePending:
            return "购买等待审批"
        case .unknown:
            return "未知错误"
        }
    }
}

// MARK: - 订阅服务

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var currentTier: SubscriptionTier = .free
    @Published var status: SubscriptionStatus = .free
    @Published var permissions: FeaturePermissions = .forTier(.free)
    @Published var lastError: String?

    private var products: [Product] = []
    private var updateTask: Task<Void, Never>?

    /// 是否已加载产品
    var hasLoadedProducts: Bool {
        !products.isEmpty
    }

    private init() {
        loadProducts()
        checkSubscriptionStatus()
    }

    // MARK: - 产品加载

    func loadProducts() {
        Task {
            let productIDs = Set(SubscriptionTier.allCases.compactMap { $0.productID })

            do {
                let storeProducts = try await Product.products(for: productIDs)
                products = Array(storeProducts)
                if products.isEmpty {
                    AppLogger.subscription.warning("⚠️ No products loaded. Check StoreKit configuration.")
                } else {
                    AppLogger.subscription.info("✅ Loaded \(self.products.count) products")
                }
            } catch {
                AppLogger.subscription.error("❌ Failed to load products: \(String(describing: error), privacy: .public)")
                lastError = "无法加载订阅产品"
            }
        }
    }

    // MARK: - 订阅状态检查

    func checkSubscriptionStatus() {
        Task {
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if let tier = getTierFromProductID(transaction.productID) {
                        currentTier = tier
                        status = .subscribed(tier)
                        permissions = FeaturePermissions.forTier(tier)
                    }
                case .unverified:
                    continue
                }
            }
        }
    }

    private func getTierFromProductID(_ productID: String) -> SubscriptionTier? {
        SubscriptionTier.allCases.first { $0.productID == productID }
    }

    // MARK: - 购买订阅

    func purchase(_ tier: SubscriptionTier) async throws -> Bool {
        // 检查产品是否已加载
        guard let productID = tier.productID,
              let product = products.first(where: { $0.id == productID }) else {
            lastError = "订阅产品未配置，请在 App Store Connect 中添加产品"
            throw SubscriptionError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                currentTier = tier
                status = .subscribed(tier)
                permissions = FeaturePermissions.forTier(tier)
                await transaction.finish()
                lastError = nil
                return true
            case .unverified:
                lastError = "交易验证失败"
                throw SubscriptionError.verificationFailed
            }
        case .userCancelled:
            lastError = nil  // 用户取消不算错误
            return false
        case .pending:
            lastError = "购买等待审批"
            throw SubscriptionError.purchasePending
        @unknown default:
            lastError = "未知购买结果"
            throw SubscriptionError.unknown
        }
    }

    /// 模拟订阅成功（仅用于开发测试）
    func simulateSubscription(_ tier: SubscriptionTier) {
        currentTier = tier
        status = .subscribed(tier)
        permissions = FeaturePermissions.forTier(tier)
        lastError = nil
        AppLogger.subscription.info("✅ Simulated subscription: \(tier.rawValue, privacy: .public)")
    }

    // MARK: - 恢复购买

    func restorePurchases() async throws {
        try await AppStore.sync()
        checkSubscriptionStatus()
    }

    // MARK: - 权限检查

    func canAddPortfolio(currentCount: Int) -> Bool {
        if permissions.unlimitedPortfolios { return true }
        return currentCount < permissions.maxPortfolios
    }

    func canAddHolding(currentCount: Int) -> Bool {
        if permissions.unlimitedHoldings { return true }
        return currentCount < permissions.maxHoldingsPerPortfolio
    }

    // MARK: - 网格交易权限检查

    func canAddGridLevel(currentCount: Int) -> Bool {
        if permissions.gridTradingLevels == .max { return true }
        return currentCount < permissions.gridTradingLevels
    }

    func canAddTradeRecord(currentCount: Int) -> Bool {
        if permissions.tradeRecords == .max { return true }
        return currentCount < permissions.tradeRecords
    }

    func canUseStrategyTemplates() -> Bool {
        permissions.strategyTemplates
    }

    func canUseOCRRecognition() -> Bool {
        permissions.ocrRecognition
    }

    // MARK: - 产品信息

    func getProduct(for tier: SubscriptionTier) -> Product? {
        guard let productID = tier.productID else { return nil }
        return products.first { $0.id == productID }
    }
}
