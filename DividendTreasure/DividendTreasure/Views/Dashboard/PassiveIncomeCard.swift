//
//  PassiveIncomeCard.swift
//  DividendTreasure
//
//  被动收入目标卡片 - 显示年度目标、预计收入、完成进度
//

import SwiftUI

struct PassiveIncomeCard: View {
    let targetAmount: Double
    let currentAmount: Double

    private var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    private var progressPercent: Int {
        Int(progress * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题行
            HStack {
                Label("今年被动收入", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(progressPercent)%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(progress >= 1.0 ? .green : .primary)
            }

            // 目标和实际金额
            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("年度目标")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatCompact(targetAmount))
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("预计股息")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatCompact(currentAmount))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景条
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    // 进度条
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .green.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 12)

            // 进度说明
            HStack {
                if progress >= 1.0 {
                    Label("已达成目标！", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("还需 \(CurrencyFormatter.formatCompact(targetAmount - currentAmount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(alignment: .topTrailing) {
            // 编辑提示
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(12)
        }
    }
}

// MARK: - 可点击版本（用于首页）

struct ClickablePassiveIncomeCard: View {
    let targetAmount: Double
    let currentAmount: Double

    private var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    private var progressPercent: Int {
        Int(progress * 100)
    }

    var body: some View {
        NavigationLink(destination: PassiveIncomeGoalView()) {
            VStack(alignment: .leading, spacing: 16) {
                // 标题行
                HStack {
                    Label("今年被动收入", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 8) {
                        Text("\(progressPercent)%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(progress >= 1.0 ? .green : .primary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // 目标和实际金额
                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("年度目标")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.formatCompact(targetAmount))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("预计股息")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.formatCompact(currentAmount))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                }

                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .green.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 12)
                            .animation(.spring(response: 0.5), value: progress)
                    }
                }
                .frame(height: 12)

                // 进度说明
                HStack {
                    if progress >= 1.0 {
                        Label("已达成目标！", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("还需 \(CurrencyFormatter.formatCompact(targetAmount - currentAmount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        // 目标进行中
        PassiveIncomeCard(
            targetAmount: 50000,
            currentAmount: 25000
        )

        // 目标达成
        PassiveIncomeCard(
            targetAmount: 50000,
            currentAmount: 52000
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
