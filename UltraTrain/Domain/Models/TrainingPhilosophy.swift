import Foundation

enum TrainingPhilosophy: String, CaseIterable, Sendable {
    case enjoyment
    case balanced
    case performance

    var displayName: String {
        switch self {
        case .enjoyment:    "Enjoy the Journey"
        case .balanced:     "Balanced"
        case .performance:  "Performance"
        }
    }

    var subtitle: String {
        switch self {
        case .enjoyment:    "Lower volume, more rest. Focus on finishing strong."
        case .balanced:     "Progressive training. Recommended for most runners."
        case .performance:  "Higher volume and intensity. Push your limits."
        }
    }

    var iconName: String {
        switch self {
        case .enjoyment:    "heart.fill"
        case .balanced:     "scalemass.fill"
        case .performance:  "flame.fill"
        }
    }
}
