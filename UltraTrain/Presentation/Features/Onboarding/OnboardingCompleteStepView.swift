import SwiftUI
import os

struct OnboardingCompleteStepView: View {
    let viewModel: OnboardingViewModel
    var onComplete: () -> Void
    let healthKitService: (any HealthKitServiceProtocol)?
    let healthKitImportService: (any HealthKitImportServiceProtocol)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isRequestingHealthKit = false
    @State private var healthKitConnected = false
    @State private var isImportingWorkouts = false
    @State private var importResult: HealthKitImportResult?
    @State private var showRunner = false
    @State private var showContent = false
    @State private var showButton = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                heroSection
                    .scaleEffect(showRunner ? 1 : 0.5)
                    .opacity(showRunner ? 1 : 0)

                titleSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 16)

                summarySection
                    .padding(.horizontal, Theme.Spacing.lg)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 16)

                healthKitCard
                    .padding(.horizontal, Theme.Spacing.lg)
                    .opacity(showContent ? 1 : 0)

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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showRunner = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
                showButton = true
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 0) {
            Image("LaunchIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .colorMultiply(colorScheme == .dark ? .white : Theme.Colors.warmCoral)
                .shadow(color: Theme.Colors.warmCoral.opacity(0.25), radius: 20, y: 8)
        }
        .padding(.top, Theme.Spacing.xxl)
        .accessibilityHidden(true)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("You're All Set")
                .font(.largeTitle.bold())

            Text(viewModel.hasNoRace
                 ? "Your fitness journey starts now"
                 : "Your personalized plan is ready")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(spacing: 0) {
            // Profile row
            summaryRow(
                icon: "figure.run",
                iconColor: Theme.Colors.warmCoral,
                title: viewModel.experienceLevel?.rawValue.capitalized ?? "Beginner",
                detail: "\(viewModel.preferredRunsPerWeek) runs/week \u{00B7} \(viewModel.trainingPhilosophy.displayName)"
            )

            if !viewModel.hasNoRace {
                Divider()
                    .padding(.horizontal, Theme.Spacing.md)

                // Race row
                summaryRow(
                    icon: "flag.checkered",
                    iconColor: Theme.Colors.goldAccent,
                    title: viewModel.raceName,
                    detail: [
                        UnitFormatter.formatDistance(viewModel.raceDistanceKm, unit: viewModel.preferredUnit, decimals: 0),
                        "D+ \(UnitFormatter.formatElevation(viewModel.raceElevationGainM, unit: viewModel.preferredUnit))",
                    ].joined(separator: " \u{00B7} ")
                )

                Divider()
                    .padding(.horizontal, Theme.Spacing.md)

                // Date row
                summaryRow(
                    icon: "calendar",
                    iconColor: Theme.Colors.zone3,
                    title: viewModel.raceDate.formatted(.dateTime.day().month(.wide).year()),
                    detail: weeksToGoLabel
                )
            } else {
                Divider()
                    .padding(.horizontal, Theme.Spacing.md)

                summaryRow(
                    icon: "arrow.up.right",
                    iconColor: Theme.Colors.zone3,
                    title: "General Fitness",
                    detail: "12-week progressive plan"
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
    }

    private var weeksToGoLabel: String {
        let weeks = Calendar.current.dateComponents(
            [.weekOfYear], from: .now, to: viewModel.raceDate
        ).weekOfYear ?? 0
        return weeks > 0 ? "\(weeks) weeks to go" : ""
    }

    private func summaryRow(icon: String, iconColor: Color, title: String, detail: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 2)
    }

    // MARK: - HealthKit

    @ViewBuilder
    private var healthKitCard: some View {
        if let service = healthKitService, service.authorizationStatus != .unavailable {
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
            .futuristicGlassStyle()
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

    // MARK: - Get Started

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
