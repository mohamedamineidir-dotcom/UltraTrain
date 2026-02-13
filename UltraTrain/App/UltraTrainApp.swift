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

    init() {
        do {
            let schema = Schema([
                AthleteSwiftDataModel.self,
                RaceSwiftDataModel.self,
                TrainingPlanSwiftDataModel.self,
                TrainingWeekSwiftDataModel.self,
                TrainingSessionSwiftDataModel.self,
                NutritionPlanSwiftDataModel.self,
                NutritionEntrySwiftDataModel.self,
                NutritionProductSwiftDataModel.self,
                CompletedRunSwiftDataModel.self,
                SplitSwiftDataModel.self
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
                locationService: locationService
            )
        }
    }
}
