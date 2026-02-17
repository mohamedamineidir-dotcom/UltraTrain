import SwiftUI
import WidgetKit

struct LastRunWidgetView: View {
    let entry: LastRunEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let run = entry.run {
            switch family {
            case .systemSmall:
                smallView(run)
            default:
                mediumView(run)
            }
        } else {
            emptyView
        }
    }

    // MARK: - Small

    private func smallView(_ run: WidgetLastRunData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "figure.run")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Last Run")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            Text(formatDistance(run.distanceKm))
                .font(.title2.bold())

            Text(formatPace(run.averagePaceSecondsPerKm))
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text(relativeDate(run.date))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Medium

    private func mediumView(_ run: WidgetLastRunData) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.run")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    Text("Last Run")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }

                Text(relativeDate(run.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Text(formatDistance(run.distanceKm))
                    .font(.title2.bold())
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 6) {
                statRow("timer", formatPace(run.averagePaceSecondsPerKm))
                statRow("mountain.2.fill", formatElevation(run.elevationGainM))
                statRow("clock", formatDuration(run.duration))

                if let hr = run.averageHeartRate {
                    statRow("heart.fill", "\(hr) bpm")
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.run")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No Runs Yet")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func statRow(_ icon: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
        }
    }

    private func formatDistance(_ km: Double) -> String {
        String(format: "%.1f km", km)
    }

    private func formatPace(_ secondsPerKm: Double) -> String {
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    private func formatElevation(_ m: Double) -> String {
        String(format: "%.0f D+", m)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
