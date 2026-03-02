import SwiftUI

struct RunHistoryFilterBadge: View {
    @ScaledMetric(relativeTo: .caption2) private var badgeSize: CGFloat = 10

    let activeCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: activeCount > 0
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle"
            )
            .overlay(alignment: .topTrailing) {
                if activeCount > 0 {
                    Text("\(activeCount)")
                        .font(.system(size: badgeSize, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Theme.Colors.primary)
                        .clipShape(Circle())
                        .offset(x: 6, y: -6)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityLabel("Filters")
        .accessibilityValue(activeCount > 0 ? "\(activeCount) active" : "None active")
        .accessibilityHint("Opens the filter options")
    }
}
