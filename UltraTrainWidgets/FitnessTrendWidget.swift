import SwiftUI
import WidgetKit

struct FitnessTrendEntry: TimelineEntry {
    let date: Date
    let fitness: WidgetFitnessData?
}

struct FitnessTrendProvider: TimelineProvider {

    func placeholder(in context: Context) -> FitnessTrendEntry {
        FitnessTrendEntry(
            date: .now,
            fitness: WidgetFitnessData(
                form: 12,
                fitness: 65,
                fatigue: 53,
                trend: (0..<14).map { i in
                    WidgetFitnessPoint(
                        date: Calendar.current.date(byAdding: .day, value: -13 + i, to: .now) ?? .now,
                        form: Double.random(in: -10...20)
                    )
                }
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FitnessTrendEntry) -> Void) {
        let entry = FitnessTrendEntry(
            date: .now,
            fitness: WidgetDataReader.readFitnessData()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FitnessTrendEntry>) -> Void) {
        let fitness = WidgetDataReader.readFitnessData()
        let entry = FitnessTrendEntry(date: .now, fitness: fitness)

        let refreshDate = Calendar.current.date(byAdding: .hour, value: 4, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct FitnessTrendWidget: Widget {
    let kind = "FitnessTrendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitnessTrendProvider()) { entry in
            FitnessTrendWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Fitness Trend")
        .description("14-day fitness form trend with sparkline.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
