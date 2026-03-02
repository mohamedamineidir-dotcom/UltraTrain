import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalWorkoutRecipeRepository Tests")
@MainActor
struct LocalWorkoutRecipeRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([WorkoutRecipeSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeRecipe(
        id: String = UUID().uuidString,
        name: String = "Trail Tempo",
        sessionType: SessionType = .tempo,
        intensity: Intensity = .moderate
    ) -> WorkoutTemplate {
        WorkoutTemplate(
            id: id,
            name: name,
            sessionType: sessionType,
            targetDistanceKm: 12.0,
            targetElevationGainM: 400,
            estimatedDuration: 3600,
            intensity: intensity,
            category: .trailSpecific,
            descriptionText: "Moderate tempo on trails",
            isUserCreated: true
        )
    }

    @Test("Save and get recipes")
    func saveAndGetRecipes() async throws {
        let container = try makeContainer()
        let repo = LocalWorkoutRecipeRepository(modelContainer: container)

        try await repo.saveRecipe(makeRecipe(name: "Hill Blaster"))

        let results = try await repo.getRecipes()
        #expect(results.count == 1)
        #expect(results.first?.name == "Hill Blaster")
    }

    @Test("Get recipes returns empty when none saved")
    func getRecipesReturnsEmptyWhenNone() async throws {
        let container = try makeContainer()
        let repo = LocalWorkoutRecipeRepository(modelContainer: container)

        let results = try await repo.getRecipes()
        #expect(results.isEmpty)
    }

    @Test("Delete recipe removes it")
    func deleteRecipeRemovesIt() async throws {
        let container = try makeContainer()
        let repo = LocalWorkoutRecipeRepository(modelContainer: container)
        let recipeId = UUID().uuidString

        try await repo.saveRecipe(makeRecipe(id: recipeId))
        try await repo.deleteRecipe(id: recipeId)

        let results = try await repo.getRecipes()
        #expect(results.isEmpty)
    }

    @Test("Delete recipe throws when not found")
    func deleteRecipeThrowsWhenNotFound() async throws {
        let container = try makeContainer()
        let repo = LocalWorkoutRecipeRepository(modelContainer: container)

        await #expect(throws: DomainError.self) {
            try await repo.deleteRecipe(id: "nonexistent")
        }
    }

    @Test("Recipes returned sorted by name")
    func recipesReturnedSortedByName() async throws {
        let container = try makeContainer()
        let repo = LocalWorkoutRecipeRepository(modelContainer: container)

        try await repo.saveRecipe(makeRecipe(name: "Zone 2 Long Run"))
        try await repo.saveRecipe(makeRecipe(name: "Alpine Intervals"))

        let results = try await repo.getRecipes()
        #expect(results.count == 2)
        #expect(results[0].name == "Alpine Intervals")
        #expect(results[1].name == "Zone 2 Long Run")
    }
}
