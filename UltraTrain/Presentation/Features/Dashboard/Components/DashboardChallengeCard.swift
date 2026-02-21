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
            }

            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(currentStreak)-day streak")
                    .font(.subheadline.bold())
            }

            if let progress = nearestProgress {
                Text(progress.definition.name)
                    .font(.caption)

                ProgressView(value: progress.progressFraction)
                    .tint(Theme.Colors.primary)
            } else if currentStreak == 0 {
                Text("Start a challenge to track your progress")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
