import SwiftUI

struct RunTrackingLaunchView: View {
    @State private var viewModel: RunTrackingLaunchViewModel
    private let athleteRepository: any AthleteRepository
    private let locationService: LocationService
    private let healthKitService: any HealthKitServiceProtocol
    private let runRepository: any RunRepository
    private let planRepository: any TrainingPlanRepository
    private let nutritionRepository: any NutritionRepository

    init(
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        locationService: LocationService,
        healthKitService: any HealthKitServiceProtocol,
        appSettingsRepository: any AppSettingsRepository,
        nutritionRepository: any NutritionRepository
    ) {
        _viewModel = State(initialValue: RunTrackingLaunchViewModel(
            athleteRepository: athleteRepository,
            planRepository: planRepository,
            runRepository: runRepository,
            appSettingsRepository: appSettingsRepository
        ))
        self.athleteRepository = athleteRepository
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.nutritionRepository = nutritionRepository
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    locationAuthSection
                    heroSection
                    if !viewModel.todaysSessions.isEmpty {
                        SessionPickerView(
                            sessions: viewModel.todaysSessions,
                            selectedSession: $viewModel.selectedSession
                        )
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                    startButton
                    historyLink
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .navigationTitle("Run")
            .task { await viewModel.load() }
            .navigationDestination(isPresented: $viewModel.showActiveRun) {
                if let athlete = viewModel.athlete {
                    ActiveRunView(
                        viewModel: ActiveRunViewModel(
                            locationService: locationService,
                            healthKitService: healthKitService,
                            runRepository: runRepository,
                            planRepository: planRepository,
                            nutritionRepository: nutritionRepository,
                            athlete: athlete,
                            linkedSession: viewModel.selectedSession,
                            autoPauseEnabled: viewModel.autoPauseEnabled,
                            nutritionRemindersEnabled: viewModel.nutritionRemindersEnabled,
                            raceId: viewModel.raceId
                        )
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

    private func authBanner(
        message: String,
        buttonLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Colors.warning)
            Button(buttonLabel, action: action)
                .buttonStyle(.bordered)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.warning.opacity(0.1))
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.primary)
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
    }

    // MARK: - History

    private var historyLink: some View {
        NavigationLink {
            RunHistoryView(
                runRepository: runRepository,
                planRepository: planRepository,
                athleteRepository: athleteRepository
            )
        } label: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text("Run History")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
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
