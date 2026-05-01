import Foundation

enum IntermediateRaceHandler {

    struct RaceWeekOverride: Equatable, Sendable {
        let weekNumber: Int
        let raceId: UUID
        let behavior: Behavior
        /// 1, 2, 3 for `.postRaceRecovery` (week 1 = first week after race);
        /// nil otherwise. Drives the progressive return-to-normal scaling
        /// in post-race recovery templates so week 2 and week 3 are
        /// progressively closer to normal training rather than repeating
        /// week 1's deepest cuts.
        let weekInRecovery: Int?

        init(weekNumber: Int, raceId: UUID, behavior: Behavior, weekInRecovery: Int? = nil) {
            self.weekNumber = weekNumber
            self.raceId = raceId
            self.behavior = behavior
            self.weekInRecovery = weekInRecovery
        }
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
        // Two-A-race seasons: plan target is the LATER A-race; any A-race
        // scheduled earlier is treated like a beefed-up B-race —
        // 2-week taper + 2-3 weeks recovery. Athletes prepping spring
        // marathon + fall marathon, or UTMB + CCC, can now have both
        // marked as A-races without the planner silently dropping the
        // earlier one.
        let sortedRaces = intermediateRaces
            .sorted { $0.date < $1.date }

        var overrides: [RaceWeekOverride] = []

        for race in sortedRaces {
            let raceDay = Calendar.current.startOfDay(for: race.date)
            guard let raceWeek = skeletons.first(where: {
                let start = Calendar.current.startOfDay(for: $0.startDate)
                let end = Calendar.current.startOfDay(for: $0.endDate)
                return raceDay >= start && raceDay <= end
            }) else { continue }

            // Taper structure:
            //   A-race intermediate → 2 weeks (true peak rebuild before
            //                          targeting the FINAL A-race)
            //   B-race              → 1 week mini-taper
            //   C-race              → no taper override (training race)
            let taperWeekCount: Int
            switch race.priority {
            case .aRace: taperWeekCount = 2
            case .bRace: taperWeekCount = 1
            case .cRace: taperWeekCount = 0
            }
            for offset in 1...max(taperWeekCount, 0) where taperWeekCount > 0 {
                if let taperWeek = skeletons.first(where: { $0.weekNumber == raceWeek.weekNumber - offset }) {
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

            // Post-race recovery scales with priority + distance.
            //   A-race intermediate: 2 weeks min (longer rebuild before
            //                         the final A-race), capped at 3
            //                         for 50K+
            //   B-race: 1-3 weeks by distance (existing)
            //   C-race: 0 weeks
            let recoveryWeekCount: Int
            switch (race.priority, race.distanceKm) {
            case (.aRace, ..<30):  recoveryWeekCount = 2
            case (.aRace, ..<50):  recoveryWeekCount = 2
            case (.aRace, _):      recoveryWeekCount = 3
            case (.bRace, ..<30):  recoveryWeekCount = 1
            case (.bRace, ..<50):  recoveryWeekCount = 2
            case (.bRace, _):      recoveryWeekCount = 3
            case (.cRace, _):      recoveryWeekCount = 0
            }
            for offset in 1...max(recoveryWeekCount, 0) where recoveryWeekCount > 0 {
                if let recoveryWeek = skeletons.first(where: { $0.weekNumber == raceWeek.weekNumber + offset }) {
                    overrides.append(RaceWeekOverride(
                        weekNumber: recoveryWeek.weekNumber,
                        raceId: race.id,
                        behavior: .postRaceRecovery,
                        weekInRecovery: offset
                    ))
                }
            }
        }
        return overrides
    }
}
