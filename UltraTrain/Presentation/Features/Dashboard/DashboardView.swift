import SwiftUI

struct DashboardView: View {
    @Environment(\.syncStatusMonitor) private var syncStatusMonitor
    @Environment(\.syncService) private var syncService
    @Environment(\.colorScheme) private var colorScheme
    @State var viewModel: DashboardViewModel
    @State private var showSyncQueue = false
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
            locationService: locationService
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .accessibilityLabel("Loading dashboard")
                        .transition(.opacity)
                }

                VStack(spacing: Theme.Spacing.xl) {
                    // Hero card
                    DashboardHeroCard(
                        daysUntilRace: viewModel.daysUntilRace,
                        raceName: viewModel.raceName,
                        currentPhase: viewModel.currentPhase,
                        weeklyProgress: viewModel.weeklyProgress,
                        weeklyDistanceKm: viewModel.weeklyDistanceKm,
                        weeklyTargetDistanceKm: viewModel.weeklyTargetDistanceKm,
                        fitnessStatus: viewModel.fitnessStatusLabel,
                        formDescription: viewModel.formDescription
                    )

                    // Safety alerts
                    if !viewModel.injuryRiskAlerts.isEmpty {
                        InjuryRiskAlertBanner(alerts: viewModel.injuryRiskAlerts)
                    }

                    // Today
                    DashboardSectionHeader(title: "Today")

                    DashboardNextSessionCard(
                        session: viewModel.nextSession,
                        hasPlan: viewModel.plan != nil,
                        currentPhase: viewModel.currentPhase,
                        onStartRun: { selectedTab = .run }
                    )
                    .accessibilityIdentifier("dashboard.nextSessionCard")

                    // This Week
                    DashboardSectionHeader(title: "This Week")

                    DashboardWeeklyStatsCard(
                        progress: viewModel.weeklyProgress,
                        distanceKm: viewModel.weeklyDistanceKm,
                        elevationM: viewModel.weeklyElevationM,
                        targetDistanceKm: viewModel.weeklyTargetDistanceKm,
                        targetElevationM: viewModel.weeklyTargetElevationM,
                        weeksUntilRace: viewModel.weeksUntilRace
                    )
                    .accessibilityIdentifier("dashboard.weeklyStatsCard")

                    LastRunCard(lastRun: viewModel.lastRun)

                    DashboardWeatherCard(
                        currentWeather: viewModel.currentWeather,
                        sessionForecast: viewModel.sessionForecast,
                        sessionDate: viewModel.nextSession?.date,
                        isLoading: viewModel.isLoading
                    )

                    // Your Race
                    DashboardSectionHeader(title: "Your Race")

                    finishEstimateSection
                    UpcomingRacesCard(races: viewModel.upcomingRaces)

                    // Recovery
                    DashboardSectionHeader(title: "Recovery")
                    recoveryLink
                }
                .padding()
            }
            .background(dashboardBackground)
            .navigationTitle("Dashboard")
            .toolbar {
                if let monitor = syncStatusMonitor, monitor.isVisible {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSyncQueue = true
                        } label: {
                            SyncStatusBadge(
                                pendingCount: monitor.pendingCount,
                                failedCount: monitor.failedCount,
                                isSyncing: monitor.isSyncing
                            )
                        }
                        .accessibilityHint("View sync queue details")
                    }
                }
            }
            .navigationDestination(isPresented: $showSyncQueue) {
                if let svc = syncService {
                    SyncQueueView(syncService: svc)
                }
            }
            .task {
                await viewModel.load()
                await syncStatusMonitor?.refresh()
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .alert("Error", isPresented: Binding(
                get: { viewModel.fitnessError != nil },
                set: { if !$0 { viewModel.fitnessError = nil } }
            )) {
                Button("OK") { viewModel.fitnessError = nil }
            } message: {
                Text(viewModel.fitnessError ?? "")
            }
        }
    }

    private var dashboardBackground: some View {
        Theme.Gradients.futuristicBackground(colorScheme: colorScheme)
            .ignoresSafeArea()
    }
}
