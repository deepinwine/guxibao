//
//  ImportNoticeView.swift
//  DividendTreasure
//
//  导入资产注意事项页面 - 在导入前显示给用户
//

import SwiftUI

struct ImportNoticeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasReadNotice = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("导入资产注意事项")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    // 主要说明
                    VStack(alignment: .leading, spacing: 16) {
                        Text("为提高识别准确率，请使用券商 App 的持仓列表页面截图。截图中应尽量包含以下信息：")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // 需要包含的信息列表
                        VStack(alignment: .leading, spacing: 12) {
                            NoticeItem(number: 1, text: "品种代码", icon: "1.circle.fill")
                            NoticeItem(number: 2, text: "品种名称", icon: "2.circle.fill")
                            NoticeItem(number: 3, text: "持仓数量", icon: "3.circle.fill")
                            NoticeItem(number: 4, text: "当前价格或当前市值（如有）", icon: "4.circle.fill")
                            NoticeItem(number: 5, text: "成本价（如有）", icon: "5.circle.fill")
                        }
                        .padding(.vertical, 8)

                        Divider()

                        // 建议
                        VStack(alignment: .leading, spacing: 12) {
                            Label("建议使用清晰、完整、无遮挡的截图", systemImage: "checkmark.circle")
                                .font(.subheadline)
                                .foregroundStyle(.green)

                            VStack(alignment: .leading, spacing: 8) {
                                Label("请避免使用：", systemImage: "xmark.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("• 暗色模糊截图")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("• 裁剪过多的截图")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("• 聊天转发截图")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("• 包含大量无关内容的截图")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.leading, 20)
                            }
                        }

                        Divider()

                        // 重要提示
                        VStack(alignment: .leading, spacing: 8) {
                            Label("识别结果仅作为辅助录入", systemImage: "exclamationmark.triangle")
                                .font(.subheadline)
                                .foregroundStyle(.orange)

                            Text("导入前请自行核对识别结果，确保数据准确无误。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                        Divider()

                        // 确认阅读
                        Toggle(isOn: $hasReadNotice) {
                            Text("我已阅读并理解以上注意事项")
                                .font(.subheadline)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("注意事项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("开始导入") {
                        dismiss()
                    }
                    .disabled(!hasReadNotice)
                }
            }
        }
    }
}

// MARK: - 注意事项项

struct NoticeItem: View {
    let number: Int
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}

#Preview {
    ImportNoticeView()
}