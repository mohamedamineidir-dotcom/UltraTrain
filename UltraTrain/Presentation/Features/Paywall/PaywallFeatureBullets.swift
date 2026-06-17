import SwiftUI

struct PaywallFeatureBullets: View {
    private struct Feature {
        let icon: String
        let tint: Color
        let key: LocalizedStringKey
    }

    // Trimmed to the two strongest differentiators (personalized plans + the
    // nutrition / finish-prediction coaching layer) so the paywall fits one
    // screen. Apple Watch / Strava sync is table-stakes, kept off the paywall.
    private let features: [Feature] = [
        Feature(icon: "figure.run.circle.fill",
                tint: Theme.Colors.warmCoral,
                key: "paywall.feature.plans"),
        Feature(icon: "fork.knife.circle.fill",
                tint: Theme.Colors.goldAccent,
                key: "paywall.feature.coaching")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm + 2) {
            ForEach(features.indices, id: \.self) { i in
                row(features[i])
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
    }

    private func row(_ feature: Feature) -> some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm + 2) {
            Image(systemName: feature.icon)
                .font(.title3)
                .foregroundStyle(feature.tint)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            Text(feature.key)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .truncationMode(.tail)
        }
    }
}
