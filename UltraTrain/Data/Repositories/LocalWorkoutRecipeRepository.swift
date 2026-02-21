import Foundation
import SwiftData
import os

final class LocalWorkoutRecipeRepository: WorkoutRecipeRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getRecipes() async throws -> [WorkoutTemplate] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<WorkoutRecipeSwiftDataModel>(
            sortBy: [SortDescriptor(\.name)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { WorkoutRecipeSwiftDataMapper.toDomain($0) }
    }

    func saveRecipe(_ recipe: WorkoutTemplate) async throws {
        let context = ModelContext(modelContainer)
        let model = WorkoutRecipeSwiftDataMapper.toSwiftData(recipe)
        context.insert(model)
        try context.save()
        Logger.workouts.info("Workout recipe saved: \(recipe.name)")
    }

    func deleteRecipe(id: String) async throws {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<WorkoutRecipeSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.workoutRecipeNotFound
        }

        context.delete(model)
        try context.save()
        Logger.workouts.info("Workout recipe deleted: \(targetId)")
    }
}
