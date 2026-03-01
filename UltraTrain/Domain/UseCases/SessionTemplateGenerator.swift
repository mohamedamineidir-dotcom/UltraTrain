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

    // MARK: - Phase Templates

    private static func phaseTemplates(
        for phase: TrainingPhase,
        experience: ExperienceLevel,
        raceEffectiveKm: Double,
        weekInPhase: Int
    ) -> [SessionTemplate] {
        switch phase {
        case .base:
            return baseTemplates(experience: experience)
        case .build:
            return buildTemplates(experience: experience, raceEffectiveKm: raceEffectiveKm, weekInPhase: weekInPhase)
        case .peak:
            return peakTemplates(experience: experience, raceEffectiveKm: raceEffectiveKm, weekInPhase: weekInPhase)
        case .taper:
            return taperTemplates()
        case .recovery, .race:
            return recoveryTemplates(experience: experience)
        }
    }

    private static func baseTemplates(experience: ExperienceLevel) -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, "Rest day. Focus on sleep and mobility work."),
            tpl(1, .recovery, .easy, 0.10, "Easy recovery run at conversational pace. Keep heart rate in Zone 1-2."),
            tpl(2, .rest, .easy, 0, "Rest day. Light stretching or yoga recommended."),
            tpl(3, .tempo, .moderate, 0.15, "Tempo run at comfortably hard pace. Maintain steady effort in Zone 3."),
            tpl(4, .rest, .easy, 0, "Rest day. Prepare gear and nutrition for the long run."),
            tplTime(5, .longRun, .easy, 0.45, "Long run at easy pace. Practice race-day nutrition strategy. Stay in Zone 2."),
            crossTrainingOrAlternative(day: 6, experience: experience)
        ]
    }

    private static func buildTemplates(experience: ExperienceLevel, raceEffectiveKm: Double, weekInPhase: Int) -> [SessionTemplate] {
        let hasSignificantElevation = raceEffectiveKm > 0 && raceEffectiveKm > 1.3 * (raceEffectiveKm - raceEffectiveKm * 0.23)
        let wantsDoubleVertical = hasSignificantElevation && weekInPhase % 2 == 1 && (experience == .advanced || experience == .elite)
        let wantsB2B = shouldHaveB2B(phase: .build, experience: experience, raceEffectiveKm: raceEffectiveKm)

        var templates: [SessionTemplate] = [
            tpl(0, .rest, .easy, 0, "Rest day. Prioritize sleep for adaptation."),
        ]

        if wantsDoubleVertical && !wantsB2B {
            // 2 vertical sessions: VO2max + endurance
            templates += [
                tpl(1, .verticalGain, .hard, 0.12, "VO2max hill repeats. Short, intense climbs to build power."),
                tpl(2, .recovery, .easy, 0.08, "Easy recovery run. Flush legs from yesterday's effort."),
                tpl(3, .verticalGain, .moderate, 0.15, "Endurance climbing. Longer moderate efforts to build vertical stamina."),
            ]
        } else {
            templates += [
                tpl(1, .intervals, .hard, 0.12, "Interval session. Build speed and VO2max."),
                tpl(2, .recovery, .easy, 0.08, "Easy recovery run. Flush legs from yesterday's intervals."),
            ]
            if experience == .advanced || experience == .elite {
                templates.append(tpl(3, .verticalGain, .hard, 0.15, "Vertical gain session. Build climbing strength."))
            } else {
                templates.append(tpl(3, .tempo, .moderate, 0.15, "Tempo run with sustained effort. Practice pacing for race intensity."))
            }
        }

        templates.append(tpl(4, .rest, .easy, 0, "Rest day. Hydrate well ahead of the weekend."))

        if wantsB2B {
            templates += [
                tplTime(5, .longRun, .easy, 0.25, "Back-to-back day 1. Moderate long run building fatigue for tomorrow."),
                tplTime(6, .backToBack, .easy, 0.30, "Back-to-back day 2. Long run on tired legs to simulate ultra fatigue."),
            ]
        } else {
            templates += [
                tplTime(5, .longRun, .easy, 0.40, "Long run on trail terrain. Include elevation if possible. Practice nutrition."),
                crossTrainingOrAlternative(day: 6, experience: experience),
            ]
        }

        return templates
    }

    private static func peakTemplates(experience: ExperienceLevel, raceEffectiveKm: Double, weekInPhase: Int) -> [SessionTemplate] {
        let wantsB2B = shouldHaveB2B(phase: .peak, experience: experience, raceEffectiveKm: raceEffectiveKm)

        var templates: [SessionTemplate] = [
            tpl(0, .rest, .easy, 0, "Rest day. Mental preparation and gear check."),
        ]

        if wantsB2B {
            // Only 1 quality session when B2B is scheduled
            templates += [
                tpl(1, .intervals, .hard, 0.10, "Short sharp intervals. Maintain sharpness."),
                tpl(2, .recovery, .easy, 0.08, "Easy recovery run. Focus on form and relaxation."),
                tpl(3, .recovery, .easy, 0.07, "Light recovery jog. Keep legs loose."),
                tpl(4, .rest, .easy, 0, "Rest day. Pre-hydrate for the weekend block."),
                tplTime(5, .longRun, .moderate, 0.22, "Back-to-back day 1. Steady effort building fatigue."),
                tplTime(6, .backToBack, .moderate, 0.28, "Back-to-back day 2. Peak simulation on tired legs. Full nutrition rehearsal."),
            ]
        } else {
            templates += [
                tpl(1, .intervals, .hard, 0.10, "Short sharp intervals. Maintain sharpness."),
                tpl(2, .recovery, .easy, 0.08, "Easy recovery run. Focus on form and relaxation."),
                tpl(3, .verticalGain, .hard, 0.12, "Vertical gain work on steep terrain. Practice power hiking."),
                tpl(4, .rest, .easy, 0, "Rest day. Pre-hydrate for the weekend block."),
                tplTime(5, .longRun, .moderate, 0.40, "Peak long run simulating race conditions. Full nutrition rehearsal."),
                crossTrainingOrAlternative(day: 6, experience: experience),
            ]
        }

        return templates
    }

    private static func taperTemplates() -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, "Rest day. Enjoy the taper — trust your training."),
            tpl(1, .intervals, .moderate, 0.12, "Short opener intervals. Stay sharp without fatiguing."),
            tpl(2, .rest, .easy, 0, "Rest day. Light stretching and foam rolling."),
            tpl(3, .recovery, .easy, 0.10, "Easy shakeout run. Keep it short and comfortable."),
            tpl(4, .rest, .easy, 0, "Rest day. Final gear and nutrition prep."),
            tplTime(5, .longRun, .easy, 0.25, "Reduced long run at easy effort. No heroics — save it for race day."),
            tpl(6, .rest, .easy, 0, "Full rest. Sleep, hydrate, visualize your race.")
        ]
    }

    private static func recoveryTemplates(experience: ExperienceLevel) -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, "Recovery week rest day. Let your body absorb the training."),
            tpl(1, .recovery, .easy, 0.12, "Easy recovery jog. Very comfortable pace, Zone 1 only."),
            tpl(2, .rest, .easy, 0, "Rest day. Focus on nutrition and sleep quality."),
            crossTrainingOrAlternative(day: 3, experience: experience, isRecoveryWeek: true),
            tpl(4, .rest, .easy, 0, "Rest day. Stretching and mobility work."),
            tplTime(5, .longRun, .easy, 0.25, "Reduced long run at very easy pace. Enjoy the scenery."),
            tpl(6, .rest, .easy, 0, "Full rest day. You've earned it.")
        ]
    }

    // MARK: - Race Override Templates

    private static func overrideTemplates(for behavior: IntermediateRaceHandler.Behavior, experience: ExperienceLevel) -> [SessionTemplate] {
        switch behavior {
        case .miniTaper:
            return taperTemplates()
        case .raceWeek(let priority):
            return priority == .cRace ? cRaceWeekTemplates() : bRaceWeekTemplates()
        case .postRaceRecovery:
            return recoveryTemplates(experience: experience)
        }
    }

    private static func bRaceWeekTemplates() -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, "Rest before race. Stay off your feet."),
            tpl(1, .recovery, .easy, 0.08, "Short shakeout run. 15-20 min at easy pace."),
            tpl(2, .rest, .easy, 0, "Rest day. Carb-load and hydrate."),
            tpl(3, .rest, .easy, 0, "Rest day. Final race prep and gear check."),
            tpl(4, .rest, .easy, 0, "Rest day. Visualize your race plan."),
            tpl(5, .rest, .maxEffort, 0, "RACE DAY! Execute your plan. Trust your training."),
            tpl(6, .rest, .easy, 0, "Post-race recovery. Walk, stretch, refuel.")
        ]
    }

    private static func cRaceWeekTemplates() -> [SessionTemplate] {
        [
            tpl(0, .rest, .easy, 0, "Rest day. Easy start to race week."),
            tpl(1, .recovery, .easy, 0.10, "Easy run at conversational pace. Keep it short."),
            tpl(2, .rest, .easy, 0, "Rest day. Light stretching."),
            tpl(3, .tempo, .moderate, 0.12, "Short tempo effort. Stay sharp but save energy for race."),
            tpl(4, .rest, .easy, 0, "Rest day. Prepare race gear and nutrition."),
            tpl(5, .rest, .maxEffort, 0, "RACE DAY! Use this as a hard training effort."),
            tpl(6, .recovery, .easy, 0.08, "Easy recovery run. Shake out race-day legs.")
        ]
    }

    // MARK: - B2B Logic

    private static func shouldHaveB2B(phase: TrainingPhase, experience: ExperienceLevel, raceEffectiveKm: Double) -> Bool {
        switch (phase, experience) {
        case (.peak, .intermediate): raceEffectiveKm >= 100
        case (.peak, .advanced):     raceEffectiveKm >= 80
        case (.peak, .elite):        raceEffectiveKm >= 80
        case (.build, .advanced):    raceEffectiveKm >= 100
        case (.build, .elite):       raceEffectiveKm >= 80
        default: false
        }
    }

    // MARK: - Cross-Training / Alternative

    private static func crossTrainingOrAlternative(
        day: Int,
        experience: ExperienceLevel,
        isRecoveryWeek: Bool = false
    ) -> SessionTemplate {
        switch experience {
        case .elite:
            return tpl(day, .crossTraining, .easy, 0.10,
                "Cross-training: cycling, swimming, or hiking. Active recovery.")
        case .advanced where isRecoveryWeek:
            return tpl(day, .crossTraining, .easy, 0.10,
                "Light cross-training: swimming, yoga, or gentle cycling.")
        case .advanced:
            return tpl(day, .recovery, .easy, 0.08,
                "Easy recovery run. Keep the pace conversational.")
        case .beginner, .intermediate:
            return tpl(day, .rest, .easy, 0,
                "Rest day. Recovery is part of training.")
        }
    }

    // MARK: - Runs Per Week Adaptation

    private static func adaptTemplates(
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

    private static func tpl(_ day: Int, _ type: SessionType, _ intensity: Intensity, _ fraction: Double, _ desc: String) -> SessionTemplate {
        SessionTemplate(dayOffset: day, type: type, intensity: intensity, volumeFraction: fraction, description: desc, isTimeBased: false)
    }

    private static func tplTime(_ day: Int, _ type: SessionType, _ intensity: Intensity, _ fraction: Double, _ desc: String) -> SessionTemplate {
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
