import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var showFitnessTrend = false
    @State private var showGoalSetting = false
    @Binding var selectedTab: Tab

    private let planRepository: any TrainingPlanRepository
    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository
    private let fitnessRepository: any FitnessRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let trainingLoadCalculator: any CalculateTrainingLoadUseCase
    private let raceRepository: any RaceRepository
    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let finishEstimateRepository: any FinishEstimateRepository
    private let nutritionRepository: any NutritionRepository
    private let nutritionGenerator: any GenerateNutritionPlanUseCase
    private let healthKitService: any HealthKitServiceProtocol
    private let recoveryRepository: any RecoveryRepository
    private let checklistRepository: any RacePrepChecklistRepository
    private let weatherService: (any WeatherServiceProtocol)?
    private let locationService: LocationService
    private let challengeRepository: any ChallengeRepository
    private let goalRepository: any GoalRepository

    init(
        selectedTab: Binding<Tab>,
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository,
        fitnessRepository: any FitnessRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        trainingLoadCalculator: any CalculateTrainingLoadUseCase,
        raceRepository: any RaceRepository,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        finishEstimateRepository: any FinishEstimateRepository,
        nutritionRepository: any NutritionRepository,
        nutritionGenerator: any GenerateNutritionPlanUseCase,
        healthKitService: any HealthKitServiceProtocol,
        recoveryRepository: any RecoveryRepository,
        checklistRepository: any RacePrepChecklistRepository,
        weatherService: (any WeatherServiceProtocol)? = nil,
        locationService: LocationService,
        challengeRepository: any ChallengeRepository,
        goalRepository: any GoalRepository
    ) {
        _selectedTab = selectedTab
        self.planRepository = planRepository
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
        self.fitnessRepository = fitnessRepository
        self.fitnessCalculator = fitnessCalculator
        self.trainingLoadCalculator = trainingLoadCalculator
        self.raceRepository = raceRepository
        self.finishTimeEstimator = finishTimeEstimator
        self.finishEstimateRepository = finishEstimateRepository
        self.nutritionRepository = nutritionRepository
        self.nutritionGenerator = nutritionGenerator
        self.healthKitService = healthKitService
        self.recoveryRepository = recoveryRepository
        self.checklistRepository = checklistRepository
        self.weatherService = weatherService
        self.locationService = locationService
        self.challengeRepository = challengeRepository
        self.goalRepository = goalRepository
        _viewModel = State(initialValue: DashboardViewModel(
            planRepository: planRepository,
            runRepository: runRepository,
            athleteRepository: athleteRepository,
            fitnessRepository: fitnessRepository,
            fitnessCalculator: fitnessCalculator,
            raceRepository: raceRepository,
            finishTimeEstimator: finishTimeEstimator,
            finishEstimateRepository: finishEstimateRepository,
            healthKitService: healthKitService,
            recoveryRepository: recoveryRepository,
            weatherService: weatherService,
            locationService: locationService,
            challengeRepository: challengeRepository,
            goalRepository: goalRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    if !viewModel.injuryRiskAlerts.isEmpty {
                        InjuryRiskAlertBanner(alerts: viewModel.injuryRiskAlerts)
                    }

                    if !viewModel.coachingInsights.isEmpty {
                        CoachingInsightCard(insights: viewModel.coachingInsights)
                    }

                    DashboardNextSessionCard(
                        session: viewModel.nextSession,
                        hasPlan: viewModel.plan != nil,
                        currentPhase: viewModel.currentPhase,
                        onStartRun: { selectedTab = .run }
                    )

                    DashboardWeatherCard(
                        currentWeather: viewModel.currentWeather,
                        sessionForecast: viewModel.sessionForecast,
                        sessionDate: viewModel.nextSession?.date,
                        isLoading: viewModel.isLoading
                    )

                    DashboardWeeklyStatsCard(
                        progress: viewModel.weeklyProgress,
                        distanceKm: viewModel.weeklyDistanceKm,
                        elevationM: viewModel.weeklyElevationM,
                        targetDistanceKm: viewModel.weeklyTargetDistanceKm,
                        targetElevationM: viewModel.weeklyTargetElevationM,
                        weeksUntilRace: viewModel.weeksUntilRace
                    )

                    DashboardGoalProgressCard(
                        weeklyProgress: viewModel.weeklyGoalProgress,
                        monthlyProgress: viewModel.monthlyGoalProgress,
                        onSetGoal: { showGoalSetting = true }
                    )

                    DashboardZoneDistributionCard(
                        distribution: viewModel.weeklyZoneDistribution
                    )

                    DashboardRecoveryCard(
                        recoveryScore: viewModel.recoveryScore,
                        sleepHistory: viewModel.sleepHistory
                    )

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

                    if !viewModel.personalRecords.isEmpty {
                        NavigationLink {
                            PersonalRecordsWallView(records: viewModel.personalRecords)
                        } label: {
                            DashboardPersonalRecordsCard(records: viewModel.personalRecords)
                        }
                        .buttonStyle(.plain)
                    }

                    LastRunCard(lastRun: viewModel.lastRun)

                    finishEstimateSection

                    fitnessSection

                    UpcomingRacesCard(races: viewModel.upcomingRaces)

                    progressSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationDestination(isPresented: $showFitnessTrend) {
                FitnessTrendView(
                    snapshots: viewModel.fitnessHistory,
                    currentSnapshot: viewModel.fitnessSnapshot
                )
            }
            .task {
                await viewModel.load()
            }
            .sheet(isPresented: $showGoalSetting) {
                GoalSettingView(goalRepository: goalRepository) {
                    Task { await viewModel.load() }
                }
            }
        }
    }

    // MARK: - NavigationLink Wrappers

    @ViewBuilder
    private var finishEstimateSection: some View {
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
        }
    }

    private var fitnessSection: some View {
        DashboardFitnessCard(
            snapshot: viewModel.fitnessSnapshot,
            fitnessStatus: viewModel.fitnessStatus,
            formDescription: viewModel.formDescription,
            fitnessHistory: viewModel.recentFormHistory,
            onSeeTrend: { showFitnessTrend = true }
        )
    }

    private var progressSection: some View {
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
    }
}
