import SwiftUI

struct PaywallHeaderSection: View {
    let firstName: String

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image("LaunchIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .shadow(color: Theme.Colors.goldAccent.opacity(0.5), radius: 20, y: 6)
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
