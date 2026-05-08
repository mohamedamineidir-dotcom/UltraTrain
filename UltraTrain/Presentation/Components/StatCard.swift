import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    var trend: TrendDirection?
    /// Optional accent tint for the futuristic glass background.
    /// Matches whatever the surrounding context wants (intensity
    /// color on session detail, phase color on plan view, etc.).
    var tint: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.5)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .lineLimit(1)
                if let trend {
                    Image(systemName: trend.iconName)
                        .font(.caption)
                        .foregroundStyle(trend.color)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(StatCardBackground(tint: tint))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var desc = "\(title), \(value) \(unit)"
        if let trend {
            switch trend {
            case .up: desc += ", trending up"
            case .down: desc += ", trending down"
            case .stable: desc += ", stable"
            }
        }
        return desc
    }
}

/// Opt-in styling: callers that pass a `tint` get the futuristic
/// glass treatment (used in SessionDetailView). Callers that don't
/// (Progress / TrainingLoad views) keep the existing flat cardStyle
/// to preserve their layouts.
private struct StatCardBackground: ViewModifier {
    let tint: Color?
    func body(content: Content) -> some View {
        if let tint {
            content
                .padding(Theme.Spacing.md)
                .futuristicGlassStyle(phaseTint: tint)
        } else {
            content.cardStyle()
        }
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
