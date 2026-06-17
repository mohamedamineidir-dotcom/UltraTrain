import SwiftUI

struct PaywallHeaderSection: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
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
                            endRadius: 64
                        )
                    )
                    .frame(width: 128, height: 128)
                    .blur(radius: 5)

                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.55), radius: 18, y: 5)
                    .accessibilityHidden(true)
            }

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
