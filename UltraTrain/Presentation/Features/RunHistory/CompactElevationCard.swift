import SwiftUI
import Charts

struct CompactElevationCard: View {
    let profile: [ElevationProfilePoint]
    let elevationGainM: Double
    let elevationLossM: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Elevation")
                    .font(.headline)
                Spacer()
                HStack(spacing: Theme.Spacing.sm) {
                    Label(
                        String(format: "+%.0f m", elevationGainM),
                        systemImage: "arrow.up.right"
                    )
                    .foregroundStyle(Theme.Colors.danger)
                    Label(
                        String(format: "-%.0f m", elevationLossM),
                        systemImage: "arrow.down.right"
                    )
                    .foregroundStyle(Theme.Colors.success)
                }
                .font(.caption2)
            }

            Chart(profile) { point in
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
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 80)
        }
        .cardStyle()
    }
}
