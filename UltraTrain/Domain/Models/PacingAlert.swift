import Foundation

struct PacingAlert: Identifiable, Equatable, Sendable {
    let id: UUID
    var type: PacingAlertType
    var severity: PacingAlertSeverity
    var message: String
    var deviationPercent: Double
}
