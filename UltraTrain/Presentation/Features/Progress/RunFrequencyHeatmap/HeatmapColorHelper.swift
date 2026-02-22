import SwiftUI

enum HeatmapColorHelper {

    /// Returns a color for a normalized intensity value from 0.0 to 1.0.
    /// Gradient: transparent yellow -> yellow -> orange -> red -> deep red
    static func color(for intensity: Double) -> Color {
        let clamped = min(max(intensity, 0), 1)

        switch clamped {
        case ..<0.05:
            return Color.yellow.opacity(0.1)
        case ..<0.25:
            return Color.yellow.opacity(0.3 + clamped * 1.2)
        case ..<0.5:
            return Color.orange.opacity(0.5 + (clamped - 0.25) * 2)
        case ..<0.75:
            return Color.red.opacity(0.6 + (clamped - 0.5) * 1.2)
        default:
            return Color(red: 0.7, green: 0, blue: 0).opacity(0.8 + (clamped - 0.75) * 0.8)
        }
    }
}
