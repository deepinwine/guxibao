//
//  PassiveIncomeGoalView.swift
//  DividendTreasure
//
//  被动收入目标设置页面 - 详细的生活支出配置
//

import SwiftUI

// MARK: - 支出项模型

struct ExpenseItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var amount: Double
    var isCustom: Bool

    init(id: UUID = UUID(), name: String, amount: Double = 0, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.amount = amount
        self.isCustom = isCustom
    }
}

struct PassiveIncomeGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("passiveIncomeCoveragePercent") private var coveragePercent: Double = 100 // 被动收入覆盖支出百分比
    @AppStorage("customExpenseItems") private var customExpenseItemsData: Data = Data() // 自定义支出项

    @State private var showCustomExpenseSheet = false
    @State private var customExpenseName = ""
    @State private var customExpenseAmount = ""

    // 基础支出项
    @AppStorage("expense_mortgage") private var expenseMortgage: Double = 0  // 房贷
    @AppStorage("expense_rent") private var expenseRent: Double = 0  // 房租
    @AppStorage("expense_food") private var expenseFood: Double = 0  // 餐饮
    @AppStorage("expense_transport") private var expenseTransport: Double = 0  // 交通
    @AppStorage("expense_utilities") private var expenseUtilities: Double = 0  // 水电燃气
    @AppStorage("expense_property") private var expenseProperty: Double = 0  // 物业费
    @AppStorage("expense_education") private var expenseEducation: Double = 0  // 教育培训
    @AppStorage("expense_shopping") private var expenseShopping: Double = 0  // 购物

    @State private var customExpenses: [ExpenseItem] = []
    @State private var manualGoalAmount: Double = 0
    @State private var useManualGoal = false

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 基本信息
                Section("基本信息") {
                    HStack {
                        Text("被动收入覆盖支出")
                        Spacer()
                        TextField("百分比", value: $coveragePercent, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - 生活支出项
                Section {
                    // 固定支出项
                    ExpenseRow(title: "房贷", icon: "house.fill", color: .blue, amount: $expenseMortgage)
                    ExpenseRow(title: "房租", icon: "building.2.fill", color: .purple, amount: $expenseRent)
                    ExpenseRow(title: "餐饮", icon: "fork.knife", color: .orange, amount: $expenseFood)
                    ExpenseRow(title: "交通", icon: "car.fill", color: .green, amount: $expenseTransport)
                    ExpenseRow(title: "水电燃气", icon: "bolt.fill", color: .yellow, amount: $expenseUtilities)
                    ExpenseRow(title: "物业费", icon: "building.columns.fill", color: .cyan, amount: $expenseProperty)
                    ExpenseRow(title: "教育培训", icon: "book.fill", color: .indigo, amount: $expenseEducation)
                    ExpenseRow(title: "购物", icon: "cart.fill", color: .pink, amount: $expenseShopping)

                    // 自定义支出项
                    ForEach(customExpenses) { expense in
                        HStack {
                            Label(expense.name, systemImage: "star.fill")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("金额", value: Binding(
                                get: { expense.amount },
                                set: { newValue in
                                    if let index = customExpenses.firstIndex(where: { $0.id == expense.id }) {
                                        customExpenses[index].amount = newValue
                                    }
                                }
                            ), format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("元/月")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .onDelete(perform: deleteCustomExpense)

                    // 添加自定义支出项
                    Button(action: { showCustomExpenseSheet = true }) {
                        Label("添加自定义支出项", systemImage: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                } header: {
                    Text("生活支出项")
                } footer: {
                    Text("单位：元/月")
                        .font(.caption)
                }

                // MARK: - 金额汇总
                Section("金额汇总") {
                    HStack {
                        Text("月度支出合计")
                            .fontWeight(.medium)
                        Spacer()
                        Text("¥\(totalMonthlyExpense, specifier: "%.2f")")
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }

                    HStack {
                        Text("年度目标总额")
                            .fontWeight(.medium)
                        Spacer()
                        Text("¥\(annualGoal, specifier: "%.2f")")
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                            .font(.title3)
                    }

                    Text("(月度支出 × 12 × \(Int(coveragePercent))%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - 手动调整
                Section {
                    Toggle("手动调整目标金额", isOn: $useManualGoal)

                    if useManualGoal {
                        HStack {
                            Text("自定义年度目标")
                            Spacer()
                            TextField("金额", value: $manualGoalAmount, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text("元")
                                .foregroundStyle(.secondary)
                        }

                        Text("手动调整将覆盖自动计算")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("高级选项")
                }

                // MARK: - 提示信息
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("可以自定义支出项名称", systemImage: "pencil.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label("也可以添加自定义支出项", systemImage: "plus.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label("填写每月生活支出，系统将自动计算年度目标", systemImage: "gearshape.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - 更新目标按钮
                Section {
                    Button(action: updateGoal) {
                        Text("更新目标")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .listRowBackground(Color.green)
                    .tint(.white)
                }
            }
            .navigationTitle("被动收入目标设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                loadCustomExpenses()
            }
            .sheet(isPresented: $showCustomExpenseSheet) {
                AddCustomExpenseSheet(
                    name: $customExpenseName,
                    amount: $customExpenseAmount,
                    onAdd: addCustomExpense
                )
            }
        }
    }

    // MARK: - 计算属性

    private var totalMonthlyExpense: Double {
        let base = expenseMortgage + expenseRent + expenseFood + expenseTransport +
                   expenseUtilities + expenseProperty + expenseEducation + expenseShopping
        let custom = customExpenses.reduce(0) { $0 + $1.amount }
        return base + custom
    }

    private var annualGoal: Double {
        if useManualGoal {
            return manualGoalAmount
        }
        return totalMonthlyExpense * 12 * (coveragePercent / 100.0)
    }

    // MARK: - 方法

    private func loadCustomExpenses() {
        if let decoded = try? JSONDecoder().decode([ExpenseItem].self, from: customExpenseItemsData) {
            customExpenses = decoded
        }
    }

    private func saveCustomExpenses() {
        if let encoded = try? JSONEncoder().encode(customExpenses) {
            customExpenseItemsData = encoded
        }
    }

    private func addCustomExpense() {
        guard !customExpenseName.isEmpty,
              let amount = Double(customExpenseAmount),
              amount > 0 else { return }

        customExpenses.append(ExpenseItem(name: customExpenseName, amount: amount, isCustom: true))
        saveCustomExpenses()

        customExpenseName = ""
        customExpenseAmount = ""
        showCustomExpenseSheet = false
    }

    private func deleteCustomExpense(offsets: IndexSet) {
        customExpenses.remove(atOffsets: offsets)
        saveCustomExpenses()
    }

    private func updateGoal() {
        // 保存年度目标到 AppStorage
        let userDefaults = UserDefaults.standard
        userDefaults.set(annualGoal, forKey: "annualPassiveIncomeGoal")

        // 保存所有基础支出项
        userDefaults.set(expenseMortgage, forKey: "expense_mortgage")
        userDefaults.set(expenseRent, forKey: "expense_rent")
        userDefaults.set(expenseFood, forKey: "expense_food")
        userDefaults.set(expenseTransport, forKey: "expense_transport")
        userDefaults.set(expenseUtilities, forKey: "expense_utilities")
        userDefaults.set(expenseProperty, forKey: "expense_property")
        userDefaults.set(expenseEducation, forKey: "expense_education")
        userDefaults.set(expenseShopping, forKey: "expense_shopping")

        dismiss()
    }
}

// MARK: - 支出行组件

struct ExpenseRow: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var amount: Double

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(color)
            Spacer()
            TextField("金额", value: $amount, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text("元/月")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}

// MARK: - 添加自定义支出项弹窗

struct AddCustomExpenseSheet: View {
    @Binding var name: String
    @Binding var amount: String
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("支出项名称") {
                    TextField("例如：医疗保健", text: $name)
                }

                Section("每月金额") {
                    TextField("金额", text: $amount)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("添加自定义支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        onAdd()
                        dismiss()
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}

#Preview {
    PassiveIncomeGoalView()
}
