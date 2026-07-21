import SwiftUI

struct PaywallHeaderSection: View {
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ZStack {
                // A soft radial halo behind the glyph so the eye lands here first.
                // Dark mode keeps the on-brand coral; light mode swaps to a warm
                // gold (the coral reads harsh on the pale backdrop).
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isDark
                                ? [Theme.Colors.warmCoral.opacity(0.28),
                                   Theme.Colors.warmCoral.opacity(0.05),
                                   .clear]
                                : [Theme.Colors.goldAccent.opacity(0.30),
                                   Theme.Colors.goldAccent.opacity(0.06),
                                   .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 74
                        )
                    )
                    .frame(width: 150, height: 150)
                    .blur(radius: 5)

                // Light mode recolors the glyph to the same coral as the
                // CTA button — it reads as more on-brand for this screen
                // than the asset's own navy variant. Dark mode keeps the
                // asset's native white rendering untouched.
                Image("LaunchIcon")
                    .renderingMode(isDark ? .original : .template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .foregroundStyle(Theme.Colors.warmCoral)
                    .shadow(
                        color: isDark
                            ? Theme.Colors.warmCoral.opacity(0.55)
                            : Theme.Colors.goldAccentDeep.opacity(0.35),
                        radius: 16, y: 5
                    )
                    .accessibilityHidden(true)
            }

            VStack(spacing: 6) {
                Text("paywall.title")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(titleGradient)
                    .multilineTextAlignment(.center)

                Text("paywall.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }

    // White on dark, deep navy on light — always legible against the backdrop.
    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: isDark
                ? [.white, .white.opacity(0.7)]
                : [Theme.Colors.premiumBgTop, Theme.Colors.premiumBgMid],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
