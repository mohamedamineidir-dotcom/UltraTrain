import SwiftUI

/// Shared colour identity for nutrition-domain surfaces (onboarding
/// sheet, race-week fuelling card, aid-station strategy card).
/// Deliberately kept distinct from the app's warm-coral brand accent
/// which sits on training surfaces — nutrition reads fresh / clean /
/// professional in green, training reads energetic in coral.
///
/// Palette is a clean mint-to-teal gradient. Values picked to pair
/// well with `.ultraThinMaterial` backgrounds and to survive light/
/// dark mode without re-tinting.
enum NutritionPalette {
    /// Primary tint for icons, borders, strokes, text accents.
    static let tint = Color(red: 0.18, green: 0.72, blue: 0.55)

    /// Deeper end-stop for gradient terminations.
    static let deep = Color(red: 0.12, green: 0.54, blue: 0.40)

    /// Top-leading → bottom-trailing diagonal. Use for hero icon
    /// circles, CTA buttons, and highlighted chip fills.
    static let gradient = LinearGradient(
        colors: [
            Color(red: 0.22, green: 0.78, blue: 0.60),
            Color(red: 0.14, green: 0.58, blue: 0.42)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
