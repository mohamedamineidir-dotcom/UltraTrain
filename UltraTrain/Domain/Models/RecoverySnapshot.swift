import Foundation

struct RecoverySnapshot: Identifiable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var recoveryScore: RecoveryScore
    var sleepEntry: SleepEntry?
    var restingHeartRate: Int?
    var hrvReading: HRVReading?
    var readinessScore: ReadinessScore?
}
