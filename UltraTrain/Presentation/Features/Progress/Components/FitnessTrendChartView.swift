import SwiftUI
import Charts

struct FitnessTrendChartView: View {
    let snapshots: [FitnessSnapshot]
    @State private var selectedDate: Date?

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

            if let selectedDate, let snapshot = nearestSnapshot(to: selectedDate) {
                RuleMark(x: .value("Selected", snapshot.date))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartForegroundStyleScale([
            "Fitness": Theme.Colors.zone2,
            "Fatigue": Theme.Colors.warning,
            "Form": Theme.Colors.success
        ])
        .chartYAxisLabel("Load")
        .frame(height: 220)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let x = drag.location.x - geo[proxy.plotFrame!].origin.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectedDate = date
                                }
                            }
                            .onEnded { _ in
                                selectedDate = nil
                            }
                    )
            }
        }
        .chartBackground { proxy in
            GeometryReader { geo in
                if let selectedDate, let snapshot = nearestSnapshot(to: selectedDate) {
                    let plotFrame = geo[proxy.plotFrame!]
                    if let xPos = proxy.position(forX: snapshot.date) {
                        let cardWidth: CGFloat = 130
                        let clampedX = min(max(xPos, cardWidth / 2), plotFrame.width - cardWidth / 2)
                        ChartAnnotationCard(
                            title: snapshot.date.formatted(.dateTime.month(.abbreviated).day()),
                            value: String(format: "CTL %.0f  ATL %.0f", snapshot.fitness, snapshot.fatigue),
                            subtitle: String(format: "Form %+.0f", snapshot.form)
                        )
                        .offset(x: clampedX, y: -8)
                    }
                }
            }
        }
    }

    private func nearestSnapshot(to date: Date) -> FitnessSnapshot? {
        snapshots.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
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
