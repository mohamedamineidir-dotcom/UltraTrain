import SwiftUI

// MARK: - NavigationLink Wrappers & Sections

extension DashboardView {

    // MARK: - Goal History Link

    var goalHistoryLink: some View {
        NavigationLink {
            GoalHistoryView(
                goalRepository: goalRepository,
                runRepository: runRepository,
                athleteRepository: athleteRepository
            )
        } label: {
            HStack {
                Label("Goal History", systemImage: "chart.bar")
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(Theme.Colors.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
    }

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
                sleepHistory: viewModel.sleepHistory,
                readinessScore: viewModel.readinessScore,
                hrvTrend: viewModel.hrvTrend
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard.recoveryCard")
        .accessibilityHint("Opens morning readiness check")
    }

    // MARK: - Challenge Link

    var challengeLink: some View {
        NavigationLink {
            ChallengesView(
                challengeRepository: challengeRepository,
                runRepository: runRepository,
                athleteRepository: athleteRepository
            )
        } label: {
            DashboardChallengeCard(
                currentStreak: viewModel.currentStreak,
                nearestProgress: viewModel.nearestChallengeProgress
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens challenges view")
    }

    // MARK: - Achievement Link

    @ViewBuilder
    var achievementLink: some View {
        if let achievementRepo = achievementRepository {
            NavigationLink {
                AchievementsView(
                    achievementRepository: achievementRepo,
                    runRepository: runRepository,
                    challengeRepository: challengeRepository,
                    raceRepository: raceRepository
                )
            } label: {
                DashboardAchievementsCard()
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens achievements view")
        }
    }

    // MARK: - Personal Records Link

    @ViewBuilder
    var personalRecordsLink: some View {
        if !viewModel.personalRecords.isEmpty {
            NavigationLink {
                PersonalRecordsWallView(records: viewModel.personalRecords)
            } label: {
                DashboardPersonalRecordsCard(records: viewModel.personalRecords)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens personal records wall")
        }
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

    // MARK: - Fitness Section

    var fitnessSection: some View {
        DashboardFitnessCard(
            snapshot: viewModel.fitnessSnapshot,
            fitnessStatus: viewModel.fitnessStatus,
            formDescription: viewModel.formDescription,
            fitnessHistory: viewModel.recentFormHistory,
            onSeeTrend: { showFitnessTrend = true }
        )
        .accessibilityIdentifier("dashboard.fitnessCard")
    }

    // MARK: - Progress Section

    var progressSection: some View {
        NavigationLink {
            TrainingProgressView(
                runRepository: runRepository,
                athleteRepository: athleteRepository,
                planRepository: planRepository,
                raceRepository: raceRepository,
                fitnessCalculator: fitnessCalculator,
                fitnessRepository: fitnessRepository,
                trainingLoadCalculator: trainingLoadCalculator
            )
        } label: {
            DashboardProgressCard(runCount: viewModel.runCount)
        }
        .accessibilityHint("Opens detailed training progress view")
    }
}
