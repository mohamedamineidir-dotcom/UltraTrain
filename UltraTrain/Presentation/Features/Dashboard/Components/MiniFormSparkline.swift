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
        .accessibilityLabel("Fitness form trend sparkline")
    }

    private var lineColor: Color {
        guard let last = snapshots.last else { return .green }
        if last.form > 10 { return .green }
        if last.form > -5 { return .orange }
        return .red
    }
}
