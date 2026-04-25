import SwiftUI

enum Theme {
    enum Colors {
        static let primary = Color("AccentColor")
        static let accentColor = Color.accentColor
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let label = Color(.label)
        static let secondaryLabel = Color(.secondaryLabel)
        static let tertiaryLabel = Color(.tertiaryLabel)
        static let success = Color.green
        static let warning = Color.orange
        static let danger = Color.red
        static let info = Color.cyan

        static let zone1 = Color.gray
        static let zone2 = Color.blue
        static let zone3 = Color.green
        static let zone4 = Color.orange
        static let zone5 = Color.red

        /// Adaptive shadow — dark in light mode, light glow in dark mode.
        static let shadow = Color(.label).opacity(0.15)

        /// Adaptive map annotation background — contrasts with map in both modes.
        static let mapAnnotationBackground = Color(.systemBackground)

        // MARK: - Premium Palette (Paywall & Onboarding)

        static let premiumBgTop = Color(red: 0.051, green: 0.043, blue: 0.180)
        static let premiumBgMid = Color(red: 0.102, green: 0.067, blue: 0.271)
        static let premiumBgBottom = Color(red: 0.039, green: 0.086, blue: 0.157)
        static let warmCoral = Color(red: 1.0, green: 0.42, blue: 0.42)
        static let warmCoralDeep = Color(red: 0.933, green: 0.314, blue: 0.314)
        static let goldAccent = Color(red: 1.0, green: 0.784, blue: 0.235)
        static let goldAccentDeep = Color(red: 0.961, green: 0.651, blue: 0.137)
        static let amberAccent = Color(red: 1.0, green: 0.690, blue: 0.231)

        // MARK: - Feature-specific

        static let heatmapHigh = Color(red: 0.85, green: 0.1, blue: 0.1)
        static let shareCardAccent = Color(red: 0.3, green: 0.75, blue: 0.55)
        static let shareCardBackgroundTop = Color(red: 0.08, green: 0.08, blue: 0.14)
        static let shareCardBackgroundMid = Color(red: 0.04, green: 0.12, blue: 0.18)
        static let shareCardBackgroundBottom = Color(red: 0.06, green: 0.06, blue: 0.12)

        // MARK: - Hero / Onboarding

        /// Top color for the hero gradient (dark: deep indigo, light: warm sky blue)
        static let heroGradientTop = Color("HeroGradientTop")
        /// Bottom color for the hero gradient (dark: teal-black, light: light peach)
        static let heroGradientBottom = Color("HeroGradientBottom")

        // MARK: - Futuristic UI

        static let futuristicBgDark = Color(red: 0.03, green: 0.03, blue: 0.06)
        static let futuristicBgMid = Color(red: 0.05, green: 0.05, blue: 0.10)
        static let futuristicBgLight = Color(red: 0.97, green: 0.96, blue: 0.95)
        static let neonAccent = Color.cyan.opacity(0.15)
        static let glassBorder = Color.white.opacity(0.12)
        static let glassBorderLight = Color.black.opacity(0.06)
    }

    enum Gradients {
        static let premiumBackground = LinearGradient(
            colors: [Theme.Colors.premiumBgTop, Theme.Colors.premiumBgMid, Theme.Colors.premiumBgBottom],
            startPoint: .top,
            endPoint: .bottom
        )

        static let warmCoralCTA = LinearGradient(
            colors: [Theme.Colors.warmCoral, Theme.Colors.warmCoralDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let goldPremium = LinearGradient(
            colors: [Theme.Colors.goldAccent, Theme.Colors.goldAccentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static func futuristicBackground(colorScheme: ColorScheme) -> LinearGradient {
            if colorScheme == .dark {
                return LinearGradient(
                    colors: [
                        Theme.Colors.futuristicBgDark,
                        Theme.Colors.futuristicBgMid,
                        Theme.Colors.futuristicBgDark
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            return LinearGradient(
                colors: [
                    Theme.Colors.futuristicBgLight,
                    Color(red: 0.95, green: 0.94, blue: 0.92),
                    Theme.Colors.futuristicBgLight
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static func glowBorder(color: Color) -> LinearGradient {
            LinearGradient(
                colors: [color.opacity(0.4), color.opacity(0.1), color.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func phaseGradient(_ phase: TrainingPhase) -> LinearGradient {
            let colors: [Color]
            switch phase {
            case .base: colors = [.blue, .cyan]
            case .build: colors = [.orange, .red]
            case .peak: colors = [.red, .purple]
            case .taper: colors = [.green, .mint]
            case .recovery: colors = [.mint, .teal]
            case .race: colors = [.purple, .pink]
            }
            return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    enum LetterSpacing {
        static let tracked: CGFloat = 1.5
        static let tight: CGFloat = 0.8
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    enum CornerRadius {
        /// Chart-bar / micro-element radius. Anything smaller than `sm`
        /// previously scattered as raw `cornerRadius(3)` / `cornerRadius(4)`
        /// literals across chart components.
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
}
