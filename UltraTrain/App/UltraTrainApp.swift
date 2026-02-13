import SwiftUI
import SwiftData

@main
struct UltraTrainApp: App {
    private let modelContainer: ModelContainer
    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository
    private let planGenerator: any GenerateTrainingPlanUseCase

    init() {
        do {
            let schema = Schema([
                AthleteSwiftDataModel.self,
                RaceSwiftDataModel.self,
                TrainingPlanSwiftDataModel.self,
                TrainingWeekSwiftDataModel.self,
                TrainingSessionSwiftDataModel.self
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
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                planRepository: planRepository,
                planGenerator: planGenerator
            )
        }
    }
}
