//
//  DataExportView.swift
//  DividendTreasure
//
//  数据导出页面 - 导出持仓数据
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataExportView: View {
    @Query private var portfolios: [Portfolio]
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingUpgradePrompt = false

    var body: some View {
        List {
            Section {
                if !subscriptionService.permissions.tradingExportImport {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.orange)
                        Text("会员功能")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("升级") {
                            showingUpgradePrompt = true
                        }
                    }
                }
            }

            Section("导出持仓数据") {
                Button(action: { exportToCSV() }) {
                    Label("导出为CSV", systemImage: "doc.text")
                }
                .disabled(!subscriptionService.permissions.tradingExportImport)

                Button(action: { exportToJSON() }) {
                    Label("导出为JSON", systemImage: "doc.badge.plus")
                }
                .disabled(!subscriptionService.permissions.tradingExportImport)
            }

            Section("导入数据") {
                NavigationLink("从文件导入持仓") {
                    DataImportView()
                }
                .disabled(!subscriptionService.permissions.tradingExportImport)
            }
        }
        .navigationTitle("数据导入导出")
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .alert("升级到会员版", isPresented: $showingUpgradePrompt) {
            Button("取消", role: .cancel) { }
            Button("查看订阅") { }
        } message: {
            Text("数据导入导出功能需要订阅会员版")
        }
    }

    private var allHoldings: [Holding] {
        portfolios.flatMap { $0.holdings }
    }

    private func exportToCSV() {
        guard subscriptionService.permissions.tradingExportImport else {
            showingUpgradePrompt = true
            return
        }

        if let url = DataExportService.exportHoldingsToCSV(allHoldings) {
            exportURL = url
            showingShareSheet = true
        }
    }

    private func exportToJSON() {
        guard subscriptionService.permissions.tradingExportImport else {
            showingUpgradePrompt = true
            return
        }

        if let url = DataExportService.exportHoldingsToJSON(allHoldings) {
            exportURL = url
            showingShareSheet = true
        }
    }
}

// MARK: - 数据导入视图

struct DataImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Portfolio.createdAt, order: .reverse) private var portfolios: [Portfolio]
    @State private var showingFilePicker = false
    @State private var showingSuccess = false
    @State private var importedCount = 0

    var body: some View {
        VStack(spacing: 20) {
            ContentUnavailableView(
                "导入持仓数据",
                systemImage: "square.and.arrow.down",
                description: Text("支持从JSON文件导入持仓数据")
            )

            Button("选择文件") {
                showingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importData(from: url)
                }
            case .failure(let error):
                print("Failed to import: \(error)")
            }
        }
        .alert("导入成功", isPresented: $showingSuccess) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("已成功导入 \(importedCount) 个持仓")
        }
    }

    private func importData(from url: URL) {
        guard let portfolio = portfolios.first else { return }

        let count = DataExportService.importHoldingsFromJSON(from: url, to: portfolio, in: modelContext)
        importedCount = count
        showingSuccess = true
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        DataExportView()
    }
}
