import Foundation

struct InjuryRiskAlert: Identifiable, Equatable, Sendable {
    let id: UUID
    var type: InjuryRiskType
    var severity: AlertSeverity
    var message: String
    var recommendation: String
}

enum InjuryRiskType: String, Sendable {
    case highACR
    case volumeSpike
    case highMonotony
    case combinedStrain
}

enum AlertSeverity: String, Sendable {
    case warning
    case critical
}
