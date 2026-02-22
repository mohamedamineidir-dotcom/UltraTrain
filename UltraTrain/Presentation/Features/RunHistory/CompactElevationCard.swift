import SwiftUI
import Charts

struct CompactElevationCard: View {
    @Environment(\.unitPreference) private var units
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
                        "+" + UnitFormatter.formatElevation(elevationGainM, unit: units),
                        systemImage: "arrow.up.right"
                    )
                    .foregroundStyle(Theme.Colors.danger)
                    Label(
                        "-" + UnitFormatter.formatElevation(elevationLossM, unit: units),
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Elevation chart. Gain: \(Int(elevationGainM)) meters. Loss: \(Int(elevationLossM)) meters")
    }
}
