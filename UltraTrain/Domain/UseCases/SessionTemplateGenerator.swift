import Foundation

enum SessionTemplateGenerator {

    struct SessionTemplate: Sendable {
        let dayOffset: Int // 0 = Monday, 6 = Sunday
        let type: SessionType
        let intensity: Intensity
        let volumeFraction: Double
        let description: String
        let isTimeBased: Bool
    }

    // MARK: - Public

    static func sessions(
        for skeleton: WeekSkeletonBuilder.WeekSkeleton,
        volume: VolumeCalculator.WeekVolume,
        experience: ExperienceLevel,
        raceEffectiveKm: Double = 0,
        weekNumberInPhase: Int = 0,
        raceOverride: IntermediateRaceHandler.RaceWeekOverride? = nil,
        preferredRunsPerWeek: Int? = nil
    ) -> (sessions: [TrainingSession], workouts: [IntervalWorkout]) {
        let templates: [SessionTemplate]
        var workouts: [IntervalWorkout] = []

        if let override = raceOverride {
            templates = overrideTemplates(for: override.behavior, experience: experience)
        } else if skeleton.isRecoveryWeek {
            templates = recoveryTemplates(experience: experience)
        } else {
            templates = phaseTemplates(
                for: skeleton.phase,
                experience: experience,
                raceEffectiveKm: raceEffectiveKm,
                weekInPhase: weekNumberInPhase
            )
        }

        let adapted = adaptTemplates(templates, preferredRuns: preferredRunsPerWeek)
        // Use fractions directly — do NOT divide by totalFraction to avoid inflation
        // when rest days reduce the sum below 1.0
        // Weekly time budget: estimate from volume at ~6.5 min/km avg pace
        let weeklyTimeBudget = volume.targetVolumeKm * 6.5 * 60.0 // seconds

        let sessions = adapted.map { template in
            let distance: Double
            let duration: TimeInterval
            let elevation: Double

            if template.isTimeBased {
                // Time-based sessions (long runs, B2B): use duration + elevation only
                duration = weeklyTimeBudget * template.volumeFraction
                elevation = volume.targetElevationGainM * template.volumeFraction
                // No distance target for time-based sessions
                distance = 0
            } else if template.volumeFraction > 0 {
                distance = volume.targetVolumeKm * template.volumeFraction
                elevation = volume.targetElevationGainM * template.volumeFraction
                duration = estimateDuration(distanceKm: distance, intensity: template.intensity)
            } else {
                distance = 0
                elevation = 0
                duration = 0
            }

            // Generate workout for quality sessions
            var workoutId: UUID?
            if template.type == .intervals || template.type == .verticalGain {
                let workout = WorkoutProgressionEngine.workout(
                    type: template.type,
                    phase: skeleton.phase,
                    weekInPhase: weekNumberInPhase,
                    intensity: template.intensity,
                    totalDuration: duration
                )
                workouts.append(workout)
                workoutId = workout.id
            }

            return TrainingSession(
                id: UUID(),
                date: skeleton.startDate.adding(days: template.dayOffset),
                type: template.type,
                plannedDistanceKm: (distance * 10).rounded() / 10,
                plannedElevationGainM: (elevation * 10).rounded() / 10,
                plannedDuration: duration,
                intensity: template.intensity,
                description: template.description,
                nutritionNotes: nutritionNotes(duration: duration, distance: distance),
                isCompleted: false,
                isSkipped: false,
                linkedRunId: nil,
                intervalWorkoutId: workoutId
            )
        }

        let markedSessions = markKeySessions(sessions, phase: skeleton.phase)
        return (markedSessions, workouts)
    }

    /// Mark the top 3 most important sessions as key ("do not miss")
    private static func markKeySessions(_ sessions: [TrainingSession], phase: TrainingPhase) -> [TrainingSession] {
        // Priority: longRun/backToBack > intervals/verticalGain > tempo > recovery
        let keyPriority: [SessionType] = [.longRun, .backToBack, .intervals, .verticalGain, .tempo, .recovery]

        let activeSessions = sessions.enumerated().filter { $0.element.type != .rest }
        let sorted = activeSessions.sorted { a, b in
            let aPriority = keyPriority.firstIndex(of: a.element.type) ?? keyPriority.count
            let bPriority = keyPriority.firstIndex(of: b.element.type) ?? keyPriority.count
            return aPriority < bPriority
        }

        let keyIndices = Set(sorted.prefix(min(3, sorted.count)).map { $0.offset })

        return sessions.enumerated().map { idx, session in
            var s = session
            s.isKeySession = keyIndices.contains(idx)
            return s
        }
    }

    // MARK: - Runs Per Week Adaptation

    static func adaptTemplates(
        _ templates: [SessionTemplate],
        preferredRuns: Int?
    ) -> [SessionTemplate] {
        guard let preferred = preferredRuns else { return templates }

        // Split into active sessions and rest days
        let active = templates.filter { $0.type != .rest && $0.volumeFraction > 0 }
        let currentCount = active.count

        if currentCount == preferred {
            return templates
        }

        if currentCount > preferred {
            // Remove lowest-priority sessions first
            let removalPriority: [SessionType] = [.crossTraining, .recovery, .tempo]
            var kept = active
            var toRemove = currentCount - preferred

            for typeToRemove in removalPriority where toRemove > 0 {
                kept = kept.enumerated().compactMap { idx, t in
                    if toRemove > 0 && t.type == typeToRemove {
                        toRemove -= 1
                        return nil
                    }
                    return t
                }
            }

            return buildWeek(from: kept)
        }

        // currentCount < preferred: add easy/recovery sessions to fill
        var expanded = active
        let additionalTypes: [(SessionType, Intensity, String)] = [
            (.recovery, .easy, "Easy recovery run. Conversational pace, Zone 1-2."),
            (.recovery, .easy, "Light aerobic run. Keep it relaxed."),
            (.tempo, .moderate, "Moderate tempo effort to build aerobic capacity."),
        ]
        var addIndex = 0
        while expanded.count < preferred && addIndex < additionalTypes.count {
            let (type, intensity, desc) = additionalTypes[addIndex]
            expanded.append(SessionTemplate(dayOffset: 0, type: type, intensity: intensity,
                                            volumeFraction: 0.08, description: desc, isTimeBased: false))
            addIndex += 1
        }
        // If still not enough, add more recovery runs
        while expanded.count < preferred {
            expanded.append(SessionTemplate(dayOffset: 0, type: .recovery, intensity: .easy,
                                            volumeFraction: 0.06, description: "Easy run. Keep effort comfortable.",
                                            isTimeBased: false))
        }

        return buildWeek(from: expanded)
    }

    /// Arrange active sessions into a 7-day week with rest days filling gaps
    private static func buildWeek(from active: [SessionTemplate]) -> [SessionTemplate] {
        let count = active.count
        guard count > 0 && count <= 7 else { return active }

        // Spread sessions across the week with rest days between hard efforts
        let dayAssignments: [[Int]] = [
            [],                          // 0 sessions (unused)
            [5],                         // 1 session
            [2, 5],                      // 2 sessions
            [1, 3, 5],                   // 3 sessions
            [1, 3, 5, 6],               // 4 sessions
            [1, 2, 3, 5, 6],            // 5 sessions
            [0, 1, 2, 3, 5, 6],         // 6 sessions
            [0, 1, 2, 3, 4, 5, 6],      // 7 sessions
        ]

        let days = dayAssignments[min(count, 7)]
        var result: [SessionTemplate] = []

        for day in 0...6 {
            if let idx = days.firstIndex(of: day), idx < active.count {
                let t = active[idx]
                result.append(SessionTemplate(dayOffset: day, type: t.type, intensity: t.intensity,
                                              volumeFraction: t.volumeFraction, description: t.description,
                                              isTimeBased: t.isTimeBased))
            } else {
                result.append(tpl(day, .rest, .easy, 0, "Rest day. Recovery is part of training."))
            }
        }

        return result
    }

    // MARK: - Helpers

    static func tpl(_ day: Int, _ type: SessionType, _ intensity: Intensity, _ fraction: Double, _ desc: String) -> SessionTemplate {
        SessionTemplate(dayOffset: day, type: type, intensity: intensity, volumeFraction: fraction, description: desc, isTimeBased: false)
    }

    static func tplTime(_ day: Int, _ type: SessionType, _ intensity: Intensity, _ fraction: Double, _ desc: String) -> SessionTemplate {
        SessionTemplate(dayOffset: day, type: type, intensity: intensity, volumeFraction: fraction, description: desc, isTimeBased: true)
    }

    private static func paceForIntensity(_ intensity: Intensity) -> Double {
        switch intensity {
        case .easy:      7.0
        case .moderate:  6.0
        case .hard:      5.5
        case .maxEffort: 5.0
        }
    }

    private static func estimateDuration(distanceKm: Double, intensity: Intensity) -> TimeInterval {
        guard distanceKm > 0 else { return 0 }
        return distanceKm * paceForIntensity(intensity) * 60.0
    }

    private static func nutritionNotes(duration: TimeInterval, distance: Double) -> String? {
        let hours = duration / 3600.0
        guard hours > 1.0 else { return nil }

        var notes = "Carry water and fuel for this session."

        if hours > 1.5 {
            let carbsPerHour = 60
            notes += " Aim for ~\(carbsPerHour)g carbs/hour (gels, bars, or real food)."
        }

        if hours > 2.0 {
            notes += " Practice your race-day nutrition plan. Train your gut."
        }

        if distance > 30 {
            notes += " Consider electrolyte supplementation (~600mg sodium/hour)."
        }

        return notes
    }
}
