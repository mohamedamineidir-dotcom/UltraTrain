import SwiftUI
import Charts

struct PaceDistributionChart: View {
    @Environment(\.unitPreference) private var units
    let buckets: [PaceDistributionCalculator.PaceBucket]
    @State private var displayMode: DisplayMode = .duration
    @State private var selectedBucket: PaceDistributionCalculator.PaceBucket?

    enum DisplayMode: String, CaseIterable {
        case duration = "Duration"
        case distance = "Distance"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Pace Distribution")
                .font(.headline)

            Picker("Display", selection: $displayMode) {
                ForEach(DisplayMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Chart {
                ForEach(buckets) { bucket in
                    BarMark(
                        x: .value("Pace", bucket.rangeLabel),
                        y: .value(yLabel, yValue(for: bucket))
                    )
                    .foregroundStyle(barColor(for: bucket))
                    .cornerRadius(4)
                    .opacity(selectedBucket == nil || selectedBucket?.id == bucket.id ? 1.0 : 0.4)
                }

                selectionMark
            }
            .chartYAxisLabel(yLabel)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: min(buckets.count, 8))) { value in
                    AxisGridLine()
                    AxisValueLabel(anchor: .top) {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.caption2)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(yAxisLabel(for: val))
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleDrag(value: value, proxy: proxy, geometry: geometry)
                                }
                                .onEnded { _ in
                                    selectedBucket = nil
                                }
                        )
                }
            }
            .frame(height: 200)

            legendRow
        }
        .chartAccessibility(summary: chartSummary)
    }

    // MARK: - Y Value

    private var yLabel: String {
        displayMode == .duration ? "Minutes" : UnitFormatter.distanceLabel(units)
    }

    private func yValue(for bucket: PaceDistributionCalculator.PaceBucket) -> Double {
        displayMode == .duration ? bucket.durationSeconds / 60 : bucket.distanceKm
    }

    private func yAxisLabel(for value: Double) -> String {
        if displayMode == .duration {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    // MARK: - Bar Color

    private var medianPace: Double {
        guard !buckets.isEmpty else { return 0 }
        let sorted = buckets.sorted { $0.rangeLowerSeconds < $1.rangeLowerSeconds }
        let totalDuration = sorted.reduce(0) { $0 + $1.durationSeconds }
        var accumulated: TimeInterval = 0
        for bucket in sorted {
            accumulated += bucket.durationSeconds
            if accumulated >= totalDuration / 2 {
                return bucket.rangeLowerSeconds
            }
        }
        return sorted[sorted.count / 2].rangeLowerSeconds
    }

    private func barColor(for bucket: PaceDistributionCalculator.PaceBucket) -> Color {
        guard medianPace > 0 else { return Theme.Colors.primary }
        let ratio = bucket.rangeLowerSeconds / medianPace
        if ratio < 0.85 {
            return Theme.Colors.success
        } else if ratio <= 1.15 {
            return Theme.Colors.primary
        } else if ratio <= 1.4 {
            return Theme.Colors.warning
        }
        return Theme.Colors.danger
    }

    // MARK: - Selection

    @ChartContentBuilder
    private var selectionMark: some ChartContent {
        if let bucket = selectedBucket {
            RuleMark(x: .value("Selected", bucket.rangeLabel))
                .foregroundStyle(Theme.Colors.label.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .annotation(position: .top, spacing: 4) {
                    ChartAnnotationCard(
                        title: bucket.rangeLabel + " " + UnitFormatter.paceLabel(units),
                        value: displayMode == .duration
                            ? String(format: "%.1f min", bucket.durationSeconds / 60)
                            : String(format: "%.2f %@", bucket.distanceKm, UnitFormatter.distanceLabel(units)),
                        subtitle: String(format: "%.1f%% of run", bucket.percentage)
                    )
                }
        }
    }

    private func handleDrag(
        value: DragGesture.Value,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        let plotFrame = geometry[proxy.plotFrame!]
        let xPosition = value.location.x - plotFrame.origin.x
        guard let label: String = proxy.value(atX: xPosition) else { return }
        if let bucket = buckets.first(where: { $0.rangeLabel == label }) {
            selectedBucket = bucket
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            legendDot(color: Theme.Colors.success, label: "Fast")
            legendDot(color: Theme.Colors.primary, label: "Average")
            legendDot(color: Theme.Colors.warning, label: "Moderate")
            legendDot(color: Theme.Colors.danger, label: "Slow")
        }
        .font(.caption)
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

    // MARK: - Accessibility

    private var chartSummary: String {
        guard !buckets.isEmpty else { return "Pace distribution chart, no data" }
        let peakBucket = buckets.max(by: { $0.durationSeconds < $1.durationSeconds })
        let peakLabel = peakBucket?.rangeLabel ?? "--"
        return "Pace distribution histogram with \(buckets.count) pace ranges. Most time spent at \(peakLabel) per \(UnitFormatter.distanceLabel(units))."
    }
}
