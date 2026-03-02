import Foundation

enum NotificationCategory: String, CaseIterable, Sendable, Codable {
    case training
    case race
    case recovery
    case weeklySummary
    case inactivity
    case nutrition

    var customSoundFilename: String {
        "notification_\(rawValue).caf"
    }

    var displayName: String {
        switch self {
        case .training: "Training Reminders"
        case .race: "Race Countdown"
        case .recovery: "Recovery"
        case .weeklySummary: "Weekly Summary"
        case .inactivity: "Inactivity"
        case .nutrition: "Nutrition"
        }
    }
}
