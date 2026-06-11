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

                // 开发测试提示
                #if DEBUG
                DevTestSection()
                #endif

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
        .onDisappear {
            subscriptionService.lastError = nil
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
                    isPurchasing: $isPurchasing
                )

                SubscriptionOptionRow(
                    tier: .quarterly,
                    isPurchasing: $isPurchasing
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2)
                )

                SubscriptionOptionRow(
                    tier: .yearly,
                    isPurchasing: $isPurchasing
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2)
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
    @Binding var isPurchasing: Bool

    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        Button(action: { purchase() }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tier.rawValue)
                            .font(.headline)

                        if let discount = tier.discount {
                            Text(discount)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .cornerRadius(4)
                        }
                    }

                    if let monthly = tier.monthlyEquivalent {
                        Text("相当于\(monthly)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(tier.price)
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
                let success = try await subscriptionService.purchase(tier)
                if !success && subscriptionService.lastError != nil {
                    // 显示错误（用户取消不显示）
                }
            } catch {
                print("Purchase failed: \(error)")
            }
            isPurchasing = false
        }
    }
}

// MARK: - 开发测试区域

struct DevTestSection: View {
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🧪 开发测试")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("StoreKit 产品未配置，点击下方按钮模拟订阅成功")
                .font(.caption)
                .foregroundStyle(.orange)

            HStack(spacing: 12) {
                devTestButton(tier: .monthly)
                devTestButton(tier: .quarterly)
                devTestButton(tier: .yearly)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private func devTestButton(tier: SubscriptionTier) -> some View {
        Button {
            subscriptionService.simulateSubscription(tier)
        } label: {
            Text(tier.rawValue)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .foregroundStyle(.orange)
                .cornerRadius(8)
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
