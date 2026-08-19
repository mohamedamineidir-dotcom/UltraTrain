import SwiftUI

struct ProfileView: View {
    @Environment(\.unitPreference) var units
    @Environment(PremiumGate.self) var premiumGate: PremiumGate?
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
    let planRepository: any TrainingPlanRepository
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
    let crewService: any CrewTrackingServiceProtocol
    let routeRepository: any RouteRepository
    private let emergencyContactRepository: (any EmergencyContactRepository)?
    let raceReflectionRepository: any RaceReflectionRepository
    private let referralRepository: (any ReferralRepository)?
    private let subscriptionService: (any SubscriptionServiceProtocol)?
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
        crewService: any CrewTrackingServiceProtocol,
        routeRepository: any RouteRepository,
        emergencyContactRepository: (any EmergencyContactRepository)? = nil,
        raceReflectionRepository: any RaceReflectionRepository,
        referralRepository: (any ReferralRepository)? = nil,
        subscriptionService: (any SubscriptionServiceProtocol)? = nil,
        authService: (any AuthServiceProtocol)? = nil,
        onLogout: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: ProfileViewModel(
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            planRepository: planRepository,
            planAutoAdjustmentService: planAutoAdjustmentService,
            runRepository: runRepository,
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
        self.crewService = crewService
        self.routeRepository = routeRepository
        self.emergencyContactRepository = emergencyContactRepository
        self.raceReflectionRepository = raceReflectionRepository
        self.referralRepository = referralRepository
        self.subscriptionService = subscriptionService
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
                    // Referrals are intentionally hidden for launch (no
                    // free trial to anchor the "7 days free" reward to
                    // right now). The underlying repository, ReferralRewardView,
                    // and this `referralSection` stay in place — flip back on
                    // whenever the reward is reintroduced, no migration needed.
                    personalRecordsSection
                    racesSection
                    gearSection
                    routesSection
                    challengesSection
                    // Social section is intentionally hidden from the
                    // profile: a serious training app isn't won on
                    // social, network effects aren't there yet, and
                    // surfacing empty rooms makes the profile feel
                    // generic. The underlying repositories
                    // (socialProfile / friend / sharedRun / activityFeed
                    // / groupChallenge) and `socialSection` view stay
                    // in place, flip back on whenever social becomes a
                    // focus, no data migration needed.
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
                            referralRepository: referralRepository,
                            subscriptionService: subscriptionService,
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
                    finishEstimateRepository: finishEstimateRepository,
                    athleteRepository: athleteRepository
                )
            }
            .confirmationDialog(
                Text(String(localized: "profile.deleteRace.title", defaultValue: "Delete this race?")),
                isPresented: Binding(
                    get: { viewModel.raceToDelete != nil },
                    set: { if !$0 { viewModel.raceToDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: viewModel.raceToDelete
            ) { race in
                Button(role: .destructive) {
                    Task { await viewModel.deleteRace(id: race.id) }
                } label: {
                    Text(String(localized: "profile.deleteRace.confirm", defaultValue: "Delete Race"))
                }
                Button(role: .cancel) {} label: {
                    Text(String(localized: "common.cancel", defaultValue: "Cancel"))
                }
            } message: { race in
                Text(String(
                    format: String(localized: "profile.deleteRace.message",
                                   defaultValue: "%@ will be removed from your calendar and your training plan will adapt around it. This can't be undone."),
                    race.name
                ))
            }
        }
    }

    // MARK: - Referral

    /// Highlighted "get 7 days free" referral entry near the top of the
    /// profile so users immediately see they can earn free access by inviting
    /// a friend.
    @ViewBuilder
    var referralSection: some View {
        if let referralRepository {
            Section {
                NavigationLink {
                    ReferralRewardView(referralRepository: referralRepository)
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "gift.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "referral.profile.title", defaultValue: "Get 7 days free"))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text(String(localized: "referral.profile.sub", defaultValue: "Invite a friend, get a week of full access free."))
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.warmCoral.opacity(0.10))
            )
        }
    }

    // MARK: - Athlete Section

    @ViewBuilder
    private var athleteSection: some View {
        if let athlete = viewModel.athlete {
            // Single full-width glass card carrying header + chips +
            // 3×2 stats grid. Sits inside one List row with the row
            // background cleared so the card's own glass surface
            // shows through, matches the futuristic DNA used on
            // Dashboard / Plan / Session Detail instead of the plain
            // grouped-list look the profile had before.
            Section {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    // Avatar + name row.
                    HStack(spacing: Theme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Theme.Colors.primary.opacity(0.35),
                                            Theme.Colors.primary.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            Image(systemName: "person.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.Colors.primary)
                        }
                        Text("\(athlete.firstName) \(athlete.lastName)")
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)

                    // Chips row. Pulled out of the avatar HStack so
                    // they have the full card width to lay out on
                    // sharing the row with the 44pt avatar squeezed
                    // them and they were wrapping ("Ad-vanced", "22 /
                    // yrs"). `.fixedSize` per chip prevents wrapping
                    // regardless of available width.
                    HStack(spacing: 6) {
                        athleteChip(label: String(localized: "profile.age", defaultValue: "\(athlete.age) yrs"), icon: "calendar")
                        athleteChip(label: athlete.experienceLevel.displayName, icon: "figure.run")
                        athleteChip(label: athlete.preferredUnit == .metric
                            ? String(localized: "unit.metric", defaultValue: "Metric")
                            : String(localized: "unit.imperial", defaultValue: "Imperial"), icon: "ruler")
                        Spacer(minLength: 0)
                    }

                    Divider().opacity(0.15)

                    athleteStatsGrid(athlete)

                    // HR Zones nav row. Just label content, the
                    // NavigationLink supplies its own trailing chevron,
                    // adding a second one was the source of the double
                    // arrow.
                    NavigationLink {
                        HRZoneConfigurationView(athlete: athlete) { updated in
                            Task { await viewModel.updateAthlete(updated) }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.text.square")
                                .foregroundStyle(Theme.Colors.warmCoral)
                            Text("HR Zones")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.Colors.label)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(Theme.Spacing.md)
                .futuristicGlassStyle(phaseTint: Theme.Colors.primary)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
            }
            .accessibilityIdentifier("profile.athleteSection")
        } else {
            Section {
                Label("Complete onboarding to see your profile", systemImage: "person.crop.circle")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .padding(Theme.Spacing.md)
                    .futuristicGlassStyle()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
            }
            .accessibilityIdentifier("profile.athleteSection")
        }
    }

    private func athleteChip(label: String, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
        }
        .foregroundStyle(Theme.Colors.secondaryLabel)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(Theme.Colors.label.opacity(0.06))
        )
        .overlay(
            Capsule().stroke(Theme.Colors.label.opacity(0.08), lineWidth: 0.5)
        )
        // Lock the chip to its intrinsic width so adjacent chips never
        // share-the-shrink with each other when the row is narrow
        // each one gets exactly the width it needs and the row scrolls
        // / clips before any chip wraps.
        .fixedSize(horizontal: true, vertical: false)
    }

}
