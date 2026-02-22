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

enum SafetyAlertStatus: String, Sendable {
    case triggered
    case cancelled
    case sent
}

struct SafetyAlert: Identifiable, Sendable {
    let id: UUID
    var type: SafetyAlertType
    var triggeredAt: Date
    var latitude: Double?
    var longitude: Double?
    var message: String
    var status: SafetyAlertStatus
}
