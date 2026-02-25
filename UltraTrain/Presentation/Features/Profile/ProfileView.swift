import SwiftUI

struct ProfileView: View {
    @Environment(\.unitPreference) var units
    @State var viewModel: ProfileViewModel
    let athleteRepository: any AthleteRepository
    let raceRepository: any RaceRepository
    let runRepository: any RunRepository
    let fitnessCalculator: any CalculateFitnessUseCase
    let finishTimeEstimator: any EstimateFinishTimeUseCase
    let finishEstimateRepository: any FinishEstimateRepository
    private let appSettingsRepository: any AppSettingsRepository
    private let clearAllDataUseCase: any ClearAllDataUseCase
    private let healthKitService: any HealthKitServiceProtocol
    private let exportService: any ExportServiceProtocol
    private let stravaAuthService: any StravaAuthServiceProtocol
    private let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    private let notificationService: any NotificationServiceProtocol
    private let planRepository: any TrainingPlanRepository
    private let biometricAuthService: any BiometricAuthServiceProtocol
    let gearRepository: any GearRepository
    let nutritionRepository: any NutritionRepository
    let nutritionGenerator: any GenerateNutritionPlanUseCase
    private let healthKitImportService: (any HealthKitImportServiceProtocol)?
    let weatherService: (any WeatherServiceProtocol)?
    let locationService: LocationService?
    let checklistRepository: any RacePrepChecklistRepository
    let challengeRepository: any ChallengeRepository
    let socialProfileRepository: any SocialProfileRepository
    let friendRepository: any FriendRepository
    let sharedRunRepository: any SharedRunRepository
    let activityFeedRepository: any ActivityFeedRepository
    let groupChallengeRepository: any GroupChallengeRepository
    let routeRepository: any RouteRepository
    private let emergencyContactRepository: (any EmergencyContactRepository)?
    let raceReflectionRepository: any RaceReflectionRepository
    private let authService: (any AuthServiceProtocol)?
    var onLogout: (() -> Void)?

    init(
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        runRepository: any RunRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        finishEstimateRepository: any FinishEstimateRepository,
        appSettingsRepository: any AppSettingsRepository,
        clearAllDataUseCase: any ClearAllDataUseCase,
        healthKitService: any HealthKitServiceProtocol,
        widgetDataWriter: WidgetDataWriter,
        exportService: any ExportServiceProtocol,
        stravaAuthService: any StravaAuthServiceProtocol,
        stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)? = nil,
        notificationService: any NotificationServiceProtocol,
        planRepository: any TrainingPlanRepository,
        biometricAuthService: any BiometricAuthServiceProtocol,
        gearRepository: any GearRepository,
        planAutoAdjustmentService: any PlanAutoAdjustmentService,
        nutritionRepository: any NutritionRepository,
        nutritionGenerator: any GenerateNutritionPlanUseCase,
        healthKitImportService: (any HealthKitImportServiceProtocol)? = nil,
        weatherService: (any WeatherServiceProtocol)? = nil,
        locationService: LocationService? = nil,
        checklistRepository: any RacePrepChecklistRepository,
        challengeRepository: any ChallengeRepository,
        socialProfileRepository: any SocialProfileRepository,
        friendRepository: any FriendRepository,
        sharedRunRepository: any SharedRunRepository,
        activityFeedRepository: any ActivityFeedRepository,
        groupChallengeRepository: any GroupChallengeRepository,
        routeRepository: any RouteRepository,
        emergencyContactRepository: (any EmergencyContactRepository)? = nil,
        raceReflectionRepository: any RaceReflectionRepository,
        authService: (any AuthServiceProtocol)? = nil,
        onLogout: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: ProfileViewModel(
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            planRepository: planRepository,
            planAutoAdjustmentService: planAutoAdjustmentService,
            widgetDataWriter: widgetDataWriter
        ))
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.runRepository = runRepository
        self.fitnessCalculator = fitnessCalculator
        self.finishTimeEstimator = finishTimeEstimator
        self.finishEstimateRepository = finishEstimateRepository
        self.appSettingsRepository = appSettingsRepository
        self.clearAllDataUseCase = clearAllDataUseCase
        self.healthKitService = healthKitService
        self.exportService = exportService
        self.stravaAuthService = stravaAuthService
        self.stravaUploadQueueService = stravaUploadQueueService
        self.notificationService = notificationService
        self.planRepository = planRepository
        self.biometricAuthService = biometricAuthService
        self.gearRepository = gearRepository
        self.nutritionRepository = nutritionRepository
        self.nutritionGenerator = nutritionGenerator
        self.healthKitImportService = healthKitImportService
        self.weatherService = weatherService
        self.locationService = locationService
        self.checklistRepository = checklistRepository
        self.challengeRepository = challengeRepository
        self.socialProfileRepository = socialProfileRepository
        self.friendRepository = friendRepository
        self.sharedRunRepository = sharedRunRepository
        self.activityFeedRepository = activityFeedRepository
        self.groupChallengeRepository = groupChallengeRepository
        self.routeRepository = routeRepository
        self.emergencyContactRepository = emergencyContactRepository
        self.raceReflectionRepository = raceReflectionRepository
        self.authService = authService
        self.onLogout = onLogout
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    athleteSection
                    racesSection
                    gearSection
                    routesSection
                    challengesSection
                    socialSection
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                if viewModel.athlete != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") {
                            viewModel.showingEditAthlete = true
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(
                            athleteRepository: athleteRepository,
                            appSettingsRepository: appSettingsRepository,
                            clearAllDataUseCase: clearAllDataUseCase,
                            healthKitService: healthKitService,
                            exportService: exportService,
                            runRepository: runRepository,
                            stravaAuthService: stravaAuthService,
                            stravaUploadQueueService: stravaUploadQueueService,
                            notificationService: notificationService,
                            planRepository: planRepository,
                            raceRepository: raceRepository,
                            biometricAuthService: biometricAuthService,
                            healthKitImportService: healthKitImportService,
                            emergencyContactRepository: emergencyContactRepository,
                            authService: authService,
                            onLogout: onLogout
                        )
                    } label: {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
                    }
                    .accessibilityIdentifier("profile.settingsButton")
                }
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .sheet(isPresented: $viewModel.showingEditAthlete) {
                if let athlete = viewModel.athlete {
                    EditAthleteSheet(athlete: athlete) { updated in
                        Task { await viewModel.updateAthlete(updated) }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if viewModel.planWasAutoAdjusted {
                    Text("Training plan updated")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.primary, in: Capsule())
                        .padding(.bottom, Theme.Spacing.md)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            Task {
                                try? await Task.sleep(for: .seconds(3))
                                withAnimation { viewModel.planWasAutoAdjusted = false }
                            }
                        }
                }
            }
            .animation(.easeInOut, value: viewModel.planWasAutoAdjusted)
            .sheet(isPresented: $viewModel.showingAddRace) {
                EditRaceSheet(mode: .add, routeRepository: routeRepository) { newRace in
                    Task { await viewModel.addRace(newRace) }
                }
            }
            .sheet(item: $viewModel.raceToEdit) { race in
                EditRaceSheet(mode: .edit(race), routeRepository: routeRepository) { updated in
                    Task { await viewModel.updateRace(updated) }
                }
            }
            .sheet(item: $viewModel.showingPostRaceWizard) { race in
                PostRaceWizardView(
                    race: race,
                    raceRepository: raceRepository,
                    raceReflectionRepository: raceReflectionRepository,
                    runRepository: runRepository,
                    finishEstimateRepository: finishEstimateRepository
                )
            }
        }
    }

    // MARK: - Athlete Section

    @ViewBuilder
    private var athleteSection: some View {
        if let athlete = viewModel.athlete {
            Section("Athlete") {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("\(athlete.firstName) \(athlete.lastName)")
                        .font(.title3.bold())
                    HStack(spacing: Theme.Spacing.md) {
                        Label("\(athlete.age) yrs", systemImage: "calendar")
                        Label(athlete.experienceLevel.rawValue.capitalized, systemImage: "figure.run")
                        Label(athlete.preferredUnit.rawValue.capitalized, systemImage: "ruler")
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                .accessibilityElement(children: .combine)
                athleteStatsGrid(athlete)
                NavigationLink {
                    HRZoneConfigurationView(athlete: athlete) { updated in
                        Task { await viewModel.updateAthlete(updated) }
                    }
                } label: {
                    Label("HR Zones", systemImage: "heart.text.square")
                }
            }
            .accessibilityIdentifier("profile.athleteSection")
        } else {
            Section("Athlete") {
                Label("Complete onboarding to see your profile", systemImage: "person.crop.circle")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .accessibilityIdentifier("profile.athleteSection")
        }
    }

}
