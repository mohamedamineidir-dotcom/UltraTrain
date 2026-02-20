import SwiftUI

struct RunHistoryFilterBadge: View {
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
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Theme.Colors.primary)
                        .clipShape(Circle())
                        .offset(x: 6, y: -6)
                }
            }
        }
    }
}
