import SwiftUI

struct OnboardingCompleteStepView: View {
    let viewModel: OnboardingViewModel
    var onComplete: () -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var checkmarkSize: CGFloat = 60

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                Spacer(minLength: Theme.Spacing.xl)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: checkmarkSize))
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityHidden(true)

                Text("You're All Set!")
                    .font(.title.bold())

                summarySection
                healthKitPlaceholder

                if let error = viewModel.error {
                    ErrorBannerView(message: error) {
                        Task { await viewModel.completeOnboarding() }
                    }
                }

                getStartedButton
            }
            .padding()
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Profile Summary")
                .font(.headline)

            SummaryRow(label: "Name", value: "\(viewModel.firstName) \(viewModel.lastName)")
            SummaryRow(
                label: "Experience",
                value: viewModel.experienceLevel?.rawValue.capitalized ?? "—"
            )
            SummaryRow(
                label: "Weekly Volume",
                value: viewModel.isNewRunner ? "Just starting" : "\(Int(viewModel.weeklyVolumeKm)) km"
            )

            Divider()

            SummaryRow(label: "Race", value: viewModel.raceName)
            SummaryRow(
                label: "Distance",
                value: "\(Int(viewModel.raceDistanceKm)) km / D+ \(Int(viewModel.raceElevationGainM)) m"
            )
            SummaryRow(label: "Goal", value: viewModel.raceGoalType.displayName)
        }
        .cardStyle()
    }

    private var healthKitPlaceholder: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "heart.circle")
                .font(.title)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text("HealthKit Integration")
                .font(.headline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text("Coming soon — auto-import heart rate and activity data.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
        .opacity(0.6)
    }

    private var getStartedButton: some View {
        Button {
            Task {
                await viewModel.completeOnboarding()
                if viewModel.isCompleted {
                    onComplete()
                }
            }
        } label: {
            Group {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Get Started")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isSaving)
        .padding(.top, Theme.Spacing.md)
        .accessibilityIdentifier("onboarding.getStartedButton")
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
