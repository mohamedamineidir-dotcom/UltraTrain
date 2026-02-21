import SwiftUI
import SwiftData
import os

@main
struct UltraTrainApp: App {
    private let modelContainer: ModelContainer
    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository
    private let planGenerator: any GenerateTrainingPlanUseCase
    private let nutritionRepository: any NutritionRepository
    private let nutritionGenerator: any GenerateNutritionPlanUseCase
    private let runRepository: any RunRepository
    private let locationService: LocationService
    private let fitnessRepository: any FitnessRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let appSettingsRepository: any AppSettingsRepository
    private let clearAllDataUseCase: any ClearAllDataUseCase
    private let healthKitService: HealthKitService
    private let hapticService: HapticService
    private let trainingLoadCalculator: TrainingLoadCalculator
    private let sessionNutritionAdvisor: any SessionNutritionAdvisor
    private let widgetDataWriter: WidgetDataWriter
    private let connectivityService: PhoneConnectivityService
    private let exportService: ExportService
    private let runImportUseCase: DefaultRunImportUseCase
    private let stravaAuthService: StravaAuthService
    private let stravaUploadService: StravaUploadService
    private let stravaImportService: StravaImportService
    private let notificationService: NotificationService
    private let biometricAuthService: BiometricAuthService
    private let watchRunImportService: WatchRunImportService
    private let gearRepository: any GearRepository
    private let finishEstimateRepository: any FinishEstimateRepository
    private let stravaUploadQueueRepository: any StravaUploadQueueRepository
    private let stravaUploadQueueService: StravaUploadQueueService
    private let pendingActionProcessor: WidgetPendingActionProcessor
    private let planAutoAdjustmentService: DefaultPlanAutoAdjustmentService
    private let healthKitImportService: HealthKitImportService
    private let weatherService: AppleWeatherKitService
    private let recoveryRepository: any RecoveryRepository
    private let checklistRepository: any RacePrepChecklistRepository
    private let challengeRepository: any ChallengeRepository
    private let workoutRecipeRepository: any WorkoutRecipeRepository
    private let goalRepository: any GoalRepository
    private let cloudKitSyncMonitor: CloudKitSyncMonitor?
    private let socialProfileRepository: any SocialProfileRepository
    private let friendRepository: any FriendRepository
    private let sharedRunRepository: any SharedRunRepository
    private let activityFeedRepository: any ActivityFeedRepository
    private let groupChallengeRepository: any GroupChallengeRepository

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITestMode")
        let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")

        do {
            let schema = Schema([
                AthleteSwiftDataModel.self,
                RaceSwiftDataModel.self,
                CheckpointSwiftDataModel.self,
                TrainingPlanSwiftDataModel.self,
                TrainingWeekSwiftDataModel.self,
                TrainingSessionSwiftDataModel.self,
                NutritionPlanSwiftDataModel.self,
                NutritionEntrySwiftDataModel.self,
                NutritionProductSwiftDataModel.self,
                CompletedRunSwiftDataModel.self,
                SplitSwiftDataModel.self,
                FitnessSnapshotSwiftDataModel.self,
                AppSettingsSwiftDataModel.self,
                NutritionPreferencesSwiftDataModel.self,
                GearItemSwiftDataModel.self,
                FinishEstimateSwiftDataModel.self,
                StravaUploadQueueSwiftDataModel.self,
                RecoverySnapshotSwiftDataModel.self,
                RacePrepChecklistSwiftDataModel.self,
                ChecklistItemSwiftDataModel.self,
                ChallengeEnrollmentSwiftDataModel.self,
                WorkoutRecipeSwiftDataModel.self,
                TrainingGoalSwiftDataModel.self,
                SocialProfileSwiftDataModel.self,
                FriendConnectionSwiftDataModel.self,
                SharedRunSwiftDataModel.self,
                ActivityFeedItemSwiftDataModel.self,
                GroupChallengeSwiftDataModel.self
            ])
            let config: ModelConfiguration
            if isUITesting {
                config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            } else if iCloudEnabled {
                config = ModelConfiguration(
                    cloudKitDatabase: .private("iCloud.com.ultratrain.app")
                )
            } else {
                config = ModelConfiguration(cloudKitDatabase: .none)
            }
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        #if DEBUG
        if isUITesting && ProcessInfo.processInfo.arguments.contains("-UITestSkipOnboarding") {
            UITestDataSeeder.seed(into: modelContainer)
        }
        #endif

        athleteRepository = LocalAthleteRepository(modelContainer: modelContainer)
        raceRepository = LocalRaceRepository(modelContainer: modelContainer)
        planRepository = LocalTrainingPlanRepository(modelContainer: modelContainer)
        planGenerator = TrainingPlanGenerator()
        nutritionRepository = LocalNutritionRepository(modelContainer: modelContainer)
        nutritionGenerator = NutritionPlanGenerator()
        runRepository = LocalRunRepository(modelContainer: modelContainer)
        locationService = LocationService()
        fitnessRepository = LocalFitnessRepository(modelContainer: modelContainer)
        fitnessCalculator = FitnessCalculator()
        finishTimeEstimator = FinishTimeEstimator()
        appSettingsRepository = LocalAppSettingsRepository(modelContainer: modelContainer)
        clearAllDataUseCase = DataCleaner(modelContainer: modelContainer)
        healthKitService = HealthKitService()
        hapticService = HapticService()
        trainingLoadCalculator = TrainingLoadCalculator()
        sessionNutritionAdvisor = DefaultSessionNutritionAdvisor()
        connectivityService = PhoneConnectivityService()
        connectivityService.activate()
        widgetDataWriter = WidgetDataWriter(
            planRepository: planRepository,
            runRepository: runRepository,
            raceRepository: raceRepository,
            fitnessRepository: fitnessRepository,
            connectivityService: connectivityService
        )
        pendingActionProcessor = WidgetPendingActionProcessor(
            planRepository: planRepository,
            widgetDataWriter: widgetDataWriter
        )
        exportService = ExportService()
        runImportUseCase = DefaultRunImportUseCase(
            gpxParser: GPXParser(),
            runRepository: runRepository
        )
        stravaAuthService = StravaAuthService()
        stravaUploadService = StravaUploadService(authService: stravaAuthService)
        stravaImportService = StravaImportService(
            authService: stravaAuthService,
            runRepository: runRepository
        )
        notificationService = NotificationService()
        biometricAuthService = BiometricAuthService()
        planAutoAdjustmentService = DefaultPlanAutoAdjustmentService(
            planGenerator: planGenerator,
            planRepository: planRepository
        )
        weatherService = AppleWeatherKitService()
        healthKitImportService = HealthKitImportService(
            healthKitService: healthKitService,
            runRepository: runRepository,
            planRepository: planRepository
        )
        gearRepository = LocalGearRepository(modelContainer: modelContainer)
        finishEstimateRepository = LocalFinishEstimateRepository(modelContainer: modelContainer)
        stravaUploadQueueRepository = LocalStravaUploadQueueRepository(modelContainer: modelContainer)
        recoveryRepository = LocalRecoveryRepository(modelContainer: modelContainer)
        checklistRepository = LocalRacePrepChecklistRepository(modelContainer: modelContainer)
        challengeRepository = LocalChallengeRepository(modelContainer: modelContainer)
        workoutRecipeRepository = LocalWorkoutRecipeRepository(modelContainer: modelContainer)
        goalRepository = LocalGoalRepository(modelContainer: modelContainer)
        socialProfileRepository = LocalSocialProfileRepository(modelContainer: modelContainer)
        friendRepository = LocalFriendRepository(modelContainer: modelContainer)
        sharedRunRepository = LocalSharedRunRepository(modelContainer: modelContainer)
        activityFeedRepository = LocalActivityFeedRepository(modelContainer: modelContainer)
        groupChallengeRepository = LocalGroupChallengeRepository(modelContainer: modelContainer)
        stravaUploadQueueService = StravaUploadQueueService(
            queueRepository: stravaUploadQueueRepository,
            runRepository: runRepository,
            uploadService: stravaUploadService
        )
        watchRunImportService = WatchRunImportService(
            runRepository: runRepository,
            planRepository: planRepository,
            widgetDataWriter: widgetDataWriter
        )
        if iCloudEnabled {
            let monitor = CloudKitSyncMonitor()
            monitor.startMonitoring(modelContainer: modelContainer)
            cloudKitSyncMonitor = monitor
            let container = modelContainer
            Task {
                try? await Task.sleep(for: .seconds(3))
                await CloudKitDeduplicationService.deduplicateIfNeeded(modelContainer: container)
            }
        } else {
            cloudKitSyncMonitor = nil
        }

        let queueService = stravaUploadQueueService
        Task { await queueService.processQueue() }

        connectivityService.completedRunHandler = { [watchRunImportService, athleteRepository] runData in
            Task {
                do {
                    guard let athlete = try await athleteRepository.getAthlete() else {
                        Logger.watch.warning("Cannot import watch run — no athlete profile")
                        return
                    }
                    try await watchRunImportService.importWatchRun(runData, athleteId: athlete.id)
                } catch {
                    Logger.watch.error("Failed to import watch run: \(error)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                planRepository: planRepository,
                planGenerator: planGenerator,
                nutritionRepository: nutritionRepository,
                nutritionGenerator: nutritionGenerator,
                runRepository: runRepository,
                locationService: locationService,
                fitnessRepository: fitnessRepository,
                fitnessCalculator: fitnessCalculator,
                finishTimeEstimator: finishTimeEstimator,
                appSettingsRepository: appSettingsRepository,
                clearAllDataUseCase: clearAllDataUseCase,
                healthKitService: healthKitService,
                hapticService: hapticService,
                trainingLoadCalculator: trainingLoadCalculator,
                sessionNutritionAdvisor: sessionNutritionAdvisor,
                connectivityService: connectivityService,
                widgetDataWriter: widgetDataWriter,
                exportService: exportService,
                runImportUseCase: runImportUseCase,
                stravaAuthService: stravaAuthService,
                stravaUploadService: stravaUploadService,
                stravaUploadQueueService: stravaUploadQueueService,
                stravaImportService: stravaImportService,
                notificationService: notificationService,
                biometricAuthService: biometricAuthService,
                gearRepository: gearRepository,
                finishEstimateRepository: finishEstimateRepository,
                planAutoAdjustmentService: planAutoAdjustmentService,
                pendingActionProcessor: pendingActionProcessor,
                healthKitImportService: healthKitImportService,
                weatherService: weatherService,
                recoveryRepository: recoveryRepository,
                checklistRepository: checklistRepository,
                challengeRepository: challengeRepository,
                workoutRecipeRepository: workoutRecipeRepository,
                goalRepository: goalRepository,
                socialProfileRepository: socialProfileRepository,
                friendRepository: friendRepository,
                sharedRunRepository: sharedRunRepository,
                activityFeedRepository: activityFeedRepository,
                groupChallengeRepository: groupChallengeRepository
            )
        }
    }
}
