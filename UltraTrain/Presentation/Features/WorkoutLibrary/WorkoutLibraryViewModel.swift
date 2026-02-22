import Foundation
import os

@Observable
@MainActor
final class WorkoutLibraryViewModel {

    // MARK: - Dependencies

    private let recipeRepository: any WorkoutRecipeRepository
    private let planRepository: any TrainingPlanRepository
    private let intervalWorkoutRepository: (any IntervalWorkoutRepository)?

    // MARK: - State

    var userRecipes: [WorkoutTemplate] = []
    var userIntervalWorkouts: [IntervalWorkout] = []
    var selectedCategory: WorkoutCategory?
    var searchQuery: String = ""
    var isLoading = false
    var error: String?
    var showingAddRecipe = false
    var showingIntervalBuilder = false
    var templateToAdd: WorkoutTemplate?
    var recipeToEdit: WorkoutTemplate?

    // MARK: - Init

    init(
        recipeRepository: any WorkoutRecipeRepository,
        planRepository: any TrainingPlanRepository,
        intervalWorkoutRepository: (any IntervalWorkoutRepository)? = nil
    ) {
        self.recipeRepository = recipeRepository
        self.planRepository = planRepository
        self.intervalWorkoutRepository = intervalWorkoutRepository
    }

    // MARK: - Computed

    var filteredTemplates: [WorkoutTemplate] {
        let combined = WorkoutTemplateLibrary.all + userRecipes
        let filtered: [WorkoutTemplate]

        if let category = selectedCategory {
            filtered = combined.filter { $0.category == category }
        } else {
            filtered = combined
        }

        if searchQuery.isEmpty {
            return filtered.sorted { $0.name < $1.name }
        }

        let query = searchQuery.lowercased()
        return filtered.filter {
            $0.name.lowercased().contains(query) ||
            $0.descriptionText.lowercased().contains(query)
        }
        .sorted { $0.name < $1.name }
    }

    // MARK: - Load

    // MARK: - Interval Computed

    var filteredIntervalWorkouts: [IntervalWorkout] {
        let combined = IntervalWorkoutLibrary.allWorkouts + userIntervalWorkouts
        let filtered: [IntervalWorkout]

        if let category = selectedCategory {
            filtered = combined.filter { $0.category == category }
        } else {
            filtered = combined
        }

        if searchQuery.isEmpty {
            return filtered.sorted { $0.name < $1.name }
        }

        let query = searchQuery.lowercased()
        return filtered.filter {
            $0.name.lowercased().contains(query) ||
            $0.descriptionText.lowercased().contains(query)
        }
        .sorted { $0.name < $1.name }
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            userRecipes = try await recipeRepository.getRecipes()
            if let repo = intervalWorkoutRepository {
                userIntervalWorkouts = try await repo.getWorkouts()
            }
        } catch {
            self.error = error.localizedDescription
            Logger.workouts.error("Failed to load recipes: \(error)")
        }

        isLoading = false
    }

    // MARK: - Add to Plan

    func addToPlan(template: WorkoutTemplate, date: Date) async {
        do {
            guard var plan = try await planRepository.getActivePlan() else {
                self.error = "No active training plan found."
                return
            }

            guard let weekIndex = plan.weeks.firstIndex(where: {
                $0.contains(date: date)
            }) else {
                self.error = "No training week found for the selected date."
                return
            }

            let session = TrainingSession(
                id: UUID(),
                date: date,
                type: template.sessionType,
                plannedDistanceKm: template.targetDistanceKm,
                plannedElevationGainM: template.targetElevationGainM,
                plannedDuration: template.estimatedDuration,
                intensity: template.intensity,
                description: template.name,
                nutritionNotes: nil,
                isCompleted: false,
                isSkipped: false,
                linkedRunId: nil
            )

            plan.weeks[weekIndex].sessions.append(session)
            try await planRepository.updatePlan(plan)
        } catch {
            self.error = error.localizedDescription
            Logger.workouts.error("Failed to add template to plan: \(error)")
        }
    }

    // MARK: - Recipes

    func saveRecipe(_ recipe: WorkoutTemplate) async {
        do {
            try await recipeRepository.saveRecipe(recipe)
            userRecipes.append(recipe)
        } catch {
            self.error = error.localizedDescription
            Logger.workouts.error("Failed to save recipe: \(error)")
        }
    }

    func deleteRecipe(id: String) async {
        do {
            try await recipeRepository.deleteRecipe(id: id)
            userRecipes.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
            Logger.workouts.error("Failed to delete recipe: \(error)")
        }
    }

    // MARK: - Interval Workouts

    func deleteIntervalWorkout(id: UUID) async {
        do {
            try await intervalWorkoutRepository?.deleteWorkout(id: id)
            userIntervalWorkouts.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
            Logger.workouts.error("Failed to delete interval workout: \(error)")
        }
    }
}
