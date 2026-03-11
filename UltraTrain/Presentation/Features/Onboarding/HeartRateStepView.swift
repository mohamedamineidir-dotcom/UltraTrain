import SwiftUI

struct HeartRateStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(
                            Circle().fill(
                                LinearGradient(colors: [.red, Color(red: 0.85, green: 0.2, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 8, y: 4)

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
                    .onboardingCardStyle()

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
                    .onboardingCardStyle()
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }
}
