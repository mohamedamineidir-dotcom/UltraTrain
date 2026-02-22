import SwiftUI

struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let unlockedDate: Date?

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(
                        isUnlocked ? categoryColor : Color.gray.opacity(0.3),
                        lineWidth: 3
                    )
                    .frame(width: 56, height: 56)

                Circle()
                    .fill(
                        isUnlocked
                            ? categoryColor.opacity(0.15)
                            : Color.gray.opacity(0.08)
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: isUnlocked ? achievement.iconName : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(isUnlocked ? categoryColor : .gray.opacity(0.4))
            }

            Text(achievement.name)
                .font(.caption2.bold())
                .foregroundStyle(isUnlocked ? Theme.Colors.label : Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if let date = unlockedDate {
                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(width: 80)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .distance: Theme.Colors.primary
        case .elevation: Theme.Colors.success
        case .consistency: .orange
        case .speed: .purple
        case .race: Theme.Colors.warning
        case .milestone: .yellow
        }
    }

    private var accessibilityText: String {
        if isUnlocked {
            return "\(achievement.name), unlocked. \(achievement.descriptionText)"
        }
        return "\(achievement.name), locked. \(achievement.descriptionText)"
    }
}
