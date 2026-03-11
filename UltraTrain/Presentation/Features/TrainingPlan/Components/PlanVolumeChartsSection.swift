import SwiftUI
import Charts

enum VolumeChartMetric: String, CaseIterable {
    case distance = "Distance"
    case duration = "Duration"
    case elevation = "Elevation"
}

struct PlanVolumeChartsSection: View {
    @Environment(\.unitPreference) private var units
    let plan: TrainingPlan
    @State private var selectedMetric: VolumeChartMetric = .distance
    @State private var selectedWeek: WeekChartDataPoint?

    private var dataPoints: [WeekChartDataPoint] {
        PlanVolumeChartData.extract(from: plan.weeks)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            headerRow
            metricPicker
            summaryStats

            if dataPoints.isEmpty {
                Text("No plan data")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                chartView
            }
        }
        .appCardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Training volume chart")
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("Training Volume")
                .font(.headline)
            Spacer()
            if let peak = peakWeekValue {
                Text("Peak: \(peak)")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    // MARK: - Metric Picker

    private var metricPicker: some View {
        Picker("Metric", selection: $selectedMetric) {
            ForEach(VolumeChartMetric.allCases, id: \.self) { metric in
                Text(metric.rawValue).tag(metric)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary Stats

    private var summaryStats: some View {
        HStack(spacing: 0) {
            summaryStatItem(
                value: totalFormattedValue,
                label: "Total"
            )
            Spacer()
            summaryStatItem(
                value: avgFormattedValue,
                label: "Avg / week"
            )
            Spacer()
            summaryStatItem(
                value: "\(completedWeeks)/\(dataPoints.count)",
                label: "Weeks done"
            )
        }
    }

    private func summaryStatItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            ForEach(dataPoints) { point in
                // Rich area gradient fill
                AreaMark(
                    x: .value("Week", "W\(point.weekNumber)"),
                    y: .value("Planned", plannedValue(for: point))
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            Theme.Colors.accentColor.opacity(0.35),
                            Theme.Colors.accentColor.opacity(0.12),
                            Theme.Colors.accentColor.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                // Glow line — 3pt with shadow
                LineMark(
                    x: .value("Week", "W\(point.weekNumber)"),
                    y: .value("Planned", plannedValue(for: point))
                )
                .foregroundStyle(Theme.Colors.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)

                // Point markers at each week
                PointMark(
                    x: .value("Week", "W\(point.weekNumber)"),
                    y: .value("Planned", plannedValue(for: point))
                )
                .symbolSize(point.isCurrentWeek ? 50 : 30)
                .foregroundStyle(Theme.Colors.accentColor)

                // Completed bars — gradient capsule
                if completedValue(for: point) > 0 {
                    BarMark(
                        x: .value("Week", "W\(point.weekNumber)"),
                        y: .value("Completed", completedValue(for: point)),
                        width: .fixed(10)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [phaseColor(point.phase), phaseColor(point.phase).opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Capsule())
                }
            }

            // Current week — filled accent pill
            if let currentWeek = dataPoints.first(where: \.isCurrentWeek) {
                RuleMark(x: .value("Current", "W\(currentWeek.weekNumber)"))
                    .foregroundStyle(Theme.Colors.accentColor.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, spacing: 4) {
                        Text("NOW")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Theme.Colors.accentColor)
                                    .shadow(color: Theme.Colors.accentColor.opacity(0.4), radius: 4, y: 2)
                            )
                    }
            }

            // Selected week line
            if let selected = selectedWeek {
                RuleMark(x: .value("Selected", "W\(selected.weekNumber)"))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.7))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel()
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
            }
        }
        .chartPlotStyle { plot in
            plot
                .frame(height: 200)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Theme.Colors.secondaryLabel.opacity(0.03))
                )
        }
        .shadow(color: Theme.Colors.accentColor.opacity(0.15), radius: 8)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let x = drag.location.x - geo[proxy.plotFrame!].origin.x
                                if let weekLabel: String = proxy.value(atX: x) {
                                    let weekNum = Int(weekLabel.dropFirst()) ?? 0
                                    selectedWeek = dataPoints.first { $0.weekNumber == weekNum }
                                }
                            }
                            .onEnded { _ in
                                selectedWeek = nil
                            }
                    )
            }
        }
        .chartBackground { proxy in
            GeometryReader { geo in
                if let selected = selectedWeek {
                    let plotFrame = geo[proxy.plotFrame!]
                    if let xPos = proxy.position(forX: "W\(selected.weekNumber)") {
                        annotationCard(for: selected)
                            .offset(
                                x: min(max(xPos - 60, 0), plotFrame.width - 120),
                                y: -8
                            )
                    }
                }
            }
        }
    }

    // MARK: - Annotation

    private func annotationCard(for point: WeekChartDataPoint) -> some View {
        HStack(spacing: 0) {
            // Phase-colored left strip
            RoundedRectangle(cornerRadius: 2)
                .fill(phaseColor(point.phase))
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 3) {
                Text("Week \(point.weekNumber)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Plan")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text(formattedPlannedValue(for: point))
                            .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                    }
                    if completedValue(for: point) > 0 {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Done")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                            Text(formattedCompletedValue(for: point))
                                .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(phaseColor(point.phase))
                        }
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.06))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: phaseColor(point.phase).opacity(0.15), radius: 8, y: 4)
    }

    // MARK: - Summary Calculations

    private var totalFormattedValue: String {
        switch selectedMetric {
        case .distance:
            let total = dataPoints.reduce(0) { $0 + $1.plannedDistanceKm }
            return UnitFormatter.formatDistance(total, unit: units, decimals: 0)
        case .duration:
            let totalSec = dataPoints.reduce(0) { $0 + $1.plannedDurationSeconds }
            let hours = Int(totalSec / 3600)
            return "\(hours)h"
        case .elevation:
            let total = dataPoints.reduce(0) { $0 + $1.plannedElevationM }
            return UnitFormatter.formatElevation(total, unit: units)
        }
    }

    private var avgFormattedValue: String {
        guard !dataPoints.isEmpty else { return "-" }
        let count = Double(dataPoints.count)
        switch selectedMetric {
        case .distance:
            let avg = dataPoints.reduce(0) { $0 + $1.plannedDistanceKm } / count
            return UnitFormatter.formatDistance(avg, unit: units)
        case .duration:
            let avgSec = dataPoints.reduce(0) { $0 + $1.plannedDurationSeconds } / count
            let hours = Int(avgSec / 3600)
            let mins = Int(avgSec.truncatingRemainder(dividingBy: 3600) / 60)
            return "\(hours)h\(String(format: "%02d", mins))"
        case .elevation:
            let avg = dataPoints.reduce(0) { $0 + $1.plannedElevationM } / count
            return UnitFormatter.formatElevation(avg, unit: units)
        }
    }

    private var completedWeeks: Int {
        dataPoints.filter { point in
            let active = plan.weeks.first { $0.weekNumber == point.weekNumber }?
                .sessions.filter { $0.type != .rest && !$0.isSkipped } ?? []
            return !active.isEmpty && active.allSatisfy(\.isCompleted)
        }.count
    }

    private var peakWeekValue: String? {
        guard let peak = dataPoints.max(by: { plannedValue(for: $0) < plannedValue(for: $1) }) else {
            return nil
        }
        return "W\(peak.weekNumber)"
    }

    // MARK: - Value Accessors

    private func plannedValue(for point: WeekChartDataPoint) -> Double {
        switch selectedMetric {
        case .distance:
            return UnitFormatter.distanceValue(point.plannedDistanceKm, unit: units)
        case .duration:
            return point.plannedDurationSeconds / 3600.0
        case .elevation:
            return UnitFormatter.elevationValue(point.plannedElevationM, unit: units)
        }
    }

    private func completedValue(for point: WeekChartDataPoint) -> Double {
        switch selectedMetric {
        case .distance:
            return UnitFormatter.distanceValue(point.completedDistanceKm, unit: units)
        case .duration:
            return point.completedDurationSeconds / 3600.0
        case .elevation:
            return UnitFormatter.elevationValue(point.completedElevationM, unit: units)
        }
    }

    private func formattedPlannedValue(for point: WeekChartDataPoint) -> String {
        switch selectedMetric {
        case .distance:
            return UnitFormatter.formatDistance(point.plannedDistanceKm, unit: units)
        case .duration:
            let hours = Int(point.plannedDurationSeconds / 3600)
            let mins = Int((point.plannedDurationSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h\(mins)m"
        case .elevation:
            return UnitFormatter.formatElevation(point.plannedElevationM, unit: units)
        }
    }

    private func formattedCompletedValue(for point: WeekChartDataPoint) -> String {
        switch selectedMetric {
        case .distance:
            return UnitFormatter.formatDistance(point.completedDistanceKm, unit: units)
        case .duration:
            let hours = Int(point.completedDurationSeconds / 3600)
            let mins = Int((point.completedDurationSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h\(mins)m"
        case .elevation:
            return UnitFormatter.formatElevation(point.completedElevationM, unit: units)
        }
    }

    private func phaseColor(_ phase: TrainingPhase) -> Color {
        switch phase {
        case .base: .blue
        case .build: .orange
        case .peak: .red
        case .taper: .green
        case .recovery: .mint
        case .race: .purple
        }
    }
}
