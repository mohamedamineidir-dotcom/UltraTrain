import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    private let planRepository: any TrainingPlanRepository
    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository
    private let trainingLoadCalculator: any CalculateTrainingLoadUseCase

    init(
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository,
        fitnessRepository: any FitnessRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        trainingLoadCalculator: any CalculateTrainingLoadUseCase
    ) {
        self.planRepository = planRepository
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
        self.trainingLoadCalculator = trainingLoadCalculator
        _viewModel = State(initialValue: DashboardViewModel(
            planRepository: planRepository,
            runRepository: runRepository,
            athleteRepository: athleteRepository,
            fitnessRepository: fitnessRepository,
            fitnessCalculator: fitnessCalculator
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    nextSessionSection
                    weeklyStatsSection
                    fitnessSection
                    progressSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .task {
                await viewModel.load()
            }
        }
    }

    private var nextSessionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Next Session")
                .font(.headline)

            if let session = viewModel.nextSession {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: session.type.icon)
                        .font(.title2)
                        .foregroundStyle(session.intensity.color)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.type.displayName)
                            .fontWeight(.medium)
                        Text(session.date.formatted(.dateTime.weekday(.wide).month().day()))
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        if session.plannedDistanceKm > 0 {
                            Text("\(session.plannedDistanceKm, specifier: "%.1f") km")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                        }
                    }

                    Spacer()

                    Text(session.intensity.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(session.intensity.color)
                        .clipShape(Capsule())
                }
            } else {
                Text(viewModel.plan != nil
                     ? "All sessions completed this week!"
                     : "Generate a training plan to see your next session")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var weeklyStatsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
                let progress = viewModel.weeklyProgress
                if progress.total > 0 {
                    Text("\(progress.completed)/\(progress.total) sessions")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }

            HStack(spacing: Theme.Spacing.md) {
                StatCard(
                    title: "Distance",
                    value: String(format: "%.1f", viewModel.weeklyDistanceKm),
                    unit: "km"
                )
                StatCard(
                    title: "Elevation",
                    value: String(format: "%.0f", viewModel.weeklyElevationM),
                    unit: "m D+"
                )
            }

            if let weeksLeft = viewModel.weeksUntilRace {
                HStack {
                    Image(systemName: "flag.checkered")
                    Text("\(weeksLeft) weeks until race day")
                        .font(.caption)
                }
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    private var fitnessSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Fitness")
                    .font(.headline)
                Spacer()
                if viewModel.fitnessSnapshot != nil {
                    NavigationLink {
                        FitnessTrendView(
                            snapshots: viewModel.fitnessHistory,
                            currentSnapshot: viewModel.fitnessSnapshot
                        )
                    } label: {
                        Text("See trend")
                            .font(.caption)
                    }
                }
            }

            if let snapshot = viewModel.fitnessSnapshot {
                HStack(spacing: Theme.Spacing.md) {
                    StatCard(title: "Fitness", value: String(format: "%.0f", snapshot.fitness), unit: "CTL")
                    StatCard(title: "Fatigue", value: String(format: "%.0f", snapshot.fatigue), unit: "ATL")
                    StatCard(title: "Form", value: viewModel.formDescription, unit: "")
                }

                acrStatusRow(snapshot: snapshot)
            } else {
                Text("Start training to see your fitness trend")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var progressSection: some View {
        NavigationLink {
            TrainingProgressView(
                runRepository: runRepository,
                athleteRepository: athleteRepository,
                planRepository: planRepository,
                trainingLoadCalculator: trainingLoadCalculator
            )
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Training Progress")
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.label)
                    Text("\(viewModel.runCount) runs logged")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Theme.Colors.primary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .cardStyle()
        }
    }

    private func acrStatusRow(snapshot: FitnessSnapshot) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: acrIcon)
                .foregroundStyle(acrColor)
            Text("ACR: \(snapshot.acuteToChronicRatio, specifier: "%.2f")")
                .font(.caption)
            Text(acrLabel)
                .font(.caption.bold())
                .foregroundStyle(acrColor)
        }
    }

    private var acrIcon: String {
        switch viewModel.fitnessStatus {
        case .injuryRisk: "exclamationmark.triangle.fill"
        case .detraining: "arrow.down.circle.fill"
        case .optimal: "checkmark.circle.fill"
        case .noData: "minus.circle"
        }
    }

    private var acrColor: Color {
        switch viewModel.fitnessStatus {
        case .injuryRisk: Theme.Colors.danger
        case .detraining: Theme.Colors.warning
        case .optimal: Theme.Colors.success
        case .noData: Theme.Colors.secondaryLabel
        }
    }

    private var acrLabel: String {
        switch viewModel.fitnessStatus {
        case .injuryRisk: "Injury Risk"
        case .detraining: "Detraining"
        case .optimal: "Optimal"
        case .noData: ""
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct PreviewPlanRepository: TrainingPlanRepository, @unchecked Sendable {
    func getActivePlan() async throws -> TrainingPlan? { nil }
    func getPlan(id: UUID) async throws -> TrainingPlan? { nil }
    func savePlan(_ plan: TrainingPlan) async throws {}
    func updatePlan(_ plan: TrainingPlan) async throws {}
    func updateSession(_ session: TrainingSession) async throws {}
}

private struct PreviewRunRepository: RunRepository, @unchecked Sendable {
    func getRuns(for athleteId: UUID) async throws -> [CompletedRun] { [] }
    func getRun(id: UUID) async throws -> CompletedRun? { nil }
    func saveRun(_ run: CompletedRun) async throws {}
    func deleteRun(id: UUID) async throws {}
    func getRecentRuns(limit: Int) async throws -> [CompletedRun] { [] }
}

private struct PreviewAthleteRepository: AthleteRepository, @unchecked Sendable {
    func getAthlete() async throws -> Athlete? { nil }
    func saveAthlete(_ athlete: Athlete) async throws {}
    func updateAthlete(_ athlete: Athlete) async throws {}
}

private struct PreviewFitnessRepository: FitnessRepository, @unchecked Sendable {
    func getSnapshots(from: Date, to: Date) async throws -> [FitnessSnapshot] { [] }
    func getLatestSnapshot() async throws -> FitnessSnapshot? { nil }
    func saveSnapshot(_ snapshot: FitnessSnapshot) async throws {}
}

private struct PreviewFitnessCalculator: CalculateFitnessUseCase, @unchecked Sendable {
    func execute(runs: [CompletedRun], asOf date: Date) async throws -> FitnessSnapshot {
        FitnessSnapshot(
            id: UUID(),
            date: date,
            fitness: 0,
            fatigue: 0,
            form: 0,
            weeklyVolumeKm: 0,
            weeklyElevationGainM: 0,
            weeklyDuration: 0,
            acuteToChronicRatio: 0,
            monotony: 0
        )
    }
}

private struct PreviewTrainingLoadCalculator: CalculateTrainingLoadUseCase, @unchecked Sendable {
    func execute(runs: [CompletedRun], plan: TrainingPlan?, asOf date: Date) async throws -> TrainingLoadSummary {
        TrainingLoadSummary(
            currentWeekLoad: WeeklyLoadData(weekStartDate: date.startOfWeek),
            weeklyHistory: [], acrTrend: [], monotony: 0, monotonyLevel: .low
        )
    }
}

#Preview("Dashboard") {
    DashboardView(
        planRepository: PreviewPlanRepository(),
        runRepository: PreviewRunRepository(),
        athleteRepository: PreviewAthleteRepository(),
        fitnessRepository: PreviewFitnessRepository(),
        fitnessCalculator: PreviewFitnessCalculator(),
        trainingLoadCalculator: PreviewTrainingLoadCalculator()
    )
}
#endif
