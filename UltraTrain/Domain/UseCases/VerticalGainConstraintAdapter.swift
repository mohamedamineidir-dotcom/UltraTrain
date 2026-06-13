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
                    notes: String(localized: "vga.flatThenHill", defaultValue: "\(flatMin)min flat at target intensity, then \(hillTimeStr) uphill. Time your run to arrive at the hill for the final portion.")
                ))
            } else {
                newPhases.append(phase)
            }
        }

        adapted.phases = newPhases

        let repCount = newPhases.first(where: { $0.phaseType == .work })?.repeatCount ?? 0
        let flatMin = Int(max((longestWorkRepDuration(in: workout) - hillMaxSec), 0)) / 60
        let hillMin = Int(hillMaxSec) / 60
        adapted.descriptionText = String(localized: "vga.repStructure", defaultValue: "\(repCount)x(\(flatMin)min flat + \(hillMin)min uphill) at target intensity / jog back")
        adapted.name = String(localized: "vga.008", defaultValue: "Integrated flat+hill intervals")

        return adapted
    }

    // MARK: - Treadmill Redirect

    private static func applyTreadmillRedirect(
        session: TrainingSession,
        config: Config
    ) -> TrainingSession {
        var s = session
        let prefix = String(localized: "vga.050", defaultValue: "Treadmill session. ")
        s.description = prefix + session.description

        let gradeAdvice: String
        switch config.phase {
        case .base:
            gradeAdvice = String(localized: "vga.036", defaultValue: "Set the grade to 10-12%. Sustained moderate effort. Focus on building climbing endurance at an easy pace.")
        case .build:
            gradeAdvice = String(localized: "vga.026", defaultValue: "Intervals: set 12-15% for hard reps, drop to 0% for recovery jogs. Same structure as outdoor hills.")
        case .peak:
            gradeAdvice = String(localized: "vga.033", defaultValue: "Race simulation: alternate between flat running and max-grade hiking to match the rhythm of your race profile.")
        default:
            gradeAdvice = String(localized: "vga.037", defaultValue: "Set the grade to 8-10% for moderate efforts, 12-15% for hard efforts.")
        }

        s.coachAdvice = String(localized: "vga.treadmillControl", defaultValue: "Treadmill gives you full control over incline and duration. \(gradeAdvice) ")
            + String(localized: "vga.028", defaultValue: "Keep your form upright, shorten your stride, drive your knees. ")
            + String(localized: "vga.031", defaultValue: "One thing treadmill cannot replicate: downhill eccentric loading. ")
            + String(localized: "vga.019", defaultValue: "Add 2-3 sets of slow eccentric step-downs or Nordic curls after this session to cover that gap.")
        return s
    }

    // MARK: - Flat Conversion

    private static func convertToFlatWorkout(
        workout: IntervalWorkout,
        config: Config
    ) -> IntervalWorkout {
        var adapted = workout
        adapted.name = String(localized: "vga.007", defaultValue: "Flat Power Intervals (VG substitute)")
        adapted.category = .speedWork

        adapted.phases = workout.phases.map { phase in
            var p = phase
            if phase.phaseType == .work {
                p.notes = String(localized: "vga.021", defaultValue: "Hard effort on flat. High cadence, powerful leg drive. Lean slightly forward and push off like you are climbing.")
            } else if phase.phaseType == .recovery {
                p.notes = String(localized: "vga.009", defaultValue: "Easy jog recovery")
            } else if phase.phaseType == .warmUp {
                p.notes = String(localized: "vga.010", defaultValue: "Easy warm-up, include 4-6 strides")
            }
            return p
        }

        let alternatives: String
        switch config.phase {
        case .base:
            alternatives = String(localized: "vga.025", defaultValue: "If you have access to stadium stairs or a parking garage ramp, use those instead for a more climbing-specific stimulus.")
        case .build:
            alternatives = String(localized: "vga.039", defaultValue: "Stadium stairs, parking garage ramps, or even a weighted vest (5-8% bodyweight) will make this more climbing-specific.")
        case .peak:
            alternatives = String(localized: "vga.047", defaultValue: "This close to race day, try to find any incline available, even 30-60 min drive away. One real hill session now is worth three flat substitutes.")
        default:
            alternatives = String(localized: "vga.029", defaultValue: "Look for any available incline: stadium stairs, parking garage ramps, bridges, or overpasses.")
        }

        adapted.descriptionText = String(localized: "vga.flatSubst", defaultValue: "Flat power intervals (VG substitute). Same intensity, same duration. \(alternatives)")
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
                name: String(localized: "vga.005", defaultValue: "Step-Up (40cm box, loaded if possible)"),
                category: .lowerBody, sets: sets, reps: isHeavy ? String(localized: "vga.014", defaultValue: "6-8 per leg") : String(localized: "vga.013", defaultValue: "10 per leg"),
                notes: String(localized: "vga.041", defaultValue: "THE most climbing-specific exercise. Drive through the heel, full hip extension at top. This is your race-day climbing engine.")
            ),
            StrengthExercise(
                name: String(localized: "vga.002", defaultValue: "Bulgarian Split Squat (eccentric focus)"),
                category: .singleLegStability, sets: sets, reps: isHeavy ? String(localized: "vga.015", defaultValue: "8 per leg") : String(localized: "vga.013", defaultValue: "10 per leg"),
                notes: String(localized: "vga.017", defaultValue: "3-second lowering phase. Builds the single-leg power and hip flexor stretch you need for steep terrain.")
            ),
            StrengthExercise(
                name: String(localized: "vga.004", defaultValue: "Eccentric Squat (4-sec lowering)"),
                category: .lowerBody, sets: sets, reps: isHeavy ? "6" : "8-10",
                notes: String(localized: "vga.038", defaultValue: "Slow controlled descent. This eccentric strength is what saves your quads on race-day descents.")
            ),
            StrengthExercise(
                name: String(localized: "vga.003", defaultValue: "Calf Raise (straight + bent knee)"),
                category: .lowerBody, sets: sets, reps: String(localized: "vga.012", defaultValue: "12-15 each"),
                notes: String(localized: "vga.016", defaultValue: "2-second hold at top. Straight-leg for power push-off, bent-knee for endurance. Your Achilles depends on this.")
            ),
            StrengthExercise(
                name: String(localized: "vga.001", defaultValue: "Banded Hip Flexor Drive"),
                category: .lowerBody, sets: 2, reps: String(localized: "vga.011", defaultValue: "12 per side"),
                notes: String(localized: "vga.022", defaultValue: "High knee drive against resistance. Trains the hip flexor power that drives you uphill at km 60.")
            ),
        ]

        let duration = StrengthSessionGenerator.estimatedDuration(
            category: .full,
            exercises: exercises,
            phase: config.phase
        )

        return StrengthWorkout(
            name: String(localized: "vga.006", defaultValue: "Climbing Strength (VG companion)"),
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
        s.coachAdvice = String(localized: "vga.030", defaultValue: "No hills or treadmill available, so this is adapted to flat power intervals. ")
            + String(localized: "vga.035", defaultValue: "Same intensity, same duration, same effort. High cadence with powerful leg drive. ")
            + String(localized: "vga.018", defaultValue: "A companion climbing strength session is paired with this to cover the muscle groups your legs would normally work on hills.")
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
            phaseAdvice = String(localized: "vga.027", defaultValue: "Keep the flat portion at a steady moderate effort. The goal is to arrive at the hill already working, not sprinting.")
        case .build:
            phaseAdvice = String(localized: "vga.flatThreshold", defaultValue: "The flat portion should be at your threshold effort. By the time you hit the hill, your legs should feel like you have been climbing for \(flatMin) minutes already.")
        case .peak:
            phaseAdvice = String(localized: "vga.034", defaultValue: "Race simulation. Run the flat portion at race effort, hit the hill at race climbing effort. Practice transitioning between flat running and climbing, exactly like race day.")
        default:
            phaseAdvice = String(localized: "vga.040", defaultValue: "Steady effort on the flat, same intensity on the hill. Smooth transition between the two.")
        }

        s.coachAdvice = String(localized: "vga.hillShorter", defaultValue: "Your hill is shorter than the ideal rep length, so each rep starts with \(flatMin) minutes of flat running ")
            + String(localized: "vga.finishesHill", defaultValue: "at the target intensity, then finishes with \(hillMin) minutes on your hill. ")
            + String(localized: "vga.049", defaultValue: "Time your approach so you arrive at the base of the climb right when the flat portion ends. ")
            + String(localized: "vga.044", defaultValue: "The total rep is the same duration as a full mountain rep. ")
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
            stackingAdvice = String(localized: "vga.020", defaultValue: "Do this strength session the same morning as your power intervals, with at least 6 hours between the two. ")
                + String(localized: "vga.042", defaultValue: "The residual leg fatigue from strength makes the flat intervals feel more like real climbing. ")
                + String(localized: "vga.024", defaultValue: "If you cannot fit both in one day, do this strength session the day before instead so your legs carry that fatigue into the intervals.")
        } else {
            stackingAdvice = String(localized: "vga.048", defaultValue: "This strength session replaces the climbing stimulus you cannot get from hills. ")
                + String(localized: "vga.045", defaultValue: "These exercises target your glutes, hip flexors, quads, and calves. Do not skip this.")
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
            return String(localized: "vga.053", defaultValue: "Your terrain has no hills, so we adapted your climbing sessions to flat power intervals ")
                + String(localized: "vga.032", defaultValue: "paired with a climbing-specific strength session on the same day. ")
                + String(localized: "vga.046", defaultValue: "This approach is used by Uphill Athlete and elite coaches for flat-area athletes. ")
                + String(localized: "vga.043", defaultValue: "The strength pre-fatigues your legs so the flat intervals simulate climbing demand. ")
                + String(localized: "vga.023", defaultValue: "If you can access stadium stairs, parking garage ramps, or any incline, use those instead.")
        }
        return String(localized: "vga.052", defaultValue: "Your terrain has no hills, so climbing sessions are adapted to flat power intervals ")
            + String(localized: "vga.051", defaultValue: "with targeted leg strength work. Look for any available incline: stairs, ramps, bridges.")
    }

    // MARK: - Helpers

    private static func formatCompanionDescription(_ workout: StrengthWorkout) -> String {
        var lines: [String] = [workout.name, String(localized: "vga.duration", defaultValue: "Duration: ~\(workout.estimatedDurationMinutes) min"), ""]
        for ex in workout.exercises {
            lines.append("  \u{2022} \(ex.name), \(ex.sets)x\(ex.reps)")
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
