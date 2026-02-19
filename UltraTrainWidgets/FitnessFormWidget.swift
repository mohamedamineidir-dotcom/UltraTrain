import SwiftUI
import WidgetKit

struct FitnessFormEntry: TimelineEntry {
    let date: Date
    let fitness: WidgetFitnessData?
}

struct FitnessFormProvider: TimelineProvider {

    func placeholder(in context: Context) -> FitnessFormEntry {
        FitnessFormEntry(
            date: .now,
            fitness: WidgetFitnessData(
                form: 12,
                fitness: 65,
                fatigue: 53,
                trend: []
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FitnessFormEntry) -> Void) {
        let entry = FitnessFormEntry(
            date: .now,
            fitness: WidgetDataReader.readFitnessData()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FitnessFormEntry>) -> Void) {
        let fitness = WidgetDataReader.readFitnessData()
        let entry = FitnessFormEntry(date: .now, fitness: fitness)

        let refreshDate = Calendar.current.date(byAdding: .hour, value: 4, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct FitnessFormWidget: Widget {
    let kind = "FitnessFormWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitnessFormProvider()) { entry in
            FitnessFormWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Fitness Form")
        .description("Your current training form at a glance.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}
