import SwiftUI
import WidgetKit

struct WatchRaceCountdownEntry: TimelineEntry {
    let date: Date
    let data: WatchComplicationData?
}

struct WatchRaceCountdownProvider: TimelineProvider {

    func placeholder(in context: Context) -> WatchRaceCountdownEntry {
        WatchRaceCountdownEntry(
            date: .now,
            data: WatchComplicationData(
                raceCountdownDays: 42,
                raceName: "UTMB"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchRaceCountdownEntry) -> Void) {
        let entry = WatchRaceCountdownEntry(
            date: .now,
            data: WatchComplicationDataStore.read()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchRaceCountdownEntry>) -> Void) {
        let data = WatchComplicationDataStore.read()
        let entry = WatchRaceCountdownEntry(date: .now, data: data)

        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

struct WatchRaceCountdownComplication: Widget {
    let kind = "WatchRaceCountdownComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchRaceCountdownProvider()) { entry in
            WatchRaceCountdownComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Race Countdown")
        .description("Days until your A-race.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
