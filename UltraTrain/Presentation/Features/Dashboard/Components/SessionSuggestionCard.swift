import SwiftUI

struct SessionSuggestionCard: View {
    let recommendation: SessionIntensityRecommendation

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's Suggestion")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(recommendation.displayText)
                    .font(.subheadline.bold())
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(iconColor.opacity(0.08))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's suggestion: \(recommendation.displayText)")
    }

    private var iconName: String {
        switch recommendation {
        case .highIntensity: "flame.fill"
        case .moderateEffort: "figure.run"
        case .easyOnly: "figure.walk"
        case .restDay: "bed.double.fill"
        case .activeRecovery: "figure.cooldown"
        }
    }

    private var iconColor: Color {
        switch recommendation {
        case .highIntensity: Theme.Colors.danger
        case .moderateEffort: Theme.Colors.primary
        case .easyOnly: Theme.Colors.success
        case .restDay: Theme.Colors.secondaryLabel
        case .activeRecovery: Theme.Colors.warning
        }
    }
}
