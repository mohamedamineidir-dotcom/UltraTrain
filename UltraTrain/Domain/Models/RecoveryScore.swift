import Foundation

struct RecoveryScore: Identifiable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var overallScore: Int
    var sleepQualityScore: Int
    var sleepConsistencyScore: Int
    var restingHRScore: Int
    var trainingLoadBalanceScore: Int
    var recommendation: String
    var status: RecoveryStatus
}

enum RecoveryStatus: String, Sendable, Equatable {
    case excellent
    case good
    case moderate
    case poor
    case critical
}
