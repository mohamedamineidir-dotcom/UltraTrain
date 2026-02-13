import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    var trend: TrendDirection?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                if let trend {
                    Image(systemName: trend.iconName)
                        .font(.caption)
                        .foregroundStyle(trend.color)
                }
            }
        }
        .cardStyle()
    }
}

enum TrendDirection {
    case up, down, stable

    var iconName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .up: return Theme.Colors.success
        case .down: return Theme.Colors.danger
        case .stable: return Theme.Colors.secondaryLabel
        }
    }
}
