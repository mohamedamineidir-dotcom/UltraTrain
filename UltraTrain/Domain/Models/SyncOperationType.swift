import Foundation

enum SyncOperationType: String, Sendable, Equatable {
    case runUpload
    case athleteSync
    case raceSync
    case raceDelete
    case trainingPlanSync
    case nutritionPlanSync
    case fitnessSnapshotSync
    case finishEstimateSync
    case socialProfileSync
    case activityPublish
    case shareRevoke
}
