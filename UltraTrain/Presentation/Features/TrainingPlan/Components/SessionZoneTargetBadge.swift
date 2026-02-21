import SwiftUI

struct SessionZoneTargetBadge: View {
    let zone: Int

    var body: some View {
        Text("Z\(zone)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(zoneColor)
            .clipShape(Capsule())
            .accessibilityLabel("Target heart rate zone \(zone)")
    }

    private var zoneColor: Color {
        switch zone {
        case 1: .blue
        case 2: .green
        case 3: .yellow
        case 4: .orange
        case 5: .red
        default: .gray
        }
    }
}
