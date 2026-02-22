import SwiftUI

struct RaceReportView: View {
    @Environment(\.unitPreference) private var units
    @State private var viewModel: RaceReportViewModel

    init(
        race: Race,
        raceReflectionRepository: any RaceReflectionRepository,
        finishEstimateRepository: any FinishEstimateRepository,
        runRepository: any RunRepository
    ) {
        _viewModel = State(initialValue: RaceReportViewModel(
            race: race,
            raceReflectionRepository: raceReflectionRepository,
            finishEstimateRepository: finishEstimateRepository,
            runRepository: runRepository
        ))
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading report...")
                    .padding(.top, Theme.Spacing.xl)
            } else {
                VStack(spacing: Theme.Spacing.md) {
                    raceHeader
                    resultCard
                    if viewModel.estimate != nil {
                        predictionAccuracyCard
                    }
                    if viewModel.reflection != nil {
                        reflectionSummaryCard
                        satisfactionCard
                        takeawaysCard
                    }
                    if viewModel.linkedRun != nil {
                        linkedRunLink
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Race Report")
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
                    viewModel.race.date.formatted(date: .abbreviated, time: .omitted),
                    systemImage: "calendar"
                )
                Label(
                    UnitFormatter.formatDistance(viewModel.race.distanceKm, unit: units, decimals: 0),
                    systemImage: "point.topleft.down.to.point.bottomright.curvepath"
                )
                Label(
                    "\(UnitFormatter.formatElevation(viewModel.race.elevationGainM, unit: units)) D+",
                    systemImage: "mountain.2"
                )
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            Label(
                viewModel.race.terrainDifficulty.rawValue.capitalized,
                systemImage: "map"
            )
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Result Card

    private var resultCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if let actual = viewModel.race.actualFinishTime {
                Text(FinishEstimate.formatDuration(actual))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
            }
            if let position = viewModel.reflection?.actualPosition {
                Text("Position: #\(position)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            goalAchievementBadge
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var goalAchievementBadge: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: viewModel.goalAchieved ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(viewModel.goalAchieved ? Theme.Colors.success : Theme.Colors.danger)
            Text(goalDescription)
                .font(.subheadline.bold())
                .foregroundStyle(viewModel.goalAchieved ? Theme.Colors.success : Theme.Colors.danger)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            (viewModel.goalAchieved ? Theme.Colors.success : Theme.Colors.danger).opacity(0.1),
            in: Capsule()
        )
    }

    private var goalDescription: String {
        switch viewModel.race.goalType {
        case .finish:
            return viewModel.goalAchieved ? "Finished!" : "Did not finish"
        case .targetTime(let target):
            let targetStr = FinishEstimate.formatDuration(target)
            return viewModel.goalAchieved ? "Target \(targetStr) achieved" : "Target \(targetStr) missed"
        case .targetRanking(let rank):
            return viewModel.goalAchieved ? "Top \(rank) achieved" : "Top \(rank) missed"
        }
    }

    // MARK: - Prediction Accuracy Card

    private var predictionAccuracyCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Prediction Accuracy")
                .font(.headline)

            if let accuracy = viewModel.predictionAccuracy {
                HStack {
                    Text(String(format: "%.1f%%", accuracy))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(accuracy >= 90 ? Theme.Colors.success : Theme.Colors.warning)
                    Spacer()
                }
            }

            if let estimate = viewModel.estimate, let actual = viewModel.race.actualFinishTime {
                predictionComparisonRow(
                    label: "Optimistic",
                    predicted: estimate.optimisticTime,
                    actual: actual
                )
                predictionComparisonRow(
                    label: "Expected",
                    predicted: estimate.expectedTime,
                    actual: actual
                )
                predictionComparisonRow(
                    label: "Conservative",
                    predicted: estimate.conservativeTime,
                    actual: actual
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func predictionComparisonRow(label: String, predicted: TimeInterval, actual: TimeInterval) -> some View {
        let diff = actual - predicted
        return HStack {
            Text(label).font(.caption).foregroundStyle(Theme.Colors.secondaryLabel).frame(width: 90, alignment: .leading)
            Text(FinishEstimate.formatDuration(predicted)).font(.caption.monospacedDigit())
            Spacer()
            Text("\(diff < 0 ? "-" : "+")\(FinishEstimate.formatDuration(abs(diff)))")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(diff < 0 ? Theme.Colors.success : Theme.Colors.danger)
        }
    }

    // MARK: - Reflection Summary

    private var reflectionSummaryCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Reflection")
                .font(.headline)
            if let reflection = viewModel.reflection {
                reflectionRow(
                    icon: "speedometer",
                    label: "Pacing",
                    value: reflection.pacingAssessment.displayLabel,
                    color: reflection.pacingAssessment.displayColor
                )
                reflectionRow(
                    icon: "fork.knife",
                    label: "Nutrition",
                    value: reflection.nutritionAssessment.displayLabel,
                    color: reflection.nutritionAssessment.displayColor
                )
                reflectionRow(
                    icon: "cloud.sun",
                    label: "Weather",
                    value: reflection.weatherImpact.displayLabel,
                    color: reflection.weatherImpact.displayColor
                )
                if reflection.hadStomachIssues {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.Colors.warning)
                        Text("Stomach issues reported")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.warning)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func reflectionRow(
        icon: String,
        label: String,
        value: String,
        color: Color
    ) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
    }

    // MARK: - Satisfaction

    private var satisfactionCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Satisfaction")
                .font(.headline)
            if let reflection = viewModel.reflection {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= reflection.overallSatisfaction ? "star.fill" : "star")
                            .foregroundStyle(star <= reflection.overallSatisfaction ? Theme.Colors.warning : Theme.Colors.secondaryLabel)
                    }
                }
                .font(.title3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Takeaways

    private var takeawaysCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Key Takeaways")
                .font(.headline)
            if let reflection = viewModel.reflection, !reflection.keyTakeaways.isEmpty {
                Text(reflection.keyTakeaways)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.label)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Linked Run

    private var linkedRunLink: some View {
        NavigationLink {
            Text("Run Details")
        } label: {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundStyle(Theme.Colors.primary)
                Text("View Linked Run")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }
}
