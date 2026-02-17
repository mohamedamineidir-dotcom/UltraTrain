import SwiftUI
import WidgetKit

struct WeeklyProgressWidgetView: View {
    let entry: WeeklyProgressEntry

    var body: some View {
        if let progress = entry.progress {
            progressView(progress)
        } else {
            emptyView
        }
    }

    // MARK: - Progress View

    private func progressView(_ progress: WidgetWeeklyProgressData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Week \(progress.weekNumber)")
                    .font(.subheadline.bold())

                phaseBadge(progress.phase)

                Spacer()
            }

            progressBar(
                label: "Distance",
                icon: "ruler",
                actual: progress.actualDistanceKm,
                target: progress.targetDistanceKm,
                unit: "km"
            )

            progressBar(
                label: "Elevation",
                icon: "mountain.2.fill",
                actual: progress.actualElevationGainM,
                target: progress.targetElevationGainM,
                unit: "D+"
            )
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No Training Plan Active")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Components

    private func phaseBadge(_ phase: String) -> some View {
        Text(phase.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(phaseColor(phase).opacity(0.2))
            .foregroundStyle(phaseColor(phase))
            .clipShape(Capsule())
    }

    private func progressBar(
        label: String,
        icon: String,
        actual: Double,
        target: Double,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(formatValues(actual: actual, target: target, unit: unit))
                    .font(.caption2.bold())
            }

            ProgressView(value: min(actual, target), total: max(target, 0.01))
                .tint(progressColor(actual: actual, target: target))
        }
    }

    // MARK: - Helpers

    private func formatValues(actual: Double, target: Double, unit: String) -> String {
        if unit == "km" {
            return String(format: "%.1f / %.0f %@", actual, target, unit)
        }
        return String(format: "%.0f / %.0f %@", actual, target, unit)
    }

    private func progressColor(actual: Double, target: Double) -> Color {
        guard target > 0 else { return .gray }
        let ratio = actual / target
        if ratio >= 0.9 { return .green }
        if ratio >= 0.5 { return .orange }
        return .red
    }

    private func phaseColor(_ phase: String) -> Color {
        switch phase {
        case "base": .blue
        case "build": .orange
        case "peak": .red
        case "taper": .green
        case "recovery": .mint
        case "race": .purple
        default: .gray
        }
    }
}
