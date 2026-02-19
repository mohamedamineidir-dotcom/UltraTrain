import SwiftUI

struct CheckpointAnnotationView: View {
    @Environment(\.unitPreference) private var units
    let name: String
    let distanceKm: Double
    let hasAidStation: Bool

    @ScaledMetric(relativeTo: .caption2) private var nameFontSize: CGFloat = 9
    @ScaledMetric(relativeTo: .caption2) private var distanceFontSize: CGFloat = 8

    private var clampedNameSize: CGFloat { min(nameFontSize, 14) }
    private var clampedDistanceSize: CGFloat { min(distanceFontSize, 12) }

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: hasAidStation ? "cross.circle.fill" : "mappin.circle.fill")
                .font(.caption)
                .foregroundStyle(hasAidStation ? Theme.Colors.danger : Theme.Colors.primary)
                .background(Circle().fill(.white).padding(-1))

            Text(name)
                .font(.system(size: clampedNameSize, weight: .semibold))
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(1)

            Text(UnitFormatter.formatDistance(distanceKm, unit: units))
                .font(.system(size: clampedDistanceSize))
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(2)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(UnitFormatter.formatDistance(distanceKm, unit: units))\(hasAidStation ? ", aid station" : "")")
    }
}
