import SwiftUI

struct VolumePreviewStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                header
                cards
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.5, blue: 0.7), Color(red: 0.15, green: 0.35, blue: 0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.7).opacity(0.3), radius: 8, y: 4)

            Text("Your Training Preview")
                .font(.title.bold())

            Text("Here's what your first weeks will look like")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.xl)
    }

    // MARK: - Cards

    private var cards: some View {
        VStack(spacing: Theme.Spacing.lg) {
            raceRecapCard
            currentProfileCard
            volumeEstimateSection
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Race Recap

    private var raceRecapCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "flag.checkered")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.goldAccent)
                Text("Your Race")
                    .font(.headline)
                Spacer()
            }

            Divider()

            summaryRow(label: "Race", value: viewModel.raceName)
            summaryRow(
                label: "Date",
                value: viewModel.raceDate.formatted(.dateTime.day().month(.wide).year())
            )
            summaryRow(
                label: "Distance",
                value: UnitFormatter.formatDistance(viewModel.raceDistanceKm, unit: viewModel.preferredUnit, decimals: 0)
            )
            summaryRow(
                label: "Elevation",
                value: "D+ \(UnitFormatter.formatElevation(viewModel.raceElevationGainM, unit: viewModel.preferredUnit))"
            )
        }
        .onboardingCardStyle()
    }

    // MARK: - Current Profile

    private var currentProfileCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "figure.run")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.warmCoral)
                Text("Your Profile")
                    .font(.headline)
                Spacer()
            }

            Divider()

            summaryRow(
                label: "Level",
                value: viewModel.experienceLevel?.rawValue.capitalized ?? "Beginner"
            )
            summaryRow(
                label: "Current Volume",
                value: viewModel.isNewRunner
                    ? "Just starting"
                    : UnitFormatter.formatDistance(viewModel.weeklyVolumeKm, unit: viewModel.preferredUnit, decimals: 0) + "/week"
            )
            summaryRow(
                label: "Training Style",
                value: viewModel.trainingPhilosophy.displayName
            )
        }
        .onboardingCardStyle()
    }

    // MARK: - Volume Estimates

    private var volumeEstimateSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weekly Volume Estimate")
                .font(.headline)
            Text("Approximate range for the first month of your plan. Pick the frequency that suits you best.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            ForEach(viewModel.volumePreviewData) { estimate in
                volumeRow(estimate)
            }

            Text("You can always adjust this later in settings.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
                .padding(.top, Theme.Spacing.xs)
        }
        .onboardingCardStyle()
    }

    private func volumeRow(_ estimate: OnboardingViewModel.VolumeEstimate) -> some View {
        let isSelected = viewModel.preferredRunsPerWeek == estimate.runsPerWeek

        return Button {
            viewModel.preferredRunsPerWeek = estimate.runsPerWeek
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("\(estimate.runsPerWeek) runs/week")
                            .font(.subheadline.bold())
                        if estimate.isRecommended {
                            Text("Recommended")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    isSelected
                                        ? Color.white.opacity(0.25)
                                        : Theme.Colors.warmCoral.opacity(0.15)
                                )
                                .foregroundStyle(isSelected ? .white : Theme.Colors.warmCoral)
                                .clipShape(Capsule())
                        }
                    }
                    Text("~\(estimate.weeklyKmMin)–\(estimate.weeklyKmMax) km/week (1st month)")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.85) : Theme.Colors.secondaryLabel)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(Theme.Spacing.md)
            .background(isSelected ? AnyShapeStyle(Theme.Colors.warmCoral) : AnyShapeStyle(Theme.Colors.secondaryBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
        }
    }
}
