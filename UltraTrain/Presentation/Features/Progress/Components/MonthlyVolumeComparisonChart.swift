import SwiftUI
import Charts

struct MonthlyVolumeComparisonChart: View {
    @Environment(\.unitPreference) private var units
    let monthlyVolumes: [MonthlyVolumeCalculator.MonthlyVolume]
    @State private var metric: VolumeMetric = .distance
    @State private var selectedMonth: Date?

    enum VolumeMetric: String, CaseIterable {
        case distance = "Distance"
        case elevation = "Elevation"
        case duration = "Duration"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Monthly Volume")
                .font(.headline)

            metricPicker

            if monthlyVolumes.isEmpty {
                Text("No monthly data yet")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                chart
            }
        }
        .chartAccessibility(summary: accessibilitySummary)
    }

    // MARK: - Metric Picker

    private var metricPicker: some View {
        Picker("Metric", selection: $metric) {
            ForEach(VolumeMetric.allCases, id: \.self) { m in
                Text(m.rawValue).tag(m)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(displayVolumes) { volume in
                BarMark(
                    x: .value("Month", monthLabel(for: volume.month)),
                    y: .value(metric.rawValue, value(for: volume))
                )
                .foregroundStyle(Theme.Colors.primary.gradient)
                .cornerRadius(4)
            }

            if let selectedMonth, let volume = nearestVolume(to: selectedMonth) {
                RuleMark(x: .value("Selected", monthLabel(for: volume.month)))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartYAxisLabel(yAxisLabel)
        .frame(height: 200)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let x = drag.location.x - geo[proxy.plotFrame!].origin.x
                                if let month: String = proxy.value(atX: x) {
                                    selectedMonth = monthDate(from: month)
                                }
                            }
                            .onEnded { _ in
                                selectedMonth = nil
                            }
                    )
            }
        }
        .chartBackground { proxy in
            GeometryReader { geo in
                if let selectedMonth, let volume = nearestVolume(to: selectedMonth) {
                    let plotFrame = geo[proxy.plotFrame!]
                    let label = monthLabel(for: volume.month)
                    if let xPos = proxy.position(forX: label) {
                        ChartAnnotationCard(
                            title: volume.month.formatted(.dateTime.month(.wide).year()),
                            value: formattedValue(for: volume),
                            subtitle: "\(volume.runCount) run\(volume.runCount == 1 ? "" : "s")"
                        )
                        .offset(
                            x: annotationX(xPos: xPos, plotWidth: plotFrame.width),
                            y: -8
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var displayVolumes: [MonthlyVolumeCalculator.MonthlyVolume] {
        Array(monthlyVolumes.suffix(12))
    }

    private func value(for volume: MonthlyVolumeCalculator.MonthlyVolume) -> Double {
        switch metric {
        case .distance:
            return volume.distanceKm
        case .elevation:
            return volume.elevationGainM
        case .duration:
            return volume.duration / 3600
        }
    }

    private func formattedValue(
        for volume: MonthlyVolumeCalculator.MonthlyVolume
    ) -> String {
        switch metric {
        case .distance:
            return String(format: "%.1f km", volume.distanceKm)
        case .elevation:
            return String(format: "%.0f m D+", volume.elevationGainM)
        case .duration:
            let hours = Int(volume.duration) / 3600
            let minutes = (Int(volume.duration) % 3600) / 60
            if hours > 0 {
                return "\(hours)h \(String(format: "%02d", minutes))m"
            }
            return "\(minutes)m"
        }
    }

    private var yAxisLabel: String {
        switch metric {
        case .distance:
            return "km"
        case .elevation:
            return "m D+"
        case .duration:
            return "hours"
        }
    }

    private func monthLabel(for date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated))
    }

    private func monthDate(from label: String) -> Date? {
        displayVolumes.first { monthLabel(for: $0.month) == label }?.month
    }

    private func nearestVolume(
        to date: Date
    ) -> MonthlyVolumeCalculator.MonthlyVolume? {
        displayVolumes.min {
            abs($0.month.timeIntervalSince(date)) < abs($1.month.timeIntervalSince(date))
        }
    }

    private func annotationX(xPos: CGFloat, plotWidth: CGFloat) -> CGFloat {
        let cardWidth: CGFloat = 130
        return min(max(xPos, cardWidth / 2), plotWidth - cardWidth / 2)
    }

    private var accessibilitySummary: String {
        let total = monthlyVolumes.reduce(0.0) { $0 + $1.distanceKm }
        return "Monthly volume chart showing \(monthlyVolumes.count) months. Total distance \(String(format: "%.0f", total)) km."
    }
}
