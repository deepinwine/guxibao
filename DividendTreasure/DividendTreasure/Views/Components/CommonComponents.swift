//
//  CommonComponents.swift
//  DividendTreasure
//
//  通用UI组件 - 空状态、错误提示、加载状态等
//

import SwiftUI

// MARK: - 空状态组件

struct EmptyStateView: View {
    let title: String
    let icon: String
    let description: String?
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        icon: String = "tray",
        description: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            if let description = description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

// MARK: - 错误提示组件

struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?

    init(
        title: String = "出错了",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Label("重试", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

// MARK: - 加载状态组件

struct LoadingView: View {
    let message: String

    init(message: String = "加载中...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}

// MARK: - 卡片容器组件

struct CardContainer<Content: View>: View {
    let title: String?
    let icon: String?
    let content: Content

    init(
        title: String? = nil,
        icon: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundStyle(.secondary)
                    }
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 分段标题组件

struct SectionHeader: View {
    let title: String
    let icon: String?

    init(title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 数字卡片组件

struct NumberCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Trend?

    enum Trend {
        case up
        case down
        case neutral
    }

    init(
        title: String,
        value: String,
        icon: String,
        color: Color,
        trend: Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)

                if let trend = trend {
                    Image(systemName: trendIcon(for: trend))
                        .font(.caption)
                        .foregroundStyle(trendColor(for: trend))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    private func trendIcon(for trend: Trend) -> String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }

    private func trendColor(for trend: Trend) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .neutral: return .secondary
        }
    }
}

// MARK: - 分隔线组件

struct DividerView: View {
    var body: some View {
        Rectangle()
            .fill(Color(.systemGray4))
            .frame(height: 1)
    }
}

// MARK: - 预览

#Preview("空状态") {
    EmptyStateView(
        title: "暂无数据",
        icon: "tray",
        description: "点击下方按钮添加数据",
        actionTitle: "添加数据",
        action: { print("Action triggered") }
    )
}

#Preview("错误提示") {
    ErrorView(
        message: "网络连接失败，请检查网络设置",
        retryAction: { print("Retry") }
    )
}

#Preview("加载状态") {
    LoadingView(message: "正在加载数据...")
}

#Preview("数字卡片") {
    VStack(spacing: 20) {
        NumberCard(
            title: "总市值",
            value: "¥12.58万",
            icon: "dollarsign.circle.fill",
            color: .blue,
            trend: .up
        )

        NumberCard(
            title: "年度股息",
            value: "¥6,500",
            icon: "arrow.down.circle.fill",
            color: .green
        )
    }
    .padding()
}