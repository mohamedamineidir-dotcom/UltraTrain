import Foundation

enum NotificationSoundPreference: String, CaseIterable, Sendable, Codable {
    case defaultSound = "default"
    case custom
    case silent
}
