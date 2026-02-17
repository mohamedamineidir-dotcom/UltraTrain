import SwiftUI

struct MapRecenterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12, weight: .medium))
                Text("Re-center")
                    .font(.caption2.bold())
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs + 2)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
}
