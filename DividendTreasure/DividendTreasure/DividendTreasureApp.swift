//
//  DividendTreasureApp.swift
//  DividendTreasure
//
//  App 入口文件 - 配置 SwiftData（暂时禁用 CloudKit）
//

import SwiftUI
import SwiftData

@main
struct DividendTreasureApp: App {
    let sharedModelContainer: ModelContainer

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

        // 配置 SwiftData（暂时仅使用本地存储）
        // TODO: 后续阶段配置 CloudKit
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
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
        .modelContainer(sharedModelContainer)
    }

    private func setupMockDataIfNeeded() {
        let context = sharedModelContainer.mainContext
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