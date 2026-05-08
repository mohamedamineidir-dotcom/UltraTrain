import Foundation

/// Decides where to inject road-race-specific quality sessions when an
/// athlete has a trail/ultra A-race + road B/C races during the prep
/// cycle and has explicitly opted into specificity.
///
/// Coaching consensus (Pfizinger *Faster Road Racing*; Daniels *RF*
/// Ch. 13; Hudson *Run Faster*; Magness "transmutation"; Roche SWAP;
/// Koop *TEU* Ch. 5):
/// - 1-3 race-specific sessions in the 2-3 weeks before the B-race
///   (replacing existing intervals/tempo/longRun slots — does NOT add
///   net work)
/// - Number scales by distance: 10K → 1-2; HM → 2-3; Marathon → 2-3
///   (incl. 1 MP-block long run)
/// - Modifiers: beginner / enjoyment philosophy → 1 session less;
///   gap-to-A-race < 4 weeks → reduced or skipped
/// - Ultra B/C races: skip entirely. Trail/ultra training already IS
///   the specificity for an ultra. Consensus across Daniels, Koop,
///   Roche.
///
/// Implementation: reuses `RoadIntervalLibrary` + `RoadWorkoutBuilder` +
/// `RoadLongRunWorkoutBuilder` for the actual session structures, so
/// we don't duplicate the road-specific quality libraries.
enum BRaceSpecificityCalculator {

    /// A single session-replacement instruction. The substitutor reads
    /// these and rewrites the matching session in the trail plan.
    struct Injection: Equatable, Sendable {
        let raceId: UUID
        let weekNumber: Int          // matches WeekSkeleton.weekNumber (1-based)
        let bRaceDiscipline: RoadRaceDiscipline
        let bRaceGoalTime: TimeInterval
        let bRaceDistanceKm: Double
        /// Which slot to replace in the week's session list. Maps to
        /// `SessionType` directly.
        let slot: Slot
        /// Which kind of road-specific work to inject. Drives the
        /// template selection inside `BRaceSpecificitySubstitutor`.
        let kind: Kind
    }

    enum Slot: Sendable, Equatable {
        case intervals
        case tempo
        case longRun
    }

    enum Kind: Sendable, Equatable {
        /// 5K-10K-pace VO2max intervals (e.g., 5×1km @ 10K pace).
        case vo2maxIntervals
        /// HMP threshold tempo (e.g., 3×3km @ HMP).
        case thresholdTempo
        /// Marathon-pace blocks inside long run (e.g., 16km long run
        /// with 8km @ MP).
        case marathonPaceLongRun
        /// Marathon-pace tempo (e.g., 8km @ MP within shorter session).
        case marathonPaceTempo
    }

    // MARK: - Public API

    /// Returns the list of injections for the trail plan. Empty when
    /// no eligible B/C races + opt-ins exist.
    static func injections(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton],
        intermediateRaces: [Race],
        targetRace: Race,
        athlete: Athlete
    ) -> [Injection] {
        // Only meaningful for trail/ultra A-races. For road A-races
        // the existing RoadSessionSelector already does specificity.
        guard targetRace.raceType == .trail else { return [] }

        var result: [Injection] = []

        // Process each eligible B/C race independently.
        let eligible = intermediateRaces.filter { isEligible($0) }
        for bRace in eligible {
            guard let goalTime = goalTime(of: bRace) else { continue }
            let discipline = RoadRaceDiscipline.from(distanceKm: bRace.distanceKm)
            let bRaceWeekNumber = weekNumber(of: bRace.date, in: skeletons)
            guard let bRaceWeekNumber else { continue }

            // Gap-to-A-race rule: weeks between B-race and A-race.
            let weeksToARace = max(0, skeletons.count - bRaceWeekNumber)
            // Skip if too close — don't compromise A-race taper.
            if weeksToARace < 3 { continue }

            // Gap-from-prior-race rule: skip if athlete is still
            // recovering from another race within the past 3 weeks.
            let isRecentlyAfterAnotherRace = intermediateRaces.contains { other in
                guard other.id != bRace.id,
                      let otherWeek = weekNumber(of: other.date, in: skeletons)
                else { return false }
                let gap = bRaceWeekNumber - otherWeek
                return gap > 0 && gap < 3
            }
            if isRecentlyAfterAnotherRace { continue }

            // Number of injections to schedule for this race.
            let count = injectionCount(
                discipline: discipline,
                priority: bRace.priority,
                weeksToARace: weeksToARace,
                experience: athlete.experienceLevel,
                philosophy: athlete.trainingPhilosophy
            )
            guard count > 0 else { continue }

            // Walk back from the B-race week. Mini-taper is the week
            // immediately before; specificity sits in weeks W-2 / W-3
            // / W-4 of the build (depending on count).
            //   count=1 → W-2 only
            //   count=2 → W-3 + W-2
            //   count=3 → W-4 + W-3 + W-2
            for i in 1...count {
                let injectionWeek = bRaceWeekNumber - 1 - i
                guard injectionWeek >= 1, injectionWeek <= skeletons.count else { continue }
                let skeleton = skeletons[injectionWeek - 1]
                // Skip recovery weeks + race weeks + taper. Peak is
                // OK — when a B-race lands in the A-race's peak phase,
                // the surrounding training weeks are in peak too, and
                // there's no fitness-development reason to forbid B-race
                // specificity in those weeks (the alternative is doing
                // nothing for this race).
                let allowedPhases: Set<TrainingPhase> = [.base, .build, .peak]
                guard allowedPhases.contains(skeleton.phase) else { continue }
                guard !skeleton.isRecoveryWeek else { continue }

                // Pick the slot + kind based on (weeksBefore, discipline).
                let weeksBefore = bRaceWeekNumber - injectionWeek
                let (slot, kind) = pickSlotAndKind(
                    weeksBefore: weeksBefore, discipline: discipline
                )

                result.append(Injection(
                    raceId: bRace.id,
                    weekNumber: skeleton.weekNumber,
                    bRaceDiscipline: discipline,
                    bRaceGoalTime: goalTime,
                    bRaceDistanceKm: bRace.distanceKm,
                    slot: slot,
                    kind: kind
                ))
            }
        }
        return result
    }

    // MARK: - Eligibility

    private static func isEligible(_ race: Race) -> Bool {
        guard race.includesSpecificPrep else { return false }
        guard race.raceType == .road else { return false }
        guard hasTargetTime(race) else { return false }
        guard race.priority != .aRace else { return false }
        return true
    }

    private static func hasTargetTime(_ race: Race) -> Bool {
        if case .targetTime = race.goalType { return true }
        return false
    }

    private static func goalTime(of race: Race) -> TimeInterval? {
        if case .targetTime(let t) = race.goalType { return t }
        return nil
    }

    // MARK: - Count + slot selection

    private static func injectionCount(
        discipline: RoadRaceDiscipline,
        priority: RacePriority,
        weeksToARace: Int,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy
    ) -> Int {
        // Base prescription by distance.
        let base: Int
        switch discipline {
        case .road10K:      base = 2
        case .roadHalf:     base = 3
        case .roadMarathon: base = 3
        }

        // C-race: half prescription (rounded down, min 1).
        var count = priority == .cRace ? max(1, base / 2) : base

        // Gap-to-A-race rule: pulled into the A-race taper window →
        // reduce or skip.
        if weeksToARace < 4 {
            count = min(count, 1)
        } else if weeksToARace < 5 {
            count = min(count, 2)
        }

        // Athlete-level dampers — beginners + enjoyment athletes get
        // one less specific session.
        if experience == .beginner { count -= 1 }
        if philosophy == .enjoyment { count -= 1 }

        return max(0, count)
    }

    private static func pickSlotAndKind(
        weeksBefore: Int,
        discipline: RoadRaceDiscipline
    ) -> (Slot, Kind) {
        switch discipline {
        case .road10K:
            // Both injections become VO2max intervals in the intervals
            // slot. W-2 is the lighter primer; substitutor picks
            // appropriate template.
            return (.intervals, .vo2maxIntervals)
        case .roadHalf:
            // W-3 → tempo at HMP (longer threshold).
            // W-2 → intervals at HMP (shorter, sharper).
            // W-4 (if used) → tempo (early specificity).
            if weeksBefore == 2 {
                return (.intervals, .thresholdTempo)
            }
            return (.tempo, .thresholdTempo)
        case .roadMarathon:
            // W-2 → tempo (8km at MP, no long run because it's close
            // to the race).
            // W-3 / W-4 → MP-block long run (the centerpiece).
            if weeksBefore == 2 {
                return (.tempo, .marathonPaceTempo)
            }
            return (.longRun, .marathonPaceLongRun)
        }
    }

    // MARK: - Helpers

    private static func weekNumber(
        of date: Date,
        in skeletons: [WeekSkeletonBuilder.WeekSkeleton]
    ) -> Int? {
        // Normalize to start-of-day. Skeleton endDate is at 00:00 of
        // the last day of the week; a wallclock-time race date later
        // that day would otherwise fail the range check. Use
        // calendar-day comparison via startOfDay to keep the range
        // inclusive at both ends.
        let cal = Calendar.current
        let dateDay = cal.startOfDay(for: date)
        return skeletons.first { skel in
            dateDay >= skel.startDate && dateDay <= skel.endDate
        }?.weekNumber
    }
}
