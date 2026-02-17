import SwiftUI
import WidgetKit

struct RaceCountdownEntry: TimelineEntry {
    let date: Date
    let race: WidgetRaceData?
}

struct RaceCountdownProvider: TimelineProvider {

    func placeholder(in context: Context) -> RaceCountdownEntry {
        RaceCountdownEntry(
            date: .now,
            race: WidgetRaceData(
                name: "UTMB",
                date: Calendar.current.date(byAdding: .day, value: 42, to: .now) ?? .now,
                distanceKm: 171,
                elevationGainM: 10000,
                planCompletionPercent: 0.65
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RaceCountdownEntry) -> Void) {
        let entry = RaceCountdownEntry(
            date: .now,
            race: WidgetDataReader.readRaceCountdown()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RaceCountdownEntry>) -> Void) {
        let race = WidgetDataReader.readRaceCountdown()
        let entry = RaceCountdownEntry(date: .now, race: race)

        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

struct RaceCountdownWidget: Widget {
    let kind = "RaceCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RaceCountdownProvider()) { entry in
            RaceCountdownWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Race Countdown")
        .description("Days until your A-race with plan progress.")
        .supportedFamilies([.systemSmall])
    }
}
