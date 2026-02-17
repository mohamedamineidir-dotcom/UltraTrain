import Foundation
import os

@Observable
@MainActor
final class NutritionViewModel {

    // MARK: - Dependencies

    private let nutritionRepository: any NutritionRepository
    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository
    private let nutritionGenerator: any GenerateNutritionPlanUseCase

    // MARK: - State

    var plan: NutritionPlan?
    var products: [NutritionProduct] = []
    var preferences: NutritionPreferences = .default
    var isLoading = false
    var isGenerating = false
    var error: String?
    var showingProductLibrary = false
    var showingAddProduct = false

    // MARK: - Init

    init(
        nutritionRepository: any NutritionRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planRepository: any TrainingPlanRepository,
        nutritionGenerator: any GenerateNutritionPlanUseCase
    ) {
        self.nutritionRepository = nutritionRepository
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.planRepository = planRepository
        self.nutritionGenerator = nutritionGenerator
    }

    // MARK: - Load

    func loadPlan() async {
        isLoading = true
        error = nil

        do {
            let races = try await raceRepository.getRaces()
            guard let targetRace = races.first(where: { $0.priority == .aRace }) else {
                isLoading = false
                return
            }

            plan = try await nutritionRepository.getNutritionPlan(for: targetRace.id)
            products = try await nutritionRepository.getProducts()
            preferences = try await nutritionRepository.getNutritionPreferences()

            if products.isEmpty {
                for product in DefaultProducts.all {
                    try await nutritionRepository.saveProduct(product)
                }
                products = DefaultProducts.all
            }
        } catch {
            self.error = error.localizedDescription
            Logger.nutrition.error("Failed to load nutrition plan: \(error)")
        }

        isLoading = false
    }

    // MARK: - Generate

    func generatePlan() async {
        guard !isGenerating else { return }
        isGenerating = true
        error = nil

        do {
            guard let athlete = try await athleteRepository.getAthlete() else {
                throw DomainError.athleteNotFound
            }

            let races = try await raceRepository.getRaces()
            guard let targetRace = races.first(where: { $0.priority == .aRace }) else {
                throw DomainError.raceNotFound
            }

            let estimatedDuration = estimateDuration(race: targetRace, athlete: athlete)

            let currentPreferences = try await nutritionRepository.getNutritionPreferences()
            preferences = currentPreferences

            var newPlan = try await nutritionGenerator.execute(
                athlete: athlete,
                race: targetRace,
                estimatedDuration: estimatedDuration,
                preferences: currentPreferences
            )

            let trainingPlan = try await planRepository.getActivePlan()
            if let trainingPlan {
                let longSessions = trainingPlan.weeks
                    .flatMap(\.sessions)
                    .filter { $0.type == .longRun && $0.plannedDuration > 2 * 3600 }
                newPlan.gutTrainingSessionIds = longSessions.map(\.id)
            }

            try await nutritionRepository.saveNutritionPlan(newPlan)
            plan = newPlan
            Logger.nutrition.info("Nutrition plan generated with \(newPlan.entries.count) entries")
        } catch {
            self.error = error.localizedDescription
            Logger.nutrition.error("Failed to generate nutrition plan: \(error)")
        }

        isGenerating = false
    }

    // MARK: - Products

    func addProduct(_ product: NutritionProduct) async {
        do {
            try await nutritionRepository.saveProduct(product)
            products.append(product)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Preferences

    func savePreferences() async {
        do {
            try await nutritionRepository.saveNutritionPreferences(preferences)
        } catch {
            self.error = error.localizedDescription
            Logger.nutrition.error("Failed to save nutrition preferences: \(error)")
        }
    }

    func toggleProductExclusion(_ productId: UUID) async {
        if preferences.excludedProductIds.contains(productId) {
            preferences.excludedProductIds.remove(productId)
        } else {
            preferences.excludedProductIds.insert(productId)
        }
        await savePreferences()
    }

    func isProductExcluded(_ productId: UUID) -> Bool {
        preferences.excludedProductIds.contains(productId)
    }

    // MARK: - Computed

    var totalCaloriesInPlan: Int {
        guard let plan else { return 0 }
        return plan.entries.reduce(0) { $0 + $1.product.caloriesPerServing * $1.quantity }
    }

    var totalSodiumInPlan: Int {
        guard let plan else { return 0 }
        return plan.entries.reduce(0) { $0 + $1.product.sodiumMgPerServing * $1.quantity }
    }

    var gutTrainingSessionCount: Int {
        plan?.gutTrainingSessionIds.count ?? 0
    }

    // MARK: - Helpers

    private func estimateDuration(race: Race, athlete: Athlete) -> TimeInterval {
        if case .targetTime(let time) = race.goalType {
            return time
        }
        let paceMinPerKm: Double = switch athlete.experienceLevel {
        case .elite:        8.0
        case .advanced:     9.0
        case .intermediate: 10.0
        case .beginner:     12.0
        }
        let terrainMultiplier: Double = switch race.terrainDifficulty {
        case .easy:      1.0
        case .moderate:  1.1
        case .technical: 1.25
        case .extreme:   1.4
        }
        let elevationPenalty = race.elevationGainM / 100.0
        let minutesEstimate = race.distanceKm * paceMinPerKm * terrainMultiplier + elevationPenalty
        return minutesEstimate * 60
    }
}
