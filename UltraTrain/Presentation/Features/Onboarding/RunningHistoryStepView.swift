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
        .accessibilityIdentifier("onboarding.newRunnerToggle")
    }

    private var weeklyVolumeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Average weekly distance")
                .font(.headline)
            Text("How many km do you typically run per week?")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            HStack {
                Slider(value: $viewModel.weeklyVolumeKm, in: 5...200, step: 5)
                    .tint(Theme.Colors.primary)
                Text("\(Int(viewModel.weeklyVolumeKm)) km")
                    .font(.body.monospacedDigit().bold())
                    .frame(width: 65, alignment: .trailing)
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
                Slider(value: $viewModel.longestRunKm, in: 5...300, step: 5)
                    .tint(Theme.Colors.primary)
                Text("\(Int(viewModel.longestRunKm)) km")
                    .font(.body.monospacedDigit().bold())
                    .frame(width: 65, alignment: .trailing)
            }
        }
        .cardStyle()
    }
}
