import Foundation

struct InjuryRiskAlert: Identifiable, Equatable, Sendable {
    let id: UUID
    var type: InjuryRiskType
    var severity: AlertSeverity
    var message: String
    var recommendation: String
}
