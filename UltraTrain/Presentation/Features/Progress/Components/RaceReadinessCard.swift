import SwiftUI
import Charts

struct RaceReadinessCard: View {
    let forecast: RaceReadinessForecast

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            projectionChart
                .chartAccessibility(summary: projectionChartSummary)
            metricsRow
        }
        .accessibilityElement(children: .combine)
    }

    private var projectionChartSummary: String {
        AccessibilityFormatters.chartSummary(
            title: "Race readiness projection for \(forecast.raceName)",
            dataPoints: forecast.fitnessProjectionPoints.count,
            trend: "\(forecast.daysUntilRace) days until race. Current fitness \(Int(forecast.currentFitness)), projected \(Int(forecast.projectedFitnessAtRace)). Form status: \(formLabel)"
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Race Readiness")
                    .font(.headline)
                Text(forecast.raceName)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                Text("\(forecast.daysUntilRace)")
                    .font(.title2.bold().monospacedDigit())
                Text("days to go")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    // MARK: - Chart

    private var projectionChart: some View {
        Chart {
            ForEach(forecast.fitnessProjectionPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Fitness", point.projectedFitness),
                    series: .value("Metric", "Fitness")
                )
                .foregroundStyle(Theme.Colors.zone2)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
            }

            ForEach(forecast.fitnessProjectionPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Form", point.projectedForm),
                    series: .value("Metric", "Form")
                )
                .foregroundStyle(Theme.Colors.success)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
            }

            RuleMark(x: .value("Race", forecast.raceDate))
                .foregroundStyle(Theme.Colors.danger.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Race")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.danger)
                }

            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
        .chartForegroundStyleScale([
            "Fitness": Theme.Colors.zone2,
            "Form": Theme.Colors.success
        ])
        .chartYAxisLabel("Load")
        .frame(height: 150)
    }

    // MARK: - Metrics

    private var metricsRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            metricTile(
                label: "Current Fitness",
                value: String(format: "%.0f", forecast.currentFitness)
            )
            metricTile(
                label: "Projected Fitness",
                value: String(format: "%.0f", forecast.projectedFitnessAtRace)
            )
            VStack(spacing: Theme.Spacing.xs) {
                Text("Projected Form")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(formLabel)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(formColor)
                    .clipShape(Capsule())
            }
        }
    }

    private func metricTile(label: String, value: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.title3.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var formLabel: String {
        switch forecast.projectedFormStatus {
        case .raceReady: "Race Ready"
        case .fresh: "Fresh"
        case .building: "Building"
        case .fatigued: "Fatigued"
        case .noData: "--"
        }
    }

    private var formColor: Color {
        switch forecast.projectedFormStatus {
        case .raceReady, .fresh: Theme.Colors.success
        case .building: Theme.Colors.warning
        case .fatigued: Theme.Colors.danger
        case .noData: Theme.Colors.secondaryLabel
        }
    }
}
