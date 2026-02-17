import SwiftUI
import SwiftData

@main
struct UltraTrainApp: App {
    private let modelContainer: ModelContainer
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
    private let healthKitService: HealthKitService
    private let hapticService: HapticService
    private let trainingLoadCalculator: TrainingLoadCalculator
    private let sessionNutritionAdvisor: any SessionNutritionAdvisor

    init() {
        do {
            let schema = Schema([
                AthleteSwiftDataModel.self,
                RaceSwiftDataModel.self,
                CheckpointSwiftDataModel.self,
                TrainingPlanSwiftDataModel.self,
                TrainingWeekSwiftDataModel.self,
                TrainingSessionSwiftDataModel.self,
                NutritionPlanSwiftDataModel.self,
                NutritionEntrySwiftDataModel.self,
                NutritionProductSwiftDataModel.self,
                CompletedRunSwiftDataModel.self,
                SplitSwiftDataModel.self,
                FitnessSnapshotSwiftDataModel.self,
                AppSettingsSwiftDataModel.self,
                NutritionPreferencesSwiftDataModel.self
            ])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        athleteRepository = LocalAthleteRepository(modelContainer: modelContainer)
        raceRepository = LocalRaceRepository(modelContainer: modelContainer)
        planRepository = LocalTrainingPlanRepository(modelContainer: modelContainer)
        planGenerator = TrainingPlanGenerator()
        nutritionRepository = LocalNutritionRepository(modelContainer: modelContainer)
        nutritionGenerator = NutritionPlanGenerator()
        runRepository = LocalRunRepository(modelContainer: modelContainer)
        locationService = LocationService()
        fitnessRepository = LocalFitnessRepository(modelContainer: modelContainer)
        fitnessCalculator = FitnessCalculator()
        finishTimeEstimator = FinishTimeEstimator()
        appSettingsRepository = LocalAppSettingsRepository(modelContainer: modelContainer)
        clearAllDataUseCase = DataCleaner(modelContainer: modelContainer)
        healthKitService = HealthKitService()
        hapticService = HapticService()
        trainingLoadCalculator = TrainingLoadCalculator()
        sessionNutritionAdvisor = DefaultSessionNutritionAdvisor()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
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
                clearAllDataUseCase: clearAllDataUseCase,
                healthKitService: healthKitService,
                hapticService: hapticService,
                trainingLoadCalculator: trainingLoadCalculator,
                sessionNutritionAdvisor: sessionNutritionAdvisor
            )
        }
    }
}
