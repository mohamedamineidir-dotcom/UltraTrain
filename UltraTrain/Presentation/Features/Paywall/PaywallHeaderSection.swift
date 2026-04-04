import SwiftUI

struct PaywallHeaderSection: View {
    let firstName: String

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack(alignment: .bottom) {
                // Mountains behind
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.Gradients.goldPremium)
                    .opacity(0.5)
                    .offset(y: 10)

                // App logo in front
                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .offset(y: -4)
            }
            .frame(height: 80)
            .shadow(color: Theme.Colors.goldAccent.opacity(0.4), radius: 16, y: 4)
            .padding(.top, Theme.Spacing.xl)
            .accessibilityHidden(true)

            Text("paywall.title")
                .font(.title.bold())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text("paywall.subtitle \(firstName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
        }
    }
}
