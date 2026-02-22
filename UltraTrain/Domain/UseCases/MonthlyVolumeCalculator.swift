import Foundation

enum MonthlyVolumeCalculator {

    struct MonthlyVolume: Identifiable, Equatable, Sendable {
        let id: String
        var month: Date
        var distanceKm: Double
        var elevationGainM: Double
        var duration: TimeInterval
        var runCount: Int
    }

    // MARK: - Public

    static func compute(from runs: [CompletedRun]) -> [MonthlyVolume] {
        guard !runs.isEmpty else { return [] }

        let calendar = Calendar.current

        // Group runs by year-month key
        var grouped: [String: (date: Date, distanceKm: Double, elevationGainM: Double, duration: TimeInterval, runCount: Int)] = [:]

        for run in runs {
            let components = calendar.dateComponents([.year, .month], from: run.date)
            guard let year = components.year, let month = components.month else { continue }

            let key = String(format: "%04d-%02d", year, month)

            if var existing = grouped[key] {
                existing.distanceKm += run.distanceKm
                existing.elevationGainM += run.elevationGainM
                existing.duration += run.duration
                existing.runCount += 1
                grouped[key] = existing
            } else {
                let firstOfMonth = calendar.date(from: components) ?? run.date
                grouped[key] = (
                    date: firstOfMonth,
                    distanceKm: run.distanceKm,
                    elevationGainM: run.elevationGainM,
                    duration: run.duration,
                    runCount: 1
                )
            }
        }

        // Sort ascending by key, limit to last 12 months
        let sortedEntries = grouped
            .sorted { $0.key < $1.key }
            .suffix(12)

        return sortedEntries.map { key, value in
            MonthlyVolume(
                id: key,
                month: value.date,
                distanceKm: value.distanceKm,
                elevationGainM: value.elevationGainM,
                duration: value.duration,
                runCount: value.runCount
            )
        }
    }
}
