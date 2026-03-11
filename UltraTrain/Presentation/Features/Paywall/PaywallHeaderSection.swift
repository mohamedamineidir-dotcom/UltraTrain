import SwiftUI

struct PaywallHeaderSection: View {
    let firstName: String

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.Gradients.goldPremium)
                Image(systemName: "figure.run")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(y: -6)
            }
            .shadow(color: Theme.Colors.goldAccent.opacity(0.5), radius: 16, y: 4)
            .shadow(color: Theme.Colors.goldAccent.opacity(0.3), radius: 32, y: 8)
            .padding(.top, Theme.Spacing.xl)
            .accessibilityHidden(true)

            Text("paywall.title")
                .font(.title.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("paywall.subtitle \(firstName)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
        }
    }
}
