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
}
