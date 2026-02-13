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
    }
}
