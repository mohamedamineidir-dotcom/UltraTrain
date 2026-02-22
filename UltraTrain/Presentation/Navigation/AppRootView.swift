import SwiftUI
import os

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasCompletedOnboarding: Bool?
    @State private var isUnlocked = false
    @State private var needsBiometricLock = false
    @State private var showFeatureTour = false
    @AppStorage("hasSeenFeatureTour") private var hasSeenFeatureTour = false
    @State private var unitPreference: UnitPreference = .metric
    @State private var lastAutoImportDate: Date?
    private let deepLinkRouter: DeepLinkRouter

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
    private let healthKitService: any HealthKitServiceProtocol
    private let hapticService: any HapticServiceProtocol
    private let trainingLoadCalculator: any CalculateTrainingLoadUseCase
    private let sessionNutritionAdvisor: any SessionNutritionAdvisor
    private let connectivityService: PhoneConnectivityService?
    private let widgetDataWriter: WidgetDataWriter
    private let exportService: any ExportServiceProtocol
    private let runImportUseCase: any RunImportUseCase
    private let stravaAuthService: any StravaAuthServiceProtocol
    private let stravaUploadService: (any StravaUploadServiceProtocol)?
    private let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    private let stravaImportService: (any StravaImportServiceProtocol)?
    private let notificationService: any NotificationServiceProtocol
    private let biometricAuthService: any BiometricAuthServiceProtocol
    private let gearRepository: any GearRepository
    private let finishEstimateRepository: any FinishEstimateRepository
    private let planAutoAdjustmentService: any PlanAutoAdjustmentService
    private let pendingActionProcessor: WidgetPendingActionProcessor?
    private let healthKitImportService: (any HealthKitImportServiceProtocol)?
    private let weatherService: (any WeatherServiceProtocol)?
    private let recoveryRepository: any RecoveryRepository
    private let checklistRepository: any RacePrepChecklistRepository
    private let challengeRepository: any ChallengeRepository
    private let workoutRecipeRepository: any WorkoutRecipeRepository
    private let goalRepository: any GoalRepository
    private let socialProfileRepository: any SocialProfileRepository
    private let friendRepository: any FriendRepository
    private let sharedRunRepository: any SharedRunRepository
    private let activityFeedRepository: any ActivityFeedRepository
    private let groupChallengeRepository: any GroupChallengeRepository
    private let routeRepository: any RouteRepository
    private let intervalWorkoutRepository: (any IntervalWorkoutRepository)?
    private let emergencyContactRepository: (any EmergencyContactRepository)?
    private let motionService: (any MotionServiceProtocol)?
    private let foodLogRepository: any FoodLogRepository
    private let raceReflectionRepository: any RaceReflectionRepository

    init(
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
        routeRepository: any RouteRepository,
        intervalWorkoutRepository: (any IntervalWorkoutRepository)? = nil,
        emergencyContactRepository: (any EmergencyContactRepository)? = nil,
        motionService: (any MotionServiceProtocol)? = nil,
        foodLogRepository: any FoodLogRepository,
        raceReflectionRepository: any RaceReflectionRepository
    ) {
        self.deepLinkRouter = deepLinkRouter
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
        self.routeRepository = routeRepository
        self.intervalWorkoutRepository = intervalWorkoutRepository
        self.emergencyContactRepository = emergencyContactRepository
        self.motionService = motionService
        self.foodLogRepository = foodLogRepository
        self.raceReflectionRepository = raceReflectionRepository
    }

    var body: some View {
        Group {
            if needsBiometricLock && !isUnlocked {
                AppLockView(biometricService: biometricAuthService) {
                    isUnlocked = true
                }
            } else {
                switch hasCompletedOnboarding {
                case .none:
                    ProgressView("Loading...")
                case .some(true):
                    MainTabView(
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
                        raceReflectionRepository: raceReflectionRepository
                    )
                    .fullScreenCover(isPresented: $showFeatureTour) {
                        FeatureTourView {
                            hasSeenFeatureTour = true
                            showFeatureTour = false
                        }
                    }
                case .some(false):
                    OnboardingView(
                        athleteRepository: athleteRepository,
                        raceRepository: raceRepository,
                        healthKitService: healthKitService,
                        onComplete: {
                            hasCompletedOnboarding = true
                            if !hasSeenFeatureTour {
                                showFeatureTour = true
                            }
                        }
                    )
                }
            }
        }
        .environment(\.unitPreference, unitPreference)
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-UITestSkipOnboarding") {
                hasCompletedOnboarding = true
                return
            }
            #endif
            await checkBiometricLockSetting()
            await checkOnboardingStatus()
            await loadUnitPreference()
            await widgetDataWriter.writeAll()
            await performAutoImportIfNeeded()
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

    private func checkBiometricLockSetting() async {
        do {
            if let settings = try await appSettingsRepository.getSettings() {
                needsBiometricLock = settings.biometricLockEnabled
            }
        } catch {
            Logger.app.error("Failed to check biometric lock setting: \(error)")
        }
    }

    private func checkOnboardingStatus() async {
        do {
            let athlete = try await athleteRepository.getAthlete()
            hasCompletedOnboarding = athlete != nil
        } catch {
            Logger.app.error("Failed to check onboarding status: \(error)")
            hasCompletedOnboarding = false
        }
    }

    private func performAutoImportIfNeeded() async {
        guard let importService = healthKitImportService else { return }
        let importer = BackgroundAutoImporter(
            healthKitService: healthKitService,
            appSettingsRepository: appSettingsRepository,
            athleteRepository: athleteRepository,
            importService: importService
        )
        let check = await importer.importIfNeeded(lastImportDate: lastAutoImportDate)
        lastAutoImportDate = check.importDate
    }

    private func loadUnitPreference() async {
        do {
            if let athlete = try await athleteRepository.getAthlete() {
                unitPreference = athlete.preferredUnit
            }
        } catch {
            Logger.app.error("Failed to load unit preference: \(error)")
        }
    }
}
