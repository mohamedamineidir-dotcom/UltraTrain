import SwiftUI

struct RunTrackingLaunchView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var heroIconSize: CGFloat = 60
    @State private var viewModel: RunTrackingLaunchViewModel
    private let athleteRepository: any AthleteRepository
    private let locationService: LocationService
    private let healthKitService: any HealthKitServiceProtocol
    private let runRepository: any RunRepository
    private let planRepository: any TrainingPlanRepository
    private let raceRepository: any RaceRepository
    private let nutritionRepository: any NutritionRepository
    private let hapticService: any HapticServiceProtocol
    private let connectivityService: PhoneConnectivityService?
    private let widgetDataWriter: WidgetDataWriter?
    private let exportService: any ExportServiceProtocol
    private let runImportUseCase: any RunImportUseCase
    private let stravaUploadService: (any StravaUploadServiceProtocol)?
    private let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    private let stravaImportService: (any StravaImportServiceProtocol)?
    private let stravaAuthService: any StravaAuthServiceProtocol
    private let gearRepository: any GearRepository
    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let finishEstimateRepository: any FinishEstimateRepository
    private let weatherService: (any WeatherServiceProtocol)?

    init(
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        raceRepository: any RaceRepository,
        locationService: LocationService,
        healthKitService: any HealthKitServiceProtocol,
        appSettingsRepository: any AppSettingsRepository,
        nutritionRepository: any NutritionRepository,
        hapticService: any HapticServiceProtocol,
        connectivityService: PhoneConnectivityService? = nil,
        widgetDataWriter: WidgetDataWriter? = nil,
        exportService: any ExportServiceProtocol,
        runImportUseCase: any RunImportUseCase,
        stravaUploadService: (any StravaUploadServiceProtocol)? = nil,
        stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)? = nil,
        stravaImportService: (any StravaImportServiceProtocol)? = nil,
        stravaAuthService: any StravaAuthServiceProtocol,
        gearRepository: any GearRepository,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        finishEstimateRepository: any FinishEstimateRepository,
        weatherService: (any WeatherServiceProtocol)? = nil
    ) {
        _viewModel = State(initialValue: RunTrackingLaunchViewModel(
            athleteRepository: athleteRepository,
            planRepository: planRepository,
            runRepository: runRepository,
            raceRepository: raceRepository,
            appSettingsRepository: appSettingsRepository,
            hapticService: hapticService,
            gearRepository: gearRepository,
            finishTimeEstimator: finishTimeEstimator,
            finishEstimateRepository: finishEstimateRepository,
            weatherService: weatherService,
            locationService: locationService
        ))
        self.athleteRepository = athleteRepository
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.raceRepository = raceRepository
        self.nutritionRepository = nutritionRepository
        self.hapticService = hapticService
        self.connectivityService = connectivityService
        self.widgetDataWriter = widgetDataWriter
        self.exportService = exportService
        self.runImportUseCase = runImportUseCase
        self.stravaUploadService = stravaUploadService
        self.stravaUploadQueueService = stravaUploadQueueService
        self.stravaImportService = stravaImportService
        self.stravaAuthService = stravaAuthService
        self.gearRepository = gearRepository
        self.finishTimeEstimator = finishTimeEstimator
        self.finishEstimateRepository = finishEstimateRepository
        self.weatherService = weatherService
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    locationAuthSection
                    heroSection
                    PreRunWeatherCard(
                        weather: viewModel.preRunWeather,
                        isLoading: viewModel.isLoading
                    )
                    .padding(.horizontal, Theme.Spacing.md)
                    if let race = viewModel.todaysRace {
                        raceDayBanner(race: race)
                    }
                    if !viewModel.todaysSessions.isEmpty {
                        SessionPickerView(
                            sessions: viewModel.todaysSessions,
                            selectedSession: $viewModel.selectedSession
                        )
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                    if viewModel.selectedSession?.isGutTrainingRecommended == true {
                        gutTrainingBanner
                    }
                    if !viewModel.activeGear.isEmpty {
                        GearPickerView(
                            gearItems: viewModel.activeGear,
                            selectedGearIds: $viewModel.selectedGearIds
                        )
                    }
                    startButton
                    historyLink
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .navigationTitle("Run")
            .task { await viewModel.load() }
            .onChange(of: viewModel.showActiveRun) { _, isShowing in
                if !isShowing {
                    viewModel.onRunSaved()
                }
            }
            .navigationDestination(isPresented: $viewModel.showActiveRun) {
                if let athlete = viewModel.athlete {
                    ActiveRunView(
                        viewModel: ActiveRunViewModel(
                            locationService: locationService,
                            healthKitService: healthKitService,
                            runRepository: runRepository,
                            planRepository: planRepository,
                            raceRepository: raceRepository,
                            nutritionRepository: nutritionRepository,
                            hapticService: hapticService,
                            connectivityService: connectivityService,
                            widgetDataWriter: widgetDataWriter,
                            stravaUploadQueueService: stravaUploadQueueService,
                            gearRepository: gearRepository,
                            finishEstimateRepository: finishEstimateRepository,
                            weatherService: weatherService,
                            athlete: athlete,
                            linkedSession: viewModel.selectedSession,
                            autoPauseEnabled: viewModel.autoPauseEnabled,
                            nutritionRemindersEnabled: viewModel.nutritionRemindersEnabled,
                            nutritionAlertSoundEnabled: viewModel.nutritionAlertSoundEnabled,
                            hydrationIntervalSeconds: viewModel.hydrationIntervalSeconds,
                            fuelIntervalSeconds: viewModel.fuelIntervalSeconds,
                            electrolyteIntervalSeconds: viewModel.electrolyteIntervalSeconds,
                            smartRemindersEnabled: viewModel.smartRemindersEnabled,
                            stravaAutoUploadEnabled: viewModel.stravaAutoUploadEnabled,
                            saveToHealthEnabled: viewModel.saveToHealthEnabled,
                            raceId: viewModel.raceId,
                            selectedGearIds: Array(viewModel.selectedGearIds)
                        ),
                        exportService: exportService
                    )
                }
            }
        }
    }

    // MARK: - Location Auth

    @ViewBuilder
    private var locationAuthSection: some View {
        switch locationService.authorizationStatus {
        case .notDetermined:
            authBanner(
                message: "Location access is needed to track your runs.",
                buttonLabel: "Allow Location"
            ) {
                locationService.requestWhenInUseAuthorization()
            }
        case .denied:
            authBanner(
                message: "Location access is denied. Enable it in Settings to track runs.",
                buttonLabel: "Open Settings"
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        case .authorizedWhenInUse, .authorizedAlways:
            EmptyView()
        }
    }

    private func authBanner(message: String, buttonLabel: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(message).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(Theme.Colors.warning)
            Button(buttonLabel, action: action).buttonStyle(.bordered)
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Theme.Colors.warning.opacity(0.1)))
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "figure.run")
                .font(.system(size: heroIconSize))
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)
            Text("Ready to Run?")
                .font(.title.bold())
            Text("Track your run with GPS, pace, and elevation.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.xl)
    }

    // MARK: - Start

    private var startButton: some View {
        Button {
            viewModel.startRun()
        } label: {
            Label("Start Run", systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal, Theme.Spacing.md)
        .disabled(
            viewModel.athlete == nil
            || locationService.authorizationStatus == .denied
            || locationService.authorizationStatus == .notDetermined
        )
        .accessibilityIdentifier("runTracking.startButton")
    }

    // MARK: - History

    // MARK: - Race Day Banner

    private func raceDayBanner(race: Race) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "flag.checkered").font(.title3).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Race Day: \(race.name)").font(.subheadline.bold())
                Text("This run will be linked to your race for finish time calibration.")
                    .font(.caption).foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Theme.Colors.primary.opacity(0.1)))
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Gut Training

    private var gutTrainingBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "fork.knife").font(.title3).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Gut Training Session").font(.subheadline.bold())
                Text("Practice your race-day nutrition during this run.")
                    .font(.caption).foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Theme.Colors.primary.opacity(0.08)))
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - History

    private var historyLink: some View {
        NavigationLink {
            RunHistoryView(
                runRepository: runRepository,
                planRepository: planRepository,
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                exportService: exportService,
                runImportUseCase: runImportUseCase,
                stravaUploadService: stravaUploadService,
                stravaUploadQueueService: stravaUploadQueueService,
                stravaImportService: stravaImportService,
                stravaConnected: stravaAuthService.isConnected(),
                finishEstimateRepository: finishEstimateRepository,
                gearRepository: gearRepository
            )
        } label: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .accessibilityHidden(true)
                Text("Run History")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.md)
    }
}
