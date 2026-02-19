import Foundation
import SwiftData
import os

final class DataCleaner: ClearAllDataUseCase, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func execute() async throws {
        let context = ModelContext(modelContainer)

        try context.delete(model: AthleteSwiftDataModel.self)
        try context.delete(model: RaceSwiftDataModel.self)
        try context.delete(model: TrainingPlanSwiftDataModel.self)
        try context.delete(model: TrainingWeekSwiftDataModel.self)
        try context.delete(model: TrainingSessionSwiftDataModel.self)
        try context.delete(model: NutritionPlanSwiftDataModel.self)
        try context.delete(model: NutritionEntrySwiftDataModel.self)
        try context.delete(model: NutritionProductSwiftDataModel.self)
        try context.delete(model: CompletedRunSwiftDataModel.self)
        try context.delete(model: SplitSwiftDataModel.self)
        try context.delete(model: FitnessSnapshotSwiftDataModel.self)
        try context.delete(model: AppSettingsSwiftDataModel.self)
        try context.delete(model: GearItemSwiftDataModel.self)

        try context.save()
        Logger.persistence.info("All data cleared successfully")
    }
}
