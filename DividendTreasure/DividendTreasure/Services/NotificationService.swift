//
//  NotificationService.swift
//  DividendTreasure
//
//  本地通知服务 - 当股息率达到目标时触发提醒
//

import Foundation
import UserNotifications
import Combine

// MARK: - 通知类型

enum DividendAlertType: String {
    case buy = "买入提醒"
    case sell = "卖出提醒"
}

// MARK: - 通知服务

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private override init() {
        super.init()
        checkAuthorization()
    }

    // MARK: - 权限管理

    /// 检查通知权限
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// 请求通知权限
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("Notification authorization error: \(error)")
                }
            }
        }
    }

    // MARK: - 发送通知

    /// 发送股息率提醒通知
    func sendDividendAlert(
        for symbol: String,
        name: String,
        type: DividendAlertType,
        currentPrice: Double,
        targetYield: Double
    ) {
        guard isAuthorized else {
            print("Notification not authorized")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "\(type.rawValue): \(name)"
        content.body = "\(symbol) 当前股息率已达到 \(PercentFormatter.format(targetYield))，当前价格: \(CurrencyFormatter.formatPrice(currentPrice))"
        content.sound = .default
        content.badge = 1

        // 立即触发
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // 创建请求
        let request = UNNotificationRequest(
            identifier: "\(symbol)_\(type.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    /// 发送价格达到提醒
    func sendPriceAlert(
        for symbol: String,
        name: String,
        currentPrice: Double,
        targetPrice: Double,
        isBuy: Bool
    ) {
        guard isAuthorized else {
            print("Notification not authorized")
            return
        }

        let content = UNMutableNotificationContent()
        let action = isBuy ? "买入" : "卖出"
        content.title = "\(action)提醒: \(name)"
        content.body = "\(symbol) 当前价格 \(CurrencyFormatter.formatPrice(currentPrice))，目标\(action)价 \(CurrencyFormatter.formatPrice(targetPrice))"
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(symbol)_price_alert_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    // MARK: - 取消通知

    /// 取消所有通知
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    /// 取消特定通知
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}

// MARK: - AppDelegate 支持

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 在前台也显示通知
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 用户点击通知后的处理
        completionHandler()
    }
}
