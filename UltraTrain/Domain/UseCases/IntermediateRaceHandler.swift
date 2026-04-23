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
                // RR-23: post-race recovery duration scales with race distance.
                // Daniels' rule: ~1 easy day per 3 km of race distance.
                //   10K / HM  → 1 recovery week
                //   Marathon+ → 2 recovery weeks
                //   50K+      → 3 recovery weeks
                // Previously we always inserted exactly 1 recovery week
                // regardless — a 42 km B-race got the same 7-day return-to-
                // training as a 10K, insufficient by a factor of 2.
                let recoveryWeekCount: Int
                switch race.distanceKm {
                case ..<30:    recoveryWeekCount = 1
                case ..<50:    recoveryWeekCount = 2
                default:       recoveryWeekCount = 3
                }
                for offset in 1...recoveryWeekCount {
                    if let recoveryWeek = skeletons.first(where: { $0.weekNumber == raceWeek.weekNumber + offset }) {
                        overrides.append(RaceWeekOverride(
                            weekNumber: recoveryWeek.weekNumber,
                            raceId: race.id,
                            behavior: .postRaceRecovery
                        ))
                    }
                }
            }
        }
        return overrides
    }
}
