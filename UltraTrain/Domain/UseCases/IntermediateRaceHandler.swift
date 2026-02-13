import Foundation

enum IntermediateRaceHandler {

    struct RaceWeekOverride: Equatable, Sendable {
        let weekNumber: Int
        let raceId: UUID
        let behavior: Behavior
    }

    enum Behavior: Equatable, Sendable {
        case miniTaper
        case raceWeek
        case postRaceRecovery
    }

    static func overrides(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton],
        intermediateRaces: [Race]
    ) -> [RaceWeekOverride] {
        let sortedRaces = intermediateRaces
            .filter { $0.priority != .aRace }
            .sorted { $0.date < $1.date }

        var overrides: [RaceWeekOverride] = []

        for race in sortedRaces {
            guard let raceWeek = skeletons.first(where: {
                race.date >= $0.startDate && race.date <= $0.endDate
            }) else { continue }

            // Mini-taper the week before race (if it exists)
            if let taperWeek = skeletons.first(where: { $0.weekNumber == raceWeek.weekNumber - 1 }) {
                overrides.append(RaceWeekOverride(
                    weekNumber: taperWeek.weekNumber,
                    raceId: race.id,
                    behavior: .miniTaper
                ))
            }

            // Race week itself
            overrides.append(RaceWeekOverride(
                weekNumber: raceWeek.weekNumber,
                raceId: race.id,
                behavior: .raceWeek
            ))

            // Recovery week after (if it exists)
            if let recoveryWeek = skeletons.first(where: { $0.weekNumber == raceWeek.weekNumber + 1 }) {
                overrides.append(RaceWeekOverride(
                    weekNumber: recoveryWeek.weekNumber,
                    raceId: race.id,
                    behavior: .postRaceRecovery
                ))
            }
        }
        return overrides
    }
}
