import SwiftUI

struct TrainingPlanView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(PremiumGate.self) private var premiumGate: PremiumGate?
    @State var viewModel: TrainingPlanViewModel
    /// Index into `phaseGroups` for the phase whose weeks are currently
    /// rendered below the charts. Initialised to the phase containing
    /// today on first appear of each loaded plan via .task(id:).
    @State var selectedPhaseIndex: Int = 0
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository
    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository
    private let subscriptionService: (any SubscriptionServiceProtocol)?
    private let stravaAuthService: (any StravaAuthServiceProtocol)?
    private let stravaImportService: (any StravaImportServiceProtocol)?

    init(
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planGenerator: any GenerateTrainingPlanUseCase,
        nutritionRepository: any NutritionRepository,
        sessionNutritionAdvisor: any SessionNutritionAdvisor,
        fitnessRepository: any FitnessRepository,
        widgetDataWriter: WidgetDataWriter,
        runRepository: any RunRepository,
        hapticService: any HapticServiceProtocol = HapticService(),
        subscriptionService: (any SubscriptionServiceProtocol)? = nil,
        stravaAuthService: (any StravaAuthServiceProtocol)? = nil,
        stravaImportService: (any StravaImportServiceProtocol)? = nil,
        intervalPerformanceRepository: (any IntervalPerformanceRepository)? = nil,
        notificationService: (any NotificationServiceProtocol)? = nil,
        appSettingsRepository: (any AppSettingsRepository)? = nil,
        recoveryRepository: (any RecoveryRepository)? = nil
    ) {
        self.raceRepository = raceRepository
        self.planRepository = planRepository
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
        self.subscriptionService = subscriptionService
        self.stravaAuthService = stravaAuthService
        self.stravaImportService = stravaImportService
        _viewModel = State(initialValue: TrainingPlanViewModel(
            planRepository: planRepository,
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            planGenerator: planGenerator,
            nutritionRepository: nutritionRepository,
            nutritionAdvisor: sessionNutritionAdvisor,
            fitnessRepository: fitnessRepository,
            widgetDataWriter: widgetDataWriter,
            hapticService: hapticService,
            subscriptionService: subscriptionService,
            runRepository: runRepository,
            stravaAuthService: stravaAuthService,
            stravaImportService: stravaImportService,
            intervalPerformanceRepository: intervalPerformanceRepository,
            notificationService: notificationService,
            appSettingsRepository: appSettingsRepository,
            recoveryRepository: recoveryRepository
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isGenerating {
                    PlanGenerationLoadingView()
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.isCustomPlanLocked, let plan = viewModel.plan {
                    LockedCustomPlanView(
                        weekCount: plan.weeks.count,
                        planName: viewModel.targetRace?.name,
                        onResubscribe: { premiumGate?.presentPaywall() },
                        onStartFreePlan: { viewModel.showPlanScenarioSheet = true }
                    )
                } else if let plan = viewModel.plan {
                    planContent(plan)
                } else {
                    emptyState
                }
            }
            .background(Theme.Gradients.futuristicBackground(colorScheme: colorScheme).ignoresSafeArea())
            .navigationTitle("Training Plan")
            .toolbar {
                if let plan = viewModel.plan {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: Theme.Spacing.sm) {
                            NavigationLink {
                                RaceCalendarView(
                                    plan: plan,
                                    races: viewModel.races
                                )
                            } label: {
                                Image(systemName: "list.bullet")
                            }
                            .accessibilityLabel("Plan timeline")

                            NavigationLink {
                                RaceCalendarGridView(
                                    raceRepository: raceRepository,
                                    planRepository: planRepository
                                )
                            } label: {
                                Image(systemName: "calendar")
                            }
                            .accessibilityLabel("Calendar")
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isGenerating)
            .task {
                await viewModel.loadPlan()
            }
            .onChange(of: premiumGate?.isUnlocked) { _, _ in
                // Tier flipped (subscribed / cancelled) while on this tab,
                // re-resolve which plan is active + its lock state.
                Task { await viewModel.loadPlan() }
            }
            .onAppear {
                Task { await viewModel.refreshRaces() }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .confirmationDialog(
                "Update Training Plan",
                isPresented: $viewModel.showRegenerateConfirmation,
                titleVisibility: .visible
            ) {
                Button("Update Plan") {
                    Task { await viewModel.prepareToGeneratePlan() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(regenerateDialogMessage)
            }
            .sheet(isPresented: $viewModel.showPlanOptionsSheet) {
                if let athlete = viewModel.planOptionsSheetAthlete,
                   let race = viewModel.planOptionsSheetTargetRace {
                    PlanGenerationOptionsSheet(
                        targetRace: race,
                        athlete: athlete,
                        planTotalWeeks: viewModel.planOptionsSheetTotalWeeks,
                        raceRepository: raceRepository,
                        onGenerate: { options in
                            Task { await viewModel.generatePlanWithOptions(options) }
                        },
                        onCancel: { viewModel.showPlanOptionsSheet = false }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showPlanScenarioSheet) {
                PlanScenarioPickerSheet { scenario in
                    Task { await viewModel.generateScenarioPlan(scenario) }
                }
            }
            .sheet(item: $viewModel.fitnessTestRecommendation) { recommendation in
                FitnessTestResultBanner(
                    recommendation: recommendation,
                    onDismiss: { viewModel.fitnessTestRecommendation = nil }
                )
            }
        }
    }
}
