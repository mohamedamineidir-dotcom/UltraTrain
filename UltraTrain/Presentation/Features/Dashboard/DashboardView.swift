import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var showFitnessTrend = false
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
        nutritionGenerator: any GenerateNutritionPlanUseCase
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
        _viewModel = State(initialValue: DashboardViewModel(
            planRepository: planRepository,
            runRepository: runRepository,
            athleteRepository: athleteRepository,
            fitnessRepository: fitnessRepository,
            fitnessCalculator: fitnessCalculator,
            raceRepository: raceRepository,
            finishTimeEstimator: finishTimeEstimator,
            finishEstimateRepository: finishEstimateRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    if !viewModel.injuryRiskAlerts.isEmpty {
                        InjuryRiskAlertBanner(alerts: viewModel.injuryRiskAlerts)
                    }

                    DashboardNextSessionCard(
                        session: viewModel.nextSession,
                        hasPlan: viewModel.plan != nil,
                        currentPhase: viewModel.currentPhase,
                        onStartRun: { selectedTab = .run }
                    )

                    DashboardWeeklyStatsCard(
                        progress: viewModel.weeklyProgress,
                        distanceKm: viewModel.weeklyDistanceKm,
                        elevationM: viewModel.weeklyElevationM,
                        targetDistanceKm: viewModel.weeklyTargetDistanceKm,
                        targetElevationM: viewModel.weeklyTargetElevationM,
                        weeksUntilRace: viewModel.weeksUntilRace
                    )

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
                    finishEstimateRepository: finishEstimateRepository
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
