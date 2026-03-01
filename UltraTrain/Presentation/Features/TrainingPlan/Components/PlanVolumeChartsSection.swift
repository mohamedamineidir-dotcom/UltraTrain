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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Training Volume")
                .font(.headline)

            Picker("Metric", selection: $selectedMetric) {
                ForEach(VolumeChartMetric.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            if dataPoints.isEmpty {
                Text("No plan data")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                chartView
            }
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Training volume chart")
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            ForEach(dataPoints) { point in
                AreaMark(
                    x: .value("Week", point.weekNumber),
                    y: .value("Planned", plannedValue(for: point))
                )
                .foregroundStyle(phaseColor(point.phase).opacity(0.15))
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Week", point.weekNumber),
                    y: .value("Planned", plannedValue(for: point))
                )
                .foregroundStyle(phaseColor(point.phase).opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                if completedValue(for: point) > 0 {
                    BarMark(
                        x: .value("Week", point.weekNumber),
                        y: .value("Completed", completedValue(for: point))
                    )
                    .foregroundStyle(phaseColor(point.phase).gradient)
                    .cornerRadius(3)
                }
            }

            if let currentWeek = dataPoints.first(where: \.isCurrentWeek) {
                RuleMark(x: .value("Current", currentWeek.weekNumber))
                    .foregroundStyle(Theme.Colors.accentColor.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .annotation(position: .top, spacing: 4) {
                        Text("Now")
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.accentColor)
                    }
            }

            if let selected = selectedWeek {
                RuleMark(x: .value("Selected", selected.weekNumber))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
            }
        }
        .chartXAxisLabel("Week")
        .chartYAxisLabel(yAxisLabel)
        .frame(height: 180)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let x = drag.location.x - geo[proxy.plotFrame!].origin.x
                                if let weekNum: Int = proxy.value(atX: x) {
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
                    if let xPos = proxy.position(forX: selected.weekNumber) {
                        annotationCard(for: selected)
                            .offset(
                                x: min(max(xPos, 70), plotFrame.width - 70),
                                y: -8
                            )
                    }
                }
            }
        }
    }

    // MARK: - Annotation

    private func annotationCard(for point: WeekChartDataPoint) -> some View {
        VStack(spacing: 2) {
            Text("Week \(point.weekNumber)")
                .font(.caption2.bold())
            Text(formattedPlannedValue(for: point))
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 6))
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

    private var yAxisLabel: String {
        switch selectedMetric {
        case .distance: UnitFormatter.distanceLabel(units)
        case .duration: "Hours"
        case .elevation: UnitFormatter.elevationLabel(units)
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
