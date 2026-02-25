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
                authService: container.authService,
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
                routeRepository: container.routeRepository,
                intervalWorkoutRepository: container.intervalWorkoutRepository,
                emergencyContactRepository: container.emergencyContactRepository,
                motionService: container.motionService,
                foodLogRepository: container.foodLogRepository,
                foodDatabaseService: container.foodDatabaseService,
                raceReflectionRepository: container.raceReflectionRepository,
                achievementRepository: container.achievementRepository,
                morningCheckInRepository: container.morningCheckInRepository,
                deviceTokenService: container.deviceTokenService,
                deviceIntegrityChecker: container.deviceIntegrityChecker
            )
            .environment(\.syncStatusMonitor, container.syncStatusMonitor)
            .environment(\.syncService, container.syncService)
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
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let syncSvc = container.syncService
                let monitor = container.syncStatusMonitor
                Task {
                    await syncSvc.processQueue()
                    await monitor.refresh()
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
