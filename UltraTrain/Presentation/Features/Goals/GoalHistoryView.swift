import SwiftUI

struct GoalHistoryView: View {
    @Environment(\.unitPreference) private var units
    @State private var viewModel: GoalHistoryViewModel

    init(
        goalRepository: any GoalRepository,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository
    ) {
        _viewModel = State(initialValue: GoalHistoryViewModel(
            goalRepository: goalRepository,
            runRepository: runRepository,
            athleteRepository: athleteRepository
        ))
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else {
                weeklySection
                monthlySection

                if viewModel.weeklyHistory.isEmpty && viewModel.monthlyHistory.isEmpty {
                    ContentUnavailableView(
                        "No Goal History",
                        systemImage: "target",
                        description: Text("Set a goal to start tracking your progress over time.")
                    )
                }
            }
        }
        .navigationTitle("Goal History")
        .task { await viewModel.load() }
    }

    // MARK: - Weekly Section

    @ViewBuilder
    private var weeklySection: some View {
        if !viewModel.weeklyHistory.isEmpty {
            Section("Weekly Goals") {
                ForEach(viewModel.weeklyHistory, id: \.goal.id) { entry in
                    goalRow(goal: entry.goal, progress: entry.progress)
                }
            }
        }
    }

    // MARK: - Monthly Section

    @ViewBuilder
    private var monthlySection: some View {
        if !viewModel.monthlyHistory.isEmpty {
            Section("Monthly Goals") {
                ForEach(viewModel.monthlyHistory, id: \.goal.id) { entry in
                    goalRow(goal: entry.goal, progress: entry.progress)
                }
            }
        }
    }

    // MARK: - Goal Row

    private func goalRow(goal: TrainingGoal, progress: GoalProgress) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateRangeText(goal))
                    .font(.subheadline.bold())
                Text(summaryText(progress))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            completionBadge(progress)
        }
        .accessibilityElement(children: .combine)
    }

    private func dateRangeText(_ goal: TrainingGoal) -> String {
        let start = goal.startDate.formatted(.dateTime.month(.abbreviated).day())
        let end = goal.endDate.formatted(.dateTime.month(.abbreviated).day())
        return "\(start) – \(end)"
    }

    private func summaryText(_ progress: GoalProgress) -> String {
        var parts: [String] = []
        if progress.goal.targetDistanceKm != nil {
            parts.append(UnitFormatter.formatDistance(progress.actualDistanceKm, unit: units, decimals: 1))
        }
        if progress.goal.targetElevationM != nil {
            parts.append(UnitFormatter.formatElevation(progress.actualElevationM, unit: units))
        }
        if progress.goal.targetRunCount != nil {
            parts.append("\(progress.actualRunCount) runs")
        }
        return parts.joined(separator: " · ")
    }

    private func completionBadge(_ progress: GoalProgress) -> some View {
        let percent = overallPercent(progress)
        let color = percent >= 0.8 ? Theme.Colors.success :
                    percent >= 0.5 ? Theme.Colors.warning : Theme.Colors.danger

        return Text("\(Int(percent * 100))%")
            .font(.subheadline.bold().monospacedDigit())
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
    }

    private func overallPercent(_ progress: GoalProgress) -> Double {
        var percentages: [Double] = []
        if progress.goal.targetDistanceKm != nil { percentages.append(progress.distancePercent) }
        if progress.goal.targetElevationM != nil { percentages.append(progress.elevationPercent) }
        if progress.goal.targetRunCount != nil { percentages.append(progress.runCountPercent) }
        if progress.goal.targetDurationSeconds != nil { percentages.append(progress.durationPercent) }
        guard !percentages.isEmpty else { return 0 }
        return percentages.reduce(0, +) / Double(percentages.count)
    }
}
