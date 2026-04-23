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
        isRoadRace: Bool = false,
        intermediateRaceContext: RaceContext? = nil
    ) -> (sessions: [TrainingSession], workouts: [IntervalWorkout], strengthWorkouts: [StrengthWorkout]) {
        let runsPerWeek = preferredRunsPerWeek
        let templates: [SessionTemplate]
        var workouts: [IntervalWorkout] = []

        if let override = raceOverride {
            templates = overrideTemplates(for: override.behavior, volume: volume, preferredRunsPerWeek: runsPerWeek, raceContext: intermediateRaceContext)
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

    // MARK: - Shared S&C generation helper (RR-5)

    /// Generates S&C TrainingSessions + StrengthWorkouts for a given week.
    /// Called by both the trail pipeline (internally) and the road pipeline
    /// (via TrainingPlanGenerator.generateRoadPlan) so road athletes who
    /// opted into strength training actually get sessions scheduled.
    static func generateStrengthForWeek(
        config: StrengthSessionGenerator.Config,
        weekStartDate: Date,
        existingRunningSessions: [SessionTemplate]
    ) -> (sessions: [TrainingSession], workouts: [StrengthWorkout]) {
        let scCount = StrengthSessionGenerator.sessionsPerWeek(config: config)
        guard scCount > 0 else { return ([], []) }

        let availableDays = StrengthSessionGenerator.availableDayOffsets(
            runningSessions: existingRunningSessions,
            config: config
        )
        let scDays = pickSCDays(
            availableDays: availableDays,
            count: scCount,
            existingSessions: existingRunningSessions
        )

        var sessions: [TrainingSession] = []
        var workouts: [StrengthWorkout] = []
        for (i, dayOffset) in scDays.enumerated() {
            let workout = StrengthSessionGenerator.generateWorkout(config: config, sessionIndex: i)
            workouts.append(workout)

            sessions.append(TrainingSession(
                id: UUID(),
                date: weekStartDate.adding(days: dayOffset),
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
                coachAdvice: scCoachAdvice(config: config, category: workout.category)
            ))
        }
        return (sessions, workouts)
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

    struct RaceContext: Sendable {
        let name: String
        let distanceKm: Double
        let elevationGainM: Double
        let estimatedDurationSeconds: TimeInterval
        let goalType: RaceGoal
    }

    static func overrideTemplates(
        for behavior: IntermediateRaceHandler.Behavior,
        volume: VolumeCalculator.WeekVolume,
        preferredRunsPerWeek: Int = 5,
        raceContext: RaceContext? = nil,
        isRoadRace: Bool = false
    ) -> [SessionTemplate] {
        let raw: [SessionTemplate]
        switch behavior {
        case .miniTaper:
            raw = miniTaperTemplates(volume: volume, raceContext: raceContext, isRoadRace: isRoadRace)
        case .raceWeek(let priority):
            raw = priority == .cRace
                ? cRaceWeekTemplates(volume: volume, raceContext: raceContext)
                : bRaceWeekTemplates(volume: volume, raceContext: raceContext)
        case .postRaceRecovery:
            raw = postRaceRecoveryTemplates(volume: volume, raceContext: raceContext, isRoadRace: isRoadRace)
        }
        return capActiveSessionsForOverride(raw, preferredRunsPerWeek: preferredRunsPerWeek)
    }

    /// Caps active (non-rest) sessions in override templates to respect preferredRunsPerWeek.
    /// Converts excess active sessions (from the end of the week) to rest days.
    /// Never converts race-day or rest sessions.
    private static func capActiveSessionsForOverride(
        _ templates: [SessionTemplate],
        preferredRunsPerWeek: Int
    ) -> [SessionTemplate] {
        let activeCount = templates.filter { $0.type != .rest }.count
        guard activeCount > preferredRunsPerWeek else { return templates }

        var excess = activeCount - preferredRunsPerWeek
        // Walk backwards, converting recovery sessions to rest (skip race/rest/tempo/intervals)
        var result = templates
        for i in result.indices.reversed() where excess > 0 {
            if result[i].type == .recovery {
                result[i] = tpl(result[i].dayOffset, .rest, .easy, 0, 0, "Rest day.")
                excess -= 1
            }
        }
        return result
    }

    // MARK: - Mini-Taper (week before B-race)
    //
    // Research (Koop, Daniels, Roche):
    // - Keep normal week structure. Maintain intensity, only reduce volume.
    // - Volume reduction scales with race distance:
    //   <20K: ~5-10% reduction (barely noticeable)
    //   20-40K: ~10-15% reduction
    //   40-60K: ~15-20% reduction
    //   60K+: ~20-25% reduction
    // - Never remove quality sessions. Just shorten them slightly.

    private static func miniTaperTemplates(
        volume: VolumeCalculator.WeekVolume,
        raceContext: RaceContext? = nil,
        isRoadRace: Bool = false
    ) -> [SessionTemplate] {
        let base = volume.baseSessionDurations
        let raceKm = raceContext?.distanceKm ?? 30

        // Volume reduction factor based on race distance
        let reductionFactor: Double
        switch raceKm {
        case ..<20:  reductionFactor = 0.93  // 7% reduction
        case ..<40:  reductionFactor = 0.88  // 12% reduction
        case ..<60:  reductionFactor = 0.83  // 17% reduction
        default:     reductionFactor = 0.78  // 22% reduction
        }

        // RR-4: For road races the mid-week workout is a threshold tempo,
        // not a vertical-gain session. Long run goes flat (0 elevation
        // fraction). Trail races retain the uphill day + hilly long run.
        let day3Type: SessionType = isRoadRace ? .tempo : .verticalGain
        let day3Desc: String = isRoadRace
            ? "Short threshold tempo, dress rehearsal of race effort. Stay sharp."
            : "Uphill session, slightly reduced. Maintain vertical efficiency."
        let longRunElevFraction: Double = isRoadRace ? 0 : 0.5

        return [
            tpl(0, .recovery, .easy, base.easyRun1Seconds * reductionFactor, 0,
                "Easy run. Normal week structure, slightly reduced volume."),
            tpl(1, .intervals, .moderate, base.intervalSeconds * reductionFactor, 0,
                "Intervals at normal intensity, slightly reduced volume. Stay sharp."),
            tpl(2, .recovery, .easy, base.easyRun1Seconds * reductionFactor, 0,
                "Easy run at conversational pace."),
            tpl(3, day3Type, .moderate, base.vgSeconds * reductionFactor, 0,
                day3Desc),
            tpl(4, .recovery, .easy, base.easyRun2Seconds * reductionFactor, 0,
                "Easy run. Keep legs loose before race week."),
            tpl(5, .longRun, .easy, volume.targetLongRunDurationSeconds * reductionFactor, longRunElevFraction,
                "Long run at reduced volume. Save energy for race week."),
            tpl(6, .rest, .easy, 0, 0,
                "Rest day. Race week starts tomorrow."),
        ]
    }

    // MARK: - B-Race Week
    //
    // Research (Koop, Roche, Magness):
    // - Adaptation scales with race distance/D+. A 15K race needs almost no change.
    //   A 60K+ race needs 2-3 days freshening up.
    // - Keep quality early in the week for shorter races.
    // - Rest days before race scale: <20K=1 day, 20-40K=1-2 days, 40-60K=2 days, 60K+=2-3 days.

    static func bRaceWeekTemplates(
        volume: VolumeCalculator.WeekVolume? = nil,
        raceContext: RaceContext? = nil
    ) -> [SessionTemplate] {
        let raceDuration = raceContext?.estimatedDurationSeconds ?? 0
        let raceName = raceContext?.name ?? "B-Race"
        let raceDistKm = raceContext?.distanceKm ?? 30
        let raceElevM = raceContext?.elevationGainM ?? 0

        let raceDesc: String
        if raceDistKm > 0 {
            let distStr = raceDistKm >= 100 ? String(format: "%.0f km", raceDistKm) : String(format: "%.1f km", raceDistKm)
            let elevStr = raceElevM > 0 ? " / D+ \(Int(raceElevM))m" : ""
            raceDesc = "RACE: \(raceName) (\(distStr)\(elevStr)). Execute your plan. Trust your fitness."
        } else {
            raceDesc = "RACE DAY: \(raceName). Execute your plan. Trust your fitness."
        }

        let baseEasy = volume?.baseSessionDurations.easyRun1Seconds ?? 2700
        let baseInterval = volume?.baseSessionDurations.intervalSeconds ?? 3000

        // Stress score: combines distance + elevation to determine adaptation level
        let stressScore = raceDistKm + (raceElevM / 100)

        if stressScore < 25 {
            // Short race (<20K, low D+): almost normal week, 1 rest day before
            return [
                tpl(0, .recovery, .easy, baseEasy * 0.85, 0,
                    "Easy run. Normal routine."),
                tpl(1, .intervals, .moderate, baseInterval * 0.7, 0,
                    "Short opener intervals. Stay sharp for race."),
                tpl(2, .recovery, .easy, baseEasy * 0.8, 0,
                    "Easy run at conversational pace."),
                tpl(3, .recovery, .easy, baseEasy * 0.7, 0,
                    "Easy run. Start freshening up."),
                tpl(4, .rest, .easy, 0, 0,
                    "Rest day. Prep gear and nutrition."),
                tpl(5, .race, .maxEffort, raceDuration, 0, raceDesc),
                tpl(6, .recovery, .easy, baseEasy * 0.6, 0,
                    "Easy shakeout. Recover from race effort."),
            ]
        } else if stressScore < 55 {
            // Medium race (20-40K or moderate D+): 1-2 rest days before
            return [
                tpl(0, .recovery, .easy, baseEasy * 0.8, 0,
                    "Easy run. Keep routine going."),
                tpl(1, .recovery, .easy, baseEasy * 0.7, 0,
                    "Easy run with strides at the end. Stay sharp."),
                tpl(2, .recovery, .easy, baseEasy * 0.6, 0,
                    "Short shakeout. Conversational pace."),
                tpl(3, .rest, .easy, 0, 0,
                    "Rest day. Prep gear, nutrition, and race plan."),
                tpl(4, .rest, .easy, 0, 0,
                    "Rest day. Visualize your race. Stay confident."),
                tpl(5, .race, .maxEffort, raceDuration, 0, raceDesc),
                tpl(6, .recovery, .easy, baseEasy * 0.5, 0,
                    "Easy shakeout if legs allow. Walk/stretch if not."),
            ]
        } else {
            // Long/hard race (50K+ or big D+): 2-3 rest days before
            return [
                tpl(0, .recovery, .easy, baseEasy * 0.7, 0,
                    "Easy run. Keep legs loose."),
                tpl(1, .recovery, .easy, baseEasy * 0.6, 0,
                    "Short easy run. Light strides at the end."),
                tpl(2, .rest, .easy, 0, 0,
                    "Rest day. Begin carb-loading if needed."),
                tpl(3, .rest, .easy, 0, 0,
                    "Rest day. Prep gear, nutrition, race plan."),
                tpl(4, .recovery, .easy, baseEasy * 0.35, 0,
                    "Very short shakeout. 10-15 min to stay loose."),
                tpl(5, .race, .maxEffort, raceDuration, 0, raceDesc),
                tpl(6, .rest, .easy, 0, 0,
                    "Complete rest. Body needs recovery after a big effort."),
            ]
        }
    }

    // MARK: - C-Race Week
    //
    // Research (Koop, Jornet, Roche):
    // - C-races are training races. Minimal disruption.
    // - Same distance-based scaling as B-race but even less aggressive.
    // - Short races: keep quality session. Long races: replace quality with easy.

    static func cRaceWeekTemplates(
        volume: VolumeCalculator.WeekVolume? = nil,
        raceContext: RaceContext? = nil
    ) -> [SessionTemplate] {
        let raceDuration = raceContext?.estimatedDurationSeconds ?? 0
        let raceName = raceContext?.name ?? "C-Race"
        let raceDistKm = raceContext?.distanceKm ?? 20
        let raceElevM = raceContext?.elevationGainM ?? 0

        let raceDesc: String
        if raceDistKm > 0 {
            let distStr = raceDistKm >= 100 ? String(format: "%.0f km", raceDistKm) : String(format: "%.1f km", raceDistKm)
            let elevStr = raceElevM > 0 ? " / D+ \(Int(raceElevM))m" : ""
            raceDesc = "RACE: \(raceName) (\(distStr)\(elevStr)). Use as a hard training effort."
        } else {
            raceDesc = "RACE DAY: \(raceName). Use as a hard training effort."
        }

        let baseEasy = volume?.baseSessionDurations.easyRun1Seconds ?? 2700
        let baseInterval = volume?.baseSessionDurations.intervalSeconds ?? 3000

        if raceDistKm < 30 {
            // Short C-race: keep a quality session, almost normal week
            return [
                tpl(0, .recovery, .easy, baseEasy * 0.9, 0, "Easy run. Normal start to the week."),
                tpl(1, .intervals, .moderate, baseInterval * 0.7, 0, "Opener intervals. Stay sharp for race."),
                tpl(2, .recovery, .easy, baseEasy * 0.85, 0, "Easy run at conversational pace."),
                tpl(3, .recovery, .easy, baseEasy * 0.75, 0, "Easy run. Freshening up."),
                tpl(4, .rest, .easy, 0, 0, "Rest day. Prepare gear."),
                tpl(5, .race, .maxEffort, raceDuration, 0, raceDesc),
                tpl(6, .recovery, .easy, baseEasy * 0.6, 0, "Easy recovery run. Shake out race legs."),
            ]
        } else {
            // Longer C-race (30K+): drop quality, more easy days before
            return [
                tpl(0, .recovery, .easy, baseEasy * 0.85, 0, "Easy run. Normal start to the week."),
                tpl(1, .recovery, .easy, baseEasy * 0.8, 0, "Easy run at conversational pace."),
                tpl(2, .recovery, .easy, baseEasy * 0.7, 0, "Easy run. Starting to freshen up."),
                tpl(3, .recovery, .easy, baseEasy * 0.5, 0, "Short easy run."),
                tpl(4, .rest, .easy, 0, 0, "Rest day. Prepare gear and nutrition."),
                tpl(5, .race, .maxEffort, raceDuration, 0, raceDesc),
                tpl(6, .recovery, .easy, baseEasy * 0.5, 0, "Easy recovery run. Shake out race legs."),
            ]
        }
    }

    // MARK: - Post-Race Recovery (week after B-race)
    //
    // Research (Koop, Roche, Magness, Canova):
    // - Progressive return to quality. Not all-easy weeks.
    // - Rest 1-3 days (based on race distance), then reintroduce:
    //   easy runs → short quality session (intervals or uphill) → shortened long run.
    // - Quality reintroduction maintains neuromuscular patterns (Canova).
    // - Long run at end of week at ~60-75% of normal to rebuild aerobic base.
    // - Scales with race distance: shorter race = faster return to quality.

    private static func postRaceRecoveryTemplates(
        volume: VolumeCalculator.WeekVolume,
        raceContext: RaceContext? = nil,
        isRoadRace: Bool = false
    ) -> [SessionTemplate] {
        let raceKm = raceContext?.distanceKm ?? 50
        let base = volume.baseSessionDurations
        let longRun = volume.targetLongRunDurationSeconds

        // RR-13: For road races, strip .verticalGain sessions and zero the
        // long-run elevationFraction. Road athletes returning from a B-race
        // don't do hill repeats or hilly long runs. The <25K branch's day 4
        // VG session becomes a moderate tempo instead.
        let lrElevFraction04: Double = isRoadRace ? 0 : 0.4
        let lrElevFraction045: Double = isRoadRace ? 0 : 0.45
        let lrElevFraction05: Double = isRoadRace ? 0 : 0.5
        let lrElevFraction055: Double = isRoadRace ? 0 : 0.55
        let day4Type: SessionType = isRoadRace ? .tempo : .verticalGain
        let day4Desc: String = isRoadRace
            ? "Moderate tempo. Rebuild threshold feel without overloading fresh-from-race legs."
            : "Uphill session at moderate effort. Rebuild vertical strength."

        if raceKm > 100 {
            // Ultra 100K+: 2 rest days, easy mid-week, short quality Thu, shortened long run
            return [
                tpl(0, .rest, .easy, 0, 0, "Complete rest. Recover from a big effort."),
                tpl(1, .rest, .easy, 0, 0, "Rest. Walk if you feel like it."),
                tpl(2, .recovery, .easy, base.easyRun1Seconds * 0.5, 0,
                    "First easy jog. Very short and gentle."),
                tpl(3, .recovery, .easy, base.easyRun1Seconds * 0.6, 0,
                    "Easy run. Gradually rebuilding."),
                tpl(4, .intervals, .moderate, base.intervalSeconds * 0.5, 0,
                    "Short intervals at moderate effort. Reawaken leg speed."),
                tpl(5, .recovery, .easy, base.easyRun2Seconds * 0.6, 0,
                    "Easy run. Pre-long-run loosener."),
                tpl(6, .longRun, .easy, longRun * 0.55, lrElevFraction04,
                    "Shortened long run. Rebuild aerobic base gently."),
            ]
        } else if raceKm > 50 {
            // 50-100K: 1 rest day, easy Tue, quality Wed-Thu, shortened long run
            return [
                tpl(0, .rest, .easy, 0, 0, "Complete rest. Let your body recover."),
                tpl(1, .recovery, .easy, base.easyRun1Seconds * 0.6, 0,
                    "First easy jog. Short and gentle."),
                tpl(2, .recovery, .easy, base.easyRun1Seconds * 0.7, 0,
                    "Easy recovery run. Keep it relaxed."),
                tpl(3, .intervals, .moderate, base.intervalSeconds * 0.6, 0,
                    "Moderate intervals. Reintroduce quality — don't force it."),
                tpl(4, .recovery, .easy, base.easyRun2Seconds * 0.7, 0,
                    "Easy run. Legs should be feeling better."),
                tpl(5, .recovery, .easy, base.easyRun2Seconds * 0.65, 0,
                    "Easy pre-long-run loosener."),
                tpl(6, .longRun, .easy, longRun * 0.65, lrElevFraction045,
                    "Shortened long run. Rebuild the aerobic engine."),
            ]
        } else if raceKm > 25 {
            // 25-50K: 1 rest day, quick return to quality + long run
            return [
                tpl(0, .rest, .easy, 0, 0, "Rest day after your race."),
                tpl(1, .recovery, .easy, base.easyRun1Seconds * 0.7, 0,
                    "Easy jog. Shake out race legs."),
                tpl(2, .recovery, .easy, base.easyRun1Seconds * 0.75, 0,
                    "Easy run at conversational pace."),
                tpl(3, .intervals, .moderate, base.intervalSeconds * 0.65, 0,
                    "Moderate intervals. Reintroduce leg speed."),
                tpl(4, .recovery, .easy, base.easyRun2Seconds * 0.75, 0,
                    "Easy run. Building back."),
                tpl(5, .recovery, .easy, base.easyRun2Seconds * 0.7, 0,
                    "Easy pre-long-run loosener."),
                tpl(6, .longRun, .easy, longRun * 0.7, lrElevFraction05,
                    "Moderately shortened long run. Back toward normal."),
            ]
        } else {
            // < 25K: almost normal week — fast return to quality + near-full long run
            return [
                tpl(0, .rest, .easy, 0, 0, "Rest day after your race."),
                tpl(1, .recovery, .easy, base.easyRun1Seconds * 0.8, 0,
                    "Easy run. Shake out race effort."),
                tpl(2, .intervals, .moderate, base.intervalSeconds * 0.7, 0,
                    "Intervals at moderate effort. Maintain sharpness."),
                tpl(3, .recovery, .easy, base.easyRun1Seconds * 0.8, 0,
                    "Easy run at conversational pace."),
                tpl(4, day4Type, .moderate, base.vgSeconds * 0.7, 0,
                    day4Desc),
                tpl(5, .recovery, .easy, base.easyRun2Seconds * 0.8, 0,
                    "Easy pre-long-run loosener."),
                tpl(6, .longRun, .easy, longRun * 0.8, lrElevFraction055,
                    "Near-normal long run. Back on track."),
            ]
        }
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
