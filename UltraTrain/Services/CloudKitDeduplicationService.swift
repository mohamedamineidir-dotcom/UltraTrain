import Foundation
import SwiftData
import os

enum CloudKitDeduplicationService {

    // MARK: - Public

    static func deduplicateIfNeeded(modelContainer: ModelContainer) async {
        let context = ModelContext(modelContainer)
        Logger.cloudKit.info("Starting CloudKit deduplication check")

        do {
            try deduplicateSingletons(context: context)
            try deduplicateEntities(context: context)
            if context.hasChanges {
                try context.save()
                Logger.cloudKit.info("Deduplication complete — duplicates removed")
            } else {
                Logger.cloudKit.debug("No duplicates found")
            }
        } catch {
            Logger.cloudKit.error("Deduplication failed: \(error)")
        }
    }

    // MARK: - Singleton Dedup

    private static func deduplicateSingletons(context: ModelContext) throws {
        try deduplicateSingleton(AthleteSwiftDataModel.self, context: context)
        try deduplicateSingleton(AppSettingsSwiftDataModel.self, context: context)
        try deduplicateSingleton(NutritionPreferencesSwiftDataModel.self, context: context)
    }

    private static func deduplicateSingleton<T: PersistentModel>(
        _ type: T.Type,
        context: ModelContext
    ) throws where T: HasUpdatedAt {
        let descriptor = FetchDescriptor<T>()
        let all = try context.fetch(descriptor)

        guard all.count > 1 else { return }

        let sorted = all.sorted { $0.updatedAt > $1.updatedAt }
        let duplicates = sorted.dropFirst()

        for duplicate in duplicates {
            context.delete(duplicate)
        }

        Logger.cloudKit.info(
            "Removed \(duplicates.count) duplicate(s) of \(String(describing: type))"
        )
    }

    // MARK: - Entity Dedup

    private static func deduplicateEntities(context: ModelContext) throws {
        try deduplicateByID(CompletedRunSwiftDataModel.self, context: context)
        try deduplicateByID(SplitSwiftDataModel.self, context: context)
        try deduplicateByID(RaceSwiftDataModel.self, context: context)
        try deduplicateByID(CheckpointSwiftDataModel.self, context: context)
        try deduplicateByID(TrainingPlanSwiftDataModel.self, context: context)
        try deduplicateByID(TrainingWeekSwiftDataModel.self, context: context)
        try deduplicateByID(TrainingSessionSwiftDataModel.self, context: context)
        try deduplicateByID(NutritionPlanSwiftDataModel.self, context: context)
        try deduplicateByID(NutritionEntrySwiftDataModel.self, context: context)
        try deduplicateByID(NutritionProductSwiftDataModel.self, context: context)
        try deduplicateByID(FitnessSnapshotSwiftDataModel.self, context: context)
    }

    private static func deduplicateByID<T: PersistentModel>(
        _ type: T.Type,
        context: ModelContext
    ) throws where T: HasIDAndUpdatedAt {
        let descriptor = FetchDescriptor<T>()
        let all = try context.fetch(descriptor)

        let grouped = Dictionary(grouping: all) { $0.id }
        var totalRemoved = 0

        for (_, models) in grouped where models.count > 1 {
            let sorted = models.sorted { $0.updatedAt > $1.updatedAt }
            let duplicates = sorted.dropFirst()
            for duplicate in duplicates {
                context.delete(duplicate)
            }
            totalRemoved += duplicates.count
        }

        if totalRemoved > 0 {
            Logger.cloudKit.info(
                "Removed \(totalRemoved) duplicate(s) of \(String(describing: type))"
            )
        }
    }
}

// MARK: - Protocols for Dedup

protocol HasUpdatedAt {
    var updatedAt: Date { get }
}

protocol HasIDAndUpdatedAt: HasUpdatedAt {
    var id: UUID { get }
}

// MARK: - Model Conformances

extension AthleteSwiftDataModel: HasUpdatedAt, HasIDAndUpdatedAt {}
extension AppSettingsSwiftDataModel: HasUpdatedAt, HasIDAndUpdatedAt {}
extension NutritionPreferencesSwiftDataModel: HasUpdatedAt, HasIDAndUpdatedAt {}
extension CompletedRunSwiftDataModel: HasIDAndUpdatedAt {}
extension SplitSwiftDataModel: HasIDAndUpdatedAt {}
extension RaceSwiftDataModel: HasIDAndUpdatedAt {}
extension CheckpointSwiftDataModel: HasIDAndUpdatedAt {}
extension TrainingPlanSwiftDataModel: HasIDAndUpdatedAt {}
extension TrainingWeekSwiftDataModel: HasIDAndUpdatedAt {}
extension TrainingSessionSwiftDataModel: HasIDAndUpdatedAt {}
extension NutritionPlanSwiftDataModel: HasIDAndUpdatedAt {}
extension NutritionEntrySwiftDataModel: HasIDAndUpdatedAt {}
extension NutritionProductSwiftDataModel: HasIDAndUpdatedAt {}
extension FitnessSnapshotSwiftDataModel: HasIDAndUpdatedAt {}
