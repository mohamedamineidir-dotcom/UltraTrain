import SwiftData

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            AthleteSwiftDataModel.self,
            RaceSwiftDataModel.self,
            CheckpointSwiftDataModel.self,
            TrainingPlanSwiftDataModel.self,
            TrainingWeekSwiftDataModel.self,
            TrainingSessionSwiftDataModel.self,
            NutritionPlanSwiftDataModel.self,
            NutritionEntrySwiftDataModel.self,
            NutritionProductSwiftDataModel.self,
            CompletedRunSwiftDataModel.self,
            SplitSwiftDataModel.self,
            FitnessSnapshotSwiftDataModel.self,
            AppSettingsSwiftDataModel.self,
            NutritionPreferencesSwiftDataModel.self,
            GearItemSwiftDataModel.self,
            FinishEstimateSwiftDataModel.self,
            StravaUploadQueueSwiftDataModel.self,
            RecoverySnapshotSwiftDataModel.self,
            RacePrepChecklistSwiftDataModel.self,
            ChecklistItemSwiftDataModel.self,
            ChallengeEnrollmentSwiftDataModel.self,
            WorkoutRecipeSwiftDataModel.self,
            TrainingGoalSwiftDataModel.self,
            SocialProfileSwiftDataModel.self,
            FriendConnectionSwiftDataModel.self,
            SharedRunSwiftDataModel.self,
            ActivityFeedItemSwiftDataModel.self,
            GroupChallengeSwiftDataModel.self,
            SavedRouteSwiftDataModel.self,
            IntervalWorkoutSwiftDataModel.self,
            EmergencyContactSwiftDataModel.self,
            FoodLogEntrySwiftDataModel.self,
            RaceReflectionSwiftDataModel.self,
            UnlockedAchievementSwiftDataModel.self,
            MorningCheckInSwiftDataModel.self,
            SyncQueueSwiftDataModel.self
        ]
    }
}
