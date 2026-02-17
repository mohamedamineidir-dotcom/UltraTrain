import SwiftUI
import WidgetKit

struct NextSessionWidgetView: View {
    let entry: NextSessionEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let session = entry.session {
            switch family {
            case .systemSmall:
                smallView(session)
            default:
                mediumView(session)
            }
        } else {
            emptyView
        }
    }

    // MARK: - Small

    private func smallView(_ session: WidgetSessionData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: session.sessionIcon)
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text(session.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            Text(formatDistance(session.plannedDistanceKm))
                .font(.title2.bold())

            if session.plannedDuration > 0 {
                Text(formatDuration(session.plannedDuration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(formatDate(session.date))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Medium

    private func mediumView(_ session: WidgetSessionData) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: session.sessionIcon)
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    Text(session.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }

                Text(session.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer(minLength: 0)

                Text(formatDate(session.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 6) {
                statRow("ruler", formatDistance(session.plannedDistanceKm))
                statRow("mountain.2.fill", formatElevation(session.plannedElevationGainM))
                statRow("clock", formatDuration(session.plannedDuration))

                Spacer(minLength: 0)

                intensityBadge(session.intensity)
            }
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bed.double.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No Session Planned")
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

    private func intensityBadge(_ intensity: String) -> some View {
        Text(intensity.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(intensityColor(intensity).opacity(0.2))
            .foregroundStyle(intensityColor(intensity))
            .clipShape(Capsule())
    }

    private func intensityColor(_ intensity: String) -> Color {
        switch intensity {
        case "easy": .green
        case "moderate": .orange
        case "hard": .red
        case "maxEffort": .purple
        default: .gray
        }
    }

    private func formatDistance(_ km: Double) -> String {
        String(format: "%.1f km", km)
    }

    private func formatElevation(_ m: Double) -> String {
        String(format: "%.0f D+", m)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(String(format: "%02d", minutes))"
        }
        return "\(minutes) min"
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}
