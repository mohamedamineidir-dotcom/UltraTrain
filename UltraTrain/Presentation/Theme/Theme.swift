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
    }

    enum Gradients {
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

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }
}
