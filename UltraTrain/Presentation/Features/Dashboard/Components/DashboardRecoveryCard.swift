import SwiftUI

struct DashboardRecoveryCard: View {
    let recoveryScore: RecoveryScore?
    var readinessScore: ReadinessScore?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Recovery", systemImage: "moon.zzz.fill")
                .font(.headline)

            if let score = recoveryScore {
                scoreContent(score)
            } else {
                Text("Enable HealthKit to see your recovery score")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle()
        .accessibilityHint("Opens morning readiness check")
    }

    @ViewBuilder
    private func scoreContent(_ score: RecoveryScore) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            RecoveryScoreGauge(score: score.overallScore, status: score.status)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(score.status.rawValue.capitalized)
                    .font(.subheadline.bold())

                Text(score.recommendation)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .lineLimit(2)

                if let readiness = readinessScore {
                    ReadinessBadge(score: readiness.overallScore, status: readiness.status)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
        }
    }
}
