import SwiftUI
import os

struct OnboardingCompleteStepView: View {
    let viewModel: OnboardingViewModel
    var onComplete: () -> Void
    let healthKitService: (any HealthKitServiceProtocol)?
    let healthKitImportService: (any HealthKitImportServiceProtocol)?
    @ScaledMetric(relativeTo: .largeTitle) private var sealSize: CGFloat = 56
    @State private var isRequestingHealthKit = false
    @State private var healthKitConnected = false
    @State private var isImportingWorkouts = false
    @State private var importResult: HealthKitImportResult?
    @State private var showSeal = false
    @State private var showContent = false
    @State private var showButton = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Hero section
                heroSection
                    .scaleEffect(showSeal ? 1 : 0.8)
                    .opacity(showSeal ? 1 : 0)

                // Summary cards
                VStack(spacing: Theme.Spacing.md) {
                    athleteCard
                    raceCard
                    healthKitCard
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                if let error = viewModel.error {
                    ErrorBannerView(message: error) {
                        Task { await viewModel.completeOnboarding() }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                getStartedButton
                    .padding(.horizontal, Theme.Spacing.lg)
                    .opacity(showButton ? 1 : 0)
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showSeal = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
                showButton = true
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.goldAccent.opacity(0.12))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: sealSize))
                    .foregroundStyle(Theme.Gradients.goldPremium)
                    .shadow(color: Theme.Colors.goldAccent.opacity(0.4), radius: 16, y: 4)
            }
            .accessibilityHidden(true)

            Text("You're All Set!")
                .font(.title.bold())

            Text("Your training journey starts now")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Athlete Card

    private var athleteCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.warmCoral)
                Text("Your Profile")
                    .font(.headline)
                Spacer()
            }

            Divider()

            summaryIconRow(
                icon: "person.fill",
                color: Theme.Colors.warmCoral,
                label: "Name",
                value: "\(viewModel.firstName) \(viewModel.lastName)"
            )
            summaryIconRow(
                icon: "figure.run",
                color: Theme.Colors.warmCoral,
                label: "Level",
                value: viewModel.experienceLevel?.rawValue.capitalized ?? "--"
            )
            summaryIconRow(
                icon: "chart.bar.fill",
                color: Theme.Colors.warmCoral,
                label: "Volume",
                value: viewModel.isNewRunner ? "Just starting" : UnitFormatter.formatDistance(viewModel.weeklyVolumeKm, unit: viewModel.preferredUnit, decimals: 0) + "/week"
            )
        }
        .onboardingCardStyle()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Race Card

    private var raceCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "flag.checkered")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.goldAccent)
                Text("A-Race")
                    .font(.headline)
                Spacer()
            }

            Divider()

            summaryIconRow(
                icon: "mappin.and.ellipse",
                color: Theme.Colors.goldAccent,
                label: "Race",
                value: viewModel.raceName
            )
            summaryIconRow(
                icon: "point.topleft.down.to.point.bottomright.curvepath",
                color: Theme.Colors.goldAccent,
                label: "Distance",
                value: UnitFormatter.formatDistance(viewModel.raceDistanceKm, unit: viewModel.preferredUnit, decimals: 0)
            )
            summaryIconRow(
                icon: "mountain.2.fill",
                color: Theme.Colors.goldAccent,
                label: "Elevation",
                value: "D+ \(UnitFormatter.formatElevation(viewModel.raceElevationGainM, unit: viewModel.preferredUnit))"
            )
            summaryIconRow(
                icon: "target",
                color: Theme.Colors.goldAccent,
                label: "Goal",
                value: viewModel.raceGoalType.displayName
            )
        }
        .onboardingCardStyle()
        .accessibilityElement(children: .combine)
    }

    // MARK: - HealthKit Card

    @ViewBuilder
    private var healthKitCard: some View {
        if let service = healthKitService, service.authorizationStatus != .unavailable {
            VStack(spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: healthKitConnected ? "heart.circle.fill" : "heart.circle")
                        .font(.title2)
                        .foregroundStyle(healthKitConnected ? Theme.Colors.success : Theme.Colors.warmCoral)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(healthKitConnected ? "Apple Health Connected" : "Connect Apple Health")
                            .font(.subheadline.bold())
                            .foregroundStyle(healthKitConnected ? Theme.Colors.success : Theme.Colors.label)
                        Text(healthKitConnected
                             ? "Workouts will be imported on launch."
                             : "Sync heart rate, weight, and workouts.")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }

                    Spacer()

                    if !healthKitConnected {
                        Button {
                            Task { await connectHealthKit() }
                        } label: {
                            if isRequestingHealthKit {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Connect")
                                    .font(.subheadline.bold())
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.Colors.warmCoral)
                        .controlSize(.small)
                        .disabled(isRequestingHealthKit)
                        .accessibilityHint("Connects to Apple Health to sync heart rate and workouts")
                    }
                }
            }
            .onboardingCardStyle()
        }
    }

    // MARK: - Helpers

    private func summaryIconRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
        }
    }

    private func connectHealthKit() async {
        guard let service = healthKitService else { return }
        isRequestingHealthKit = true
        do {
            try await service.requestAuthorization()
            healthKitConnected = true
        } catch {
            Logger.healthKit.error("HealthKit onboarding auth failed: \(error)")
        }
        isRequestingHealthKit = false
    }

    // MARK: - Get Started Button

    private var getStartedButton: some View {
        Button {
            Task {
                await viewModel.completeOnboarding()
                guard viewModel.isCompleted else { return }
                if healthKitConnected, let importService = healthKitImportService,
                   let athleteId = viewModel.savedAthleteId {
                    isImportingWorkouts = true
                    do {
                        let result = try await importService.importNewWorkouts(athleteId: athleteId)
                        importResult = result
                        Logger.healthKit.info("Onboarding import: \(result.importedCount) workouts imported")
                    } catch {
                        Logger.healthKit.error("Onboarding HealthKit import failed: \(error)")
                    }
                    isImportingWorkouts = false
                }
                onComplete()
            }
        } label: {
            Group {
                if viewModel.isSaving || isImportingWorkouts {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView()
                            .tint(.white)
                        if isImportingWorkouts {
                            Text("Importing workouts...")
                                .font(.subheadline)
                        }
                    }
                } else {
                    Text("Get Started")
                }
            }
            .font(.headline.bold())
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.Gradients.warmCoralCTA)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(viewModel.isSaving || isImportingWorkouts)
        .padding(.top, Theme.Spacing.sm)
        .accessibilityHint("Completes setup and opens the main app")
        .accessibilityIdentifier("onboarding.getStartedButton")
    }
}
