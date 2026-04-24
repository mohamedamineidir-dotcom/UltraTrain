import Foundation

/// Produces a short "what this week is for" narrative for each training
/// week. Surfaces on the expanded week card so the athlete gets actual
/// coach-style framing — "this is a peak week, here's what we want out
/// of it" — instead of just a list of session rows to execute.
///
/// Inputs are the current week plus its neighbours in the plan so the
/// narrative can reference volume trend (up vs previous, or cutback)
/// and weeks-to-race. Output is hand-written copy per branch — no
/// templated strings with em-dashes.
enum WeeklyNarrativeGenerator {

    struct Narrative: Equatable, Sendable {
        /// Short title, typically phase + week-in-phase.
        /// Example: "Build · Week 3", "Cutback week", "Race week".
        let title: String
        /// 1-2 sentence body in coach voice. What this week is trying
        /// to accomplish and what to prioritise.
        let body: String
        /// Optional one-line actionable goal. Surfaced as a small chip
        /// under the body.
        let goal: String?
    }

    static func build(
        week: TrainingWeek,
        weekIndex: Int,
        allWeeks: [TrainingWeek],
        isRoad: Bool = false
    ) -> Narrative {
        // Race week takes precedence over everything else.
        if week.phase == .race {
            return Narrative(
                title: "Race week",
                body: "Short, easy, confident. The work is done — your job now is arriving rested.",
                goal: "Protect sleep. Eat normally. Get to the start line unhurried."
            )
        }

        if week.isRecoveryWeek {
            return recoveryNarrative(week: week)
        }

        switch week.phase {
        case .base:
            return baseNarrative(week: week, weekIndex: weekIndex, allWeeks: allWeeks, isRoad: isRoad)
        case .build:
            return buildNarrative(week: week, weekIndex: weekIndex, allWeeks: allWeeks, isRoad: isRoad)
        case .peak:
            return peakNarrative(week: week, weekIndex: weekIndex, allWeeks: allWeeks, isRoad: isRoad)
        case .taper:
            return taperNarrative(week: week, weekIndex: weekIndex, allWeeks: allWeeks)
        case .recovery:
            return Narrative(
                title: "Post-race recovery",
                body: "Legs need time. Easy running only, or full rest if anything still aches from race day.",
                goal: "No hard efforts this week. Let the body absorb the effort."
            )
        case .race:
            return Narrative(title: "Race week", body: "", goal: nil)
        }
    }

    // MARK: - Phase narratives

    private static func baseNarrative(
        week: TrainingWeek,
        weekIndex: Int,
        allWeeks: [TrainingWeek],
        isRoad: Bool
    ) -> Narrative {
        let n = weekNumberInPhase(week: week, allWeeks: allWeeks)
        let trend = volumeTrend(weekIndex: weekIndex, allWeeks: allWeeks)
        let body: String
        if n <= 1 {
            body = "Set the floor. Easy miles, conversational pace. Volume will build gradually over the next few weeks."
        } else if trend == .up {
            body = isRoad
                ? "Volume ticks up again. Most runs should still feel easy. The aerobic engine is quietly compounding."
                : "A little more vertical this week. Most runs still easy. The engine compounds in the background."
        } else {
            body = "Hold the rhythm. Most runs should feel unremarkable — that's the point of base training."
        }
        return Narrative(
            title: "Aerobic base · Week \(n)",
            body: body,
            goal: baseGoal(week: week, weekIndex: weekIndex, allWeeks: allWeeks)
        )
    }

    private static func buildNarrative(
        week: TrainingWeek,
        weekIndex: Int,
        allWeeks: [TrainingWeek],
        isRoad: Bool
    ) -> Narrative {
        let n = weekNumberInPhase(week: week, allWeeks: allWeeks)
        let qualityCount = week.sessions.filter {
            $0.type == .intervals || $0.type == .tempo || $0.type == .verticalGain
        }.count
        let body: String
        if qualityCount >= 2 {
            body = isRoad
                ? "Quality layers onto your base. Two focused sessions this week — one for VO2max, one for threshold or race pace."
                : "Quality sits on top of your base. Two hard sessions this week. Keep easy days genuinely easy."
        } else {
            body = "Building. One quality session, the rest aerobic. Protect that one hard effort — it's where the adaptation lives."
        }
        return Narrative(
            title: "Build · Week \(n)",
            body: body,
            goal: "Hit your quality targets without dragging fatigue into the long run."
        )
    }

    private static func peakNarrative(
        week: TrainingWeek,
        weekIndex: Int,
        allWeeks: [TrainingWeek],
        isRoad: Bool
    ) -> Narrative {
        let n = weekNumberInPhase(week: week, allWeeks: allWeeks)
        let weeksToRace = max(0, (allWeeks.count - 1) - weekIndex)
        let body: String
        if weeksToRace <= 3 {
            body = "Race-specific work. Intervals at race pace, long runs with structured blocks. This is the hardest week of the block, don't skimp on sleep."
        } else {
            body = isRoad
                ? "Peak volume with race-specific intensity. Execution quality matters more than hitting numbers."
                : "Peak weeks stack the specificity. The hard sessions are the ones that count — everything else supports them."
        }
        return Narrative(
            title: "Peak · Week \(n)",
            body: body,
            goal: "Execute the key session well. Everything else is support."
        )
    }

    private static func taperNarrative(
        week: TrainingWeek,
        weekIndex: Int,
        allWeeks: [TrainingWeek]
    ) -> Narrative {
        let n = weekNumberInPhase(week: week, allWeeks: allWeeks)
        let body = n <= 1
            ? "Volume drops, intensity stays sharp. You may feel flat — that's fatigue clearing, not fitness leaving (Mujika 2003)."
            : "Second taper week. Even lighter volume, short sharp efforts. Anxiety spikes are normal. Trust the work already done."
        return Narrative(
            title: "Taper · Week \(n)",
            body: body,
            goal: n <= 1
                ? "Keep the legs familiar with race pace. More sleep."
                : "Protect sleep. Avoid new foods. Keep the routine boring."
        )
    }

    private static func recoveryNarrative(week: TrainingWeek) -> Narrative {
        let body = "Volume drops about 25%. If anything felt overloaded the last two weeks, this is where it clears."
        return Narrative(
            title: "Cutback week",
            body: body,
            goal: "Easier days. More sleep. No new tests."
        )
    }

    // MARK: - Helpers

    /// Counts how many weeks of the same phase came before this one
    /// (1-indexed). e.g. "Build Week 3" = third build week in the
    /// plan, not absolute plan week 3.
    private static func weekNumberInPhase(
        week: TrainingWeek,
        allWeeks: [TrainingWeek]
    ) -> Int {
        var count = 0
        for w in allWeeks {
            guard w.phase == week.phase, !w.isRecoveryWeek else { continue }
            count += 1
            if w.id == week.id { return count }
        }
        return max(1, count)
    }

    private enum Trend { case up, flat, down }

    private static func volumeTrend(
        weekIndex: Int,
        allWeeks: [TrainingWeek]
    ) -> Trend {
        guard weekIndex > 0, weekIndex < allWeeks.count else { return .flat }
        let prev = allWeeks[weekIndex - 1].targetDurationSeconds
        let cur = allWeeks[weekIndex].targetDurationSeconds
        guard prev > 0 else { return .flat }
        let delta = (cur - prev) / prev
        if delta > 0.05 { return .up }
        if delta < -0.05 { return .down }
        return .flat
    }

    private static func baseGoal(
        week: TrainingWeek,
        weekIndex: Int,
        allWeeks: [TrainingWeek]
    ) -> String? {
        // If this week's long run is notably longer than last week's,
        // call it out explicitly. Otherwise fall back to a generic goal.
        guard weekIndex > 0 else { return "Hit your weekly volume target without pushing intensity." }
        let prevLR = allWeeks[weekIndex - 1].sessions
            .filter { $0.type == .longRun }
            .map(\.plannedDuration)
            .max() ?? 0
        let curLR = week.sessions
            .filter { $0.type == .longRun }
            .map(\.plannedDuration)
            .max() ?? 0
        if curLR > prevLR, prevLR > 0 {
            let curMin = Int(curLR / 60)
            return "Long run extends to around \(curMin) min this week."
        }
        return "Stay consistent. Easy days easy, long run steady."
    }
}
