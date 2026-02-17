import SwiftUI

struct RunHistoryView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 48
    @State private var viewModel: RunHistoryViewModel
    private let planRepository: any TrainingPlanRepository
    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository

    init(
        runRepository: any RunRepository,
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository
    ) {
        _viewModel = State(initialValue: RunHistoryViewModel(runRepository: runRepository))
        self.planRepository = planRepository
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.sortedRuns.isEmpty {
                emptyState
            } else {
                runList
            }
        }
        .navigationTitle("Run History")
        .task { await viewModel.load() }
    }

    // MARK: - List

    private var runList: some View {
        List {
            ForEach(viewModel.sortedRuns) { run in
                NavigationLink(value: run.id) {
                    RunHistoryRow(run: run)
                }
            }
            .onDelete { indexSet in
                let sorted = viewModel.sortedRuns
                for index in indexSet {
                    Task { await viewModel.deleteRun(id: sorted[index].id) }
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: UUID.self) { runId in
            if let run = viewModel.runs.first(where: { $0.id == runId }) {
                RunDetailView(
                    run: run,
                    planRepository: planRepository,
                    athleteRepository: athleteRepository,
                    raceRepository: raceRepository
                )
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: emptyIconSize))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text("No runs yet")
                .font(.headline)
            Text("Your completed runs will appear here.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}

// MARK: - Row

private struct RunHistoryRow: View {
    let run: CompletedRun

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(run.date, style: .date)
                    .font(.subheadline.bold())
                Spacer()
                Text(RunStatisticsCalculator.formatDuration(run.duration))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            HStack(spacing: Theme.Spacing.md) {
                Label(
                    String(format: "%.2f km", run.distanceKm),
                    systemImage: "arrow.left.arrow.right"
                )
                Label(run.paceFormatted, systemImage: "speedometer")
                if run.elevationGainM > 0 {
                    Label(
                        String(format: "+%.0f m", run.elevationGainM),
                        systemImage: "arrow.up.right"
                    )
                }
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}
