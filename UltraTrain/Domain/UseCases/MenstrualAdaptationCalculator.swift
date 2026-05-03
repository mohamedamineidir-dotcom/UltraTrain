import Foundation

/// Adaptation engine for menstrual-cycle skips. Symptom-driven, not
/// phase-based. Offers options instead of auto-applying changes.
///
/// ## Why symptom-driven, not phase-based
///
/// The strongest evidence in this space is McNulty et al. (2020),
/// *Sports Medicine*, a meta-analysis of 78 studies finding that
/// performance reduction in the early follicular phase is "trivial"
/// with huge between-study variation, and concluding that *"general
/// guidelines on exercise performance across the menstrual cycle
/// cannot be formed; rather, a personalized approach based on each
/// individual's response is recommended."* The 2023 IOC and 2025
/// UEFA consensus statements explicitly say there is insufficient
/// high-quality evidence to prescribe phase-based training
/// adjustments.
///
/// What is well-supported is that **symptoms** (when they occur)
/// affect training availability. Bruinvels et al. (2021), n=6,812
/// Strava users, *BJSM*: ~78% of exercising women report cycle
/// symptoms affect training, and symptoms are the actionable signal.
///
/// ## Cluster mapping
///
/// **Bleed-day symptoms** (cramps, heavy flow, fatigue) — 24-48 h
/// window. Light aerobic exercise actually *reduces* cramps via
/// beta-endorphin release (Yang 2024 NMA, n=1,808 across 29 RCTs;
/// Armour 2019). Heavy intensity is poorly tolerated. Lever: defer
/// quality 1-2 days OR drop intensity, not full rest.
///
/// **Pre-period (PMS) symptoms** — 3-5 day window. Schmalenberger
/// (2019) and replications show vagally-mediated HRV drops in late
/// luteal *only* in women with high PMS symptoms — autonomic
/// recovery is delayed. Heat-sensitive sessions (long tempo in warm
/// conditions, progesterone-driven thermoregulation) and high-cognitive
/// sessions (intervals) are most affected. Lever: defer hardest
/// session past expected period start OR drop intensity 10-15%.
///
/// **Asymptomatic logs** — no plan adjustment. McNulty 2020:
/// asymptomatic athletes train and PR while bleeding without issue.
/// Treating "luteal = soft training" as a default has been criticised
/// (Cedars-Sinai 2024, Time 2024, McMaster 2024) as oversimplified
/// and patronising.
///
/// **Unspecified** — fall through to existing fatigue logic.
///
/// ## What this calculator does NOT do
///
/// - It does NOT auto-apply changes; it produces option-style
///   recommendations the user picks from. "Keep the plan as-is" is
///   always shown as a first-class option.
/// - It does NOT predict next month's symptoms or rewrite the plan
///   in advance. Cycle length and symptom severity vary too much
///   month-to-month for deterministic prescription.
/// - It does NOT modify training based on logged period dates
///   alone; symptoms are the trigger.
/// - It does NOT surface RED-S guardrails — that's a separate
///   concern (out of scope for v1; spec'd for v2).
enum MenstrualAdaptationCalculator {

    struct Context: Sendable {
        let skippedSession: TrainingSession
        let cluster: MenstrualSymptomCluster
        let currentWeek: TrainingWeek
        let nextWeek: TrainingWeek?
        let now: Date
    }

    struct Adaptation: Sendable, Equatable {
        let recommendations: [PlanAdjustmentRecommendation]
        let note: String
    }

    // MARK: - Public

    static func analyze(context: Context) -> Adaptation {
        switch context.cluster {
        case .bleedDay:
            return analyzeBleedDay(context: context)
        case .prePeriod:
            return analyzePrePeriod(context: context)
        case .asymptomatic:
            return Adaptation(
                recommendations: [],
                note: "Logged for your records. No plan change — many runners train and PR comfortably while bleeding without symptoms."
            )
        case .unspecified:
            return Adaptation(
                recommendations: [],
                note: "Skip recorded. If symptoms come up, mark the next skip with the cluster that fits best so we can offer relevant options."
            )
        }
    }

    // MARK: - Bleed-day

    /// Window: 24-48 h. Returns recommendations for any quality
    /// session within ~2 days of `now`. Never proposes more than one
    /// adjustment to avoid stacking changes; the next skip refreshes
    /// the analysis.
    private static func analyzeBleedDay(context: Context) -> Adaptation {
        let nowDay = Calendar.current.startOfDay(for: context.now)
        let windowEnd = Calendar.current.date(byAdding: .day, value: 2, to: nowDay) ?? nowDay

        // Find next quality session in window
        let qualityTypes: Set<SessionType> = [.intervals, .verticalGain, .tempo, .longRun, .backToBack]
        let candidate = upcomingSessions(context: context, until: windowEnd)
            .first { qualityTypes.contains($0.type) }

        guard let session = candidate else {
            return Adaptation(
                recommendations: [],
                note: "Symptoms may affect the next 1-2 days. No quality session in that window — keep things easy and check in tomorrow."
            )
        }

        let dayLabel = sessionDayLabel(session: session, now: context.now)
        let recommendation = PlanAdjustmentRecommendation(
            id: UUID(),
            type: .menstrualBleedDayOptions,
            severity: .suggestion,
            title: "Symptoms ahead — pick what fits",
            message: "Bleed-day symptoms can last 1-2 days. For your \(session.type.rawValue) on \(dayLabel) you could: defer it 1-2 days, reduce volume ~25% and keep effort easy, or swap to easy or strength. Or keep the plan — light aerobic actually helps cramps for many runners.",
            actionLabel: "See options",
            affectedSessionIds: [session.id]
        )
        return Adaptation(
            recommendations: [recommendation],
            note: "Bleed-day symptoms tend to settle within 24-48 h. We surfaced your next quality session as a decision point."
        )
    }

    // MARK: - Pre-period

    /// Window: 3-5 days. Watch heat-sensitive long tempo + intervals
    /// specifically.
    private static func analyzePrePeriod(context: Context) -> Adaptation {
        let nowDay = Calendar.current.startOfDay(for: context.now)
        let windowEnd = Calendar.current.date(byAdding: .day, value: 5, to: nowDay) ?? nowDay

        // Find the HARDEST session in the window (intervals > tempo > longRun > VG)
        let priority: [SessionType] = [.intervals, .tempo, .longRun, .verticalGain, .backToBack]
        let upcoming = upcomingSessions(context: context, until: windowEnd)
        let candidate = priority.compactMap { type in
            upcoming.first { $0.type == type }
        }.first

        guard let session = candidate else {
            return Adaptation(
                recommendations: [],
                note: "PMS symptoms tend to resolve once your period starts (3-5 days). No hard session in the next few days — keep an eye on heat exposure if you run outside."
            )
        }

        let dayLabel = sessionDayLabel(session: session, now: context.now)
        let isHeatSensitive = session.type == .tempo || session.type == .longRun

        let heatNote = isHeatSensitive
            ? " Long efforts in warm conditions are the most affected — progesterone raises core temp + reduces sweat efficiency."
            : ""

        let recommendation = PlanAdjustmentRecommendation(
            id: UUID(),
            type: .menstrualPrePeriodOptions,
            severity: .suggestion,
            title: "PMS week — options for your hardest session",
            message: "Symptoms typically last 3-5 days, easing once your period starts. For your \(session.type.rawValue) on \(dayLabel): defer past expected period start, drop intensity ~10-15%, or keep the plan. \(heatNote)",
            actionLabel: "See options",
            affectedSessionIds: [session.id]
        )
        return Adaptation(
            recommendations: [recommendation],
            note: "PMS-driven recovery cost is real for symptomatic athletes (Schmalenberger 2019). Defer or downshift if the day arrives heavy."
        )
    }

    // MARK: - Helpers

    private static func upcomingSessions(
        context: Context,
        until end: Date
    ) -> [TrainingSession] {
        let nowDay = Calendar.current.startOfDay(for: context.now)
        var pool: [TrainingSession] = []
        pool.append(contentsOf: context.currentWeek.sessions)
        if let next = context.nextWeek {
            pool.append(contentsOf: next.sessions)
        }
        return pool
            .filter { session in
                let day = Calendar.current.startOfDay(for: session.date)
                return day >= nowDay
                    && day <= end
                    && !session.isCompleted
                    && !session.isSkipped
                    && session.type != .rest
            }
            .sorted { $0.date < $1.date }
    }

    private static func sessionDayLabel(session: TrainingSession, now: Date) -> String {
        let calendar = Calendar.current
        let nowDay = calendar.startOfDay(for: now)
        let sessionDay = calendar.startOfDay(for: session.date)
        let days = calendar.dateComponents([.day], from: nowDay, to: sessionDay).day ?? 0
        switch days {
        case 0:  return "today"
        case 1:  return "tomorrow"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: session.date)
        }
    }

    // MARK: - v2: Multi-skip pattern detection

    /// Detects ≥2 menstrual-cycle skips inside a 7-day window across
    /// the supplied weeks. When that fires, surfaces a single
    /// pattern-level recommendation that names the signal explicitly:
    /// the athlete is already dropping load via skips, the
    /// recommendation just makes the deload structural in framing
    /// (no auto plan mutation — the skips themselves are doing the
    /// work).
    static func analyzeMultiSkipPattern(
        weeks: [TrainingWeek],
        now: Date = .now,
        windowDays: Int = 7
    ) -> [PlanAdjustmentRecommendation] {
        guard let windowStart = Calendar.current.date(
            byAdding: .day, value: -windowDays, to: now
        ) else { return [] }

        let menstrualSkips = weeks.flatMap(\.sessions).filter { session in
            session.isSkipped
                && session.skipReason == .menstrualCycle
                && session.date >= windowStart
                && session.date <= now
        }

        guard menstrualSkips.count >= 2 else { return [] }

        return [PlanAdjustmentRecommendation(
            id: UUID(),
            type: .menstrualMultiSkipPattern,
            severity: .recommended,
            title: "Cycle pattern this week — name it",
            message: "You've logged \(menstrualSkips.count) cycle-related skips in the last week. Your body's already dialled the load — let this week be a soft deload (easy + recovery only, no key quality), then resume normal training next week. McNulty 2020: when symptoms drive availability, listen.",
            actionLabel: "Got it",
            affectedSessionIds: menstrualSkips.map(\.id)
        )]
    }

    // MARK: - v2: RED-S amenorrhea screening

    /// Surfaces a non-judgmental health prompt when the athlete has
    /// `cycleAware == true` AND has logged a `lastPeriodStartDate`
    /// 90+ days in the past AND training volume is still active
    /// (≥1 completed session in the last 21 days). Persistent
    /// menstrual disruption while training is a Female Athlete
    /// Program / BJSM RED-S screening signal — the prompt links to
    /// resources, never diagnoses, never auto-modifies training.
    ///
    /// Skipped entirely when cycleAware is off (athlete didn't opt
    /// into cycle features) or when no period has ever been logged
    /// (we'd produce false positives for first-time users).
    static func analyzeAmenorrheaScreening(
        cycleAware: Bool,
        lastPeriodStartDate: Date?,
        weeks: [TrainingWeek],
        now: Date = .now
    ) -> [PlanAdjustmentRecommendation] {
        guard cycleAware,
              let lastPeriod = lastPeriodStartDate else { return [] }

        let daysSincePeriod = Calendar.current.dateComponents(
            [.day], from: lastPeriod, to: now
        ).day ?? 0
        guard daysSincePeriod >= 90 else { return [] }

        // Athlete is still training — at least 1 completed session
        // in last 21 days. If they've completely stopped, the prompt
        // would be misplaced (different concern, not RED-S).
        guard let recentWindow = Calendar.current.date(
            byAdding: .day, value: -21, to: now
        ) else { return [] }
        let recentlyActive = weeks.flatMap(\.sessions).contains {
            $0.isCompleted && $0.date >= recentWindow && $0.date <= now
        }
        guard recentlyActive else { return [] }

        return [PlanAdjustmentRecommendation(
            id: UUID(),
            type: .menstrualAmenorrheaScreening,
            severity: .suggestion,
            title: "Worth a check-in",
            message: "You haven't logged a period in \(daysSincePeriod) days while training has stayed active. That can be normal for some athletes and a flag for others (RED-S). Worth a chat with a sports-med doctor or reading the Female Athlete Program / BJSM RED-S consensus when you have a moment. We won't diagnose — just naming the signal.",
            actionLabel: "Got it",
            affectedSessionIds: []
        )]
    }

    // MARK: - v2: Predictive flagging

    /// Projects forward from the athlete's `lastPeriodStartDate +
    /// cycleLengthDays` and flags any A-priority hard session
    /// (intervals / tempo / longRun / VG / B2B) that falls inside the
    /// predicted symptomatic window (-3 to +2 days from expected
    /// period start). Flag only — athlete sees it ahead of time and
    /// decides whether to defer or adjust on the day.
    ///
    /// Skipped entirely when cycleAware is off, or no
    /// lastPeriodStartDate logged. Looks ahead 14 days max — far
    /// enough to be useful, not so far that cycle drift makes the
    /// prediction unreliable.
    static func analyzePredictiveFlag(
        cycleAware: Bool,
        lastPeriodStartDate: Date?,
        cycleLengthDays: Int,
        weeks: [TrainingWeek],
        now: Date = .now,
        lookAheadDays: Int = 14
    ) -> [PlanAdjustmentRecommendation] {
        guard cycleAware,
              let lastPeriod = lastPeriodStartDate,
              cycleLengthDays > 0 else { return [] }

        let calendar = Calendar.current
        // Project the next expected period start. If the last logged
        // period was less than one cycle ago, the athlete is mid-
        // cycle; project forward from lastPeriod + cycleLengthDays.
        // If it was longer ago (skipped logging), keep adding cycles
        // until we find the first projected start in the future.
        var nextExpected = lastPeriod
        while nextExpected <= now {
            guard let next = calendar.date(
                byAdding: .day, value: cycleLengthDays, to: nextExpected
            ) else { return [] }
            nextExpected = next
        }

        // Flag only when the projected start is within the look-ahead
        // window. Beyond that, cycle drift makes the projection
        // unreliable.
        guard let lookAheadEnd = calendar.date(
            byAdding: .day, value: lookAheadDays, to: now
        ) else { return [] }
        guard nextExpected <= lookAheadEnd else { return [] }

        // Symptomatic window: 3 days before expected period start
        // through 2 days after. Captures the typical PMS + early
        // bleed-day overlap.
        guard let windowStart = calendar.date(
            byAdding: .day, value: -3, to: nextExpected
        ) else { return [] }
        guard let windowEnd = calendar.date(
            byAdding: .day, value: 2, to: nextExpected
        ) else { return [] }

        let qualityTypes: Set<SessionType> = [
            .intervals, .tempo, .longRun, .verticalGain, .backToBack
        ]
        let flagged = weeks.flatMap(\.sessions).filter { session in
            let day = calendar.startOfDay(for: session.date)
            return qualityTypes.contains(session.type)
                && session.isKeySession
                && day >= calendar.startOfDay(for: windowStart)
                && day <= calendar.startOfDay(for: windowEnd)
                && !session.isCompleted
                && !session.isSkipped
        }

        guard !flagged.isEmpty else { return [] }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let expectedLabel = formatter.string(from: nextExpected)
        let typesLabel = flagged
            .map { $0.type.rawValue.capitalized }
            .joined(separator: ", ")

        return [PlanAdjustmentRecommendation(
            id: UUID(),
            type: .menstrualPredictiveFlag,
            severity: .suggestion,
            title: "Heads-up: cycle window approaching",
            message: "Based on your cycle history, your next period is likely around \(expectedLabel). \(flagged.count) key session(s) (\(typesLabel)) fall in that window — flag only, no plan change. Adjust on the day if symptoms hit.",
            actionLabel: "Got it",
            affectedSessionIds: flagged.map(\.id)
        )]
    }
}
