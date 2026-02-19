import SwiftUI

enum GradientColorHelper {

    static func color(for category: GradientCategory) -> Color {
        switch category {
        case .steepDown: .blue
        case .moderateDown: .cyan
        case .flat: .green
        case .moderateUp: .orange
        case .steepUp: .red
        }
    }

    static func color(forGradient gradient: Double) -> Color {
        color(for: GradientCategory.from(gradient: gradient))
    }
}
