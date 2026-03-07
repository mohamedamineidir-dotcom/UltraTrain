import SwiftUI

struct HeartRateStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)

                    Text("Heart Rate")
                        .font(.title.bold())

                    Text("Used to set your training zones. Skip if unsure.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                VStack(spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        LabeledIntStepper(
                            label: "Resting HR",
                            value: $viewModel.restingHeartRate,
                            range: 30...120,
                            unit: "bpm"
                        )
                        Text("Measure first thing in the morning. Typical: 60-70 bpm.")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        LabeledIntStepper(
                            label: "Max HR",
                            value: $viewModel.maxHeartRate,
                            range: 120...230,
                            unit: "bpm"
                        )
                        Text("If unknown, use 220 minus your age.")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    .cardStyle()
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }
}
