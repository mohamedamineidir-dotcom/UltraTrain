import SwiftUI

struct TrainingProgressView: View {
    @Environment(\.unitPreference) private var units
    @State private var viewModel: ProgressViewModel
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

    private var trainingLoadLink: some View {
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

    private var runFrequencyHeatmapLink: some View {
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

    private var thisWeekSection: some View {
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
    private var injuryRiskSection: some View {
        let critical = viewModel.injuryRiskAlerts.filter { $0.severity == .critical }
        if !critical.isEmpty {
            InjuryRiskAlertBanner(alerts: critical)
        }
    }

    // MARK: - Phase Timeline

    @ViewBuilder
    private var phaseTimelineSection: some View {
        if !viewModel.phaseBlocks.isEmpty {
            PhaseTimelineView(blocks: viewModel.phaseBlocks)
                .cardStyle()
        }
    }

    // MARK: - Fitness Section

    private var fitnessSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if viewModel.fitnessSnapshots.count >= 2 {
                FitnessTrendChartView(snapshots: viewModel.fitnessSnapshots)

                if viewModel.formStatus != .noData {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: viewModel.formIcon)
                            .foregroundStyle(viewModel.formColor)
                            .accessibilityHidden(true)
                        Text("Form: \(viewModel.formLabel)")
                            .font(.subheadline)
                        Spacer()
                        if let snapshot = viewModel.currentFitnessSnapshot {
                            Text(String(format: "%+.0f TSB", snapshot.form))
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(viewModel.formColor)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Current form: \(viewModel.formLabel)\(viewModel.currentFitnessSnapshot.map { String(format: ". Training stress balance: %+.0f", $0.form) } ?? "")")
                }
            } else {
                Text("Complete some runs to see your fitness trend")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .cardStyle()
    }

    // MARK: - Race Readiness

    @ViewBuilder
    private var raceReadinessSection: some View {
        if let forecast = viewModel.raceReadiness {
            RaceReadinessCard(forecast: forecast)
                .cardStyle()
        }
    }

    // MARK: - Volume Chart

    private var volumeChartSection: some View {
        WeeklyDistanceChartView(weeklyVolumes: viewModel.weeklyVolumes)
            .cardStyle()
    }

    // MARK: - Elevation Chart

    private var elevationChartSection: some View {
        WeeklyElevationChartView(weeklyVolumes: viewModel.weeklyVolumes)
            .cardStyle()
    }

    // MARK: - Duration Chart

    @ViewBuilder
    private var durationChartSection: some View {
        if viewModel.weeklyVolumes.contains(where: { $0.duration > 0 }) {
            WeeklyDurationChartView(weeklyVolumes: viewModel.weeklyVolumes)
                .cardStyle()
        }
    }

    // MARK: - Cumulative Volume

    @ViewBuilder
    private var cumulativeVolumeSection: some View {
        if viewModel.weeklyVolumes.contains(where: { $0.distanceKm > 0 }) {
            CumulativeVolumeChartView(weeklyVolumes: viewModel.weeklyVolumes)
                .cardStyle()
        }
    }

    // MARK: - Monthly Volume

    @ViewBuilder
    private var monthlyVolumeSection: some View {
        if viewModel.monthlyVolumes.count >= 2 {
            MonthlyVolumeComparisonChart(monthlyVolumes: viewModel.monthlyVolumes)
                .cardStyle()
        }
    }

    // MARK: - Session Type Breakdown

    @ViewBuilder
    private var sessionTypeSection: some View {
        if !viewModel.sessionTypeStats.isEmpty {
            SessionTypeBreakdownChart(stats: viewModel.sessionTypeStats)
                .cardStyle()
        }
    }

    // MARK: - Adherence

    private var adherenceSection: some View {
        ProgressAdherenceSection(
            adherencePercent: viewModel.adherencePercent,
            completed: viewModel.planAdherence.completed,
            total: viewModel.planAdherence.total,
            weeklyAdherence: viewModel.weeklyAdherence
        )
    }

    // MARK: - Training Calendar

    @ViewBuilder
    private var trainingCalendarSection: some View {
        if !viewModel.calendarHeatmapDays.isEmpty {
            TrainingCalendarHeatmapView(dayIntensities: viewModel.calendarHeatmapDays)
                .cardStyle()
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        ProgressSummarySection(
            totalDistanceKm: viewModel.totalDistanceKm,
            totalElevationGainM: viewModel.totalElevationGainM,
            totalRuns: viewModel.totalRuns,
            averageWeeklyKm: viewModel.averageWeeklyKm
        )
    }

    // MARK: - Pace Trend

    @ViewBuilder
    private var paceTrendSection: some View {
        if viewModel.runTrendPoints.count >= 3 {
            PaceTrendChartView(trendPoints: viewModel.runTrendPoints)
                .cardStyle()
        }
    }

    // MARK: - Heart Rate Trend

    @ViewBuilder
    private var heartRateTrendSection: some View {
        let pointsWithHR = viewModel.runTrendPoints.filter { $0.averageHeartRate != nil }
        if pointsWithHR.count >= 3 {
            HeartRateTrendChartView(trendPoints: viewModel.runTrendPoints)
                .cardStyle()
        }
    }

    // MARK: - Personal Records

    @ViewBuilder
    private var personalRecordsSection: some View {
        if !viewModel.personalRecords.isEmpty {
            PersonalRecordsSection(records: viewModel.personalRecords)
                .cardStyle()
        }
    }
}
