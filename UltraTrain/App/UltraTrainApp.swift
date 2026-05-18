import SwiftUI
import SwiftData
import os

@main
struct UltraTrainApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let container: AppDependencyContainer

    init() {
        container = AppDependencyContainer()
    }

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = "system"
    /// Controls the in-app launch splash that bridges the gap when
    /// the user has forced the app to dark mode on a light-system
    /// device. iOS launch screens follow the system appearance only;
    /// the splash takes over for ~0.4 s so the visible flash from the
    /// light system launch into the dark app is masked.
    @State private var showLaunchSplash: Bool = true

    private var colorScheme: ColorScheme? {
        switch AppearanceMode(rawValue: appearanceModeRaw) {
        case .light: .light
        case .dark: .dark
        default: nil
        }
    }

    /// True only when the user has explicitly set the app to dark.
    /// For .system and .light the iOS launch screen already shows the
    /// correct variant, so the splash is unnecessary overhead.
    private var shouldOverrideLaunchToDark: Bool {
        AppearanceMode(rawValue: appearanceModeRaw) == .dark
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
            AppRootView(
                authService: container.authService,
                subscriptionService: container.subscriptionService,
                referralRepository: container.referralRepository,
                deepLinkRouter: container.deepLinkRouter,
                athleteRepository: container.athleteRepository,
                raceRepository: container.raceRepository,
                planRepository: container.planRepository,
                planGenerator: container.planGenerator,
                nutritionRepository: container.nutritionRepository,
                nutritionGenerator: container.nutritionGenerator,
                runRepository: container.runRepository,
                locationService: container.locationService,
                fitnessRepository: container.fitnessRepository,
                fitnessCalculator: container.fitnessCalculator,
                finishTimeEstimator: container.finishTimeEstimator,
                appSettingsRepository: container.appSettingsRepository,
                clearAllDataUseCase: container.clearAllDataUseCase,
                healthKitService: container.healthKitService,
                hapticService: container.hapticService,
                trainingLoadCalculator: container.trainingLoadCalculator,
                sessionNutritionAdvisor: container.sessionNutritionAdvisor,
                connectivityService: container.connectivityService,
                widgetDataWriter: container.widgetDataWriter,
                exportService: container.exportService,
                runImportUseCase: container.runImportUseCase,
                stravaAuthService: container.stravaAuthService,
                stravaUploadService: container.stravaUploadService,
                stravaUploadQueueService: container.stravaUploadQueueService,
                stravaImportService: container.stravaImportService,
                notificationService: container.notificationService,
                biometricAuthService: container.biometricAuthService,
                gearRepository: container.gearRepository,
                finishEstimateRepository: container.finishEstimateRepository,
                planAutoAdjustmentService: container.planAutoAdjustmentService,
                pendingActionProcessor: container.pendingActionProcessor,
                healthKitImportService: container.healthKitImportService,
                weatherService: container.weatherService,
                recoveryRepository: container.recoveryRepository,
                checklistRepository: container.checklistRepository,
                challengeRepository: container.challengeRepository,
                workoutRecipeRepository: container.workoutRecipeRepository,
                goalRepository: container.goalRepository,
                socialProfileRepository: container.socialProfileRepository,
                friendRepository: container.friendRepository,
                sharedRunRepository: container.sharedRunRepository,
                activityFeedRepository: container.activityFeedRepository,
                groupChallengeRepository: container.groupChallengeRepository,
                crewService: container.cloudKitCrewService,
                routeRepository: container.routeRepository,
                intervalWorkoutRepository: container.intervalWorkoutRepository,
                emergencyContactRepository: container.emergencyContactRepository,
                motionService: container.motionService,
                foodLogRepository: container.foodLogRepository,
                foodDatabaseService: container.foodDatabaseService,
                foodPhotoAnalysisService: container.foodPhotoAnalysisService,
                raceReflectionRepository: container.raceReflectionRepository,
                achievementRepository: container.achievementRepository,
                morningCheckInRepository: container.morningCheckInRepository,
                intervalPerformanceRepository: container.intervalPerformanceRepository,
                deviceTokenService: container.deviceTokenService,
                deviceIntegrityChecker: container.deviceIntegrityChecker
            )
            .environment(\.syncStatusMonitor, container.syncStatusMonitor)
            .environment(\.syncService, container.syncService)
            .environment(\.networkMonitor, container.networkMonitor)
            .preferredColorScheme(colorScheme)
            .onOpenURL { url in
                _ = container.deepLinkRouter.handle(url: url)
            }
            .onAppear {
                container.configureAppDelegate(appDelegate)
                let tokenService = container.deviceTokenService
                appDelegate.onDeviceTokenReceived = { token in
                    Task { await tokenService.registerToken(token) }
                }
                let syncSvc = container.syncService
                let monitor = container.syncStatusMonitor
                appDelegate.onSilentPushReceived = {
                    await syncSvc.processQueue()
                    await monitor.refresh()
                }
            }

            if shouldOverrideLaunchToDark && showLaunchSplash {
                LaunchSplashView()
                    .transition(.opacity)
                    .task {
                        // Show the dark splash for ~0.4 s, then fade
                        // out over 0.3 s so the handoff to the main
                        // UI feels like a smooth cross-fade rather
                        // than a hard cut.
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        withAnimation(.easeOut(duration: 0.3)) {
                            showLaunchSplash = false
                        }
                    }
            }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let syncSvc = container.syncService
                let monitor = container.syncStatusMonitor
                let reporter = container.crashReporter
                Task {
                    await syncSvc.processQueue()
                    await monitor.refresh()
                    await reporter.uploadPendingReports()
                }
            }
            if newPhase == .background {
                container.backgroundTaskService.scheduleHealthKitSync()
                container.backgroundTaskService.scheduleRecoveryCalc()
                container.backgroundTaskService.scheduleSyncQueueProcessing()
            }
        }
    }
}
