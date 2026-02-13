import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

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
        finishTimeEstimator: any EstimateFinishTimeUseCase
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
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                planRepository: planRepository,
                runRepository: runRepository,
                athleteRepository: athleteRepository,
                fitnessRepository: fitnessRepository,
                fitnessCalculator: fitnessCalculator
            )
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)

            TrainingPlanView(
                planRepository: planRepository,
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                planGenerator: planGenerator
            )
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
                .tag(Tab.plan)

            RunTrackingLaunchView(
                athleteRepository: athleteRepository,
                planRepository: planRepository,
                runRepository: runRepository,
                locationService: locationService
            )
                .tabItem {
                    Label("Run", systemImage: "figure.run")
                }
                .tag(Tab.run)

            NutritionView(
                nutritionRepository: nutritionRepository,
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                planRepository: planRepository,
                nutritionGenerator: nutritionGenerator
            )
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
                .tag(Tab.nutrition)

            ProfileView(
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                runRepository: runRepository,
                fitnessCalculator: fitnessCalculator,
                finishTimeEstimator: finishTimeEstimator
            )
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
    }
}

enum Tab: Hashable {
    case dashboard
    case plan
    case run
    case nutrition
    case profile
}
