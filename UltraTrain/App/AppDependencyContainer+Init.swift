import SwiftData
import UserNotifications
import os

// swiftlint:disable function_body_length

extension AppDependencyContainer {

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITestMode")
        let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")

        modelContainer = Self.createModelContainer(isUITesting: isUITesting, iCloudEnabled: iCloudEnabled)

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
        let signingInterceptor = RequestSigningInterceptor()
        let authApiClient = APIClient(signingInterceptor: signingInterceptor)
        let auth = AuthService(apiClient: authApiClient)
        let authInterceptor = AuthInterceptor(authService: auth)
        let client = APIClient(authInterceptor: authInterceptor, signingInterceptor: signingInterceptor)
        let remoteRunDataSource = RemoteRunDataSource(apiClient: client)
        let remoteAthleteDataSource = RemoteAthleteDataSource(apiClient: client)
        let remoteRaceDataSource = RemoteRaceDataSource(apiClient: client)
        let remoteTrainingPlanDataSource = RemoteTrainingPlanDataSource(apiClient: client)
        let localRaceRepo = LocalRaceRepository(modelContainer: modelContainer)
        let localPlanRepo = LocalTrainingPlanRepository(modelContainer: modelContainer)
        let raceSyncService = RaceSyncService(remote: remoteRaceDataSource, authService: auth)
        let planSyncService = TrainingPlanSyncService(
            remote: remoteTrainingPlanDataSource, raceRepository: localRaceRepo, authService: auth
        )
        let syncQueueRepo = LocalSyncQueueRepository(modelContainer: modelContainer)

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
        let socialHandler = SocialSyncHandler(
            remoteSocialProfile: remoteSocialProfile, localSocialProfile: localSocialProfileRepo,
            remoteActivityFeed: remoteActivityFeed, localActivityFeed: localActivityFeedRepo,
            remoteSharedRun: remoteSharedRun
        )
        let bgUploadService = BackgroundUploadService(
            baseURL: AppConfiguration.API.baseURL, syncQueueRepository: syncQueueRepo, authService: auth
        )
        let sync = SyncService(
            queueRepository: syncQueueRepo, localRunRepository: localRunRepo,
            remoteRunDataSource: remoteRunDataSource, authService: auth,
            remoteAthleteDataSource: remoteAthleteDataSource, localAthleteRepository: localAthleteRepo,
            remoteRaceDataSource: remoteRaceDataSource, localRaceRepository: localRaceRepo,
            remoteTrainingPlanDataSource: remoteTrainingPlanDataSource,
            localTrainingPlanRepository: localPlanRepo,
            trainingPlanSyncService: planSyncService, socialSyncHandler: socialHandler,
            backgroundUploadService: bgUploadService
        )
        apiClient = client
        authService = auth
        syncService = sync
        syncStatusMonitor = SyncStatusMonitor(syncQueueService: sync)
        deviceTokenService = DeviceTokenService(apiClient: client)

        athleteRepository = SyncedAthleteRepository(
            local: localAthleteRepo, remote: remoteAthleteDataSource, authService: auth, syncQueue: sync
        )
        raceRepository = SyncedRaceRepository(
            local: localRaceRepo, syncService: raceSyncService, syncQueue: sync
        )
        planRepository = SyncedTrainingPlanRepository(
            local: localPlanRepo, syncService: planSyncService, syncQueue: sync
        )
        planGenerator = TrainingPlanGenerator()
        nutritionRepository = LocalNutritionRepository(modelContainer: modelContainer)
        nutritionGenerator = NutritionPlanGenerator()
        let runRestoreService = RunRestoreService(
            remote: remoteRunDataSource, authService: auth, athleteRepository: athleteRepository
        )
        runRepository = SyncedRunRepository(
            local: localRunRepo, syncService: sync, restoreService: runRestoreService,
            remoteDataSource: remoteRunDataSource, authService: auth
        )
        locationService = LocationService()
        fitnessRepository = LocalFitnessRepository(modelContainer: modelContainer)
        fitnessCalculator = FitnessCalculator()
        let mlService = FinishTimeMLService()
        finishTimeEstimator = FinishTimeEstimator(mlPredictionService: mlService)
        appSettingsRepository = LocalAppSettingsRepository(modelContainer: modelContainer)
        clearAllDataUseCase = DataCleaner(modelContainer: modelContainer)
        healthKitService = HealthKitService()
        hapticService = HapticService()
        trainingLoadCalculator = TrainingLoadCalculator()
        sessionNutritionAdvisor = DefaultSessionNutritionAdvisor()
        connectivityService = PhoneConnectivityService()
        connectivityService.activate()
        widgetDataWriter = WidgetDataWriter(
            planRepository: planRepository, runRepository: runRepository,
            raceRepository: raceRepository, fitnessRepository: fitnessRepository,
            connectivityService: connectivityService
        )
        pendingActionProcessor = WidgetPendingActionProcessor(
            planRepository: planRepository, widgetDataWriter: widgetDataWriter
        )
        exportService = ExportService()
        runImportUseCase = DefaultRunImportUseCase(gpxParser: GPXParser(), runRepository: runRepository)
        stravaAuthService = StravaAuthService()
        stravaUploadService = StravaUploadService(authService: stravaAuthService)
        stravaImportService = StravaImportService(
            authService: stravaAuthService, runRepository: runRepository
        )
        notificationService = NotificationService()
        biometricAuthService = BiometricAuthService()
        planAutoAdjustmentService = DefaultPlanAutoAdjustmentService(
            planGenerator: planGenerator, planRepository: planRepository
        )
        weatherService = AppleWeatherKitService()
        healthKitImportService = HealthKitImportService(
            healthKitService: healthKitService, runRepository: runRepository, planRepository: planRepository
        )
        gearRepository = LocalGearRepository(modelContainer: modelContainer)
        finishEstimateRepository = LocalFinishEstimateRepository(modelContainer: modelContainer)
        stravaUploadQueueRepository = LocalStravaUploadQueueRepository(modelContainer: modelContainer)
        recoveryRepository = LocalRecoveryRepository(modelContainer: modelContainer)
        checklistRepository = LocalRacePrepChecklistRepository(modelContainer: modelContainer)
        challengeRepository = LocalChallengeRepository(modelContainer: modelContainer)
        workoutRecipeRepository = LocalWorkoutRecipeRepository(modelContainer: modelContainer)
        goalRepository = LocalGoalRepository(modelContainer: modelContainer)
        socialProfileRepository = SyncedSocialProfileRepository(
            local: localSocialProfileRepo, remote: remoteSocialProfile, authService: auth, syncQueue: sync
        )
        friendRepository = SyncedFriendRepository(
            local: localFriendRepo, remote: remoteFriend, authService: auth
        )
        sharedRunRepository = SyncedSharedRunRepository(
            local: localSharedRunRepo, remote: remoteSharedRun, authService: auth, syncQueue: sync
        )
        activityFeedRepository = SyncedActivityFeedRepository(
            local: localActivityFeedRepo, remote: remoteActivityFeed, authService: auth, syncQueue: sync
        )
        groupChallengeRepository = SyncedGroupChallengeRepository(
            local: localGroupChallengeRepo, remote: remoteGroupChallenge, authService: auth
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
            queueRepository: stravaUploadQueueRepository, runRepository: runRepository,
            uploadService: stravaUploadService
        )
        watchRunImportService = WatchRunImportService(
            runRepository: runRepository, planRepository: planRepository, widgetDataWriter: widgetDataWriter
        )
        let cloudKitResult = Self.configureCloudKit(
            iCloudEnabled: iCloudEnabled, modelContainer: modelContainer
        )
        cloudKitSyncMonitor = cloudKitResult.monitor
        cloudKitSharingService = cloudKitResult.sharingService
        cloudKitCrewService = cloudKitResult.crewService

        deepLinkRouter = DeepLinkRouter()
        let delegate = NotificationDelegate()
        delegate.deepLinkRouter = deepLinkRouter
        notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate
        deviceIntegrityChecker = DeviceIntegrityChecker()

        backgroundTaskService = BackgroundTaskService(
            healthKitService: healthKitService, recoveryRepository: recoveryRepository,
            fitnessRepository: fitnessRepository, fitnessCalculator: fitnessCalculator,
            runRepository: runRepository, syncQueueService: sync,
            notificationService: notificationService
        )
        backgroundTaskService.registerTasks()

        let netMonitor = NetworkMonitor(onConnectivityRestored: { [syncSvc = sync] in
            await syncSvc.processQueue()
        })
        netMonitor.start()
        networkMonitor = netMonitor

        Self.startBackgroundTasks(
            stravaUploadQueueService: stravaUploadQueueService, syncService: syncService,
            notificationService: notificationService, connectivityService: connectivityService,
            watchRunImportService: watchRunImportService, athleteRepository: athleteRepository,
            runRepository: runRepository
        )

        backgroundUploadService = bgUploadService
    }
}

// swiftlint:enable function_body_length
