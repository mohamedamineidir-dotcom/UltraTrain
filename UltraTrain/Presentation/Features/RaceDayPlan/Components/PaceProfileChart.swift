import Charts
import SwiftUI

struct PaceProfileChart: View {
    @Environment(\.unitPreference) private var units
    let segments: [RaceDaySegment]
    let checkpoints: [Checkpoint]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Pace Profile")
                .font(.headline)

            Chart {
                ForEach(elevationData, id: \.distanceKm) { point in
                    AreaMark(
                        x: .value("Distance", point.distanceKm),
                        y: .value("Elevation", point.elevationM)
                    )
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.15))
                    .interpolationMethod(.catmullRom)
                }

                ForEach(paceData, id: \.distanceKm) { point in
                    LineMark(
                        x: .value("Distance", point.distanceKm),
                        y: .value("Pace", point.paceMinPerKm)
                    )
                    .foregroundStyle(point.zone.color)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Distance", point.distanceKm),
                        y: .value("Pace", point.paceMinPerKm)
                    )
                    .foregroundStyle(point.zone.color)
                    .symbolSize(20)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let pace = value.as(Double.self) {
                            Text(formatPaceMinutes(pace))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxisLabel("Distance (\(UnitFormatter.distanceLabel(units)))")
            .chartYAxisLabel("Pace (min/\(UnitFormatter.distanceLabel(units)))")
            .frame(height: 180)
            .chartAccessibility(summary: AccessibilityFormatters.chartSummary(
                title: "Pace profile",
                dataPoints: segments.count,
                trend: "showing target paces across race segments"
            ))
        }
        .cardStyle()
    }

    // MARK: - Data

    private struct ElevationPoint {
        let distanceKm: Double
        let elevationM: Double
    }

    private struct PacePoint {
        let distanceKm: Double
        let paceMinPerKm: Double
        let zone: RacePacingCalculator.PacingZone
    }

    private var elevationData: [ElevationPoint] {
        var points: [ElevationPoint] = [ElevationPoint(distanceKm: 0, elevationM: firstElevation)]
        let sorted = checkpoints.sorted { $0.distanceFromStartKm < $1.distanceFromStartKm }
        for cp in sorted {
            points.append(ElevationPoint(distanceKm: cp.distanceFromStartKm, elevationM: cp.elevationM))
        }
        return points
    }

    private var firstElevation: Double {
        let sorted = checkpoints.sorted { $0.distanceFromStartKm < $1.distanceFromStartKm }
        guard let first = sorted.first else { return 0 }
        return first.elevationM - (first.elevationM - first.elevationM)
    }

    private var paceData: [PacePoint] {
        segments.map { segment in
            PacePoint(
                distanceKm: segment.distanceFromStartKm,
                paceMinPerKm: segment.targetPaceSecondsPerKm / 60.0,
                zone: segment.pacingZone
            )
        }
    }

    // MARK: - Helpers

    private func formatPaceMinutes(_ minutes: Double) -> String {
        let mins = Int(minutes)
        let secs = Int((minutes - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
}
