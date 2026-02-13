import SwiftUI

struct ActiveRunStatsBar: View {
    let distance: String
    let pace: String
    let elevation: String
    let heartRate: Int?

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
            StatTile(label: "Distance", value: distance, unit: "km")
            StatTile(label: "Pace", value: pace, unit: "/km")
            StatTile(label: "Elevation", value: elevation, unit: "")
            StatTile(
                label: "Heart Rate",
                value: heartRate.map { "\($0)" } ?? "--",
                unit: "bpm"
            )
        }
    }

    private var columns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }
}

private struct StatTile: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold().monospacedDigit())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }
}
