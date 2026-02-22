import SwiftUI

struct TrainingLoadView: View {
    @State private var viewModel: TrainingLoadViewModel

    init(
        trainingLoadCalculator: any CalculateTrainingLoadUseCase,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository
    ) {
        _viewModel = State(initialValue: TrainingLoadViewModel(
            trainingLoadCalculator: trainingLoadCalculator,
            runRepository: runRepository,
            athleteRepository: athleteRepository,
            planRepository: planRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding(.top, Theme.Spacing.xl)
                } else if let summary = viewModel.summary {
                    if !viewModel.injuryRiskAlerts.isEmpty {
                        InjuryRiskAlertBanner(alerts: viewModel.injuryRiskAlerts)
                    }
                    currentWeekSection(summary)
                    WeeklyLoadChartView(weeklyHistory: summary.weeklyHistory)
                    acrSection(summary)
                    monotonySection(summary)
                } else {
                    ContentUnavailableView(
                        "No Training Data",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Complete some runs to see your training load analysis.")
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Training Load")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - Current Week

    private func currentWeekSection(_ summary: TrainingLoadSummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: Theme.Spacing.md) {
                StatCard(
                    title: "Load",
                    value: viewModel.currentLoadFormatted,
                    unit: "effort",
                    trend: viewModel.loadTrend
                )
                StatCard(
                    title: "Distance",
                    value: viewModel.currentDistanceFormatted,
                    unit: "km"
                )
                StatCard(
                    title: "Duration",
                    value: viewModel.currentDurationFormatted,
                    unit: ""
                )
            }
        }
    }

    // MARK: - ACR

    private func acrSection(_ summary: TrainingLoadSummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ACRTrendChartView(dataPoints: summary.acrTrend)
            acrStatusRow
        }
    }

    private var acrStatusRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: viewModel.acrStatusIcon)
                .foregroundStyle(acrColor)
                .accessibilityHidden(true)
            Text("ACR: \(viewModel.currentACR, specifier: "%.2f")")
                .font(.subheadline)
            Spacer()
            Text(viewModel.acrStatusLabel)
                .font(.caption.bold())
                .foregroundStyle(acrColor)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(acrColor.opacity(0.1))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Acute to chronic ratio: \(String(format: "%.2f", viewModel.currentACR)). Status: \(viewModel.acrStatusLabel)")
    }

    private var acrColor: Color {
        let acr = viewModel.currentACR
        if acr > 1.5 { return Theme.Colors.danger }
        if acr < 0.8 { return Theme.Colors.warning }
        return Theme.Colors.success
    }

    // MARK: - Monotony

    private func monotonySection(_ summary: TrainingLoadSummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Training Monotony")
                .font(.headline)

            HStack(spacing: Theme.Spacing.sm) {
                Text(String(format: "%.1f", summary.monotony))
                    .font(.title2.bold().monospacedDigit())

                Text(summary.monotonyLevel.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(monotonyColor(summary.monotonyLevel))
                    .clipShape(Capsule())

                Spacer()
            }

            Text(viewModel.monotonyDescription)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Training monotony: \(String(format: "%.1f", summary.monotony)), \(summary.monotonyLevel.displayName). \(viewModel.monotonyDescription)")
    }

    private func monotonyColor(_ level: MonotonyLevel) -> Color {
        switch level {
        case .low: Theme.Colors.success
        case .normal: Theme.Colors.warning
        case .high: Theme.Colors.danger
        }
    }
}
