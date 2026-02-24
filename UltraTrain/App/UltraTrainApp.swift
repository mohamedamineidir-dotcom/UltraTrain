import SwiftUI
import SwiftData
import UserNotifications
import os

@main
struct UltraTrainApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
    private let cloudKitSharingService: (any CloudKitSharingServiceProtocol)?
    private let cloudKitCrewService: any CrewTrackingServiceProtocol
    private let routeRepository: any RouteRepository
    private let intervalWorkoutRepository: any IntervalWorkoutRepository
    private let emergencyContactRepository: any EmergencyContactRepository
    private let motionService: MotionService
    private let foodLogRepository: any FoodLogRepository
    private let foodDatabaseService: FoodDatabaseService
    private let raceReflectionRepository: any RaceReflectionRepository
    private let achievementRepository: any AchievementRepository
    private let morningCheckInRepository: any MorningCheckInRepository
    private let apiClient: APIClient
    private let authService: AuthService
    private let syncService: SyncService
    private let syncStatusMonitor: SyncStatusMonitor
    private let deviceTokenService: DeviceTokenService
    private let deepLinkRouter: DeepLinkRouter
    private let backgroundTaskService: BackgroundTaskService
    private let notificationDelegate: NotificationDelegate
    private let deviceIntegrityChecker: DeviceIntegrityChecker

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
                GroupChallengeSwiftDataModel.self,
                SavedRouteSwiftDataModel.self,
                IntervalWorkoutSwiftDataModel.self,
                EmergencyContactSwiftDataModel.self,
                FoodLogEntrySwiftDataModel.self,
                RaceReflectionSwiftDataModel.self,
                UnlockedAchievementSwiftDataModel.self,
                MorningCheckInSwiftDataModel.self,
                SyncQueueSwiftDataModel.self
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

        if !isUITesting {
            FileProtectionManager.applyProtection(to: FileProtectionManager.defaultStoreDirectory)
        }

        #if DEBUG
        if isUITesting && ProcessInfo.processInfo.arguments.contains("-UITestSkipOnboarding") {
            UITestDataSeeder.seed(into: modelContainer)
        }
        #endif

        let localAthleteRepo = LocalAthleteRepository(modelContainer: modelContainer)
        let localRunRepo = LocalRunRepository(modelContainer: modelContainer)

        let auth = AuthService(apiClient: APIClient())
        let authInterceptor = AuthInterceptor(authService: auth)
        let signingInterceptor = RequestSigningInterceptor()
        let client = APIClient(authInterceptor: authInterceptor, signingInterceptor: signingInterceptor)
        let remoteRunDataSource = RemoteRunDataSource(apiClient: client)
        let remoteAthleteDataSource = RemoteAthleteDataSource(apiClient: client)
        let remoteRaceDataSource = RemoteRaceDataSource(apiClient: client)
        let remoteTrainingPlanDataSource = RemoteTrainingPlanDataSource(apiClient: client)
        let localRaceRepo = LocalRaceRepository(modelContainer: modelContainer)
        let localPlanRepo = LocalTrainingPlanRepository(modelContainer: modelContainer)
        let raceSyncService = RaceSyncService(remote: remoteRaceDataSource, authService: auth)
        let planSyncService = TrainingPlanSyncService(
            remote: remoteTrainingPlanDataSource,
            raceRepository: localRaceRepo,
            authService: auth
        )
        let syncQueueRepo = LocalSyncQueueRepository(modelContainer: modelContainer)
        let sync = SyncService(
            queueRepository: syncQueueRepo,
            localRunRepository: localRunRepo,
            remoteRunDataSource: remoteRunDataSource,
            authService: auth,
            remoteAthleteDataSource: remoteAthleteDataSource,
            localAthleteRepository: localAthleteRepo,
            remoteRaceDataSource: remoteRaceDataSource,
            localRaceRepository: localRaceRepo,
            remoteTrainingPlanDataSource: remoteTrainingPlanDataSource,
            localTrainingPlanRepository: localPlanRepo,
            trainingPlanSyncService: planSyncService
        )
        apiClient = client
        authService = auth
        syncService = sync
        syncStatusMonitor = SyncStatusMonitor(syncQueueService: sync)
        deviceTokenService = DeviceTokenService(apiClient: client)

        athleteRepository = SyncedAthleteRepository(
            local: localAthleteRepo,
            remote: remoteAthleteDataSource,
            authService: auth,
            syncQueue: sync
        )
        raceRepository = SyncedRaceRepository(
            local: localRaceRepo,
            syncService: raceSyncService,
            syncQueue: sync
        )
        planRepository = SyncedTrainingPlanRepository(
            local: localPlanRepo,
            syncService: planSyncService,
            syncQueue: sync
        )
        planGenerator = TrainingPlanGenerator()
        nutritionRepository = LocalNutritionRepository(modelContainer: modelContainer)
        nutritionGenerator = NutritionPlanGenerator()
        let runRestoreService = RunRestoreService(
            remote: remoteRunDataSource,
            authService: auth,
            athleteRepository: athleteRepository
        )
        runRepository = SyncedRunRepository(
            local: localRunRepo,
            syncService: sync,
            restoreService: runRestoreService,
            remoteDataSource: remoteRunDataSource,
            authService: auth
        )
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
        let localSocialProfileRepo = LocalSocialProfileRepository(modelContainer: modelContainer)
        let localFriendRepo = LocalFriendRepository(modelContainer: modelContainer)
        let localSharedRunRepo = LocalSharedRunRepository(modelContainer: modelContainer)
        let localActivityFeedRepo = LocalActivityFeedRepository(modelContainer: modelContainer)
        let localGroupChallengeRepo = LocalGroupChallengeRepository(modelContainer: modelContainer)

        let remoteSocialProfile = RemoteSocialProfileDataSource(apiClient: client)
        let remoteFriend = RemoteFriendDataSource(apiClient: client)
        let remoteActivityFeed = RemoteActivityFeedDataSource(apiClient: client)
        let remoteSharedRun = RemoteSharedRunDataSource(apiClient: client)
        let remoteGroupChallenge = RemoteGroupChallengeDataSource(apiClient: client)

        socialProfileRepository = SyncedSocialProfileRepository(
            local: localSocialProfileRepo,
            remote: remoteSocialProfile,
            authService: auth
        )
        friendRepository = SyncedFriendRepository(
            local: localFriendRepo,
            remote: remoteFriend,
            authService: auth
        )
        sharedRunRepository = SyncedSharedRunRepository(
            local: localSharedRunRepo,
            remote: remoteSharedRun,
            authService: auth
        )
        activityFeedRepository = SyncedActivityFeedRepository(
            local: localActivityFeedRepo,
            remote: remoteActivityFeed,
            authService: auth
        )
        groupChallengeRepository = SyncedGroupChallengeRepository(
            local: localGroupChallengeRepo,
            remote: remoteGroupChallenge,
            authService: auth
        )
        routeRepository = LocalRouteRepository(modelContainer: modelContainer)
        intervalWorkoutRepository = LocalIntervalWorkoutRepository(modelContainer: modelContainer)
        emergencyContactRepository = LocalEmergencyContactRepository(modelContainer: modelContainer)
        foodLogRepository = LocalFoodLogRepository(modelContainer: modelContainer)
        foodDatabaseService = FoodDatabaseService()
        raceReflectionRepository = LocalRaceReflectionRepository(modelContainer: modelContainer)
        achievementRepository = LocalAchievementRepository(modelContainer: modelContainer)
        morningCheckInRepository = LocalMorningCheckInRepository(modelContainer: modelContainer)
        motionService = MotionService()
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
            let accountManager = CloudKitAccountManager()
            cloudKitSharingService = CloudKitSharingService(accountManager: accountManager)
            cloudKitCrewService = CloudKitCrewTrackingService(accountManager: accountManager)
        } else {
            cloudKitSyncMonitor = nil
            cloudKitSharingService = nil
            cloudKitCrewService = CrewTrackingService()
        }

        let queueService = stravaUploadQueueService
        Task { await queueService.processQueue() }

        let syncSvc = syncService
        Task { await syncSvc.processQueue() }

        connectivityService.completedRunHandler = {
            [watchRunImportService, athleteRepository, runRepository, connectivityService] runData in
            Task {
                do {
                    guard let athlete = try await athleteRepository.getAthlete() else {
                        Logger.watch.warning("Cannot import watch run — no athlete profile")
                        return
                    }
                    try await watchRunImportService.importWatchRun(runData, athleteId: athlete.id)

                    let recentRuns = try await runRepository.getRecentRuns(limit: 10)
                    let historyData = recentRuns.map { run in
                        WatchRunHistoryData(
                            id: run.id,
                            date: run.date,
                            distanceKm: run.distanceKm,
                            elevationGainM: run.elevationGainM,
                            duration: run.duration,
                            averagePaceSecondsPerKm: run.averagePaceSecondsPerKm,
                            averageHeartRate: run.averageHeartRate
                        )
                    }
                    await connectivityService.sendRunHistory(historyData)
                } catch {
                    Logger.watch.error("Failed to import watch run: \(error)")
                }
            }
        }

        deepLinkRouter = DeepLinkRouter()

        let delegate = NotificationDelegate()
        delegate.deepLinkRouter = deepLinkRouter
        notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate

        let notifService = notificationService
        Task { await notifService.registerNotificationCategories() }

        backgroundTaskService = BackgroundTaskService(
            healthKitService: healthKitService,
            recoveryRepository: recoveryRepository,
            fitnessRepository: fitnessRepository,
            fitnessCalculator: fitnessCalculator,
            runRepository: runRepository,
            syncQueueService: sync
        )
        backgroundTaskService.registerTasks()
        deviceIntegrityChecker = DeviceIntegrityChecker()
    }

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = "system"

    private var colorScheme: ColorScheme? {
        switch AppearanceMode(rawValue: appearanceModeRaw) {
        case .light: .light
        case .dark: .dark
        default: nil
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                authService: authService,
                deepLinkRouter: deepLinkRouter,
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
                groupChallengeRepository: groupChallengeRepository,
                routeRepository: routeRepository,
                intervalWorkoutRepository: intervalWorkoutRepository,
                emergencyContactRepository: emergencyContactRepository,
                motionService: motionService,
                foodLogRepository: foodLogRepository,
                foodDatabaseService: foodDatabaseService,
                raceReflectionRepository: raceReflectionRepository,
                achievementRepository: achievementRepository,
                morningCheckInRepository: morningCheckInRepository,
                deviceTokenService: deviceTokenService,
                deviceIntegrityChecker: deviceIntegrityChecker
            )
            .environment(\.syncStatusMonitor, syncStatusMonitor)
            .environment(\.syncService, syncService)
            .preferredColorScheme(colorScheme)
            .onOpenURL { url in
                _ = deepLinkRouter.handle(url: url)
            }
            .onAppear {
                let tokenService = deviceTokenService
                appDelegate.onDeviceTokenReceived = { token in
                    Task { await tokenService.registerToken(token) }
                }
                let syncSvc = syncService
                let monitor = syncStatusMonitor
                appDelegate.onSilentPushReceived = {
                    await syncSvc.processQueue()
                    await monitor.refresh()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let syncSvc = syncService
                let monitor = syncStatusMonitor
                Task {
                    await syncSvc.processQueue()
                    await monitor.refresh()
                }
            }
            if newPhase == .background {
                backgroundTaskService.scheduleHealthKitSync()
                backgroundTaskService.scheduleRecoveryCalc()
                backgroundTaskService.scheduleSyncQueueProcessing()
            }
        }
    }
}
