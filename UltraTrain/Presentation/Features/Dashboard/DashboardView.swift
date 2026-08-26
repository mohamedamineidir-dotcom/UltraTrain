import SwiftUI

struct DashboardView: View {
    @Environment(\.syncStatusMonitor) private var syncStatusMonitor
    @Environment(\.syncService) private var syncService
    @Environment(\.colorScheme) private var colorScheme
    @State var viewModel: DashboardViewModel
    @State private var showSyncQueue = false
    @State private var showValidateSession = false
    @State private var showSkipSession = false
    @State private var validateRecentRuns: [CompletedRun] = []
    /// Race selected from the "Upcoming Races" card. Drives a
    /// navigationDestination push to FinishEstimationView so the
    /// athlete can open the race predictor straight from the
    /// dashboard, same as from the Profile section.
    @State private var selectedUpcomingRace: Race?
    @State private var showUpcomingRacePredictor = false
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

                    // Race forecast — the app's key feature, surfaced right
                    // under the hero card so it's visible without scrolling,
                    // rather than buried at the bottom of the dashboard.
                    finishEstimateSection
                    UpcomingRacesCard(races: viewModel.upcomingRaces) { race in
                        selectedUpcomingRace = race
                        showUpcomingRacePredictor = true
                    }

                    // Today
                    SectionHeader(title: "Today")

                    DashboardNextSessionCard(
                        session: viewModel.nextSession,
                        hasPlan: viewModel.plan != nil,
                        currentPhase: viewModel.currentPhase,
                        onStartRun: { selectedTab = .run },
                        onValidate: viewModel.nextSession == nil ? nil : {
                            Task {
                                if let session = viewModel.nextSession {
                                    validateRecentRuns = await viewModel.recentUnlinkedRuns(near: session.date)
                                }
                                showValidateSession = true
                            }
                        },
                        onSkip: viewModel.nextSession == nil ? nil : {
                            showSkipSession = true
                        }
                    )
                    .accessibilityIdentifier("dashboard.nextSessionCard")

                    // This Week
                    SectionHeader(title: "This Week")

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

                    // Weather card intentionally removed from the
                    // dashboard, generic "current conditions" without
                    // a session attached to it didn't drive useful
                    // decisions for the athlete; per-session weather
                    // still surfaces on the run-tracking screen and
                    // session detail. WeatherService is still wired in
                    // so the race-day forecast card on the finish
                    // estimate page keeps working.

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
            .navigationDestination(isPresented: $showUpcomingRacePredictor) {
                if let race = selectedUpcomingRace {
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
                }
            }
            .sheet(isPresented: $showValidateSession) {
                if let session = viewModel.nextSession {
                    SessionValidationView(
                        session: session,
                        recentRuns: validateRecentRuns,
                        onComplete: { dist, dur, elev, feeling, rpe in
                            Task {
                                await viewModel.completeNextSessionManually(
                                    distanceKm: dist,
                                    durationSeconds: dur,
                                    elevationGainM: elev,
                                    feeling: feeling,
                                    exertion: rpe
                                )
                            }
                        },
                        onLinkRun: { runId in
                            Task { await viewModel.linkNextSessionToRun(runId: runId) }
                        },
                        recentRunsProvider: { date in
                            await viewModel.recentUnlinkedRuns(near: date)
                        }
                    )
                }
            }
            .sheet(isPresented: $showSkipSession) {
                if let session = viewModel.nextSession {
                    SkipReasonSheet(sessionType: session.type) { reason in
                        Task { await viewModel.skipNextSession(reason: reason) }
                    }
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
