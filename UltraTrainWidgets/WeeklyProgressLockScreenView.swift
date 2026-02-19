import SwiftUI
import WidgetKit

struct WeeklyProgressLockScreenView: View {
    let entry: WeeklyProgressEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let progress = entry.progress {
            switch family {
            case .accessoryCircular:
                circularView(progress)
            case .accessoryRectangular:
                rectangularView(progress)
            default:
                EmptyView()
            }
        } else {
            accessoryEmptyView
        }
    }

    private func circularView(_ progress: WidgetWeeklyProgressData) -> some View {
        let ratio = progress.targetDistanceKm > 0
            ? progress.actualDistanceKm / progress.targetDistanceKm
            : 0
        return Gauge(value: min(ratio, 1.0)) {
            Image(systemName: "figure.run")
        } currentValueLabel: {
            Text("\(Int(ratio * 100))%")
                .font(.system(.caption2, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }

    private func rectangularView(_ progress: WidgetWeeklyProgressData) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Week \(progress.weekNumber)")
                .font(.headline)

            progressRow(
                icon: "ruler",
                actual: progress.actualDistanceKm,
                target: progress.targetDistanceKm,
                unit: "km"
            )
            progressRow(
                icon: "mountain.2.fill",
                actual: progress.actualElevationGainM,
                target: progress.targetElevationGainM,
                unit: "D+"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func progressRow(icon: String, actual: Double, target: Double, unit: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            let ratio = target > 0 ? actual / target : 0
            ProgressView(value: min(ratio, 1.0))
                .tint(ratio >= 0.9 ? .green : .orange)
            Text(unit == "km" ? String(format: "%.0f", actual) : String(format: "%.0f", actual))
                .font(.caption2)
        }
    }

    private var accessoryEmptyView: some View {
        VStack(spacing: 2) {
            Image(systemName: "chart.bar.fill")
                .font(.title3)
            Text("No Plan")
                .font(.caption2)
        }
    }
}
