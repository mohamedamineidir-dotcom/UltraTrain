import SwiftUI

struct RunTrackingLaunchView: View {
    @ScaledMetric(relativeTo: .largeTitle) var heroIconSize: CGFloat = 60
    @State var viewModel: RunTrackingLaunchViewModel
    @State var showCrossTrainingSheet = false
    let athleteRepository: any AthleteRepository
    let locationService: LocationService
    private let healthKitService: any HealthKitServiceProtocol
    let runRepository: any RunRepository
    let planRepository: any TrainingPlanRepository
    let raceRepository: any RaceRepository
    private let nutritionRepository: any NutritionRepository
    private let hapticService: any HapticServiceProtocol
    private let connectivityService: PhoneConnectivityService?
    private let widgetDataWriter: WidgetDataWriter?
    let exportService: any ExportServiceProtocol
    let runImportUseCase: any RunImportUseCase
    let stravaUploadService: (any StravaUploadServiceProtocol)?
    let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    let stravaImportService: (any StravaImportServiceProtocol)?
    let stravaAuthService: any StravaAuthServiceProtocol
    let gearRepository: any GearRepository
    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    let finishEstimateRepository: any FinishEstimateRepository
    private let weatherService: (any WeatherServiceProtocol)?
    private let recoveryRepository: any RecoveryRepository
    private let intervalWorkoutRepository: (any IntervalWorkoutRepository)?
    private let emergencyContactRepository: (any EmergencyContactRepository)?
    private let motionService: (any MotionServiceProtocol)?

    init(
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        raceRepository: any RaceRepository,
        locationService: LocationService,
        healthKitService: any HealthKitServiceProtocol,
        appSettingsRepository: any AppSettingsRepository,
        nutritionRepository: any NutritionRepository,
        hapticService: any HapticServiceProtocol,
        connectivityService: PhoneConnectivityService? = nil,
        widgetDataWriter: WidgetDataWriter? = nil,
        exportService: any ExportServiceProtocol,
        runImportUseCase: any RunImportUseCase,
        stravaUploadService: (any StravaUploadServiceProtocol)? = nil,
        stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)? = nil,
        stravaImportService: (any StravaImportServiceProtocol)? = nil,
        stravaAuthService: any StravaAuthServiceProtocol,
        gearRepository: any GearRepository,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        finishEstimateRepository: any FinishEstimateRepository,
        weatherService: (any WeatherServiceProtocol)? = nil,
        recoveryRepository: any RecoveryRepository,
        intervalWorkoutRepository: (any IntervalWorkoutRepository)? = nil,
        emergencyContactRepository: (any EmergencyContactRepository)? = nil,
        motionService: (any MotionServiceProtocol)? = nil
    ) {
        _viewModel = State(initialValue: RunTrackingLaunchViewModel(
            athleteRepository: athleteRepository,
            planRepository: planRepository,
            runRepository: runRepository,
            raceRepository: raceRepository,
            appSettingsRepository: appSettingsRepository,
            hapticService: hapticService,
            gearRepository: gearRepository,
            finishTimeEstimator: finishTimeEstimator,
            finishEstimateRepository: finishEstimateRepository,
            weatherService: weatherService,
            locationService: locationService,
            healthKitService: healthKitService,
            recoveryRepository: recoveryRepository,
            intervalWorkoutRepository: intervalWorkoutRepository
        ))
        self.athleteRepository = athleteRepository
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.raceRepository = raceRepository
        self.nutritionRepository = nutritionRepository
        self.hapticService = hapticService
        self.connectivityService = connectivityService
        self.widgetDataWriter = widgetDataWriter
        self.exportService = exportService
        self.runImportUseCase = runImportUseCase
        self.stravaUploadService = stravaUploadService
        self.stravaUploadQueueService = stravaUploadQueueService
        self.stravaImportService = stravaImportService
        self.stravaAuthService = stravaAuthService
        self.gearRepository = gearRepository
        self.finishTimeEstimator = finishTimeEstimator
        self.finishEstimateRepository = finishEstimateRepository
        self.weatherService = weatherService
        self.recoveryRepository = recoveryRepository
        self.intervalWorkoutRepository = intervalWorkoutRepository
        self.emergencyContactRepository = emergencyContactRepository
        self.motionService = motionService
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    locationAuthSection
                    heroSection
                    PreRunWeatherCard(
                        weather: viewModel.preRunWeather,
                        isLoading: viewModel.isLoading
                    )
                    .padding(.horizontal, Theme.Spacing.md)
                    if let briefing = viewModel.preRunBriefing {
                        PreRunBriefingCard(briefing: briefing)
                            .padding(.horizontal, Theme.Spacing.md)
                    }
                    if let race = viewModel.todaysRace {
                        raceDayBanner(race: race)
                    }
                    if !viewModel.todaysSessions.isEmpty {
                        SessionPickerView(
                            sessions: viewModel.todaysSessions,
                            selectedSession: $viewModel.selectedSession
                        )
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                    if viewModel.selectedSession?.isGutTrainingRecommended == true {
                        gutTrainingBanner
                    }
                    if !viewModel.activeGear.isEmpty {
                        GearPickerView(
                            gearItems: viewModel.activeGear,
                            selectedGearIds: $viewModel.selectedGearIds
                        )
                    }
                    startButton
                    crossTrainingButton
                    historyLink
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .navigationTitle("Run")
            .task { await viewModel.load() }
            .onChange(of: viewModel.showActiveRun) { _, isShowing in
                if !isShowing {
                    viewModel.onRunSaved()
                }
            }
            .navigationDestination(isPresented: $viewModel.showActiveRun) {
                if let athlete = viewModel.athlete {
                    ActiveRunView(
                        viewModel: ActiveRunViewModel(
                            locationService: locationService,
                            healthKitService: healthKitService,
                            runRepository: runRepository,
                            planRepository: planRepository,
                            raceRepository: raceRepository,
                            nutritionRepository: nutritionRepository,
                            hapticService: hapticService,
                            connectivityService: connectivityService,
                            widgetDataWriter: widgetDataWriter,
                            stravaUploadQueueService: stravaUploadQueueService,
                            gearRepository: gearRepository,
                            finishEstimateRepository: finishEstimateRepository,
                            weatherService: weatherService,
                            athlete: athlete,
                            linkedSession: viewModel.selectedSession,
                            autoPauseEnabled: viewModel.autoPauseEnabled,
                            nutritionRemindersEnabled: viewModel.nutritionRemindersEnabled,
                            nutritionAlertSoundEnabled: viewModel.nutritionAlertSoundEnabled,
                            hydrationIntervalSeconds: viewModel.hydrationIntervalSeconds,
                            fuelIntervalSeconds: viewModel.fuelIntervalSeconds,
                            electrolyteIntervalSeconds: viewModel.electrolyteIntervalSeconds,
                            smartRemindersEnabled: viewModel.smartRemindersEnabled,
                            stravaAutoUploadEnabled: viewModel.stravaAutoUploadEnabled,
                            saveToHealthEnabled: viewModel.saveToHealthEnabled,
                            pacingAlertsEnabled: viewModel.pacingAlertsEnabled,
                            raceId: viewModel.raceId,
                            selectedGearIds: Array(viewModel.selectedGearIds),
                            voiceCoachingConfig: viewModel.voiceCoachingConfig,
                            intervalWorkout: viewModel.intervalWorkout,
                            emergencyContactRepository: emergencyContactRepository,
                            motionService: motionService,
                            safetyConfig: viewModel.safetyConfig,
                            raceCourseRoute: viewModel.raceCourseRoute,
                            raceCheckpoints: viewModel.raceCheckpoints,
                            raceCheckpointSplits: viewModel.raceCheckpointSplits,
                            raceTotalDistanceKm: viewModel.raceTotalDistanceKm
                        ),
                        exportService: exportService
                    )
                }
            }
        }
    }
}
