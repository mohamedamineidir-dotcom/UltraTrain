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
                    switch hasActiveSubscription {
                    case .none:
                        ProgressView("Loading...")
                    case .some:
                        // Freemium: onboarded users always enter the app.
                        // Free users (inactive) get a one-time, dismissable
                        // trial offer; premium features stay locked in-app
                        // until they subscribe or start the trial.
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
                            foodPhotoAnalysisService: foodPhotoAnalysisService,
                            raceReflectionRepository: raceReflectionRepository,
                            achievementRepository: achievementRepository,
                            morningCheckInRepository: morningCheckInRepository,
                            intervalPerformanceRepository: intervalPerformanceRepository,
                            referralRepository: referralRepository,
                            subscriptionService: subscriptionService,
                            authService: authService,
                            onLogout: {
                                hasCompletedOnboarding = nil
                                hasActiveSubscription = nil
                                cachedFirstName = nil
                                pendingFirstName = nil
                                pendingLastName = nil
                                isAuthenticated = false
                            }
                        )
                        .fullScreenCover(isPresented: $showFeatureTour) {
                            FeatureTourView {
                                hasSeenFeatureTour = true
                                showFeatureTour = false
                            }
                        }
                        .fullScreenCover(
                            isPresented: $showInitialOffer,
                            onDismiss: { hasSeenInitialPaywallOffer = true }
                        ) {
                            PaywallView(
                                subscriptionService: subscriptionService,
                                firstName: cachedFirstName ?? pendingFirstName ?? "Runner",
                                isDismissable: true,
                                onSubscribed: {
                                    hasActiveSubscription = true
                                    showInitialOffer = false
                                    if !hasSeenFeatureTour {
                                        showFeatureTour = true
                                    }
                                },
                                onDismiss: { showInitialOffer = false }
                            )
                        }
                        .task(id: hasActiveSubscription) {
                            // Show the one-time trial offer once a free user
                            // lands in the app. Premium / trial users skip it.
                            if hasActiveSubscription == false, !hasSeenInitialPaywallOffer {
                                showInitialOffer = true
                            }
                        }
                    }
                case .some(false):
                    OnboardingView(
                        athleteRepository: athleteRepository,
                        raceRepository: raceRepository,
                        healthKitService: healthKitService,
                        healthKitImportService: healthKitImportService,
                        initialFirstName: pendingFirstName,
                        initialLastName: pendingLastName,
                        onComplete: {
                            // Present the initial offer in the SAME state change
                            // that reveals the main app, so the paywall covers
                            // from the first frame instead of the app flashing
                            // for an instant before the cover animates in.
                            if !hasSeenInitialPaywallOffer {
                                showInitialOffer = true
                            }
                            hasCompletedOnboarding = true
                            hasActiveSubscription = false
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
            cachedFirstName = athlete?.firstName
        } catch {
            Logger.app.error("Failed to check onboarding status: \(error)")
            hasCompletedOnboarding = false
        }
    }

    func checkSubscriptionStatus() async {
        // Use cached status first so user isn't blocked by a slow StoreKit query
        if subscriptionService.currentStatus.isActive {
            hasActiveSubscription = true
        }
        // Then verify with StoreKit (updates cache if status changed)
        let status = await subscriptionService.refreshStatus()
        hasActiveSubscription = status.isActive
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
