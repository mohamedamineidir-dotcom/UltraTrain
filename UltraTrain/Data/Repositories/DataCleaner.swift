import Foundation
import SwiftData
import os

// @unchecked Sendable: thread-safe via ModelContainer (new context per call)
final class DataCleaner: ClearAllDataUseCase, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func execute() async throws {
        let context = ModelContext(modelContainer)

        // Core models
        try context.delete(model: AthleteSwiftDataModel.self)
        try context.delete(model: RaceSwiftDataModel.self)
        try context.delete(model: CheckpointSwiftDataModel.self)
        try context.delete(model: TrainingPlanSwiftDataModel.self)
        try context.delete(model: TrainingWeekSwiftDataModel.self)
        try context.delete(model: TrainingSessionSwiftDataModel.self)
        try context.delete(model: CompletedRunSwiftDataModel.self)
        try context.delete(model: SplitSwiftDataModel.self)
        try context.delete(model: FitnessSnapshotSwiftDataModel.self)
        try context.delete(model: FinishEstimateSwiftDataModel.self)
        try context.delete(model: RecoverySnapshotSwiftDataModel.self)

        // Nutrition
        try context.delete(model: NutritionPlanSwiftDataModel.self)
        try context.delete(model: NutritionEntrySwiftDataModel.self)
        try context.delete(model: NutritionProductSwiftDataModel.self)
        try context.delete(model: NutritionPreferencesSwiftDataModel.self)
        try context.delete(model: FoodLogEntrySwiftDataModel.self)

        // Gear & goals
        try context.delete(model: GearItemSwiftDataModel.self)
        try context.delete(model: TrainingGoalSwiftDataModel.self)
        try context.delete(model: WorkoutRecipeSwiftDataModel.self)
        try context.delete(model: IntervalWorkoutSwiftDataModel.self)

        // Race prep
        try context.delete(model: RacePrepChecklistSwiftDataModel.self)
        try context.delete(model: ChecklistItemSwiftDataModel.self)
        try context.delete(model: RaceReflectionSwiftDataModel.self)
        try context.delete(model: ChallengeEnrollmentSwiftDataModel.self)

        // Social
        try context.delete(model: SocialProfileSwiftDataModel.self)
        try context.delete(model: FriendConnectionSwiftDataModel.self)
        try context.delete(model: SharedRunSwiftDataModel.self)
        try context.delete(model: ActivityFeedItemSwiftDataModel.self)
        try context.delete(model: GroupChallengeSwiftDataModel.self)

        // Routes & contacts
        try context.delete(model: SavedRouteSwiftDataModel.self)
        try context.delete(model: EmergencyContactSwiftDataModel.self)

        // Health & check-ins
        try context.delete(model: MorningCheckInSwiftDataModel.self)
        try context.delete(model: UnlockedAchievementSwiftDataModel.self)

        // Sync & upload queues
        try context.delete(model: SyncQueueSwiftDataModel.self)
        try context.delete(model: StravaUploadQueueSwiftDataModel.self)

        // Settings (last)
        try context.delete(model: AppSettingsSwiftDataModel.self)

        try context.save()
        Logger.persistence.info("All data cleared successfully")
    }
}
