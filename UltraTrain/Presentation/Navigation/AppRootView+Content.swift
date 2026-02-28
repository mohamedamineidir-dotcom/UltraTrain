import SwiftUI
import UIKit
import UserNotifications
import os

// MARK: - Authenticated Content & Helper Methods

extension AppRootView {

    @ViewBuilder
    var authenticatedContent: some View {
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
                        crewService: crewService,
                        routeRepository: routeRepository,
                        intervalWorkoutRepository: intervalWorkoutRepository,
                        emergencyContactRepository: emergencyContactRepository,
                        motionService: motionService,
                        foodLogRepository: foodLogRepository,
                        foodDatabaseService: foodDatabaseService,
                        raceReflectionRepository: raceReflectionRepository,
                        achievementRepository: achievementRepository,
                        morningCheckInRepository: morningCheckInRepository,
                        authService: authService,
                        onLogout: { isAuthenticated = false }
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
    }

    // MARK: - Helper Methods

    func checkBiometricLockSetting() async {
        do {
            if let settings = try await appSettingsRepository.getSettings() {
                needsBiometricLock = settings.biometricLockEnabled
            }
        } catch {
            Logger.app.error("Failed to check biometric lock setting: \(error)")
        }
    }

    func checkOnboardingStatus() async {
        do {
            let athlete = try await athleteRepository.getAthlete()
            hasCompletedOnboarding = athlete != nil
        } catch {
            Logger.app.error("Failed to check onboarding status: \(error)")
            hasCompletedOnboarding = false
        }
    }

    func performAutoImportIfNeeded() async {
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

    func loadUnitPreference() async {
        do {
            if let athlete = try await athleteRepository.getAthlete() {
                unitPreference = athlete.preferredUnit
            }
        } catch {
            Logger.app.error("Failed to load unit preference: \(error)")
        }
    }

    func registerForPushNotifications() async {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                Logger.app.info("Push notification permission denied")
                return
            }
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            await deviceTokenService?.sendPendingTokenIfNeeded()
        } catch {
            Logger.app.error("Failed to register for push notifications: \(error)")
        }
    }
}
