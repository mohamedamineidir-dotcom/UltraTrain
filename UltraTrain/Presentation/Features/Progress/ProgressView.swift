import SwiftUI

struct TrainingProgressView: View {
    @Environment(\.unitPreference) private var units
    @State var viewModel: ProgressViewModel
    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository
    private let planRepository: any TrainingPlanRepository
    private let trainingLoadCalculator: any CalculateTrainingLoadUseCase

    init(
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository,
        raceRepository: any RaceRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        fitnessRepository: any FitnessRepository,
        trainingLoadCalculator: any CalculateTrainingLoadUseCase
    ) {
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
        self.planRepository = planRepository
        self.trainingLoadCalculator = trainingLoadCalculator
        _viewModel = State(initialValue: ProgressViewModel(
            runRepository: runRepository,
            athleteRepository: athleteRepository,
            planRepository: planRepository,
            raceRepository: raceRepository,
            fitnessCalculator: fitnessCalculator,
            fitnessRepository: fitnessRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding(.top, Theme.Spacing.xl)
                } else {
                    trainingLoadLink
                    runFrequencyHeatmapLink
                    thisWeekSection
                    injuryRiskSection
                    phaseTimelineSection
                    fitnessSection
                    raceReadinessSection
                    volumeChartSection
                    elevationChartSection
                    durationChartSection
                    cumulativeVolumeSection
                    monthlyVolumeSection
                    sessionTypeSection
                    adherenceSection
                    trainingCalendarSection
                    summarySection
                    paceTrendSection
                    heartRateTrendSection
                    personalRecordsSection
                }
            }
            .padding()
        }
        .navigationTitle("Training Progress")
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Training Load Link

    var trainingLoadLink: some View {
        NavigationLink {
            TrainingLoadView(
                trainingLoadCalculator: trainingLoadCalculator,
                runRepository: runRepository,
                athleteRepository: athleteRepository,
                planRepository: planRepository
            )
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Training Load")
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.label)
                    Text("Effort trends, injury risk & monotony")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .accessibilityHidden(true)
            }
            .cardStyle()
        }
    }

    // MARK: - Run Frequency Heatmap Link

    var runFrequencyHeatmapLink: some View {
        NavigationLink {
            RunFrequencyHeatmapView(
                runRepository: runRepository,
                athleteRepository: athleteRepository
            )
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Run Heatmap")
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.label)
                    Text("Most frequently run areas")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "map.fill")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .accessibilityHidden(true)
            }
            .cardStyle()
        }
    }

    // MARK: - This Week

    var thisWeekSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: Theme.Spacing.md) {
                StatCard(
                    title: "Distance",
                    value: viewModel.currentWeekDistanceFormatted,
                    unit: "km",
                    trend: viewModel.distanceTrend
                )
                StatCard(
                    title: "Elevation",
                    value: viewModel.currentWeekElevationFormatted,
                    unit: "m D+",
                    trend: viewModel.elevationTrend
                )
                StatCard(
                    title: "Duration",
                    value: viewModel.currentWeekDurationFormatted,
                    unit: "",
                    trend: viewModel.durationTrend
                )
            }
        }
    }

    // MARK: - Injury Risk Alerts

    @ViewBuilder
    var injuryRiskSection: some View {
        let critical = viewModel.injuryRiskAlerts.filter { $0.severity == .critical }
        if !critical.isEmpty {
            InjuryRiskAlertBanner(alerts: critical)
        }
    }

    // MARK: - Phase Timeline

    @ViewBuilder
    var phaseTimelineSection: some View {
        if !viewModel.phaseBlocks.isEmpty {
            PhaseTimelineView(blocks: viewModel.phaseBlocks)
                .cardStyle()
        }
    }
}
