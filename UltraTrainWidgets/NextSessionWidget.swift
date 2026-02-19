import SwiftUI
import WidgetKit

struct NextSessionEntry: TimelineEntry {
    let date: Date
    let session: WidgetSessionData?
}

struct NextSessionProvider: TimelineProvider {

    func placeholder(in context: Context) -> NextSessionEntry {
        NextSessionEntry(
            date: .now,
            session: WidgetSessionData(
                sessionId: UUID(),
                sessionType: "longRun",
                sessionIcon: "figure.run",
                displayName: "Long Run",
                description: "Easy long run with steady pace",
                plannedDistanceKm: 25,
                plannedElevationGainM: 800,
                plannedDuration: 7200,
                intensity: "moderate",
                date: .now
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextSessionEntry) -> Void) {
        let entry = NextSessionEntry(
            date: .now,
            session: WidgetDataReader.readNextSession()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextSessionEntry>) -> Void) {
        let session = WidgetDataReader.readNextSession()
        let entry = NextSessionEntry(date: .now, session: session)

        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

struct NextSessionWidget: Widget {
    let kind = "NextSessionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextSessionProvider()) { entry in
            NextSessionWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Session")
        .description("See your next training session at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}
