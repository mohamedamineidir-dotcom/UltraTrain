import Foundation

/// Post-race recovery prescriptions for ROAD races
/// (5K / 10K / Half Marathon / Marathon).
///
/// Replaces the generic `recoveryTemplates` shape for the weeks AFTER
/// the A-race with a research-backed, day-by-day structure that:
///
/// - Scales by race distance class. A 5K recovery week is "two days
///   easy + light strides"; a marathon W1 is "mostly rest plus walking
///   or one short cross-training session."
/// - Drops vertical-gain entirely (road plans had it via the generic
///   recovery template, wrong for road athletes anyway).
/// - Modifies by athlete experience and philosophy. Beginners get an
///   extra rest day; performance philosophy keeps slightly more
///   volume in late recovery; enjoyment replaces some easy runs with
///   walking or cross-training.
/// - Total weekly volume in W1 of marathon recovery is ~20% of peak,
///   not the 60-70% the in-plan recovery template aims at.
///
/// Sources:
/// - Daniels, *Running Formula* Ch. 10, "easy day per 3 km of race"
///   rule scaling recovery to race distance
/// - Pfitzinger, *Advanced Marathoning* Ch. 9, post-marathon protocol
///   (5 days easy / cross-train, then 3-5 mi jogs, 2-3 weeks rebuild)
/// - Hansons, *Marathon Method* Ch. 10, 7-10 days zero training, then
///   gradual easy return; cross-training if joint pain or DOMS persists
/// - Magness, *The Science of Running* Ch. 14, recovery cadence and
///   neuromuscular re-engagement
/// - Galloway, *Marathon*, "recovery week per major race" guideline
/// - Hudson, *Run Faster*, 5K / 10K recovery (lighter than half / marathon)
enum RoadRaceRecoveryTemplates {

    // MARK: - Public API

    static func sessions(
        targetRace: Race,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy,
        weekStartDate: Date,
        weekInRecovery: Int  // 1-based: 1, 2, 3
    ) -> [SessionTemplateGenerator.SessionTemplate] {
        let distClass = RoadRaceClass.from(distanceKm: targetRace.distanceKm)
        let mod = Modifiers(
            isBeginner: experience == .beginner,
            isAdvanced: experience == .advanced || experience == .elite,
            isPerformance: philosophy == .performance,
            isEnjoyment: philosophy == .enjoyment
        )

        let shape = recoveryShape(
            for: distClass,
            weekInRecovery: weekInRecovery,
            mod: mod
        )

        let templates: [SessionTemplateGenerator.SessionTemplate] = shape.map { day, session in
            SessionTemplateGenerator.tpl(
                day, session.type, session.intensity,
                session.durationSeconds, 0, session.description
            )
        }

        // Backfill any unused days with rest.
        let usedDays = Set(templates.map(\.dayOffset))
        var result = templates
        for day in 0...6 where !usedDays.contains(day) {
            result.append(SessionTemplateGenerator.tpl(
                day, .rest, .easy, 0, 0,
                "Rest day. Recovery is the work."
            ))
        }
        return result.sorted { $0.dayOffset < $1.dayOffset }
    }

    // MARK: - Distance class

    private enum RoadRaceClass {
        case fiveK         // < 8 km
        case tenK          // 8-15 km
        case halfMarathon  // 15-30 km
        case marathon      // 30-50 km
        case ultra         // 50+ km (rare road category, 50K, 50mi road)

        static func from(distanceKm: Double) -> RoadRaceClass {
            switch distanceKm {
            case ..<8:   return .fiveK
            case ..<15:  return .tenK
            case ..<30:  return .halfMarathon
            case ..<50:  return .marathon
            default:     return .ultra
            }
        }
    }

    // MARK: - Types

    private struct RecoverySession {
        let type: SessionType
        let intensity: Intensity
        let durationSeconds: TimeInterval
        let description: String
    }

    private struct Modifiers {
        let isBeginner: Bool
        let isAdvanced: Bool
        let isPerformance: Bool
        let isEnjoyment: Bool
    }

    // MARK: - Shape dispatch

    private static func recoveryShape(
        for distClass: RoadRaceClass,
        weekInRecovery: Int,
        mod: Modifiers
    ) -> [(day: Int, session: RecoverySession)] {
        switch (distClass, weekInRecovery) {
        case (.fiveK, _):           return fiveKWeek1(mod)
        case (.tenK, _):            return tenKWeek1(mod)
        case (.halfMarathon, _):    return halfWeek1(mod)

        case (.marathon, 1):        return marathonWeek1(mod)
        case (.marathon, 2):        return marathonWeek2(mod)
        case (.marathon, _):        return marathonWeek3(mod)

        case (.ultra, 1):           return ultraRoadWeek1(mod)
        case (.ultra, 2):           return ultraRoadWeek2(mod)
        case (.ultra, _):           return ultraRoadWeek3(mod)
        }
    }

    // MARK: - 5K (1 recovery week)

    private static func fiveKWeek1(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // 5K post-race is light. ~50-60% of peak. Most athletes are
        // running again by Day 1.
        [
            (0, rest()),
            (1, easy(scaled(30, mod), "Easy 30 min jog. Shake out race effort.")),
            (2, mod.isBeginner ? rest("Rest. Beginners take an extra easy day.") : easy(scaled(35, mod), "Easy 35 min, conversational.")),
            (3, easy(scaled(35, mod), "Easy 35 min + 4 strides if legs feel sharp.")),
            (4, rest()),
            (5, easy(scaled(45, mod), "Easy 45-50 min on flat.")),
            (6, mod.isPerformance ? easy(scaled(30, mod), "Easy 30 min, performance retains volume.") : rest()),
        ]
    }

    // MARK: - 10K (1 recovery week)

    private static func tenKWeek1(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // ~50% of peak. Slightly less running than 5K because of more
        // glycogen depletion / muscle damage from the longer effort.
        [
            (0, rest()),
            (1, easy(scaled(35, mod), "Easy 35 min jog. Shake out the effort.")),
            (2, mod.isBeginner ? rest() : easy(scaled(30, mod), "Easy 30 min, conversational.")),
            (3, easy(scaled(40, mod), "Easy 40 min + 4 strides.")),
            (4, rest()),
            (5, easy(scaled(50, mod), "Easy 50 min on flat.")),
            (6, mod.isPerformance ? easy(scaled(30, mod), "Easy 30 min, performance philosophy.") : rest()),
        ]
    }

    // MARK: - Half marathon (1 recovery week)

    private static func halfWeek1(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // ~40% of peak. HM produces real muscle damage, 1-2 days off
        // first, then progressive return.
        [
            (0, rest()),
            (1, mod.isBeginner ? rest("Rest. Beginners need an extra day after a half.") : walk(scaled(30, mod))),
            (2, easy(scaled(30, mod), "Easy 30 min very gentle. Pace by feel.")),
            (3, rest()),
            (4, easy(scaled(35, mod), "Easy 35 min, conversational.")),
            (5, mod.isEnjoyment ? walk(scaled(30, mod)) : easy(scaled(35, mod), "Easy 35 min, light.")),
            (6, easy(scaled(55, mod), "Easy 50-55 min on flat. No pace targets, by feel only.")),
        ]
    }

    // MARK: - Marathon (2 recovery weeks)

    private static func marathonWeek1(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W1 of 2. ~15-20% of peak. Pfitz / Hansons consensus: 5-7 days
        // of zero structured running after a marathon. Walking and
        // very light cross-training only.
        [
            (0, rest("Complete rest. Eat, sleep, hydrate.")),
            (1, mod.isPerformance ? walk(scaled(25, mod)) : rest()),
            (2, rest()),
            (3, mod.isBeginner ? rest() : walk(scaled(30, mod))),
            (4, mod.isAdvanced && !mod.isEnjoyment
                ? easy(scaled(25, mod), "Optional 25 min very easy jog. Skip if anything still hurts.")
                : cross(scaled(30, mod))),
            (5, rest()),
            (6, easy(scaled(30, mod), "Easy 30 min jog. First 'real' run since the marathon.")),
        ]
    }

    private static func marathonWeek2(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W2 of 3. Pfitzinger *Adv. Marathoning* Plan A reverse taper W2:
        // 4 runs (Tue/Thu/Sat/Sun pattern). Hansons Marathon Method Ch.10
        // is even more conservative at 3-4 easy runs. All recovery pace,
        // no quality. Identical across philosophies, performance doesn't
        // get extra running here; muscle damage doesn't care about
        // training-prep style and the deep aerobic damage from a marathon
        // takes 2-3 weeks to clear (Saugy 2013, Hammerle & Tartaruga 2019).
        [
            (0, rest()),
            (1, easy(scaled(35, mod), "Easy 35 min, conversational.")),
            (2, rest()),
            (3, mod.isEnjoyment ? cross(scaled(30, mod)) : easy(scaled(30, mod), "Easy 30 min. Strides only if no soreness.")),
            (4, rest()),
            (5, easy(scaled(35, mod), "Easy 35 min on flat.")),
            (6, easy(scaled(55, mod), "Easy 50-55 min. By feel only.")),
        ]
    }

    private static func marathonWeek3(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W3 of 3. Pfitz Plan A reverse taper W3: 5 runs at ~70% of peak
        // volume. Last recovery week before normal training resumes.
        // Performance philosophy nudges day 4 slightly longer; enjoyment
        // keeps day 2 as cross-training instead of an extra run.
        [
            (0, rest()),
            (1, easy(scaled(45, mod), "Easy 45 min + 4 strides if legs feel sharp.")),
            (2, mod.isEnjoyment ? cross(scaled(30, mod)) : easy(scaled(35, mod), "Easy 35 min, conversational.")),
            (3, rest()),
            (4, easy(scaled(mod.isPerformance ? 55 : 50, mod), "Easy 50-55 min on flat.")),
            (5, easy(scaled(35, mod), "Easy 35 min, light.")),
            (6, easy(scaled(70, mod), "Easy 65-75 min on flat. Normal training resumes next week.")),
        ]
    }

    // MARK: - Ultra road (50K+, 3 recovery weeks)

    private static func ultraRoadWeek1(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W1 of 3. ~10% of peak. Like marathon W1 but stretched.
        [
            (0, rest("Complete rest.")),
            (1, rest()),
            (2, walk(scaled(25, mod))),
            (3, rest()),
            (4, cross(scaled(30, mod))),
            (5, rest()),
            (6, mod.isAdvanced ? easy(scaled(25, mod), "Optional 25 min very easy jog.") : walk(scaled(25, mod))),
        ]
    }

    private static func ultraRoadWeek2(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W2 of 3. ~35% of peak.
        [
            (0, rest()),
            (1, easy(scaled(30, mod), "Easy 30 min, conversational.")),
            (2, easy(scaled(30, mod), "Easy 30 min.")),
            (3, rest()),
            (4, easy(scaled(35, mod), "Easy 35 min on flat.")),
            (5, rest()),
            (6, easy(scaled(50, mod), "Easy 50 min on flat.")),
        ]
    }

    private static func ultraRoadWeek3(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W3 of 3. ~60% of peak. Near-baseline.
        [
            (0, rest()),
            (1, easy(scaled(40, mod), "Easy 40 min + 4 strides.")),
            (2, easy(scaled(35, mod), "Easy 35 min, conversational.")),
            (3, mod.isPerformance ? easy(scaled(30, mod), "Easy 30 min, performance retains volume.") : rest()),
            (4, easy(scaled(45, mod), "Easy 45 min on flat.")),
            (5, easy(scaled(35, mod), "Easy 35 min, light.")),
            (6, easy(scaled(75, mod), "Easy 70-80 min on flat.")),
        ]
    }

    // MARK: - Helpers

    private static func rest(_ desc: String = "Rest day. Recovery is the work.") -> RecoverySession {
        RecoverySession(type: .rest, intensity: .easy, durationSeconds: 0, description: desc)
    }

    private static func easy(_ minutes: Int, _ desc: String) -> RecoverySession {
        RecoverySession(
            type: .recovery, intensity: .easy,
            durationSeconds: TimeInterval(minutes * 60),
            description: desc
        )
    }

    private static func cross(_ minutes: Int) -> RecoverySession {
        RecoverySession(
            type: .crossTraining, intensity: .easy,
            durationSeconds: TimeInterval(minutes * 60),
            description: "Cross-training \(minutes) min, easy bike, swim, or elliptical. Low-impact aerobic work while running tissue rebuilds."
        )
    }

    private static func walk(_ minutes: Int) -> RecoverySession {
        RecoverySession(
            type: .crossTraining, intensity: .easy,
            durationSeconds: TimeInterval(minutes * 60),
            description: "Walking \(minutes) min, easy. Light movement to promote blood flow."
        )
    }

    /// Same scaling logic as TrailRaceRecoveryTemplates. Clamp to
    /// [0.75, 1.20] so combined modifiers never produce extreme
    /// outputs.
    private static func scaled(_ baseMinutes: Int, _ mod: Modifiers) -> Int {
        var m: Double = 1.0
        if mod.isBeginner   { m *= 0.80 }
        if mod.isAdvanced   { m *= 1.10 }
        if mod.isPerformance { m *= 1.10 }
        if mod.isEnjoyment  { m *= 0.90 }
        let clamped = min(max(m, 0.75), 1.20)
        return max(10, Int(Double(baseMinutes) * clamped))
    }
}
