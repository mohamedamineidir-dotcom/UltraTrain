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
        weekNumberInPhase: Int = 0,
        raceOverride: IntermediateRaceHandler.RaceWeekOverride? = nil,
        preferredRunsPerWeek: Int? = nil,
        verticalGainEnvironment: VerticalGainEnvironment = .mountain,
        expectedRaceDuration: TimeInterval = 0
    ) -> (sessions: [TrainingSession], workouts: [IntervalWorkout]) {
        let runsPerWeek = preferredRunsPerWeek ?? 5
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
                preferredRunsPerWeek: runsPerWeek
            )
        }

        let sessions = templates.map { template in
            let duration = template.durationSeconds
            let elevation = volume.targetElevationGainM * template.elevationFraction

            // Generate workout for active sessions
            var workoutId: UUID?
            var sessionDescription = template.description
            let shouldGenerateWorkout = template.type != .rest
            if shouldGenerateWorkout {
                let isB2BDay1 = volume.isB2BWeek && template.type == .longRun
                let workout = WorkoutProgressionEngine.workout(
                    type: template.type,
                    phase: skeleton.phase,
                    weekInPhase: weekNumberInPhase,
                    intensity: template.intensity,
                    totalDuration: duration,
                    expectedRaceDuration: expectedRaceDuration,
                    isB2BDay1: isB2BDay1,
                    phaseFocus: skeleton.phaseFocus
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
                verticalGainEnvironment: verticalGainEnvironment
            )

            return TrainingSession(
                id: UUID(),
                date: skeleton.startDate.adding(days: template.dayOffset),
                type: template.type,
                plannedDistanceKm: 0,
                plannedElevationGainM: (elevation * 10).rounded() / 10,
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
        return (markedSessions, workouts)
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
        preferredRunsPerWeek: Int = 5
    ) -> [SessionTemplate] {
        switch phase {
        case .base, .build, .peak:
            return standardWeekTemplates(
                volume: volume, experience: experience, phase: phase,
                weekInPhase: weekNumberInPhase, preferredRunsPerWeek: preferredRunsPerWeek
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
        preferredRunsPerWeek: Int = 5
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

        // Build pool of active sessions in priority order
        // Priority: longRun > intervals > VG > easy1 > easy2 > tempo > crossTraining
        var pool: [(day: Int, template: SessionTemplate)] = [
            (6, tpl(6, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.20,
                    SessionDescriptionGenerator.longRun(phase: phase, isRecoveryWeek: false))),
            (2, tpl(2, .intervals, intervalIntensity, base.intervalSeconds, 0.10,
                    SessionDescriptionGenerator.intervals(phase: phase, isRecoveryWeek: false, weekInPhase: weekInPhase))),
            (3, tpl(3, .verticalGain, vgIntensity, base.vgSeconds, 0.25,
                    SessionDescriptionGenerator.verticalGain(phase: phase, isRecoveryWeek: false))),
            (1, tpl(1, .recovery, .easy, base.easyRun1Seconds, 0.05,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false))),
            (5, tpl(5, .recovery, .easy, base.easyRun2Seconds, 0.05,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false, isPreLongRun: true))),
            (4, tpl(4, .tempo, .moderate, base.intervalSeconds, 0.08,
                    SessionDescriptionGenerator.tempo(phase: phase))),
            (0, tpl(0, .crossTraining, .easy, base.easyRun1Seconds, 0.02,
                    SessionDescriptionGenerator.crossTraining())),
        ]

        // Take only the number of active sessions the user wants
        let activeCount = min(preferredRunsPerWeek, pool.count)
        let activeSlots = pool.prefix(activeCount)
        let activeDays = Set(activeSlots.map(\.day))

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
        let pool: [(day: Int, template: SessionTemplate)] = [
            (5, tpl(5, .longRun, .easy, volume.b2bDay1Seconds, 0.25,
                    SessionDescriptionGenerator.b2bDay1(phase: phase))),
            (6, tpl(6, .backToBack, .easy, volume.b2bDay2Seconds, 0.30,
                    SessionDescriptionGenerator.b2bDay2(phase: phase))),
            (2, tpl(2, .verticalGain, vgIntensity, base.vgSeconds, 0.30,
                    SessionDescriptionGenerator.verticalGain(phase: phase, isRecoveryWeek: false))),
            (1, tpl(1, .recovery, .easy, base.easyRun1Seconds, 0.05,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false))),
            (3, tpl(3, .recovery, .easy, base.easyRun2Seconds, 0.05,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false, isPreLongRun: true))),
            (4, tpl(4, .intervals, .moderate, base.intervalSeconds, 0.05,
                    SessionDescriptionGenerator.intervals(phase: phase, isRecoveryWeek: false, weekInPhase: weekInPhase))),
            (0, tpl(0, .recovery, .easy, base.easyRun1Seconds, 0.02,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false))),
        ]

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

        let pool: [(day: Int, template: SessionTemplate)] = [
            (5, tpl(5, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.15,
                    SessionDescriptionGenerator.longRun(phase: .taper, isRecoveryWeek: false))),
            (1, tpl(1, .intervals, .moderate, base.intervalSeconds, 0.10,
                    SessionDescriptionGenerator.intervals(phase: .taper, isRecoveryWeek: false))),
            (3, tpl(3, .recovery, .easy, base.easyRun1Seconds, 0.05,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false))),
            (4, tpl(4, .recovery, .easy, base.easyRun2Seconds, 0.05,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false, isPreRace: true))),
            (2, tpl(2, .verticalGain, .easy, base.vgSeconds, 0.08,
                    SessionDescriptionGenerator.verticalGain(phase: .taper, isRecoveryWeek: false))),
        ]

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
        let pool: [(day: Int, template: SessionTemplate)] = [
            (5, tpl(5, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.15,
                    SessionDescriptionGenerator.longRun(phase: .recovery, isRecoveryWeek: true))),
            (3, tpl(3, .verticalGain, .easy, base.vgSeconds, 0.15,
                    SessionDescriptionGenerator.verticalGain(phase: .recovery, isRecoveryWeek: true))),
            (1, tpl(1, .recovery, .easy, base.easyRun1Seconds, 0.08,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: true))),
            (4, tpl(4, .recovery, .easy, base.easyRun2Seconds, 0.05,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: true))),
            (2, tpl(2, .recovery, .easy, base.easyRun1Seconds, 0.05,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: true))),
            (6, tpl(6, .recovery, .easy, base.easyRun2Seconds, 0.04,
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
