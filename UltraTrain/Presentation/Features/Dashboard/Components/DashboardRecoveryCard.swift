import SwiftUI

struct DashboardRecoveryCard: View {
    let recoveryScore: RecoveryScore?
    let sleepHistory: [SleepEntry]
    var readinessScore: ReadinessScore?
    var hrvTrend: HRVAnalyzer.HRVTrend?

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
        .cardStyle()
    }

    @ViewBuilder
    private func scoreContent(_ score: RecoveryScore) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            RecoveryScoreGauge(score: score.overallScore, status: score.status)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                componentRow(label: "Sleep", score: score.sleepQualityScore)
                componentRow(label: "Consistency", score: score.sleepConsistencyScore)
                componentRow(label: "Resting HR", score: score.restingHRScore)
                componentRow(label: "Load Balance", score: score.trainingLoadBalanceScore)
            }
        }

        Text(score.recommendation)
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)

        if let readiness = readinessScore {
            ReadinessBadge(score: readiness.overallScore, status: readiness.status)
            SessionSuggestionCard(recommendation: readiness.sessionRecommendation)
        }

        if let trend = hrvTrend {
            HRVIndicator(
                currentHRV: trend.currentHRV,
                trend: trend.trend,
                sevenDayAverage: trend.sevenDayAverage
            )
        }

        if sleepHistory.count >= 2 {
            SleepHistoryBars(entries: sleepHistory)
        }
    }

    private func componentRow(label: String, score: Int) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 72, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.secondaryLabel.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(componentColor(score))
                        .frame(width: geo.size.width * CGFloat(score) / 100)
                }
            }
            .frame(height: 6)

            Text("\(score)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 22, alignment: .trailing)
        }
    }

    private func componentColor(_ score: Int) -> Color {
        if score >= 70 { return Theme.Colors.success }
        if score >= 40 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }
}
