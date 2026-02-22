import SwiftUI
import Charts

struct RecoveryTrendChart: View {
    let snapshots: [RecoverySnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Recovery Trend")
                .font(.headline)
            Chart {
                ForEach(snapshots) { snapshot in
                    LineMark(
                        x: .value("Date", snapshot.date, unit: .day),
                        y: .value("Score", snapshot.recoveryScore.overallScore)
                    )
                    .foregroundStyle(Theme.Colors.primary)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", snapshot.date, unit: .day),
                        y: .value("Score", snapshot.recoveryScore.overallScore)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Theme.Colors.primary.opacity(0.2), Theme.Colors.primary.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxisLabel("Score")
            .frame(height: 180)
            .chartAccessibility(summary: AccessibilityFormatters.chartSummary(
                title: "Recovery trend",
                dataPoints: snapshots.count,
                trend: "showing recovery score over time"
            ))
        }
        .cardStyle()
    }
}
