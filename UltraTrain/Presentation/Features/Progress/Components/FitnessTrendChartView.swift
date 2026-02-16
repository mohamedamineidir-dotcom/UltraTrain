import SwiftUI
import Charts

struct FitnessTrendChartView: View {
    let snapshots: [FitnessSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Fitness Trend")
                .font(.headline)

            if snapshots.count < 2 {
                Text("Not enough data to show trend")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                chart
                legend
            }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            // Form area fill — green above zero
            ForEach(snapshots) { snapshot in
                AreaMark(
                    x: .value("Date", snapshot.date),
                    yStart: .value("Zero", 0),
                    yEnd: .value("Form+", max(0, snapshot.form))
                )
                .foregroundStyle(Theme.Colors.success.opacity(0.15))
            }

            // Form area fill — red below zero
            ForEach(snapshots) { snapshot in
                AreaMark(
                    x: .value("Date", snapshot.date),
                    yStart: .value("Zero", 0),
                    yEnd: .value("Form-", min(0, snapshot.form))
                )
                .foregroundStyle(Theme.Colors.danger.opacity(0.15))
            }

            // Zero reference line
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

            // CTL (Fitness) line
            ForEach(snapshots) { snapshot in
                LineMark(
                    x: .value("Date", snapshot.date),
                    y: .value("Load", snapshot.fitness),
                    series: .value("Metric", "Fitness")
                )
                .foregroundStyle(Theme.Colors.zone2)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            // ATL (Fatigue) line
            ForEach(snapshots) { snapshot in
                LineMark(
                    x: .value("Date", snapshot.date),
                    y: .value("Load", snapshot.fatigue),
                    series: .value("Metric", "Fatigue")
                )
                .foregroundStyle(Theme.Colors.warning)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            // TSB (Form) line
            ForEach(snapshots) { snapshot in
                LineMark(
                    x: .value("Date", snapshot.date),
                    y: .value("Load", snapshot.form),
                    series: .value("Metric", "Form")
                )
                .foregroundStyle(Theme.Colors.success)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartForegroundStyleScale([
            "Fitness": Theme.Colors.zone2,
            "Fatigue": Theme.Colors.warning,
            "Form": Theme.Colors.success
        ])
        .chartYAxisLabel("Load")
        .frame(height: 220)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: Theme.Spacing.md) {
            legendDot(color: Theme.Colors.zone2, label: "Fitness (CTL)")
            legendDot(color: Theme.Colors.warning, label: "Fatigue (ATL)")
            legendDot(color: Theme.Colors.success, label: "Form (TSB)")
        }
        .font(.caption2)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}
