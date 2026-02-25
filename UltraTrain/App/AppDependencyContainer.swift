import SwiftUI
import SwiftData
import UserNotifications
import os

@MainActor
struct AppDependencyContainer {

    // MARK: - Persistence

    let modelContainer: ModelContainer

    // MARK: - Networking & Auth

    let apiClient: APIClient
    let authService: AuthService
    let syncService: SyncService
    let syncStatusMonitor: SyncStatusMonitor
    let deviceTokenService: DeviceTokenService
    let networkMonitor: NetworkMonitor

    // MARK: - Repositories

    let athleteRepository: any AthleteRepository
    let raceRepository: any RaceRepository
    let planRepository: any TrainingPlanRepository
    let nutritionRepository: any NutritionRepository
    let runRepository: any RunRepository
    let fitnessRepository: any FitnessRepository
    let appSettingsRepository: any AppSettingsRepository
    let gearRepository: any GearRepository
    let finishEstimateRepository: any FinishEstimateRepository
    let stravaUploadQueueRepository: any StravaUploadQueueRepository
    let recoveryRepository: any RecoveryRepository
    let checklistRepository: any RacePrepChecklistRepository
    let challengeRepository: any ChallengeRepository
    let workoutRecipeRepository: any WorkoutRecipeRepository
    let goalRepository: any GoalRepository
    let routeRepository: any RouteRepository
    let intervalWorkoutRepository: any IntervalWorkoutRepository
    let emergencyContactRepository: any EmergencyContactRepository
    let foodLogRepository: any FoodLogRepository
    let raceReflectionRepository: any RaceReflectionRepository
    let achievementRepository: any AchievementRepository
    let morningCheckInRepository: any MorningCheckInRepository

    // MARK: - Social Repositories

    let socialProfileRepository: any SocialProfileRepository
    let friendRepository: any FriendRepository
    let sharedRunRepository: any SharedRunRepository
    let activityFeedRepository: any ActivityFeedRepository
    let groupChallengeRepository: any GroupChallengeRepository

    // MARK: - Use Cases & Calculators

    let planGenerator: any GenerateTrainingPlanUseCase
    let nutritionGenerator: any GenerateNutritionPlanUseCase
    let fitnessCalculator: any CalculateFitnessUseCase
    let finishTimeEstimator: any EstimateFinishTimeUseCase
    let clearAllDataUseCase: any ClearAllDataUseCase
    let trainingLoadCalculator: TrainingLoadCalculator
    let sessionNutritionAdvisor: any SessionNutritionAdvisor
    let runImportUseCase: DefaultRunImportUseCase

    // MARK: - Services

    let locationService: LocationService
    let healthKitService: HealthKitService
    let hapticService: HapticService
    let connectivityService: PhoneConnectivityService
    let widgetDataWriter: WidgetDataWriter
    let pendingActionProcessor: WidgetPendingActionProcessor
    let exportService: ExportService
    let stravaAuthService: StravaAuthService
    let stravaUploadService: StravaUploadService
    let stravaImportService: StravaImportService
    let stravaUploadQueueService: StravaUploadQueueService
    let notificationService: NotificationService
    let biometricAuthService: BiometricAuthService
    let watchRunImportService: WatchRunImportService
    let planAutoAdjustmentService: DefaultPlanAutoAdjustmentService
    let healthKitImportService: HealthKitImportService
    let weatherService: AppleWeatherKitService
    let motionService: MotionService
    let foodDatabaseService: FoodDatabaseService

    // MARK: - CloudKit

    let cloudKitSyncMonitor: CloudKitSyncMonitor?
    let cloudKitSharingService: (any CloudKitSharingServiceProtocol)?
    let cloudKitCrewService: any CrewTrackingServiceProtocol

    // MARK: - App Infrastructure

    let deepLinkRouter: DeepLinkRouter
    let backgroundTaskService: BackgroundTaskService
    let notificationDelegate: NotificationDelegate
    let deviceIntegrityChecker: DeviceIntegrityChecker
    let backgroundUploadService: BackgroundUploadService

    func configureAppDelegate(_ appDelegate: AppDelegate) {
        appDelegate.onBackgroundSessionCompletion = { [backgroundUploadService] identifier, completion in
            backgroundUploadService.handleSessionCompletion(identifier: identifier, completion: completion)
        }
    }
}
