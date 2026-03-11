import SwiftUI

struct PaywallFeatureBullets: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            featureRow("paywall.feature.plans")
            featureRow("paywall.feature.sync")
            featureRow("paywall.feature.coaching")
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
    }

    private func featureRow(_ key: LocalizedStringKey) -> some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Colors.goldAccent)
                .font(.body)
                .accessibilityHidden(true)
            Text(key)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }
}
