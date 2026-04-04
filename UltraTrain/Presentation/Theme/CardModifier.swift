import SwiftUI

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    func appCardStyle() -> some View {
        modifier(AppCardModifier())
    }

    func glassCardStyle(isSelected: Bool = false) -> some View {
        modifier(GlassCardModifier(isSelected: isSelected))
    }

    func onboardingCardStyle() -> some View {
        modifier(OnboardingCardModifier())
    }

    func futuristicGlassStyle(phaseTint: Color? = nil) -> some View {
        modifier(FuturisticGlassCardModifier(phaseTint: phaseTint))
    }
}

struct AppCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(colorScheme == .dark
                          ? Color(red: 0.08, green: 0.08, blue: 0.12)
                          : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(sheenGradient)
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(edgeLightGradient, lineWidth: 0.5)
            )
    }

    private var sheenGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(0.06), location: 0.0),
                    .init(color: Color.white.opacity(0.01), location: 0.3),
                    .init(color: Color.clear, location: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            stops: [
                .init(color: Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.06), location: 0.0),
                .init(color: Color.clear, location: 0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var edgeLightGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color.black.opacity(0.03), Color.black.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct GlassCardModifier: ViewModifier {
    var isSelected: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(
                        isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
    }
}

struct FuturisticGlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var phaseTint: Color?

    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .fill(tintOverlay)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(sheenGradient)
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(edgeLightGradient, lineWidth: colorScheme == .dark ? 1 : 0.5)
            )
    }

    private var tintOverlay: Color {
        if let tint = phaseTint, colorScheme == .dark {
            return tint.opacity(0.10)
        }
        return colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.7)
    }

    private var sheenGradient: LinearGradient {
        let tint = phaseTint ?? Theme.Colors.accentColor
        if colorScheme == .dark {
            // Use the phase tint color in the sheen for more warmth/variety
            let sheenColor = phaseTint ?? Color.white
            return LinearGradient(
                stops: [
                    .init(color: sheenColor.opacity(0.12), location: 0.0),
                    .init(color: sheenColor.opacity(0.03), location: 0.25),
                    .init(color: Color.clear, location: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            stops: [
                .init(color: tint.opacity(0.06), location: 0.0),
                .init(color: Color.clear, location: 0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var edgeLightGradient: LinearGradient {
        if colorScheme == .dark {
            let edgeColor = phaseTint ?? Color.white
            return LinearGradient(
                colors: [edgeColor.opacity(0.25), Color.white.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color.black.opacity(0.03), Color.black.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct OnboardingCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.md)
            .background(
                Group {
                    if colorScheme == .dark {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                    .fill(Color.white.opacity(0.06))
                            )
                    } else {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(Color.white.opacity(0.85))
                            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06),
                        lineWidth: 1
                    )
            )
    }
}
