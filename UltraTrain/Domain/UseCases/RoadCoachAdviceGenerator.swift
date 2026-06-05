import Foundation

/// Generates road-specific coach advice and session descriptions.
///
/// Key difference from trail advice: references paces in min/km, uses
/// road-specific terminology (tempo, threshold, VO2max intervals),
/// no trail/hiking/elevation language.
///
/// All user-facing copy is localized via `String(localized:)`; the English
/// text is the `defaultValue`, so en-locale builds (and tests) resolve to
/// the original strings while French users get the translated catalog value.
enum RoadCoachAdviceGenerator {

    /// Generates coach advice for a road training session.
    ///
    /// `qualityTemplate` lets the advice surface the *correct* prescribed
    /// pace for threshold sessions, cruise intervals use the faster end
    /// of the threshold range (1.06×), sustained tempos use the slower
    /// end (1.09×). Without it the advice falls back to the slower
    /// single-value default, which underspeeds cruise prescriptions.
    static func advice(
        type: SessionType,
        intensity: Intensity,
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        isRecoveryWeek: Bool,
        paceProfile: RoadPaceProfile?,
        raceName: String? = nil,
        experience: ExperienceLevel = .intermediate,
        isFirstTimer: Bool = false,
        isShortPrep: Bool = false,
        hotRaceForecast: Bool = false,
        refinementSummary: RefineRoadPaceFromFeedbackUseCase.PaceRefinementSummary? = nil,
        restingHR: Int? = nil,
        maxHR: Int? = nil,
        biologicalSex: BiologicalSex? = nil,
        qualityTemplate: RoadIntervalLibrary.Template? = nil
    ) -> String? {
        if isRecoveryWeek {
            return recoveryWeekAdvice(type: type)
        }

        var advice: String?
        switch type {
        case .recovery:
            advice = easyRunAdvice(phase: phase, paceProfile: paceProfile)
        case .intervals:
            advice = intervalAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile, template: qualityTemplate)
        case .tempo:
            advice = tempoAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile, template: qualityTemplate)
        case .longRun:
            advice = longRunAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile)
        case .rest:
            advice = String(localized: "road.coach.rest",
                            defaultValue: "Rest is where adaptation happens. Trust the process.")
        default:
            break
        }

        // RR-20: First-timer conservative advice. Appended on long runs during
        // peak + taper (the sessions closest in feel to race day), and never
        // during base/build (athlete is still building; specificity comes later).
        // Research: first-time marathoners most often fail in the final 10K
        // from going out too hard, coaching emphasis = hold back, finish well.
        if isFirstTimer, type == .longRun, phase == .peak || phase == .taper {
            advice = (advice ?? "") + " " + firstTimerAdvice(discipline: discipline)
        }

        // RR-21: Short-prep warning. When the plan has fewer weeks than
        // research-accepted minimums (marathon <12, HM <8, 10K <6), the
        // base phase is truncated and aerobic fitness won't fully develop.
        // Surfaced on long runs in base phase only, that's when the athlete
        // can still reconsider their target or defer. After base, they've
        // committed.
        if isShortPrep, type == .longRun, phase == .base {
            advice = (advice ?? "") + " " + shortPrepAdvice(discipline: discipline)
        }

        // RR-22: Hot-race advisory (heat + humidity). Pure coaching advice
        // no training-plan modification. Surfaced during peak + taper on
        // long runs and tempo sessions, the contexts where the athlete is
        // thinking about race-day execution. Advice is actionable regardless
        // of the athlete's home climate: sauna, overdressing, hydration
        // calibration, pre-cooling, things everyone can do.
        if hotRaceForecast, phase == .peak || phase == .taper,
           type == .longRun || type == .tempo {
            advice = (advice ?? "") + " " + hotRaceAdvice()
        }

        // IR-2: when the target pace was refined from recent feedback,
        // surface the adjustment transparently so the athlete knows why
        // the number they see today differs from yesterday. We append
        // this only on intervals / tempo sessions (the pace types that
        // get refined), adding it to easy runs would be noise.
        if let summary = refinementSummary,
           let entry = summary.entry(for: type),
           type == .intervals || type == .tempo {
            advice = (advice ?? "") + " " + refinementNote(entry: entry)
        }

        // RR-19 (was #9): Goal realism warning. Now applied in ALL phases
        // (the previous base/build-only gate hid the warning during peak,
        // exactly when the athlete sees race-specific work getting gated
        // and most needs to know why). `.veryAmbitious` also names the
        // recommended realistic target so the athlete has a concrete
        // alternative, not just a vague warning.
        if let realism = paceProfile?.goalRealismLevel, realism != .realistic {
            let warning: String
            if realism == .veryAmbitious {
                if let recommended = paceProfile?.recommendedGoalTime {
                    warning = " " + String(localized: "road.coach.goal.veryAmbitious.withTarget",
                        defaultValue: "⚠ Goal is very ambitious. A realistic target right now is ~\(formatFinishTime(recommended)). Race pace unlocks only if your tune-up trial confirms it.")
                } else {
                    warning = " " + String(localized: "road.coach.goal.veryAmbitious",
                        defaultValue: "⚠ Goal is very ambitious vs current fitness. Race pace unlocks only if your tune-up trial confirms it.")
                }
            } else {
                warning = " " + String(localized: "road.coach.goal.ambitious",
                    defaultValue: "Note: goal is ambitious. Training paces reflect current fitness; race-specific work unlocks in late peak.")
            }
            advice = (advice ?? "") + warning
        }

        // #14: append Karvonen HR range when the athlete has recorded
        // both resting + max HR. Skips rest days and sessions with no
        // base advice. Helps athletes who train by HR get the same
        // guidance their pace-focused peers already get.
        if type != .rest,
           let restingHR, let maxHR, restingHR > 0, maxHR > restingHR,
           var current = advice {
            let range = PaceCalculator.heartRateRange(
                for: intensity, restingHR: restingHR, maxHR: maxHR
            )
            current += " " + String(localized: "road.coach.targetHR",
                defaultValue: "Target HR: \(range.min)-\(range.max) bpm.")
            advice = current
        }

        // #15: append research-backed sex-specific note when applicable.
        // Phase 1 appends only for female athletes (long-run fuelling,
        // peak iron surveillance, race-week RED-S). Male athletes pass
        // through unchanged.
        if let biologicalSex, let current = advice,
           let note = SexSpecificAdviceHelper.note(
               biologicalSex: biologicalSex,
               sessionType: type,
               phase: phase,
               isRecoveryWeek: isRecoveryWeek,
               isRaceWeek: phase == .race
           ) {
            advice = current + " " + note
        }

        return advice
    }

    /// IR-2: transparent explanation of a feedback-driven pace refinement.
    /// Always cites the evidence count and the reason so the athlete can
    /// trust, or push back on, the change. Silent adjustments would
    /// erode the athlete's sense of agency over their own training.
    private static func refinementNote(
        entry: RefineRoadPaceFromFeedbackUseCase.PaceRefinementSummary.Entry
    ) -> String {
        let from = formatPace(entry.originalPacePerKm)
        let to = formatPace(entry.adjustedPacePerKm)
        let deltaSeconds = Int(abs(entry.adjustedPacePerKm - entry.originalPacePerKm).rounded())
        let direction = entry.adjustedPacePerKm > entry.originalPacePerKm
            ? String(localized: "road.coach.refine.slowed", defaultValue: "slowed")
            : String(localized: "road.coach.refine.quickened", defaultValue: "quickened")
        let reasonText: String
        switch entry.reason {
        case .slowDownPaceDrift:
            reasonText = String(localized: "road.coach.refine.reason.paceDrift",
                defaultValue: "your recent reps have been running \(Int(entry.meanDeviationSecondsPerKm.rounded()))s/km slower than target")
        case .slowDownHighRPE:
            reasonText = String(localized: "road.coach.refine.reason.highRPE",
                defaultValue: "you've been hitting target but at a perceived effort of \(String(format: "%.1f", entry.meanRPE))/10, unsustainable across a block")
        case .slowDownIncompleteReps:
            reasonText = String(localized: "road.coach.refine.reason.incompleteReps",
                defaultValue: "you've bailed on reps across multiple sessions; the previous target was too hard")
        case .speedUpFitnessHeadroom:
            reasonText = String(localized: "road.coach.refine.reason.fitnessHeadroom",
                defaultValue: "you've been clearing the work at RPE \(String(format: "%.1f", entry.meanRPE))/10 with all reps completed; fitness has room")
        }
        return String(localized: "road.coach.refine.summary",
            defaultValue: "📊 Target \(direction) \(deltaSeconds)s/km (\(from) → \(to)) based on \(entry.evidenceCount) recent sessions: \(reasonText). The fitness baseline is unchanged; only this session's prescription adapts.")
    }

    /// RR-22: Hot-race advisory, practical heat-acclimation options the
    /// athlete can do wherever they live. Research: passive heat exposure
    /// (sauna, hot baths) produces ~50-70% of the acclimation adaptations
    /// of active heat training (Scoon 2007, Zurawlew 2016). Heat acclimation
    /// starts at 5-7 days but optimal benefit at 10-14 days.
    private static func hotRaceAdvice() -> String {
        return String(localized: "road.coach.hotRace",
            defaultValue: "Hot-race advisory: forecast suggests warm/humid race conditions. Practical acclimation: (1) sauna sessions 20-30 min at 60-80 °C, 3× per week starting 2 weeks out (passive heat exposure yields ~50-70% of active-heat benefit); (2) overdress on easy runs during the final 10 days; (3) pre-cool with ice slurry or cold water 15 min before the race; (4) expect to pace 10-30 s/km slower than your cool-weather goal pace.")
    }

    /// RR-21: Short-prep advisory for compressed plans. Surfaced only during
    /// base phase, after that, the athlete has committed and piling on
    /// warnings is unhelpful.
    private static func shortPrepAdvice(discipline: RoadRaceDiscipline) -> String {
        switch discipline {
        case .roadMarathon:
            return String(localized: "road.coach.shortPrep.marathon",
                defaultValue: "Compressed prep alert: marathon builds typically run 16-18 weeks, with 8 weeks of aerobic base development alone. Your base is truncated, which caps how much aerobic engine you can build before race day. Strongly recommend a conservative finish goal (add 5-10% to your target) or deferring to a later race if the calendar allows.")
        case .roadHalf:
            return String(localized: "road.coach.shortPrep.half",
                defaultValue: "Compressed prep alert: HM prep benefits from at least 8 weeks for meaningful threshold development. Your plan is running shorter. Consider a conservative finish goal, and trust your aerobic base rather than chasing speed.")
        case .road10K:
            return String(localized: "road.coach.shortPrep.tenK",
                defaultValue: "Compressed prep alert: 10K plans normally run 6+ weeks. Your base is short. Prioritize finishing cleanly over hitting a hard target.")
        }
    }

    /// RR-20: First-timer coaching nudge for athletes with no prior PB at the
    /// target race distance. Kept short and tactical, the athlete sees this
    /// on long runs in peak + taper, when race-day execution is on their mind.
    private static func firstTimerAdvice(discipline: RoadRaceDiscipline) -> String {
        switch discipline {
        case .roadMarathon:
            return String(localized: "road.coach.firstTimer.marathon",
                defaultValue: "First-timer note: prioritize finishing strong over hitting a specific time. First-time marathoners most often blow up in the final 10K from going out too hard. Hold marathon pace even when it feels too easy in the first half. The fast target belongs to race #2.")
        case .roadHalf:
            return String(localized: "road.coach.firstTimer.half",
                defaultValue: "First-timer note: keep the first 15 km conservative. A common first-half-marathon mistake is starting at 10K effort and blowing up at 17 km. Save a little for the final 5 km.")
        case .road10K:
            return String(localized: "road.coach.firstTimer.tenK",
                defaultValue: "First-timer note: most first 10Ks go out too hard. Settle into goal pace by 2 km and save a surge for the final 2 km, not the first.")
        }
    }

    /// Formats a TimeInterval as a finish time using letter-suffixed
    /// segments ("3h16", "22min30s") instead of colon notation. Avoids
    /// visual collision with pace strings like "3:16/km".
    private static func formatFinishTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        if hours > 0 {
            return "\(hours)h\(String(format: "%02d", minutes))"
        }
        if secs > 0 {
            return "\(minutes)min\(secs)s"
        }
        return "\(minutes)min"
    }


    // MARK: - Specific Advice

    private static func easyRunAdvice(phase: TrainingPhase, paceProfile: RoadPaceProfile?) -> String {
        var advice = String(localized: "road.coach.easy.intro",
            defaultValue: "Keep it truly easy, at conversational pace.")
        if let profile = paceProfile {
            let slowPace = formatPace(profile.easyPacePerKm.upperBound)
            let fastPace = formatPace(profile.easyPacePerKm.lowerBound)
            advice += " " + String(localized: "road.coach.targetRange",
                defaultValue: "Target: \(fastPace)-\(slowPace)/km.")
        }
        advice += " " + String(localized: "road.coach.easy.outro",
            defaultValue: "This is where your aerobic engine grows. Resist the urge to push.")
        return advice
    }

    private static func intervalAdvice(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile?,
        template: RoadIntervalLibrary.Template?
    ) -> String {
        var advice = String(localized: "road.coach.interval.warmup",
            defaultValue: "Warm-up: 10-15min easy jog + 4-6 strides.")
        switch phase {
        case .base:
            advice += " " + String(localized: "road.coach.interval.base",
                defaultValue: "Speed strides and short reps. Focus on form and leg turnover, not raw speed.")
        case .build:
            advice += " " + String(localized: "road.coach.interval.build",
                defaultValue: "VO2max session. Run the intervals at a controlled hard effort, working hard but not sprinting.")
            if let profile = paceProfile {
                let pace = paceForTemplate(template: template, profile: profile, fallback: profile.intervalPacePerKm)
                advice += " " + targetPaceText(pace)
            }
        case .peak:
            advice += " " + String(localized: "road.coach.interval.peak",
                defaultValue: "Race-specific work. This is your \(discipline.displayName) pace. Memorize how it feels.")
            if let profile = paceProfile {
                let pace = paceForTemplate(template: template, profile: profile, fallback: profile.racePacePerKm)
                advice += " " + targetPaceText(pace)
            }
        default:
            advice += " " + String(localized: "road.coach.interval.default",
                defaultValue: "Light speed work to stay sharp.")
        }
        advice += " " + String(localized: "road.coach.cooldown",
            defaultValue: "Cool-down: 5-10min easy jog.")
        return advice
    }

    private static func tempoAdvice(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile?,
        template: RoadIntervalLibrary.Template?
    ) -> String {
        var advice = String(localized: "road.coach.tempo.warmup",
            defaultValue: "Warm-up: 10min easy jog + 4 strides.")
        switch phase {
        case .base, .build:
            advice += " " + String(localized: "road.coach.tempo.baseBuild",
                defaultValue: "Threshold pace: comfortably hard. Speak in short phrases but not a conversation.")
            if let profile = paceProfile {
                let pace = paceForTemplate(template: template, profile: profile, fallback: profile.thresholdPacePerKm)
                advice += " " + targetPaceText(pace)
            }
        case .peak:
            advice += " " + String(localized: "road.coach.tempo.peak",
                defaultValue: "Race-pace threshold work. Sustain your target \(discipline.displayName) pace with control.")
            if let profile = paceProfile {
                let pace = paceForTemplate(template: template, profile: profile, fallback: profile.racePacePerKm)
                advice += " " + targetPaceText(pace)
            }
        default:
            advice += " " + String(localized: "road.coach.tempo.default",
                defaultValue: "Easy tempo to maintain feel.")
        }
        advice += " " + String(localized: "road.coach.cooldown",
            defaultValue: "Cool-down: 5-10min easy jog.")
        return advice
    }

    /// "Target: <pace>/km." — shared across interval/tempo prescriptions.
    private static func targetPaceText(_ pace: Double) -> String {
        String(localized: "road.coach.targetPace",
               defaultValue: "Target: \(formatPace(pace))/km.")
    }

    /// Returns the prescribed pace for a quality session. When a template
    /// is available we honor its target zone (so an MP cruise session in
    /// late-build marathon doesn't get told "VO2max pace" or threshold
    /// pace just because the phase implies it). Threshold-zone templates
    /// pick from the cruise/sustained range based on rep structure.
    private static func paceForTemplate(
        template: RoadIntervalLibrary.Template?,
        profile: RoadPaceProfile,
        fallback: Double
    ) -> Double {
        guard let template = template else { return fallback }
        switch template.targetPaceZone {
        case .easy:          return profile.easyPacePerKm.lowerBound
        case .marathonPace:  return profile.marathonPacePerKm
        case .threshold:     return template.effectiveThresholdPacePerKm(profile: profile)
        case .interval:      return profile.intervalPacePerKm
        case .repetition:    return profile.repetitionPacePerKm
        case .racePace:      return profile.racePacePerKm
        }
    }

    private static func longRunAdvice(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile?
    ) -> String {
        switch phase {
        case .base:
            var advice = String(localized: "road.coach.longRun.base",
                defaultValue: "Easy long run. The goal is time on feet, not pace.")
            if let profile = paceProfile {
                advice += " " + String(localized: "road.coach.longRun.baseRange",
                    defaultValue: "Stay in the \(formatPace(profile.easyPacePerKm.lowerBound))-\(formatPace(profile.easyPacePerKm.upperBound))/km range.")
            }
            return advice
        case .build:
            return String(localized: "road.coach.longRun.build",
                defaultValue: "Structured long run. Start easy and build into a moderate effort in the second half. Practice your race-day nutrition.")
        case .peak:
            if discipline == .roadMarathon {
                return String(localized: "road.coach.longRun.peak.marathon",
                    defaultValue: "Marathon-specific long run. Include blocks at marathon pace. This is your dress rehearsal. Practice everything: pacing, fueling, gear.")
            }
            return String(localized: "road.coach.longRun.peak.other",
                defaultValue: "Race-specific long run. Include a faster segment at race pace. Practice your race-day routine.")
        default:
            return String(localized: "road.coach.longRun.default",
                defaultValue: "Easy long run to maintain aerobic fitness.")
        }
    }

    private static func recoveryWeekAdvice(type: SessionType) -> String {
        switch type {
        case .longRun:
            String(localized: "road.coach.recoveryWeek.longRun",
                   defaultValue: "Shorter long run this week. Your body is absorbing recent training. Let it work.")
        case .recovery:
            String(localized: "road.coach.recoveryWeek.recovery",
                   defaultValue: "Easy effort. Recovery weeks are when you get stronger. Trust the process.")
        default:
            String(localized: "road.coach.recoveryWeek.default",
                   defaultValue: "Recovery week. Keep it easy.")
        }
    }

    // MARK: - Formatting

    /// Formats pace in seconds/km to "M:SS" string.
    static func formatPace(_ secondsPerKm: Double) -> String {
        let mins = Int(secondsPerKm) / 60
        let secs = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
