import SwiftUI

struct PaywallHeaderSection: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                // Soft coral radial behind the glyph so the eye lands here
                // first and the brand colour anchors the dark backdrop
                // instead of the gold drifting off-DNA.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.warmCoral.opacity(0.28),
                                Theme.Colors.warmCoral.opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)
                    .blur(radius: 6)

                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 104)
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.55), radius: 24, y: 8)
                    .accessibilityHidden(true)
            }
            .padding(.top, Theme.Spacing.xl)

            VStack(spacing: 6) {
                Text("paywall.title")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .multilineTextAlignment(.center)

                Text("paywall.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }
}
