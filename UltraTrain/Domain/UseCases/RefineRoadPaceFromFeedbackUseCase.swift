import Foundation

/// IR-2: adapts future interval / tempo target paces based on recent
/// per-rep feedback.
///
/// This is NOT a cosmetic feature. It exists so the plan stays honest to
/// the athlete's current trajectory — if the athlete has been hitting
/// targets at unsustainable cost, the target slows; if they're clearing
/// work with plenty in the tank, the target quickens. The rules below
/// are what a human coach would apply when reading a month of workout
/// logs: small adjustments, evidence-based, phase-aware, never knee-jerk.
///
/// Design notes:
/// - Pace, RPE, and completion are three distinct signals. None is
///   sufficient alone. Completion is the strongest (bailing reps = the
///   prescription is too hard); RPE gates direction (fast + high RPE
///   is unsustainable output, not fitness signal); pace deviation
///   supplies the magnitude.
/// - We require ≥3 same-type feedbacks in the last 21 days before
///   changing anything. A single session is noise. An ambiguous mix is
///   noise.
/// - Adjustments are dampened by experience (beginners noisier),
///   distance (10K tighter tolerance than marathon), and phase (base
///   small, peak responsive, taper locked).
/// - Hard cap: never more than ±8% from the fitness-derived baseline.
///
/// The refined profile is what the TrainingPlanGenerator uses when
/// writing session descriptions, selecting intervals, and driving coach
/// advice. The optional `PaceRefinementSummary` is carried back so the
/// coach-advice layer can surface the "adjusted from X to Y because Z"
/// note — silent changes would be unprofessional.
enum RefineRoadPaceFromFeedbackUseCase {

    // MARK: - Summary types

    struct PaceRefinementSummary: Equatable, Sendable {
        struct Entry: Equatable, Sendable {
            let sessionType: SessionType
            let originalPacePerKm: Double
            let adjustedPacePerKm: Double
            let reason: Reason
            let evidenceCount: Int
            let meanRPE: Double
            let meanDeviationSecondsPerKm: Double
        }

        enum Reason: String, Equatable, Sendable {
            /// Paces consistently slower than target — target was too hard.
            case slowDownPaceDrift
            /// Target was hit but RPE was consistently ≥ 8 — unsustainable.
            case slowDownHighRPE
            /// Reps not completed repeatedly — strongest signal to ease off.
            case slowDownIncompleteReps
            /// Paces faster than target with low RPE and full completion —
            /// athlete has fitness headroom.
            case speedUpFitnessHeadroom
        }

        let entries: [Entry]
        /// The phase gate that was in effect — useful when the UI wants to
        /// say "held back in base" vs "responsive in peak".
        let gatePhase: TrainingPhase

        func entry(for type: SessionType) -> Entry? {
            entries.first { $0.sessionType == type }
        }

        var isEmpty: Bool { entries.isEmpty }
    }

    // MARK: - Public API

    /// Returns the refined pace profile and a summary describing any
    /// adjustments made. When no rule fires, the profile is returned
    /// unchanged and the summary is nil.
    ///
    /// `now` is injectable so tests can exercise date-windowing without
    /// having to sleep / freeze real time.
    static func refine(
        baseProfile: RoadPaceProfile,
        feedback: [IntervalPerformanceFeedback],
        now: Date = .now,
        raceDate: Date,
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel
    ) -> (RoadPaceProfile, PaceRefinementSummary?) {

        // Refining a non-data-derived (pure experience-tier) profile is
        // stacking heuristic on heuristic. The UI already shows effort
        // labels instead of pace for those athletes; don't invent a
        // "refinement" from numbers we never trusted in the first place.
        guard baseProfile.isDataDerived else { return (baseProfile, nil) }

        // Phase gate — taper is sacred. Race phase (race week itself)
        // also locked.
        let gatePhase = phaseForDaysToRace(
            daysToRace: daysBetween(now, raceDate),
            totalWeeks: nil
        )
        if gatePhase == .taper || gatePhase == .race { return (baseProfile, nil) }

        let cutoff = now.addingTimeInterval(-21 * 24 * 3600)
        let recent = feedback.filter { $0.createdAt >= cutoff }

        var entries: [PaceRefinementSummary.Entry] = []
        var refined = baseProfile

        // Intervals leg
        if let entry = evaluate(
            sessionType: .intervals,
            originalPace: baseProfile.intervalPacePerKm,
            feedback: recent.filter { $0.sessionType == .intervals },
            experience: experience,
            discipline: discipline,
            gatePhase: gatePhase,
            goalRealism: baseProfile.goalRealismLevel
        ) {
            entries.append(entry)
            refined = RoadPaceProfile(
                easyPacePerKm: refined.easyPacePerKm,
                marathonPacePerKm: refined.marathonPacePerKm,
                thresholdPacePerKm: refined.thresholdPacePerKm,
                intervalPacePerKm: entry.adjustedPacePerKm,
                repetitionPacePerKm: refined.repetitionPacePerKm,
                racePacePerKm: refined.racePacePerKm,
                goalRealismLevel: refined.goalRealismLevel,
                isDataDerived: refined.isDataDerived,
                recommendedGoalTime: refined.recommendedGoalTime
            )
        }

        // Tempo leg
        if let entry = evaluate(
            sessionType: .tempo,
            originalPace: baseProfile.thresholdPacePerKm,
            feedback: recent.filter { $0.sessionType == .tempo },
            experience: experience,
            discipline: discipline,
            gatePhase: gatePhase,
            goalRealism: baseProfile.goalRealismLevel
        ) {
            entries.append(entry)
            refined = RoadPaceProfile(
                easyPacePerKm: refined.easyPacePerKm,
                marathonPacePerKm: refined.marathonPacePerKm,
                thresholdPacePerKm: entry.adjustedPacePerKm,
                intervalPacePerKm: refined.intervalPacePerKm,
                repetitionPacePerKm: refined.repetitionPacePerKm,
                racePacePerKm: refined.racePacePerKm,
                goalRealismLevel: refined.goalRealismLevel,
                isDataDerived: refined.isDataDerived,
                recommendedGoalTime: refined.recommendedGoalTime
            )
        }

        if entries.isEmpty { return (baseProfile, nil) }
        return (refined, PaceRefinementSummary(entries: entries, gatePhase: gatePhase))
    }

    // MARK: - Evaluation (shared between intervals and tempo)

    /// Applies the decision tree for a single pace type. Returns a
    /// summary entry when an adjustment fires, nil otherwise.
    private static func evaluate(
        sessionType: SessionType,
        originalPace: Double,
        feedback: [IntervalPerformanceFeedback],
        experience: ExperienceLevel,
        discipline: RoadRaceDiscipline,
        gatePhase: TrainingPhase,
        goalRealism: GoalRealism
    ) -> PaceRefinementSummary.Entry? {
        // Minimum evidence — 3 sessions of THIS type within the window.
        guard feedback.count >= 3 else { return nil }

        // Pace deviation comes only from sessions where actual paces were
        // logged. Other signals (RPE, completion) are drawn from the
        // whole set.
        let pacedFeedback = feedback.filter { !$0.actualPacesPerKm.isEmpty }
        let hasPaceSignal = pacedFeedback.count >= 3

        let meanRPE = feedback.map { Double($0.perceivedEffort) }.reduce(0, +) / Double(feedback.count)

        // Completion ratio across the window. When `completedRepCount` is
        // available we use the actual reps-done / reps-prescribed ratio
        // (a session that completed 9/10 signals very differently from
        // 2/10). Legacy records without a count fall back to boolean
        // all-or-nothing.
        let totalPrescribed = feedback.reduce(0) { $0 + max(1, $1.prescribedRepCount) }
        let totalCompleted = feedback.reduce(0) { sum, fb -> Int in
            if let count = fb.completedRepCount {
                return sum + min(count, fb.prescribedRepCount)
            }
            return sum + (fb.completedAllReps ? fb.prescribedRepCount : 0)
        }
        let completionRatio = Double(totalCompleted) / Double(max(1, totalPrescribed))
        // Incomplete rate for the decision tree: fraction of sessions that
        // missed at least one rep.
        let incompleteCount = feedback.filter { fb in
            if let c = fb.completedRepCount { return c < fb.prescribedRepCount }
            return !fb.completedAllReps
        }.count
        let incompleteRate = Double(incompleteCount) / Double(feedback.count)
        _ = completionRatio  // reserved for future magnitude weighting

        // Mean deviation (sec/km, positive = slower than target).
        let meanDeviation: Double
        if hasPaceSignal {
            meanDeviation = pacedFeedback
                .compactMap(\.meanDeviationSecondsPerKm)
                .reduce(0, +) / Double(pacedFeedback.count)
        } else {
            meanDeviation = 0
        }

        // Base decision — returns (multiplier, reason) before modifiers.
        guard let (rawMultiplier, reason) = decide(
            meanDeviation: meanDeviation,
            hasPaceSignal: hasPaceSignal,
            meanRPE: meanRPE,
            incompleteRate: incompleteRate,
            goalRealism: goalRealism
        ) else { return nil }

        // Apply experience / distance dampening. Deltas shrink for
        // beginners (noisier week-to-week) and 10K athletes (tolerance
        // is intrinsically tighter).
        let expDamp = experienceDampen(experience)
        let distDamp = distanceDampen(discipline)
        let rawDelta = rawMultiplier - 1.0
        var finalMultiplier = 1.0 + rawDelta * expDamp * distDamp

        // Phase cap — how aggressive can we get right now?
        let phaseCap = phaseCap(gatePhase)
        finalMultiplier = clamp(finalMultiplier, min: 1.0 - phaseCap, max: 1.0 + phaseCap)

        // Hard safety cap — never more than ±8% from the fitness anchor.
        finalMultiplier = clamp(finalMultiplier, min: 0.92, max: 1.08)

        // Deadband: <0.5% drift isn't worth a user-visible change.
        if abs(finalMultiplier - 1.0) < 0.005 { return nil }

        let adjustedPace = originalPace * finalMultiplier

        return PaceRefinementSummary.Entry(
            sessionType: sessionType,
            originalPacePerKm: originalPace,
            adjustedPacePerKm: adjustedPace,
            reason: reason,
            evidenceCount: feedback.count,
            meanRPE: meanRPE,
            meanDeviationSecondsPerKm: meanDeviation
        )
    }

    // MARK: - Decision tree

    private static func decide(
        meanDeviation: Double,
        hasPaceSignal: Bool,
        meanRPE: Double,
        incompleteRate: Double,
        goalRealism: GoalRealism
    ) -> (Double, PaceRefinementSummary.Reason)? {
        let slowTolerance = 5.0   // sec/km — within this band, no slow-down from pace alone
        let fastTolerance = -5.0

        // Highest-priority signal: persistent incomplete reps. Pace deviation
        // may not even be logged on sessions the athlete bailed on, so we
        // treat this independently.
        if incompleteRate >= 0.4 {
            return (1.03, .slowDownIncompleteReps)
        }

        // No pace signal — we only have RPE and completion. If RPE is
        // consistently very high without incomplete reps, pull back
        // modestly. Otherwise no action.
        if !hasPaceSignal {
            if meanRPE >= 8.5 {
                return (1.02, .slowDownHighRPE)
            }
            return nil
        }

        // Pace signal present.
        if meanDeviation > slowTolerance {
            if meanRPE >= 8 {
                return (1.04, .slowDownPaceDrift)  // strong slow
            }
            if meanRPE <= 4 {
                // Slow paces but very low effort — the athlete is being
                // cautious, not overcooked. Tiny nudge.
                return (1.01, .slowDownPaceDrift)
            }
            return (1.02, .slowDownPaceDrift)      // mild slow
        }

        if meanDeviation < fastTolerance {
            // Very-ambitious goal: NEVER speed up via feedback. The athlete
            // will happily chase faster paces past safe limits. Race-pace
            // unlocks only via the tune-up time trial in the existing flow.
            if goalRealism == .veryAmbitious { return nil }

            // High RPE despite fast paces — unsustainable output, don't
            // encourage it.
            if meanRPE >= 8 { return nil }

            // Clean signal: fast + low-moderate RPE + no incomplete reps.
            if meanRPE <= 6 && incompleteRate == 0 {
                return (0.98, .speedUpFitnessHeadroom)
            }

            // Ambiguous — don't adjust.
            return nil
        }

        // Pace on target.
        if meanRPE >= 8 {
            // Hitting target but at too high a cost — gentle slow.
            return (1.015, .slowDownHighRPE)
        }
        return nil
    }

    // MARK: - Modifiers & gates

    /// Experience dampening — beginners have noisier week-to-week variance
    /// than elites, so the same feedback pattern should move the target
    /// less confidently.
    private static func experienceDampen(_ experience: ExperienceLevel) -> Double {
        switch experience {
        case .beginner:     return 0.5
        case .intermediate: return 0.75
        case .advanced:     return 1.0
        case .elite:        return 1.0
        }
    }

    /// Distance dampening — 10K intensity is more race-critical per
    /// second than a marathon's, so keep 10K adjustments tighter.
    /// Marathon paces can tolerate a wider adjustment.
    private static func distanceDampen(_ discipline: RoadRaceDiscipline) -> Double {
        switch discipline {
        case .road10K:      return 0.75
        case .roadHalf:     return 1.0
        case .roadMarathon: return 1.2
        }
    }

    /// Per-phase maximum adjustment magnitude. The curve matches how
    /// responsive a human coach is at each point in the build: small in
    /// base (still building aerobic), more in build/peak (refining the
    /// engine we have).
    private static func phaseCap(_ phase: TrainingPhase) -> Double {
        switch phase {
        case .base:     return 0.02
        case .build:    return 0.04
        case .peak:     return 0.05
        case .taper, .race, .recovery:
            // Taper/race: locked (caller already returned early).
            // Recovery: treat conservatively.
            return 0.01
        }
    }

    // MARK: - Phase-from-time heuristic

    /// Maps "days until race" to the approximate phase the athlete is in.
    /// Used as the gate for how aggressive an adjustment is allowed to be.
    /// Mirrors typical Pfitzinger / Daniels plan structure — taper starts
    /// 2 weeks out, peak begins ~6 weeks out for marathon.
    static func phaseForDaysToRace(
        daysToRace: Int,
        totalWeeks: Int?
    ) -> TrainingPhase {
        if daysToRace <= 0 { return .race }
        switch daysToRace {
        case ..<14:  return .taper
        case ..<42:  return .peak
        case ..<84:  return .build
        default:     return .base
        }
    }

    // MARK: - Helpers

    private static func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    }

    private static func clamp(_ value: Double, min lo: Double, max hi: Double) -> Double {
        if value < lo { return lo }
        if value > hi { return hi }
        return value
    }
}
