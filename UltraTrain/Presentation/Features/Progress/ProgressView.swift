import SwiftUI
import Charts

struct TrainingProgressView: View {
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
                    injuryRiskSection
                    phaseTimelineSection
                    fitnessSection
                    raceReadinessSection
                    volumeChartSection
                    elevationChartSection
                    durationChartSection
                    cumulativeVolumeSection
                    sessionTypeSection
                    adherenceSection
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
                        Text("Form: \(viewModel.formLabel)")
                            .font(.subheadline)
                        Spacer()
                        if let snapshot = viewModel.currentFitnessSnapshot {
                            Text(String(format: "%+.0f TSB", snapshot.form))
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(viewModel.formColor)
                        }
                    }
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weekly Distance")
                .font(.headline)

            Chart(viewModel.weeklyVolumes) { week in
                BarMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Distance", week.distanceKm)
                )
                .foregroundStyle(Theme.Colors.primary.gradient)
                .cornerRadius(4)
            }
            .chartYAxisLabel("km")
            .frame(height: 180)
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly distance chart. Total \(String(format: "%.0f", viewModel.totalDistanceKm)) km over \(viewModel.weeklyVolumes.count) weeks.")
    }

    // MARK: - Elevation Chart

    private var elevationChartSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weekly Elevation")
                .font(.headline)

            Chart(viewModel.weeklyVolumes) { week in
                BarMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Elevation", week.elevationGainM)
                )
                .foregroundStyle(Theme.Colors.success.gradient)
                .cornerRadius(4)
            }
            .chartYAxisLabel("m D+")
            .frame(height: 180)
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly elevation chart. Total \(String(format: "%.0f", viewModel.totalElevationGainM)) meters of elevation gain.")
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
