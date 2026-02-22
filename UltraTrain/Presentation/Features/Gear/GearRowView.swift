import SwiftUI

struct GearRowView: View {
    @Environment(\.unitPreference) private var units
    let item: GearItem

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(item.name)
                        .font(.subheadline.bold())
                    if item.needsReplacement {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                Text(item.brand)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)

                ProgressView(value: item.usagePercentage)
                    .tint(progressColor)

                Text("\(UnitFormatter.formatDistance(item.totalDistanceKm, unit: units, decimals: 0)) / \(UnitFormatter.formatDistance(item.maxDistanceKm, unit: units, decimals: 0))")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityIdentifier("gear.row.\(item.name)")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let used = UnitFormatter.formatDistance(item.totalDistanceKm, unit: units, decimals: 0)
        let max = UnitFormatter.formatDistance(item.maxDistanceKm, unit: units, decimals: 0)
        let percent = Int(item.usagePercentage * 100)
        var label = "\(item.name) by \(item.brand). \(used) of \(max). \(percent) percent worn"
        if item.needsReplacement {
            label += ". Needs replacement"
        }
        if item.isRetired {
            label += ". Retired"
        }
        return label
    }

    private var iconName: String {
        switch item.type {
        case .trailShoes, .roadShoes: "shoe.fill"
        case .poles: "figure.hiking"
        case .vest: "tshirt.fill"
        case .headlamp: "flashlight.on.fill"
        case .other: "bag.fill"
        }
    }

    private var iconColor: Color {
        item.isRetired ? .gray : Theme.Colors.primary
    }

    private var progressColor: Color {
        if item.usagePercentage >= 1.0 { return .red }
        if item.usagePercentage >= 0.8 { return .orange }
        return .green
    }
}
