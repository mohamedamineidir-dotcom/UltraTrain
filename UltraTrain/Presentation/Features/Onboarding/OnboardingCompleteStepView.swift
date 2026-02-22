import SwiftUI
import os

struct OnboardingCompleteStepView: View {
    let viewModel: OnboardingViewModel
    var onComplete: () -> Void
    let healthKitService: (any HealthKitServiceProtocol)?
    @ScaledMetric(relativeTo: .largeTitle) private var checkmarkSize: CGFloat = 60
    @State private var isRequestingHealthKit = false
    @State private var healthKitConnected = false
    @State private var showCheckmark = false
    @State private var showTitle = false
    @State private var showSummary = false
    @State private var showHealthKit = false
    @State private var showButton = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                Spacer(minLength: Theme.Spacing.xl)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: checkmarkSize))
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityHidden(true)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .opacity(showCheckmark ? 1 : 0)

                Text("You're All Set!")
                    .font(.title.bold())
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 10)

                summarySection
                    .opacity(showSummary ? 1 : 0)
                    .offset(y: showSummary ? 0 : 20)
                healthKitCard
                    .opacity(showHealthKit ? 1 : 0)
                    .offset(y: showHealthKit ? 0 : 20)

                if let error = viewModel.error {
                    ErrorBannerView(message: error) {
                        Task { await viewModel.completeOnboarding() }
                    }
                    .opacity(showSummary ? 1 : 0)
                    .offset(y: showSummary ? 0 : 20)
                }

                getStartedButton
                    .opacity(showButton ? 1 : 0)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                showCheckmark = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                showSummary = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.7)) {
                showHealthKit = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
                showButton = true
            }
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
                value: viewModel.isNewRunner ? "Just starting" : UnitFormatter.formatDistance(viewModel.weeklyVolumeKm, unit: viewModel.preferredUnit, decimals: 0)
            )

            Divider()

            SummaryRow(label: "Race", value: viewModel.raceName)
            SummaryRow(
                label: "Distance",
                value: "\(UnitFormatter.formatDistance(viewModel.raceDistanceKm, unit: viewModel.preferredUnit, decimals: 0)) / D+ \(UnitFormatter.formatElevation(viewModel.raceElevationGainM, unit: viewModel.preferredUnit))"
            )
            SummaryRow(label: "Goal", value: viewModel.raceGoalType.displayName)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var healthKitCard: some View {
        if let service = healthKitService, service.authorizationStatus != .unavailable {
            VStack(spacing: Theme.Spacing.sm) {
                if healthKitConnected {
                    Image(systemName: "heart.circle.fill")
                        .font(.title)
                        .foregroundStyle(Theme.Colors.success)
                        .accessibilityHidden(true)
                    Text("Apple Health Connected")
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.success)
                    Text("Heart rate, body weight, and workouts will sync automatically.")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "heart.circle")
                        .font(.title)
                        .foregroundStyle(Theme.Colors.primary)
                        .accessibilityHidden(true)
                    Text("Connect Apple Health")
                        .font(.headline)
                    Text("Sync heart rate, body weight, and running workouts.")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await connectHealthKit() }
                    } label: {
                        if isRequestingHealthKit {
                            ProgressView()
                        } else {
                            Text("Connect")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(isRequestingHealthKit)
                    .accessibilityHint("Connects to Apple Health to sync heart rate and workouts")
                }
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
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
        .accessibilityHint("Completes setup and opens the main app")
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
