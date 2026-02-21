import Foundation

enum PersonalRecordCalculator {

    static func computeAll(from runs: [CompletedRun]) -> [PersonalRecord] {
        guard !runs.isEmpty else { return [] }
        var records: [PersonalRecord] = []

        // Original 4 records
        if let longest = runs.max(by: { $0.distanceKm < $1.distanceKm }) {
            records.append(PersonalRecord(
                id: UUID(), type: .longestDistance,
                value: longest.distanceKm, date: longest.date, runId: longest.id
            ))
        }
        if let mostElev = runs.max(by: { $0.elevationGainM < $1.elevationGainM }) {
            records.append(PersonalRecord(
                id: UUID(), type: .mostElevation,
                value: mostElev.elevationGainM, date: mostElev.date, runId: mostElev.id
            ))
        }
        let runsWithPace = runs.filter { $0.averagePaceSecondsPerKm > 0 }
        if let fastest = runsWithPace.min(by: { $0.averagePaceSecondsPerKm < $1.averagePaceSecondsPerKm }) {
            records.append(PersonalRecord(
                id: UUID(), type: .fastestPace,
                value: fastest.averagePaceSecondsPerKm, date: fastest.date, runId: fastest.id
            ))
        }
        if let longestDur = runs.max(by: { $0.duration < $1.duration }) {
            records.append(PersonalRecord(
                id: UUID(), type: .longestDuration,
                value: longestDur.duration, date: longestDur.date, runId: longestDur.id
            ))
        }

        // Distance bracket records
        let brackets: [(PersonalRecordType, Double)] = [
            (.fastest5K, 5.0),
            (.fastest10K, 10.0),
            (.fastestHalf, 21.1),
            (.fastestMarathon, 42.2),
            (.fastest50K, 50.0),
            (.fastest100K, 100.0)
        ]

        for (type, targetKm) in brackets {
            let tolerance = targetKm * 0.1
            let bracketRuns = runs.filter {
                $0.distanceKm >= (targetKm - tolerance) && $0.distanceKm <= (targetKm + tolerance)
            }
            if let best = bracketRuns.min(by: { $0.duration < $1.duration }) {
                records.append(PersonalRecord(
                    id: UUID(), type: type,
                    value: best.duration, date: best.date, runId: best.id
                ))
            }
        }

        return records
    }
}
