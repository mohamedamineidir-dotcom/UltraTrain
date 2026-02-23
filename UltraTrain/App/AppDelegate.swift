import UIKit
import os

final class AppDelegate: NSObject, UIApplicationDelegate {

    var onDeviceTokenReceived: ((String) -> Void)?

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Logger.notification.info("APNs device token received")
        onDeviceTokenReceived?(token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.notification.error("Failed to register for remote notifications: \(error)")
    }
}
