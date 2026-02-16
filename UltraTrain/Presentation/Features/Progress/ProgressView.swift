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
                    fitnessSection
                    volumeChartSection
                    elevationChartSection
                    adherenceSection
                    summarySection
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
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
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
    }

    // MARK: - Adherence

    private var adherenceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Plan Adherence")
                .font(.headline)

            if viewModel.planAdherence.total > 0 {
                HStack(spacing: Theme.Spacing.lg) {
                    ZStack {
                        Circle()
                            .stroke(Theme.Colors.secondaryLabel.opacity(0.2), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: viewModel.adherencePercent / 100)
                            .stroke(adherenceColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.0f%%", viewModel.adherencePercent))
                            .font(.title3.bold().monospacedDigit())
                    }
                    .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("\(viewModel.planAdherence.completed) of \(viewModel.planAdherence.total) sessions")
                            .font(.subheadline)
                        Text(adherenceMessage)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            } else {
                Text("Generate a training plan to track adherence")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            if viewModel.weeklyAdherence.count >= 2 {
                AdherenceTrendChartView(weeklyAdherence: viewModel.weeklyAdherence)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var adherenceColor: Color {
        let pct = viewModel.adherencePercent
        if pct >= 80 { return Theme.Colors.success }
        if pct >= 50 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }

    private var adherenceMessage: String {
        let pct = viewModel.adherencePercent
        if pct >= 80 { return "Great consistency! Keep it up." }
        if pct >= 50 { return "Good progress. Try to complete more sessions." }
        return "Falling behind. Focus on key sessions."
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("8-Week Summary")
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: Theme.Spacing.md
            ) {
                StatCard(
                    title: "Total Distance",
                    value: String(format: "%.0f", viewModel.totalDistanceKm),
                    unit: "km"
                )
                StatCard(
                    title: "Total Elevation",
                    value: String(format: "%.0f", viewModel.totalElevationGainM),
                    unit: "m D+"
                )
                StatCard(
                    title: "Total Runs",
                    value: "\(viewModel.totalRuns)",
                    unit: "runs"
                )
                StatCard(
                    title: "Avg/Week",
                    value: String(format: "%.1f", viewModel.averageWeeklyKm),
                    unit: "km"
                )
            }
        }
    }
}
