import Foundation

/// Transforms VG sessions into executable versions based on the athlete's
/// terrain constraints. Runs after SessionTemplateGenerator, modifying only
/// execution modality, rep structure, and descriptions. Never reduces load.
///
/// Trail/ultra only. No effect on road plans.
enum VerticalGainConstraintAdapter {

    struct Config: Sendable {
        let environment: VerticalGainEnvironment
        let maxUphillSeconds: TimeInterval?
        let phase: TrainingPhase
        let experience: ExperienceLevel
    }

    struct AdaptedResult: Sendable {
        var sessions: [TrainingSession]
        var workouts: [IntervalWorkout]
        var strengthWorkouts: [StrengthWorkout]
        var planNote: String?
    }

    // MARK: - Public

    static func adapt(
        sessions: [TrainingSession],
        workouts: [IntervalWorkout],
        strengthWorkouts: [StrengthWorkout],
        config: Config
    ) -> AdaptedResult {
        var adaptedSessions = sessions
        var adaptedWorkouts = workouts
        var adaptedStrength = strengthWorkouts
        var planNote: String?

        for (i, session) in sessions.enumerated() {
            guard session.type == .verticalGain else { continue }

            let adaptation = resolveAdaptation(
                session: session,
                workouts: workouts,
                config: config
            )

            switch adaptation {
            case .noChange:
                break

            case .capRepsWithPreFatigue(let cappedWorkout, let preFatigueMinutes):
                adaptedSessions[i] = applyWorkoutAdaptation(
                    session: session,
                    workout: cappedWorkout,
                    modality: .hillCapped,
                    preFatigueMinutes: preFatigueMinutes,
                    config: config
                )
                replaceWorkout(id: session.intervalWorkoutId, with: cappedWorkout, in: &adaptedWorkouts)

            case .redirectToTreadmill:
                adaptedSessions[i] = applyModalityChange(
                    session: session,
                    modality: .treadmill,
                    config: config
                )

            case .redirectToStairs(let cappedWorkout):
                adaptedSessions[i] = applyWorkoutAdaptation(
                    session: session,
                    workout: cappedWorkout,
                    modality: .stairs,
                    preFatigueMinutes: 0,
                    config: config
                )
                replaceWorkout(id: session.intervalWorkoutId, with: cappedWorkout, in: &adaptedWorkouts)

            case .convertToFlat(let flatWorkout, let companionStrength):
                adaptedSessions[i] = applyFlatConversion(
                    session: session,
                    workout: flatWorkout,
                    config: config
                )
                replaceWorkout(id: session.intervalWorkoutId, with: flatWorkout, in: &adaptedWorkouts)

                if let strength = companionStrength {
                    let injected = injectCompanionStrength(
                        strength: strength,
                        sessions: &adaptedSessions,
                        nearDate: session.date
                    )
                    if injected {
                        adaptedStrength.append(strength)
                    }
                }

                planNote = "Your terrain doesn't have hills or a treadmill, so we adapted your climbing sessions. "
                    + "Flat power work and targeted leg strength will build the same muscle groups you need for race-day climbing. "
                    + "This approach is used by coaches working with athletes in flat areas and it works."
            }
        }

        return AdaptedResult(
            sessions: adaptedSessions,
            workouts: adaptedWorkouts,
            strengthWorkouts: adaptedStrength,
            planNote: planNote
        )
    }

    // MARK: - Adaptation Resolution

    private enum Adaptation {
        case noChange
        case capRepsWithPreFatigue(workout: IntervalWorkout, preFatigueMinutes: Int)
        case redirectToTreadmill
        case redirectToStairs(workout: IntervalWorkout)
        case convertToFlat(workout: IntervalWorkout, companion: StrengthWorkout?)
    }

    private enum Modality {
        case hillCapped
        case treadmill
        case stairs
        case flat
    }

    private static func resolveAdaptation(
        session: TrainingSession,
        workouts: [IntervalWorkout],
        config: Config
    ) -> Adaptation {
        guard let workoutId = session.intervalWorkoutId,
              let workout = workouts.first(where: { $0.id == workoutId }) else {
            return .noChange
        }

        let repDuration = longestWorkRepDuration(in: workout)
        let maxUphill = config.maxUphillSeconds

        // If athlete has unconstrained hill access, no adaptation needed
        if config.environment.hasOutdoorHill {
            if let max = maxUphill, max > 0, repDuration > max {
                // Hill is shorter than the generated rep duration
                let capped = capRepDuration(workout: workout, maxSec: max)
                let preFatigue = preFatigueMinutes(hillMaxSec: max, targetRepSec: repDuration)
                return .capRepsWithPreFatigue(workout: capped, preFatigueMinutes: preFatigue)
            }
            return .noChange
        }

        // No outdoor hill. Try treadmill.
        if config.environment.hasTreadmill {
            return .redirectToTreadmill
        }

        // No treadmill. Try stairs.
        if config.environment.hasStairs {
            let stairMaxSec: TimeInterval = 120 // stairs reps capped at 2min
            let capped = capRepDuration(workout: workout, maxSec: stairMaxSec)
            return .redirectToStairs(workout: capped)
        }

        // Nothing. Convert to flat equivalent + companion strength.
        let flat = convertToFlatWorkout(workout: workout)
        let companion = buildCompanionStrength(config: config, originalWorkDuration: workout.totalWorkDuration)
        return .convertToFlat(workout: flat, companion: companion)
    }

    // MARK: - Rep Capping

    /// Caps each work rep to maxSec, increasing rep count to preserve total work volume.
    private static func capRepDuration(workout: IntervalWorkout, maxSec: TimeInterval) -> IntervalWorkout {
        var newPhases: [IntervalPhase] = []

        for phase in workout.phases {
            if phase.phaseType == .work, case .duration(let sec) = phase.trigger, sec > maxSec {
                let totalWork = sec * Double(phase.repeatCount)
                let newReps = max(Int((totalWork / maxSec).rounded(.up)), phase.repeatCount)
                let adjustedDuration = totalWork / Double(newReps)
                let roundedDuration = (adjustedDuration / 15.0).rounded() * 15.0

                newPhases.append(IntervalPhase(
                    id: UUID(), phaseType: .work,
                    trigger: .duration(seconds: max(roundedDuration, 30)),
                    targetIntensity: phase.targetIntensity,
                    repeatCount: newReps,
                    notes: phase.notes
                ))
            } else if phase.phaseType == .recovery, case .duration = phase.trigger {
                // Scale recovery reps to match work reps
                let workPhase = newPhases.last(where: { $0.phaseType == .work })
                let reps = workPhase?.repeatCount ?? phase.repeatCount
                newPhases.append(IntervalPhase(
                    id: UUID(), phaseType: .recovery,
                    trigger: phase.trigger,
                    targetIntensity: phase.targetIntensity,
                    repeatCount: reps,
                    notes: phase.notes
                ))
            } else {
                newPhases.append(phase)
            }
        }

        let descParts = newPhases.filter { $0.phaseType == .work }.map { p -> String in
            if case .duration(let s) = p.trigger {
                let min = Int(s) / 60
                let sec = Int(s) % 60
                let timeStr = sec > 0 ? "\(min)m\(sec)s" : "\(min)min"
                return "\(p.repeatCount)x\(timeStr)"
            }
            return ""
        }

        var adapted = workout
        adapted.phases = newPhases
        adapted.descriptionText = descParts.joined(separator: " + ") + " (capped to hill length)"
        return adapted
    }

    // MARK: - Pre-Fatigue Calculation

    /// Longer pre-fatigue for shorter hills. Range: 10-30 minutes.
    private static func preFatigueMinutes(hillMaxSec: TimeInterval, targetRepSec: TimeInterval) -> Int {
        guard targetRepSec > 0 else { return 0 }
        let shortfall = 1.0 - (hillMaxSec / targetRepSec)
        let minutes = 10.0 + shortfall * 20.0
        return Int(min(max(minutes, 10), 30))
    }

    // MARK: - Flat Conversion

    /// Converts a VG workout to a flat neuromuscular equivalent.
    private static func convertToFlatWorkout(workout: IntervalWorkout) -> IntervalWorkout {
        var adapted = workout
        adapted.name = "Flat Power Work (VG substitute)"
        adapted.category = .speedWork

        // Replace "Climb at steady effort" notes with flat equivalents
        adapted.phases = workout.phases.map { phase in
            var p = phase
            if phase.phaseType == .work {
                p.notes = "Hard effort on flat. High cadence, powerful leg drive. Think about pushing off like you are climbing."
            } else if phase.phaseType == .recovery {
                p.notes = "Easy jog recovery"
            } else if phase.phaseType == .warmUp {
                p.notes = "Easy warm-up, include strides"
            }
            return p
        }

        adapted.descriptionText = "Flat power intervals (VG substitute). Same intensity and volume as your hill session, "
            + "targeting the same muscle groups through high-effort flat running."
        return adapted
    }

    // MARK: - Companion Strength Session

    private static func buildCompanionStrength(
        config: Config,
        originalWorkDuration: TimeInterval
    ) -> StrengthWorkout {
        let sets = config.experience == .beginner ? 2 : 3
        let workMinutes = Int(originalWorkDuration / 60)
        let duration = min(max(workMinutes, 15), 30)

        let exercises: [StrengthExercise] = [
            StrengthExercise(
                name: "Box Step-Up (weighted if available)",
                category: .lowerBody, sets: sets, reps: "10 per leg",
                notes: "Mimics uphill running. Drive through the heel, stand tall at the top."
            ),
            StrengthExercise(
                name: "Bulgarian Split Squat",
                category: .singleLegStability, sets: sets, reps: "10 per leg",
                notes: "Slow descent, explosive push up. Builds the single-leg power you need for climbing."
            ),
            StrengthExercise(
                name: "Calf Raise (straight + bent knee)",
                category: .lowerBody, sets: sets, reps: "15 each",
                notes: "3-second lower. This is your Achilles armor for steep terrain."
            ),
            StrengthExercise(
                name: "Hip Flexor March (weighted or banded)",
                category: .lowerBody, sets: sets, reps: "12 per side",
                notes: "High knee drive against resistance. Trains the hip flexor drive that powers uphill running."
            ),
            StrengthExercise(
                name: "Glute Bridge (single-leg)",
                category: .lowerBody, sets: sets, reps: "12 per side",
                notes: "Squeeze at the top for 2 seconds. Glute strength is your climbing engine."
            ),
        ]

        return StrengthWorkout(
            name: "Climbing Strength (VG companion)",
            category: .full,
            exercises: exercises,
            estimatedDurationMinutes: duration,
            warmUpNotes: "5 min easy movement: bodyweight squats, leg swings, calf raises.",
            coolDownNotes: "5 min stretching: quads, hip flexors, calves, hamstrings."
        )
    }

    // MARK: - Session Modification Helpers

    private static func applyWorkoutAdaptation(
        session: TrainingSession,
        workout: IntervalWorkout,
        modality: Modality,
        preFatigueMinutes: Int,
        config: Config
    ) -> TrainingSession {
        var s = session
        let preFatigueText = preFatigueMinutes > 0
            ? "\(preFatigueMinutes)min moderate flat running to pre-fatigue your legs, then "
            : ""
        let modalityText: String
        switch modality {
        case .hillCapped:
            modalityText = "hill repeats (capped to your hill length)"
        case .stairs:
            modalityText = "stair repeats"
        default:
            modalityText = ""
        }

        s.description = preFatigueText + workout.descriptionText
        s.coachAdvice = coachAdviceForAdaptation(
            modality: modality,
            preFatigueMinutes: preFatigueMinutes,
            config: config
        )
        return s
    }

    private static func applyModalityChange(
        session: TrainingSession,
        modality: Modality,
        config: Config
    ) -> TrainingSession {
        var s = session
        s.coachAdvice = coachAdviceForAdaptation(
            modality: modality,
            preFatigueMinutes: 0,
            config: config
        )
        // Description stays the same, workout structure is identical on treadmill
        let prefix = "Treadmill session. "
        s.description = prefix + session.description
        return s
    }

    private static func applyFlatConversion(
        session: TrainingSession,
        workout: IntervalWorkout,
        config: Config
    ) -> TrainingSession {
        var s = session
        s.description = workout.descriptionText
        s.coachAdvice = coachAdviceForAdaptation(
            modality: .flat,
            preFatigueMinutes: 0,
            config: config
        )
        return s
    }

    // MARK: - Coach Advice

    private static func coachAdviceForAdaptation(
        modality: Modality,
        preFatigueMinutes: Int,
        config: Config
    ) -> String {
        switch modality {
        case .hillCapped:
            if preFatigueMinutes > 0 {
                return "Your hill is shorter than the ideal rep length, so we start with \(preFatigueMinutes) minutes "
                    + "of moderate flat running first. By the time you hit the hill your legs are already loaded, "
                    + "and each short rep delivers the same training stimulus as a longer climb on fresh legs. "
                    + "This is a proven technique pro coaches use for athletes training in flatter areas."
            }
            return "Shorter reps, more of them. Same total climbing volume. Stay consistent across all reps."

        case .treadmill:
            return "Treadmill gives you full control over the incline and duration. Set the grade to 8-10% for moderate efforts, "
                + "12-15% for hard efforts. The stimulus is identical to outdoor climbing. Keep your form upright, "
                + "shorten your stride, and drive your knees."

        case .stairs:
            return "Stair repeats are an excellent climbing substitute. Focus on quick, powerful steps. "
                + "Drive your knees, stay light on your feet. Walk back down for recovery. "
                + "The muscle groups are the same ones you will use climbing on race day."

        case .flat:
            return "No hills or treadmill available, so we converted this to flat power intervals. "
                + "Same intensity, same duration, same effort. High cadence with powerful leg drive. "
                + "A companion leg strength session was added this week to cover the climbing-specific "
                + "muscle work your legs would normally get from hills."
        }
    }

    // MARK: - Companion Injection

    private static func injectCompanionStrength(
        strength: StrengthWorkout,
        sessions: inout [TrainingSession],
        nearDate: Date
    ) -> Bool {
        // Find nearest rest or recovery day to inject the strength session
        let candidates = sessions.enumerated().filter {
            ($0.element.type == .rest || $0.element.type == .recovery)
                && $0.element.strengthWorkoutId == nil
        }

        // Prefer a slot within 2 days of the VG session
        let nearest = candidates.min(by: {
            abs($0.element.date.timeIntervalSince(nearDate)) < abs($1.element.date.timeIntervalSince(nearDate))
        })

        guard let slot = nearest else { return false }

        let scSession = TrainingSession(
            id: UUID(),
            date: slot.element.date,
            type: .strengthConditioning,
            plannedDistanceKm: 0,
            plannedElevationGainM: 0,
            plannedDuration: TimeInterval(strength.estimatedDurationMinutes * 60),
            intensity: .moderate,
            description: formatCompanionDescription(strength),
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil,
            strengthWorkoutId: strength.id,
            coachAdvice: "This strength session replaces the climbing stimulus you cannot get from hills. "
                + "These exercises target your glutes, hip flexors, quads, and calves, "
                + "the exact muscles that power you uphill on race day. Do not skip this."
        )

        sessions.append(scSession)
        return true
    }

    private static func formatCompanionDescription(_ workout: StrengthWorkout) -> String {
        var lines: [String] = [workout.name, "Duration: ~\(workout.estimatedDurationMinutes) min", ""]
        lines.append(workout.warmUpNotes)
        lines.append("")
        for ex in workout.exercises {
            lines.append("  \u{2022} \(ex.name) \u{2014} \(ex.sets)x\(ex.reps)")
            if !ex.notes.isEmpty {
                lines.append("    \(ex.notes)")
            }
        }
        lines.append("")
        lines.append(workout.coolDownNotes)
        return lines.joined(separator: "\n")
    }

    // MARK: - Utilities

    private static func longestWorkRepDuration(in workout: IntervalWorkout) -> TimeInterval {
        workout.phases
            .filter { $0.phaseType == .work }
            .compactMap { phase -> TimeInterval? in
                if case .duration(let sec) = phase.trigger { return sec }
                return nil
            }
            .max() ?? 0
    }

    private static func replaceWorkout(
        id: UUID?,
        with newWorkout: IntervalWorkout,
        in workouts: inout [IntervalWorkout]
    ) {
        guard let id, let idx = workouts.firstIndex(where: { $0.id == id }) else { return }
        workouts[idx] = newWorkout
    }
}
