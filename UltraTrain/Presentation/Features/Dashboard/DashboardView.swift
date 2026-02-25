import SwiftUI

struct DashboardView: View {
    @Environment(\.syncStatusMonitor) private var syncStatusMonitor
    @State var viewModel: DashboardViewModel
    @State var showFitnessTrend = false
    @State private var showGoalSetting = false
    @Binding var selectedTab: Tab

    let planRepository: any TrainingPlanRepository
    let runRepository: any RunRepository
    let athleteRepository: any AthleteRepository
    let fitnessRepository: any FitnessRepository
    let fitnessCalculator: any CalculateFitnessUseCase
    let trainingLoadCalculator: any CalculateTrainingLoadUseCase
    let raceRepository: any RaceRepository
    let finishTimeEstimator: any EstimateFinishTimeUseCase
    let finishEstimateRepository: any FinishEstimateRepository
    let nutritionRepository: any NutritionRepository
    let nutritionGenerator: any GenerateNutritionPlanUseCase
    let healthKitService: any HealthKitServiceProtocol
    let recoveryRepository: any RecoveryRepository
    let checklistRepository: any RacePrepChecklistRepository
    let weatherService: (any WeatherServiceProtocol)?
    let locationService: LocationService
    let challengeRepository: any ChallengeRepository
    let goalRepository: any GoalRepository
    let achievementRepository: (any AchievementRepository)?
    let morningCheckInRepository: (any MorningCheckInRepository)?

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
        goalRepository: any GoalRepository,
        achievementRepository: (any AchievementRepository)? = nil,
        morningCheckInRepository: (any MorningCheckInRepository)? = nil
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
        self.achievementRepository = achievementRepository
        self.morningCheckInRepository = morningCheckInRepository
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
                LazyVStack(spacing: Theme.Spacing.md) {
                    if !viewModel.injuryRiskAlerts.isEmpty {
                        InjuryRiskAlertBanner(alerts: viewModel.injuryRiskAlerts)
                    }

                    if !viewModel.coachingInsights.isEmpty {
                        CoachingInsightCard(insights: viewModel.coachingInsights)
                    }

                    if let optimalSession = viewModel.optimalSession {
                        OptimalSessionCard(session: optimalSession)
                    }

                    if !viewModel.fatiguePatterns.isEmpty {
                        FatigueAlertCard(patterns: viewModel.fatiguePatterns)
                    }

                    DashboardNextSessionCard(
                        session: viewModel.nextSession,
                        hasPlan: viewModel.plan != nil,
                        currentPhase: viewModel.currentPhase,
                        onStartRun: { selectedTab = .run }
                    )
                    .accessibilityIdentifier("dashboard.nextSessionCard")

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
                    .accessibilityIdentifier("dashboard.weeklyStatsCard")

                    DashboardGoalProgressCard(
                        weeklyProgress: viewModel.weeklyGoalProgress,
                        monthlyProgress: viewModel.monthlyGoalProgress,
                        onSetGoal: { showGoalSetting = true }
                    )

                    goalHistoryLink

                    DashboardZoneDistributionCard(
                        distribution: viewModel.weeklyZoneDistribution
                    )

                    recoveryLink

                    challengeLink

                    achievementLink

                    personalRecordsLink

                    LastRunCard(lastRun: viewModel.lastRun)

                    finishEstimateSection

                    fitnessSection

                    if !viewModel.performanceTrends.isEmpty {
                        ForEach(viewModel.performanceTrends) { trend in
                            PerformanceTrendSparkline(trend: trend)
                        }
                    }

                    UpcomingRacesCard(races: viewModel.upcomingRaces)
                        .accessibilityIdentifier("dashboard.upcomingRacesCard")

                    progressSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                if let monitor = syncStatusMonitor, monitor.isVisible {
                    ToolbarItem(placement: .topBarTrailing) {
                        SyncStatusBadge(
                            pendingCount: monitor.pendingCount,
                            failedCount: monitor.failedCount,
                            isSyncing: monitor.isSyncing
                        )
                    }
                }
            }
            .navigationDestination(isPresented: $showFitnessTrend) {
                FitnessTrendView(
                    snapshots: viewModel.fitnessHistory,
                    currentSnapshot: viewModel.fitnessSnapshot
                )
            }
            .task {
                await viewModel.load()
                await syncStatusMonitor?.refresh()
            }
            .sheet(isPresented: $showGoalSetting) {
                GoalSettingView(goalRepository: goalRepository) {
                    Task { await viewModel.load() }
                }
            }
        }
    }
}
