import SwiftUI

struct ReplayStatsBar: View {
    let pace: String
    let heartRate: String
    let elevation: String
    let distance: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ReplayStatItem(
                icon: "speedometer",
                value: pace,
                label: "/km"
            )

            ReplayStatItem(
                icon: "heart.fill",
                value: heartRate,
                label: "bpm",
                iconColor: Theme.Colors.danger
            )

            ReplayStatItem(
                icon: "mountain.2.fill",
                value: elevation,
                label: ""
            )

            ReplayStatItem(
                icon: "point.topleft.down.to.point.bottomright.curvepath",
                value: distance,
                label: "km"
            )
        }
    }
}

// MARK: - ReplayStatItem

private struct ReplayStatItem: View {
    let icon: String
    let value: String
    let label: String
    var iconColor: Color = Theme.Colors.primary

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)

            Text(value)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(Theme.Colors.label)

            if !label.isEmpty {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            label.isEmpty ? "\(value)" : "\(value) \(label)"
        )
    }
}
