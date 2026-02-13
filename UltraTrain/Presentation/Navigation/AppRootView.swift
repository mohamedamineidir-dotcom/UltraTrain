import SwiftUI
import os

struct AppRootView: View {
    @State private var hasCompletedOnboarding: Bool?
    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository
    private let planGenerator: any GenerateTrainingPlanUseCase
    private let nutritionRepository: any NutritionRepository
    private let nutritionGenerator: any GenerateNutritionPlanUseCase
    private let runRepository: any RunRepository
    private let locationService: LocationService
    private let fitnessRepository: any FitnessRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let appSettingsRepository: any AppSettingsRepository
    private let clearAllDataUseCase: any ClearAllDataUseCase

    init(
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planRepository: any TrainingPlanRepository,
        planGenerator: any GenerateTrainingPlanUseCase,
        nutritionRepository: any NutritionRepository,
        nutritionGenerator: any GenerateNutritionPlanUseCase,
        runRepository: any RunRepository,
        locationService: LocationService,
        fitnessRepository: any FitnessRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        appSettingsRepository: any AppSettingsRepository,
        clearAllDataUseCase: any ClearAllDataUseCase
    ) {
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.planRepository = planRepository
        self.planGenerator = planGenerator
        self.nutritionRepository = nutritionRepository
        self.nutritionGenerator = nutritionGenerator
        self.runRepository = runRepository
        self.locationService = locationService
        self.fitnessRepository = fitnessRepository
        self.fitnessCalculator = fitnessCalculator
        self.finishTimeEstimator = finishTimeEstimator
        self.appSettingsRepository = appSettingsRepository
        self.clearAllDataUseCase = clearAllDataUseCase
    }

    var body: some View {
        Group {
            switch hasCompletedOnboarding {
            case .none:
                ProgressView("Loading...")
            case .some(true):
                MainTabView(
                    athleteRepository: athleteRepository,
                    raceRepository: raceRepository,
                    planRepository: planRepository,
                    planGenerator: planGenerator,
                    nutritionRepository: nutritionRepository,
                    nutritionGenerator: nutritionGenerator,
                    runRepository: runRepository,
                    locationService: locationService,
                    fitnessRepository: fitnessRepository,
                    fitnessCalculator: fitnessCalculator,
                    finishTimeEstimator: finishTimeEstimator,
                    appSettingsRepository: appSettingsRepository,
                    clearAllDataUseCase: clearAllDataUseCase
                )
            case .some(false):
                OnboardingView(
                    athleteRepository: athleteRepository,
                    raceRepository: raceRepository,
                    onComplete: { hasCompletedOnboarding = true }
                )
            }
        }
        .task {
            await checkOnboardingStatus()
        }
    }

    private func checkOnboardingStatus() async {
        do {
            let athlete = try await athleteRepository.getAthlete()
            hasCompletedOnboarding = athlete != nil
        } catch {
            Logger.app.error("Failed to check onboarding status: \(error)")
            hasCompletedOnboarding = false
        }
    }
}
