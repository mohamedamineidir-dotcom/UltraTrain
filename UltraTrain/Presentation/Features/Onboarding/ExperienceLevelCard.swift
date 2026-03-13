import SwiftUI

struct ExperienceLevelCard: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Theme.Colors.warmCoral : Theme.Colors.secondaryLabel)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(level.displayName)
                        .font(.headline)
                        .foregroundStyle(isSelected ? Theme.Colors.warmCoral : Theme.Colors.label)
                    Text(levelDescription)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.warmCoral)
                }
            }
            .padding(Theme.Spacing.md)
            .background(isSelected ? Theme.Colors.warmCoral.opacity(0.12) : Theme.Colors.secondaryBackground.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(isSelected ? Theme.Colors.warmCoral : Theme.Colors.secondaryLabel.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(level.rawValue.capitalized), \(levelDescription)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select \(level.rawValue) experience level")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("onboarding.experienceCard.\(level.rawValue)")
    }

    private var iconName: String {
        switch level {
        case .beginner: return "figure.walk"
        case .intermediate: return "figure.run"
        case .advanced: return "figure.run.circle"
        case .elite: return "figure.run.circle.fill"
        }
    }

    private var levelDescription: String {
        switch level {
        case .beginner: return String(localized: "experience.beginner.description", defaultValue: "New to running or less than 1 year of regular training")
        case .intermediate: return String(localized: "experience.intermediate.description", defaultValue: "1-3 years running, completed races up to marathon distance")
        case .advanced: return String(localized: "experience.advanced.description", defaultValue: "3+ years, completed ultras, consistent 50+ km weeks")
        case .elite: return String(localized: "experience.elite.description", defaultValue: "Competitive ultra runner, podium finishes, 80+ km weeks")
        }
    }
}
