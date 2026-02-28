import SwiftUI
import UIKit
import UserNotifications
import os

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State var isAuthenticated: Bool?
    @State var hasCompletedOnboarding: Bool?
    @State var isUnlocked = false
    @State var needsBiometricLock = false
    @State var showFeatureTour = false
    @AppStorage("hasSeenFeatureTour") var hasSeenFeatureTour = false
    @State var unitPreference: UnitPreference = .metric
    @State var lastAutoImportDate: Date?
    @State private var isDeviceCompromised = false
    let authService: any AuthServiceProtocol
    let deepLinkRouter: DeepLinkRouter
    private let deviceIntegrityChecker: (any DeviceIntegrityCheckerProtocol)?

    let athleteRepository: any AthleteRepository
    let raceRepository: any RaceRepository
    let planRepository: any TrainingPlanRepository
    let planGenerator: any GenerateTrainingPlanUseCase
    let nutritionRepository: any NutritionRepository
    let nutritionGenerator: any GenerateNutritionPlanUseCase
    let runRepository: any RunRepository
    let locationService: LocationService
    let fitnessRepository: any FitnessRepository
    let fitnessCalculator: any CalculateFitnessUseCase
    let finishTimeEstimator: any EstimateFinishTimeUseCase
    let appSettingsRepository: any AppSettingsRepository
    let clearAllDataUseCase: any ClearAllDataUseCase
    let healthKitService: any HealthKitServiceProtocol
    let hapticService: any HapticServiceProtocol
    let trainingLoadCalculator: any CalculateTrainingLoadUseCase
    let sessionNutritionAdvisor: any SessionNutritionAdvisor
    let connectivityService: PhoneConnectivityService?
    let widgetDataWriter: WidgetDataWriter
    let exportService: any ExportServiceProtocol
    let runImportUseCase: any RunImportUseCase
    let stravaAuthService: any StravaAuthServiceProtocol
    let stravaUploadService: (any StravaUploadServiceProtocol)?
    let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    let stravaImportService: (any StravaImportServiceProtocol)?
    let notificationService: any NotificationServiceProtocol
    let biometricAuthService: any BiometricAuthServiceProtocol
    let gearRepository: any GearRepository
    let finishEstimateRepository: any FinishEstimateRepository
    let planAutoAdjustmentService: any PlanAutoAdjustmentService
    private let pendingActionProcessor: WidgetPendingActionProcessor?
    let healthKitImportService: (any HealthKitImportServiceProtocol)?
    let weatherService: (any WeatherServiceProtocol)?
    let recoveryRepository: any RecoveryRepository
    let checklistRepository: any RacePrepChecklistRepository
    let challengeRepository: any ChallengeRepository
    let workoutRecipeRepository: any WorkoutRecipeRepository
    let goalRepository: any GoalRepository
    let socialProfileRepository: any SocialProfileRepository
    let friendRepository: any FriendRepository
    let sharedRunRepository: any SharedRunRepository
    let activityFeedRepository: any ActivityFeedRepository
    let groupChallengeRepository: any GroupChallengeRepository
    let crewService: any CrewTrackingServiceProtocol
    let routeRepository: any RouteRepository
    let intervalWorkoutRepository: (any IntervalWorkoutRepository)?
    let emergencyContactRepository: (any EmergencyContactRepository)?
    let motionService: (any MotionServiceProtocol)?
    let foodLogRepository: any FoodLogRepository
    let foodDatabaseService: (any FoodDatabaseServiceProtocol)?
    let raceReflectionRepository: any RaceReflectionRepository
    let achievementRepository: (any AchievementRepository)?
    let morningCheckInRepository: (any MorningCheckInRepository)?
    let deviceTokenService: DeviceTokenService?

    init(
        authService: any AuthServiceProtocol,
        deepLinkRouter: DeepLinkRouter,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planRepository: any TrainingPlanRepository,
        planGenerator: any GenerateTrainingPlanUseCase,
        nutritionRepository: any NutritionRepository,
        nutritionGenerator: any GenerateNutritionPlanUseCase,
        runRepository: any RunRepository,
        locationService: LocationService,
        fitnessRepository: any FitnessRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        appSettingsRepository: any AppSettingsRepository,
        clearAllDataUseCase: any ClearAllDataUseCase,
        healthKitService: any HealthKitServiceProtocol,
        hapticService: any HapticServiceProtocol,
        trainingLoadCalculator: any CalculateTrainingLoadUseCase,
        sessionNutritionAdvisor: any SessionNutritionAdvisor,
        connectivityService: PhoneConnectivityService? = nil,
        widgetDataWriter: WidgetDataWriter,
        exportService: any ExportServiceProtocol,
        runImportUseCase: any RunImportUseCase,
        stravaAuthService: any StravaAuthServiceProtocol,
        stravaUploadService: (any StravaUploadServiceProtocol)? = nil,
        stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)? = nil,
        stravaImportService: (any StravaImportServiceProtocol)? = nil,
        notificationService: any NotificationServiceProtocol,
        biometricAuthService: any BiometricAuthServiceProtocol,
        gearRepository: any GearRepository,
        finishEstimateRepository: any FinishEstimateRepository,
        planAutoAdjustmentService: any PlanAutoAdjustmentService,
        pendingActionProcessor: WidgetPendingActionProcessor? = nil,
        healthKitImportService: (any HealthKitImportServiceProtocol)? = nil,
        weatherService: (any WeatherServiceProtocol)? = nil,
        recoveryRepository: any RecoveryRepository,
        checklistRepository: any RacePrepChecklistRepository,
        challengeRepository: any ChallengeRepository,
        workoutRecipeRepository: any WorkoutRecipeRepository,
        goalRepository: any GoalRepository,
        socialProfileRepository: any SocialProfileRepository,
        friendRepository: any FriendRepository,
        sharedRunRepository: any SharedRunRepository,
        activityFeedRepository: any ActivityFeedRepository,
        groupChallengeRepository: any GroupChallengeRepository,
        crewService: any CrewTrackingServiceProtocol,
        routeRepository: any RouteRepository,
        intervalWorkoutRepository: (any IntervalWorkoutRepository)? = nil,
        emergencyContactRepository: (any EmergencyContactRepository)? = nil,
        motionService: (any MotionServiceProtocol)? = nil,
        foodLogRepository: any FoodLogRepository,
        foodDatabaseService: (any FoodDatabaseServiceProtocol)? = nil,
        raceReflectionRepository: any RaceReflectionRepository,
        achievementRepository: (any AchievementRepository)? = nil,
        morningCheckInRepository: (any MorningCheckInRepository)? = nil,
        deviceTokenService: DeviceTokenService? = nil,
        deviceIntegrityChecker: (any DeviceIntegrityCheckerProtocol)? = nil
    ) {
        self.authService = authService
        self.deepLinkRouter = deepLinkRouter
        self.deviceIntegrityChecker = deviceIntegrityChecker
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.planRepository = planRepository
        self.planGenerator = planGenerator
        self.nutritionRepository = nutritionRepository
        self.nutritionGenerator = nutritionGenerator
        self.runRepository = runRepository
        self.locationService = locationService
        self.fitnessRepository = fitnessRepository
        self.fitnessCalculator = fitnessCalculator
        self.finishTimeEstimator = finishTimeEstimator
        self.appSettingsRepository = appSettingsRepository
        self.clearAllDataUseCase = clearAllDataUseCase
        self.healthKitService = healthKitService
        self.hapticService = hapticService
        self.trainingLoadCalculator = trainingLoadCalculator
        self.sessionNutritionAdvisor = sessionNutritionAdvisor
        self.connectivityService = connectivityService
        self.widgetDataWriter = widgetDataWriter
        self.exportService = exportService
        self.runImportUseCase = runImportUseCase
        self.stravaAuthService = stravaAuthService
        self.stravaUploadService = stravaUploadService
        self.stravaUploadQueueService = stravaUploadQueueService
        self.stravaImportService = stravaImportService
        self.notificationService = notificationService
        self.biometricAuthService = biometricAuthService
        self.gearRepository = gearRepository
        self.finishEstimateRepository = finishEstimateRepository
        self.planAutoAdjustmentService = planAutoAdjustmentService
        self.pendingActionProcessor = pendingActionProcessor
        self.healthKitImportService = healthKitImportService
        self.weatherService = weatherService
        self.recoveryRepository = recoveryRepository
        self.checklistRepository = checklistRepository
        self.challengeRepository = challengeRepository
        self.workoutRecipeRepository = workoutRecipeRepository
        self.goalRepository = goalRepository
        self.socialProfileRepository = socialProfileRepository
        self.friendRepository = friendRepository
        self.sharedRunRepository = sharedRunRepository
        self.activityFeedRepository = activityFeedRepository
        self.groupChallengeRepository = groupChallengeRepository
        self.crewService = crewService
        self.routeRepository = routeRepository
        self.intervalWorkoutRepository = intervalWorkoutRepository
        self.emergencyContactRepository = emergencyContactRepository
        self.motionService = motionService
        self.foodLogRepository = foodLogRepository
        self.foodDatabaseService = foodDatabaseService
        self.raceReflectionRepository = raceReflectionRepository
        self.achievementRepository = achievementRepository
        self.morningCheckInRepository = morningCheckInRepository
        self.deviceTokenService = deviceTokenService
    }

    var body: some View {
        VStack(spacing: 0) {
            if isDeviceCompromised {
                JailbreakWarningBanner()
            }
            Group {
                switch isAuthenticated {
                case .none:
                    ProgressView("Loading...")
                case .some(false):
                    LoginView(authService: authService) {
                        isAuthenticated = true
                        Task {
                            await checkBiometricLockSetting()
                            await checkOnboardingStatus()
                            await loadUnitPreference()
                            await registerForPushNotifications()
                        }
                    }
                case .some(true):
                    authenticatedContent
                }
            }
        }
        .environment(\.unitPreference, unitPreference)
        .task {
            if let checker = deviceIntegrityChecker {
                isDeviceCompromised = checker.isDeviceCompromised()
            }
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-UITestSkipOnboarding") {
                isAuthenticated = true
                hasCompletedOnboarding = true
                return
            }
            if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
                isAuthenticated = true
                await checkOnboardingStatus()
                return
            }
            #endif
            isAuthenticated = authService.isAuthenticated()
            if isAuthenticated == true {
                await checkBiometricLockSetting()
                await checkOnboardingStatus()
                await loadUnitPreference()
                await widgetDataWriter.writeAll()
                await performAutoImportIfNeeded()
                await registerForPushNotifications()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await pendingActionProcessor?.processPendingActions()
                    await loadUnitPreference()
                    await performAutoImportIfNeeded()
                }
            }
            if newPhase == .background && needsBiometricLock {
                isUnlocked = false
            }
        }
    }
}
