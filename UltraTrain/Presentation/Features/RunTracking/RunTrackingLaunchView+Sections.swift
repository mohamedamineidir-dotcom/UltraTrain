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
        .appCardStyle()
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Hero

    var heroSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.Colors.primary.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "figure.run")
                    .font(.system(size: heroIconSize))
                    .foregroundStyle(Theme.Colors.primary)
            }
            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 12)
            .accessibilityHidden(true)

            Text("Ready to Run?")
                .font(.title.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.label, Theme.Colors.label.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text("Track your run with GPS, pace, and elevation.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Theme.Spacing.lg)
        .padding(.horizontal, Theme.Spacing.md)
        .futuristicGlassStyle()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(
                    Theme.Gradients.glowBorder(color: Theme.Colors.primary),
                    lineWidth: heroBorderPulse ? 1.0 : 0.5
                )
                .opacity(heroBorderPulse ? 0.8 : 0.3)
        )
        .padding(.horizontal, Theme.Spacing.md)
        .onAppear {
            withAnimation(.pulseGlow) { heroBorderPulse = true }
        }
    }

    // MARK: - Start

    var startButton: some View {
        let isDisabled = viewModel.athlete == nil
            || locationService.authorizationStatus == .denied
            || locationService.authorizationStatus == .notDetermined

        return Button {
            viewModel.startRun()
        } label: {
            Label("Start Run", systemImage: "play.fill")
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Gradients.warmCoralCTA)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                .shadow(color: Theme.Colors.warmCoral.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.md)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .accessibilityIdentifier("runTracking.startButton")
        .accessibilityHint("Double tap to begin GPS run tracking")
    }

    // MARK: - Race Day Banner

    func raceDayBanner(race: Race) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "flag.checkered")
                    .font(.body)
                    .foregroundStyle(Theme.Colors.primary)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Race Day: \(race.name)").font(.subheadline.bold())
                Text("This run will be linked to your race for finish time calibration.")
                    .font(.caption).foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
        }
        .appCardStyle()
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Gut Training

    var gutTrainingBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "fork.knife")
                    .font(.body)
                    .foregroundStyle(Theme.Colors.primary)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Gut Training Session").font(.subheadline.bold())
                Text("Practice your race-day nutrition during this run.")
                    .font(.caption).foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
        }
        .appCardStyle()
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Cross-Training

    var crossTrainingButton: some View {
        Button {
            showCrossTrainingSheet = true
        } label: {
            Label("Log Cross-Training", systemImage: "figure.mixed.cardio")
                .font(.headline)
                .foregroundStyle(Theme.Colors.label)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
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
        }
        .buttonStyle(.plain)
        .appCardStyle()
        .padding(.horizontal, Theme.Spacing.md)
    }
}
