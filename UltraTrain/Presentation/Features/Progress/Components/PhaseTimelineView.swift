import SwiftUI
import Charts

struct PhaseTimelineView: View {
    let blocks: [PhaseBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Training Phases")
                    .font(.headline)
                Spacer()
                if let current = blocks.first(where: \.isCurrentPhase) {
                    Text(current.phase.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(phaseColor(current.phase))
                        .clipShape(Capsule())
                }
            }

            chart
            legend
        }
        .chartAccessibility(summary: accessibilityDescription)
    }

    // MARK: - Chart

    private var chart: some View {
        Chart(blocks) { block in
            BarMark(
                xStart: .value("Start", block.startDate),
                xEnd: .value("End", block.endDate),
                y: .value("Phase", "Plan")
            )
            .foregroundStyle(phaseColor(block.phase))
            .cornerRadius(4)
            .opacity(block.isCurrentPhase ? 1.0 : 0.7)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 40)
    }

    // MARK: - Legend

    private var legend: some View {
        let uniquePhases = blocks.map(\.phase).uniqued()
        return HStack(spacing: Theme.Spacing.md) {
            ForEach(uniquePhases, id: \.self) { phase in
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(phaseColor(phase))
                        .frame(width: 8, height: 8)
                    Text(phase.displayName)
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
    }

    private var accessibilityDescription: String {
        let phases = blocks.map { "\($0.phase.displayName) (weeks \($0.weekNumbers.map(String.init).joined(separator: ",")))" }
        let current = blocks.first(where: \.isCurrentPhase)?.phase.displayName ?? "none"
        return "Training phases: \(phases.joined(separator: ", ")). Current phase: \(current)."
    }

    // MARK: - Colors

    private func phaseColor(_ phase: TrainingPhase) -> Color {
        phase.color
    }
}

// MARK: - Extensions

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
