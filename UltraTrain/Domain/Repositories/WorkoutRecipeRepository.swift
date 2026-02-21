import Foundation

protocol WorkoutRecipeRepository: Sendable {
    func getRecipes() async throws -> [WorkoutTemplate]
    func saveRecipe(_ recipe: WorkoutTemplate) async throws
    func deleteRecipe(id: String) async throws
}
