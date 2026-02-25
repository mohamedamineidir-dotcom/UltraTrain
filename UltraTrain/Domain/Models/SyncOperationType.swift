import Foundation

enum SyncOperationType: String, Sendable, Equatable {
    case runUpload
    case athleteSync
    case raceSync
    case raceDelete
    case trainingPlanSync
    case socialProfileSync
    case activityPublish
    case shareRevoke
}
