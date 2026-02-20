import Foundation
import SwiftData

@Model
final class RecoverySnapshotSwiftDataModel {
    var id: UUID = UUID()
    var date: Date = Date()
    var overallScore: Int = 0
    var sleepQualityScore: Int = 0
    var sleepConsistencyScore: Int = 0
    var restingHRScore: Int = 0
    var trainingLoadBalanceScore: Int = 0
    var recommendation: String = ""
    var status: String = ""
    var sleepDuration: Double = 0
    var deepSleepDuration: Double = 0
    var remSleepDuration: Double = 0
    var sleepEfficiency: Double = 0
    var restingHeartRate: Int = 0
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        overallScore: Int = 0,
        sleepQualityScore: Int = 0,
        sleepConsistencyScore: Int = 0,
        restingHRScore: Int = 0,
        trainingLoadBalanceScore: Int = 0,
        recommendation: String = "",
        status: String = "",
        sleepDuration: Double = 0,
        deepSleepDuration: Double = 0,
        remSleepDuration: Double = 0,
        sleepEfficiency: Double = 0,
        restingHeartRate: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.overallScore = overallScore
        self.sleepQualityScore = sleepQualityScore
        self.sleepConsistencyScore = sleepConsistencyScore
        self.restingHRScore = restingHRScore
        self.trainingLoadBalanceScore = trainingLoadBalanceScore
        self.recommendation = recommendation
        self.status = status
        self.sleepDuration = sleepDuration
        self.deepSleepDuration = deepSleepDuration
        self.remSleepDuration = remSleepDuration
        self.sleepEfficiency = sleepEfficiency
        self.restingHeartRate = restingHeartRate
        self.updatedAt = updatedAt
    }
}
