//
//  SettingsView.swift
//  DividendTreasure
//
//  设置视图
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("annualPassiveIncomeGoal") private var annualPassiveIncomeGoal: Double = 50000
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "CNY"

    var body: some View {
        NavigationStack {
            List {
                Section("年度目标") {
                    HStack {
                        Text("被动收入目标")
                        Spacer()
                        TextField("目标", value: $annualPassiveIncomeGoal, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("元")
                    }
                }

                Section("偏好设置") {
                    Picker("默认货币", selection: $defaultCurrency) {
                        Text("人民币 (CNY)").tag("CNY")
                        Text("美元 (USD)").tag("USD")
                        Text("港币 (HKD)").tag("HKD")
                    }
                }

                Section {
                    NavigationLink("免责声明") {
                        DisclaimerView()
                    }

                    HStack {
                        Text("iCloud 同步")
                        Spacer()
                        Text("自动")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}

// MARK: - 免责声明视图

struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("免责声明")
                    .font(.title)
                    .fontWeight(.bold)

                Text("""
                本应用仅为个人财务数据管理工具，不构成任何投资建议。

                1. 本应用不提供证券投资咨询、投资建议或推荐任何证券产品。

                2. 应用内的所有数据均由用户自行录入，应用不对数据的准确性、完整性做任何保证。

                3. 股息数据、价格数据仅供参考，实际情况请以券商或官方数据为准。

                4. 投资有风险，入市需谨慎。用户应根据自身情况独立做出投资决策。

                5. 本应用不会接入任何券商账户，不会执行任何交易操作。

                6. 用户数据通过 iCloud 同步，数据安全由 Apple iCloud 服务保障。
                """)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("免责声明")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
