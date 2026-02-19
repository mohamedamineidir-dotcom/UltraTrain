import SwiftUI
import WidgetKit

struct RaceCountdownLockScreenView: View {
    let entry: RaceCountdownEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let race = entry.race {
            switch family {
            case .accessoryCircular:
                circularView(race)
            case .accessoryInline:
                inlineView(race)
            default:
                EmptyView()
            }
        } else {
            accessoryEmptyView
        }
    }

    private func circularView(_ race: WidgetRaceData) -> some View {
        VStack(spacing: 1) {
            Text("\(daysUntil(race.date))")
                .font(.system(.title, design: .rounded).bold())
            Text("days")
                .font(.system(.caption2, weight: .semibold))
        }
    }

    private func inlineView(_ race: WidgetRaceData) -> some View {
        Text("\(daysUntil(race.date))d to \(race.name)")
    }

    private var accessoryEmptyView: some View {
        VStack(spacing: 2) {
            Image(systemName: "flag.checkered")
                .font(.title3)
            Text("No Race")
                .font(.caption2)
        }
    }

    private func daysUntil(_ date: Date) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0)
    }
}
