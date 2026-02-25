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
    var hrvScore: Int = 0
}
