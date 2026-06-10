//
//  DividendTreasureApp.swift
//  DividendTreasure
//
//  App 入口文件
//

import SwiftUI
import SwiftData

@main
struct DividendTreasureApp: App {
    let container: ModelContainer

    init() {
        // 定义数据模型 Schema
        let schema = Schema([
            Portfolio.self,
            Holding.self,
            DividendRecord.self,
            WatchlistItem.self,
            ImportBatch.self,
            ImportCandidate.self,
        ])

        // 配置 CloudKit/iCloud 同步
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier("iCloud.com.yourcompany.dividendtreasure"),
            cloudKitDatabase: .automatic
        )

        do {
            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .onAppear {
                    // 首次启动时插入 Mock 数据（仅用于开发测试）
                    setupMockDataIfNeeded()
                }
        }
        .modelContainer(container)
    }

    private func setupMockDataIfNeeded() {
        let context = container.mainContext
        let portfolioDescriptor = FetchDescriptor<Portfolio>()

        do {
            let portfolios = try context.fetch(portfolioDescriptor)
            if portfolios.isEmpty {
                // 仅在数据库为空时插入 Mock 数据
                MockDataService.createSampleData(in: context)
            }
        } catch {
            print("Failed to check portfolios: \(error)")
        }
    }
}
