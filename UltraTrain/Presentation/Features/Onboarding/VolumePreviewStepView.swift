import SwiftUI

struct VolumePreviewStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                header
                cards
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 8, y: 4)

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
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "flag.checkered")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.Colors.goldAccent)
                Text("Your Race")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, Theme.Spacing.md)

            VStack(spacing: 0) {
                summaryRow(label: "Race", value: viewModel.raceName)
                thinDivider
                summaryRow(
                    label: "Date",
                    value: viewModel.raceDate.formatted(.dateTime.day().month(.wide).year())
                )
                thinDivider
                summaryRow(
                    label: "Distance",
                    value: UnitFormatter.formatDistance(
                        viewModel.raceDistanceKm, unit: viewModel.preferredUnit, decimals: 0
                    )
                )
                thinDivider
                summaryRow(
                    label: "Elevation",
                    value: "D+ \(UnitFormatter.formatElevation(viewModel.raceElevationGainM, unit: viewModel.preferredUnit))"
                )
            }
        }
        .onboardingCardStyle()
    }

    // MARK: - Current Profile

    private var currentProfileCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "figure.run")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.Colors.warmCoral)
                Text("Your Profile")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, Theme.Spacing.md)

            VStack(spacing: 0) {
                summaryRow(
                    label: "Level",
                    value: viewModel.experienceLevel?.rawValue.capitalized ?? "Beginner"
                )
                thinDivider
                summaryRow(
                    label: "Current Volume",
                    value: viewModel.isNewRunner
                        ? "Just starting"
                        : UnitFormatter.formatDistance(
                            viewModel.weeklyVolumeKm, unit: viewModel.preferredUnit, decimals: 0
                        ) + "/week"
                )
                thinDivider
                summaryRow(
                    label: "Training Style",
                    value: viewModel.trainingPhilosophy.displayName
                )
            }
        }
        .onboardingCardStyle()
    }

    // MARK: - Volume Estimates

    private var volumeEstimateSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Weekly Volume Estimate")
                    .font(.headline)
                Text("Approximate range for the first month of your plan. Pick the frequency that suits you best.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(viewModel.volumePreviewData) { estimate in
                    volumeRow(estimate)
                }
            }

            Text("You can always adjust this later in settings.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
        }
        .onboardingCardStyle()
    }

    @Environment(\.colorScheme) private var colorScheme

    private func volumeRow(_ estimate: OnboardingViewModel.VolumeEstimate) -> some View {
        let isSelected = viewModel.preferredRunsPerWeek == estimate.runsPerWeek

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.preferredRunsPerWeek = estimate.runsPerWeek
            }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Theme.Colors.warmCoral : Theme.Colors.tertiaryLabel,
                            lineWidth: isSelected ? 0 : 1.5
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Theme.Gradients.warmCoralCTA)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("\(estimate.runsPerWeek) runs/week")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? Theme.Colors.warmCoral : .primary)
                        if estimate.isRecommended {
                            recommendedBadge
                        }
                    }
                    Text("~\(estimate.weeklyKmMin)--\(estimate.weeklyKmMax) km/week")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                Spacer()

                if isSelected {
                    Text("\(estimate.runsPerWeek)x")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.Colors.warmCoral)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(
                        isSelected
                            ? (colorScheme == .dark
                                ? Theme.Colors.warmCoral.opacity(0.12)
                                : Theme.Colors.warmCoral.opacity(0.06))
                            : (colorScheme == .dark
                                ? Color.white.opacity(0.03)
                                : Color.black.opacity(0.02))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(
                        isSelected
                            ? Theme.Colors.warmCoral.opacity(colorScheme == .dark ? 0.5 : 0.35)
                            : (colorScheme == .dark
                                ? Color.white.opacity(0.06)
                                : Color.black.opacity(0.06)),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(
                color: isSelected ? Theme.Colors.warmCoral.opacity(0.15) : .clear,
                radius: 8,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Subviews

    private var recommendedBadge: some View {
        Label("Rec.", systemImage: "star.fill")
            .font(.caption2.bold())
            .foregroundStyle(Theme.Colors.warmCoral)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Theme.Colors.warmCoral.opacity(colorScheme == .dark ? 0.15 : 0.1))
            )
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06))
            .frame(height: 0.5)
            .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Helpers

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}
