//
//  SubscriptionView.swift
//  DividendTreasure
//
//  订阅管理页面 - 显示免费版限制、订阅价格、购买按钮
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 当前状态
                CurrentSubscriptionCard()

                // 免费版限制
                FreeVersionLimitCard()

                // 订阅选项
                SubscriptionOptionsCard(isPurchasing: $isPurchasing)

                // 恢复购买
                RestorePurchaseButton()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("订阅管理")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isPurchasing)
        .overlay {
            if isPurchasing {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("处理中...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
        }
        .alert("购买失败", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - 当前订阅卡片

struct CurrentSubscriptionCard: View {
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前订阅")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionService.currentTier.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)

                    if subscriptionService.status.isActive {
                        Text("已激活")
                            .font(.caption)
                            .padding(4)
                            .background(.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .cornerRadius(4)
                    } else {
                        Text("未激活")
                            .font(.caption)
                            .padding(4)
                            .background(.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                Image(systemName: subscriptionService.status.isActive ? "checkmark.seal.fill" : "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundStyle(subscriptionService.status.isActive ? .green : .orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 免费版限制卡片

struct FreeVersionLimitCard: View {
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("免费版限制")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                LimitRow(title: "投资组合", limit: "最多1个", isPro: subscriptionService.status.isActive)
                LimitRow(title: "持仓数量", limit: "每个组合最多5个", isPro: subscriptionService.status.isActive)
                LimitRow(title: "iCloud同步", limit: "不支持", isPro: subscriptionService.status.isActive)
                LimitRow(title: "交易导入导出", limit: "不支持", isPro: subscriptionService.status.isActive)
                LimitRow(title: "AI智能洞察", limit: "不支持", isPro: subscriptionService.status.isActive)
                LimitRow(title: "日历视图", limit: "不支持", isPro: subscriptionService.status.isActive)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct LimitRow: View {
    let title: String
    let limit: String
    let isPro: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(limit)
                .font(.caption)
                .foregroundStyle(isPro ? .green : .secondary)
            Image(systemName: isPro ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(isPro ? .green : .red)
                .font(.caption)
        }
    }
}

// MARK: - 订阅选项卡片

struct SubscriptionOptionsCard: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Binding var isPurchasing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("订阅会员版")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("解锁全部功能")
                .font(.caption)
                .foregroundStyle(.green)

            VStack(spacing: 12) {
                SubscriptionOptionRow(
                    tier: .monthly,
                    price: "¥5/月",
                    description: "适合短期试用",
                    isPurchasing: $isPurchasing
                )

                SubscriptionOptionRow(
                    tier: .quarterly,
                    price: "¥10/季度",
                    description: "推荐选择",
                    isPurchasing: $isPurchasing
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 2)
                )

                SubscriptionOptionRow(
                    tier: .yearly,
                    price: "¥30/年",
                    description: "最划算",
                    isPurchasing: $isPurchasing
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct SubscriptionOptionRow: View {
    let tier: SubscriptionTier
    let price: String
    let description: String
    @Binding var isPurchasing: Bool

    var body: some View {
        Button(action: { purchase() }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.rawValue)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(price)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func purchase() {
        Task {
            isPurchasing = true
            do {
                _ = try await SubscriptionService.shared.purchase(tier)
            } catch {
                print("Purchase failed: \(error)")
            }
            isPurchasing = false
        }
    }
}

// MARK: - 恢复购买按钮

struct RestorePurchaseButton: View {
    var body: some View {
        Button(action: {
            Task {
                try? await SubscriptionService.shared.restorePurchases()
            }
        }) {
            Text("恢复购买")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionView()
    }
}
