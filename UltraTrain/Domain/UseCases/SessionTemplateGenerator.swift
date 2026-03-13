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
        let templates: [SessionTemplate]
        var workouts: [IntervalWorkout] = []

        if let override = raceOverride {
            templates = overrideTemplates(for: override.behavior, volume: volume)
        } else if skeleton.isRecoveryWeek {
            templates = recoveryTemplates(volume: volume)
        } else {
            templates = phaseTemplates(
                for: skeleton.phase,
                volume: volume,
                experience: experience,
                weekNumberInPhase: weekNumberInPhase
            )
        }

        let sessions = templates.map { template in
            let duration = template.durationSeconds
            let elevation = volume.targetElevationGainM * template.elevationFraction

            // Generate workout for quality sessions
            var workoutId: UUID?
            var sessionDescription = template.description
            let shouldGenerateWorkout = template.type != .rest
            if shouldGenerateWorkout {
                let workout = WorkoutProgressionEngine.workout(
                    type: template.type,
                    phase: skeleton.phase,
                    weekInPhase: weekNumberInPhase,
                    intensity: template.intensity,
                    totalDuration: duration,
                    expectedRaceDuration: expectedRaceDuration
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
        weekNumberInPhase: Int
    ) -> [SessionTemplate] {
        switch phase {
        case .base:
            return standardWeekTemplates(volume: volume, experience: experience, phase: .base, weekInPhase: weekNumberInPhase)
        case .build:
            return standardWeekTemplates(volume: volume, experience: experience, phase: .build, weekInPhase: weekNumberInPhase)
        case .peak:
            return standardWeekTemplates(volume: volume, experience: experience, phase: .peak, weekInPhase: weekNumberInPhase)
        case .taper:
            return taperTemplates(volume: volume)
        case .recovery, .race:
            return recoveryTemplates(volume: volume)
        }
    }

    // MARK: - Standard Week (2 easy + 1 VG + 1 interval + 1 longRun OR B2B variant)

    private static func standardWeekTemplates(
        volume: VolumeCalculator.WeekVolume,
        experience: ExperienceLevel,
        phase: TrainingPhase,
        weekInPhase: Int = 0
    ) -> [SessionTemplate] {
        let base = volume.baseSessionDurations
        let vgIntensity: Intensity = (experience == .advanced || experience == .elite) ? .hard : .moderate

        if volume.isB2BWeek {
            return [
                tpl(0, .rest, .easy, 0, 0,
                    SessionDescriptionGenerator.rest(isRecoveryWeek: false)),
                tpl(1, .recovery, .easy, base.easyRun1Seconds, 0.05,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false)),
                tpl(2, .verticalGain, vgIntensity, base.vgSeconds, 0.30,
                    SessionDescriptionGenerator.verticalGain(phase: phase, isRecoveryWeek: false)),
                tpl(3, .recovery, .easy, base.easyRun2Seconds, 0.05,
                    SessionDescriptionGenerator.easyRun(isRecoveryWeek: false, isPreLongRun: true)),
                tpl(4, .rest, .easy, 0, 0,
                    SessionDescriptionGenerator.rest(isRecoveryWeek: false)),
                tpl(5, .longRun, .easy, volume.b2bDay1Seconds, 0.25,
                    SessionDescriptionGenerator.b2bDay1(phase: phase)),
                tpl(6, .backToBack, .easy, volume.b2bDay2Seconds, 0.30,
                    SessionDescriptionGenerator.b2bDay2(phase: phase)),
            ]
        }

        let intervalIntensity: Intensity = phase == .base ? .moderate : .hard
        return [
            tpl(0, .rest, .easy, 0, 0,
                SessionDescriptionGenerator.rest(isRecoveryWeek: false)),
            tpl(1, .recovery, .easy, base.easyRun1Seconds, 0.05,
                SessionDescriptionGenerator.easyRun(isRecoveryWeek: false)),
            tpl(2, .intervals, intervalIntensity, base.intervalSeconds, 0.10,
                SessionDescriptionGenerator.intervals(phase: phase, isRecoveryWeek: false, weekInPhase: weekInPhase)),
            tpl(3, .verticalGain, vgIntensity, base.vgSeconds, 0.25,
                SessionDescriptionGenerator.verticalGain(phase: phase, isRecoveryWeek: false)),
            tpl(4, .rest, .easy, 0, 0,
                SessionDescriptionGenerator.rest(isRecoveryWeek: false)),
            tpl(5, .recovery, .easy, base.easyRun2Seconds, 0.05,
                SessionDescriptionGenerator.easyRun(isRecoveryWeek: false, isPreLongRun: true)),
            tpl(6, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.20,
                SessionDescriptionGenerator.longRun(phase: phase, isRecoveryWeek: false)),
        ]
    }

    // MARK: - Taper

    private static func taperTemplates(volume: VolumeCalculator.WeekVolume) -> [SessionTemplate] {
        let base = volume.baseSessionDurations
        return [
            tpl(0, .rest, .easy, 0, 0,
                SessionDescriptionGenerator.rest(isRecoveryWeek: false)),
            tpl(1, .intervals, .moderate, base.intervalSeconds, 0.10,
                SessionDescriptionGenerator.intervals(phase: .taper, isRecoveryWeek: false)),
            tpl(2, .rest, .easy, 0, 0,
                SessionDescriptionGenerator.rest(isRecoveryWeek: false)),
            tpl(3, .recovery, .easy, base.easyRun1Seconds, 0.05,
                SessionDescriptionGenerator.easyRun(isRecoveryWeek: false)),
            tpl(4, .rest, .easy, 0, 0,
                SessionDescriptionGenerator.rest(isRecoveryWeek: false, isPreRace: true)),
            tpl(5, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.15,
                SessionDescriptionGenerator.longRun(phase: .taper, isRecoveryWeek: false)),
            tpl(6, .rest, .easy, 0, 0,
                SessionDescriptionGenerator.rest(isRecoveryWeek: false)),
        ]
    }

    // MARK: - Recovery

    static func recoveryTemplates(volume: VolumeCalculator.WeekVolume) -> [SessionTemplate] {
        let base = volume.baseSessionDurations
        return [
            tpl(0, .rest, .easy, 0, 0,
                SessionDescriptionGenerator.rest(isRecoveryWeek: true)),
            tpl(1, .recovery, .easy, base.easyRun1Seconds, 0.08,
                SessionDescriptionGenerator.easyRun(isRecoveryWeek: true)),
            tpl(2, .rest, .easy, 0, 0,
                SessionDescriptionGenerator.rest(isRecoveryWeek: true)),
            tpl(3, .verticalGain, .easy, base.vgSeconds, 0.15,
                SessionDescriptionGenerator.verticalGain(phase: .recovery, isRecoveryWeek: true)),
            tpl(4, .rest, .easy, 0, 0,
                SessionDescriptionGenerator.rest(isRecoveryWeek: true)),
            tpl(5, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.15,
                SessionDescriptionGenerator.longRun(phase: .recovery, isRecoveryWeek: true)),
            tpl(6, .rest, .easy, 0, 0,
                SessionDescriptionGenerator.rest(isRecoveryWeek: true)),
        ]
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
