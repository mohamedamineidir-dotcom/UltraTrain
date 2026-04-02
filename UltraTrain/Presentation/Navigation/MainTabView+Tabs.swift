import SwiftUI

// MARK: - Body & Tab Content

extension MainTabView {
    var body: some View {
        Group {
            if sizeClass == .regular {
                NavigationSplitView {
                    SidebarView(selectedTab: $selectedTab)
                } detail: {
                    tabContent
                }
            } else {
                compactTabView
            }
        }
        .onChange(of: deepLinkRouter.pendingDeepLink) { _, _ in
            handleDeepLink()
        }
        .task { await checkWeeklyReview() }
        .fullScreenCover(isPresented: $showWeeklyReview) {
            if let vm = weeklyReviewViewModel {
                WeeklyReviewSheet(viewModel: vm) {
                    showWeeklyReview = false
                    weeklyReviewViewModel = nil
                }
            }
        }
    }

    // MARK: - Compact (iPhone)

    private var compactTabView: some View {
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
                runRepository: runRepository,
                subscriptionService: subscriptionService,
                stravaAuthService: stravaAuthService,
                stravaImportService: stravaImportService
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
                foodDatabaseService: foodDatabaseService,
                foodPhotoAnalysisService: foodPhotoAnalysisService
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
                crewService: crewService,
                routeRepository: routeRepository,
                emergencyContactRepository: emergencyContactRepository,
                raceReflectionRepository: raceReflectionRepository,
                referralRepository: referralRepository,
                subscriptionService: subscriptionService,
                authService: authService,
                onLogout: onLogout
            )
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
    }

    // MARK: - Deep Link

    // MARK: - Weekly Review

    func checkWeeklyReview() async {
        guard let plan = try? await planRepository.getActivePlan() else { return }
        let result = WeeklyReviewHandler.checkReviewNeeded(
            plan: plan,
            lastReviewedWeekNumber: lastReviewedWeekNumber
        )
        guard result.isNeeded,
              let pwi = result.previousWeekIndex,
              let pwn = result.previousWeekNumber else { return }
        weeklyReviewViewModel = WeeklyReviewViewModel(
            planRepository: planRepository,
            plan: plan,
            previousWeekIndex: pwi,
            previousWeekNumber: pwn,
            nonRestSessions: result.nonRestSessions
        )
        lastReviewedWeekNumber = pwn
        showWeeklyReview = true
    }

    func handleDeepLink() {
        guard let link = deepLinkRouter.consume() else { return }
        switch link {
        case .tab(let tab):
            selectedTab = tab
        case .startRun:
            selectedTab = .run
        case .morningReadiness:
            selectedTab = .dashboard
        case .sharedRun:
            selectedTab = .profile
        case .crewTracking:
            selectedTab = .run
        case .raceDetail:
            selectedTab = .plan
        case .raceNutritionTimer:
            selectedTab = .nutrition
        case .referral:
            selectedTab = .profile
        }
    }
}
