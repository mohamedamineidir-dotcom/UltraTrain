import SwiftUI
import WidgetKit

struct WeeklyProgressEntry: TimelineEntry {
    let date: Date
    let progress: WidgetWeeklyProgressData?
}

struct WeeklyProgressProvider: TimelineProvider {

    func placeholder(in context: Context) -> WeeklyProgressEntry {
        WeeklyProgressEntry(
            date: .now,
            progress: WidgetWeeklyProgressData(
                actualDistanceKm: 45,
                targetDistanceKm: 70,
                actualElevationGainM: 1200,
                targetElevationGainM: 2000,
                phase: "build",
                weekNumber: 8
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyProgressEntry) -> Void) {
        let entry = WeeklyProgressEntry(
            date: .now,
            progress: WidgetDataReader.readWeeklyProgress()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyProgressEntry>) -> Void) {
        let progress = WidgetDataReader.readWeeklyProgress()
        let entry = WeeklyProgressEntry(date: .now, progress: progress)

        let refreshDate = Calendar.current.date(byAdding: .hour, value: 4, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct WeeklyProgressWidget: Widget {
    let kind = "WeeklyProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyProgressProvider()) { entry in
            WeeklyProgressWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Weekly Progress")
        .description("Track your training volume this week.")
        .supportedFamilies([.systemMedium])
    }
}
