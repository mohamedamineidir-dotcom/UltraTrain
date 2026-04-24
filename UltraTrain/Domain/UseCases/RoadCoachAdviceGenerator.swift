import Foundation

/// Generates road-specific coach advice and session descriptions.
///
/// Key difference from trail advice: references paces in min/km, uses
/// road-specific terminology (tempo, threshold, VO2max intervals),
/// no trail/hiking/elevation language.
enum RoadCoachAdviceGenerator {

    /// Generates coach advice for a road training session.
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
        biologicalSex: BiologicalSex? = nil
    ) -> String? {
        if isRecoveryWeek {
            return recoveryWeekAdvice(type: type)
        }

        var advice: String?
        switch type {
        case .recovery:
            advice = easyRunAdvice(phase: phase, paceProfile: paceProfile)
        case .intervals:
            advice = intervalAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile)
        case .tempo:
            advice = tempoAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile)
        case .longRun:
            advice = longRunAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile)
        case .rest:
            advice = "Rest is where adaptation happens. Trust the process."
        default:
            break
        }

        // RR-20: First-timer conservative advice. Appended on long runs during
        // peak + taper (the sessions closest in feel to race day), and never
        // during base/build (athlete is still building; specificity comes later).
        // Research: first-time marathoners most often fail in the final 10K
        // from going out too hard — coaching emphasis = hold back, finish well.
        if isFirstTimer, type == .longRun, phase == .peak || phase == .taper {
            advice = (advice ?? "") + " " + firstTimerAdvice(discipline: discipline)
        }

        // RR-21: Short-prep warning. When the plan has fewer weeks than
        // research-accepted minimums (marathon <12, HM <8, 10K <6), the
        // base phase is truncated and aerobic fitness won't fully develop.
        // Surfaced on long runs in base phase only — that's when the athlete
        // can still reconsider their target or defer. After base, they've
        // committed.
        if isShortPrep, type == .longRun, phase == .base {
            advice = (advice ?? "") + " " + shortPrepAdvice(discipline: discipline)
        }

        // RR-22: Hot-race advisory (heat + humidity). Pure coaching advice —
        // no training-plan modification. Surfaced during peak + taper on
        // long runs and tempo sessions, the contexts where the athlete is
        // thinking about race-day execution. Advice is actionable regardless
        // of the athlete's home climate: sauna, overdressing, hydration
        // calibration, pre-cooling — things everyone can do.
        if hotRaceForecast, phase == .peak || phase == .taper,
           type == .longRun || type == .tempo {
            advice = (advice ?? "") + " " + hotRaceAdvice()
        }

        // IR-2: when the target pace was refined from recent feedback,
        // surface the adjustment transparently so the athlete knows why
        // the number they see today differs from yesterday. We append
        // this only on intervals / tempo sessions (the pace types that
        // get refined) — adding it to easy runs would be noise.
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
                    warning = " ⚠ Goal is very ambitious — >20% faster than current fitness supports. Training paces stay honest (fitness-derived); race-pace work is held back until late peak. Your fitness right now points to ~\(formatFinishTime(recommended)) as a realistic target for this race. If the tune-up time trial doesn't match your declared goal, retarget before race day — chasing an unattainable goal leads to overtraining, not breakthroughs."
                } else {
                    warning = " ⚠ Goal is very ambitious vs current fitness. Training paces stay honest — we'll introduce goal pace only in late peak, and only if the tune-up time trial supports it."
                }
            } else {
                warning = " Note: goal is ambitious. Training paces reflect current fitness to build safely toward race day; race-specific work unlocks in late peak."
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
            current += " Target HR: \(range.min)-\(range.max) bpm."
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
    /// trust — or push back on — the change. Silent adjustments would
    /// erode the athlete's sense of agency over their own training.
    private static func refinementNote(
        entry: RefineRoadPaceFromFeedbackUseCase.PaceRefinementSummary.Entry
    ) -> String {
        let from = formatPace(entry.originalPacePerKm)
        let to = formatPace(entry.adjustedPacePerKm)
        let deltaSeconds = Int(abs(entry.adjustedPacePerKm - entry.originalPacePerKm).rounded())
        let direction = entry.adjustedPacePerKm > entry.originalPacePerKm ? "slowed" : "quickened"
        let reasonText: String
        switch entry.reason {
        case .slowDownPaceDrift:
            reasonText = "your recent reps have been running \(Int(entry.meanDeviationSecondsPerKm.rounded()))s/km slower than target"
        case .slowDownHighRPE:
            reasonText = "you've been hitting target but at a perceived effort of \(String(format: "%.1f", entry.meanRPE))/10 — unsustainable across a block"
        case .slowDownIncompleteReps:
            reasonText = "you've bailed on reps across multiple sessions — the previous target was too hard"
        case .speedUpFitnessHeadroom:
            reasonText = "you've been clearing the work at RPE \(String(format: "%.1f", entry.meanRPE))/10 with all reps completed — fitness has room"
        }
        return "📊 Target \(direction) \(deltaSeconds)s/km (\(from) → \(to)) based on \(entry.evidenceCount) recent sessions — \(reasonText). The fitness baseline is unchanged; only this session's prescription adapts."
    }

    /// RR-22: Hot-race advisory — practical heat-acclimation options the
    /// athlete can do wherever they live. Research: passive heat exposure
    /// (sauna, hot baths) produces ~50-70% of the acclimation adaptations
    /// of active heat training (Scoon 2007, Zurawlew 2016). Heat acclimation
    /// starts at 5-7 days but optimal benefit at 10-14 days.
    private static func hotRaceAdvice() -> String {
        return "Hot-race advisory: forecast suggests warm/humid race conditions. Practical acclimation you can do wherever you live: (1) sauna sessions 20-30 min at 60-80 °C, 3× per week starting 2 weeks out — passive heat exposure yields ~50-70% of active-heat training benefit; (2) overdress (extra layer) on easy runs during the final 10 days; (3) pre-cool with ice slurry or cold water 15 min before the race if available; (4) expect to pace 10-30 s/km slower than your cool-weather goal pace, and front-load hydration the week before."
    }

    /// RR-21: Short-prep advisory for compressed plans. Surfaced only during
    /// base phase — after that, the athlete has committed and piling on
    /// warnings is unhelpful.
    private static func shortPrepAdvice(discipline: RoadRaceDiscipline) -> String {
        switch discipline {
        case .roadMarathon:
            return "Compressed prep alert: marathon builds typically run 16-18 weeks, with 8 weeks of aerobic base development alone. Your base is truncated, which caps how much aerobic engine you can build before race day. Strongly recommend a conservative finish goal (add 5-10% to your target) or deferring to a later race if the calendar allows."
        case .roadHalf:
            return "Compressed prep alert: HM prep benefits from at least 8 weeks for meaningful threshold development. Your plan is running shorter — consider a conservative finish goal, and trust your aerobic base rather than chasing speed."
        case .road10K:
            return "Compressed prep alert: 10K plans normally run 6+ weeks. Your base is short — prioritize finishing cleanly over hitting a hard target."
        }
    }

    /// RR-20: First-timer coaching nudge for athletes with no prior PB at the
    /// target race distance. Kept short and tactical — the athlete sees this
    /// on long runs in peak + taper, when race-day execution is on their mind.
    private static func firstTimerAdvice(discipline: RoadRaceDiscipline) -> String {
        switch discipline {
        case .roadMarathon:
            return "First-timer note: prioritize finishing strong over hitting a specific time. First-time marathoners most often blow up in the final 10K from going out too hard — hold marathon pace even when it feels too easy in the first half. The fast target belongs to race #2."
        case .roadHalf:
            return "First-timer note: keep the first 15 km conservative — a common first-half-marathon mistake is starting at 10K effort and blowing up at 17 km. Save a little for the final 5 km."
        case .road10K:
            return "First-timer note: most first 10Ks go out too hard. Settle into goal pace by 2 km and save a surge for the final 2 km, not the first."
        }
    }

    /// Formats a TimeInterval as "H:MM" or "M:SS" for coach advice messages.
    private static func formatFinishTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes))"
        }
        return "\(minutes):\(String(format: "%02d", secs))"
    }


    // MARK: - Specific Advice

    private static func easyRunAdvice(phase: TrainingPhase, paceProfile: RoadPaceProfile?) -> String {
        var advice = "Keep it truly easy — conversational pace."
        if let profile = paceProfile {
            let slowPace = formatPace(profile.easyPacePerKm.upperBound)
            let fastPace = formatPace(profile.easyPacePerKm.lowerBound)
            advice += " Target: \(fastPace)-\(slowPace)/km."
        }
        advice += " This is where your aerobic engine grows. Resist the urge to push."
        return advice
    }

    private static func intervalAdvice(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile?
    ) -> String {
        var advice = "Warm-up: 10-15min easy jog + 4-6 strides."
        switch phase {
        case .base:
            advice += " Speed strides and short reps. Focus on form and leg turnover, not raw speed."
        case .build:
            advice += " VO2max session. Run the intervals at a controlled hard effort — working hard but not sprinting."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.intervalPacePerKm))/km."
            }
        case .peak:
            advice += " Race-specific work. This is your \(discipline.displayName) pace — memorize how it feels."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.racePacePerKm))/km."
            }
        default:
            advice += " Light speed work to stay sharp."
        }
        advice += " Cool-down: 5-10min easy jog."
        return advice
    }

    private static func tempoAdvice(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile?
    ) -> String {
        var advice = "Warm-up: 10min easy jog + 4 strides."
        switch phase {
        case .base, .build:
            advice += " Threshold pace: comfortably hard. Speak in short phrases but not a conversation."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.thresholdPacePerKm))/km."
            }
        case .peak:
            advice += " Race-pace threshold work. Sustain your target \(discipline.displayName) pace with control."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.racePacePerKm))/km."
            }
        default:
            advice += " Easy tempo to maintain feel."
        }
        advice += " Cool-down: 5-10min easy jog."
        return advice
    }

    private static func longRunAdvice(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile?
    ) -> String {
        switch phase {
        case .base:
            var advice = "Easy long run. The goal is time on feet, not pace."
            if let profile = paceProfile {
                advice += " Stay in the \(formatPace(profile.easyPacePerKm.lowerBound))-\(formatPace(profile.easyPacePerKm.upperBound))/km range."
            }
            return advice
        case .build:
            return "Structured long run. Start easy and build into a moderate effort in the second half. Practice your race-day nutrition."
        case .peak:
            if discipline == .roadMarathon {
                return "Marathon-specific long run. Include blocks at marathon pace. This is your dress rehearsal — practice everything: pacing, fueling, gear."
            }
            return "Race-specific long run. Include a faster segment at race pace. Practice your race-day routine."
        default:
            return "Easy long run to maintain aerobic fitness."
        }
    }

    private static func recoveryWeekAdvice(type: SessionType) -> String {
        switch type {
        case .longRun:
            "Shorter long run this week. Your body is absorbing recent training — let it work."
        case .recovery:
            "Easy effort. Recovery weeks are when you get stronger. Trust the process."
        default:
            "Recovery week. Keep it easy."
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
