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
}

struct AppCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(colorScheme == .dark
                          ? Color(.secondarySystemBackground)
                          : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.06)
                            : Color.black.opacity(0.04),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.white.opacity(0.02)
                    : .black.opacity(0.06),
                radius: colorScheme == .dark ? 6 : 12,
                y: colorScheme == .dark ? 2 : 4
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
