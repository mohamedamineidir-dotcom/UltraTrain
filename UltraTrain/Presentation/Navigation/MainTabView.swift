import SwiftUI

struct MainTabView: View {
    @State var selectedTab: Tab = .dashboard

    let deepLinkRouter: DeepLinkRouter

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
    let routeRepository: any RouteRepository
    let intervalWorkoutRepository: (any IntervalWorkoutRepository)?
    let emergencyContactRepository: (any EmergencyContactRepository)?
    let motionService: (any MotionServiceProtocol)?
    let foodLogRepository: any FoodLogRepository
    let foodDatabaseService: (any FoodDatabaseServiceProtocol)?
    let raceReflectionRepository: any RaceReflectionRepository
    let achievementRepository: (any AchievementRepository)?
    let morningCheckInRepository: (any MorningCheckInRepository)?
    let authService: (any AuthServiceProtocol)?
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
}

enum Tab: Hashable {
    case dashboard
    case plan
    case run
    case nutrition
    case profile
}
