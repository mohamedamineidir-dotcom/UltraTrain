import SwiftUI
import WidgetKit

struct WatchRaceCountdownComplicationView: View {
    let entry: WatchRaceCountdownEntry

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
        if let data = entry.data, let days = data.raceCountdownDays {
            VStack(spacing: 0) {
                Text("\(days)")
                    .font(.system(.title3, design: .rounded).bold())
                    .widgetAccentable()
                Text("days")
                    .font(.system(.caption2))
            }
        } else {
            VStack(spacing: 2) {
                Image(systemName: "flag.checkered")
                    .font(.caption)
                Text("--")
                    .font(.caption2)
            }
        }
    }

    // MARK: - Rectangular

    @ViewBuilder
    private var rectangularView: some View {
        if let data = entry.data, let days = data.raceCountdownDays {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flag.checkered")
                        .font(.caption2)
                    Text(data.raceName ?? "Race")
                        .font(.caption2.bold())
                        .lineLimit(1)
                }
                .widgetAccentable()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(days)")
                        .font(.system(.title2, design: .rounded).bold())
                    Text(days == 1 ? "day to go" : "days to go")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("No Race")
                    .font(.caption2.bold())
                Text("Set up a race in the app")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Inline

    @ViewBuilder
    private var inlineView: some View {
        if let data = entry.data, let days = data.raceCountdownDays {
            Text("\(data.raceName ?? "Race"): \(days)d")
        } else {
            Text("No race scheduled")
        }
    }
}
