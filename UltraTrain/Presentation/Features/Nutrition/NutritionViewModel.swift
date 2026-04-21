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
    var targetRace: Race?
    var estimatedRaceDurationSeconds: TimeInterval = 0
    var athlete: Athlete?
    var gutTrainingSessions: [TrainingSession] = []
    var feedbacks: [NutritionSessionFeedback] = []
    var isLoading = false
    var isGenerating = false
    var error: String?
    var showingProductLibrary = false
    var showingAddProduct = false
    var showingNutritionOnboarding = false
    var feedbackTargetSessionId: UUID?
    var lastRefinementNotes: [String] = []
    var selectedTab: NutritionTab = .training

    /// True when the athlete hasn't yet completed the pre-plan nutrition
    /// onboarding. Drives whether `generatePlan` opens the sheet first.
    var needsNutritionOnboarding: Bool {
        !preferences.onboardingCompleted
    }

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
            guard let race = races.first(where: { $0.priority == .aRace }) else {
                isLoading = false
                return
            }
            targetRace = race
            if let athlete = try await athleteRepository.getAthlete() {
                self.athlete = athlete
                estimatedRaceDurationSeconds = estimateDuration(race: race, athlete: athlete)
            }

            plan = try await nutritionRepository.getNutritionPlan(for: race.id)
            products = try await nutritionRepository.getProducts()
            preferences = try await nutritionRepository.getNutritionPreferences()
            feedbacks = try await nutritionRepository.getNutritionFeedbacks()

            if products.isEmpty {
                for product in DefaultProducts.all {
                    try await nutritionRepository.saveProduct(product)
                }
                products = DefaultProducts.all
            }

            // Load linked gut-training sessions from the active training plan
            // so we can list them in the feedback log section.
            if let trainingPlan = try await planRepository.getActivePlan() {
                let linkedIds = Set(plan?.gutTrainingSessionIds ?? [])
                gutTrainingSessions = trainingPlan.weeks
                    .flatMap(\.sessions)
                    .filter { linkedIds.contains($0.id) }
                    .sorted { $0.date < $1.date }
            }
        } catch {
            self.error = error.localizedDescription
            Logger.nutrition.error("Failed to load nutrition plan: \(error)")
        }

        isLoading = false
    }

    // MARK: - Generate

    /// Kicks off plan generation. If the athlete hasn't completed the
    /// pre-plan nutrition onboarding, presents the sheet first — the sheet's
    /// "Generate" button then calls `generatePlan(with:)` directly.
    func startPlanGeneration() async {
        if needsNutritionOnboarding {
            showingNutritionOnboarding = true
        } else {
            await generatePlan()
        }
    }

    /// Called by the onboarding sheet on its "Generate my plan" tap. Saves
    /// the updated preferences (with onboardingCompleted = true) and then
    /// runs the generator.
    func generatePlan(with updatedPreferences: NutritionPreferences) async {
        preferences = updatedPreferences
        do {
            try await nutritionRepository.saveNutritionPreferences(updatedPreferences)
        } catch {
            self.error = error.localizedDescription
            Logger.nutrition.error("Failed to save nutrition preferences: \(error)")
            return
        }
        await generatePlan()
    }

    func generatePlan() async {
        guard !isGenerating else { return }
        isGenerating = true
        error = nil
        let generationStart = ContinuousClock.now

        do {
            guard let athlete = try await athleteRepository.getAthlete() else {
                throw DomainError.athleteNotFound
            }

            let races = try await raceRepository.getRaces()
            guard let race = races.first(where: { $0.priority == .aRace }) else {
                throw DomainError.raceNotFound
            }
            targetRace = race

            let estimatedDuration = estimateDuration(race: race, athlete: athlete)

            // Phase 4: refine preferences from accumulated feedback before
            // generating. If the athlete has logged >= 2 gut-training runs we
            // tighten the tolerance ceiling, exclude intolerant products, and
            // promote favorites automatically.
            let storedPreferences = try await nutritionRepository.getNutritionPreferences()
            let storedFeedbacks = try await nutritionRepository.getNutritionFeedbacks()
            let refinement = RefineNutritionPlanFromFeedbackUseCase.refine(
                preferences: storedPreferences,
                feedbacks: storedFeedbacks
            )
            lastRefinementNotes = refinement.notes
            let currentPreferences = refinement.refinedPreferences

            if currentPreferences != storedPreferences {
                try await nutritionRepository.saveNutritionPreferences(currentPreferences)
            }
            preferences = currentPreferences

            var newPlan = try await nutritionGenerator.execute(
                athlete: athlete,
                race: race,
                estimatedDuration: estimatedDuration,
                preferences: currentPreferences
            )

            let trainingPlan = try await planRepository.getActivePlan()
            if let trainingPlan {
                let longSessions = trainingPlan.weeks
                    .flatMap(\.sessions)
                    .filter { ($0.type == .longRun || $0.type == .race) && $0.plannedDuration > 2 * 3600 }
                newPlan.gutTrainingSessionIds = longSessions.map(\.id)
            }

            try await nutritionRepository.saveNutritionPlan(newPlan)
            plan = newPlan
            Logger.nutrition.info("Nutrition plan generated with \(newPlan.entries.count) entries")
        } catch {
            self.error = error.localizedDescription
            Logger.nutrition.error("Failed to generate nutrition plan: \(error)")
        }

        // Let the loading animation finish its current cycle (~8.5s total)
        let elapsed = ContinuousClock.now - generationStart
        let minimumDuration = Duration.seconds(8.5)
        if elapsed < minimumDuration {
            try? await Task.sleep(for: minimumDuration - elapsed)
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

    // MARK: - Feedback (Phase 4)

    func openFeedbackSheet(for sessionId: UUID) {
        feedbackTargetSessionId = sessionId
    }

    func closeFeedbackSheet() {
        feedbackTargetSessionId = nil
    }

    /// Persists post-long-run feedback, reloads the cached list, and re-applies
    /// the refinement rules so the next generate uses the updated tolerance.
    func saveFeedback(_ feedback: NutritionSessionFeedback) async {
        do {
            try await nutritionRepository.saveNutritionFeedback(feedback)
            feedbacks = try await nutritionRepository.getNutritionFeedbacks()
            feedbackTargetSessionId = nil
            Logger.nutrition.info("Nutrition feedback saved and \(self.feedbacks.count) total loaded")
        } catch {
            self.error = error.localizedDescription
            Logger.nutrition.error("Failed to save feedback: \(error)")
        }
    }

    /// True when we have enough feedback history to show the refinement banner
    /// (informs the athlete their plan now reflects their training data).
    var hasRefinementSignal: Bool {
        feedbacks.count >= 2 && !lastRefinementNotes.isEmpty
    }

    /// Returns feedback entry for a specific session if one exists.
    func feedback(for sessionId: UUID) -> NutritionSessionFeedback? {
        feedbacks.first { $0.sessionId == sessionId }
    }

    /// Distinct products currently scheduled in the plan (for the feedback
    /// sheet's product-tolerance chips).
    var productsInPlan: [NutritionProduct] {
        guard let plan else { return [] }
        var seen = Set<UUID>()
        var result: [NutritionProduct] = []
        for entry in plan.entries where !seen.contains(entry.product.id) {
            seen.insert(entry.product.id)
            result.append(entry.product)
        }
        return result
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

    /// Grams of carbohydrate delivered by the scheduled entries across the race.
    var totalCarbsGrams: Int {
        guard let plan else { return 0 }
        return Int(plan.entries.reduce(0.0) { $0 + $1.product.carbsGramsPerServing * Double($1.quantity) })
    }

    /// Total fluid volume recommended with scheduled products (drinks + flush water).
    var totalFluidMl: Int {
        guard let plan else { return 0 }
        return plan.entries.reduce(0) { $0 + ($1.product.fluidMlPerServing ?? 0) * $1.quantity }
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
        let effectiveKm = race.distanceKm + (race.elevationGainM / 100.0)
        let minutesEstimate = effectiveKm * paceMinPerKm * terrainMultiplier
        return minutesEstimate * 60
    }
}

enum NutritionTab: String, CaseIterable {
    case raceDay = "Race Day"
    case training = "Training"
}
