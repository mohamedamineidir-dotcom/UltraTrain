import Charts
import SwiftUI

struct MiniFormSparkline: View {
    let snapshots: [FitnessSnapshot]

    var body: some View {
        Chart(snapshots, id: \.id) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Form", point.form)
            )
            .foregroundStyle(lineColor)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Date", point.date),
                y: .value("Form", point.form)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [lineColor.opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.3))
                .lineStyle(StrokeStyle(dash: [4, 4]))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: 60)
        .accessibilityLabel(chartAccessibilityLabel)
    }

    private var chartAccessibilityLabel: String {
        guard let last = snapshots.last, let first = snapshots.first else {
            return "Fitness form trend"
        }
        let days = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 0
        let trend = last.form > first.form ? "improving" : (last.form < first.form ? "declining" : "stable")
        return "Form trend: currently at \(Int(last.form)), \(trend) over \(days) days"
    }

    private var lineColor: Color {
        guard let last = snapshots.last else { return .green }
        if last.form > 10 { return .green }
        if last.form > -5 { return .orange }
        return .red
    }
}
