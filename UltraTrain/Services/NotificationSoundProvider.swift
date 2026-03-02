import Foundation
import UserNotifications

enum NotificationSoundProvider {
    static func sound(
        for category: NotificationCategory,
        preference: NotificationSoundPreference
    ) -> UNNotificationSound? {
        switch preference {
        case .defaultSound:
            return .default
        case .custom:
            return UNNotificationSound(named: UNNotificationSoundName(category.customSoundFilename))
        case .silent:
            return nil
        }
    }
}
