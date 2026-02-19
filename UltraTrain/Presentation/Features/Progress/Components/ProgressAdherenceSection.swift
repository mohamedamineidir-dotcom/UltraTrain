import SwiftUI

struct ProgressAdherenceSection: View {
    let adherencePercent: Double
    let completed: Int
    let total: Int
    let weeklyAdherence: [WeeklyAdherence]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Plan Adherence")
                .font(.headline)

            if total > 0 {
                HStack(spacing: Theme.Spacing.lg) {
                    ZStack {
                        Circle()
                            .stroke(Theme.Colors.secondaryLabel.opacity(0.2), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: adherencePercent / 100)
                            .stroke(adherenceColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.0f%%", adherencePercent))
                            .font(.title3.bold().monospacedDigit())
                    }
                    .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("\(completed) of \(total) sessions")
                            .font(.subheadline)
                        Text(adherenceMessage)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            } else {
                Text("Generate a training plan to track adherence")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            if weeklyAdherence.count >= 2 {
                AdherenceTrendChartView(weeklyAdherence: weeklyAdherence)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var adherenceColor: Color {
        if adherencePercent >= 80 { return Theme.Colors.success }
        if adherencePercent >= 50 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }

    private var adherenceMessage: String {
        if adherencePercent >= 80 { return "Great consistency! Keep it up." }
        if adherencePercent >= 50 { return "Good progress. Try to complete more sessions." }
        return "Falling behind. Focus on key sessions."
    }
}
