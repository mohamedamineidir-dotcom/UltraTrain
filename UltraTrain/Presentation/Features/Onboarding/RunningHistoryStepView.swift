import SwiftUI
import os

struct RunningHistoryStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    let healthKitService: (any HealthKitServiceProtocol)?
    @State private var importState: HealthKitImportState = .idle

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                newRunnerToggle

                if !viewModel.isNewRunner {
                    healthKitImportCard
                    weeklyVolumeSection
                    longestRunSection
                }
            }
            .padding()
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isNewRunner)
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Your Running Background")
                .font(.title2.bold())
            Text("Tell us about your current training so we can set the right starting point.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private var newRunnerToggle: some View {
        Toggle(isOn: $viewModel.isNewRunner) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("I'm just getting started")
                    .font(.headline)
                Text("No worries — we'll build your base from scratch.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .tint(Theme.Colors.primary)
        .cardStyle()
        .accessibilityHint("When enabled, skips running history questions")
        .accessibilityIdentifier("onboarding.newRunnerToggle")
    }

    private var isImperial: Bool { viewModel.preferredUnit == .imperial }

    private var weeklyVolumeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Average weekly distance")
                .font(.headline)
            Text("How many \(UnitFormatter.distanceLabel(viewModel.preferredUnit)) do you typically run per week?")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            HStack {
                Slider(
                    value: weeklyVolumeBinding,
                    in: isImperial ? 3...124 : 5...200,
                    step: isImperial ? 3 : 5
                )
                .tint(Theme.Colors.primary)
                .accessibilityLabel("Weekly distance")
                .accessibilityValue(AccessibilityFormatters.distance(viewModel.weeklyVolumeKm, unit: viewModel.preferredUnit))
                Text("\(Int(UnitFormatter.distanceValue(viewModel.weeklyVolumeKm, unit: viewModel.preferredUnit))) \(UnitFormatter.distanceLabel(viewModel.preferredUnit))")
                    .font(.body.monospacedDigit().bold())
                    .frame(width: 65, alignment: .trailing)
                    .accessibilityHidden(true)
            }
        }
        .cardStyle()
    }

    private var longestRunSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Longest run ever")
                .font(.headline)
            Text("What's the farthest you've run in a single effort?")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            HStack {
                Slider(
                    value: longestRunBinding,
                    in: isImperial ? 3...186 : 5...300,
                    step: isImperial ? 3 : 5
                )
                .tint(Theme.Colors.primary)
                .accessibilityLabel("Longest run distance")
                .accessibilityValue(AccessibilityFormatters.distance(viewModel.longestRunKm, unit: viewModel.preferredUnit))
                Text("\(Int(UnitFormatter.distanceValue(viewModel.longestRunKm, unit: viewModel.preferredUnit))) \(UnitFormatter.distanceLabel(viewModel.preferredUnit))")
                    .font(.body.monospacedDigit().bold())
                    .frame(width: 65, alignment: .trailing)
                    .accessibilityHidden(true)
            }
        }
        .cardStyle()
    }

    private var weeklyVolumeBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.distanceValue(viewModel.weeklyVolumeKm, unit: .imperial) },
                set: { viewModel.weeklyVolumeKm = UnitFormatter.distanceToKm($0, unit: .imperial) }
            )
            : $viewModel.weeklyVolumeKm
    }

    private var longestRunBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.distanceValue(viewModel.longestRunKm, unit: .imperial) },
                set: { viewModel.longestRunKm = UnitFormatter.distanceToKm($0, unit: .imperial) }
            )
            : $viewModel.longestRunKm
    }

    // MARK: - HealthKit Import

    @ViewBuilder
    private var healthKitImportCard: some View {
        if let service = healthKitService, service.authorizationStatus != .unavailable {
            switch importState {
            case .idle, .error:
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Image(systemName: "heart.circle")
                            .font(.title2)
                            .foregroundStyle(Theme.Colors.primary)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Import from Apple Health")
                                .font(.headline)
                            Text("Auto-fill from your recent running history.")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                        }
                        Spacer()
                        Button("Import") {
                            Task { await importFromHealthKit(service: service) }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    if case .error(let message) = importState {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.warning)
                    }
                }
                .cardStyle()

            case .loading:
                HStack(spacing: Theme.Spacing.sm) {
                    ProgressView()
                    Text("Reading workouts...")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

            case .imported(let weeklyKm, let longestKm):
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Image(systemName: "heart.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.Colors.success)
                            .accessibilityHidden(true)
                        Text("Imported from Apple Health")
                            .font(.headline)
                            .foregroundStyle(Theme.Colors.success)
                    }
                    Text("Weekly avg: \(UnitFormatter.formatDistance(weeklyKm, unit: viewModel.preferredUnit, decimals: 0)) · Longest: \(UnitFormatter.formatDistance(longestKm, unit: viewModel.preferredUnit, decimals: 0))")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Text("You can still adjust the sliders below.")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                .cardStyle()

            case .noWorkouts:
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(Theme.Colors.warning)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("No running workouts found")
                            .font(.subheadline.weight(.medium))
                        Text("No runs in the last 90 days. Fill in the sliders manually.")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                .cardStyle()
            }
        }
    }

    private func importFromHealthKit(service: any HealthKitServiceProtocol) async {
        importState = .loading
        do {
            try await service.requestAuthorization()

            let endDate = Date.now
            let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate)!
            let workouts = try await service.fetchRunningWorkouts(from: startDate, to: endDate)

            guard !workouts.isEmpty else {
                importState = .noWorkouts
                return
            }

            let avgWeeklyKm = RunningHistoryCalculator.averageWeeklyKm(from: workouts)
            let longestKm = workouts.map(\.distanceKm).max() ?? 0

            viewModel.weeklyVolumeKm = max(5, avgWeeklyKm)
            viewModel.longestRunKm = max(5, longestKm)

            importState = .imported(weeklyKm: avgWeeklyKm, longestKm: longestKm)
            Logger.healthKit.info(
                "HealthKit auto-fill: avgWeekly=\(avgWeeklyKm, format: .fixed(precision: 1)) longest=\(longestKm, format: .fixed(precision: 1))"
            )
        } catch {
            importState = .error("Could not read from Apple Health. Please try again.")
            Logger.healthKit.error("HealthKit onboarding import failed: \(error)")
        }
    }
}

// MARK: - Import State

private enum HealthKitImportState: Equatable {
    case idle
    case loading
    case imported(weeklyKm: Double, longestKm: Double)
    case noWorkouts
    case error(String)
}
