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

    var body: some Scene {
        WindowGroup {
            AppRootContainer {
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

/// Hosts the app's content, applies the user's appearance preference,
/// and conditionally overlays `LaunchSplashView`.
///
/// Reads `@Environment(\.colorScheme)` *before* `preferredColorScheme`
/// is applied to the content, so `systemColorScheme` reflects what
/// iOS actually rendered for the system launch screen. The splash is
/// only drawn when the iOS launch screen would have shown the *light*
/// variant while the app wants dark. When the system is already dark
/// the splash is skipped, otherwise it produces a redundant ~0.7 s
/// second blue flash after the iOS launch.
private struct AppRootContainer<Content: View>: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = "system"
    @State private var showLaunchSplash: Bool = true
    @ViewBuilder var content: () -> Content

    private var preferredColorScheme: ColorScheme? {
        switch AppearanceMode(rawValue: appearanceModeRaw) {
        case .light: .light
        case .dark: .dark
        default: nil
        }
    }

    private var shouldOverrideLaunchToDark: Bool {
        AppearanceMode(rawValue: appearanceModeRaw) == .dark
            && systemColorScheme == .light
    }

    var body: some View {
        ZStack {
            content()
                .preferredColorScheme(preferredColorScheme)

            if shouldOverrideLaunchToDark && showLaunchSplash {
                LaunchSplashView()
                    .transition(.opacity)
                    .task {
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        withAnimation(.easeOut(duration: 0.3)) {
                            showLaunchSplash = false
                        }
                    }
            }
        }
    }
}
