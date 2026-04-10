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

    /// Generates a full 7-day session template array for a road training week.
    static func sessions(
        phase: TrainingPhase,
        volume: VolumeCalculator.WeekVolume,
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel,
        weekInPhase: Int,
        preferredRunsPerWeek: Int,
        isRecoveryWeek: Bool,
        paceProfile: RoadPaceProfile?
    ) -> [SessionTemplateGenerator.SessionTemplate] {
        let tpl = SessionTemplateGenerator.tpl
        let base = volume.baseSessionDurations
        let longRunDuration = volume.targetLongRunDurationSeconds

        // Recovery weeks: all easy + reduced long run (Daniels: maintain frequency, drop quality)
        if isRecoveryWeek {
            return recoveryWeekSessions(
                base: base, longRunDuration: longRunDuration,
                preferredRunsPerWeek: preferredRunsPerWeek, tpl: tpl
            )
        }

        // Select quality session templates from the library
        let q1 = RoadIntervalLibrary.selectForSlot(
            slotIndex: 0, phase: phase, discipline: discipline,
            experience: experience, weekInPhase: weekInPhase
        )
        let q2 = RoadIntervalLibrary.selectForSlot(
            slotIndex: 1, phase: phase, discipline: discipline,
            experience: experience, weekInPhase: weekInPhase,
            excludeCategory: q1?.category
        )

        // Quality session intensities
        let q1Intensity: Intensity = q1?.targetPaceZone == .repetition ? .maxEffort : .hard
        let q2Intensity: Intensity = q2?.targetPaceZone == .threshold ? .moderate : .hard

        // Build the session pool (priority order: long run > quality > easy)
        // Day layout: Mon=0(rest/easy) Tue=1(quality1) Wed=2(easy) Thu=3(quality2) Fri=4(easy) Sat=5(long) Sun=6(rest)
        let longRunDesc = longRunDescription(phase: phase, weekInPhase: weekInPhase, discipline: discipline, experience: experience)
        let longRunElev: Double = 0 // Road: no elevation

        var pool: [(day: Int, template: SessionTemplateGenerator.SessionTemplate)] = [
            // Long run: always Saturday (day 5)
            (5, tpl(5, .longRun, .easy, longRunDuration, longRunElev, longRunDesc)),
            // Quality 1: Tuesday (day 1)
            (1, tpl(1, .intervals, q1Intensity, base.intervalSeconds, 0,
                    q1?.description ?? "Quality intervals session.")),
            // Quality 2: Thursday (day 3)
            (3, tpl(3, .tempo, q2Intensity, base.vgSeconds, 0,
                    q2?.description ?? "Tempo / threshold session.")),
            // Easy runs fill remaining days
            (0, tpl(0, .recovery, .easy, base.easyRun1Seconds, 0,
                    "Easy run. Conversational pace — protect your recovery.")),
            (4, tpl(4, .recovery, .easy, base.easyRun2Seconds, 0,
                    "Easy run before your long run. Stay relaxed.")),
            (2, tpl(2, .recovery, .easy, base.easyRun1Seconds, 0,
                    "Easy recovery run between quality sessions.")),
            (6, tpl(6, .recovery, .easy, base.easyRun2Seconds, 0,
                    "Easy run or cross-training. Active recovery.")),
        ]

        // For 6+ runs/week marathon plans: convert day 2 easy to medium-long (Pfitzinger)
        if preferredRunsPerWeek >= 6 && discipline == .roadMarathon && phase != .base {
            let medLongDuration = longRunDuration * 0.6
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
        tpl: (Int, SessionType, Intensity, TimeInterval, Double, String) -> SessionTemplateGenerator.SessionTemplate
    ) -> [SessionTemplateGenerator.SessionTemplate] {
        // Recovery: all easy + reduced long run + optional strides
        let recoveryCount = min(preferredRunsPerWeek, 5) // Max 5 on recovery weeks
        let pool: [(day: Int, template: SessionTemplateGenerator.SessionTemplate)] = [
            (5, tpl(5, .longRun, .easy, longRunDuration, 0,
                    "Easy long run. Recovery week — shorter than usual.")),
            (1, tpl(1, .recovery, .easy, base.easyRun1Seconds, 0,
                    "Easy run with 4-6 strides at the end. Maintain leg speed.")),
            (3, tpl(3, .recovery, .easy, base.easyRun2Seconds, 0,
                    "Easy recovery run. Conversational pace.")),
            (0, tpl(0, .recovery, .easy, base.easyRun1Seconds * 0.8, 0,
                    "Short easy run. Recovery week.")),
            (4, tpl(4, .recovery, .easy, base.easyRun2Seconds * 0.8, 0,
                    "Easy jog. Keep the legs moving.")),
        ]

        let activeSlots = pool.prefix(recoveryCount)
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
            return "Easy long run. Conversational pace throughout — build your aerobic engine."
        case .progressive:
            return "Progressive long run. Start easy, build to ~90% race pace in the final third."
        case .fastFinish:
            return "Fast-finish long run. Easy pace until the last 20%, then surge to race pace."
        case .marathonPaceBlocks:
            return "MP long run. Easy warm-up, then 2-3 blocks at marathon pace with easy jogs between."
        case .twoPart:
            return "Two-part long run. First half easy, second half at race pace. Race simulation."
        case .raceSimulation:
            return "Race simulation. Extended block at race pace within the long run. Rehearse race day."
        }
    }
}
