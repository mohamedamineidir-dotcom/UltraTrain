import SwiftUI
import WidgetKit

struct WatchNextSessionComplicationView: View {
    let entry: WatchNextSessionEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        default:
            inlineView
        }
    }

    // MARK: - Circular

    @ViewBuilder
    private var circularView: some View {
        if let data = entry.data, data.nextSessionType != nil {
            VStack(spacing: 2) {
                Image(systemName: data.nextSessionIcon ?? "figure.run")
                    .font(.caption)
                Text(formatShortDistance(data.nextSessionDistanceKm))
                    .font(.system(.caption2, design: .rounded).bold())
            }
            .widgetAccentable()
        } else {
            VStack(spacing: 2) {
                Image(systemName: "bed.double.fill")
                    .font(.caption)
                Text("Rest")
                    .font(.caption2)
            }
        }
    }

    // MARK: - Rectangular

    @ViewBuilder
    private var rectangularView: some View {
        if let data = entry.data, let sessionType = data.nextSessionType {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: data.nextSessionIcon ?? "figure.run")
                        .font(.caption2)
                    Text(sessionType)
                        .font(.caption2.bold())
                }
                .widgetAccentable()

                Text(formatDistance(data.nextSessionDistanceKm))
                    .font(.headline)

                if let sessionDate = data.nextSessionDate {
                    Text(formatDate(sessionDate))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("No Session")
                    .font(.caption2.bold())
                Text("Enjoy the rest!")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Inline

    @ViewBuilder
    private var inlineView: some View {
        if let data = entry.data, let sessionType = data.nextSessionType {
            Text("\(sessionType) \(formatShortDistance(data.nextSessionDistanceKm))")
        } else {
            Text("No session planned")
        }
    }

    // MARK: - Helpers

    private func formatDistance(_ km: Double?) -> String {
        guard let km else { return "--" }
        return String(format: "%.1f km", km)
    }

    private func formatShortDistance(_ km: Double?) -> String {
        guard let km else { return "--" }
        if km >= 10 {
            return String(format: "%.0fk", km)
        }
        return String(format: "%.1fk", km)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
