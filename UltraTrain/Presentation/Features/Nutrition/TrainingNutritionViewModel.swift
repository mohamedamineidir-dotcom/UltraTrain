import Foundation
import os

@Observable
@MainActor
final class TrainingNutritionViewModel {

    // MARK: - Dependencies

    private let athleteRepository: any AthleteRepository
    private let planRepository: any TrainingPlanRepository
    private let nutritionRepository: any NutritionRepository
    private let foodLogRepository: any FoodLogRepository
    private let sessionNutritionAdvisor: any SessionNutritionAdvisor

    // MARK: - State

    var dailyTarget: DailyNutritionTarget?
    var todayEntries: [FoodLogEntry] = []
    var weeklyEntries: [FoodLogEntry] = []
    var currentPhase: TrainingPhase = .base
    var todaySession: TrainingSession?
    var isLoading = false
    var error: String?
    var showingAddEntry = false

    // MARK: - Init

    init(
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository,
        nutritionRepository: any NutritionRepository,
        foodLogRepository: any FoodLogRepository,
        sessionNutritionAdvisor: any SessionNutritionAdvisor
    ) {
        self.athleteRepository = athleteRepository
        self.planRepository = planRepository
        self.nutritionRepository = nutritionRepository
        self.foodLogRepository = foodLogRepository
        self.sessionNutritionAdvisor = sessionNutritionAdvisor
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            guard let athlete = try await athleteRepository.getAthlete() else {
                isLoading = false
                return
            }

            let plan = try await planRepository.getActivePlan()
            let session = findTodaySession(in: plan)
            todaySession = session

            let phase = findCurrentPhase(in: plan)
            currentPhase = phase

            let preferences = try await nutritionRepository.getNutritionPreferences()

            var target = DailyNutritionCalculator.calculateTarget(
                athlete: athlete,
                trainingPhase: phase,
                session: session,
                preferences: preferences
            )

            if let session {
                let advice = sessionNutritionAdvisor.advise(
                    for: session,
                    athleteWeightKg: athlete.weightKg,
                    experienceLevel: athlete.experienceLevel,
                    preferences: preferences
                )
                target.sessionAdvice = advice
            }

            dailyTarget = target

            todayEntries = try await foodLogRepository.getEntries(for: Date.now)
            weeklyEntries = try await loadWeeklyEntries()
        } catch {
            self.error = error.localizedDescription
            Logger.nutrition.error("Failed to load training nutrition: \(error)")
        }

        isLoading = false
    }

    // MARK: - Consumed Totals

    var consumedCalories: Int {
        todayEntries.compactMap(\.caloriesEstimate).reduce(0, +)
    }

    var consumedCarbs: Double {
        todayEntries.compactMap(\.carbsGrams).reduce(0, +)
    }

    var consumedProtein: Double {
        todayEntries.compactMap(\.proteinGrams).reduce(0, +)
    }

    var consumedFat: Double {
        todayEntries.compactMap(\.fatGrams).reduce(0, +)
    }

    var consumedHydration: Int {
        todayEntries.compactMap(\.hydrationMl).reduce(0, +)
    }

    // MARK: - Actions

    func addEntry(_ entry: FoodLogEntry) async {
        do {
            try await foodLogRepository.saveEntry(entry)
            todayEntries.append(entry)
            weeklyEntries.append(entry)
            Logger.nutrition.info("Food log entry added: \(entry.mealType.rawValue)")
        } catch {
            self.error = error.localizedDescription
            Logger.nutrition.error("Failed to add food log entry: \(error)")
        }
    }

    func deleteEntry(id: UUID) async {
        do {
            try await foodLogRepository.deleteEntry(id: id)
            todayEntries.removeAll { $0.id == id }
            weeklyEntries.removeAll { $0.id == id }
            Logger.nutrition.info("Food log entry deleted")
        } catch {
            self.error = error.localizedDescription
            Logger.nutrition.error("Failed to delete food log entry: \(error)")
        }
    }

    // MARK: - Helpers

    private func findTodaySession(in plan: TrainingPlan?) -> TrainingSession? {
        guard let plan else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        return plan.weeks
            .flatMap(\.sessions)
            .first { calendar.startOfDay(for: $0.date) == today }
    }

    private func findCurrentPhase(in plan: TrainingPlan?) -> TrainingPhase {
        guard let plan else { return .recovery }
        guard let week = plan.weeks.first(where: { $0.containsToday }) else {
            return .recovery
        }
        return week.phase
    }

    private func loadWeeklyEntries() async throws -> [FoodLogEntry] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date.now)
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: todayStart) else {
            return []
        }
        let endOfToday = todayStart.addingTimeInterval(86399)
        return try await foodLogRepository.getEntries(from: weekStart, to: endOfToday)
    }
}
