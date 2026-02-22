import SwiftUI

struct DashboardChallengeCard: View {
    let currentStreak: Int
    let nearestProgress: ChallengeProgressCalculator.ChallengeProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Challenges")
                    .font(.headline)
                Spacer()
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
            }

            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text("\(currentStreak)-day streak")
                    .font(.subheadline.bold())
            }
            .accessibilityElement(children: .combine)

            if let progress = nearestProgress {
                Text(progress.definition.name)
                    .font(.caption)

                ProgressView(value: progress.progressFraction)
                    .tint(Theme.Colors.primary)
                    .accessibilityLabel("\(progress.definition.name) progress: \(Int(progress.progressFraction * 100)) percent")
            } else if currentStreak == 0 {
                Text("Start a challenge to track your progress")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityHint("Opens challenges view")
    }
}
