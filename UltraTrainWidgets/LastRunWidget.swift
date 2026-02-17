import SwiftUI
import WidgetKit

struct LastRunEntry: TimelineEntry {
    let date: Date
    let run: WidgetLastRunData?
}

struct LastRunProvider: TimelineProvider {

    func placeholder(in context: Context) -> LastRunEntry {
        LastRunEntry(
            date: .now,
            run: WidgetLastRunData(
                date: .now,
                distanceKm: 18.5,
                elevationGainM: 650,
                duration: 5400,
                averagePaceSecondsPerKm: 360,
                averageHeartRate: 148
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LastRunEntry) -> Void) {
        let entry = LastRunEntry(
            date: .now,
            run: WidgetDataReader.readLastRun()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LastRunEntry>) -> Void) {
        let run = WidgetDataReader.readLastRun()
        let entry = LastRunEntry(date: .now, run: run)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct LastRunWidget: Widget {
    let kind = "LastRunWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LastRunProvider()) { entry in
            LastRunWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Last Run")
        .description("Quick stats from your most recent run.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
