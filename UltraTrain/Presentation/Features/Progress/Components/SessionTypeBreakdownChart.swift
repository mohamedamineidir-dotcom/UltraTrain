import SwiftUI
import Charts

struct SessionTypeBreakdownChart: View {
    let stats: [SessionTypeStats]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Session Types")
                .font(.headline)

            HStack(spacing: Theme.Spacing.lg) {
                donutChart
                    .frame(width: 120, height: 120)

                legend
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Chart

    private var donutChart: some View {
        Chart(stats) { stat in
            SectorMark(
                angle: .value("Count", stat.count),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .foregroundStyle(sessionColor(stat.sessionType))
            .cornerRadius(3)
        }
        .chartBackground { _ in
            VStack(spacing: 0) {
                Text("\(totalSessions)")
                    .font(.title3.bold().monospacedDigit())
                Text("sessions")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    // MARK: - Legend

    private var legend: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(stats) { stat in
                HStack(spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(sessionColor(stat.sessionType))
                        .frame(width: 8, height: 8)
                    Text(stat.sessionType.displayLabel)
                        .font(.caption)
                    Spacer()
                    Text("\(stat.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Text(String(format: "%.0f%%", stat.percentage))
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    private var totalSessions: Int {
        stats.reduce(0) { $0 + $1.count }
    }

    private var accessibilityDescription: String {
        let items = stats.map { "\($0.sessionType.displayLabel) \($0.count) (\(String(format: "%.0f", $0.percentage))%)" }
        return "Session type breakdown: \(items.joined(separator: ", ")). Total \(totalSessions) sessions."
    }

    // MARK: - Colors

    private func sessionColor(_ type: SessionType) -> Color {
        switch type {
        case .longRun: .blue
        case .tempo: .orange
        case .intervals: .red
        case .verticalGain: .purple
        case .backToBack: .indigo
        case .recovery: .green
        case .crossTraining: .cyan
        case .rest: .gray
        }
    }
}

// MARK: - Extensions

private extension SessionType {
    var displayLabel: String {
        switch self {
        case .longRun: "Long Run"
        case .tempo: "Tempo"
        case .intervals: "Intervals"
        case .verticalGain: "Vertical"
        case .backToBack: "Back-to-Back"
        case .recovery: "Recovery"
        case .crossTraining: "Cross-Training"
        case .rest: "Rest"
        }
    }
}
