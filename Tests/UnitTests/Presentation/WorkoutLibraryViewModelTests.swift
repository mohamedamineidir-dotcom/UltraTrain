import Foundation
import Testing
@testable import UltraTrain

@Suite("WorkoutLibraryViewModel Tests")
struct WorkoutLibraryViewModelTests {

    // MARK: - Helpers

    private func makeRecipe(
        id: String = UUID().uuidString,
        name: String = "Custom Trail Run",
        category: WorkoutCategory = .trailSpecific
    ) -> WorkoutTemplate {
        WorkoutTemplate(
            id: id,
            name: name,
            sessionType: .longRun,
            targetDistanceKm: 20,
            targetElevationGainM: 600,
            estimatedDuration: 7200,
            intensity: .moderate,
            category: category,
            descriptionText: "A custom user-created workout.",
            isUserCreated: true
        )
    }

    @MainActor
    private func makeSUT(
        recipeRepo: MockWorkoutRecipeRepository = MockWorkoutRecipeRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository()
    ) -> (WorkoutLibraryViewModel, MockWorkoutRecipeRepository, MockTrainingPlanRepository) {
        let vm = WorkoutLibraryViewModel(
            recipeRepository: recipeRepo,
            planRepository: planRepo
        )
        return (vm, recipeRepo, planRepo)
    }

    // MARK: - Tests

    @Test("Load populates user recipes")
    @MainActor
    func loadPopulatesRecipes() async {
        let recipeRepo = MockWorkoutRecipeRepository()
        recipeRepo.recipes = [makeRecipe(name: "Recipe A"), makeRecipe(name: "Recipe B")]

        let (vm, _, _) = makeSUT(recipeRepo: recipeRepo)
        await vm.load()

        #expect(vm.userRecipes.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Filtered templates includes built-in and user")
    @MainActor
    func filteredIncludesBuiltInAndUser() async {
        let recipeRepo = MockWorkoutRecipeRepository()
        recipeRepo.recipes = [makeRecipe()]

        let (vm, _, _) = makeSUT(recipeRepo: recipeRepo)
        await vm.load()

        #expect(vm.filteredTemplates.count == WorkoutTemplateLibrary.all.count + 1)
    }

    @Test("Filter by category returns matching")
    @MainActor
    func filterByCategory() async {
        let (vm, _, _) = makeSUT()
        await vm.load()

        vm.selectedCategory = .hillTraining

        let filtered = vm.filteredTemplates
        #expect(!filtered.isEmpty)
        #expect(filtered.allSatisfy { $0.category == .hillTraining })
    }

    @Test("Search filters by name")
    @MainActor
    func searchFiltersByName() async {
        let (vm, _, _) = makeSUT()
        await vm.load()

        vm.searchQuery = "fartlek"

        let filtered = vm.filteredTemplates
        #expect(!filtered.isEmpty)
        #expect(filtered.allSatisfy { $0.name.lowercased().contains("fartlek") || $0.descriptionText.lowercased().contains("fartlek") })
    }

    @Test("Save recipe appends to list")
    @MainActor
    func saveRecipeAppends() async {
        let (vm, repo, _) = makeSUT()
        let recipe = makeRecipe(name: "New Recipe")

        await vm.saveRecipe(recipe)

        #expect(repo.saveCallCount == 1)
        #expect(vm.userRecipes.count == 1)
        #expect(vm.userRecipes.first?.name == "New Recipe")
    }

    @Test("Delete recipe removes from list")
    @MainActor
    func deleteRecipeRemoves() async {
        let recipeRepo = MockWorkoutRecipeRepository()
        let recipe = makeRecipe(id: "to-delete", name: "Doomed Recipe")
        recipeRepo.recipes = [recipe]

        let (vm, repo, _) = makeSUT(recipeRepo: recipeRepo)
        await vm.load()
        #expect(vm.userRecipes.count == 1)

        await vm.deleteRecipe(id: "to-delete")

        #expect(repo.deleteCallCount == 1)
        #expect(vm.userRecipes.isEmpty)
    }

    @Test("Error sets error message")
    @MainActor
    func errorSetsMessage() async {
        let recipeRepo = MockWorkoutRecipeRepository()
        recipeRepo.shouldThrow = true

        let (vm, _, _) = makeSUT(recipeRepo: recipeRepo)
        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }
}
