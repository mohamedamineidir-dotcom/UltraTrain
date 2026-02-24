import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

    let deepLinkRouter: DeepLinkRouter

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
    private let foodDatabaseService: (any FoodDatabaseServiceProtocol)?
    private let raceReflectionRepository: any RaceReflectionRepository
    private let achievementRepository: (any AchievementRepository)?
    private let morningCheckInRepository: (any MorningCheckInRepository)?
    private let authService: (any AuthServiceProtocol)?
    var onLogout: (() -> Void)?

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
        foodDatabaseService: (any FoodDatabaseServiceProtocol)? = nil,
        raceReflectionRepository: any RaceReflectionRepository,
        achievementRepository: (any AchievementRepository)? = nil,
        morningCheckInRepository: (any MorningCheckInRepository)? = nil,
        authService: (any AuthServiceProtocol)? = nil,
        onLogout: (() -> Void)? = nil
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
        self.foodDatabaseService = foodDatabaseService
        self.raceReflectionRepository = raceReflectionRepository
        self.achievementRepository = achievementRepository
        self.morningCheckInRepository = morningCheckInRepository
        self.authService = authService
        self.onLogout = onLogout
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                selectedTab: $selectedTab,
                planRepository: planRepository,
                runRepository: runRepository,
                athleteRepository: athleteRepository,
                fitnessRepository: fitnessRepository,
                fitnessCalculator: fitnessCalculator,
                trainingLoadCalculator: trainingLoadCalculator,
                raceRepository: raceRepository,
                finishTimeEstimator: finishTimeEstimator,
                finishEstimateRepository: finishEstimateRepository,
                nutritionRepository: nutritionRepository,
                nutritionGenerator: nutritionGenerator,
                healthKitService: healthKitService,
                recoveryRepository: recoveryRepository,
                checklistRepository: checklistRepository,
                weatherService: weatherService,
                locationService: locationService,
                challengeRepository: challengeRepository,
                goalRepository: goalRepository,
                achievementRepository: achievementRepository,
                morningCheckInRepository: morningCheckInRepository
            )
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)

            TrainingPlanView(
                planRepository: planRepository,
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                planGenerator: planGenerator,
                nutritionRepository: nutritionRepository,
                sessionNutritionAdvisor: sessionNutritionAdvisor,
                fitnessRepository: fitnessRepository,
                widgetDataWriter: widgetDataWriter,
                workoutRecipeRepository: workoutRecipeRepository,
                runRepository: runRepository
            )
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
                .tag(Tab.plan)

            RunTrackingLaunchView(
                athleteRepository: athleteRepository,
                planRepository: planRepository,
                runRepository: runRepository,
                raceRepository: raceRepository,
                locationService: locationService,
                healthKitService: healthKitService,
                appSettingsRepository: appSettingsRepository,
                nutritionRepository: nutritionRepository,
                hapticService: hapticService,
                connectivityService: connectivityService,
                widgetDataWriter: widgetDataWriter,
                exportService: exportService,
                runImportUseCase: runImportUseCase,
                stravaUploadService: stravaUploadService,
                stravaUploadQueueService: stravaUploadQueueService,
                stravaImportService: stravaImportService,
                stravaAuthService: stravaAuthService,
                gearRepository: gearRepository,
                finishTimeEstimator: finishTimeEstimator,
                finishEstimateRepository: finishEstimateRepository,
                weatherService: weatherService,
                recoveryRepository: recoveryRepository,
                intervalWorkoutRepository: intervalWorkoutRepository,
                emergencyContactRepository: emergencyContactRepository,
                motionService: motionService
            )
                .tabItem {
                    Label("Run", systemImage: "figure.run")
                }
                .tag(Tab.run)

            NutritionView(
                nutritionRepository: nutritionRepository,
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                planRepository: planRepository,
                nutritionGenerator: nutritionGenerator,
                foodLogRepository: foodLogRepository,
                sessionNutritionAdvisor: sessionNutritionAdvisor,
                foodDatabaseService: foodDatabaseService
            )
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
                .tag(Tab.nutrition)

            ProfileView(
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                runRepository: runRepository,
                fitnessCalculator: fitnessCalculator,
                finishTimeEstimator: finishTimeEstimator,
                finishEstimateRepository: finishEstimateRepository,
                appSettingsRepository: appSettingsRepository,
                clearAllDataUseCase: clearAllDataUseCase,
                healthKitService: healthKitService,
                widgetDataWriter: widgetDataWriter,
                exportService: exportService,
                stravaAuthService: stravaAuthService,
                stravaUploadQueueService: stravaUploadQueueService,
                notificationService: notificationService,
                planRepository: planRepository,
                biometricAuthService: biometricAuthService,
                gearRepository: gearRepository,
                planAutoAdjustmentService: planAutoAdjustmentService,
                nutritionRepository: nutritionRepository,
                nutritionGenerator: nutritionGenerator,
                healthKitImportService: healthKitImportService,
                weatherService: weatherService,
                locationService: locationService,
                checklistRepository: checklistRepository,
                challengeRepository: challengeRepository,
                socialProfileRepository: socialProfileRepository,
                friendRepository: friendRepository,
                sharedRunRepository: sharedRunRepository,
                activityFeedRepository: activityFeedRepository,
                groupChallengeRepository: groupChallengeRepository,
                routeRepository: routeRepository,
                emergencyContactRepository: emergencyContactRepository,
                raceReflectionRepository: raceReflectionRepository,
                authService: authService,
                onLogout: onLogout
            )
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .onChange(of: deepLinkRouter.pendingDeepLink) { _, newLink in
            guard let link = deepLinkRouter.consume() else { return }
            switch link {
            case .tab(let tab):
                selectedTab = tab
            case .startRun:
                selectedTab = .run
            case .morningReadiness:
                selectedTab = .dashboard
            }
        }
    }
}

enum Tab: Hashable {
    case dashboard
    case plan
    case run
    case nutrition
    case profile
}
