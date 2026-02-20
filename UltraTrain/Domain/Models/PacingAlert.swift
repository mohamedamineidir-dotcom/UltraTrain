import Foundation

enum PacingAlertType: String, Sendable {
    case tooFast
    case tooSlow
    case backOnPace
}

enum PacingAlertSeverity: String, Sendable {
    case minor
    case major
    case positive
}

struct PacingAlert: Identifiable, Equatable, Sendable {
    let id: UUID
    var type: PacingAlertType
    var severity: PacingAlertSeverity
    var message: String
    var deviationPercent: Double
}
