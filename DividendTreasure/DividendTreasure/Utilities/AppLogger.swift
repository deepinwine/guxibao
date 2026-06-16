//
//  AppLogger.swift
//  DividendTreasure
//
//  统一的日志工具，基于 os.Logger。
//  发布版（Release）下 os.Logger 默认不输出 debug 级别日志到 stdout，
//  可通过 Console.app 或 Xcode 按 subsystem "com.guxibao.DividendTreasure" 过滤查看。
//

import Foundation
import os

enum AppLogger {
    /// 统一 subsystem，便于在 Console.app / Xcode 中过滤
    private static let subsystem = "com.guxibao.DividendTreasure"

    static let network = Logger(subsystem: subsystem, category: "network")
    static let ocr = Logger(subsystem: subsystem, category: "ocr")
    static let data = Logger(subsystem: subsystem, category: "data")
    static let notification = Logger(subsystem: subsystem, category: "notification")
    static let subscription = Logger(subsystem: subsystem, category: "subscription")
    static let general = Logger(subsystem: subsystem, category: "general")
}
