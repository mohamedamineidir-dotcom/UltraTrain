import Foundation

/// Post-race recovery prescriptions for TRAIL / ULTRA races.
///
/// Replaces the generic `recoveryTemplates` shape for the weeks AFTER
/// the A-race with a research-backed, day-by-day structure that:
///
/// - Scales by race distance class (short trail → multi-day) so a 35K
///   recovery week looks nothing like a 100-miler recovery week.
/// - Detects mountain races (D+ density ≥ 40 m/km) and prescribes
///   cross-training (bike) over running for the first two weeks
///   because eccentric quad damage, not aerobic fitness, is the
///   limiter at UTMB / Hardrock / Madeira-class events.
/// - Strips ALL hill / vertical-gain work for the first three weeks
///   (House & Johnston). Recovery sessions are flat or rolling only.
/// - Modifies by athlete experience (beginner = more rest days, less
///   running; advanced/elite = slightly faster return) and philosophy
///   (performance = small bump in late-recovery volume; enjoyment =
///   replaces some easy runs with walk / bike, more rest).
/// - Drops total weekly volume substantially vs the in-plan recovery
///   templates: post-race week 1 of a 100-miler is ~5% of peak (mostly
///   rest), not the 60-70% the in-plan recovery template aims at.
///
/// Sources:
/// - Koop, *Training Essentials for Ultrarunning* Ch. 12, recovery
///   from 50K, 100K, 100mi (the most-cited source for ultra recovery)
/// - Roche, *The Happy Runner* + Trail Runner columns, "can you run
///   without limping" gate, no HR / pace targets for two weeks
/// - Jurek, *Eat and Run*, 100mi recovery (4 weeks of walk / swim /
///   bike before structured running resumes)
/// - House & Johnston, *Training for the Uphill Athlete* Ch. 12
///   mountain-race eccentric damage, cross-training mandate, no hill
///   running for three weeks
/// - Comrades coaching consensus, 90K reverse-taper recovery
/// - Friel ultra writings, cross-training is preferred over running
///   for the first 7-10 days of long-ultra recovery
enum TrailRaceRecoveryTemplates {

    // MARK: - Public API

    static func sessions(
        targetRace: Race,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy,
        weekStartDate: Date,
        weekInRecovery: Int  // 1-based: 1, 2, 3, 4, 5
    ) -> [SessionTemplateGenerator.SessionTemplate] {
        let distClass = TrailRaceClass.from(distanceKm: targetRace.distanceKm)
        let elevDensity = targetRace.distanceKm > 0
            ? targetRace.elevationGainM / targetRace.distanceKm
            : 0
        let isMountain = elevDensity >= 40

        let mod = Modifiers(
            isBeginner: experience == .beginner,
            isAdvanced: experience == .advanced || experience == .elite,
            isPerformance: philosophy == .performance,
            isEnjoyment: philosophy == .enjoyment,
            isMountain: isMountain
        )

        let shape = recoveryShape(
            for: distClass,
            weekInRecovery: weekInRecovery,
            mod: mod
        )

        // Convert to SessionTemplate. elevation = 0, no hill running
        // during recovery.
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
                String(localized: "trrt.050", defaultValue: "Rest day. Recovery is the work.")
            ))
        }
        return result.sorted { $0.dayOffset < $1.dayOffset }
    }

    // MARK: - Distance class

    private enum TrailRaceClass {
        case shortTrail   // < 35 km
        case fiftyK       // 35-60 km
        case fiftyMile    // 60-100 km
        case hundredK     // 100-150 km
        case hundredMile  // 150-220 km
        case multiDay     // 220+ km

        static func from(distanceKm: Double) -> TrailRaceClass {
            switch distanceKm {
            case ..<35:  return .shortTrail
            case ..<60:  return .fiftyK
            case ..<100: return .fiftyMile
            case ..<150: return .hundredK
            case ..<220: return .hundredMile
            default:     return .multiDay
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
        let isMountain: Bool
    }

    // MARK: - Shape dispatch

    private static func recoveryShape(
        for distClass: TrailRaceClass,
        weekInRecovery: Int,
        mod: Modifiers
    ) -> [(day: Int, session: RecoverySession)] {
        // Defensive: clamp anything beyond expected range to the deepest
        // / closest-to-baseline shape for that class.
        switch (distClass, weekInRecovery) {
        case (.shortTrail, _):     return shortTrailWeek1(mod)

        case (.fiftyK, 1):         return fiftyKWeek1(mod)
        case (.fiftyK, _):         return fiftyKWeek2(mod)

        case (.fiftyMile, 1):      return fiftyMileWeek1(mod)
        case (.fiftyMile, 2):      return fiftyMileWeek2(mod)
        case (.fiftyMile, _):      return fiftyMileWeek3(mod)

        case (.hundredK, 1):       return hundredKWeek1(mod)
        case (.hundredK, 2):       return hundredKWeek2(mod)
        case (.hundredK, 3):       return hundredKWeek3(mod)
        case (.hundredK, _):       return hundredKWeek4(mod)

        case (.hundredMile, 1):    return hundredMileWeek1(mod)
        case (.hundredMile, 2):    return hundredMileWeek2(mod)
        case (.hundredMile, 3):    return hundredMileWeek3(mod)
        case (.hundredMile, 4):    return hundredMileWeek4(mod)
        case (.hundredMile, _):    return hundredMileWeek5(mod)

        case (.multiDay, 1):       return multiDayWeek1(mod)
        case (.multiDay, 2):       return multiDayWeek2(mod)
        case (.multiDay, 3):       return hundredMileWeek3(mod)
        case (.multiDay, 4):       return hundredMileWeek4(mod)
        case (.multiDay, _):       return hundredMileWeek5(mod)
        }
    }

    // MARK: - Short trail (<35K)

    private static func shortTrailWeek1(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // 1 recovery week. ~50% of normal training volume. Easy return
        // to running, optional cross-training only for mountain races
        // or enjoyment philosophy.
        [
            (0, rest()),
            (1, easy(scaled(30, mod), String(localized: "trrt.015", defaultValue: "Easy 30 min on flat. Shake out race effort."))),
            (2, mod.isMountain
                ? cross(scaled(30, mod))
                : (mod.isBeginner ? rest(String(localized: "trrt.052", defaultValue: "Rest. Take an extra easy day.")) : easy(scaled(35, mod), String(localized: "trrt.024", defaultValue: "Easy 35 min, conversational pace.")))),
            (3, easy(scaled(35, mod), String(localized: "trrt.027", defaultValue: "Easy 35-40 min on flat or rolling."))),
            (4, rest()),
            (5, easy(scaled(50, mod), String(localized: "trrt.038", defaultValue: "Easy 45-50 min on flat. Strides only if you feel sharp."))),
            (6, mod.isEnjoyment ? walk(30) : rest()),
        ]
    }

    // MARK: - 50K (35-60K)

    private static func fiftyKWeek1(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W1 of 2. ~25% of peak. 1-2 active days, 1 cross-training,
        // 4-5 rest days.
        [
            (0, rest()),
            (1, mod.isBeginner ? rest(String(localized: "trrt.051", defaultValue: "Rest. Body still rebuilding from race.")) : walk(scaled(25, mod))),
            (2, rest()),
            (3, mod.isMountain ? cross(scaled(30, mod)) : easy(scaled(25, mod), String(localized: "trrt.008", defaultValue: "Easy 25 min on flat. Run-walk if legs feel heavy."))),
            (4, rest()),
            (5, easy(scaled(35, mod), String(localized: "trrt.021", defaultValue: "Easy 30-40 min on flat. Conversational pace only."))),
            (6, rest()),
        ]
    }

    private static func fiftyKWeek2(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W2 of 2. ~50% of peak. Gradual return to easy training.
        [
            (0, rest()),
            (1, easy(scaled(35, mod), String(localized: "trrt.025", defaultValue: "Easy 35 min, conversational."))),
            (2, mod.isMountain ? cross(scaled(35, mod)) : easy(scaled(30, mod), String(localized: "trrt.013", defaultValue: "Easy 30 min + 4 strides if no soreness."))),
            (3, rest()),
            (4, easy(scaled(40, mod), String(localized: "trrt.029", defaultValue: "Easy 40 min on flat or rolling."))),
            (5, easy(scaled(35, mod), String(localized: "trrt.026", defaultValue: "Easy 35 min, light."))),
            (6, easy(scaled(60, mod), String(localized: "trrt.044", defaultValue: "Easy 60 min on flat. No pace targets."))),
        ]
    }

    // MARK: - 50-mile (60-100K)

    private static func fiftyMileWeek1(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W1 of 3. ~15% of peak. Mostly rest. Cross-training over
        // running because of cumulative quad/calf damage.
        [
            (0, rest(String(localized: "trrt.001", defaultValue: "Complete rest. Massage, sleep, eat."))),
            (1, walk(scaled(30, mod))),
            (2, rest()),
            (3, cross(scaled(30, mod))),
            (4, rest()),
            (5, mod.isAdvanced ? easy(scaled(25, mod), String(localized: "trrt.010", defaultValue: "Easy 25-30 min jog (run-walk if needed). Skip if you're limping.")) : walk(scaled(30, mod))),
            (6, rest()),
        ]
    }

    private static func fiftyMileWeek2(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W2 of 3. ~40% of peak. Building back, still cross-training.
        [
            (0, rest()),
            (1, easy(scaled(30, mod), String(localized: "trrt.014", defaultValue: "Easy 30 min on flat. First 'real' run since the race."))),
            (2, mod.isMountain || mod.isEnjoyment ? cross(scaled(30, mod)) : easy(scaled(30, mod), String(localized: "trrt.017", defaultValue: "Easy 30 min, conversational."))),
            (3, rest()),
            (4, easy(scaled(40, mod), String(localized: "trrt.030", defaultValue: "Easy 40 min on flat. Pace by feel only."))),
            (5, easy(scaled(30, mod), String(localized: "trrt.013", defaultValue: "Easy 30 min + 4 strides if no soreness."))),
            (6, easy(scaled(50, mod), String(localized: "trrt.040", defaultValue: "Easy 50 min on flat or rolling."))),
        ]
    }

    private static func fiftyMileWeek3(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W3 of 3. ~65% of peak. Near-baseline easy training.
        [
            (0, rest()),
            (1, easy(scaled(40, mod), String(localized: "trrt.028", defaultValue: "Easy 40 min + 4 strides."))),
            (2, easy(scaled(35, mod), String(localized: "trrt.025", defaultValue: "Easy 35 min, conversational."))),
            (3, mod.isPerformance ? easy(scaled(30, mod), String(localized: "trrt.019", defaultValue: "Easy 30 min, performance philosophy retains volume.")) : rest()),
            (4, easy(scaled(45, mod), String(localized: "trrt.036", defaultValue: "Easy 45 min on flat or rolling."))),
            (5, easy(scaled(30, mod), String(localized: "trrt.018", defaultValue: "Easy 30 min, light."))),
            (6, easy(scaled(75, mod), String(localized: "trrt.045", defaultValue: "Easy 70-80 min on flat. No vertical work yet."))),
        ]
    }

    // MARK: - 100K (100-150K)

    private static func hundredKWeek1(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W1 of 4. ~10% of peak. Almost full rest. Cross-training only
        // if athlete has the energy.
        [
            (0, rest(String(localized: "trrt.003", defaultValue: "Complete rest. The race is in your legs, let it dissipate."))),
            (1, rest()),
            (2, mod.isBeginner ? rest() : walk(scaled(30, mod))),
            (3, rest()),
            (4, cross(scaled(30, mod))),
            (5, mod.isAdvanced && !mod.isMountain ? easy(scaled(20, mod), String(localized: "trrt.049", defaultValue: "Optional 20 min very easy jog. Skip if anything hurts.")) : walk(scaled(25, mod))),
            (6, rest()),
        ]
    }

    private static func hundredKWeek2(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W2 of 4. ~30% of peak. Running returns gradually.
        [
            (0, rest()),
            (1, easy(scaled(25, mod), String(localized: "trrt.006", defaultValue: "Easy 25 min jog (run-walk acceptable). Pace by feel."))),
            (2, mod.isMountain ? cross(scaled(35, mod)) : easy(scaled(30, mod), String(localized: "trrt.017", defaultValue: "Easy 30 min, conversational."))),
            (3, rest()),
            (4, easy(scaled(35, mod), String(localized: "trrt.023", defaultValue: "Easy 35 min on flat."))),
            (5, mod.isPerformance ? easy(scaled(25, mod), String(localized: "trrt.009", defaultValue: "Easy 25 min, light, performance retains some volume.")) : rest()),
            (6, easy(scaled(45, mod), String(localized: "trrt.037", defaultValue: "Easy 45 min, conversational."))),
        ]
    }

    private static func hundredKWeek3(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W3 of 4. ~50% of peak. Return to standard easy week shape.
        [
            (0, rest()),
            (1, easy(scaled(35, mod), String(localized: "trrt.023", defaultValue: "Easy 35 min on flat."))),
            (2, easy(scaled(30, mod), String(localized: "trrt.011", defaultValue: "Easy 30 min + 4 strides if legs are clean."))),
            (3, rest()),
            (4, easy(scaled(40, mod), String(localized: "trrt.033", defaultValue: "Easy 40 min, conversational."))),
            (5, easy(scaled(30, mod), String(localized: "trrt.018", defaultValue: "Easy 30 min, light."))),
            (6, easy(scaled(60, mod), String(localized: "trrt.043", defaultValue: "Easy 60 min on flat or rolling."))),
        ]
    }

    private static func hundredKWeek4(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W4 of 4. ~65% of peak. Near-baseline. Hill running can
        // resume after this week (next plan or A-race-window close).
        [
            (0, rest()),
            (1, easy(scaled(45, mod), String(localized: "trrt.035", defaultValue: "Easy 45 min + 4 strides."))),
            (2, easy(scaled(35, mod), String(localized: "trrt.025", defaultValue: "Easy 35 min, conversational."))),
            (3, mod.isPerformance ? easy(scaled(30, mod), String(localized: "trrt.020", defaultValue: "Easy 30 min, performance retains volume.")) : rest()),
            (4, easy(scaled(50, mod), String(localized: "trrt.039", defaultValue: "Easy 50 min on flat or gentle rolling."))),
            (5, easy(scaled(40, mod), String(localized: "trrt.034", defaultValue: "Easy 40 min, light."))),
            (6, easy(scaled(85, mod), String(localized: "trrt.047", defaultValue: "Easy 75-90 min. First longer run, flat or rolling, no big climbs."))),
        ]
    }

    // MARK: - 100-mile (150-220K)

    private static func hundredMileWeek1(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W1 of 5. ~5% of peak. ALL rest or walking, Koop/Jurek
        // consensus: zero structured exercise after 100mi for 5-7 days.
        [
            (0, rest(String(localized: "trrt.005", defaultValue: "Complete rest. You finished a 100. Sleep, eat, hydrate."))),
            (1, rest(String(localized: "trrt.002", defaultValue: "Complete rest. Nutrition and sleep are the only training."))),
            (2, rest()),
            (3, walk(20)),
            (4, rest()),
            (5, mod.isPerformance ? walk(scaled(25, mod)) : rest()),
            (6, rest()),
        ]
    }

    private static func hundredMileWeek2(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W2 of 5. ~10-15% of peak. Cross-training over running.
        [
            (0, rest()),
            (1, walk(scaled(25, mod))),
            (2, rest()),
            (3, cross(scaled(30, mod))),
            (4, rest()),
            (5, mod.isAdvanced && !mod.isMountain
                ? easy(scaled(20, mod), String(localized: "trrt.048", defaultValue: "Optional 20 min very easy jog. First run since the race, pace by feel, walk if needed."))
                : walk(scaled(25, mod))),
            (6, rest()),
        ]
    }

    private static func hundredMileWeek3(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W3 of 5. ~25% of peak. Easy running returns.
        [
            (0, rest()),
            (1, easy(scaled(25, mod), String(localized: "trrt.007", defaultValue: "Easy 25 min jog. Run-walk if needed."))),
            (2, mod.isMountain ? cross(scaled(30, mod)) : easy(scaled(30, mod), String(localized: "trrt.017", defaultValue: "Easy 30 min, conversational."))),
            (3, rest()),
            (4, easy(scaled(30, mod), String(localized: "trrt.016", defaultValue: "Easy 30 min on flat."))),
            (5, rest()),
            (6, easy(scaled(40, mod), String(localized: "trrt.032", defaultValue: "Easy 40 min, conversational pace only."))),
        ]
    }

    private static func hundredMileWeek4(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W4 of 5. ~45% of peak.
        [
            (0, rest()),
            (1, easy(scaled(35, mod), String(localized: "trrt.025", defaultValue: "Easy 35 min, conversational."))),
            (2, easy(scaled(30, mod), String(localized: "trrt.012", defaultValue: "Easy 30 min + 4 strides if legs feel sharp."))),
            (3, mod.isPerformance ? easy(scaled(30, mod), String(localized: "trrt.020", defaultValue: "Easy 30 min, performance retains volume.")) : rest()),
            (4, easy(scaled(40, mod), String(localized: "trrt.031", defaultValue: "Easy 40 min on flat."))),
            (5, easy(scaled(30, mod), String(localized: "trrt.018", defaultValue: "Easy 30 min, light."))),
            (6, easy(scaled(60, mod), String(localized: "trrt.042", defaultValue: "Easy 50-60 min on flat or rolling."))),
        ]
    }

    private static func hundredMileWeek5(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W5 of 5. ~65% of peak. Near-baseline.
        [
            (0, rest()),
            (1, easy(scaled(50, mod), String(localized: "trrt.041", defaultValue: "Easy 50 min, conversational."))),
            (2, easy(scaled(35, mod), String(localized: "trrt.022", defaultValue: "Easy 35 min + 6 strides."))),
            (3, rest()),
            (4, easy(scaled(45, mod), String(localized: "trrt.036", defaultValue: "Easy 45 min on flat or rolling."))),
            (5, easy(scaled(40, mod), String(localized: "trrt.033", defaultValue: "Easy 40 min, conversational."))),
            (6, easy(scaled(85, mod), String(localized: "trrt.046", defaultValue: "Easy 70-90 min. Flat or gentle rolling, no big climbs."))),
        ]
    }

    // MARK: - Multi-day (220+ km)

    private static func multiDayWeek1(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W1 of 5. ~3% of peak. Pure rest. Multi-day stage races
        // (PTL, MDS) deplete glycogen, sleep, and tissue more than any
        // other category, recovery is measured in weeks, not days.
        [
            (0, rest(String(localized: "trrt.004", defaultValue: "Complete rest. Walk only if you feel like it."))),
            (1, rest()),
            (2, rest()),
            (3, walk(15)),
            (4, rest()),
            (5, rest()),
            (6, rest()),
        ]
    }

    private static func multiDayWeek2(_ mod: Modifiers) -> [(Int, RecoverySession)] {
        // W2 of 5. ~8% of peak. Mostly rest. One easy walk + one
        // short cross-training.
        [
            (0, rest()),
            (1, walk(scaled(25, mod))),
            (2, rest()),
            (3, cross(scaled(25, mod))),
            (4, rest()),
            (5, rest()),
            (6, walk(scaled(30, mod))),
        ]
    }

    // MARK: - Helpers

    private static func rest(_ desc: String = String(localized: "trrt.050", defaultValue: "Rest day. Recovery is the work.")) -> RecoverySession {
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
            description: String(localized: "trrt.cross", defaultValue: "Cross-training \(minutes) min, easy bike, swim, or elliptical. Concentric only, no eccentric loading. Promotes blood flow without re-damaging quads.")
        )
    }

    private static func walk(_ minutes: Int) -> RecoverySession {
        RecoverySession(
            type: .crossTraining, intensity: .easy,
            durationSeconds: TimeInterval(minutes * 60),
            description: String(localized: "trrt.walk", defaultValue: "Walking \(minutes) min, easy. Light movement, no impact. If you have stairs at home, take them, gentle eccentric reload helps quads remap.")
        )
    }

    /// Scales a baseline duration by experience + philosophy. Range
    /// clamped to [0.75, 1.20] so no combination produces extreme
    /// outputs. Beginners and enjoyment athletes shrink; advanced /
    /// elite + performance bumps slightly.
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
