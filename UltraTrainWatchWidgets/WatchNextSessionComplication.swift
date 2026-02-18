import SwiftUI
import WidgetKit

struct WatchNextSessionEntry: TimelineEntry {
    let date: Date
    let data: WatchComplicationData?
}

struct WatchNextSessionProvider: TimelineProvider {

    func placeholder(in context: Context) -> WatchNextSessionEntry {
        WatchNextSessionEntry(
            date: .now,
            data: WatchComplicationData(
                nextSessionType: "Long Run",
                nextSessionIcon: "figure.run",
                nextSessionDistanceKm: 25,
                nextSessionDate: .now
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchNextSessionEntry) -> Void) {
        let entry = WatchNextSessionEntry(
            date: .now,
            data: WatchComplicationDataStore.read()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchNextSessionEntry>) -> Void) {
        let data = WatchComplicationDataStore.read()
        let entry = WatchNextSessionEntry(date: .now, data: data)

        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

struct WatchNextSessionComplication: Widget {
    let kind = "WatchNextSessionComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchNextSessionProvider()) { entry in
            WatchNextSessionComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Session")
        .description("Your next training session.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
