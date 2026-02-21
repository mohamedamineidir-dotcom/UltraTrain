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

        let hrvReading: HRVReading?
        if let sdnn = model.hrvSdnnMs {
            hrvReading = HRVReading(date: model.date, sdnnMs: sdnn)
        } else {
            hrvReading = nil
        }

        let readinessScore: ReadinessScore?
        if let data = model.readinessScoreData {
            readinessScore = try? JSONDecoder().decode(ReadinessScore.self, from: data)
        } else {
            readinessScore = nil
        }

        return RecoverySnapshot(
            id: model.id,
            date: model.date,
            recoveryScore: score,
            sleepEntry: nil,
            restingHeartRate: model.restingHeartRate > 0 ? model.restingHeartRate : nil,
            hrvReading: hrvReading,
            readinessScore: readinessScore
        )
    }

    static func toSwiftData(_ snapshot: RecoverySnapshot) -> RecoverySnapshotSwiftDataModel {
        let score = snapshot.recoveryScore
        let model = RecoverySnapshotSwiftDataModel(
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
            hrvSdnnMs: snapshot.hrvReading?.sdnnMs,
            readinessScoreData: snapshot.readinessScore.flatMap { try? JSONEncoder().encode($0) },
            updatedAt: Date.now
        )
        return model
    }
}
