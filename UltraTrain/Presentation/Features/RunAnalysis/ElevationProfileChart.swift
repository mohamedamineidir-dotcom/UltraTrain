import SwiftUI
import Charts

struct ElevationProfileChart: View {
    let dataPoints: [ElevationProfilePoint]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Elevation Profile")
                .font(.headline)

            Chart(dataPoints) { point in
                AreaMark(
                    x: .value("Distance", point.distanceKm),
                    y: .value("Altitude", point.altitudeM)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            Theme.Colors.success.opacity(0.3),
                            Theme.Colors.success.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Distance", point.distanceKm),
                    y: .value("Altitude", point.altitudeM)
                )
                .foregroundStyle(Theme.Colors.success)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartXAxisLabel("Distance (km)")
            .chartYAxisLabel("Altitude (m)")
            .frame(height: 200)
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartSummary)
    }

    private var chartSummary: String {
        guard !dataPoints.isEmpty else { return "Elevation profile chart, no data" }
        let minAlt = dataPoints.map(\.altitudeM).min() ?? 0
        let maxAlt = dataPoints.map(\.altitudeM).max() ?? 0
        let totalDist = dataPoints.last?.distanceKm ?? 0
        return "Elevation profile chart. \(String(format: "%.1f", totalDist)) km. Altitude range \(Int(minAlt)) to \(Int(maxAlt)) meters."
    }
}
