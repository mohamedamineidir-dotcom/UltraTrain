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
                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryLabel)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(level.rawValue.capitalized)
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.label)
                    Text(levelDescription)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.primary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(isSelected ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(isSelected ? Theme.Colors.primary : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
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
        case .beginner: return "New to running or less than 1 year of regular training"
        case .intermediate: return "1-3 years running, completed races up to marathon distance"
        case .advanced: return "3+ years, completed ultras, consistent 50+ km weeks"
        case .elite: return "Competitive ultra runner, podium finishes, 80+ km weeks"
        }
    }
}
