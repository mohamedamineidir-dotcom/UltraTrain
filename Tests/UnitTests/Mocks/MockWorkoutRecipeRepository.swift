import Foundation
@testable import UltraTrain

final class MockWorkoutRecipeRepository: WorkoutRecipeRepository, @unchecked Sendable {
    var recipes: [WorkoutTemplate] = []
    var saveCallCount = 0
    var deleteCallCount = 0
    var shouldThrow = false

    func getRecipes() async throws -> [WorkoutTemplate] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return recipes
    }

    func saveRecipe(_ recipe: WorkoutTemplate) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        saveCallCount += 1
        recipes.append(recipe)
    }

    func deleteRecipe(id: String) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        deleteCallCount += 1
        recipes.removeAll { $0.id == id }
    }
}
