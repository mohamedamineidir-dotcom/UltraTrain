import SwiftUI
import WidgetKit

struct NextSessionLockScreenView: View {
    let entry: NextSessionEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let session = entry.session {
            switch family {
            case .accessoryCircular:
                circularView(session)
            case .accessoryRectangular:
                rectangularView(session)
            default:
                EmptyView()
            }
        } else {
            accessoryEmptyView
        }
    }

    private func circularView(_ session: WidgetSessionData) -> some View {
        VStack(spacing: 2) {
            Image(systemName: session.sessionIcon)
                .font(.title3)
            Text(session.displayName)
                .font(.system(.caption2, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private func rectangularView(_ session: WidgetSessionData) -> some View {
        HStack(spacing: 6) {
            Image(systemName: session.sessionIcon)
                .font(.title3)

            VStack(alignment: .leading, spacing: 1) {
                Text(session.displayName)
                    .font(.headline)
                    .lineLimit(1)
                Text(String(format: "%.1f km", session.plannedDistanceKm))
                    .font(.caption)
                Text(formatDate(session.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accessoryEmptyView: some View {
        VStack(spacing: 2) {
            Image(systemName: "bed.double.fill")
                .font(.title3)
            Text("Rest")
                .font(.caption2)
        }
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
