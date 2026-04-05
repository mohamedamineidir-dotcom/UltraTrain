import Foundation

enum SessionTemplateGenerator {

    struct SessionTemplate: Sendable {
        let dayOffset: Int // 0 = Monday, 6 = Sunday
        let type: SessionType
        let intensity: Intensity
        let durationSeconds: TimeInterval
        let elevationFraction: Double
        let description: String
    }

    // MARK: - Public

    static func sessions(
        for skeleton: WeekSkeletonBuilder.WeekSkeleton,
        volume: VolumeCalculator.WeekVolume,
        experience: ExperienceLevel,
        raceEffectiveKm: Double = 0,
        raceElevationGainM: Double = 0,
        totalWeeks: Int = 0,
        philosophy: TrainingPhilosophy = .balanced,
        weekNumberInPhase: Int = 0,
        raceOverride: IntermediateRaceHandler.RaceWeekOverride? = nil,
        preferredRunsPerWeek: Int = 5,
        verticalGainEnvironment: VerticalGainEnvironment = .mountain,
        expectedRaceDuration: TimeInterval = 0,
        strengthConfig: StrengthSessionGenerator.Config? = nil,
        qualityRatio: QualitySessionRatioResolver.Ratio? = nil,
        intervalFocus: IntervalFocus = .mixed,
        isRoadRace: Bool = false
    ) -> (sessions: [TrainingSession], workouts: [IntervalWorkout], strengthWorkouts: [StrengthWorkout]) {
        let runsPerWeek = preferredRunsPerWeek
        let templates: [SessionTemplate]
        var workouts: [IntervalWorkout] = []

        if let override = raceOverride {
            templates = overrideTemplates(for: override.behavior, volume: volume)
        } else if skeleton.isRecoveryWeek {
            templates = recoveryTemplates(volume: volume, preferredRunsPerWeek: runsPerWeek)
        } else {
            templates = phaseTemplates(
                for: skeleton.phase,
                volume: volume,
                experience: experience,
                weekNumberInPhase: weekNumberInPhase,
                preferredRunsPerWeek: runsPerWeek,
                qualityRatio: qualityRatio
            )
        }

        let progressionContext: WorkoutProgressionEngine.ProgressionContext? = totalWeeks > 0
            ? .init(
                raceEffectiveKm: raceEffectiveKm,
                raceElevationGainM: raceElevationGainM,
                totalWeeks: totalWeeks,
                weekIndexInPlan: skeleton.weekNumber,
                experience: experience,
                philosophy: philosophy
            )
            : nil

        // Track quality session slots to differentiate session 1 vs session 2
        var qualitySlotCounter: [SessionType: Int] = [:]

        let sessions = templates.map { template in
            let rawDuration = template.durationSeconds
            let rawElevation = volume.targetElevationGainM * template.elevationFraction

            // Round duration to nearest 5min for non-precise session types
            let duration: TimeInterval
            switch template.type {
            case .intervals, .verticalGain, .rest:
                duration = rawDuration
            default:
                duration = roundToNearest5Min(rawDuration)
            }

            // Round all session elevation to nearest 5m for clean numbers
            let elevation = roundToNearest5(rawElevation)

            // Generate workout for active sessions
            var workoutId: UUID?
            var sessionDescription = template.description
            let shouldGenerateWorkout = template.type != .rest
            if shouldGenerateWorkout {
                let isB2BDay1 = volume.isB2BWeek && template.type == .longRun
                let isQuality = template.type == .intervals || template.type == .verticalGain
                let slotIndex = isQuality ? (qualitySlotCounter[template.type, default: 0]) : 0
                if isQuality { qualitySlotCounter[template.type, default: 0] += 1 }

                let workout = WorkoutProgressionEngine.workout(
                    type: template.type,
                    phase: skeleton.phase,
                    weekInPhase: weekNumberInPhase,
                    intensity: template.intensity,
                    totalDuration: duration,
                    expectedRaceDuration: expectedRaceDuration,
                    isB2BDay1: isB2BDay1,
                    phaseFocus: skeleton.phaseFocus,
                    progressionContext: progressionContext,
                    isSecondarySession: slotIndex > 0
                )
                workouts.append(workout)
                workoutId = workout.id
                sessionDescription = workout.descriptionText
            }

            let advice = CoachAdviceGenerator.advice(
                for: template.type,
                intensity: template.intensity,
                phase: skeleton.phase,
                weekInPhase: weekNumberInPhase,
                isB2BDay2: template.type == .backToBack,
                isRecoveryWeek: skeleton.isRecoveryWeek,
                verticalGainEnvironment: verticalGainEnvironment,
                intervalFocus: intervalFocus,
                isRoadRace: isRoadRace
            )

            return TrainingSession(
                id: UUID(),
                date: skeleton.startDate.adding(days: template.dayOffset),
                type: template.type,
                plannedDistanceKm: 0,
                plannedElevationGainM: elevation,
                plannedDuration: duration,
                intensity: template.intensity,
                description: sessionDescription,
                nutritionNotes: nutritionNotes(duration: duration),
                isCompleted: false,
                isSkipped: false,
                linkedRunId: nil,
                intervalWorkoutId: workoutId,
                coachAdvice: advice
            )
        }

        let markedSessions = markKeySessions(sessions, phase: skeleton.phase)

        // Generate S&C sessions if athlete opted in
        var strengthWorkouts: [StrengthWorkout] = []
        var allSessions = markedSessions
        if let sConfig = strengthConfig {
            let scCount = StrengthSessionGenerator.sessionsPerWeek(config: sConfig)
            if scCount > 0 {
                let availableDays = StrengthSessionGenerator.availableDayOffsets(
                    runningSessions: templates, config: sConfig
                )
                let scDays = pickSCDays(
                    availableDays: availableDays,
                    count: scCount,
                    existingSessions: templates
                )
                for (i, dayOffset) in scDays.enumerated() {
                    let workout = StrengthSessionGenerator.generateWorkout(
                        config: sConfig, sessionIndex: i
                    )
                    strengthWorkouts.append(workout)

                    let scSession = TrainingSession(
                        id: UUID(),
                        date: skeleton.startDate.adding(days: dayOffset),
                        type: .strengthConditioning,
                        plannedDistanceKm: 0,
                        plannedElevationGainM: 0,
                        plannedDuration: TimeInterval(workout.estimatedDurationMinutes * 60),
                        intensity: .easy,
                        description: formatSCDescription(workout),
                        nutritionNotes: nil,
                        isCompleted: false,
                        isSkipped: false,
                        linkedRunId: nil,
                        strengthWorkoutId: workout.id,
                        coachAdvice: scCoachAdvice(config: sConfig, category: workout.category)
                    )
                    allSessions.append(scSession)
                }
            }
        }

        // Sort all sessions by date
        allSessions.sort { $0.date < $1.date }

        return (allSessions, workouts, strengthWorkouts)
    }

    // MARK: - S&C Day Placement

    /// Picks the best days for S&C sessions from available slots.
    /// Prefers rest days first, then easy run days. Spreads them apart.
    private static func pickSCDays(
        availableDays: [Int],
        count: Int,
        existingSessions: [SessionTemplate]
    ) -> [Int] {
        guard !availableDays.isEmpty, count > 0 else { return [] }

        // Prefer rest days, then recovery/easy days, then any available
        let restDays = availableDays.filter { day in
            existingSessions.first(where: { $0.dayOffset == day })?.type == .rest
        }
        let easyDays = availableDays.filter { day in
            let sessionType = existingSessions.first(where: { $0.dayOffset == day })?.type
            return sessionType == .recovery || sessionType == .crossTraining
        }

        var candidates = restDays + easyDays + availableDays
        // Remove duplicates while preserving order
        var seen = Set<Int>()
        candidates = candidates.filter { seen.insert($0).inserted }

        if count == 1 {
            // Single session: prefer mid-week (day 0=Mon or 3=Thu)
            let preferred = candidates.min(by: { abs($0 - 3) < abs($1 - 3) })
            return [preferred ?? candidates[0]]
        }

        if count >= 2, candidates.count >= 2 {
            // Spread sessions apart: pick first and one ~3 days later
            let first = candidates[0]
            let second = candidates.first(where: { abs($0 - first) >= 2 }) ?? candidates[1]
            var result = [first, second]

            if count >= 3, candidates.count >= 3 {
                let third = candidates.first(where: {
                    $0 != first && $0 != second && abs($0 - first) >= 2 && abs($0 - second) >= 2
                }) ?? candidates.first(where: { $0 != first && $0 != second })
                if let t = third { result.append(t) }
            }

            return Array(result.prefix(count))
        }

        return Array(candidates.prefix(count))
    }

    // MARK: - S&C Description & Advice

    private static func formatSCDescription(_ workout: StrengthWorkout) -> String {
        var lines: [String] = []
        lines.append(workout.name)
        lines.append("Duration: ~\(workout.estimatedDurationMinutes) min")
        lines.append("")
        lines.append(workout.warmUpNotes)
        lines.append("")

        let grouped = Dictionary(grouping: workout.exercises, by: { $0.category })
        for category in StrengthExerciseCategory.allCases {
            guard let exercises = grouped[category], !exercises.isEmpty else { continue }
            lines.append("▸ \(category.displayName):")
            for ex in exercises {
                lines.append("  • \(ex.name) — \(ex.sets)×\(ex.reps)")
                if !ex.notes.isEmpty {
                    lines.append("    \(ex.notes)")
                }
            }
            lines.append("")
        }

        lines.append(workout.coolDownNotes)
        return lines.joined(separator: "\n")
    }

    private static func scCoachAdvice(
        config: StrengthSessionGenerator.Config,
        category: StrengthSessionCategory
    ) -> String {
        switch category {
        case .full:
            switch config.phase {
            case .base:
                return "Foundation phase: focus on learning proper form with moderate loads. Build the strength base that will support harder training later. Take 60-90 sec rest between sets."
            case .build:
                return "Build phase: increase weight or difficulty. Add power movements. Quality over quantity — stop if form breaks down. Allow 4-6 hours between running and this session."
            case .peak:
                return "Peak maintenance: keep loads moderate, reduce volume. You're preserving strength, not building it. 2-3 sets max per exercise."
            default:
                return "Keep it controlled and focused. Listen to your body."
            }
        case .maintenance:
            return "Quick maintenance session: hit the key movements with reduced volume. 2-3 sets, don't push to failure. Keep the neuromuscular connection alive."
        case .activation:
            switch config.phase {
            case .taper:
                return "Light activation only. No soreness allowed — your race is close. These movements keep muscles firing without creating fatigue."
            case .recovery:
                return "Gentle activation to promote blood flow and recovery. Stop immediately if anything feels off."
            default:
                return "Light activation routine. Wake up the stabilizers before your next run."
            }
        }
    }

    // MARK: - Mark Key Sessions

    private static func markKeySessions(_ sessions: [TrainingSession], phase: TrainingPhase) -> [TrainingSession] {
        let keyCount: Int
        switch phase {
        case .peak, .build: keyCount = 4
        case .race: keyCount = 5
        default: keyCount = 3
        }

        let keyPriority: [SessionType] = [.longRun, .backToBack, .intervals, .verticalGain, .tempo, .recovery]
        let activeSessions = sessions.enumerated().filter { $0.element.type != .rest }
        let sorted = activeSessions.sorted { a, b in
            let aPriority = keyPriority.firstIndex(of: a.element.type) ?? keyPriority.count
            let bPriority = keyPriority.firstIndex(of: b.element.type) ?? keyPriority.count
            return aPriority < bPriority
        }

        let keyIndices = Set(sorted.prefix(min(keyCount, sorted.count)).map { $0.offset })
        return sessions.enumerated().map { idx, session in
            var s = session
            s.isKeySession = keyIndices.contains(idx)
            return s
        }
    }

    // MARK: - Phase Dispatch

    static func phaseTemplates(
        for phase: TrainingPhase,
        volume: VolumeCalculator.WeekVolume,
        experience: ExperienceLevel,
        weekNumberInPhase: Int,
        preferredRunsPerWeek: Int = 5,
        qualityRatio: QualitySessionRatioResolver.Ratio? = nil
    ) -> [SessionTemplate] {
        switch phase {
        case .base, .build, .peak:
            return standardWeekTemplates(
                volume: volume, experience: experience, phase: phase,
                weekInPhase: weekNumberInPhase, preferredRunsPerWeek: preferredRunsPerWeek,
                qualityRatio: qualityRatio
            )
        case .taper:
            return taperTemplates(volume: volume, preferredRunsPerWeek: preferredRunsPerWeek)
        case .recovery, .race:
            return recoveryTemplates(volume: volume, preferredRunsPerWeek: preferredRunsPerWeek)
        }
    }

    // MARK: - Standard Week (dynamic session count)

    private static func standardWeekTemplates(
        volume: VolumeCalculator.WeekVolume,
        experience: ExperienceLevel,
        phase: TrainingPhase,
        weekInPhase: Int = 0,
        preferredRunsPerWeek: Int = 5,
        qualityRatio: QualitySessionRatioResolver.Ratio? = nil
    ) -> [SessionTemplate] {
        let base = volume.baseSessionDurations
        let vgIntensity: Intensity = (experience == .advanced || experience == .elite) ? .hard : .moderate
        let intervalIntensity: Intensity = phase == .base ? .moderate : .hard

        if volume.isB2BWeek {
            return b2bWeekTemplates(
                volume: volume, base: base, vgIntensity: vgIntensity,
                phase: phase, weekInPhase: weekInPhase,
                preferredRunsPerWeek: preferredRunsPerWeek
            )
        }

        // Determine quality slot types based on ratio
        let slotAssignment = QualitySessionRatioResolver.assignSlots(
            ratio: qualityRatio ?? .init(vgFraction: 0.50),
            qualitySlotCount: 2,
            weekNumberInPhase: weekInPhase
        )
        let slot1IsVG = slotAssignment[0]
        let slot2IsVG = slotAssignment[1]

        // Quality slot 1 (Tuesday, day 2)
        let q1Type: SessionType = slot1IsVG ? .verticalGain : .intervals
        let q1Intensity = slot1IsVG ? vgIntensity : intervalIntensity
        let q1Duration = slot1IsVG ? base.vgSeconds : base.intervalSeconds
        let q1Desc = slot1IsVG
            ? SessionDescriptionGenerator.verticalGain(phase: phase, isRecoveryWeek: false)
            : SessionDescriptionGenerator.intervals(phase: phase, isRecoveryWeek: false, weekInPhase: weekInPhase)

        // Quality slot 2 (Thursday, day 4) — never consecutive with slot 1
        let q2Type: SessionType = slot2IsVG ? .verticalGain : .intervals
        let q2Intensity = slot2IsVG ? vgIntensity : intervalIntensity
        let q2Duration = slot2IsVG ? base.vgSeconds : base.intervalSeconds
        let q2Desc = slot2IsVG
            ? SessionDescriptionGenerator.verticalGain(phase: phase, isRecoveryWeek: false)
            : SessionDescriptionGenerator.intervals(phase: phase, isRecoveryWeek: false, weekInPhase: weekInPhase)

        // Build pool: quality sessions separated by easy/tempo day
        // Mon=0(easy), Tue=2(quality1), Wed=3(tempo/easy), Thu=4(quality2), Fri=5(easy), Sat=6(long), Sun=rest/cross
        let pool: [(day: Int, template: SessionTemplate)] = [
            (6, tpl(6, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.75,
                    SessionDescriptionGenerator.longRun(phase: phase, isRecoveryWeek: false))),
            (2, tpl(2, q1Type, q1Intensity, q1Duration, 0, q1Desc)),
            (4, tpl(4, q2Type, q2Intensity, q2Duration, 0, q2Desc)),
            (1, tpl(1, .recovery, .easy, base.easyRun1Seconds, 0,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false))),
            (5, tpl(5, .recovery, .easy, base.easyRun2Seconds, 0,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false, isPreLongRun: true))),
            (3, tpl(3, .tempo, .moderate, base.intervalSeconds, 0,
                    SessionDescriptionGenerator.tempo(phase: phase))),
            (0, tpl(0, .crossTraining, .easy, base.easyRun1Seconds, 0,
                    SessionDescriptionGenerator.crossTraining())),
        ]

        // Take only the number of active sessions the user wants
        let activeCount = min(preferredRunsPerWeek, pool.count)
        let activeSlots = pool.prefix(activeCount)

        // Build full 7-day week: active sessions + rest days
        var templates: [SessionTemplate] = []
        for day in 0...6 {
            if let slot = activeSlots.first(where: { $0.day == day }) {
                templates.append(slot.template)
            } else {
                templates.append(tpl(day, .rest, .easy, 0, 0,
                    SessionDescriptionGenerator.rest(isRecoveryWeek: false)))
            }
        }
        return templates
    }

    // MARK: - B2B Week (dynamic session count)

    private static func b2bWeekTemplates(
        volume: VolumeCalculator.WeekVolume,
        base: VolumeCalculator.BaseSessionDurations,
        vgIntensity: Intensity,
        phase: TrainingPhase,
        weekInPhase: Int,
        preferredRunsPerWeek: Int
    ) -> [SessionTemplate] {
        // B2B days are always included (day 5 + day 6)
        // D+ split between the two long runs (40/60)
        var pool: [(day: Int, template: SessionTemplate)] = [
            (5, tpl(5, .longRun, .easy, volume.b2bDay1Seconds, 0.40,
                    SessionDescriptionGenerator.b2bDay1(phase: phase))),
            (6, tpl(6, .backToBack, .easy, volume.b2bDay2Seconds, 0.60,
                    SessionDescriptionGenerator.b2bDay2(phase: phase))),
        ]

        // VG: include only if duration > 0 (dropped on hardest B2B weeks)
        if base.vgSeconds > 0 {
            pool.append((2, tpl(2, .verticalGain, vgIntensity, base.vgSeconds, 0,
                    SessionDescriptionGenerator.verticalGain(phase: phase, isRecoveryWeek: false))))
        } else {
            pool.append((2, tpl(2, .recovery, .easy, base.easyRun1Seconds, 0,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false))))
        }

        pool.append((1, tpl(1, .recovery, .easy, base.easyRun1Seconds, 0,
                SessionDescriptionGenerator.easyRun(isRecoveryWeek: false))))
        pool.append((3, tpl(3, .recovery, .easy, base.easyRun2Seconds, 0,
                SessionDescriptionGenerator.easyRun(isRecoveryWeek: false, isPreLongRun: true))))

        // Intervals: replaced by easy run on B2B weeks (intervalSeconds = 0)
        if base.intervalSeconds > 0 {
            pool.append((4, tpl(4, .intervals, .moderate, base.intervalSeconds, 0,
                    SessionDescriptionGenerator.intervals(phase: phase, isRecoveryWeek: false, weekInPhase: weekInPhase))))
        } else {
            pool.append((4, tpl(4, .recovery, .easy, base.easyRun1Seconds, 0,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false))))
        }

        pool.append((0, tpl(0, .recovery, .easy, base.easyRun1Seconds, 0,
                SessionDescriptionGenerator.easyRun(isRecoveryWeek: false))))

        let activeCount = min(preferredRunsPerWeek, pool.count)
        let activeSlots = pool.prefix(activeCount)

        var templates: [SessionTemplate] = []
        for day in 0...6 {
            if let slot = activeSlots.first(where: { $0.day == day }) {
                templates.append(slot.template)
            } else {
                templates.append(tpl(day, .rest, .easy, 0, 0,
                    SessionDescriptionGenerator.rest(isRecoveryWeek: false)))
            }
        }
        return templates
    }

    // MARK: - Taper (dynamic session count)

    private static func taperTemplates(
        volume: VolumeCalculator.WeekVolume,
        preferredRunsPerWeek: Int = 5
    ) -> [SessionTemplate] {
        let base = volume.baseSessionDurations

        let qualityAllowed: Bool
        if let profile = volume.taperProfile {
            qualityAllowed = profile.isQualityAllowed(forWeekInTaper: volume.weekNumberInTaper)
        } else {
            qualityAllowed = true // legacy: all taper weeks get quality
        }

        let subPhase: TaperProfile.SubPhase = volume.taperProfile?.subPhase(
            forWeekInTaper: volume.weekNumberInTaper
        ) ?? .volumeTransition

        let pool: [(day: Int, template: SessionTemplate)]

        if qualityAllowed {
            // Volume transition: intervals and VG separated by easy day
            pool = [
                (5, tpl(5, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.43,
                        SessionDescriptionGenerator.taperLongRun(subPhase: subPhase))),
                (1, tpl(1, .intervals, .moderate, base.intervalSeconds, 0,
                        SessionDescriptionGenerator.taperIntervals(subPhase: subPhase))),
                (2, tpl(2, .recovery, .easy, base.easyRun1Seconds, 0,
                        SessionDescriptionGenerator.taperEasyRun(subPhase: subPhase))),
                (3, tpl(3, .verticalGain, .easy, base.vgSeconds, 0,
                        SessionDescriptionGenerator.taperVerticalGain(subPhase: subPhase))),
                (4, tpl(4, .recovery, .easy, base.easyRun2Seconds, 0,
                        SessionDescriptionGenerator.taperEasyRun(subPhase: subPhase))),
            ]
        } else {
            // True taper: no quality sessions — long run + easy runs + opener strides
            let stridesDuration: TimeInterval = 15 * 60
            pool = [
                (5, tpl(5, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.43,
                        SessionDescriptionGenerator.taperLongRun(subPhase: subPhase))),
                (2, tpl(2, .intervals, .moderate, stridesDuration, 0,
                        SessionDescriptionGenerator.taperStrides())),
                (3, tpl(3, .recovery, .easy, base.easyRun1Seconds, 0,
                        SessionDescriptionGenerator.taperEasyRun(subPhase: subPhase))),
                (4, tpl(4, .recovery, .easy, base.easyRun2Seconds, 0,
                        SessionDescriptionGenerator.taperEasyRun(subPhase: subPhase))),
            ]
        }

        let activeCount = min(preferredRunsPerWeek, pool.count)
        let activeSlots = pool.prefix(activeCount)

        var templates: [SessionTemplate] = []
        for day in 0...6 {
            if let slot = activeSlots.first(where: { $0.day == day }) {
                templates.append(slot.template)
            } else {
                let isPreRace = !qualityAllowed
                templates.append(tpl(day, .rest, .easy, 0, 0,
                    SessionDescriptionGenerator.rest(isRecoveryWeek: false, isPreRace: isPreRace)))
            }
        }
        return templates
    }

    // MARK: - Recovery (dynamic session count)

    static func recoveryTemplates(
        volume: VolumeCalculator.WeekVolume,
        preferredRunsPerWeek: Int = 5
    ) -> [SessionTemplate] {
        let base = volume.baseSessionDurations

        // Recovery week count: 3-5 → same, 6 → 5, 7 → 6
        let recoveryCount: Int
        switch preferredRunsPerWeek {
        case ...5:  recoveryCount = preferredRunsPerWeek
        case 6:     recoveryCount = 5
        default:    recoveryCount = 6
        }

        // All sessions at easy/recovery intensity
        // D+ concentrated on long run only
        let pool: [(day: Int, template: SessionTemplate)] = [
            (5, tpl(5, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.52,
                    SessionDescriptionGenerator.longRun(phase: .recovery, isRecoveryWeek: true))),
            (3, tpl(3, .verticalGain, .easy, base.vgSeconds, 0,
                    SessionDescriptionGenerator.verticalGain(phase: .recovery, isRecoveryWeek: true))),
            (1, tpl(1, .recovery, .easy, base.easyRun1Seconds, 0,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: true))),
            (4, tpl(4, .recovery, .easy, base.easyRun2Seconds, 0,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: true))),
            (2, tpl(2, .recovery, .easy, base.easyRun1Seconds, 0,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: true))),
            (6, tpl(6, .recovery, .easy, base.easyRun2Seconds, 0,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: true))),
        ]

        let activeCount = min(recoveryCount, pool.count)
        let activeSlots = pool.prefix(activeCount)

        var templates: [SessionTemplate] = []
        for day in 0...6 {
            if let slot = activeSlots.first(where: { $0.day == day }) {
                templates.append(slot.template)
            } else {
                templates.append(tpl(day, .rest, .easy, 0, 0,
                    SessionDescriptionGenerator.rest(isRecoveryWeek: true)))
            }
        }
        return templates
    }

    // MARK: - Race Override Templates

    static func overrideTemplates(
        for behavior: IntermediateRaceHandler.Behavior,
        volume: VolumeCalculator.WeekVolume
    ) -> [SessionTemplate] {
        switch behavior {
        case .miniTaper:
            return taperTemplates(volume: volume)
        case .raceWeek(let priority):
            return priority == .cRace ? cRaceWeekTemplates() : bRaceWeekTemplates()
        case .postRaceRecovery:
            return recoveryTemplates(volume: volume)
        }
    }

    static func bRaceWeekTemplates() -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, 0, "Rest before race. Stay off your feet."),
            tpl(1, .recovery, .easy, 1200, 0, "Short shakeout run. 15-20 min at easy pace."),
            tpl(2, .rest, .easy, 0, 0, "Rest day. Carb-load and hydrate."),
            tpl(3, .rest, .easy, 0, 0, "Rest day. Final race prep and gear check."),
            tpl(4, .rest, .easy, 0, 0, "Rest day. Visualize your race plan."),
            tpl(5, .rest, .maxEffort, 0, 0, "RACE DAY! Execute your plan."),
            tpl(6, .rest, .easy, 0, 0, "Post-race recovery. Walk, stretch, refuel."),
        ]
    }

    static func cRaceWeekTemplates() -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, 0, "Rest day. Easy start to race week."),
            tpl(1, .recovery, .easy, 1800, 0, "Easy run at conversational pace."),
            tpl(2, .rest, .easy, 0, 0, "Rest day. Light stretching."),
            tpl(3, .tempo, .moderate, 2400, 0.05, "Short tempo effort. Stay sharp."),
            tpl(4, .rest, .easy, 0, 0, "Rest day. Prepare race gear and nutrition."),
            tpl(5, .rest, .maxEffort, 0, 0, "RACE DAY! Use as a hard training effort."),
            tpl(6, .recovery, .easy, 1500, 0, "Easy recovery run. Shake out race-day legs."),
        ]
    }

    // MARK: - Helpers

    static func tpl(
        _ day: Int, _ type: SessionType, _ intensity: Intensity,
        _ duration: TimeInterval, _ elevFraction: Double, _ desc: String
    ) -> SessionTemplate {
        SessionTemplate(
            dayOffset: day, type: type, intensity: intensity,
            durationSeconds: duration, elevationFraction: elevFraction,
            description: desc
        )
    }

    /// Rounds seconds to the nearest 5-minute boundary (300s).
    private static func roundToNearest5Min(_ seconds: TimeInterval) -> TimeInterval {
        guard seconds > 0 else { return 0 }
        return (seconds / 300.0).rounded() * 300.0
    }

    /// Rounds meters to the nearest 5m for clean D+ numbers.
    private static func roundToNearest5(_ meters: Double) -> Double {
        guard meters > 0 else { return 0 }
        return (meters / 5.0).rounded() * 5.0
    }

    private static func nutritionNotes(duration: TimeInterval) -> String? {
        let hours = duration / 3600.0
        guard hours > 1.0 else { return nil }

        var notes = "Carry water and fuel for this session."

        if hours > 1.5 {
            notes += " Aim for ~60g carbs/hour (gels, bars, or real food)."
        }
        if hours > 2.0 {
            notes += " Practice your race-day nutrition plan. Train your gut."
        }
        return notes
    }
}
