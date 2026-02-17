import SwiftUI

struct CheckpointAnnotationView: View {
    let name: String
    let distanceKm: Double
    let hasAidStation: Bool

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: hasAidStation ? "cross.circle.fill" : "mappin.circle.fill")
                .font(.caption)
                .foregroundStyle(hasAidStation ? Theme.Colors.danger : Theme.Colors.primary)
                .background(Circle().fill(.white).padding(-1))

            Text(name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(1)

            Text(String(format: "%.1f km", distanceKm))
                .font(.system(size: 8))
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(2)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
