import SwiftUI

struct FinishEstimationView: View {
    @State private var viewModel: FinishEstimationViewModel

    init(
        race: Race,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        athleteRepository: any AthleteRepository,
        runRepository: any RunRepository,
        fitnessCalculator: any CalculateFitnessUseCase
    ) {
        _viewModel = State(initialValue: FinishEstimationViewModel(
            race: race,
            finishTimeEstimator: finishTimeEstimator,
            athleteRepository: athleteRepository,
            runRepository: runRepository,
            fitnessCalculator: fitnessCalculator
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                if viewModel.isLoading {
                    ProgressView("Calculating...")
                        .padding(.top, Theme.Spacing.xl)
                } else if let estimate = viewModel.estimate {
                    raceHeader
                    scenarioCards(estimate)
                    confidenceSection(estimate)
                    if !estimate.checkpointSplits.isEmpty {
                        checkpointSplitsSection(estimate)
                    }
                } else if let error = viewModel.error {
                    errorSection(error)
                }
            }
            .padding()
        }
        .navigationTitle("Finish Estimate")
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Race Header

    private var raceHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(viewModel.race.name)
                .font(.title2.bold())
            HStack(spacing: Theme.Spacing.md) {
                Label(
                    String(format: "%.0f km", viewModel.race.distanceKm),
                    systemImage: "point.topleft.down.to.point.bottomright.curvepath"
                )
                Label(
                    String(format: "%.0f m D+", viewModel.race.elevationGainM),
                    systemImage: "mountain.2"
                )
                Label(
                    viewModel.race.terrainDifficulty.rawValue.capitalized,
                    systemImage: "map"
                )
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)

            if viewModel.race.date > .now {
                Text(viewModel.race.date.formatted(.dateTime.month(.wide).day().year()))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Scenario Cards

    private func scenarioCards(_ estimate: FinishEstimate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Predicted Finish Time")
                .font(.headline)

            HStack(spacing: Theme.Spacing.sm) {
                scenarioCard(
                    title: "Optimistic",
                    time: estimate.optimisticTime,
                    color: Theme.Colors.success
                )
                scenarioCard(
                    title: "Expected",
                    time: estimate.expectedTime,
                    color: Theme.Colors.primary
                )
                scenarioCard(
                    title: "Conservative",
                    time: estimate.conservativeTime,
                    color: Theme.Colors.warning
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func scenarioCard(title: String, time: TimeInterval, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(FinishEstimate.formatDuration(time))
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Confidence

    private func confidenceSection(_ estimate: FinishEstimate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Confidence")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f%%", estimate.confidencePercent))
                    .font(.subheadline.bold().monospacedDigit())
            }

            ProgressView(value: estimate.confidencePercent, total: 100)
                .tint(confidenceColor(estimate.confidencePercent))

            Text(confidenceLabel(estimate.confidencePercent))
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .cardStyle()
    }

    private func confidenceColor(_ percent: Double) -> Color {
        if percent >= 70 { return Theme.Colors.success }
        if percent >= 50 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }

    private func confidenceLabel(_ percent: Double) -> String {
        if percent >= 70 { return "Strong prediction — good training data available" }
        if percent >= 50 { return "Moderate prediction — more training data would improve accuracy" }
        return "Low confidence — keep training to improve prediction accuracy"
    }

    // MARK: - Checkpoint Splits

    private func checkpointSplitsSection(_ estimate: FinishEstimate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Checkpoint Splits")
                .font(.headline)

            splitsHeaderRow

            ForEach(estimate.checkpointSplits) { split in
                splitRow(split)
                if split.id != estimate.checkpointSplits.last?.id {
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private var splitsHeaderRow: some View {
        HStack {
            Text("Checkpoint")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Best")
                .frame(width: 60, alignment: .trailing)
            Text("Expected")
                .frame(width: 70, alignment: .trailing)
            Text("Worst")
                .frame(width: 60, alignment: .trailing)
        }
        .font(.caption.bold())
        .foregroundStyle(Theme.Colors.secondaryLabel)
    }

    private func splitRow(_ split: CheckpointSplit) -> some View {
        HStack {
            Text(split.checkpointName)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(FinishEstimate.formatDuration(split.optimisticTime))
                .frame(width: 60, alignment: .trailing)
            Text(FinishEstimate.formatDuration(split.expectedTime))
                .frame(width: 70, alignment: .trailing)
                .fontWeight(.medium)
            Text(FinishEstimate.formatDuration(split.conservativeTime))
                .frame(width: 60, alignment: .trailing)
        }
        .font(.caption.monospacedDigit())
    }

    // MARK: - Error

    private func errorSection(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(message)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.xl)
    }
}
