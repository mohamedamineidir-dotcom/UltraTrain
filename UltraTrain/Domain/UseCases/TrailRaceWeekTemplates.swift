import Foundation

/// Race-week prescriptions for TRAIL / ULTRA races.
///
/// Replaces the generic "last taper week" treatment with a research-backed
/// day-by-day structure that:
/// - Includes the race itself as a `.race` SessionTemplate with the
///   athlete's expected race duration, so weekly volume totals reflect
///   the actual race-day stimulus (often 4-30+ hours for ultras).
/// - Scales the prep shape by race-distance class — a 35K mountain
///   trail race week looks nothing like a 100-miler race week.
/// - Modifies by athlete experience (beginner = more rest, no quality;
///   advanced/elite = optional light quality on Day -5) and philosophy
///   (performance = adds openers Day -2; enjoyment = pure rest dominates).
/// - Modifies by race profile (mountain ultras with high D+ density
///   strip ALL quality and replace running with easy hikes; flat trails
///   tolerate short strides and pickups).
///
/// Sources: Koop *Training Essentials for Ultrarunning* Ch. 11; Roche
/// *The Happy Runner* + Trail Runner columns; Jurek *Eat and Run*;
/// House & Johnston *Training for the Uphill Athlete* Ch. 8-9; Friel
/// ultra adaptations; Mujika & Padilla 2003 (foundational tapering
/// meta-analysis).
enum TrailRaceWeekTemplates {

    static func sessions(
        targetRace: Race,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy,
        weekStartDate: Date,
        preferredRunsPerWeek: Int = 5
    ) -> [SessionTemplateGenerator.SessionTemplate] {
        let raceDayOffset = max(0, min(6, dayOffset(from: weekStartDate, to: targetRace.date)))
        let raceDuration = targetRace.estimatedDuration(experience: experience)
        let raceDesc = makeRaceDescription(targetRace: targetRace)
        let distClass = TrailRaceClass.from(distanceKm: targetRace.distanceKm)

        // D+ density tells us mountain vs flat. ≥40 m/km = mountain
        // (typical UTMB / Hardrock / Madeira class). <20 m/km = flat
        // (Comrades-style trail, jeep-track 100K). In between =
        // moderate.
        let elevDensity = targetRace.distanceKm > 0
            ? targetRace.elevationGainM / targetRace.distanceKm
            : 0
        let isMountain = elevDensity >= 40

        var templates: [SessionTemplateGenerator.SessionTemplate] = []

        let prep = prepShape(
            for: distClass, experience: experience, philosophy: philosophy,
            isMountain: isMountain
        )
        for (daysBefore, session) in prep {
            let day = raceDayOffset - daysBefore
            guard day >= 0 && day <= 6 else { continue }
            templates.append(SessionTemplateGenerator.tpl(
                day, session.type, session.intensity,
                session.durationSeconds, session.elevationFraction, session.description
            ))
        }

        // Race day
        templates.append(SessionTemplateGenerator.tpl(
            raceDayOffset, .race, .maxEffort,
            raceDuration, 1.0, raceDesc
        ))

        // Post-race days (Saturday races leave Sunday open). Guarded
        // so a Sunday race (raceDayOffset == 6) doesn't form an
        // invalid range.
        if raceDayOffset < 6 {
            for day in (raceDayOffset + 1)...6 {
                templates.append(SessionTemplateGenerator.tpl(
                    day, .rest, .easy, 0, 0,
                    "Rest / very easy walk. Race is done — refuel, hydrate, reflect. Recovery starts now."
                ))
            }
        }

        // Unused days = rest
        let usedDays = Set(templates.map(\.dayOffset))
        for day in 0...6 where !usedDays.contains(day) {
            templates.append(SessionTemplateGenerator.tpl(
                day, .rest, .easy, 0, 0,
                "Rest day. Conserve energy for race day."
            ))
        }

        let sorted = templates.sorted { $0.dayOffset < $1.dayOffset }
        return capActivePrep(
            sorted,
            raceDayOffset: raceDayOffset,
            maxActivePrep: maxActivePrepDays(
                distClass: distClass,
                preferredRunsPerWeek: preferredRunsPerWeek,
                experience: experience,
                isMountain: isMountain
            )
        )
    }

    // MARK: - Frequency cap

    /// Max active prep days (excluding race day) allowed in race week.
    /// Koop *TEU* Ch.11: 50-mile and longer race weeks taper to 3-4
    /// active days regardless of normal frequency; 100-mile drops to
    /// 3 active days; multi-day stage races to 2. Race week always runs
    /// fewer sessions than the athlete's normal week. Mountain profiles
    /// drop one extra (descent prep matters more than mileage retention).
    private static func maxActivePrepDays(
        distClass: TrailRaceClass,
        preferredRunsPerWeek: Int,
        experience: ExperienceLevel,
        isMountain: Bool
    ) -> Int {
        // Hard ceiling per distance class.
        let baseCap: Int
        switch distClass {
        case .shortTrail, .fiftyK:               baseCap = 4
        case .fiftyMile, .hundredK, .hundredMile: baseCap = 3
        case .multiDay:                           baseCap = 2
        }
        // Drop count from athlete's normal frequency. Longer races
        // drop two days; shorter trail drops one. Beginner / mountain
        // drop one more for the recovery margin.
        var dropCount: Int
        switch distClass {
        case .shortTrail, .fiftyK:               dropCount = 1
        case .fiftyMile, .hundredK, .hundredMile: dropCount = 2
        case .multiDay:                           dropCount = 2
        }
        if experience == .beginner { dropCount += 1 }
        if isMountain { dropCount += 1 }
        let frequencyCap = preferredRunsPerWeek - dropCount
        return max(2, min(baseCap, frequencyCap))
    }

    /// Demotes lowest-value prep sessions to rest until active-prep
    /// count meets `maxActivePrep`. Race day is never touched. Demote
    /// priority (most preferred to drop first):
    ///   1. Day -4 (mid-week recovery, lowest value)
    ///   2. Day -6 (longer easy — can be cut)
    ///   3. Day -5 (quality / primer)
    ///   4. Day -3 (strides — high value, last resort)
    ///   5. Day -1 (shakeout — never drop)
    private static func capActivePrep(
        _ templates: [SessionTemplateGenerator.SessionTemplate],
        raceDayOffset: Int,
        maxActivePrep: Int
    ) -> [SessionTemplateGenerator.SessionTemplate] {
        var result = templates
        let activeCount = result.filter { $0.type != .rest && $0.type != .race }.count
        guard activeCount > maxActivePrep else { return result }
        var toDemote = activeCount - maxActivePrep

        let demoteOrder: [Int] = [4, 6, 5, 3, 1]
        for daysBefore in demoteOrder where toDemote > 0 {
            let targetDay = raceDayOffset - daysBefore
            guard targetDay >= 0 else { continue }
            if let idx = result.firstIndex(where: {
                $0.dayOffset == targetDay && $0.type != .rest && $0.type != .race
            }) {
                result[idx] = SessionTemplateGenerator.tpl(
                    targetDay, .rest, .easy, 0, 0,
                    "Rest day. Race-week frequency dialed back to keep your legs fresh."
                )
                toDemote -= 1
            }
        }
        return result
    }

    // MARK: - Distance classification

    private enum TrailRaceClass {
        case shortTrail   // < 35 km
        case fiftyK       // 35-60 km
        case fiftyMile    // 60-100 km
        case hundredK     // 100-150 km
        case hundredMile  // 150-220 km
        case multiDay     // 220+ km

        static func from(distanceKm: Double) -> TrailRaceClass {
            switch distanceKm {
            case ..<35:    return .shortTrail
            case ..<60:    return .fiftyK
            case ..<100:   return .fiftyMile
            case ..<150:   return .hundredK
            case ..<220:   return .hundredMile
            default:       return .multiDay
            }
        }
    }

    // MARK: - Prep shape

    private struct PrepSession {
        let type: SessionType
        let intensity: Intensity
        let durationSeconds: TimeInterval
        let elevationFraction: Double
        let description: String
    }

    private static func prepShape(
        for distClass: TrailRaceClass,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy,
        isMountain: Bool
    ) -> [(daysBefore: Int, session: PrepSession)] {
        let isBeginner = experience == .beginner
        let isEliteOrAdvanced = experience == .advanced || experience == .elite
        let isPerformance = philosophy == .performance
        let isEnjoyment = philosophy == .enjoyment

        switch distClass {
        case .shortTrail:
            // Roche-style sub-marathon trail. Day -5 keeps a CV-pace
            // touch on rolling terrain unless mountain. Volume ~60%
            // of peak.
            return [
                (6, easyRun(40, descSuffix: "+ 4 × 100m strides. Aerobic ticking.")),
                (5, isMountain || isBeginner || isEnjoyment
                    ? easyRun(35, descSuffix: "Conversational pace.")
                    : PrepSession(type: .intervals, intensity: .moderate,
                                  durationSeconds: minutes(40),
                                  elevationFraction: 0.3,
                                  description: "4-5 × 3 min at controlled threshold on rolling terrain, 2 min easy between. Specific stimulus — Roche fast-finish mentality.")),
                (4, easyRun(30, descSuffix: "Recovery from yesterday.")),
                (3, easyRun(28, descSuffix: isMountain
                    ? "Easy 25-30 min. No hill strides — keep climbing legs fresh."
                    : "+ 4 × 20s hill strides. Climb prime.")),
                (2, restOrEasy(isBeginner: isBeginner, isEnjoyment: isEnjoyment, easyMin: 20)),
                (1, easyRun(18, descSuffix: isMountain
                    ? "Shakeout 15-20 min on flat. Stay loose."
                    : "Shakeout 15-20 min + 2 × 30s @ race effort uphill. Prime climbing legs.")),
            ]

        case .fiftyK:
            // Koop *TEU* Ch. 11: 50K race week resembles marathon
            // taper. Volume ~55% of peak. Light primer Day -5 only
            // for fit non-mountain athletes.
            return [
                (6, easyRun(55, descSuffix: "+ 4 × 100m strides. Aerobic.")),
                (5, isMountain || isBeginner || isEnjoyment
                    ? easyRun(40, descSuffix: "Conversational pace, light strides at the end.")
                    : isEliteOrAdvanced
                        ? PrepSession(type: .tempo, intensity: .moderate,
                                      durationSeconds: minutes(45),
                                      elevationFraction: 0.2,
                                      description: "30 min easy + 5 × 1 min at threshold or 4 × 30s hill strides. Koop's 'primer' — light sharpening only.")
                        : easyRun(40, descSuffix: "+ 4 × 30s hill strides. Light primer.")),
                (4, easyRun(35, descSuffix: "Recovery, conversational pace.")),
                (3, easyRun(28, descSuffix: "+ 4-6 × 100m strides. CNS prime.")),
                (2, isBeginner || isEnjoyment
                    ? PrepSession(type: .rest, intensity: .easy,
                                  durationSeconds: 0, elevationFraction: 0,
                                  description: "Rest. Mental prep — visualize aid stations, fueling timing.")
                    : easyRun(20, descSuffix: "Easy OR rest if legs feel heavy.")),
                (1, easyRun(20, descSuffix: "Shakeout 20-25 min + 2-3 strides. Prime.")),
            ]

        case .fiftyMile:
            // Koop *TEU* Ch. 11: 50-mile race week. Strides only, no
            // threshold. Volume ~50% of peak.
            return [
                (6, easyRun(55, descSuffix: "+ 4 strides. Last 'real' run before taper deepens.")),
                (5, easyRun(45, descSuffix: isPerformance
                    ? "+ 4 × 1 min at steady on race-specific terrain. Performance philosophy — light primer."
                    : "+ 4 × 30s pickups. Light primer — Koop avoids hard work this close.")),
                (4, isBeginner
                    ? PrepSession(type: .rest, intensity: .easy,
                                  durationSeconds: 0, elevationFraction: 0,
                                  description: "Rest. Beginners prioritize recovery this close to race day.")
                    : easyRun(35, descSuffix: "Conversational pace, recovery.")),
                (3, easyRun(28, descSuffix: "+ 4 strides. Keep legs alive.")),
                (2, PrepSession(type: .rest, intensity: .easy,
                                durationSeconds: 0, elevationFraction: 0,
                                description: "Rest. Glycogen super-compensation, mental prep.")),
                (1, easyRun(18, descSuffix: "Shakeout 15-20 min + 2 strides. Prime.")),
            ]

        case .hundredK:
            // Koop *TEU* Ch. 11 + Roche: 100K race week. Strides only,
            // optional. Volume ~45% of peak. Day -3 is rest for most.
            return [
                (6, easyRun(45, descSuffix: "+ 4 strides. Aerobic ticking.")),
                (5, easyRun(35, descSuffix: "Conversational pace, recovery from peak block.")),
                (4, easyRun(28, descSuffix: "+ 4 strides. Light.")),
                (3, isEliteOrAdvanced && !isMountain && isPerformance
                    ? easyRun(25, descSuffix: "+ 20 min steady-state pickup. Roche allows for elites with high training age.")
                    : PrepSession(type: .rest, intensity: .easy,
                                  durationSeconds: 0, elevationFraction: 0,
                                  description: "Rest or 20 min very easy. Mental + physical reset.")),
                (2, PrepSession(type: .rest, intensity: .easy,
                                durationSeconds: 0, elevationFraction: 0,
                                description: "Rest. Glycogen + travel + headspace.")),
                (1, easyRun(18, descSuffix: "Shakeout 15-20 min + 2 strides. Prime.")),
            ]

        case .hundredMile:
            // Koop *TEU* Ch. 11: 100-mile race week is the lowest
            // volume of any taper. ~35-40% of peak. Strides only,
            // multiple rest days. Jurek emphasizes mental rest.
            return [
                (6, easyRun(35, descSuffix: "+ 4 strides. Last 'real' run before final descent into rest.")),
                (5, easyRun(28, descSuffix: "Conversational. Recovery.")),
                (4, easyRun(22, descSuffix: "+ 4 strides. Light.")),
                (3, PrepSession(type: .rest, intensity: .easy,
                                durationSeconds: 0, elevationFraction: 0,
                                description: "Rest. Travel day for most. Mental reset — Jurek: race-week stillness equals race-day strength.")),
                (2, isPerformance
                    ? easyRun(15, descSuffix: "Shakeout 15-20 min + 2-3 strides. Performance openers — keep CNS engaged.")
                    : PrepSession(type: .rest, intensity: .easy,
                                  durationSeconds: 0, elevationFraction: 0,
                                  description: "Rest. Scout the course mentally. Pack drop bags.")),
                (1, isPerformance
                    ? PrepSession(type: .rest, intensity: .easy,
                                  durationSeconds: 0, elevationFraction: 0,
                                  description: "Rest. Race tomorrow — sleep, hydrate, eat real food, calm the mind.")
                    : easyRun(12, descSuffix: "Optional 10-15 min jog if legs feel locked up. Otherwise rest is fine.")),
            ]

        case .multiDay:
            // Multi-day stage races (UTMB PTL 300K, MDS 250K). Volume
            // ~30-35% of peak. Logistics + heat acclimation dominate.
            // House & Johnston Ch. 9 + Friel ultra writings: "the
            // start line is not a fitness test — get there fresh."
            return [
                (6, easyRun(30, descSuffix: "+ 4 strides. Last short run.")),
                (5, easyRun(25, descSuffix: "Conversational. Easy.")),
                (4, PrepSession(type: .rest, intensity: .easy,
                                durationSeconds: 0, elevationFraction: 0,
                                description: "Rest / travel day. Final gear check.")),
                (3, PrepSession(type: .rest, intensity: .easy,
                                durationSeconds: 0, elevationFraction: 0,
                                description: "Rest. Hydrate, eat, sleep.")),
                (2, easyRun(15, descSuffix: "Optional 15-min jog if legs feel locked up. Otherwise rest.")),
                (1, PrepSession(type: .rest, intensity: .easy,
                                durationSeconds: 0, elevationFraction: 0,
                                description: "Rest. Stage 1 starts tomorrow — pacing strategy beats fitness fine-tuning.")),
            ]
        }
    }

    // MARK: - Helpers

    private static func easyRun(_ minutes: Int, descSuffix: String) -> PrepSession {
        PrepSession(
            type: .recovery, intensity: .easy,
            durationSeconds: TimeInterval(minutes * 60),
            elevationFraction: 0,
            description: "Easy \(minutes) min. \(descSuffix)"
        )
    }

    private static func restOrEasy(isBeginner: Bool, isEnjoyment: Bool, easyMin: Int) -> PrepSession {
        if isBeginner || isEnjoyment {
            return PrepSession(type: .rest, intensity: .easy, durationSeconds: 0,
                               elevationFraction: 0,
                               description: "Rest. Glycogen + freshness.")
        }
        return easyRun(easyMin, descSuffix: "Easy OR rest if legs feel heavy.")
    }

    private static func minutes(_ m: Int) -> TimeInterval { TimeInterval(m * 60) }

    private static func dayOffset(from start: Date, to date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: date).day ?? 0
    }

    private static func makeRaceDescription(targetRace: Race) -> String {
        let dist = targetRace.distanceKm
        let elev = targetRace.elevationGainM
        let distStr = dist >= 100 ? String(format: "%.0f km", dist)
            : String(format: "%.1f km", dist)
        let elevStr = elev > 0 ? " / D+ \(Int(elev))m" : ""
        return "RACE: \(targetRace.name) (\(distStr)\(elevStr)). The journey ends here. Trust your training, fuel like clockwork, manage the climbs, respect the descents. The first half is for patience — the second half is for grit."
    }
}
