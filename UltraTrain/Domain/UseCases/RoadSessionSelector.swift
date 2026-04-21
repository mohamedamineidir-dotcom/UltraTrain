import Foundation

/// Selects and arranges training sessions for road race weeks.
///
/// Implements hard/easy alternation (Daniels) with phase-appropriate quality selection.
/// No VG sessions for road plans — replaced by progression runs.
/// No B2B weeks — single long run on Saturday.
///
/// Quality session allocation by runs/week (Daniels, Pfitzinger):
/// - 3/week: 1 quality + 1 long run + 1 easy
/// - 4/week: 2 quality + 1 long run + 1 easy
/// - 5/week: 2 quality + 1 long run + 2 easy (strides in 1 easy)
/// - 6/week: 2-3 quality + 1 long run + 2-3 easy (Pfitzinger medium-long for marathon)
/// - 7/week: 3 quality + 1 long run + 3 easy
enum RoadSessionSelector {

    /// Context for athlete-specific personalization.
    struct AthleteContext: Sendable {
        let philosophy: TrainingPhilosophy
        let hasRecentInjury: Bool
        let painFrequency: PainFrequency
        let age: Int
        let weightGoal: WeightGoal
        let raceName: String?
    }

    /// Generates a full 7-day session template array for a road training week.
    static func sessions(
        phase: TrainingPhase,
        volume: VolumeCalculator.WeekVolume,
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel,
        weekInPhase: Int,
        preferredRunsPerWeek: Int,
        isRecoveryWeek: Bool,
        paceProfile: RoadPaceProfile?,
        athleteContext: AthleteContext? = nil
    ) -> [SessionTemplateGenerator.SessionTemplate] {
        let tpl = SessionTemplateGenerator.tpl
        let base = volume.baseSessionDurations
        let longRunDuration = volume.targetLongRunDurationSeconds

        // Recovery weeks: keep 1 reduced quality session (Pfitzinger/Daniels).
        // Research: road recovery should preserve intensity while cutting volume
        // ~15-20%. Stripping all quality creates a "shutdown week" that loses
        // fitness and feels like a totally different week structure.
        if isRecoveryWeek {
            return recoveryWeekSessions(
                base: base,
                longRunDuration: longRunDuration,
                preferredRunsPerWeek: preferredRunsPerWeek,
                phase: phase,
                discipline: discipline,
                experience: experience,
                weekInPhase: weekInPhase,
                paceProfile: paceProfile,
                tpl: tpl
            )
        }

        // #3: Injury gating — no VO2max/maxEffort for injured athletes
        // Threshold-only base for athletes with frequent pain
        let injuryGatedCategory: RoadIntervalLibrary.Category?
        if athleteContext?.hasRecentInjury == true {
            injuryGatedCategory = .vo2max // Exclude all VO2max work
        } else if athleteContext?.painFrequency == .often {
            injuryGatedCategory = phase == .base ? .vo2max : nil // Base: threshold only
        } else {
            injuryGatedCategory = nil
        }

        // Issue #4: Goal realism gating — ambitious goals restrict race-pace usage
        // Daniels: don't prescribe paces the athlete can't physiologically sustain
        let gateRaceSpecific: Bool
        if let realism = paceProfile?.goalRealismLevel {
            switch realism {
            case .realistic:
                gateRaceSpecific = false // Use race pace freely in peak
            case .ambitious:
                // Only allow race-specific in final 40% of peak phase
                let phaseProgress = Double(weekInPhase) / max(Double(weekInPhase + 2), 1.0)
                gateRaceSpecific = phase == .peak && phaseProgress < 0.60
            case .veryAmbitious:
                // Never use race-specific — use fitness-derived paces only
                gateRaceSpecific = true
            }
        } else {
            gateRaceSpecific = false
        }

        let excludeForRealism: RoadIntervalLibrary.Category? = gateRaceSpecific ? .raceSpecific : nil
        // Combine injury + realism exclusions
        let primaryExclusion = injuryGatedCategory ?? excludeForRealism

        // Select quality session templates from the library
        let q1 = RoadIntervalLibrary.selectForSlot(
            slotIndex: 0, phase: phase, discipline: discipline,
            experience: experience, weekInPhase: weekInPhase,
            excludeCategory: primaryExclusion
        )
        let q2 = RoadIntervalLibrary.selectForSlot(
            slotIndex: 1, phase: phase, discipline: discipline,
            experience: experience, weekInPhase: weekInPhase,
            excludeCategory: q1?.category ?? primaryExclusion
        )

        // Quality session intensities
        let q1Intensity: Intensity = q1?.targetPaceZone == .repetition ? .maxEffort : .hard
        let q2Intensity: Intensity = q2?.targetPaceZone == .easy ? .moderate : .hard

        // #1: Philosophy-based duration scaling
        // Enjoyment: +15% easy, -10% quality. Performance: -10% easy, +10% quality.
        let philEasyScale: Double
        let philQualityScale: Double
        switch athleteContext?.philosophy ?? .balanced {
        case .enjoyment:    philEasyScale = 1.15; philQualityScale = 0.90
        case .balanced:     philEasyScale = 1.00; philQualityScale = 1.00
        case .performance:  philEasyScale = 0.90; philQualityScale = 1.10
        }

        // #2: Runs/week intensity scaling (Canova: fewer sessions = higher intensity per session)
        let runsIntensityScale: Double = switch preferredRunsPerWeek {
        case ...3:  1.15  // 3 runs: +15% quality duration (harder per session)
        case 4:     1.08  // 4 runs: +8%
        case 5:     1.00  // 5 runs: baseline
        case 6:     0.95  // 6 runs: slightly easier per session
        default:    0.90  // 7 runs: more distributed
        }

        // Apply scaling to session durations
        let scaledEasy1 = base.easyRun1Seconds * philEasyScale
        let scaledEasy2 = base.easyRun2Seconds * philEasyScale
        let scaledInterval = base.intervalSeconds * philQualityScale * runsIntensityScale
        let scaledTempo = base.vgSeconds * philQualityScale * runsIntensityScale

        // Build the session pool (priority order: long run > quality > easy)
        // Day layout: Mon=0(rest/easy) Tue=1(quality1) Wed=2(easy) Thu=3(quality2) Fri=4(easy) Sat=5(long) Sun=6(rest)
        let longRunDesc = longRunDescription(phase: phase, weekInPhase: weekInPhase, discipline: discipline, experience: experience)
        let longRunElev: Double = 0 // Road: no elevation

        // SHORT descriptions — rep format like trail plan display
        let easyPace: String
        if let p = paceProfile {
            let fast = RoadCoachAdviceGenerator.formatPace(p.easyPacePerKm.lowerBound)
            let slow = RoadCoachAdviceGenerator.formatPace(p.easyPacePerKm.upperBound)
            easyPace = "\(fast)-\(slow)/km"
        } else {
            easyPace = "conversational pace"
        }

        let q1Desc: String
        if let t = q1, let p = paceProfile {
            let pace = RoadCoachAdviceGenerator.formatPace(paceForZone(t.targetPaceZone, profile: p))
            if t.repDistanceM > 0 {
                q1Desc = "\(t.name) — \(t.repCount)×\(t.repDistanceM)m @ \(pace)/km"
            } else {
                q1Desc = "\(t.name) @ \(pace)/km"
            }
        } else {
            q1Desc = q1?.name ?? "Intervals"
        }

        let q2Desc: String
        if let t = q2, let p = paceProfile {
            let pace = RoadCoachAdviceGenerator.formatPace(paceForZone(t.targetPaceZone, profile: p))
            if t.repDistanceM > 0 {
                q2Desc = "\(t.name) — \(t.repCount)×\(t.repDistanceM)m @ \(pace)/km"
            } else {
                q2Desc = "\(t.name) @ \(pace)/km"
            }
        } else {
            q2Desc = q2?.name ?? "Tempo"
        }

        var pool: [(day: Int, template: SessionTemplateGenerator.SessionTemplate)] = [
            (5, tpl(5, .longRun, .easy, longRunDuration, longRunElev, longRunDesc)),
            (1, tpl(1, .intervals, q1Intensity, scaledInterval, 0, q1Desc)),
            (3, tpl(3, .tempo, q2Intensity, scaledTempo, 0, q2Desc)),
            (0, tpl(0, .recovery, .easy, scaledEasy1, 0,
                    "Easy run @ \(easyPace)")),
            (4, tpl(4, .recovery, .easy, scaledEasy2, 0,
                    "Easy run @ \(easyPace)")),
            (2, tpl(2, .recovery, .easy, scaledEasy1, 0,
                    "Recovery run @ \(easyPace)")),
            (6, tpl(6, .recovery, .easy, scaledEasy2, 0,
                    "Easy run @ \(easyPace)")),
        ]

        // For 6+ runs/week marathon plans: convert day 2 easy to medium-long (Pfitzinger)
        if preferredRunsPerWeek >= 6 && discipline == .roadMarathon && phase != .base {
            let medLongDuration = longRunDuration * 0.75
            pool[5] = (2, tpl(2, .recovery, .easy, medLongDuration, 0,
                    "Medium-long run. Pfitzinger aerobic builder. Easy-moderate pace."))
        }

        // Take only the number of active sessions the user wants
        let activeCount = min(preferredRunsPerWeek, pool.count)
        let activeSlots = pool.prefix(activeCount)

        // Build full 7-day week: active sessions + rest days
        var templates: [SessionTemplateGenerator.SessionTemplate] = []
        for day in 0...6 {
            if let slot = activeSlots.first(where: { $0.day == day }) {
                templates.append(slot.template)
            } else {
                templates.append(tpl(day, .rest, .easy, 0, 0, "Rest day."))
            }
        }
        return templates
    }

    // MARK: - Recovery Week

    private static func recoveryWeekSessions(
        base: VolumeCalculator.BaseSessionDurations,
        longRunDuration: TimeInterval,
        preferredRunsPerWeek: Int,
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel,
        weekInPhase: Int,
        paceProfile: RoadPaceProfile?,
        tpl: (Int, SessionType, Intensity, TimeInterval, Double, String) -> SessionTemplateGenerator.SessionTemplate
    ) -> [SessionTemplateGenerator.SessionTemplate] {
        // Recovery week retains the SAME session count as a normal week but
        // swaps the two-quality layout for a one-quality layout:
        //   - 1 reduced tempo/threshold session (threshold preferred — lower
        //     CNS load than VO2max; Pfitzinger 18/55 recovery weeks)
        //   - 1 easy long run (already reduced by RoadVolumeCalculator)
        //   - Remaining easy runs (also already reduced via base durations)
        //
        // This keeps the weekly "shape" close to the prior week and avoids the
        // fitness-losing shutdown feel.

        // Pick a threshold-preferred template from the library for this slot.
        // Threshold templates exist across all phases and are the safest
        // quality to preserve during recovery.
        let quality = RoadIntervalLibrary.selectForSlot(
            slotIndex: 1, // slot 1 biases toward threshold in most phase prefs
            phase: phase,
            discipline: discipline,
            experience: experience,
            weekInPhase: weekInPhase,
            excludeCategory: .vo2max // exclude hard VO2max on recovery week
        )

        // Quality duration: base.vgSeconds (tempo slot in road plans) is
        // already cut by RoadVolumeCalculator's recovery multiplier (~0.85).
        // Keep it as-is; no extra reduction to avoid double-cutting.
        let qualityDuration = base.vgSeconds
        let qualityIntensity: Intensity = .hard

        // Build quality description with pace where available.
        let qualityDesc: String
        if let t = quality, let p = paceProfile {
            let pace = RoadCoachAdviceGenerator.formatPace(paceForZone(t.targetPaceZone, profile: p))
            if t.repDistanceM > 0 {
                qualityDesc = "\(t.name) — \(t.repCount)×\(t.repDistanceM)m @ \(pace)/km (recovery week — reduced volume)"
            } else {
                qualityDesc = "\(t.name) @ \(pace)/km (recovery week — reduced volume)"
            }
        } else {
            qualityDesc = "Tempo run — reduced volume (recovery week)"
        }

        let easyPace: String
        if let p = paceProfile {
            let fast = RoadCoachAdviceGenerator.formatPace(p.easyPacePerKm.lowerBound)
            let slow = RoadCoachAdviceGenerator.formatPace(p.easyPacePerKm.upperBound)
            easyPace = "\(fast)-\(slow)/km"
        } else {
            easyPace = "conversational pace"
        }

        // Mirror normal-week layout (Mon=0, Tue=1 quality, Wed=2 easy,
        // Thu=3 easy, Fri=4 easy, Sat=5 long, Sun=6 rest) with only 1 quality
        // on Thursday (mid-week) to keep the week's rhythm.
        let pool: [(day: Int, template: SessionTemplateGenerator.SessionTemplate)] = [
            (5, tpl(5, .longRun, .easy, longRunDuration, 0,
                    "Easy long run — recovery week, reduced volume")),
            (3, tpl(3, .tempo, qualityIntensity, qualityDuration, 0, qualityDesc)),
            (1, tpl(1, .recovery, .easy, base.easyRun1Seconds, 0,
                    "Easy run with 4-6 strides @ \(easyPace)")),
            (0, tpl(0, .recovery, .easy, base.easyRun1Seconds, 0,
                    "Easy run @ \(easyPace)")),
            (4, tpl(4, .recovery, .easy, base.easyRun2Seconds, 0,
                    "Easy run @ \(easyPace)")),
            (2, tpl(2, .recovery, .easy, base.easyRun1Seconds, 0,
                    "Recovery run @ \(easyPace)")),
            (6, tpl(6, .recovery, .easy, base.easyRun2Seconds, 0,
                    "Easy run @ \(easyPace)")),
        ]

        // Same session count as normal week (Pfitzinger: keep the rhythm)
        let activeCount = min(preferredRunsPerWeek, pool.count)
        let activeSlots = pool.prefix(activeCount)
        var templates: [SessionTemplateGenerator.SessionTemplate] = []
        for day in 0...6 {
            if let slot = activeSlots.first(where: { $0.day == day }) {
                templates.append(slot.template)
            } else {
                templates.append(tpl(day, .rest, .easy, 0, 0, "Rest day. Recovery week."))
            }
        }
        return templates
    }

    // MARK: - Long Run Descriptions

    private static func longRunDescription(
        phase: TrainingPhase,
        weekInPhase: Int,
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel
    ) -> String {
        let variant = RoadLongRunCalculator.variant(
            phase: phase, weekInPhase: weekInPhase,
            raceDistanceKm: discipline == .road10K ? 10 : discipline == .roadHalf ? 21.1 : 42.2,
            experience: experience, isRecoveryWeek: false
        )

        switch variant {
        case .easy:
            return "Easy long run — conversational pace"
        case .progressive:
            return "Progressive long run — easy → race pace final 1/3"
        case .fastFinish:
            return "Fast-finish long run — last 20% at race pace"
        case .marathonPaceBlocks:
            return "MP long run — 2-3 blocks at marathon pace"
        case .twoPart:
            return "Two-part long run — easy then race pace"
        case .raceSimulation:
            return "Race simulation — extended block at race pace"
        }
    }

    // MARK: - Pace Zone Lookup

    private static func paceForZone(_ zone: RoadIntervalLibrary.PaceZone, profile: RoadPaceProfile) -> Double {
        switch zone {
        case .easy:          profile.easyPacePerKm.lowerBound
        case .marathonPace:  profile.marathonPacePerKm
        case .threshold:     profile.thresholdPacePerKm
        case .interval:      profile.intervalPacePerKm
        case .repetition:    profile.repetitionPacePerKm
        case .racePace:      profile.racePacePerKm
        }
    }
}
