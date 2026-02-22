import SwiftUI

struct RunningHistoryStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                newRunnerToggle

                if !viewModel.isNewRunner {
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
}
