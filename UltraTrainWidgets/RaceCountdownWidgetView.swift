import SwiftUI
import WidgetKit

struct RaceCountdownWidgetView: View {
    let entry: RaceCountdownEntry

    var body: some View {
        if let race = entry.race {
            raceView(race)
        } else {
            emptyView
        }
    }

    // MARK: - Race View

    private func raceView(_ race: WidgetRaceData) -> some View {
        VStack(spacing: 6) {
            Text("\(daysUntil(race.date))")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
            Text("days")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .offset(y: -4)

            Text(race.name)
                .font(.caption2.bold())
                .lineLimit(1)

            Text(raceInfo(race))
                .font(.caption2)
                .foregroundStyle(.secondary)

            Gauge(value: race.planCompletionPercent) {
                EmptyView()
            }
            .gaugeStyle(.linearCapacity)
            .tint(.orange)
            .scaleEffect(y: 0.8)
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No Race Scheduled")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func daysUntil(_ date: Date) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0)
    }

    private func raceInfo(_ race: WidgetRaceData) -> String {
        let km = String(format: "%.0f km", race.distanceKm)
        let dPlus = String(format: "%.0f D+", race.elevationGainM)
        return "\(km) | \(dPlus)"
    }
}
