import Foundation

enum SafetyAlertType: String, Sendable, Codable {
    case sos
    case fallDetected
    case noMovement
    case safetyTimerExpired

    var displayName: String {
        switch self {
        case .sos: return "SOS"
        case .fallDetected: return "Fall Detected"
        case .noMovement: return "No Movement"
        case .safetyTimerExpired: return "Safety Timer Expired"
        }
    }

    var iconName: String {
        switch self {
        case .sos: return "sos"
        case .fallDetected: return "figure.fall"
        case .noMovement: return "person.fill.questionmark"
        case .safetyTimerExpired: return "timer"
        }
    }
}
