import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository
    private let planGenerator: any GenerateTrainingPlanUseCase

    init(
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planRepository: any TrainingPlanRepository,
        planGenerator: any GenerateTrainingPlanUseCase
    ) {
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.planRepository = planRepository
        self.planGenerator = planGenerator
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(planRepository: planRepository)
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

            RunTrackingLaunchView()
                .tabItem {
                    Label("Run", systemImage: "figure.run")
                }
                .tag(Tab.run)

            NutritionView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
                .tag(Tab.nutrition)

            ProfileView()
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
