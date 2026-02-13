import SwiftUI

struct NutritionScheduleView: View {
    let entries: [NutritionEntry]

    private var groupedByHour: [(hour: Int, entries: [NutritionEntry])] {
        let grouped = Dictionary(grouping: entries) { $0.timingMinutes / 60 }
        return grouped.sorted { $0.key < $1.key }
            .map { (hour: $0.key, entries: $0.value.sorted { $0.timingMinutes < $1.timingMinutes }) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Race Day Schedule")
                .font(.headline)
                .padding(.bottom, Theme.Spacing.xs)

            ForEach(groupedByHour, id: \.hour) { group in
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Hour \(group.hour + 1)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Colors.primary)

                    ForEach(group.entries) { entry in
                        NutritionEntryRow(entry: entry)
                    }
                }
                .cardStyle()
            }
        }
    }
}
