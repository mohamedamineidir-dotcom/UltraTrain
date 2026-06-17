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
                            endRadius: 70
                        )
                    )
                    .frame(width: 130, height: 130)
                    .blur(radius: 4)

                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.55), radius: 16, y: 5)
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
