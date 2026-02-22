import SwiftUI

struct MapRecenterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .accessibilityHidden(true)
                Text("Re-center")
                    .font(.caption2.bold())
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(minHeight: 44)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .accessibilityLabel("Re-center map")
        .accessibilityHint("Centers the map on your current location")
    }
}
