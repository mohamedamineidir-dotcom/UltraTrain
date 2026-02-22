import SwiftUI
import Charts

struct ActivityTypeBreakdownData: Identifiable {
    let id = UUID()
    let activityType: ActivityType
    let count: Int
    let percentage: Double
}

struct ActivityTypeBreakdownChart: View {
    let runs: [CompletedRun]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Activity Types")
                .font(.headline)

            if breakdown.isEmpty {
                Text("No activities logged yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                HStack(spacing: Theme.Spacing.lg) {
                    donutChart
                        .frame(width: 120, height: 120)
                    legend
                }
            }
        }
        .chartAccessibility(summary: accessibilityDescription)
    }

    // MARK: - Chart

    private var donutChart: some View {
        Chart(breakdown) { item in
            SectorMark(
                angle: .value("Count", item.count),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .foregroundStyle(activityColor(item.activityType))
            .cornerRadius(3)
        }
        .chartBackground { _ in
            VStack(spacing: 0) {
                Text("\(runs.count)")
                    .font(.title3.bold().monospacedDigit())
                Text("activities")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    // MARK: - Legend

    private var legend: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(breakdown) { item in
                HStack(spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(activityColor(item.activityType))
                        .frame(width: 8, height: 8)
                    Text(item.activityType.displayName)
                        .font(.caption)
                    Spacer()
                    Text("\(item.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Text(String(format: "%.0f%%", item.percentage))
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Data

    private var breakdown: [ActivityTypeBreakdownData] {
        let total = runs.count
        guard total > 0 else { return [] }

        var counts: [ActivityType: Int] = [:]
        for run in runs {
            counts[run.activityType, default: 0] += 1
        }

        return counts
            .sorted { $0.value > $1.value }
            .map { type, count in
                ActivityTypeBreakdownData(
                    activityType: type,
                    count: count,
                    percentage: Double(count) / Double(total) * 100.0
                )
            }
    }

    private var accessibilityDescription: String {
        let items = breakdown.map {
            "\($0.activityType.displayName) \($0.count) (\(String(format: "%.0f", $0.percentage))%)"
        }
        return "Activity type breakdown: \(items.joined(separator: ", ")). Total \(runs.count) activities."
    }

    // MARK: - Colors

    private func activityColor(_ type: ActivityType) -> Color {
        switch type {
        case .running: .blue
        case .trailRunning: .indigo
        case .cycling: .orange
        case .swimming: .cyan
        case .hiking: .green
        case .strength: .red
        case .yoga: .purple
        case .other: .gray
        }
    }
}
