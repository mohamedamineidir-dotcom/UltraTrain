import SwiftUI

struct ChallengeProgressRow: View {
    let progress: ChallengeProgressCalculator.ChallengeProgress

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: progress.definition.iconName)
                .font(.title3)
                .foregroundStyle(Theme.Colors.primary)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(progress.definition.name)
                    .font(.subheadline.bold())

                ProgressView(value: progress.progressFraction)
                    .tint(Theme.Colors.primary)
                    .accessibilityLabel("Progress: \(AccessibilityFormatters.percentage(progress.progressFraction * 100))")

                Text("\(formatted(progress.currentValue)) / \(formatted(progress.targetValue)) \(progress.definition.unitLabel)")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private func formatted(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
