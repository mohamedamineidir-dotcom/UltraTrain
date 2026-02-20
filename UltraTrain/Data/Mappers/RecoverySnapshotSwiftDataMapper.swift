import Foundation

enum RecoverySnapshotSwiftDataMapper {

    static func toDomain(_ model: RecoverySnapshotSwiftDataModel) -> RecoverySnapshot {
        let score = RecoveryScore(
            id: model.id,
            date: model.date,
            overallScore: model.overallScore,
            sleepQualityScore: model.sleepQualityScore,
            sleepConsistencyScore: model.sleepConsistencyScore,
            restingHRScore: model.restingHRScore,
            trainingLoadBalanceScore: model.trainingLoadBalanceScore,
            recommendation: model.recommendation,
            status: RecoveryStatus(rawValue: model.status) ?? .moderate
        )

        return RecoverySnapshot(
            id: model.id,
            date: model.date,
            recoveryScore: score,
            sleepEntry: nil,
            restingHeartRate: model.restingHeartRate > 0 ? model.restingHeartRate : nil
        )
    }

    static func toSwiftData(_ snapshot: RecoverySnapshot) -> RecoverySnapshotSwiftDataModel {
        let score = snapshot.recoveryScore
        return RecoverySnapshotSwiftDataModel(
            id: snapshot.id,
            date: snapshot.date,
            overallScore: score.overallScore,
            sleepQualityScore: score.sleepQualityScore,
            sleepConsistencyScore: score.sleepConsistencyScore,
            restingHRScore: score.restingHRScore,
            trainingLoadBalanceScore: score.trainingLoadBalanceScore,
            recommendation: score.recommendation,
            status: score.status.rawValue,
            sleepDuration: snapshot.sleepEntry?.totalSleepDuration ?? 0,
            deepSleepDuration: snapshot.sleepEntry?.deepSleepDuration ?? 0,
            remSleepDuration: snapshot.sleepEntry?.remSleepDuration ?? 0,
            sleepEfficiency: snapshot.sleepEntry?.sleepEfficiency ?? 0,
            restingHeartRate: snapshot.restingHeartRate ?? 0,
            updatedAt: Date.now
        )
    }
}
