import SwiftUI

struct SplitMarkerBadge: View {
    let km: Int
    let paceSecondsPerKm: Double?
    var averagePace: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Text("\(km)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)

            if let pace = paceSecondsPerKm {
                Text(RunStatisticsCalculator.formatPace(pace))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(badgeColor)
                .shadow(radius: 1)
        )
    }

    private var badgeColor: Color {
        guard let pace = paceSecondsPerKm, averagePace > 0 else {
            return Theme.Colors.primary
        }
        let ratio = pace / averagePace
        if ratio < 0.95 { return Theme.Colors.success }
        if ratio <= 1.05 { return Theme.Colors.primary }
        return Theme.Colors.danger
    }
}
