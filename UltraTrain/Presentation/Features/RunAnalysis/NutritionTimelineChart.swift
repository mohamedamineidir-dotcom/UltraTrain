import SwiftUI
import Charts

struct NutritionTimelineChart: View {
    let analysis: NutritionAnalysis
    let splits: [Split]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Nutrition Timeline")
                .font(.headline)

            Chart {
                ForEach(Array(splits.enumerated()), id: \.offset) { index, split in
                    let cumulativeTime = splits.prefix(index).reduce(0.0) { $0 + $1.duration }
                    LineMark(
                        x: .value("Time", cumulativeTime / 60),
                        y: .value("Pace", split.duration / 60)
                    )
                    .foregroundStyle(Theme.Colors.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                ForEach(analysis.timelineEvents) { event in
                    RuleMark(x: .value("Intake", event.elapsedTimeSeconds / 60))
                        .foregroundStyle(colorForType(event.type).opacity(event.status == .taken ? 0.8 : 0.3))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: event.status == .skipped ? [4, 4] : []))
                        .annotation(position: .top, spacing: 4) {
                            Image(systemName: iconForEvent(event))
                                .font(.caption2)
                                .foregroundStyle(colorForType(event.type))
                        }
                }
            }
            .chartXAxisLabel("Time (min)")
            .chartYAxisLabel("Pace (min/km)")
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 200)

            legendRow
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            legendItem(color: .blue, label: "Hydration")
            legendItem(color: .orange, label: "Fuel")
            legendItem(color: .green, label: "Electrolyte")
        }
        .font(.caption2)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Helpers

    private func colorForType(_ type: NutritionReminderType) -> Color {
        switch type {
        case .hydration: return .blue
        case .fuel: return .orange
        case .electrolyte: return .green
        }
    }

    private func iconForEvent(_ event: NutritionTimelineEvent) -> String {
        if event.status == .skipped { return "xmark.circle.fill" }
        switch event.type {
        case .hydration: return "drop.fill"
        case .fuel: return "bolt.fill"
        case .electrolyte: return "sparkle"
        }
    }
}
