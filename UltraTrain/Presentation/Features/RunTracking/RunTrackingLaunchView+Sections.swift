import SwiftUI

// MARK: - View Sections

extension RunTrackingLaunchView {

    // MARK: - Location Auth

    @ViewBuilder
    var locationAuthSection: some View {
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

    func authBanner(message: String, buttonLabel: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(message).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(Theme.Colors.warning)
            Button(buttonLabel, action: action).buttonStyle(.bordered)
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Theme.Colors.warning.opacity(0.1)))
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Hero

    var heroSection: some View {
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

    var startButton: some View {
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
        .accessibilityHint("Double tap to begin GPS run tracking")
    }

    // MARK: - Race Day Banner

    func raceDayBanner(race: Race) -> some View {
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

    var gutTrainingBanner: some View {
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

    // MARK: - Cross-Training

    var crossTrainingButton: some View {
        Button {
            showCrossTrainingSheet = true
        } label: {
            Label("Log Cross-Training", systemImage: "figure.mixed.cardio")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .padding(.horizontal, Theme.Spacing.md)
        .sheet(isPresented: $showCrossTrainingSheet) {
            CrossTrainingLogView(
                viewModel: CrossTrainingLogViewModel(
                    runRepository: runRepository,
                    athleteRepository: athleteRepository
                )
            )
        }
    }

    // MARK: - History

    var historyLink: some View {
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
