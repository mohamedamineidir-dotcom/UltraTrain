import Foundation
import UserNotifications
import os

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    var deepLinkRouter: DeepLinkRouter?

    // MARK: - Notification Response

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionId = response.actionIdentifier
        let category = response.notification.request.content.categoryIdentifier

        guard actionId != UNNotificationDismissActionIdentifier else { return }

        if actionId == UNNotificationDefaultActionIdentifier {
            await handleDefaultTap(category: category)
            return
        }

        await handleAction(actionId)
        Logger.notification.info("Handled notification action: \(actionId)")
    }

    // MARK: - Foreground Presentation

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // MARK: - Routing

    @MainActor
    private func handleDefaultTap(category: String) {
        switch category {
        case "training":
            deepLinkRouter?.pendingDeepLink = .tab(.plan)
        case "race":
            deepLinkRouter?.pendingDeepLink = .tab(.plan)
        case "recovery", "weeklySummary":
            deepLinkRouter?.pendingDeepLink = .tab(.dashboard)
        default:
            deepLinkRouter?.pendingDeepLink = .tab(.dashboard)
        }
    }

    @MainActor
    private func handleAction(_ actionId: String) {
        switch actionId {
        case "viewSession", "skipSession", "viewRace":
            deepLinkRouter?.pendingDeepLink = .tab(.plan)
        case "viewProgress":
            deepLinkRouter?.pendingDeepLink = .tab(.dashboard)
        default:
            break
        }
    }
}
