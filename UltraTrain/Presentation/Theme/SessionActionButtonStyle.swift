import SwiftUI

/// Capsule action button used for session-level actions (Validate /
/// Skip / Reschedule / Swap / Move Rest Day). Comes in two variants:
///
/// - `.primary` is a filled tint-coloured capsule with a vertical
///   gradient, a top sheen, an inner highlight border, and a soft
///   outer glow. Used for the lead CTA on the screen.
/// - `.secondary` is a glass capsule that picks up the surrounding
///   dark background; the tint colour shows through the border, icon
///   and label, and a subtle inner sheen catches light.
///
/// Both shrink on press so the haptic feel matches the visual.
struct SessionActionButtonStyle: ButtonStyle {
    enum Variant { case primary, secondary }

    let tint: Color
    let variant: Variant

    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        switch variant {
        case .primary:
            primaryBody(configuration: configuration)
        case .secondary:
            secondaryBody(configuration: configuration)
        }
    }

    private func primaryBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [tint, tint.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: tint.opacity(0.35), radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private func secondaryBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                ZStack {
                    Capsule()
                        .fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.04)
                                : Color.black.opacity(0.025)
                        )
                    Capsule()
                        .fill(tint.opacity(0.10))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.06), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [tint.opacity(0.55), tint.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: tint.opacity(0.18), radius: 8, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SessionActionButtonStyle {
    static func sessionPrimary(tint: Color) -> SessionActionButtonStyle {
        SessionActionButtonStyle(tint: tint, variant: .primary)
    }

    static func sessionSecondary(tint: Color) -> SessionActionButtonStyle {
        SessionActionButtonStyle(tint: tint, variant: .secondary)
    }
}
