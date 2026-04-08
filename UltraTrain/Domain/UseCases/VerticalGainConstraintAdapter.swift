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

            case .integratedFlatHillRep(let adaptedWorkout, let flatPortionSec, let hillPortionSec):
                adaptedSessions[i] = applyIntegratedRepAdaptation(
                    session: session,
                    workout: adaptedWorkout,
                    flatSeconds: flatPortionSec,
                    hillSeconds: hillPortionSec,
                    config: config
                )
                replaceWorkout(id: session.intervalWorkoutId, with: adaptedWorkout, in: &adaptedWorkouts)

            case .redirectToTreadmill:
                adaptedSessions[i] = applyTreadmillRedirect(
                    session: session,
                    config: config
                )

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
                        nearDate: session.date,
                        config: config
                    )
                    if injected {
                        adaptedStrength.append(strength)
                    }
                }

                planNote = flatAreaPlanNote(config: config)
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
        case integratedFlatHillRep(workout: IntervalWorkout, flatSec: TimeInterval, hillSec: TimeInterval)
        case redirectToTreadmill
        case convertToFlat(workout: IntervalWorkout, companion: StrengthWorkout?)
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

        // Athlete has outdoor hill access
        if config.environment.hasOutdoorHill {
            if let max = maxUphill, max > 0, repDuration > max {
                // Hill shorter than target rep.
                // If hill < 50% of target and treadmill available, prefer treadmill.
                if max < repDuration * 0.5, config.environment.hasTreadmill {
                    return .redirectToTreadmill
                }
                // Integrated flat+hill rep: run flat portion at target intensity,
                // finish each rep on the hill. Preserves original rep duration.
                let adapted = buildIntegratedWorkout(
                    workout: workout,
                    hillMaxSec: max,
                    config: config
                )
                return .integratedFlatHillRep(workout: adapted, flatSec: repDuration - max, hillSec: max)
            }
            return .noChange
        }

        // No outdoor hill. Try treadmill.
        if config.environment.hasTreadmill {
            return .redirectToTreadmill
        }

        // No hill and no treadmill. Convert to flat + companion strength.
        let flat = convertToFlatWorkout(workout: workout, config: config)
        let companion = buildCompanionStrength(config: config, originalWorkDuration: workout.totalWorkDuration)
        return .convertToFlat(workout: flat, companion: companion)
    }

    // MARK: - Integrated Flat+Hill Rep

    /// Keeps the original rep duration. Each rep = flat portion at target intensity + hill portion.
    /// Example: 8min target on 2min hill → each rep = 6min flat Z3 + 2min uphill Z3.
    private static func buildIntegratedWorkout(
        workout: IntervalWorkout,
        hillMaxSec: TimeInterval,
        config: Config
    ) -> IntervalWorkout {
        var adapted = workout
        var newPhases: [IntervalPhase] = []

        for phase in workout.phases {
            if phase.phaseType == .work, case .duration(let totalRepSec) = phase.trigger, totalRepSec > hillMaxSec {
                let flatSec = totalRepSec - hillMaxSec
                let flatMin = Int(flatSec) / 60
                let hillMin = Int(hillMaxSec) / 60
                let hillSec = Int(hillMaxSec) % 60
                let hillTimeStr = hillSec > 0 ? "\(hillMin)m\(hillSec)s" : "\(hillMin)min"

                // The work phase keeps the full duration (flat + hill = original rep)
                newPhases.append(IntervalPhase(
                    id: UUID(), phaseType: .work,
                    trigger: .duration(seconds: totalRepSec),
                    targetIntensity: phase.targetIntensity,
                    repeatCount: phase.repeatCount,
                    notes: "\(flatMin)min flat at target intensity, then \(hillTimeStr) uphill. Time your run to arrive at the hill for the final portion."
                ))
            } else {
                newPhases.append(phase)
            }
        }

        adapted.phases = newPhases

        let repCount = newPhases.first(where: { $0.phaseType == .work })?.repeatCount ?? 0
        let flatMin = Int(max((longestWorkRepDuration(in: workout) - hillMaxSec), 0)) / 60
        let hillMin = Int(hillMaxSec) / 60
        adapted.descriptionText = "\(repCount)x(\(flatMin)min flat + \(hillMin)min uphill) at target intensity / jog back"
        adapted.name = "Integrated flat+hill intervals"

        return adapted
    }

    // MARK: - Treadmill Redirect

    private static func applyTreadmillRedirect(
        session: TrainingSession,
        config: Config
    ) -> TrainingSession {
        var s = session
        let prefix = "Treadmill session. "
        s.description = prefix + session.description

        let gradeAdvice: String
        switch config.phase {
        case .base:
            gradeAdvice = "Set the grade to 10-12%. Sustained moderate effort. Focus on building climbing endurance at an easy pace."
        case .build:
            gradeAdvice = "Intervals: set 12-15% for hard reps, drop to 0% for recovery jogs. Same structure as outdoor hills."
        case .peak:
            gradeAdvice = "Race simulation: alternate between flat running and max-grade hiking to match the rhythm of your race profile."
        default:
            gradeAdvice = "Set the grade to 8-10% for moderate efforts, 12-15% for hard efforts."
        }

        s.coachAdvice = "Treadmill gives you full control over incline and duration. \(gradeAdvice) "
            + "Keep your form upright, shorten your stride, drive your knees. "
            + "One thing treadmill cannot replicate: downhill eccentric loading. "
            + "Add 2-3 sets of slow eccentric step-downs or Nordic curls after this session to cover that gap."
        return s
    }

    // MARK: - Flat Conversion

    private static func convertToFlatWorkout(
        workout: IntervalWorkout,
        config: Config
    ) -> IntervalWorkout {
        var adapted = workout
        adapted.name = "Flat Power Intervals (VG substitute)"
        adapted.category = .speedWork

        adapted.phases = workout.phases.map { phase in
            var p = phase
            if phase.phaseType == .work {
                p.notes = "Hard effort on flat. High cadence, powerful leg drive. Lean slightly forward and push off like you are climbing."
            } else if phase.phaseType == .recovery {
                p.notes = "Easy jog recovery"
            } else if phase.phaseType == .warmUp {
                p.notes = "Easy warm-up, include 4-6 strides"
            }
            return p
        }

        let alternatives: String
        switch config.phase {
        case .base:
            alternatives = "If you have access to stadium stairs or a parking garage ramp, use those instead for a more climbing-specific stimulus."
        case .build:
            alternatives = "Stadium stairs, parking garage ramps, or even a weighted vest (5-8% bodyweight) will make this more climbing-specific."
        case .peak:
            alternatives = "This close to race day, try to find any incline available, even 30-60 min drive away. One real hill session now is worth three flat substitutes."
        default:
            alternatives = "Look for any available incline: stadium stairs, parking garage ramps, bridges, or overpasses."
        }

        adapted.descriptionText = "Flat power intervals (VG substitute). Same intensity, same duration. \(alternatives)"
        return adapted
    }

    // MARK: - Companion Strength

    private static func buildCompanionStrength(
        config: Config,
        originalWorkDuration: TimeInterval
    ) -> StrengthWorkout {
        let sets = config.experience == .beginner ? 2 : 3
        let isHeavy = config.phase == .build || config.phase == .peak

        let exercises: [StrengthExercise] = [
            StrengthExercise(
                name: "Step-Up (40cm box, loaded if possible)",
                category: .lowerBody, sets: sets, reps: isHeavy ? "6-8 per leg" : "10 per leg",
                notes: "THE most climbing-specific exercise. Drive through the heel, full hip extension at top. This is your race-day climbing engine."
            ),
            StrengthExercise(
                name: "Bulgarian Split Squat (eccentric focus)",
                category: .singleLegStability, sets: sets, reps: isHeavy ? "8 per leg" : "10 per leg",
                notes: "3-second lowering phase. Builds the single-leg power and hip flexor stretch you need for steep terrain."
            ),
            StrengthExercise(
                name: "Eccentric Squat (4-sec lowering)",
                category: .lowerBody, sets: sets, reps: isHeavy ? "6" : "8-10",
                notes: "Slow controlled descent. This eccentric strength is what saves your quads on race-day descents."
            ),
            StrengthExercise(
                name: "Calf Raise (straight + bent knee)",
                category: .lowerBody, sets: sets, reps: "12-15 each",
                notes: "2-second hold at top. Straight-leg for power push-off, bent-knee for endurance. Your Achilles depends on this."
            ),
            StrengthExercise(
                name: "Banded Hip Flexor Drive",
                category: .lowerBody, sets: 2, reps: "12 per side",
                notes: "High knee drive against resistance. Trains the hip flexor power that drives you uphill at km 60."
            ),
        ]

        let duration = StrengthSessionGenerator.estimatedDuration(
            category: .full,
            exercises: exercises,
            phase: config.phase
        )

        return StrengthWorkout(
            name: "Climbing Strength (VG companion)",
            category: .full,
            exercises: exercises,
            estimatedDurationMinutes: duration,
            warmUpNotes: "",
            coolDownNotes: ""
        )
    }

    // MARK: - Flat Conversion Application

    private static func applyFlatConversion(
        session: TrainingSession,
        workout: IntervalWorkout,
        config: Config
    ) -> TrainingSession {
        var s = session
        s.description = workout.descriptionText
        s.coachAdvice = "No hills or treadmill available, so this is adapted to flat power intervals. "
            + "Same intensity, same duration, same effort. High cadence with powerful leg drive. "
            + "A companion climbing strength session is paired with this to cover the muscle groups your legs would normally work on hills."
        return s
    }

    // MARK: - Integrated Rep Adaptation

    private static func applyIntegratedRepAdaptation(
        session: TrainingSession,
        workout: IntervalWorkout,
        flatSeconds: TimeInterval,
        hillSeconds: TimeInterval,
        config: Config
    ) -> TrainingSession {
        var s = session
        let flatMin = Int(flatSeconds) / 60
        let hillMin = Int(hillSeconds) / 60

        s.description = workout.descriptionText

        let phaseAdvice: String
        switch config.phase {
        case .base:
            phaseAdvice = "Keep the flat portion at a steady moderate effort. The goal is to arrive at the hill already working, not sprinting."
        case .build:
            phaseAdvice = "The flat portion should be at your threshold effort. By the time you hit the hill, your legs should feel like you have been climbing for \(flatMin) minutes already."
        case .peak:
            phaseAdvice = "Race simulation. Run the flat portion at race effort, hit the hill at race climbing effort. Practice transitioning between flat running and climbing, exactly like race day."
        default:
            phaseAdvice = "Steady effort on the flat, same intensity on the hill. Smooth transition between the two."
        }

        s.coachAdvice = "Your hill is shorter than the ideal rep length, so each rep starts with \(flatMin) minutes of flat running "
            + "at the target intensity, then finishes with \(hillMin) minutes on your hill. "
            + "Time your approach so you arrive at the base of the climb right when the flat portion ends. "
            + "The total rep is the same duration as a full mountain rep. "
            + "\(phaseAdvice)"
        return s
    }

    // MARK: - Companion Injection

    private static func injectCompanionStrength(
        strength: StrengthWorkout,
        sessions: inout [TrainingSession],
        nearDate: Date,
        config: Config
    ) -> Bool {
        // For build/peak: inject on the SAME DAY as the flat power session (AM strength, PM run)
        // For base: inject on nearest rest/recovery day
        let targetDate: Date
        let isSameDay = (config.phase == .build || config.phase == .peak)
            && config.experience != .beginner

        if isSameDay {
            targetDate = nearDate // Same day as the VG substitute
        } else {
            // Find nearest rest or recovery day
            let candidates = sessions.filter {
                ($0.type == .rest || $0.type == .recovery)
                    && $0.strengthWorkoutId == nil
            }
            let nearest = candidates.min(by: {
                abs($0.date.timeIntervalSince(nearDate)) < abs($1.date.timeIntervalSince(nearDate))
            })
            targetDate = nearest?.date ?? nearDate
        }

        let stackingAdvice: String
        if isSameDay {
            stackingAdvice = "Do this strength session the same morning as your power intervals, with at least 6 hours between the two. "
                + "The residual leg fatigue from strength makes the flat intervals feel more like real climbing. "
                + "If you cannot fit both in one day, do this strength session the day before instead so your legs carry that fatigue into the intervals."
        } else {
            stackingAdvice = "This strength session replaces the climbing stimulus you cannot get from hills. "
                + "These exercises target your glutes, hip flexors, quads, and calves. Do not skip this."
        }

        let scSession = TrainingSession(
            id: UUID(),
            date: targetDate,
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
            coachAdvice: stackingAdvice
        )

        sessions.append(scSession)
        return true
    }

    // MARK: - Plan Note

    private static func flatAreaPlanNote(config: Config) -> String {
        if config.phase == .build || config.phase == .peak {
            return "Your terrain has no hills, so we adapted your climbing sessions to flat power intervals "
                + "paired with a climbing-specific strength session on the same day. "
                + "This approach is used by Uphill Athlete and elite coaches for flat-area athletes. "
                + "The strength pre-fatigues your legs so the flat intervals simulate climbing demand. "
                + "If you can access stadium stairs, parking garage ramps, or any incline, use those instead."
        }
        return "Your terrain has no hills, so climbing sessions are adapted to flat power intervals "
            + "with targeted leg strength work. Look for any available incline: stairs, ramps, bridges."
    }

    // MARK: - Helpers

    private static func formatCompanionDescription(_ workout: StrengthWorkout) -> String {
        var lines: [String] = [workout.name, "Duration: ~\(workout.estimatedDurationMinutes) min", ""]
        for ex in workout.exercises {
            lines.append("  \u{2022} \(ex.name) \u{2014} \(ex.sets)x\(ex.reps)")
            if !ex.notes.isEmpty {
                lines.append("    \(ex.notes)")
            }
        }
        return lines.joined(separator: "\n")
    }

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
