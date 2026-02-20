import SwiftUI

struct PacingZoneIndicator: View {
    let zone: RacePacingCalculator.PacingZone

    var body: some View {
        Text(zone.label)
            .font(.caption2.bold())
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 2)
            .background(zone.color.opacity(0.15))
            .foregroundStyle(zone.color)
            .clipShape(Capsule())
    }
}
