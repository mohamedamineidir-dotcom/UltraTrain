import SwiftUI
import os

struct AppRootView: View {
    @State private var hasCompletedOnboarding: Bool?
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
        Group {
            switch hasCompletedOnboarding {
            case .none:
                ProgressView("Loading...")
            case .some(true):
                MainTabView(
                    athleteRepository: athleteRepository,
                    raceRepository: raceRepository,
                    planRepository: planRepository,
                    planGenerator: planGenerator
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
