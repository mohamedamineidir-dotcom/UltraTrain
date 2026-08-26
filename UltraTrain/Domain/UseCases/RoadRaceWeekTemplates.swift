import Foundation

/// Race-week prescriptions for ROAD races (5K / 10K / HM / Marathon).
///
/// Replaces the generic "last taper week" treatment with a research-backed
/// day-by-day structure that:
/// - Includes the race itself as a `.race` SessionTemplate with the
///   athlete's expected race duration, so weekly volume totals reflect
///   the actual race-day stimulus.
/// - Scales the prep shape by race-distance class, a 5K race week looks
///   nothing like a marathon race week.
/// - Modifies by athlete experience (beginner = less quality, more rest;
///   advanced/elite = full sharpening) and philosophy (performance =
///   keep MP/HMP touch + extra openers; enjoyment = strip quality, more
///   rest days).
///
/// Sources: Pfitzinger *Advanced Marathoning* Ch. 8 + *Faster Road
/// Racing* Ch. 7-9; Daniels *RF* Ch. 9-10, 16; Hudson *Run Faster*;
/// Hansons *Marathon Method* Ch. 9; Magness *Science of Running* Ch. 14;
/// Mujika & Padilla 2003 (*Sports Medicine*) tapering meta-analysis.
enum RoadRaceWeekTemplates {

    /// Builds the 7-day session list for the A-race week. Race day is
    /// placed at the dayOffset corresponding to the actual race date;
    /// prep days fill the slots before; any days after race day in the
    /// same week become very easy / rest. The final template list is
    /// frequency-capped so a 6/wk athlete doesn't end up with 6 active
    /// prep days + race day; race week should run *fewer* sessions than
    /// a normal training week, not the same or more.
    static func sessions(
        targetRace: Race,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy,
        weekStartDate: Date,
        preferredRunsPerWeek: Int = 5,
        // A real fitness-derived estimate (PBs / VMA / index via
        // `FinishTimeEstimator.quickEstimate`), when the caller has an
        // `Athlete` to compute one from. Without it, falls back to the
        // generic experience-level heuristic below — which is only
        // sensible when there's no fitness signal at all (a brand new
        // profile), not as the default for every athlete regardless of
        // what they've logged.
        precomputedRaceDuration: TimeInterval? = nil
    ) -> [SessionTemplateGenerator.SessionTemplate] {
        let raceDayOffset = max(0, min(6, dayOffset(from: weekStartDate, to: targetRace.date)))
        let raceDuration = precomputedRaceDuration ?? targetRace.estimatedDuration(experience: experience)
        let raceDesc = makeRaceDescription(targetRace: targetRace)
        let distClass = RoadRaceClass.from(distanceKm: targetRace.distanceKm)

        var templates: [SessionTemplateGenerator.SessionTemplate] = []

        // Prep days: walk backward from race day. Each entry in the
        // prep shape is keyed by "days before race" (1 = day before, 6 =
        // 6 days before). Slots beyond available days (if race is
        // earlier in the week) are simply not emitted.
        let prep = prepShape(for: distClass, experience: experience, philosophy: philosophy)
        for (daysBefore, session) in prep {
            let day = raceDayOffset - daysBefore
            guard day >= 0 && day <= 6 else { continue }
            templates.append(SessionTemplateGenerator.tpl(
                day, session.type, session.intensity,
                session.durationSeconds, 0, session.description
            ))
        }

        // Race day. Carries the real race distance via the template's
        // distanceKmOverride so the session card reads "10.0 km" instead
        // of the duration ÷ 5:30 derivation (B1).
        templates.append(SessionTemplateGenerator.SessionTemplate(
            dayOffset: raceDayOffset, type: .race, intensity: .maxEffort,
            durationSeconds: raceDuration, elevationFraction: 0,
            description: raceDesc,
            distanceKmOverride: targetRace.distanceKm > 0 ? targetRace.distanceKm : nil
        ))

        // Post-race days within the same week (e.g. Saturday race
        // leaves Sunday as a post-race recovery day). Guarded so a
        // Sunday race (raceDayOffset == 6) doesn't form an invalid
        // range.
        if raceDayOffset < 6 {
            for day in (raceDayOffset + 1)...6 {
                templates.append(SessionTemplateGenerator.tpl(
                    day, .rest, .easy, 0, 0,
                    String(localized: "rwt.restCelebrate", defaultValue: "Rest / very easy walk. Race is done, celebrate, refuel, reflect.")
                ))
            }
        }

        // Any unused slots before the prep window become rest.
        let usedDays = Set(templates.map(\.dayOffset))
        for day in 0...6 where !usedDays.contains(day) {
            templates.append(SessionTemplateGenerator.tpl(
                day, .rest, .easy, 0, 0,
                String(localized: "rwt.restConserve", defaultValue: "Rest day. Conserve energy for race day.")
            ))
        }

        let sorted = templates.sorted { $0.dayOffset < $1.dayOffset }
        return capActivePrep(
            sorted,
            raceDayOffset: raceDayOffset,
            maxActivePrep: maxActivePrepDays(
                distClass: distClass,
                preferredRunsPerWeek: preferredRunsPerWeek,
                experience: experience
            )
        )
    }

    // MARK: - Frequency cap

    /// Max active prep days (excluding race day) allowed in race week.
    /// Pfitzinger *Adv. Marathoning* Plan A: 5 runs Mon-Sat including
    /// race day = 4 prep days. Daniels *RF* Ch.9: 5K race week is
    /// 4 prep + race day. Race week should run fewer sessions than a
    /// normal training week regardless of how many days/week the athlete
    /// usually runs.
    private static func maxActivePrepDays(
        distClass: RoadRaceClass,
        preferredRunsPerWeek: Int,
        experience: ExperienceLevel
    ) -> Int {
        // Hard ceiling regardless of normal frequency.
        let baseCap = 4
        // Drop count: race week always has at least 1 fewer running day
        // than the athlete's normal week.
        let dropCount = experience == .beginner ? 2 : 1
        let frequencyCap = preferredRunsPerWeek - dropCount
        return max(2, min(baseCap, frequencyCap))
    }

    /// Demotes the lowest-value prep sessions to rest until the
    /// active-prep count meets `maxActivePrep`. Race day is never
    /// touched. Demote priority (most preferred to drop first):
    ///   1. Day -4 (mid-week recovery, lowest value)
    ///   2. Day -6 (longer easy, high volume, can be cut)
    ///   3. Day -5 (quality session, drop only when cutting deep)
    ///   4. Day -3 (strides + CNS prime, high value, last resort)
    ///   5. Day -1 (shakeout, never drop)
    private static func capActivePrep(
        _ templates: [SessionTemplateGenerator.SessionTemplate],
        raceDayOffset: Int,
        maxActivePrep: Int
    ) -> [SessionTemplateGenerator.SessionTemplate] {
        var result = templates
        let activeCount = result.filter { $0.type != .rest && $0.type != .race }.count
        guard activeCount > maxActivePrep else { return result }
        var toDemote = activeCount - maxActivePrep

        // daysBefore in demote priority order (lowest value first).
        let demoteOrder: [Int] = [4, 6, 5, 3, 1]
        for daysBefore in demoteOrder where toDemote > 0 {
            let targetDay = raceDayOffset - daysBefore
            guard targetDay >= 0 else { continue }
            if let idx = result.firstIndex(where: {
                $0.dayOffset == targetDay && $0.type != .rest && $0.type != .race
            }) {
                result[idx] = SessionTemplateGenerator.tpl(
                    targetDay, .rest, .easy, 0, 0,
                    String(localized: "rwt.restDialedBack", defaultValue: "Rest day. Race-week frequency dialed back to keep your legs fresh.")
                )
                toDemote -= 1
            }
        }
        return result
    }

    // MARK: - Distance classification

    private enum RoadRaceClass {
        case fiveK     // < 8 km
        case tenK      // 8-15 km
        case halfMarathon // 15-30 km
        case marathon  // 30+ km

        static func from(distanceKm: Double) -> RoadRaceClass {
            switch distanceKm {
            case ..<8:     return .fiveK
            case ..<15:    return .tenK
            case ..<30:    return .halfMarathon
            default:       return .marathon
            }
        }
    }

    // MARK: - Prep shape

    private struct PrepSession {
        let type: SessionType
        let intensity: Intensity
        let durationSeconds: TimeInterval
        let description: String
    }

    /// Returns the prep-day list keyed by "days before race" (1-6).
    /// Beginners drop the quality session and gain a rest day; performance
    /// athletes hold a quality touch; enjoyment athletes rest more.
    private static func prepShape(
        for distClass: RoadRaceClass,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy
    ) -> [(daysBefore: Int, session: PrepSession)] {
        let isBeginner = experience == .beginner
        let isPerformance = philosophy == .performance
        let isEnjoyment = philosophy == .enjoyment

        switch distClass {
        case .fiveK:
            // Pfitzinger *FRR* Ch. 7 + Daniels *RF* Ch. 9. Day -5 is the
            // last race-pace touch (Daniels' R-pace tune-up). Volume
            // ~55% of peak.
            return [
                (6, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(35),
                                description: String(localized: "rwt.strides5kTune", defaultValue: "Easy run + 4 × 100m strides. Aerobic ticking, sharp legs."))),
                (5, qualityOrEasy(
                    isBeginner: isBeginner, isEnjoyment: isEnjoyment,
                    isPerformance: isPerformance,
                    quality: PrepSession(type: .intervals, intensity: .hard,
                                         durationSeconds: minutes(40),
                                         description: String(localized: "rwt.q800", defaultValue: "3-4 × 800m at 5K race pace, 90s rec. Race-pace tune-up, last sharpener.")),
                    fallback: PrepSession(type: .recovery, intensity: .easy,
                                          durationSeconds: minutes(35),
                                          description: String(localized: "rwt.strides", defaultValue: "Easy run + 4 × 100m strides."))
                )),
                (4, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(35),
                                description: String(localized: "rwt.recoveryYesterday", defaultValue: "Easy run, conversational. Recovery from yesterday."))),
                (3, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(25),
                                description: String(localized: "rwt.easy25", defaultValue: "Easy 25 min + 4-6 × 100m strides. Keep CNS firing."))),
                (2, restOrEasy(isBeginner: isBeginner, isEnjoyment: isEnjoyment, easyMin: 20)),
                (1, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(18),
                                description: String(localized: "rwt.shakeout1520", defaultValue: "Shakeout 15-20 min + 2-3 × 100m + 1 × 30s @ goal pace. Prime CNS."))),
            ]

        case .tenK:
            // Pfitzinger *FRR* Ch. 7-8. Volume ~60% of peak. Quality
            // session is 3 × 1km @ 10K pace OR 5 × 600m @ 5K pace.
            return [
                (6, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(45),
                                description: String(localized: "rwt.stridesAerobic", defaultValue: "Easy run + 4 × 100m strides. Aerobic."))),
                (5, qualityOrEasy(
                    isBeginner: isBeginner, isEnjoyment: isEnjoyment,
                    isPerformance: isPerformance,
                    quality: PrepSession(type: .intervals, intensity: .hard,
                                         durationSeconds: minutes(45),
                                         description: String(localized: "rwt.q1km", defaultValue: "3 × 1km at 10K pace, full recovery. Sharpen race rhythm without depletion.")),
                    fallback: PrepSession(type: .recovery, intensity: .easy,
                                          durationSeconds: minutes(40),
                                          description: String(localized: "rwt.strides", defaultValue: "Easy run + 4 × 100m strides."))
                )),
                (4, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(38),
                                description: String(localized: "rwt.recovery", defaultValue: "Easy run, conversational. Recovery."))),
                (3, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(30),
                                description: String(localized: "rwt.easy30", defaultValue: "Easy 30 min + 6 × 100m strides. Neuromuscular."))),
                (2, restOrEasy(isBeginner: isBeginner, isEnjoyment: isEnjoyment, easyMin: 20)),
                (1, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(20),
                                description: String(localized: "rwt.shakeout20_10k", defaultValue: "Shakeout 20 min + 4 × 100m strides + 1 × 200m @ 10K pace. Prime."))),
            ]

        case .halfMarathon:
            // Pfitzinger *FRR* Ch. 9. Volume ~65% of peak. Quality is
            // 3 × 1 mi @ HMP. Friday is rest (glycogen super-comp).
            return [
                (6, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(55),
                                description: String(localized: "rwt.stridesAerobic", defaultValue: "Easy run + 4 × 100m strides. Aerobic."))),
                (5, qualityOrEasy(
                    isBeginner: isBeginner, isEnjoyment: isEnjoyment,
                    isPerformance: isPerformance,
                    quality: PrepSession(type: .intervals, intensity: .moderate,
                                         durationSeconds: minutes(50),
                                         description: String(localized: "rwt.q1mile", defaultValue: "3 × 5 min at half-marathon pace, 90s rec. Dress rehearsal, last quality.")),
                    fallback: PrepSession(type: .recovery, intensity: .easy,
                                          durationSeconds: minutes(45),
                                          description: String(localized: "rwt.strides", defaultValue: "Easy run + 4 × 100m strides."))
                )),
                (4, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(40),
                                description: String(localized: "rwt.recovery", defaultValue: "Easy run, conversational. Recovery."))),
                (3, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(32),
                                description: String(localized: "rwt.easy3035", defaultValue: "Easy 30-35 min + 6 × 100m strides. CNS prime."))),
                (2, PrepSession(type: .rest, intensity: .easy,
                                durationSeconds: 0,
                                description: String(localized: "rwt.restGlycoSuper", defaultValue: "Rest. Glycogen super-compensation begins."))),
                (1, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(22),
                                description: String(localized: "rwt.q200hmp", defaultValue: "20-25 min easy + 2-3 × 200m at HMP. Prime + prevent staleness."))),
            ]

        case .marathon:
            // Pfitzinger *Adv. Marathoning* Ch. 8. Volume ~55% of peak.
            // Day -5 is short MP touch within easy run (Pfitz 'dress
            // rehearsal'). Friday rest (carb-loading peak).
            return [
                (6, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(50),
                                description: String(localized: "rwt.stridesAerobic", defaultValue: "Easy run + 4 × 100m strides. Aerobic."))),
                (5, qualityOrEasy(
                    isBeginner: isBeginner, isEnjoyment: isEnjoyment,
                    isPerformance: isPerformance,
                    quality: PrepSession(type: .tempo, intensity: .moderate,
                                         durationSeconds: minutes(60),
                                         description: String(localized: "rwt.q8mi", defaultValue: "60 min total: 40 min easy + the last 20 min at marathon pace. Dress rehearsal, last MP touch.")),
                    fallback: PrepSession(type: .recovery, intensity: .easy,
                                          durationSeconds: minutes(45),
                                          description: String(localized: "rwt.strides", defaultValue: "Easy run + 4 × 100m strides."))
                )),
                (4, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: isPerformance ? minutes(50) : minutes(40),
                                description: isPerformance
                                    ? String(localized: "rwt.easyPerf", defaultValue: "Easy 50 min. Performance philosophy, preserve aerobic fitness.")
                                    : String(localized: "rwt.recovery", defaultValue: "Easy run, conversational. Recovery."))),
                (3, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(35),
                                description: String(localized: "rwt.easy56glyco", defaultValue: "Easy 35 min + 6 × 100m strides. Glycogen-loading begins."))),
                (2, restOrEasy(isBeginner: false, isEnjoyment: isEnjoyment, easyMin: 25)),
                (1, PrepSession(type: .recovery, intensity: .easy,
                                durationSeconds: minutes(25),
                                description: String(localized: "rwt.shakeout2030", defaultValue: "Shakeout 20-30 min + 4 × 100m strides. Prime, prevent stiffness."))),
            ]
        }
    }

    // MARK: - Helpers

    private static func qualityOrEasy(
        isBeginner: Bool, isEnjoyment: Bool, isPerformance: Bool,
        quality: PrepSession, fallback: PrepSession
    ) -> PrepSession {
        if isBeginner || isEnjoyment { return fallback }
        return quality
    }

    private static func restOrEasy(isBeginner: Bool, isEnjoyment: Bool, easyMin: Int) -> PrepSession {
        if isBeginner || isEnjoyment {
            return PrepSession(type: .rest, intensity: .easy, durationSeconds: 0,
                               description: String(localized: "rwt.restGlycoFresh", defaultValue: "Rest. Glycogen + freshness."))
        }
        return PrepSession(type: .recovery, intensity: .easy,
                           durationSeconds: minutes(easyMin),
                           description: String(localized: "rwt.easyOrRest", defaultValue: "Easy \(easyMin) min OR rest if legs feel heavy. Listen to your body."))
    }

    private static func minutes(_ m: Int) -> TimeInterval { TimeInterval(m * 60) }

    private static func dayOffset(from start: Date, to date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: date).day ?? 0
    }

    private static func makeRaceDescription(targetRace: Race) -> String {
        let dist = targetRace.distanceKm
        let distStr = dist >= 100 ? String(format: "%.0f km", dist)
            : dist >= 10 ? String(format: "%.1f km", dist)
            : String(format: "%.1f km", dist)
        return String(localized: "rwt.raceDay", defaultValue: "RACE: \(targetRace.name) (\(distStr)). Execute your plan. Trust your fitness. Pace the first 25%, hold through 50%, race the last half.")
    }
}
