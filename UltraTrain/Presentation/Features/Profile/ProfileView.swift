import SwiftUI

struct ProfileView: View {
    @Environment(\.unitPreference) private var units
    @State private var viewModel: ProfileViewModel
    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let runRepository: any RunRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let finishEstimateRepository: any FinishEstimateRepository
    private let appSettingsRepository: any AppSettingsRepository
    private let clearAllDataUseCase: any ClearAllDataUseCase
    private let healthKitService: any HealthKitServiceProtocol
    private let exportService: any ExportServiceProtocol
    private let stravaAuthService: any StravaAuthServiceProtocol
    private let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    private let notificationService: any NotificationServiceProtocol
    private let planRepository: any TrainingPlanRepository
    private let biometricAuthService: any BiometricAuthServiceProtocol
    private let gearRepository: any GearRepository
    private let nutritionRepository: any NutritionRepository
    private let nutritionGenerator: any GenerateNutritionPlanUseCase
    private let healthKitImportService: (any HealthKitImportServiceProtocol)?
    private let weatherService: (any WeatherServiceProtocol)?
    private let locationService: LocationService?
    private let checklistRepository: any RacePrepChecklistRepository
    private let challengeRepository: any ChallengeRepository
    private let socialProfileRepository: any SocialProfileRepository
    private let friendRepository: any FriendRepository
    private let sharedRunRepository: any SharedRunRepository
    private let activityFeedRepository: any ActivityFeedRepository
    private let groupChallengeRepository: any GroupChallengeRepository

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
        groupChallengeRepository: any GroupChallengeRepository
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
                            healthKitImportService: healthKitImportService
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
                EditRaceSheet(mode: .add) { newRace in
                    Task { await viewModel.addRace(newRace) }
                }
            }
            .sheet(item: $viewModel.raceToEdit) { race in
                EditRaceSheet(mode: .edit(race)) { updated in
                    Task { await viewModel.updateRace(updated) }
                }
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

    private func athleteStatsGrid(_ athlete: Athlete) -> some View {
        Grid(alignment: .leading, horizontalSpacing: Theme.Spacing.lg, verticalSpacing: Theme.Spacing.sm) {
            GridRow {
                statItem(
                    label: "Weight",
                    value: String(format: "%.1f", UnitFormatter.weightValue(athlete.weightKg, unit: units)),
                    unit: UnitFormatter.weightLabel(units)
                )
                statItem(
                    label: "Height",
                    value: UnitFormatter.formatHeight(athlete.heightCm, unit: units),
                    unit: ""
                )
            }
            GridRow {
                statItem(label: "Resting HR", value: "\(athlete.restingHeartRate)", unit: "bpm")
                statItem(label: "Max HR", value: "\(athlete.maxHeartRate)", unit: "bpm")
            }
            GridRow {
                statItem(
                    label: "Weekly Vol",
                    value: String(format: "%.0f", UnitFormatter.distanceValue(athlete.weeklyVolumeKm, unit: units)),
                    unit: UnitFormatter.distanceLabel(units)
                )
                statItem(
                    label: "Longest Run",
                    value: String(format: "%.0f", UnitFormatter.distanceValue(athlete.longestRunKm, unit: units)),
                    unit: UnitFormatter.distanceLabel(units)
                )
            }
        }
    }

    private func statItem(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold().monospacedDigit())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value) \(unit)")
    }

    // MARK: - Races Section

    private var racesSection: some View {
        Section {
            if viewModel.races.isEmpty {
                Label("No races configured", systemImage: "flag.checkered")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                ForEach(viewModel.sortedRaces) { race in
                    NavigationLink {
                        FinishEstimationView(
                            race: race,
                            finishTimeEstimator: finishTimeEstimator,
                            athleteRepository: athleteRepository,
                            runRepository: runRepository,
                            fitnessCalculator: fitnessCalculator,
                            nutritionRepository: nutritionRepository,
                            nutritionGenerator: nutritionGenerator,
                            raceRepository: raceRepository,
                            finishEstimateRepository: finishEstimateRepository,
                            weatherService: weatherService,
                            locationService: locationService,
                            checklistRepository: checklistRepository
                        )
                    } label: {
                        RaceRowView(race: race)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Edit") {
                            viewModel.raceToEdit = race
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { indexSet in
                    let sorted = viewModel.sortedRaces
                    for index in indexSet {
                        Task { await viewModel.deleteRace(id: sorted[index].id) }
                    }
                }
            }
        } header: {
            HStack {
                Text("Races")
                Spacer()
                Button {
                    viewModel.showingAddRace = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .accessibilityLabel("Add Race")
                }
                .accessibilityIdentifier("profile.addRaceButton")
                .accessibilityHint("Opens the form to add a new race")
            }
        }
        .accessibilityIdentifier("profile.racesSection")
    }

    // MARK: - Gear Section

    private var gearSection: some View {
        Section {
            NavigationLink {
                GearListView(
                    gearRepository: gearRepository,
                    runRepository: runRepository
                )
            } label: {
                Label("Gear", systemImage: "shoe.fill")
            }
            .accessibilityIdentifier("profile.gearLink")
        }
    }

    // MARK: - Challenges Section

    private var challengesSection: some View {
        Section {
            NavigationLink {
                ChallengesView(
                    challengeRepository: challengeRepository,
                    runRepository: runRepository,
                    athleteRepository: athleteRepository
                )
            } label: {
                Label("Challenges", systemImage: "trophy.fill")
            }
        }
    }

    // MARK: - Social Section

    private var socialSection: some View {
        Section {
            NavigationLink {
                SocialTabView(
                    friendRepository: friendRepository,
                    profileRepository: socialProfileRepository,
                    athleteRepository: athleteRepository,
                    runRepository: runRepository,
                    activityFeedRepository: activityFeedRepository,
                    sharedRunRepository: sharedRunRepository
                )
            } label: {
                Label("Social", systemImage: "person.2.fill")
            }

            NavigationLink {
                GroupChallengesView(
                    challengeRepository: groupChallengeRepository,
                    profileRepository: socialProfileRepository,
                    friendRepository: friendRepository
                )
            } label: {
                Label("Group Challenges", systemImage: "person.3.fill")
            }
        } header: {
            Text("Social")
        }
    }

}
