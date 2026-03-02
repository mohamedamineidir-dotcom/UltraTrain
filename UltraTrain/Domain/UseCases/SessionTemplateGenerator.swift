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
        let totalFraction = adapted.reduce(0.0) { $0 + $1.volumeFraction }
        let weeklyTimeBudget = volume.targetVolumeKm * 7.0 * 60.0 // rough time in seconds

        let sessions = adapted.map { template in
            let distance: Double
            let duration: TimeInterval
            let elevation: Double

            if template.isTimeBased && totalFraction > 0 {
                // Time-based: duration is primary, distance is estimated
                duration = weeklyTimeBudget * (template.volumeFraction / totalFraction)
                let paceMinPerKm = paceForIntensity(template.intensity)
                distance = duration / (paceMinPerKm * 60.0)
                elevation = totalFraction > 0
                    ? volume.targetElevationGainM * (template.volumeFraction / totalFraction)
                    : 0
            } else if totalFraction > 0 {
                distance = volume.targetVolumeKm * (template.volumeFraction / totalFraction)
                elevation = volume.targetElevationGainM * (template.volumeFraction / totalFraction)
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

        return (sessions, workouts)
    }

    // MARK: - Runs Per Week Adaptation

    static func adaptTemplates(
        _ templates: [SessionTemplate],
        preferredRuns: Int?
    ) -> [SessionTemplate] {
        guard let preferred = preferredRuns else { return templates }
        var result = templates
        let currentRunCount = result.filter { $0.type != .rest && $0.volumeFraction > 0 }.count
        var toRemove = currentRunCount - preferred
        guard toRemove > 0 else { return result }

        // Collect volume being removed to redistribute
        var removedVolume = 0.0
        let removalPriority: [SessionType] = [.recovery, .crossTraining, .tempo]

        for typeToRemove in removalPriority where toRemove > 0 {
            for i in result.indices where toRemove > 0 {
                if result[i].type == typeToRemove && result[i].volumeFraction > 0 {
                    removedVolume += result[i].volumeFraction
                    result[i] = tpl(result[i].dayOffset, .rest, .easy, 0, "Rest day. Recovery is part of training.")
                    toRemove -= 1
                }
            }
        }

        // Redistribute removed volume among remaining active sessions
        let remainingActive = result.filter { $0.type != .rest && $0.volumeFraction > 0 }
        guard !remainingActive.isEmpty, removedVolume > 0 else { return result }

        let totalRemaining = remainingActive.reduce(0.0) { $0 + $1.volumeFraction }
        guard totalRemaining > 0 else { return result }

        for i in result.indices {
            if result[i].type != .rest && result[i].volumeFraction > 0 {
                let share = result[i].volumeFraction / totalRemaining
                let bonus = removedVolume * share
                result[i] = SessionTemplate(
                    dayOffset: result[i].dayOffset,
                    type: result[i].type,
                    intensity: result[i].intensity,
                    volumeFraction: result[i].volumeFraction + bonus,
                    description: result[i].description,
                    isTimeBased: result[i].isTimeBased
                )
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
