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
            return standardWeekTemplates(volume: volume, experience: experience, phase: .base)
        case .build:
            return standardWeekTemplates(volume: volume, experience: experience, phase: .build)
        case .peak:
            return standardWeekTemplates(volume: volume, experience: experience, phase: .peak)
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
        phase: TrainingPhase
    ) -> [SessionTemplate] {
        let base = volume.baseSessionDurations
        let vgIntensity: Intensity = (experience == .advanced || experience == .elite) ? .hard : .moderate

        if volume.isB2BWeek {
            // B2B week: 2 easy (shorter) + 1 VG + B2B day1 + B2B day2
            return [
                tpl(0, .rest, .easy, 0, 0, "Rest day. Prioritize sleep for adaptation."),
                tpl(1, .recovery, .easy, base.easyRun1Seconds, 0.05,
                    "Easy run at conversational pace (Zone 2)."),
                tpl(2, .verticalGain, vgIntensity, base.vgSeconds, 0.30,
                    "Vertical gain session. Build climbing power."),
                tpl(3, .recovery, .easy, base.easyRun2Seconds, 0.05,
                    "Easy run. Keep it relaxed before the weekend block."),
                tpl(4, .rest, .easy, 0, 0, "Rest day. Hydrate well for B2B."),
                tpl(5, .longRun, .easy, volume.b2bDay1Seconds, 0.25,
                    "B2B Day 1: Long run building fatigue for tomorrow. Easy pace (Zone 2)."),
                tpl(6, .backToBack, .easy, volume.b2bDay2Seconds, 0.30,
                    "B2B Day 2: Long run on tired legs. Simulate ultra fatigue (Zone 2)."),
            ]
        }

        // Non-B2B: 2 easy + 1 interval + 1 VG + 1 long run
        let intervalIntensity: Intensity = phase == .base ? .moderate : .hard
        return [
            tpl(0, .rest, .easy, 0, 0, "Rest day. Recovery is part of training."),
            tpl(1, .recovery, .easy, base.easyRun1Seconds, 0.05,
                "Easy run at conversational pace (Zone 2)."),
            tpl(2, .intervals, intervalIntensity, base.intervalSeconds, 0.10,
                "Intervals at \(intervalIntensity == .hard ? "VO2max (Zone 4)" : "threshold (Zone 3)"). Build speed."),
            tpl(3, .verticalGain, vgIntensity, base.vgSeconds, 0.25,
                "Vertical gain session. Build climbing strength."),
            tpl(4, .rest, .easy, 0, 0, "Rest day. Prepare for the weekend."),
            tpl(5, .recovery, .easy, base.easyRun2Seconds, 0.05,
                "Easy run. Loosen up before the long run."),
            tpl(6, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.20,
                "Long run (Zone 2). Practice race-day nutrition. Include elevation."),
        ]
    }

    // MARK: - Taper

    private static func taperTemplates(volume: VolumeCalculator.WeekVolume) -> [SessionTemplate] {
        let base = volume.baseSessionDurations
        return [
            tpl(0, .rest, .easy, 0, 0, "Rest day. Enjoy the taper — trust your training."),
            tpl(1, .intervals, .moderate, base.intervalSeconds, 0.10,
                "Short opener intervals. Stay sharp without fatiguing."),
            tpl(2, .rest, .easy, 0, 0, "Rest day. Light stretching and foam rolling."),
            tpl(3, .recovery, .easy, base.easyRun1Seconds, 0.05,
                "Easy shakeout run. Keep it short and comfortable."),
            tpl(4, .rest, .easy, 0, 0, "Rest day. Final gear and nutrition prep."),
            tpl(5, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.15,
                "Reduced long run at easy effort. Save it for race day."),
            tpl(6, .rest, .easy, 0, 0, "Full rest. Sleep, hydrate, visualize your race."),
        ]
    }

    // MARK: - Recovery

    static func recoveryTemplates(volume: VolumeCalculator.WeekVolume) -> [SessionTemplate] {
        let base = volume.baseSessionDurations
        return [
            tpl(0, .rest, .easy, 0, 0, "Recovery week. Let your body absorb the training."),
            tpl(1, .recovery, .easy, base.easyRun1Seconds, 0.08,
                "Easy recovery jog. Very comfortable pace, Zone 1 only."),
            tpl(2, .rest, .easy, 0, 0, "Rest day. Focus on nutrition and sleep quality."),
            tpl(3, .verticalGain, .easy, base.vgSeconds, 0.15,
                "Light vertical gain. Easy effort, enjoy the trail."),
            tpl(4, .rest, .easy, 0, 0, "Rest day. Stretching and mobility work."),
            tpl(5, .longRun, .easy, volume.targetLongRunDurationSeconds, 0.15,
                "Reduced long run at very easy pace. Enjoy the scenery."),
            tpl(6, .rest, .easy, 0, 0, "Full rest day. You've earned it."),
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
