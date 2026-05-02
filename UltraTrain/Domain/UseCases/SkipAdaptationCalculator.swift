import Foundation

/// Calculates training plan adaptations when an athlete skips a session with a reason.
///
/// ## Core principle (supported by all major coaches)
/// A single missed session has essentially ZERO measurable impact on fitness.
/// **Mujika & Padilla (2000, 2003)**: VO2max drops ~7% only after 2+ weeks of no training.
/// **Hickson et al. (1985)**: Reducing frequency by 1/3 for 15 weeks maintained VO2max.
/// **Koop**: "Don't try to make up missed sessions. A single miss is meaningless."
/// **Roche**: "If an athlete misses for non-physiological reasons, the best response is nothing."
///
/// ## When adaptation IS warranted
/// - **Illness**: Immune suppression is real. Nieman (1994) showed training while sick
///   extends recovery 2-3x. Even a single illness skip → downgrade remaining week.
/// - **Fatigue/soreness patterns**: 2-3+ physiological skips in recent weeks signal
///   overreaching (Meeusen et al., 2013). Respond with targeted intensity reduction.
/// - **Accumulated skips**: 4+ non-weather skips in 3 weeks suggests plan is misaligned
///   with athlete capacity (Friel, Training Bible).
///
/// ## Context scaling
/// All reductions scale with: experience level, training phase, race proximity,
/// and skipped session importance.
enum SkipAdaptationCalculator {

    /// A past skip carrying its reason + when it happened. Replaces the
    /// older `[SkipReason]` so the calculator can do time-window
    /// clustering (acute flares vs chronic patterns) and detect
    /// sustained illness/injury runs.
    struct RecentSkip: Sendable, Equatable {
        let reason: SkipReason
        let date: Date
    }

    struct Context: Sendable {
        let skippedSession: TrainingSession
        let reason: SkipReason
        let currentWeek: TrainingWeek
        let nextWeek: TrainingWeek?
        /// Optional second future week. Lets us extend reductions over
        /// 2+ weeks for sustained illness/injury patterns rather than
        /// being capped at next week only.
        let weekAfterNext: TrainingWeek?
        let experience: ExperienceLevel
        /// Recent skips with their dates (typically last 3 weeks). Carries
        /// timestamps so we can distinguish a 3-skip flare in 5 days
        /// (acute) from 3 skips spread across 21 days (chronic).
        let recentSkips: [RecentSkip]
        let totalWeeksInPlan: Int
        let raceDate: Date?
        /// "Now" for time-based logic (race proximity, flare windows).
        /// Defaults to `.now` for callers; injectable for tests.
        let analysisDate: Date

        init(
            skippedSession: TrainingSession,
            reason: SkipReason,
            currentWeek: TrainingWeek,
            nextWeek: TrainingWeek?,
            weekAfterNext: TrainingWeek? = nil,
            experience: ExperienceLevel,
            recentSkips: [RecentSkip],
            totalWeeksInPlan: Int,
            raceDate: Date?,
            analysisDate: Date = .now
        ) {
            self.skippedSession = skippedSession
            self.reason = reason
            self.currentWeek = currentWeek
            self.nextWeek = nextWeek
            self.weekAfterNext = weekAfterNext
            self.experience = experience
            self.recentSkips = recentSkips
            self.totalWeeksInPlan = totalWeeksInPlan
            self.raceDate = raceDate
            self.analysisDate = analysisDate
        }
    }

    /// Race-proximity bands. Drive severity escalation across all
    /// adaptation paths. Coaches treat the last 3 weeks before a race
    /// fundamentally differently — every quality session matters more,
    /// experimental adjustments are ill-advised, and protective
    /// recommendations get prioritized.
    enum RaceProximity: Sendable {
        case offSeason       // No race on the horizon (no raceDate or >42 days)
        case farOut          // 21-42 days
        case approaching     // 7-21 days — bump severity one notch
        case raceWeek        // 3-7 days — bump and prefer protective options
        case taperLockdown   // <3 days — minimum interventions, protect taper

        var bumpsSeverity: Bool {
            switch self {
            case .offSeason, .farOut: return false
            case .approaching, .raceWeek, .taperLockdown: return true
            }
        }
    }

    /// Categorical reason scoring for combination-aware pattern
    /// detection. injury/illness are critical and always escalate at
    /// count=1. fatigue/soreness/menstrualCycle are moderate (need
    /// 2-3 to escalate). noMotivation/noTime/other/weather are minor
    /// (3+ to even register).
    enum ReasonSeverity: Sendable {
        case critical, moderate, minor, neutral

        static func of(_ reason: SkipReason) -> ReasonSeverity {
            switch reason {
            case .injury, .illness:                  return .critical
            case .fatigue, .soreness:                return .moderate
            case .noMotivation, .other:              return .minor
            case .noTime, .weather, .menstrualCycle: return .neutral
            }
        }
    }

    struct Adaptation: Sendable, Equatable {
        let recommendations: [PlanAdjustmentRecommendation]
        let note: String
    }

    // MARK: - Public

    static func analyze(context: Context) -> Adaptation {
        let reason = context.reason
        let session = context.skippedSession
        let isFirstHalf = isFirstHalfOfWeek(session: session, week: context.currentWeek)
        let isKeySession = session.type == .longRun || session.type == .intervals
            || session.type == .verticalGain || session.isKeySession
        let isLongRun = session.type == .longRun
        // Issue #7: Scale pattern thresholds by plan length
        let pattern = detectSkipPattern(
            context.recentSkips,
            currentReason: reason,
            currentDate: context.analysisDate,
            totalWeeks: context.totalWeeksInPlan
        )
        // Issue #6: Phase-aware severity escalation
        let isPeakOrTaper = context.currentWeek.phase == .peak || context.currentWeek.phase == .taper
        // Race-proximity awareness: last few weeks before the A-race
        // change everything. Every quality session matters more, plan
        // experimentation gets shut down, protective options preferred.
        let proximity = raceProximity(raceDate: context.raceDate, now: context.analysisDate)

        var result: Adaptation

        switch reason {
        case .illness:
            result = handleIllness(context: context, isFirstHalf: isFirstHalf)

        case .injury:
            // Issue #4: Injury protocol — aggressive rest + cross-training
            result = handleInjury(context: context, isFirstHalf: isFirstHalf)

        case .fatigue:
            result = handleFatigue(
                context: context, isFirstHalf: isFirstHalf,
                isKeySession: isKeySession, pattern: pattern
            )

        case .soreness:
            result = handleSoreness(
                context: context, isFirstHalf: isFirstHalf, pattern: pattern
            )

        case .noMotivation:
            result = handleNoMotivation(context: context, pattern: pattern)

        case .noTime:
            result = handleNoTime(
                context: context, isFirstHalf: isFirstHalf,
                isKeySession: isKeySession, pattern: pattern
            )

        case .weather:
            result = Adaptation(
                recommendations: [],
                note: "Skipped due to weather. No training adaptation needed."
            )

        case .other:
            result = handleOther(context: context, pattern: pattern)

        case .menstrualCycle:
            // Menstrual-cycle skips are routed to MenstrualAdaptationCalculator
            // by the ViewModel using the session's `menstrualSymptomCluster`,
            // which carries the cluster needed for the right adaptation.
            // SkipAdaptationCalculator deliberately returns no-op for this
            // case so the two pipelines don't double-recommend.
            result = Adaptation(
                recommendations: [],
                note: "Logged as menstrual-cycle skip. Symptom-specific options will surface separately if you flagged bleed-day or PMS symptoms."
            )
        }

        // Issue #3: Long run skips — special handling (Pfitzinger: "most important session")
        if isLongRun && reason != .weather && reason != .injury && reason != .illness {
            let lrNote = " The long run is the most important session for endurance development. Consider rescheduling to another day this week if possible."
            result = Adaptation(
                recommendations: result.recommendations + longRunRescheduleRecommendation(context: context),
                note: result.note + lrNote
            )
        }

        // Issue #6: Escalate severity in peak/taper phase
        if isPeakOrTaper && isKeySession && !result.recommendations.isEmpty {
            result = Adaptation(
                recommendations: result.recommendations.map { rec in
                    var upgraded = rec
                    if rec.severity == .suggestion {
                        upgraded = PlanAdjustmentRecommendation(
                            id: rec.id, type: rec.type, severity: .recommended,
                            title: rec.title, message: rec.message + " (Peak phase — every session counts.)",
                            actionLabel: rec.actionLabel, affectedSessionIds: rec.affectedSessionIds,
                            volumeAdjustments: rec.volumeAdjustments
                        )
                    }
                    return upgraded
                },
                note: result.note
            )
        }

        // Race-proximity bump. Stacks on top of peak-phase escalation.
        // Within 21 days of race day, suggestions become recommended;
        // in race week (<7 days) and the final lockdown (<3 days), we
        // also append a contextual coach note so the athlete sees
        // *why* the severity moved.
        if proximity.bumpsSeverity && !result.recommendations.isEmpty {
            let suffix: String? = {
                switch proximity {
                case .approaching:    return " (Race in 1-3 weeks — every session matters.)"
                case .raceWeek:       return " (Race week — protect freshness, no experiments.)"
                case .taperLockdown:  return " (Race in days — minimum interventions only.)"
                default:              return nil
                }
            }()
            result = Adaptation(
                recommendations: result.recommendations.map { rec in
                    let nextSeverity: AdjustmentSeverity = {
                        // .approaching bumps suggestion → recommended.
                        // .raceWeek + .taperLockdown bump suggestion →
                        // recommended AND recommended → urgent so
                        // athletes see protective advice the way a
                        // coach would phrase it on race week.
                        switch (proximity, rec.severity) {
                        case (.approaching, .suggestion):    return .recommended
                        case (.raceWeek, .suggestion):       return .recommended
                        case (.raceWeek, .recommended):      return .urgent
                        case (.taperLockdown, .suggestion):  return .recommended
                        case (.taperLockdown, .recommended): return .urgent
                        default:                             return rec.severity
                        }
                    }()
                    return PlanAdjustmentRecommendation(
                        id: rec.id,
                        type: rec.type,
                        severity: nextSeverity,
                        title: rec.title,
                        message: suffix.map { rec.message + $0 } ?? rec.message,
                        actionLabel: rec.actionLabel,
                        affectedSessionIds: rec.affectedSessionIds,
                        volumeAdjustments: rec.volumeAdjustments
                    )
                },
                note: result.note
            )
        }

        return result
    }

    // MARK: - Race-Proximity

    static func raceProximity(raceDate: Date?, now: Date) -> RaceProximity {
        guard let raceDate else { return .offSeason }
        let days = Calendar.current.dateComponents([.day], from: now, to: raceDate).day ?? Int.max
        switch days {
        case ..<3:    return .taperLockdown
        case ..<7:    return .raceWeek
        case ..<21:   return .approaching
        case ..<42:   return .farOut
        default:      return .offSeason
        }
    }

    // MARK: - Illness
    //
    // Only reason where a SINGLE skip warrants immediate action.
    // Nieman (1994): exercise during illness suppresses immune function.
    // Gleeson (2007): upper respiratory infections last 2-3x longer if training continues.
    // Protocol: downgrade remaining hard sessions this week to easy.
    // Next week reduction scales with experience (beginners need more recovery).

    private static func handleIllness(
        context: Context, isFirstHalf: Bool
    ) -> Adaptation {
        var recs: [PlanAdjustmentRecommendation] = []

        // Downgrade remaining hard sessions this week
        let remainingHard = remainingQualitySessions(in: context.currentWeek, after: context.skippedSession)
        if !remainingHard.isEmpty {
            recs.append(PlanAdjustmentRecommendation(
                id: UUID(),
                type: .swapToRecovery,
                severity: .recommended,
                title: "Ease off while unwell",
                message: "Hard training suppresses immunity. Remaining hard sessions this week converted to easy.",
                actionLabel: "Convert to easy",
                affectedSessionIds: remainingHard.map(\.id)
            ))
        }

        // Sustained-illness check: ≥2 illness skips in the last 14 days
        // = bug that's hung around → extend reduction to week-after-next
        // too. Gleeson (2007) on multi-day URI: return to training
        // should be gradual. A 10-day flu warrants 2 weeks of reduced
        // load, not just 1.
        let sustained = sustainedCriticalCount(
            recentSkips: context.recentSkips,
            currentReason: .illness,
            now: context.analysisDate,
            kind: .illness,
            withinDays: 14
        ) >= 2

        // Next week: mild reduction. Illness is the exception where even 1 skip matters.
        // Scale: beginners 10-12%, intermediate 8-10%, advanced/elite 5-8%
        if let nextWeek = context.nextWeek {
            let factor = illnessReductionFactor(experience: context.experience)
            let volumeAdj = nextWeekVolumeReduction(nextWeek: nextWeek, factor: factor)
            if !volumeAdj.isEmpty {
                let pct = Int((1 - factor) * 100)
                let extraNote = sustained
                    ? " You've logged multiple illness skips recently — keeping load lighter for two weeks instead of one."
                    : " Return to normal the week after."
                recs.append(PlanAdjustmentRecommendation(
                    id: UUID(),
                    type: .reduceFatigueLoad,
                    severity: sustained ? .urgent : .recommended,
                    title: sustained ? "Two-week ease-off — illness pattern" : "Lighter week after illness",
                    message: "Reducing next week by ~\(pct)% to support immune recovery.\(extraNote)",
                    actionLabel: "Reduce volume",
                    affectedSessionIds: volumeAdj.map(\.sessionId),
                    volumeAdjustments: volumeAdj
                ))
            }
        }

        // Sustained illness → also reduce week-after-next (lighter than
        // week 1 — gradual ramp back). Gleeson recommends a 7-14 day
        // gradual return after upper-respiratory infection.
        if sustained, let weekAfter = context.weekAfterNext {
            // Week 2: split the difference between illness reduction
            // and full normal — a stair-step back to baseline.
            let weekTwoFactor = (illnessReductionFactor(experience: context.experience) + 1.0) / 2.0
            let volumeAdj = nextWeekVolumeReduction(nextWeek: weekAfter, factor: weekTwoFactor)
            if !volumeAdj.isEmpty {
                let pct = Int((1 - weekTwoFactor) * 100)
                recs.append(PlanAdjustmentRecommendation(
                    id: UUID(),
                    type: .reduceFatigueLoad,
                    severity: .recommended,
                    title: "Stair-step back the week after",
                    message: "Week 2 stays ~\(pct)% under normal so the immune system finishes recovering before full load resumes.",
                    actionLabel: "Reduce volume",
                    affectedSessionIds: volumeAdj.map(\.sessionId),
                    volumeAdjustments: volumeAdj
                ))
            }
        }

        let note: String
        if sustained {
            note = "Multiple illness skips logged in the last 2 weeks. Two-week stair-step reduction in place — return to full load only when symptom-free 48h+. Persistent illness > 10 days warrants a doctor."
        } else {
            note = "Illness noted. Remaining hard sessions eased off. Light reduction next week to support recovery."
        }
        return Adaptation(recommendations: recs, note: note)
    }

    /// Counts critical-reason skips of the given kind within the last
    /// `withinDays` days, including `currentReason` if it matches.
    /// Used by handleIllness / handleInjury to detect sustained
    /// patterns that warrant 2-week reductions instead of 1.
    private enum CriticalKind {
        case illness, injury
    }
    private static func sustainedCriticalCount(
        recentSkips: [RecentSkip],
        currentReason: SkipReason,
        now: Date,
        kind: CriticalKind,
        withinDays: Int
    ) -> Int {
        let target: SkipReason = kind == .illness ? .illness : .injury
        let windowStart = Calendar.current.date(byAdding: .day, value: -withinDays, to: now) ?? now
        let recentMatching = recentSkips.filter {
            $0.reason == target && $0.date >= windowStart
        }.count
        let currentMatches = currentReason == target ? 1 : 0
        return recentMatching + currentMatches
    }

    // MARK: - Fatigue
    //
    // Single fatigue skip: the skip itself IS the adaptation (Roche).
    // No volume change. Just a note.
    // UNLESS it's a pattern (2+ fatigue skips recently) → then respond.
    // Magness: pattern of fatigue = functional overreaching. Reduce intensity, not volume first.
    // Beginners: lower threshold for concern (less capacity to absorb load).

    private static func handleFatigue(
        context: Context, isFirstHalf: Bool,
        isKeySession: Bool, pattern: PatternLevel
    ) -> Adaptation {
        // Isolated fatigue skip → no adaptation
        guard pattern != .none else {
            // Exception: beginners get a gentle suggestion to ease next hard session
            if context.experience == .beginner, isFirstHalf {
                let remaining = remainingQualitySessions(in: context.currentWeek, after: context.skippedSession)
                if let next = remaining.first {
                    return Adaptation(
                        recommendations: [PlanAdjustmentRecommendation(
                            id: UUID(),
                            type: .swapToRecovery,
                            severity: .suggestion,
                            title: "Consider easing next hard session",
                            message: "You're still building your base. If fatigue persists, converting \(next.type.displayName) to easy could help.",
                            actionLabel: "Convert to easy",
                            affectedSessionIds: [next.id]
                        )],
                        note: "Fatigue noted. As a newer runner, listen to your body — you can ease the next hard session if needed."
                    )
                }
            }
            return Adaptation(
                recommendations: [],
                note: "Fatigue noted. A single rest is often all you need — no plan changes."
            )
        }

        // Pattern detected → respond proportionally
        var recs: [PlanAdjustmentRecommendation] = []
        let note: String

        if isFirstHalf {
            // Early in week: swap next quality to easy (Magness: reduce intensity first)
            let remaining = remainingQualitySessions(in: context.currentWeek, after: context.skippedSession)
            if let next = remaining.first {
                recs.append(PlanAdjustmentRecommendation(
                    id: UUID(),
                    type: .swapToRecovery,
                    severity: pattern >= .elevated ? .urgent : .recommended,
                    title: "Ease off — fatigue pattern detected",
                    message: "Multiple fatigue signals recently. Converting \(next.type.displayName) to easy this week.",
                    actionLabel: "Convert to easy",
                    affectedSessionIds: [next.id]
                ))
            }
            note = "Recurring fatigue detected. Easing intensity this week."
        } else {
            // Late in week: light reduction next week
            if let nextWeek = context.nextWeek {
                let factor = fatiguePatternFactor(pattern: pattern, experience: context.experience)
                let volumeAdj = nextWeekVolumeReduction(nextWeek: nextWeek, factor: factor)
                if !volumeAdj.isEmpty {
                    let pct = Int((1 - factor) * 100)
                    recs.append(PlanAdjustmentRecommendation(
                        id: UUID(),
                        type: .reduceFatigueLoad,
                        severity: pattern >= .elevated ? .urgent : .recommended,
                        title: "Lighter next week",
                        message: "Fatigue pattern detected. Reducing next week ~\(pct)% to help recovery.",
                        actionLabel: "Reduce volume",
                        affectedSessionIds: volumeAdj.map(\.sessionId),
                        volumeAdjustments: volumeAdj
                    ))
                }
            }
            note = "Recurring fatigue detected. Light volume reduction next week."
        }

        return Adaptation(recommendations: recs, note: note)
    }

    // MARK: - Soreness
    //
    // Single soreness skip: monitor only. No adaptation.
    // Pattern (2+): swap next hard to easy as precaution (Bompa: protect the body).
    // Never reduce volume for soreness — just reduce intensity of next hard session.

    private static func handleSoreness(
        context: Context, isFirstHalf: Bool, pattern: PatternLevel
    ) -> Adaptation {
        guard pattern != .none else {
            return Adaptation(
                recommendations: [],
                note: "Soreness noted. Rest was the right call. No plan changes needed."
            )
        }

        // Pattern: swap next hard session to easy
        let targetWeek = isFirstHalf ? context.currentWeek : context.nextWeek
        var recs: [PlanAdjustmentRecommendation] = []

        if let week = targetWeek {
            let sessions = isFirstHalf
                ? remainingQualitySessions(in: week, after: context.skippedSession)
                : week.sessions.filter { !$0.isCompleted && !$0.isSkipped && ($0.intensity == .hard || $0.intensity == .maxEffort) }
            if let target = sessions.first {
                recs.append(PlanAdjustmentRecommendation(
                    id: UUID(),
                    type: .swapToRecovery,
                    severity: .recommended,
                    title: "Ease next hard session",
                    message: "Recurring soreness — converting \(target.type.displayName) to easy to protect against injury.",
                    actionLabel: "Convert to easy",
                    affectedSessionIds: [target.id]
                ))
            }
        }

        return Adaptation(
            recommendations: recs,
            note: "Recurring soreness. Next hard session eased as precaution. Consider mobility work."
        )
    }

    // MARK: - No Motivation
    //
    // Single: nothing. Everyone has off days (Roche).
    // Pattern: Magness notes motivation loss can signal CNS fatigue / overreaching.
    // But response should be intensity swap, not volume cut — the issue is staleness, not load.
    // Only at elevated pattern level do we suggest a light reduction.

    private static func handleNoMotivation(
        context: Context, pattern: PatternLevel
    ) -> Adaptation {
        guard pattern != .none else {
            return Adaptation(
                recommendations: [],
                note: "Off day — everyone has them. No plan changes needed."
            )
        }

        if pattern >= .elevated {
            // Elevated: could be overreaching. Suggest light next-week reduction.
            var recs: [PlanAdjustmentRecommendation] = []
            if let nextWeek = context.nextWeek {
                let factor = 0.95 // Only 5% — motivation is mental, not muscular
                let volumeAdj = nextWeekVolumeReduction(nextWeek: nextWeek, factor: factor)
                if !volumeAdj.isEmpty {
                    recs.append(PlanAdjustmentRecommendation(
                        id: UUID(),
                        type: .reduceFatigueLoad,
                        severity: .suggestion,
                        title: "Slight ease-up",
                        message: "Repeated motivation dips can signal mental overload. A tiny volume reduction can help reset.",
                        actionLabel: "Ease slightly",
                        affectedSessionIds: volumeAdj.map(\.sessionId),
                        volumeAdjustments: volumeAdj
                    ))
                }
            }
            return Adaptation(
                recommendations: recs,
                note: "Recurring motivation dips. Slight ease-up suggested — often this helps reignite drive."
            )
        }

        // Mild pattern: just acknowledge
        return Adaptation(
            recommendations: [],
            note: "A couple motivation dips noted. No changes yet — reach out if it persists."
        )
    }

    // MARK: - No Time
    //
    // Purely logistical. No fitness implication whatsoever (Koop, Friel).
    // Single: nothing. Just move on.
    // Exception: if key session + early in week → suggest reschedule to rest day.
    // Pattern: if consistently skipping, plan may not fit athlete's schedule.

    private static func handleNoTime(
        context: Context, isFirstHalf: Bool,
        isKeySession: Bool, pattern: PatternLevel
    ) -> Adaptation {
        var recs: [PlanAdjustmentRecommendation] = []

        // Only suggest reschedule for key sessions early in the week
        if isKeySession && isFirstHalf {
            let restSlots = context.currentWeek.sessions.filter {
                $0.type == .rest && $0.date > context.skippedSession.date && !$0.isCompleted && !$0.isSkipped
            }
            if let slot = restSlots.first {
                recs.append(PlanAdjustmentRecommendation(
                    id: UUID(),
                    type: .rescheduleKeySession,
                    severity: .suggestion,
                    title: "Reschedule \(context.skippedSession.type.displayName)?",
                    message: "Key session missed for time. It can be moved to \(slot.date.formatted(.dateTime.weekday(.wide))) if your schedule allows.",
                    actionLabel: "Reschedule",
                    affectedSessionIds: [context.skippedSession.id, slot.id]
                ))
            }
        }

        let note: String
        if pattern >= .elevated {
            note = "Frequent time-based skips. The plan might not match your schedule — consider adjusting your preferred runs per week."
        } else {
            note = "Skipped for time. No plan changes needed."
        }

        return Adaptation(recommendations: recs, note: note)
    }

    // MARK: - Other

    private static func handleOther(
        context: Context, pattern: PatternLevel
    ) -> Adaptation {
        guard pattern >= .elevated else {
            return Adaptation(
                recommendations: [],
                note: "Session skipped. No plan adaptation needed."
            )
        }

        // Elevated pattern of miscellaneous skips → plan may be too ambitious
        var recs: [PlanAdjustmentRecommendation] = []
        if let nextWeek = context.nextWeek {
            let factor = 0.95
            let volumeAdj = nextWeekVolumeReduction(nextWeek: nextWeek, factor: factor)
            if !volumeAdj.isEmpty {
                recs.append(PlanAdjustmentRecommendation(
                    id: UUID(),
                    type: .reduceVolumeAfterLowAdherence,
                    severity: .suggestion,
                    title: "Adjust for adherence",
                    message: "Several sessions skipped recently. A small adjustment helps keep the plan realistic.",
                    actionLabel: "Ease slightly",
                    affectedSessionIds: volumeAdj.map(\.sessionId),
                    volumeAdjustments: volumeAdj
                ))
            }
        }

        return Adaptation(
            recommendations: recs,
            note: "Multiple sessions skipped recently. Small adjustment to keep the plan achievable."
        )
    }

    // MARK: - Pattern Detection

    enum PatternLevel: Comparable {
        case none     // Isolated skip — no concern
        case mild     // 2 non-weather skips recently — worth noting
        case elevated // 3+ physiological or 5+ total — real concern
        case acuteFlare // 3+ skips clustered in 7 days — recent dense pattern
    }

    /// Detects skip patterns from recent history.
    ///
    /// Categorical scoring (audit fix #3): not all physiological reasons
    /// are equal. injury / illness are *critical* and contribute much
    /// more than fatigue / soreness, which contribute more than mild
    /// reasons (motivation, other). Scoring lets us catch e.g.
    /// 1× injury + 1× illness = elevated even at count=2.
    ///
    /// Time-window clustering (audit fix #2): if 3+ skips of any
    /// physiological kind happen within the **same 7-day window**,
    /// classify as `.acuteFlare` rather than `.elevated`. Acute flares
    /// often resolve on their own (one bad week) and warrant a
    /// shorter, sharper response than chronic patterns where the same
    /// number of skips is spread across 21 days.
    ///
    /// Plan-length scaling (issue #7): thresholds tighten on shorter
    /// plans. A 12-week 10K plan can't absorb the same skip rate as
    /// a 28-week marathon.
    private static func detectSkipPattern(
        _ recentSkips: [RecentSkip],
        currentReason: SkipReason,
        currentDate: Date,
        totalWeeks: Int
    ) -> PatternLevel {
        let allSkips = recentSkips + [RecentSkip(reason: currentReason, date: currentDate)]
        let physiological = allSkips.filter {
            $0.reason == .fatigue || $0.reason == .soreness
            || $0.reason == .illness || $0.reason == .injury
        }
        let meaningful = allSkips.filter {
            $0.reason != .weather && $0.reason != .other
            && $0.reason != .menstrualCycle  // routed separately
        }

        // Acute flare check: 3+ physiological skips clustered in any
        // 7-day window. Walks each skip, counts how many physiological
        // skips fall in the next 7 days from that anchor. If any
        // anchor has ≥3 → flare.
        let physioDates = physiological.map(\.date).sorted()
        for anchor in physioDates {
            let windowEnd = Calendar.current.date(byAdding: .day, value: 7, to: anchor) ?? anchor
            let countInWindow = physioDates.filter { $0 >= anchor && $0 <= windowEnd }.count
            if countInWindow >= 3 {
                return .acuteFlare
            }
        }

        // Categorical score for chronic-pattern detection. Critical
        // reasons (injury / illness) count 3×, moderate (fatigue /
        // soreness) count 2×, minor (motivation / other) count 1×.
        // The score is what we threshold against.
        let score = allSkips.reduce(0.0) { acc, skip in
            switch ReasonSeverity.of(skip.reason) {
            case .critical: return acc + 3.0
            case .moderate: return acc + 2.0
            case .minor:    return acc + 1.0
            case .neutral:  return acc + 0.0
            }
        }

        // Plan-length scaling. 28-week baseline → elevated at score ≥ 6
        // (e.g. 3× moderate, or 1× critical + 1× moderate + 1× minor).
        // Mild at score ≥ 4 (2× moderate, etc.). Shorter plans tighten.
        let scale = max(Double(totalWeeks) / 28.0, 0.5)
        let elevatedScore = max(6.0 * scale, 4.0)
        let mildScore = max(4.0 * scale, 2.5)

        // Single-skip critical fast-path: any skip with severity
        // .critical (illness/injury) routes to its own handler with
        // urgent severity — but if RECENT history already shows
        // another critical, that's an immediate elevated pattern.
        let criticalCount = allSkips.filter { ReasonSeverity.of($0.reason) == .critical }.count
        if criticalCount >= 2 { return .elevated }

        // Volume backstop: 5+ meaningful skips of any kind in window
        // means the plan isn't matching capacity — elevated even if
        // the categorical score is low.
        if meaningful.count >= max(Int(5.0 * scale), 3) { return .elevated }

        if score >= elevatedScore { return .elevated }
        if score >= mildScore { return .mild }
        return .none
    }

    // MARK: - Context-Aware Reduction Factors

    /// Illness reduction: beginners need more recovery (less developed aerobic base).
    /// Gleeson (2007): return to training should be gradual after illness.
    /// Numbers: 5-12% is intentionally conservative — illness is the one exception.
    private static func illnessReductionFactor(experience: ExperienceLevel) -> Double {
        switch experience {
        case .beginner:     0.88 // 12% reduction
        case .intermediate: 0.90 // 10% reduction
        case .advanced:     0.93 // 7% reduction
        case .elite:        0.95 // 5% reduction
        }
    }

    /// Fatigue pattern reduction: scales with pattern severity and experience.
    /// Only applied when a PATTERN exists (never for single skips).
    /// Meeusen et al. (2013): functional overreaching responds to 5-15% load reduction.
    private static func fatiguePatternFactor(
        pattern: PatternLevel, experience: ExperienceLevel
    ) -> Double {
        switch (pattern, experience) {
        // Elevated chronic pattern OR acute 7-day flare — same response
        // for now (response shape is identical; only the messaging
        // differs based on which pattern fired).
        case (.elevated, .beginner), (.acuteFlare, .beginner):         return 0.88 // 12%
        case (.elevated, .intermediate), (.acuteFlare, .intermediate): return 0.90 // 10%
        case (.elevated, .advanced), (.acuteFlare, .advanced):         return 0.93 // 7%
        case (.elevated, .elite), (.acuteFlare, .elite):               return 0.95 // 5%
        // Mild pattern
        case (.mild, .beginner):         return 0.93 // 7%
        case (.mild, .intermediate):     return 0.95 // 5%
        case (.mild, .advanced):         return 0.97 // 3%
        case (.mild, .elite):            return 0.97 // 3%
        // No pattern — should not reach here
        case (.none, _):                 return 1.0
        }
    }

    // MARK: - Injury (Issue #4)
    //
    // Acute injury requires aggressive protocol — NOT just "ease next hard session."
    // Protocol: 48-72hr full rest → cross-training only → gradual return.
    // Volume reduction 30-40% for next week (much more than fatigue/soreness).

    private static func handleInjury(
        context: Context, isFirstHalf: Bool
    ) -> Adaptation {
        var recs: [PlanAdjustmentRecommendation] = []

        // Cancel ALL remaining sessions this week (not just hard ones)
        let remaining = context.currentWeek.sessions.filter {
            $0.date > context.skippedSession.date && !$0.isCompleted && !$0.isSkipped && $0.type != .rest
        }
        if !remaining.isEmpty {
            recs.append(PlanAdjustmentRecommendation(
                id: UUID(),
                type: .swapToRecovery,
                severity: .urgent,
                title: "Rest — injury reported",
                message: "All remaining sessions this week should be rest or gentle cross-training (swimming, cycling). Do not run through an injury.",
                actionLabel: "Cancel remaining",
                affectedSessionIds: remaining.map(\.id)
            ))
        }

        // Sustained-injury check: ≥2 injury skips in the last 14 days
        // = either the injury didn't resolve or there's a re-injury
        // pattern. Either way the prescribed rebuild needs to span
        // 2 weeks, not 1.
        let sustained = sustainedCriticalCount(
            recentSkips: context.recentSkips,
            currentReason: .injury,
            now: context.analysisDate,
            kind: .injury,
            withinDays: 14
        ) >= 2

        // Aggressive next-week reduction (30-40% based on experience)
        if let nextWeek = context.nextWeek {
            let factor: Double = switch context.experience {
            case .beginner:     0.60  // 40% reduction
            case .intermediate: 0.65  // 35% reduction
            case .advanced:     0.70  // 30% reduction
            case .elite:        0.70  // 30% reduction
            }
            let volumeAdj = nextWeekVolumeReduction(nextWeek: nextWeek, factor: factor)
            if !volumeAdj.isEmpty {
                let pct = Int((1.0 - factor) * 100)
                let extraNote = sustained
                    ? " You've logged multiple injury skips recently — extending the reduction over two weeks instead of one."
                    : ""
                recs.append(PlanAdjustmentRecommendation(
                    id: UUID(),
                    type: .reduceFatigueLoad,
                    severity: .urgent,
                    title: "Reduced load after injury",
                    message: "Reducing next week by ~\(pct)%. Return to running only when pain-free. Consider cross-training (swimming, cycling) to maintain fitness.\(extraNote)",
                    actionLabel: "Reduce volume",
                    affectedSessionIds: volumeAdj.map(\.sessionId),
                    volumeAdjustments: volumeAdj
                ))
            }
        }

        // Sustained injury pattern → also reduce week-after-next.
        // Step from ~30-40% reduction (week 1) to ~15-20% (week 2)
        // before resuming full load. Coaching consensus: re-injury
        // risk is highest when athletes ramp back too fast.
        if sustained, let weekAfter = context.weekAfterNext {
            let weekTwoFactor: Double = switch context.experience {
            case .beginner:     0.80  // 20% reduction
            case .intermediate: 0.83  // 17% reduction
            case .advanced:     0.85  // 15% reduction
            case .elite:        0.85
            }
            let volumeAdj = nextWeekVolumeReduction(nextWeek: weekAfter, factor: weekTwoFactor)
            if !volumeAdj.isEmpty {
                let pct = Int((1 - weekTwoFactor) * 100)
                recs.append(PlanAdjustmentRecommendation(
                    id: UUID(),
                    type: .reduceFatigueLoad,
                    severity: .recommended,
                    title: "Stair-step back the week after",
                    message: "Week 2 stays ~\(pct)% under normal — re-injury risk is highest when ramp is too fast. Confirm pain-free running before adding back.",
                    actionLabel: "Reduce volume",
                    affectedSessionIds: volumeAdj.map(\.sessionId),
                    volumeAdjustments: volumeAdj
                ))
            }
        }

        let note: String
        if sustained {
            note = "Multiple injury skips logged in the last 2 weeks. Two-week stair-step rebuild in place — return to running only when pain-free, and if pain returns or persists, see a sports-med professional."
        } else {
            note = "Injury reported. All remaining sessions cancelled. Next week significantly reduced. Do NOT run through pain — cross-train if possible. See a professional if pain persists beyond 48-72h."
        }
        return Adaptation(recommendations: recs, note: note)
    }

    // MARK: - Long Run Reschedule (Issue #3)

    private static func longRunRescheduleRecommendation(
        context: Context
    ) -> [PlanAdjustmentRecommendation] {
        let restSlots = context.currentWeek.sessions.filter {
            $0.type == .rest && $0.date > context.skippedSession.date && !$0.isCompleted && !$0.isSkipped
        }
        guard let slot = restSlots.first else { return [] }

        return [PlanAdjustmentRecommendation(
            id: UUID(),
            type: .rescheduleKeySession,
            severity: .recommended,
            title: "Reschedule long run?",
            message: "The long run builds endurance that can't be replaced by other sessions. Move it to \(slot.date.formatted(.dateTime.weekday(.wide))) if possible.",
            actionLabel: "Reschedule",
            affectedSessionIds: [context.skippedSession.id, slot.id]
        )]
    }

    // MARK: - Helpers

    private static func isFirstHalfOfWeek(session: TrainingSession, week: TrainingWeek) -> Bool {
        let cal = Calendar.current
        let weekStart = cal.startOfDay(for: week.startDate)
        let sessionDay = cal.startOfDay(for: session.date)
        let dayOffset = cal.dateComponents([.day], from: weekStart, to: sessionDay).day ?? 0
        return dayOffset <= 2
    }

    private static func remainingQualitySessions(
        in week: TrainingWeek, after session: TrainingSession
    ) -> [TrainingSession] {
        week.sessions.filter {
            $0.date > session.date
            && !$0.isCompleted
            && !$0.isSkipped
            && ($0.type == .intervals || $0.type == .verticalGain || $0.type == .tempo || $0.type == .longRun)
        }
    }

    private static func nextWeekVolumeReduction(
        nextWeek: TrainingWeek, factor: Double
    ) -> [VolumeAdjustment] {
        let reductionFraction = 1.0 - factor
        return nextWeek.sessions
            .filter { $0.type != .rest && $0.type != .strengthConditioning && !$0.isCompleted && !$0.isSkipped }
            .map { session in
                VolumeAdjustment(
                    sessionId: session.id,
                    addedDistanceKm: -(session.plannedDistanceKm * reductionFraction),
                    addedElevationGainM: -(session.plannedElevationGainM * reductionFraction),
                    newType: nil
                )
            }
    }
}
