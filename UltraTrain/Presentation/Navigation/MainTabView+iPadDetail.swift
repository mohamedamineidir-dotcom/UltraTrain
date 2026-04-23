import SwiftUI

// MARK: - iPad Detail Content

extension MainTabView {
    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case .dashboard:
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
                morningCheckInRepository: morningCheckInRepository
            )

        case .plan:
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
                runRepository: runRepository,
                subscriptionService: subscriptionService,
                stravaAuthService: stravaAuthService,
                stravaImportService: stravaImportService,
                intervalPerformanceRepository: intervalPerformanceRepository
            )

        case .run:
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

        case .nutrition:
            NutritionView(
                nutritionRepository: nutritionRepository,
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                planRepository: planRepository,
                nutritionGenerator: nutritionGenerator,
                foodLogRepository: foodLogRepository,
                sessionNutritionAdvisor: sessionNutritionAdvisor,
                foodDatabaseService: foodDatabaseService,
                foodPhotoAnalysisService: foodPhotoAnalysisService
            )

        case .profile:
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
                crewService: crewService,
                routeRepository: routeRepository,
                emergencyContactRepository: emergencyContactRepository,
                raceReflectionRepository: raceReflectionRepository,
                referralRepository: referralRepository,
                subscriptionService: subscriptionService,
                authService: authService,
                onLogout: onLogout
            )
        }
    }
}
