import Foundation

enum IntermediateRaceHandler {

    struct RaceWeekOverride: Equatable, Sendable {
        let weekNumber: Int
        let raceId: UUID
        let behavior: Behavior
    }

    enum Behavior: Equatable, Sendable {
        case miniTaper
        case raceWeek(priority: RacePriority)
        case postRaceRecovery

        var isRaceWeek: Bool {
            if case .raceWeek = self { return true }
            return false
        }
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
            let raceDay = Calendar.current.startOfDay(for: race.date)
            guard let raceWeek = skeletons.first(where: {
                let start = Calendar.current.startOfDay(for: $0.startDate)
                let end = Calendar.current.startOfDay(for: $0.endDate)
                return raceDay >= start && raceDay <= end
            }) else { continue }

            // B-races get full treatment: taper + race week + recovery
            // C-races get only the race week override (lighter treatment)
            if race.priority == .bRace {
                if let taperWeek = skeletons.first(where: { $0.weekNumber == raceWeek.weekNumber - 1 }) {
                    overrides.append(RaceWeekOverride(
                        weekNumber: taperWeek.weekNumber,
                        raceId: race.id,
                        behavior: .miniTaper
                    ))
                }
            }

            overrides.append(RaceWeekOverride(
                weekNumber: raceWeek.weekNumber,
                raceId: race.id,
                behavior: .raceWeek(priority: race.priority)
            ))

            if race.priority == .bRace {
                if let recoveryWeek = skeletons.first(where: { $0.weekNumber == raceWeek.weekNumber + 1 }) {
                    overrides.append(RaceWeekOverride(
                        weekNumber: recoveryWeek.weekNumber,
                        raceId: race.id,
                        behavior: .postRaceRecovery
                    ))
                }
            }
        }
        return overrides
    }
}
