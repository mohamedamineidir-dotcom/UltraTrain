import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text("You're offline. Changes will sync when reconnected.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.secondaryBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offline. Changes will sync when reconnected.")
    }
}
