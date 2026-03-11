import SwiftUI

// MARK: - NavigationLink Wrappers & Sections

extension DashboardView {

    // MARK: - Recovery Link

    var recoveryLink: some View {
        NavigationLink {
            MorningReadinessView(
                healthKitService: healthKitService,
                recoveryRepository: recoveryRepository,
                fitnessCalculator: fitnessCalculator,
                fitnessRepository: fitnessRepository,
                morningCheckInRepository: morningCheckInRepository
            )
        } label: {
            DashboardRecoveryCard(
                recoveryScore: viewModel.recoveryScore,
                readinessScore: viewModel.readinessScore
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard.recoveryCard")
        .accessibilityHint("Opens morning readiness check")
    }

    // MARK: - Finish Estimate Section

    @ViewBuilder
    var finishEstimateSection: some View {
        if let estimate = viewModel.finishEstimate, let race = viewModel.aRace {
            NavigationLink {
                FinishEstimationView(
                    race: race,
                    finishTimeEstimator: finishTimeEstimator,
                    athleteRepository: athleteRepository,
                    runRepository: runRepository,
                    fitnessCalculator: fitnessCalculator,
                    nutritionRepository: nutritionRepository,
                    nutritionGenerator: nutritionGenerator,
                    raceRepository: raceRepository,
                    finishEstimateRepository: finishEstimateRepository,
                    weatherService: weatherService,
                    locationService: locationService,
                    checklistRepository: checklistRepository
                )
            } label: {
                DashboardFinishEstimateCard(estimate: estimate, race: race)
            }
            .accessibilityHint("Opens detailed finish time estimation")
        }
    }

}
